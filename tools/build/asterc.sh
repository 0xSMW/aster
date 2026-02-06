#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [[ $# -ne 2 ]]; then
    echo "usage: asterc.sh <input.as> <output>" >&2
    exit 2
fi

ASTER_COMPILER="${ASTER_COMPILER:-$ROOT/tools/build/out/asterc}"
if [[ ! -x "$ASTER_COMPILER" ]]; then
    echo "asterc not found or not executable: $ASTER_COMPILER" >&2
    echo "Build it (once implemented) via: tools/build/build.sh asm/driver/asterc.S" >&2
    exit 2
fi

"$ASTER_COMPILER" "$1" "$2"
