#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
OUT="${ASTER_IR_TEST_OUT_DIR:-$ROOT/.context/aster/tests/ir/out}"
mkdir -p "$OUT"

ASTER_COMPILER="${ASTER_COMPILER:-$ROOT/tools/build/out/asterc}"
if [[ ! -x "$ASTER_COMPILER" ]]; then
  bash "$ROOT/tools/build/build.sh" "$ROOT/asm/driver/asterc.S" >/dev/null
fi

compile() {
  ASTER_COMPILER="$ASTER_COMPILER" "$ROOT/tools/build/asterc.sh" "$1" "$2"
}

want_dir="$ROOT/aster/tests/ir"
src="$want_dir/dump_smoke.as"
base="dump_smoke"
bin="$OUT/$base.bin"
ast="$OUT/$base.ast"
hir="$OUT/$base.hir"

rm -f "$bin" "$bin.ll" "$ast" "$hir"

ASTER_DUMP_AST="$ast" ASTER_DUMP_HIR="$hir" compile "$src" "$bin" >/dev/null 2>"$OUT/$base.compile.stderr"

cmp -s "$ast" "$want_dir/$base.ast" || { echo "FAIL ast dump ($base)" >&2; diff -u "$want_dir/$base.ast" "$ast" >&2 || true; exit 1; }
cmp -s "$hir" "$want_dir/$base.hir" || { echo "FAIL hir dump ($base)" >&2; diff -u "$want_dir/$base.hir" "$hir" >&2 || true; exit 1; }

echo "ok ir_dumps $base"
