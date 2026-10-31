#!/usr/bin/env bash
set -euo pipefail
# Immutable upstream BSC source revision reviewed for this Auvra scaffold.
BSC_COMMIT="${AUVRA_BSC_COMMIT:-947ba1cb1ef05d4a5f71b738113a3d8b4c16f6b7}"
DEST="${BSC_SOURCE_DIR:-.build/bsc}"
[[ "$BSC_COMMIT" =~ ^[0-9a-f]{40}$ ]] || { echo "AUVRA_BSC_COMMIT must be a full immutable 40-character commit SHA" >&2; exit 2; }
mkdir -p "$(dirname "$DEST")"
if [[ ! -d "$DEST/.git" ]]; then git clone https://github.com/bnb-chain/bsc.git "$DEST"; fi
git -C "$DEST" fetch --no-tags origin "$BSC_COMMIT"
git -C "$DEST" checkout --detach "$BSC_COMMIT"
[[ "$(git -C "$DEST" rev-parse HEAD)" == "$BSC_COMMIT" ]]
(
  cd "$DEST"
  export CGO_CFLAGS="${CGO_CFLAGS:--O -D__BLST_PORTABLE__}"
  export CGO_CFLAGS_ALLOW="${CGO_CFLAGS_ALLOW:--O -D__BLST_PORTABLE__}"
  make geth
)
echo "Built pinned BSC-derived client: $DEST/build/bin/geth"
echo "This binary still requires Auvra's generated genesis and validator configuration."
