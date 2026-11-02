#!/usr/bin/env bash
# Prepare an Ubuntu EC2 host for an Auvra testnet full node.
# This script builds the pinned BSC-derived client but does not generate genesis
# or start a validator. Run from the repository root as the ubuntu user.
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$ROOT/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/ec2-bootstrap-$(date -u +%Y%m%dT%H%M%SZ).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[Auvra] EC2 host bootstrap started at $(date -u --iso-8601=seconds)"
echo "[Auvra] Repository: $ROOT"

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Run this script as the ubuntu user, not root." >&2
  exit 2
fi
if ! grep -qiE 'ubuntu|debian' /etc/os-release; then
  echo "This bootstrap currently supports Ubuntu/Debian only." >&2
  exit 2
fi

echo "[Auvra] Installing base build dependencies..."
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ca-certificates curl git wget build-essential gcc make jq unzip \
  python3 python3-pip python3-venv chrony ufw pkg-config

echo "[Auvra] Enabling time synchronization..."
sudo systemctl enable --now chrony
sudo timedatectl set-ntp true || true

echo "[Auvra] Checking free disk and memory..."
df -h "$ROOT"
free -h

AVAILABLE_GIB="$(df -BG --output=avail "$ROOT" | tail -n1 | tr -dc '0-9')"
if [[ -z "$AVAILABLE_GIB" ]] || (( AVAILABLE_GIB < 80 )); then
  echo "At least 80 GiB free disk is required for this source build; expand EBS before continuing." >&2
  exit 3
fi

GO_VERSION_REQUIRED=1.25
if ! command -v go >/dev/null 2>&1 || ! go version | grep -Eq 'go1\.(25|2[6-9]|[3-9][0-9])'; then
  echo "[Auvra] Installing Go 1.25.0..."
  ARCH="$(dpkg --print-architecture)"
  case "$ARCH" in
    amd64) GO_ARCH=amd64 ;;
    arm64) GO_ARCH=arm64 ;;
    *) echo "Unsupported architecture for Go bootstrap: $ARCH" >&2; exit 2 ;;
  esac
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  curl -fsSLo "$TMP/go.tar.gz" "https://go.dev/dl/go1.25.0.linux-${GO_ARCH}.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "$TMP/go.tar.gz"
  if ! grep -q '/usr/local/go/bin' "$HOME/.profile" 2>/dev/null; then
    printf '\nexport PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"\n' >> "$HOME/.profile"
  fi
  export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"
fi

export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"
echo "[Auvra] Go toolchain:"
go version
git --version
gcc --version | head -n1
make --version | head -n1

echo "[Auvra] Validating Auvra network configuration..."
set +e
python3 scripts/validate-network.py
VALIDATION_STATUS=$?
set -e
if [[ "$VALIDATION_STATUS" -ne 0 && "$VALIDATION_STATUS" -ne 2 ]]; then
  echo "Auvra network configuration has structural errors; stopping before build." >&2
  exit "$VALIDATION_STATUS"
fi
if [[ "$VALIDATION_STATUS" -eq 2 ]]; then
  echo "[Auvra] Configuration is structurally valid but genesis/validator launch gates remain pending."
fi

echo "[Auvra] Building pinned BSC-derived execution client..."
export BSC_VERSION="${BSC_VERSION:-v1.8.1}"
bash scripts/bootstrap-upstream.sh

GETH="$ROOT/.build/bsc/build/bin/geth"
test -x "$GETH"
echo "[Auvra] Client version:"
"$GETH" version

echo "[Auvra] Creating persistent node directory..."
sudo install -d -o "$USER" -g "$USER" -m 700 /home/ubuntu/auvra-validator
install -d -m 700 /home/ubuntu/auvra-validator/data

echo "[Auvra] Configuring host firewall baseline..."
if ! sudo ufw status | grep -q 'Status: active'; then
  sudo ufw allow OpenSSH
  sudo ufw allow 30303/tcp
  sudo ufw allow 30303/udp
  sudo ufw --force enable
fi

echo "[Auvra] Bootstrap complete."
echo "Built client: $GETH"
echo "Persistent datadir: /home/ubuntu/auvra-validator/data"
echo "Log: $LOG_FILE"
echo "No genesis was generated and no validator signing was started."
