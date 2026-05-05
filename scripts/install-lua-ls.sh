#!/usr/bin/env bash
# Bootstrap Lua development tools (lua-language-server, stylua) into .tools/
# inside this nvim config repo. No system install; binaries live under the repo.
#
# Bump versions below (or override via env) to upgrade:
#   LUA_LS_VERSION=3.13.6 STYLUA_VERSION=2.1.0 ./scripts/install-lua-ls.sh

set -euo pipefail

LUA_LS_VERSION="${LUA_LS_VERSION:-3.13.5}"
STYLUA_VERSION="${STYLUA_VERSION:-2.0.2}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TOOLS_DIR="$REPO_ROOT/.tools"

OS="$(uname -s)"
ARCH="$(uname -m)"
case "$OS-$ARCH" in
  Linux-x86_64)   LUA_LS_PLATFORM="linux-x64";    STYLUA_PLATFORM="linux-x86_64"  ;;
  Linux-aarch64)  LUA_LS_PLATFORM="linux-arm64";  STYLUA_PLATFORM="linux-aarch64" ;;
  Darwin-x86_64)  LUA_LS_PLATFORM="darwin-x64";   STYLUA_PLATFORM="macos-x86_64"  ;;
  Darwin-arm64)   LUA_LS_PLATFORM="darwin-arm64"; STYLUA_PLATFORM="macos-aarch64" ;;
  *) echo "Unsupported platform: $OS-$ARCH" >&2; exit 1 ;;
esac

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

install_lua_ls() {
  local dest="$TOOLS_DIR/lua_ls"
  local bin="$dest/bin/lua-language-server"
  if [ -x "$bin" ]; then
    local installed
    installed="$("$bin" --version 2>/dev/null | head -n1 || true)"
    if echo "$installed" | grep -q "$LUA_LS_VERSION"; then
      echo "lua-language-server $LUA_LS_VERSION already installed at $bin"
      return
    fi
    echo "Replacing $installed with $LUA_LS_VERSION"
    rm -rf "$dest"
  fi

  local tarball="lua-language-server-${LUA_LS_VERSION}-${LUA_LS_PLATFORM}.tar.gz"
  local url="https://github.com/LuaLS/lua-language-server/releases/download/${LUA_LS_VERSION}/${tarball}"
  mkdir -p "$dest"
  echo "Downloading $url"
  curl -fsSL "$url" -o "$TMP/$tarball"
  tar -xzf "$TMP/$tarball" -C "$dest"

  if [ ! -x "$bin" ]; then
    echo "Install failed: $bin missing or not executable" >&2
    exit 1
  fi
  echo "Installed lua-language-server $LUA_LS_VERSION at $bin"
}

install_stylua() {
  local dest="$TOOLS_DIR/stylua/bin"
  local bin="$dest/stylua"
  if [ -x "$bin" ]; then
    local installed
    installed="$("$bin" --version 2>/dev/null | head -n1 || true)"
    if echo "$installed" | grep -q "$STYLUA_VERSION"; then
      echo "stylua $STYLUA_VERSION already installed at $bin"
      return
    fi
    echo "Replacing $installed with $STYLUA_VERSION"
    rm -rf "$TOOLS_DIR/stylua"
  fi

  if ! command -v unzip >/dev/null 2>&1; then
    echo "unzip is required to install stylua" >&2
    exit 1
  fi

  local zip="stylua-${STYLUA_PLATFORM}.zip"
  local url="https://github.com/JohnnyMorganz/StyLua/releases/download/v${STYLUA_VERSION}/${zip}"
  mkdir -p "$dest"
  echo "Downloading $url"
  curl -fsSL "$url" -o "$TMP/$zip"
  unzip -q "$TMP/$zip" -d "$dest"
  chmod +x "$bin"

  if [ ! -x "$bin" ]; then
    echo "Install failed: $bin missing or not executable" >&2
    exit 1
  fi
  echo "Installed stylua $STYLUA_VERSION at $bin"
}

install_lua_ls
install_stylua
