#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${BENCH_RECORD_OUT_DIR:-$ROOT/.context/bench/record}"
mkdir -p "$OUT_DIR"

stamp="$(date +%Y%m%d_%H%M%S)"
log_txt="$OUT_DIR/run_${stamp}.txt"
log_md="$OUT_DIR/run_${stamp}.md"

cmd="${BENCH_RECORD_CMD:-tools/bench/run.sh}"
title="${BENCH_RECORD_TITLE:-bench run}"

(
  cd "$ROOT"
  bash -lc "$cmd"
) | tee "$log_txt" >/dev/null

python3 - <<'PY' "$ROOT" "$log_txt" "$log_md" "$cmd" "$title"
import pathlib
import re
import sys
from typing import Optional

root = pathlib.Path(sys.argv[1])
log_txt = pathlib.Path(sys.argv[2])
log_md = pathlib.Path(sys.argv[3])
cmd = sys.argv[4]
title = sys.argv[5]

bench_md = root / "BENCH.md"
bench_text = bench_md.read_text(encoding="utf-8")
m = re.findall(r"^## Run (\\d+)", bench_text, flags=re.M)
run_no = (max(int(x) for x in m) + 1) if m else 1

log = log_txt.read_text(encoding="utf-8", errors="replace").splitlines()

def first_line(prefix: str) -> Optional[str]:
    for line in log:
        if line.startswith(prefix):
            return line
    return None

env = {
    "host": first_line("Darwin") or "",
}

out = []
out.append(f"## Run {run_no:03d} — {title}")
out.append(f"Command: `{cmd}`")
out.append(f"Log: `{log_txt}`")
out.append("")

# Include the key provenance blocks if present (FS dataset + build timing + bench results).
copy = False
for line in log:
    if line.startswith("FS dataset:"):
        copy = True
    if line.startswith("Benchmark:"):
        copy = True
    if line.startswith("Build timing:"):
        copy = True
    if copy:
        # Make compiler output markdown-friendly by bulleting the language timing lines.
        if re.match(r"^(aster:|\\s+cpp:|\\s*rust:)", line):
            out.append(f"- {line.strip()}")
        elif line.startswith("perf delta (median):"):
            out.append(f"- {line.strip()}")
            out.append("")
        else:
            out.append(line.rstrip())

log_md.write_text("\n".join(out).rstrip() + "\n", encoding="utf-8")
PY

echo "wrote $log_txt"
echo "wrote $log_md"

if [[ -n "${BENCH_APPEND:-}" ]]; then
  cat "$log_md" >> "$ROOT/BENCH.md"
  echo "appended to $ROOT/BENCH.md"
fi
