#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-}"
OUT="${2:-}"
MAX_DEPTH="${3:-6}"
MAX_LINES="${4:-}"

if [[ -z "$ROOT" || -z "$OUT" ]]; then
  echo "usage: treewalk_list.sh <root> <out> [max_depth] [max_lines]" >&2
  exit 2
fi

tmp="${OUT}.tmp"
rm -f "$tmp"

# Deterministic directory list for repeatability across runs.
find "$ROOT" -maxdepth "$MAX_DEPTH" -type d -print 2>/dev/null | LC_ALL=C sort >"$tmp" || true

if [[ -n "$MAX_LINES" && "$MAX_LINES" -gt 0 ]]; then
  head -n "$MAX_LINES" "$tmp" >"$OUT"
  rm -f "$tmp"
else
  mv -f "$tmp" "$OUT"
fi
