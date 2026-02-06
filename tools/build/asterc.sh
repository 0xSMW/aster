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

IN="$1"
OUT="$2"

if [[ -n "${ASTER_CACHE:-}" && "${ASTER_CACHE}" != "0" ]]; then
    CACHE_DIR="${ASTER_CACHE_DIR:-$ROOT/.context/build/cache}"
    mkdir -p "$CACHE_DIR"

    src_sha="$(shasum -a 256 "$IN" | awk '{print $1}')"
    # Compiler binary hash is part of the cache key to avoid stale outputs after upgrades.
    cc_sha="$(shasum -a 256 "$ASTER_COMPILER" | awk '{print $1}')"
    key="${src_sha}_${cc_sha}"
    entry="$CACHE_DIR/$key"
    bin_cache="$entry/out"
    ll_cache="$entry/out.ll"

    if [[ -x "$bin_cache" ]]; then
        cp -f "$bin_cache" "$OUT"
        if [[ -f "$ll_cache" ]]; then
            cp -f "$ll_cache" "${OUT}.ll"
        fi
        exit 0
    fi

    mkdir -p "$entry"
    tmp_out="$bin_cache"
    "$ASTER_COMPILER" "$IN" "$tmp_out"
    cp -f "$tmp_out" "$OUT"
    if [[ -f "${tmp_out}.ll" ]]; then
        cp -f "${tmp_out}.ll" "$ll_cache"
        cp -f "${tmp_out}.ll" "${OUT}.ll"
    fi
    exit 0
fi

"$ASTER_COMPILER" "$IN" "$OUT"
