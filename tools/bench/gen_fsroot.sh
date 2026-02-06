#!/usr/bin/env bash
set -euo pipefail

# Deterministically generate a filesystem tree for IO benchmarks.
# Intended for local perf runs (not used by CI gate).
#
# Usage:
#   tools/bench/gen_fsroot.sh <out_dir> [dirs] [files_per_dir]
#
# Defaults are chosen to generate a few thousand files quickly.

OUT_DIR="${1:-}"
if [[ -z "$OUT_DIR" ]]; then
  echo "usage: gen_fsroot.sh <out_dir> [dirs] [files_per_dir]" >&2
  exit 2
fi

DIRS="${2:-64}"
FILES="${3:-64}"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

printf "aster fsroot seed\n" >"$OUT_DIR/.aster_seed"

for ((i = 0; i < DIRS; i++)); do
  d="$(printf 'd%03d' "$i")"
  mkdir -p "$OUT_DIR/$d/sub0" "$OUT_DIR/$d/sub1/nested"
  for ((j = 0; j < FILES; j++)); do
    f="$(printf 'f%04d.txt' "$j")"
    printf "dir=%s file=%s\n" "$d" "$f" >"$OUT_DIR/$d/$f"
    printf "dir=%s sub0 file=%s\n" "$d" "$f" >"$OUT_DIR/$d/sub0/$f"
    printf "dir=%s nested file=%s\n" "$d" "$f" >"$OUT_DIR/$d/sub1/nested/$f"
  done
done

# Add a few deterministic symlinks.
ln -s "d000/f0000.txt" "$OUT_DIR/link_to_d000_f0000" 2>/dev/null || true
ln -s "d001/sub0/f0001.txt" "$OUT_DIR/link_to_d001_sub0_f0001" 2>/dev/null || true

echo "generated fsroot: $OUT_DIR (dirs=$DIRS files_per_dir=$FILES)"

