#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-}"
OUT="${2:-}"
DEPTH="${3:-6}"

if [[ -z "$ROOT" || -z "$OUT" ]]; then
    echo "usage: fswalk_list.sh <root> <out_list> [depth]" >&2
    exit 2
fi

find "$ROOT" -maxdepth "$DEPTH" -print 2>/dev/null > "$OUT" || true
