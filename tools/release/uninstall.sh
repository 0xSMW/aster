#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'TXT'
usage: tools/release/uninstall.sh [--prefix <dir>]

Removes:
- <prefix>/bin/aster
- <prefix>/bin/asterc
- <prefix>/bin/asterfmt

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
      echo "uninstall: unknown arg: $1" >&2
      usage
      exit 2
      ;;
  esac
done

bin_dir="$prefix/bin"
rm -f "$bin_dir/aster" "$bin_dir/asterc" "$bin_dir/asterfmt"
echo "removed:"
echo "- $bin_dir/aster"
echo "- $bin_dir/asterc"
echo "- $bin_dir/asterfmt"

