#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC="${1:-$ROOT/asm/tests/hello.S}"
OUT_DIR="$ROOT/tools/build/out"

mkdir -p "$OUT_DIR"

BASE_NAME="$(basename "$SRC")"
BASE_NAME="${BASE_NAME%.*}"
BIN="$OUT_DIR/$BASE_NAME"

shopt -s nullglob
RUNTIME_SRC=("$ROOT/asm/runtime/"*.S)
COMPILER_SRC=("$ROOT/asm/compiler/"*.S "$ROOT/asm/compiler/"*.c)

OBJ_FILES=()
LINK_FILES=()
for file in "${RUNTIME_SRC[@]}" "${COMPILER_SRC[@]}" "$SRC"; do
    obj="$OUT_DIR/$(basename "${file%.*}").o"
    clang -c "$file" -O3 -I"$ROOT/asm/macros" -o "$obj"
    OBJ_FILES+=("$obj")
    # Runtime helper objects (`*_rt.c`) are meant to be linked into produced
    # Aster binaries via `ASTER_LINK_OBJ`, not into the compiler binary itself.
    if [[ "$file" == "$ROOT/asm/compiler/"*_rt.c ]]; then
        continue
    fi
    LINK_FILES+=("$obj")
done

clang "${LINK_FILES[@]}" -o "$BIN"

echo "built $BIN"
