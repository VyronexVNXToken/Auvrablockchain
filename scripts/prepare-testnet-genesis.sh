#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHAIN_ID="${AUVRA_TESTNET_CHAIN_ID:?Set AUVRA_TESTNET_CHAIN_ID to an approved, collision-checked chain ID (1..65535)}"
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
python3 - "$OUT/genesis.json" "$CHAIN_ID" <<'PY'
import json,sys
p,expected=sys.argv[1],int(sys.argv[2])
d=json.load(open(p))
if d.get("config",{}).get("chainId") != expected:
    raise SystemExit("Generated genesis chainId does not match requested Auvra ID")
if not d.get("extraData","").startswith("0x") or len(d.get("extraData","")) < 2+64+130:
    raise SystemExit("Genesis extraData does not contain expected Parlia vanity/validator/seal fields")
for a in ("0x0000000000000000000000000000000000001000","0x0000000000000000000000000000000000001001","0x0000000000000000000000000000000000001002"):
    if not d.get("alloc",{}).get(a,{}).get("code"):
        raise SystemExit(f"Missing Parlia system contract bytecode at {a}")
print("Genesis structure, chain ID, validator extraData and core system predeploys verified.")
PY
sha256sum "$OUT/genesis.json" | tee "$OUT/genesis.sha256"
printf '%s\n' "$GENESIS_COMMIT" > "$OUT/genesis-tooling.commit"
printf '%s\n' "$BSC_COMMIT" > "$OUT/bsc-client.commit"
printf '%s\n' "$CHAIN_ID" > "$OUT/chain-id"
echo "Auvra testnet genesis generated. This does NOT start validators or publish an RPC."
