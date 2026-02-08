#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

STATE_DIR="${BENCH_HILL_STATE_DIR:-$ROOT/.context/bench/hillclimb}"
mkdir -p "$STATE_DIR"

CMD="${BENCH_HILL_CMD:-tools/bench/run.sh}"
EPS="${BENCH_HILL_EPS:-0.002}" # require >=0.2% improvement to accept by default

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<EOF
usage: tools/bench/hillclimb.sh

Runs a benchmark command, compares against the current "best" snapshot, and
prints ACCEPT/REJECT plus a BENCH.md-ready delta snippet.

Environment:
  BENCH_HILL_CMD        command to run (default: tools/bench/run.sh)
  BENCH_HILL_STATE_DIR  state dir (default: .context/bench/hillclimb)
  BENCH_HILL_EPS        min relative improvement required to accept (default: 0.002)
  BENCH_HILL_RESET=1    forget current best and accept next run as baseline

Typical:
  BENCH_ONLY=json,hashmap BENCH_ITERS=20 BENCH_BUILD_TIMING=1 tools/bench/hillclimb.sh
EOF
  exit 0
fi

BEST_JSON="$STATE_DIR/best.json"
BEST_LOG="$STATE_DIR/best.txt"

if [[ -n "${BENCH_HILL_RESET:-}" ]]; then
  rm -f "$BEST_JSON" "$BEST_LOG" 2>/dev/null || true
fi

stamp="$(date +%Y%m%d_%H%M%S)"
CAND_LOG="$STATE_DIR/cand_${stamp}.txt"
CAND_JSON="$STATE_DIR/cand_${stamp}.json"

(
  cd "$ROOT"
  bash -lc "$CMD"
) 2>&1 | tee "$CAND_LOG" >/dev/null

python3 - <<'PY' "$CAND_LOG" "$CAND_JSON"
import json
import re
import sys

log_path = sys.argv[1]
out_path = sys.argv[2]

lines = open(log_path, "r", encoding="utf-8", errors="replace").read().splitlines()

geomean = None
win_rate = None
m20 = None

bench_ratios = {}
cur = None
for line in lines:
    if line.startswith("Benchmark:"):
        cur = line.split(":", 1)[1].strip()
        continue
    m = re.match(r"^perf delta \(median\): aster/baseline\s+([0-9.]+)x$", line.strip())
    if m and cur:
        bench_ratios[cur] = float(m.group(1))
        continue
    m = re.match(r"^Geometric mean \(aster/baseline\):\s+([0-9.]+)x$", line.strip())
    if m:
        geomean = float(m.group(1))
        continue
    m = re.match(r"^Win rate \(aster < baseline\):\s+(\d+)/(\d+)\s+=", line.strip())
    if m:
        win_rate = {"wins": int(m.group(1)), "total": int(m.group(2))}
        continue
    m = re.match(r"^Margin >=20% faster \(<=0.80x\):\s+(\d+)/(\d+)\s+=", line.strip())
    if m:
        m20 = {"wins": int(m.group(1)), "total": int(m.group(2))}
        continue

data = {
    "geomean": geomean,
    "win_rate": win_rate,
    "m20": m20,
    "bench_ratios": bench_ratios,
}

with open(out_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, sort_keys=True)
PY

if [[ ! -f "$BEST_JSON" ]]; then
  cp -f "$CAND_JSON" "$BEST_JSON"
  cp -f "$CAND_LOG" "$BEST_LOG"
  echo "HILLCLIMB: ACCEPT (baseline)"
  echo "best: $BEST_LOG"
  exit 0
fi

python3 - <<'PY' "$BEST_JSON" "$CAND_JSON" "$EPS"
import json
import math
import sys

best = json.load(open(sys.argv[1], "r", encoding="utf-8"))
cand = json.load(open(sys.argv[2], "r", encoding="utf-8"))
eps = float(sys.argv[3])

def f(x):
    return float(x) if x is not None else math.nan

b = f(best.get("geomean"))
c = f(cand.get("geomean"))

if math.isnan(b) or math.isnan(c):
    print("HILLCLIMB: REJECT (missing geomean in log)")
    sys.exit(2)

improve = (b - c) / b if b != 0 else 0.0
verdict = "ACCEPT" if improve >= eps else "REJECT"

print(f"HILLCLIMB: {verdict}")
print(f"- geomean: {b:.3f}x -> {c:.3f}x  ({improve*100:+.2f}%)")

# Show biggest ratio deltas (negative is improvement).
deltas = []
for k, v in cand.get("bench_ratios", {}).items():
    if k in best.get("bench_ratios", {}):
        deltas.append((k, float(best["bench_ratios"][k]), float(v)))

deltas.sort(key=lambda t: (t[2] - t[1]))  # improvements first
if deltas:
    print("- per-benchmark (best -> cand):")
    for k, bv, cv in deltas[:8]:
        dp = (bv - cv) / bv * 100 if bv else 0.0
        print(f"  - {k}: {bv:.3f}x -> {cv:.3f}x  ({dp:+.2f}%)")

sys.exit(0 if verdict == "ACCEPT" else 1)
PY

rc=$?
if [[ "$rc" -eq 0 ]]; then
  cp -f "$CAND_JSON" "$BEST_JSON"
  cp -f "$CAND_LOG" "$BEST_LOG"
  echo "best: $BEST_LOG"
else
  echo "best: $BEST_LOG"
  echo "cand: $CAND_LOG"
fi
exit "$rc"

