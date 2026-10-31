#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$ROOT/config/auvra-network.json"
CONFIG_CHAIN_ID="$(python3 - "$CONFIG" <<'PY'
import json,sys
print(json.load(open(sys.argv[1]))["chainIds"]["testnet"] or "")
PY
)"
CHAIN_ID="${AUVRA_TESTNET_CHAIN_ID:-$CONFIG_CHAIN_ID}"
[[ -n "$CHAIN_ID" ]] || { echo "Set chainIds.testnet in config/auvra-network.json first." >&2; exit 2; }
[[ "$CHAIN_ID" == "$CONFIG_CHAIN_ID" ]] || { echo "AUVRA_TESTNET_CHAIN_ID must match config/auvra-network.json ($CONFIG_CHAIN_ID)." >&2; exit 2; }
ADMIN="${AUVRA_SYSTEM_ADMIN_ADDRESS:?Set AUVRA_SYSTEM_ADMIN_ADDRESS to a reviewed testnet system-contract protector address}"
GENESIS_COMMIT="${AUVRA_GENESIS_TOOLING_COMMIT:-84641812a013eda1593e058aeed4dc116c7746eb}"
BSC_COMMIT="${AUVRA_BSC_COMMIT:-947ba1cb1ef05d4a5f71b738113a3d8b4c16f6b7}"
WORK="${AUVRA_GENESIS_WORKDIR:-$ROOT/.build/bsc-genesis-contract}"
OUT="$ROOT/artifacts/auvra-testnet"
[[ "$CHAIN_ID" =~ ^[0-9]+$ ]] && (( CHAIN_ID > 0 && CHAIN_ID <= 65535 )) || { echo "Chain ID must be 1..65535 for current BSC system-contract field." >&2; exit 2; }
[[ "$ADMIN" =~ ^0x[0-9a-fA-F]{40}$ ]] || { echo "System admin must be a 20-byte EVM address." >&2; exit 2; }
[[ "$GENESIS_COMMIT" =~ ^[0-9a-f]{40}$ ]] || { echo "Genesis tooling commit must be a full SHA." >&2; exit 2; }
[[ "$BSC_COMMIT" =~ ^[0-9a-f]{40}$ ]] || { echo "BSC client commit must be a full SHA." >&2; exit 2; }
mkdir -p "$(dirname "$WORK")" "$OUT"
if [[ ! -d "$WORK/.git" ]]; then git clone https://github.com/bnb-chain/bsc-genesis-contract.git "$WORK"; fi
git -C "$WORK" fetch --no-tags origin "$GENESIS_COMMIT"
git -C "$WORK" checkout --detach "$GENESIS_COMMIT"
[[ "$(git -C "$WORK" rev-parse HEAD)" == "$GENESIS_COMMIT" ]]
python3 "$ROOT/scripts/render-genesis-inputs.py" "$WORK" "$CHAIN_ID"
(
  cd "$WORK"
  npm ci
  forge install --no-git foundry-rs/forge-std@v1.7.3
  poetry install
  poetry run python -m scripts.generate dev \
    --dev-chain-id "$CHAIN_ID" \
    --stake-hub-protector "address($ADMIN)" \
    --governor-protector "address($ADMIN)" \
    --token-recover-portal-protector "address($ADMIN)" \
    --block-interval "3 seconds" \
    --max-elected-validators "21"
  cp genesis-dev.json "$OUT/genesis.json"
  poetry run python -m scripts.generate recover
)
python3 - "$OUT/genesis.json" "$CHAIN_ID" "$ROOT/config/validators.testnet.conf" "$ROOT/config/initial-holders.testnet.csv" <<'PY'
import csv, json, re, sys
p, expected, validator_path, holders_path = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4]
with open(p) as f:
    d = json.load(f)
if d.get("config", {}).get("chainId") != expected:
    raise SystemExit("Generated genesis chainId does not match requested Auvra ID")
validators = []
for raw in open(validator_path):
    line = raw.strip()
    if line and not line.startswith("#"):
        validators.append(line.split(","))
if len(validators) < 4:
    raise SystemExit("Generated genesis must include at least four configured validators")
extra = d.get("extraData", "")
expected_extra_length = 2 + 64 + (40 * len(validators)) + 130
if not re.fullmatch(r"0x[0-9a-fA-F]+", extra) or len(extra) != expected_extra_length:
    raise SystemExit(f"Genesis extraData length does not match {len(validators)} configured Parlia validators")
alloc = {str(k).lower().removeprefix("0x"): v for k, v in d.get("alloc", {}).items()}
for a in ("0000000000000000000000000000000000001000", "0000000000000000000000000000000000001001", "0000000000000000000000000000000000001002"):
    if not alloc.get(a, {}).get("code"):
        raise SystemExit(f"Missing Parlia system contract bytecode at 0x{a}")
with open(holders_path, newline="") as f:
    for row in csv.reader(f):
        if not row or row[0].strip().startswith("#"):
            continue
        address, balance = row[0].strip(), int(row[1].strip())
        entry = alloc.get(address.lower().removeprefix("0x"))
        if entry is None or int(entry.get("balance", "0x0"), 16) != balance:
            raise SystemExit(f"Genesis allocation missing or incorrect for initial holder {address}")
print(f"Genesis verified: chain ID {expected}, {len(validators)} validators, holder allocations and core system predeploys.")
PY
sha256sum "$OUT/genesis.json" | tee "$OUT/genesis.sha256"
printf '%s\n' "$GENESIS_COMMIT" > "$OUT/genesis-tooling.commit"
printf '%s\n' "$BSC_COMMIT" > "$OUT/bsc-client.commit"
printf '%s\n' "$CHAIN_ID" > "$OUT/chain-id"
echo "Auvra testnet genesis generated. This does NOT start validators or publish an RPC."
