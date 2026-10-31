#!/usr/bin/env python3
"""Validate Auvra network identity and launch prerequisites."""
import json, re, sys
from pathlib import Path
P = Path(__file__).resolve().parents[1] / "config" / "auvra-network.json"
def fail(s):
    print("ERROR:", s, file=sys.stderr); raise SystemExit(1)
try: c = json.loads(P.read_text())
except Exception as e: fail(f"cannot parse config: {e}")
if c.get("name") != "Auvra": fail("network name must be Auvra")
if c.get("nativeCurrency") != {"name":"Auvra","symbol":"AUR","decimals":18}: fail("native currency must be Auvra (AUR), 18 decimals")
if c.get("consensus") != "parlia" or c.get("execution") != "evm": fail("expected Parlia PoSA and EVM")
ids = c.get("chainIds", {})
for n in ("testnet","mainnet"):
    v=ids.get(n)
    if v is not None and (not isinstance(v,int) or isinstance(v,bool) or v <= 0): fail(f"{n} chain ID must be a positive integer")
if ids.get("testnet") is not None and ids.get("testnet") > 65535: fail("testnet chain ID must fit the current BSC Parlia system-contract uint16 field (1..65535)")
if ids.get("testnet") is not None and ids.get("testnet")==ids.get("mainnet"): fail("testnet and mainnet IDs must differ")
validators=c.get("validators",{}).get("addresses",[])
for a in validators:
    if not isinstance(a,str) or not re.fullmatch(r"0x[0-9a-fA-F]{40}",a): fail(f"invalid validator address {a!r}")
if len({a.lower() for a in validators}) != len(validators): fail("duplicate validator addresses")
g=c.get("genesis",{})
if g.get("sha256") and not re.fullmatch(r"[0-9a-fA-F]{64}",g["sha256"]): fail("genesis SHA-256 must be 64 hex chars")
if g.get("approved") and (not g.get("generated") or not g.get("sha256")): fail("cannot approve absent genesis")
print("Auvra configuration structure is valid.")
missing=[]
if ids.get("testnet") is None: missing.append("testnet chain ID")
if ids.get("mainnet") is None: missing.append("mainnet chain ID")
if not validators: missing.append("initial validator addresses")
if not g.get("approved"): missing.append("generated, verified and approved genesis")
if missing:
    print("NOT LAUNCH READY — still required: " + ", ".join(missing))
    raise SystemExit(2)
print("Configuration launch gates passed. This does not replace a live network test.")
