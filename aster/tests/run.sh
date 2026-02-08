#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${ASTER_TEST_OUT_DIR:-$ROOT/.context/aster/tests/out}"
mkdir -p "$OUT"

ASTER_COMPILER="${ASTER_COMPILER:-$ROOT/tools/build/out/asterc}"
if [[ ! -x "$ASTER_COMPILER" ]]; then
  bash "$ROOT/tools/build/build.sh" "$ROOT/asm/driver/asterc.S" >/dev/null
fi

compile() {
  # Use the build wrapper so tests exercise the current module/preprocess behavior.
  ASTER_COMPILER="$ASTER_COMPILER" "$ROOT/tools/build/asterc.sh" "$1" "$2"
}

check_golden() {
  local base="$1"
  local got="$2"
  local want="$3"
  if [[ -f "$want" ]]; then
    if ! cmp -s "$got" "$want"; then
      echo "FAIL golden $base ($(basename "$want"))" >&2
      diff -u "$want" "$got" >&2 || true
      return 1
    fi
  fi
  return 0
}

status=0

for src in "$ROOT/aster/tests/pass/"*.as; do
  [[ -e "$src" ]] || continue
  base="$(basename "$src" .as)"
  bin="$OUT/$base"
  if ! compile "$src" "$bin" >"$OUT/$base.compile.stdout" 2>"$OUT/$base.compile.stderr"; then
    echo "FAIL pass compile $base" >&2
    status=1
    continue
  fi
  if ! "$bin" >"$OUT/$base.run.stdout" 2>"$OUT/$base.run.stderr"; then
    echo "FAIL pass run $base" >&2
    status=1
    continue
  fi
  if ! check_golden "$base" "$OUT/$base.run.stdout" "$ROOT/aster/tests/pass/$base.stdout"; then
    status=1
    continue
  fi
  if ! check_golden "$base" "$OUT/$base.run.stderr" "$ROOT/aster/tests/pass/$base.stderr"; then
    status=1
    continue
  fi
  echo "ok pass $base"
done

for src in "$ROOT/aster/tests/fail/"*.as; do
  [[ -e "$src" ]] || continue
  base="$(basename "$src" .as)"
  bin="$OUT/$base"
  if compile "$src" "$bin" >"$OUT/$base.compile.stdout" 2>"$OUT/$base.compile.stderr"; then
    echo "FAIL expected compile failure $base" >&2
    status=1
    continue
  fi
  echo "ok fail $base"
done

for src in "$ROOT/aster/tests/leetcode/"*.as; do
  [[ -e "$src" ]] || continue
  base="$(basename "$src" .as)"
  bin="$OUT/leetcode_$base"
  if ! compile "$src" "$bin" >"$OUT/leetcode_$base.compile.stdout" 2>"$OUT/leetcode_$base.compile.stderr"; then
    echo "FAIL leetcode compile $base" >&2
    status=1
    continue
  fi
  if ! "$bin" >"$OUT/leetcode_$base.run.stdout" 2>"$OUT/leetcode_$base.run.stderr"; then
    echo "FAIL leetcode run $base" >&2
    status=1
    continue
  fi
  echo "ok leetcode $base"
done

exit "$status"
