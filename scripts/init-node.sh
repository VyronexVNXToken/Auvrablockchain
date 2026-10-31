#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GETH_BIN="${AUVRA_GETH_BIN:-$ROOT/.build/bsc/build/bin/geth}"
GENESIS="${AUVRA_GENESIS_FILE:-$ROOT/artifacts/auvra-testnet/genesis.json}"
EXPECTED_SHA="${AUVRA_GENESIS_SHA256:-$ROOT/artifacts/auvra-testnet/genesis.sha256}"
DATA_DIR="${AUVRA_DATA_DIR:?Set AUVRA_DATA_DIR to a persistent node data directory}"
[[ -x "$GETH_BIN" ]] || { echo "Missing executable client: $GETH_BIN (run scripts/bootstrap-upstream.sh)" >&2; exit 2; }
[[ -s "$GENESIS" ]] || { echo "Missing Auvra genesis: $GENESIS (generate and approve it first)" >&2; exit 2; }
[[ -s "$EXPECTED_SHA" ]] || { echo "Missing approved genesis checksum file: $EXPECTED_SHA" >&2; exit 2; }
EXPECTED="$(awk 'NR==1 {print $1}' "$EXPECTED_SHA")"
ACTUAL="$(sha256sum "$GENESIS" | awk '{print $1}')"
[[ "$EXPECTED" =~ ^[0-9a-f]{64}$ && "$ACTUAL" == "$EXPECTED" ]] || { echo "Genesis SHA-256 mismatch; refusing to initialize node." >&2; exit 3; }
install -d -m 700 "$DATA_DIR"
"$GETH_BIN" --datadir "$DATA_DIR" init "$GENESIS"
echo "Node initialized from verified Auvra genesis."
echo "This command does not start the node or configure validator signing/RPC exposure."
