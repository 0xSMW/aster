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
COMPILER_SRC=("$ROOT/asm/compiler/"*.S)

OBJ_FILES=()
for file in "${RUNTIME_SRC[@]}" "${COMPILER_SRC[@]}" "$SRC"; do
    obj="$OUT_DIR/$(basename "${file%.*}").o"
    clang -c "$file" -I"$ROOT/asm/macros" -o "$obj"
    OBJ_FILES+=("$obj")
done

clang "${OBJ_FILES[@]}" -o "$BIN"

echo "built $BIN"
