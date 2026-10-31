#!/usr/bin/env python3
"""Regression tests for Auvra testnet validator genesis input validation."""
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

SOURCE = Path(__file__).resolve().parents[1] / "scripts" / "render-genesis-inputs.py"
ADDRS = [
    ("0x" + f"{i:040x}", "0x" + f"{i+100:040x}", "0x" + f"{i+200:040x}")
    for i in range(1, 5)
]
BLS = [f"{i:096x}" for i in range(1, 5)]

def records():
    return [
        f"operator-{i+1},{a},{b},{c},{100+i},{BLS[i]}"
        for i, (a, b, c) in enumerate(ADDRS)
    ]

class ValidatorInputTests(unittest.TestCase):
    def run_renderer(self, lines):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        (root / "scripts").mkdir()
        (root / "config").mkdir()
        upstream = root / "upstream"
        (upstream / "scripts").mkdir(parents=True)
        shutil.copy2(SOURCE, root / "scripts" / SOURCE.name)
        (root / "config" / "validators.testnet.conf").write_text(
            "# test fixture\n" + "\n".join(lines) + "\n"
        )
        (root / "config" / "initial-holders.testnet.csv").write_text(
            "0x" + "f" * 40 + ",1000000000000000000\n"
        )
        return subprocess.run(
            ["python3", str(root / "scripts" / SOURCE.name), str(upstream), "52101"],
            text=True, capture_output=True, check=False
        )

    def test_valid_four_operator_set(self):
        result = self.run_renderer(records())
        self.assertEqual(result.returncode, 0, result.stderr)
        upstream = Path(result.args[2])
        self.assertTrue((upstream / "validators.conf").exists())
        self.assertTrue((upstream / "scripts" / "validators.js").exists())
        rows = (upstream / "validators.conf").read_text().splitlines()
        self.assertEqual(len(rows), 4)
        self.assertTrue(all(len(row.split(",")) == 5 for row in rows))

    def test_reject_duplicate_operator_id(self):
        rows = records()
        rows[1] = rows[1].replace("operator-2,", "operator-1,")
        result = self.run_renderer(rows)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("distinct operatorId", result.stderr)

    def test_reject_address_reused_across_roles(self):
        rows = records()
        fields = rows[1].split(",")
        fields[1] = ADDRS[0][0]
        rows[1] = ",".join(fields)
        result = self.run_renderer(rows)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("globally unique", result.stderr)

    def test_reject_duplicate_bls_key(self):
        rows = records()
        fields = rows[1].split(",")
        fields[5] = BLS[0]
        rows[1] = ",".join(fields)
        result = self.run_renderer(rows)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("distinct BLS public key", result.stderr)


    def test_reject_less_than_four_validators(self):
        result = self.run_renderer(records()[:3])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("At least four validator entries", result.stderr)

    def test_reject_malformed_bls_key_length(self):
        rows = records()
        fields = rows[0].split(",")
        fields[5] = "ab" * 47
        rows[0] = ",".join(fields)
        result = self.run_renderer(rows)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("BLS public key must be 48-byte hex", result.stderr)

    def test_reject_wrong_validator_field_count(self):
        rows = records()
        rows[0] = ",".join(rows[0].split(",")[:5])
        result = self.run_renderer(rows)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("expected 6 fields", result.stderr)

    def test_reject_chain_id_outside_uint16(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        (root / "scripts").mkdir()
        (root / "config").mkdir()
        upstream = root / "upstream"
        upstream.mkdir()
        shutil.copy2(SOURCE, root / "scripts" / SOURCE.name)
        (root / "config" / "validators.testnet.conf").write_text("\n".join(records()) + "\n")
        (root / "config" / "initial-holders.testnet.csv").write_text(
            "0x" + "f" * 40 + ",1000000000000000000\n"
        )
        result = subprocess.run(
            ["python3", str(root / "scripts" / SOURCE.name), str(upstream), "65536"],
            text=True, capture_output=True, check=False
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must fit uint16", result.stderr)

    def test_reject_duplicate_holder_address(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        (root / "scripts").mkdir()
        (root / "config").mkdir()
        upstream = root / "upstream"
        upstream.mkdir()
        shutil.copy2(SOURCE, root / "scripts" / SOURCE.name)
        (root / "config" / "validators.testnet.conf").write_text("\n".join(records()) + "\n")
        holder = "0x" + "f" * 40
        (root / "config" / "initial-holders.testnet.csv").write_text(
            f"{holder},1000000000000000000\n{holder},2000000000000000000\n"
        )
        result = subprocess.run(
            ["python3", str(root / "scripts" / SOURCE.name), str(upstream), "52101"],
            text=True, capture_output=True, check=False
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Duplicate initial holder address", result.stderr)
 
if __name__ == "__main__":
    unittest.main()
