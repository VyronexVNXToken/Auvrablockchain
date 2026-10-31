#!/usr/bin/env bash
set -euo pipefail
VERSION="${BSC_VERSION:-v1.8.1}"
DEST="${BSC_SOURCE_DIR:-.build/bsc}"
[[ "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Use a stable BSC tag such as v1.8.1" >&2; exit 2; }
mkdir -p "$(dirname "$DEST")"
if [[ ! -d "$DEST/.git" ]]; then git clone https://github.com/bnb-chain/bsc.git "$DEST"; fi
git -C "$DEST" fetch --tags origin
git -C "$DEST" checkout --detach "$VERSION"
(
  cd "$DEST"
  export CGO_CFLAGS="${CGO_CFLAGS:--O -D__BLST_PORTABLE__}"
  export CGO_CFLAGS_ALLOW="${CGO_CFLAGS_ALLOW:--O}"
  make geth
)
echo "Client built at $DEST/build/bin/geth"
echo "Verify upstream release signatures and test Auvra-specific compatibility before deployment."
