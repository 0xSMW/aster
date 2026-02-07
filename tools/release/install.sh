#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

usage() {
  cat >&2 <<'TXT'
usage: tools/release/install.sh [--prefix <dir>]

Installs aster tools into <prefix>/bin:
- aster  (CLI wrapper)
- asterc (compiler)
- asterfmt

Defaults:
  prefix: $HOME/.local
TXT
}

prefix="${PREFIX:-$HOME/.local}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix)
      prefix="${2:?missing arg to --prefix}"
      shift 2
      ;;
    -h|--help|help)
      usage
      exit 0
      ;;
    *)
      echo "install: unknown arg: $1" >&2
      usage
      exit 2
      ;;
  esac
done

bin_dir="$prefix/bin"
mkdir -p "$bin_dir"

# Ensure compiler exists for this host.
if [[ ! -x "$ROOT/tools/build/out/asterc" ]]; then
  bash "$ROOT/tools/build/build.sh" "$ROOT/asm/driver/asterc.S" >/dev/null
fi

install_one() {
  local src="$1"
  local dst="$2"
  cp -f "$src" "$dst"
  chmod +x "$dst" 2>/dev/null || true
}

install_one "$ROOT/tools/aster/aster" "$bin_dir/aster"
install_one "$ROOT/tools/build/out/asterc" "$bin_dir/asterc"
install_one "$ROOT/tools/asterfmt/asterfmt" "$bin_dir/asterfmt"

echo "installed:"
echo "- $bin_dir/aster"
echo "- $bin_dir/asterc"
echo "- $bin_dir/asterfmt"

