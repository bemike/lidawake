#!/bin/bash
# Install lidawake CLI to /usr/local/bin (or ~/.local/bin if no write to /usr/local)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
PREFIX="${PREFIX:-/usr/local}"
BIN="$PREFIX/bin"

if [ ! -w "$BIN" ] 2>/dev/null; then
  if mkdir -p "$BIN" 2>/dev/null && [ -w "$BIN" ]; then
    :
  else
    PREFIX="$HOME/.local"
    BIN="$PREFIX/bin"
    mkdir -p "$BIN"
    echo "无 /usr/local 写权限，改装到 $BIN"
    echo "请确保 PATH 含有: $BIN"
  fi
fi

# Keep watch script next to the real binary (not only the symlink target name)
LIB="$PREFIX/lib/lidawake"
mkdir -p "$LIB"
install -m 755 "$ROOT/bin/lidawake" "$LIB/lidawake"
install -m 755 "$ROOT/bin/lid-display-watch.sh" "$LIB/lid-display-watch.sh"
ln -sfn "$LIB/lidawake" "$BIN/lidawake"

echo "已安装: $BIN/lidawake"
"$BIN/lidawake" help
