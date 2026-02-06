#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${FUZZ_OUT_DIR:-$ROOT/.context/fuzz/out}"
mkdir -p "$OUT"

ITERS="${FUZZ_ITERS:-200}"
MAX_BYTES="${FUZZ_MAX_BYTES:-256}"

ASTER_COMPILER="${ASTER_COMPILER:-$ROOT/tools/build/out/asterc}"
if [[ ! -x "$ASTER_COMPILER" ]]; then
  bash "$ROOT/tools/build/build.sh" "$ROOT/asm/driver/asterc.S" >/dev/null
fi

status=0
for i in $(seq 1 "$ITERS"); do
  src="$OUT/case_${i}.as"
  bin="$OUT/case_${i}.bin"
  # Random bytes, but ensure there's at least one newline so the lexer/parser hits indentation paths.
  head -c "$MAX_BYTES" /dev/urandom >"$src" || true
  printf '\n' >>"$src"

  set +e
  "$ASTER_COMPILER" "$src" "$bin" >/dev/null 2>"$OUT/case_${i}.stderr"
  rc=$?
  set -e

  # Treat signals/crashes as failure (bash convention: 128+signal).
  if [[ "$rc" -ge 128 ]]; then
    echo "FAIL: compiler crashed (rc=$rc) on $src" >&2
    status=1
    break
  fi
done

if [[ "$status" -eq 0 ]]; then
  echo "ok fuzz ($ITERS cases)"
fi
exit "$status"

