#!/usr/bin/env bash
set -euo pipefail
VERSION="${GENESIS_TOOLING_REF:-master}"
DEST="${GENESIS_TOOLING_DIR:-.build/bsc-genesis-contract}"
mkdir -p "$(dirname "$DEST")"
if [[ ! -d "$DEST/.git" ]]; then
  git clone https://github.com/bnb-chain/bsc-genesis-contract.git "$DEST"
fi
git -C "$DEST" fetch origin "$VERSION"
git -C "$DEST" checkout --detach FETCH_HEAD
echo "Official BSC genesis-contract tooling checked out at $DEST"
echo "Read its README. Customize init_holders.js, validators.js and system contract settings for Auvra."
echo "Do not run the generator until Auvra chain IDs, validator public addresses and allocations are reviewed."
