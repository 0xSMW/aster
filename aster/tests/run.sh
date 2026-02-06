#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${ASTER_TEST_OUT_DIR:-$ROOT/.context/aster/tests/out}"
mkdir -p "$OUT"

ASTER_COMPILER="${ASTER_COMPILER:-$ROOT/tools/build/out/asterc}"
if [[ ! -x "$ASTER_COMPILER" ]]; then
  bash "$ROOT/tools/build/build.sh" "$ROOT/asm/driver/asterc.S" >/dev/null
fi

status=0

for src in "$ROOT/aster/tests/pass/"*.as; do
  [[ -e "$src" ]] || continue
  base="$(basename "$src" .as)"
  bin="$OUT/$base"
  if ! "$ASTER_COMPILER" "$src" "$bin" >"$OUT/$base.compile.stdout" 2>"$OUT/$base.compile.stderr"; then
    echo "FAIL pass compile $base" >&2
    status=1
    continue
  fi
  if ! "$bin" >"$OUT/$base.run.stdout" 2>"$OUT/$base.run.stderr"; then
    echo "FAIL pass run $base" >&2
    status=1
    continue
  fi
  echo "ok pass $base"
done

for src in "$ROOT/aster/tests/fail/"*.as; do
  [[ -e "$src" ]] || continue
  base="$(basename "$src" .as)"
  bin="$OUT/$base"
  if "$ASTER_COMPILER" "$src" "$bin" >"$OUT/$base.compile.stdout" 2>"$OUT/$base.compile.stderr"; then
    echo "FAIL expected compile failure $base" >&2
    status=1
    continue
  fi
  echo "ok fail $base"
done

exit "$status"

