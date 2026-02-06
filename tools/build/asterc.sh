#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [[ $# -ne 2 ]]; then
    echo "usage: asterc.sh <input.as> <output.S>" >&2
    exit 2
fi

"$ROOT/tools/build/asterc.py" "$1" "$2"
