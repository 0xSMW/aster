#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-}"
OUT="${2:-}"
MAX_DEPTH="${3:-6}"

if [[ -z "$ROOT" || -z "$OUT" ]]; then
  echo "usage: treewalk_list.sh <root> <out> [max_depth]" >&2
  exit 2
fi

python3 - <<'PY' "$ROOT" "$OUT" "$MAX_DEPTH"
import os
import sys

root = os.path.abspath(sys.argv[1])
out = sys.argv[2]
max_depth = int(sys.argv[3])

base_depth = root.rstrip(os.sep).count(os.sep)

def onerror(err):
    # Skip permission errors; keep list generation going.
    pass

with open(out, "w") as f:
    for dirpath, dirnames, _ in os.walk(root, topdown=True, onerror=onerror, followlinks=False):
        depth = dirpath.rstrip(os.sep).count(os.sep) - base_depth
        f.write(dirpath + "\n")
        if depth >= max_depth:
            dirnames[:] = []
        else:
            dirnames.sort()
PY
