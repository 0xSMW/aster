#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

OUT="${ML_GOLDEN_OUT:-$ROOT/.context/ml/golden.json}"
SEED="${ML_GOLDEN_SEED:-1}"
FUZZ_CASES="${ML_GOLDEN_FUZZ_CASES:-5}"
PARITY_AS="${ML_PARITY_AS:-$ROOT/.context/ml/parity.as}"
PARITY_BIN="${ML_PARITY_BIN:-$ROOT/.context/ml/parity}"

ASTER_COMPILER="${ASTER_COMPILER:-$ROOT/tools/build/out/asterc}"
if [[ ! -x "$ASTER_COMPILER" ]]; then
  bash "$ROOT/tools/build/build.sh" "$ROOT/asm/driver/asterc.S" >/dev/null
fi

mkdir -p "$(dirname "$OUT")"

python3 "$ROOT/tools/ml/golden.py" --seed "$SEED" --fuzz-cases "$FUZZ_CASES" --out "$OUT" >/dev/null
echo "ml: wrote golden: $OUT"

python3 "$ROOT/tools/ml/parity_gen.py" --golden "$OUT" --out "$PARITY_AS"
echo "ml: wrote parity runner src: $PARITY_AS"

rm -f "$PARITY_BIN" "$PARITY_BIN.ll"
"$ASTER_COMPILER" "$PARITY_AS" "$PARITY_BIN" >/dev/null
echo "ml: built parity runner: $PARITY_BIN"
"$PARITY_BIN"
