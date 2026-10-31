#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GETH_BIN="${AUVRA_GETH_BIN:-$ROOT/.build/bsc/build/bin/geth}"
DATA_DIR="${AUVRA_DATA_DIR:?Set AUVRA_DATA_DIR to this validator's initialized data directory}"
VALIDATOR_ADDRESS="${AUVRA_VALIDATOR_ADDRESS:?Set AUVRA_VALIDATOR_ADDRESS to the validator's consensus EVM address}"
PASSWORD_FILE="${AUVRA_PASSWORD_FILE:?Set AUVRA_PASSWORD_FILE to a protected file containing this validator account password}"
BOOTNODES="${AUVRA_BOOTNODES:?Set AUVRA_BOOTNODES to one or more enode:// bootnode URLs}"
NETWORK_ID="${AUVRA_NETWORK_ID:-52101}"
P2P_PORT="${AUVRA_P2P_PORT:-30303}"
VERBOSITY="${AUVRA_VERBOSITY:-3}"

[[ -x "$GETH_BIN" ]] || { echo "Missing BSC-derived geth binary: $GETH_BIN" >&2; exit 2; }
[[ -d "$DATA_DIR/geth/chaindata" ]] || { echo "Node datadir is not initialized from the approved Auvra genesis." >&2; exit 2; }
[[ -s "$PASSWORD_FILE" ]] || { echo "Password file is missing or empty." >&2; exit 2; }
[[ "$VALIDATOR_ADDRESS" =~ ^0x[0-9a-fA-F]{40}$ ]] || { echo "Validator address must be a 20-byte EVM address." >&2; exit 2; }
[[ "$NETWORK_ID" =~ ^[0-9]+$ && "$P2P_PORT" =~ ^[0-9]+$ ]] || { echo "Network ID and P2P port must be numeric." >&2; exit 2; }

ARGS=(
  --datadir "$DATA_DIR"
  --networkid "$NETWORK_ID"
  --port "$P2P_PORT"
  --bootnodes "$BOOTNODES"
  --verbosity "$VERBOSITY"
  --mine
  --unlock "$VALIDATOR_ADDRESS"
  --miner.etherbase "$VALIDATOR_ADDRESS"
  --password "$PASSWORD_FILE"
)

# BLS wallet password is only needed when enabling the client's BLS voting /
# fast-finality features. It is deliberately optional for basic Parlia sealing.
if [[ -n "${AUVRA_BLS_PASSWORD_FILE:-}" ]]; then
  [[ -s "$AUVRA_BLS_PASSWORD_FILE" ]] || { echo "BLS password file is missing or empty." >&2; exit 2; }
  ARGS+=(--blspassword "$AUVRA_BLS_PASSWORD_FILE")
fi

echo "Starting Auvra validator process for public address $VALIDATOR_ADDRESS"
echo "RPC APIs are not enabled by this launcher."
exec "$GETH_BIN" "${ARGS[@]}"
