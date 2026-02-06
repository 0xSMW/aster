#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="$ROOT/asm/tests/out"
INC="$ROOT/asm/macros"

mkdir -p "$OUT"

runtime_objs=()
for src in "$ROOT/asm/runtime/"*.S; do
  obj="$OUT/$(basename "$src" .S).o"
  clang -c "$src" -I"$INC" -o "$obj"
  runtime_objs+=("$obj")
done

compiler_objs=()
for src in "$ROOT/asm/compiler/"*.S; do
  obj="$OUT/$(basename "$src" .S).o"
  clang -c "$src" -I"$INC" -o "$obj"
  compiler_objs+=("$obj")
done

status=0
for test in "$ROOT/asm/tests/"*.S; do
  base="$(basename "$test" .S)"
  obj="$OUT/${base}.o"
  bin="$OUT/${base}"
  clang -c "$test" -I"$INC" -o "$obj"
  clang "$obj" "${runtime_objs[@]}" "${compiler_objs[@]}" -o "$bin"
  if "$bin"; then
    echo "ok $base"
  else
    echo "FAIL $base" >&2
    status=1
  fi
done

exit "$status"
