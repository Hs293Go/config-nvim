#!/usr/bin/env bash
# Download lua-language-server into .tools/lua_ls/ inside this nvim config
# repo. No system install; the binary lives entirely under the repo.
#
# Bump LUA_LS_VERSION below (or override via env) to upgrade.
#   LUA_LS_VERSION=3.13.6 ./scripts/install-lua-ls.sh

set -euo pipefail

LUA_LS_VERSION="${LUA_LS_VERSION:-3.13.5}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEST="$REPO_ROOT/.tools/lua_ls"
BIN="$DEST/bin/lua-language-server"

OS="$(uname -s)"
ARCH="$(uname -m)"
case "$OS-$ARCH" in
  Linux-x86_64)   PLATFORM="linux-x64"   ;;
  Linux-aarch64)  PLATFORM="linux-arm64" ;;
  Darwin-x86_64)  PLATFORM="darwin-x64"  ;;
  Darwin-arm64)   PLATFORM="darwin-arm64";;
  *) echo "Unsupported platform: $OS-$ARCH" >&2; exit 1 ;;
esac

if [ -x "$BIN" ]; then
  INSTALLED="$("$BIN" --version 2>/dev/null | head -n1 || true)"
  if echo "$INSTALLED" | grep -q "$LUA_LS_VERSION"; then
    echo "lua-language-server $LUA_LS_VERSION already installed at $BIN"
    exit 0
  fi
  echo "Replacing $INSTALLED with $LUA_LS_VERSION"
  rm -rf "$DEST"
fi

TARBALL="lua-language-server-${LUA_LS_VERSION}-${PLATFORM}.tar.gz"
URL="https://github.com/LuaLS/lua-language-server/releases/download/${LUA_LS_VERSION}/${TARBALL}"

mkdir -p "$DEST"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Downloading $URL"
curl -fsSL "$URL" -o "$TMP/$TARBALL"
tar -xzf "$TMP/$TARBALL" -C "$DEST"

if [ ! -x "$BIN" ]; then
  echo "Install failed: $BIN missing or not executable" >&2
  exit 1
fi

echo "Installed lua-language-server $LUA_LS_VERSION at $BIN"
