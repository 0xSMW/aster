#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

OUT_DIR="${ML_BENCH_OUT_DIR:-$ROOT/.context/ml/bench/out}"
mkdir -p "$OUT_DIR"

ASTER_COMPILER="${ASTER_COMPILER:-$ROOT/tools/build/out/asterc}"
if [[ ! -x "$ASTER_COMPILER" ]]; then
  bash "$ROOT/tools/build/build.sh" "$ROOT/asm/driver/asterc.S" >/dev/null
fi

now_ns() {
  python3 - <<'PY'
import time
print(time.time_ns())
PY
}

median_u64() {
  sort -n | awk '{a[NR]=$1} END{if(NR==0) exit 2; print a[int((NR+1)/2)]}'
}

echo "Toolchains:"
echo "- host: $(uname -a)"
echo "- clang: $(clang --version | head -n 1)"
echo "- rustc: $(rustc --version)"
echo "- python3: $(python3 --version)"
echo ""

RUNS="${ML_BENCH_RUNS:-7}"
BENCHES=(
  autograd_matmul
  train_mlp
  sdpa_forward
)

for bench in "${BENCHES[@]}"; do
  SRC="$ROOT/aster/bench/ml/$bench.as"
  BIN="$OUT_DIR/aster_$bench"

  # Compile-time (clean + cached no-op) via ASTER_CACHE.
  CACHE_DIR="$OUT_DIR/cache_$bench"
  rm -rf "$CACHE_DIR"
  mkdir -p "$CACHE_DIR"

  rm -f "$BIN" "$BIN.ll"
  t0="$(now_ns)"
  ASTER_CACHE=1 ASTER_CACHE_DIR="$CACHE_DIR" "$ASTER_COMPILER" "$SRC" "$BIN" >/dev/null
  t1="$(now_ns)"
  clean_ns="$((t1 - t0))"

  rm -f "$BIN" "$BIN.ll"
  t2="$(now_ns)"
  ASTER_CACHE=1 ASTER_CACHE_DIR="$CACHE_DIR" "$ASTER_COMPILER" "$SRC" "$BIN" >/dev/null
  t3="$(now_ns)"
  noop_ns="$((t3 - t2))"

  echo "Benchmark: $bench"
  echo "- compile clean ns: $clean_ns"
  echo "- compile noop  ns: $noop_ns"

  times=()
  for ((i=0;i<RUNS;i++)); do
    times+=("$("$BIN")")
  done
  printf '%s\n' "${times[@]}" | median_u64 | awk '{print "- runtime median ns: "$1}'
  echo ""
done
