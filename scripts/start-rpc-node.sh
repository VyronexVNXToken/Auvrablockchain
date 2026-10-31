#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GETH_BIN="${AUVRA_GETH_BIN:-$ROOT/.build/bsc/build/bin/geth}"
DATA_DIR="${AUVRA_DATA_DIR:?Set AUVRA_DATA_DIR to an initialized persistent node data directory}"
NETWORK_ID="${AUVRA_NETWORK_ID:-52101}"
P2P_PORT="${AUVRA_P2P_PORT:-30303}"
RPC_BIND="${AUVRA_RPC_BIND:-127.0.0.1}"
HTTP_PORT="${AUVRA_HTTP_PORT:-8545}"
WS_PORT="${AUVRA_WS_PORT:-8546}"
CACHE_MIB="${AUVRA_CACHE_MIB:-2048}"

[[ -x "$GETH_BIN" ]] || { echo "Missing BSC-derived geth binary: $GETH_BIN" >&2; exit 2; }
[[ -d "$DATA_DIR/geth/chaindata" ]] || { echo "Node datadir is not initialized. Run scripts/init-node.sh first." >&2; exit 2; }
[[ "$NETWORK_ID" =~ ^[0-9]+$ ]] || { echo "AUVRA_NETWORK_ID must be numeric." >&2; exit 2; }
[[ "$P2P_PORT" =~ ^[0-9]+$ && "$HTTP_PORT" =~ ^[0-9]+$ && "$WS_PORT" =~ ^[0-9]+$ ]] || { echo "Ports must be numeric." >&2; exit 2; }

if [[ "$RPC_BIND" == "0.0.0.0" || "$RPC_BIND" == "::" ]]; then
  echo "WARNING: RPC is being bound to all interfaces. Put it behind a firewall and TLS reverse proxy." >&2
fi

exec "$GETH_BIN" \
  --datadir "$DATA_DIR" \
  --networkid "$NETWORK_ID" \
  --port "$P2P_PORT" \
  --syncmode full \
  --cache "$CACHE_MIB" \
  --http \
  --http.addr "$RPC_BIND" \
  --http.port "$HTTP_PORT" \
  --http.api eth,net,web3 \
  --http.vhosts localhost \
  --http.corsdomain "" \
  --ws \
  --ws.addr "$RPC_BIND" \
  --ws.port "$WS_PORT" \
  --ws.api eth,net,web3 \
  --ws.origins localhost
