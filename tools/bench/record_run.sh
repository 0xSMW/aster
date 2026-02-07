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
) 2>&1 | tee "$log_txt" >/dev/null

python3 - <<'PY' "$ROOT" "$log_txt" "$log_md" "$cmd" "$title"
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
log_txt = pathlib.Path(sys.argv[2])
log_md = pathlib.Path(sys.argv[3])
cmd = sys.argv[4]
title = sys.argv[5]

bench_md = root / "BENCH.md"
bench_text = bench_md.read_text(encoding="utf-8")
m = re.findall(r"^## Run (\d+)", bench_text, flags=re.M)
run_no = (max(int(x) for x in m) + 1) if m else 1

log = log_txt.read_text(encoding="utf-8", errors="replace").splitlines()

def find_block(header: str) -> list[str]:
    for i, line in enumerate(log):
        if line.strip() == header:
            out = []
            j = i + 1
            while j < len(log):
                t = log[j].rstrip()
                if not t.startswith("-"):
                    break
                out.append(t)
                j += 1
            return out
    return []

toolchains = find_block("Toolchains:")
bench_cfg = find_block("Bench config:")
fs_dataset = find_block("FS dataset:")

build_stages = []
i = 0
while i < len(log):
    line = log[i].rstrip()
    if line.startswith("Build timing:"):
        stage_name = line[len("Build timing:") :].strip()
        langs: dict[str, dict[str, float]] = {}
        aster_break = None
        j = i + 1
        while j < len(log):
            t = log[j].rstrip()
            if not t.startswith("-"):
                break
            m = re.match(r"^-\s*(aster|cpp|rust):\s+median\s+([0-9.]+)s\s+stdev\s+([0-9.]+)s(?:\s+breakdown:\s+asterc\s+([0-9.]+)ms\s+\(sd\s+([0-9.]+)ms\),\s+clang\s+([0-9.]+)ms\s+\(sd\s+([0-9.]+)ms\))?$", t)
            if m:
                lang = m.group(1)
                langs[lang] = {"median_s": float(m.group(2)), "stdev_s": float(m.group(3)), "raw": t}
                if lang == "aster" and m.group(4):
                    aster_break = {
                        "asterc_ms": float(m.group(4)),
                        "asterc_sd_ms": float(m.group(5)),
                        "clang_ms": float(m.group(6)),
                        "clang_sd_ms": float(m.group(7)),
                    }
            j += 1
        build_stages.append({"name": stage_name, "langs": langs, "aster_break": aster_break})
        i = j
        continue
    i += 1

benches = []
cur = None
i = 0
while i < len(log):
    line = log[i].rstrip()
    if line.startswith("Benchmark:"):
        name = line.split(":", 1)[1].strip()
        cur = {"name": name, "langs": {}, "ratio": None}
        benches.append(cur)
        i += 1
        continue
    if cur is not None:
        m = re.match(r"^\s*(aster|cpp|rust):\s+median\s+([0-9.]+)s\s+avg\s+([0-9.]+)s\s+min\s+([0-9.]+)s\s+stdev\s+([0-9.]+)s\s+runs\s+([0-9]+)$", line)
        if m:
            cur["langs"][m.group(1)] = {
                "median_s": float(m.group(2)),
                "avg_s": float(m.group(3)),
                "min_s": float(m.group(4)),
                "stdev_s": float(m.group(5)),
                "runs": int(m.group(6)),
            }
        m = re.match(r"^perf delta \(median\): aster/baseline\s+([0-9.]+)x$", line)
        if m:
            cur["ratio"] = float(m.group(1))
    i += 1

summary = []
for line in log:
    t = line.rstrip()
    if t.startswith("Geometric mean (aster/baseline):"):
        summary.append(t)
    elif t.startswith("Win rate (aster < baseline):"):
        summary.append(t)
    elif t.startswith("Margin >=5% faster"):
        summary.append(t)
    elif t.startswith("Margin >=15% faster"):
        summary.append(t)
    elif t.startswith("Margin >=20% faster"):
        summary.append(t)

def _fmt_date_from_path(p: pathlib.Path) -> str | None:
    m = re.search(r"run_(\d{8})_(\d{6})", p.name)
    if not m:
        return None
    ymd = m.group(1)
    hms = m.group(2)
    return f"{ymd[0:4]}-{ymd[4:6]}-{ymd[6:8]} {hms[0:2]}:{hms[2:4]}:{hms[4:6]}"

stamp = _fmt_date_from_path(log_txt)

out = []
out.append(f"## Run {run_no:03d} — {title}")
if stamp:
    out.append(f"Date: `{stamp}`")
out.append(f"Command: `{cmd}`")
out.append(f"Log: `{log_txt}`")
out.append("")

if toolchains:
    out.append("### Toolchains")
    out.extend(toolchains)
    out.append("")

if bench_cfg:
    out.append("### Bench Config")
    out.extend(bench_cfg)
    out.append("")

out.append("### Datasets")
if fs_dataset:
    out.extend(fs_dataset)
else:
    out.append("- (none)")
out.append("")

out.append("### Compile Time (Build + Link)")
if build_stages:
    out.append("| stage | aster median | aster stdev | aster breakdown (asterc, clang) | cpp median | cpp stdev | rust median | rust stdev |")
    out.append("|---|---:|---:|---|---:|---:|---:|---:|")
    for st in build_stages:
        langs = st["langs"]
        a = langs.get("aster", {})
        c = langs.get("cpp", {})
        r = langs.get("rust", {})
        def cell(lang: dict, k: str) -> str:
            v = lang.get(k)
            return f"{v:.3f}s" if isinstance(v, float) else ""
        br = st.get("aster_break")
        br_cell = ""
        if br:
            br_cell = f"asterc {br['asterc_ms']:.3f}ms (sd {br['asterc_sd_ms']:.3f}ms); clang {br['clang_ms']:.3f}ms (sd {br['clang_sd_ms']:.3f}ms)"

        out.append(
            "| "
            + st["name"].replace("|", "\\|")
            + " | "
            + cell(a, "median_s")
            + " | "
            + cell(a, "stdev_s")
            + " | "
            + br_cell.replace("|", "\\|")
            + " | "
            + cell(c, "median_s")
            + " | "
            + cell(c, "stdev_s")
            + " | "
            + cell(r, "median_s")
            + " | "
            + cell(r, "stdev_s")
            + " |"
        )
else:
    out.append("- (not recorded)")
out.append("")

out.append("### Runtime")
if benches:
    out.append("| bench | aster median | cpp median | rust median | aster/best |")
    out.append("|---|---:|---:|---:|---:|")
    for b in benches:
        langs = b["langs"]
        a = langs.get("aster")
        c = langs.get("cpp")
        r = langs.get("rust")

        def cell_lang(x):
            if not x:
                return ""
            return f"{x['median_s']:.4f}s (sd {x['stdev_s']:.4f}, n={x['runs']})"

        ratio = b.get("ratio")
        ratio_cell = f"{ratio:.3f}x" if isinstance(ratio, float) else ""
        out.append(
            "| "
            + b["name"].replace("|", "\\|")
            + " | "
            + cell_lang(a)
            + " | "
            + cell_lang(c)
            + " | "
            + cell_lang(r)
            + " | "
            + ratio_cell
            + " |"
        )
else:
    out.append("- (no benchmark results found)")
out.append("")

if summary:
    out.append("### Summary")
    out.extend([f"- {s}" for s in summary])
    out.append("")

log_md.write_text("\n".join(out).rstrip() + "\n", encoding="utf-8")
PY

echo "wrote $log_txt"
echo "wrote $log_md"

if [[ -n "${BENCH_APPEND:-}" ]]; then
  cat "$log_md" >> "$ROOT/BENCH.md"
  echo "appended to $ROOT/BENCH.md"
fi
