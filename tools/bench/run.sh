#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="$ROOT/tools/bench/out"
mkdir -p "$OUT_DIR"

BENCH_SET="${BENCH_SET:-all}"
BENCHES=(dot gemm stencil sort json hashmap regex async_io)

if [[ "$BENCH_SET" == "kernels" ]]; then
    BENCHES=(dot gemm stencil sort json hashmap regex async_io)
elif [[ "$BENCH_SET" == "fswalk" ]]; then
    if [[ -z "${FS_BENCH_ROOT:-}" ]]; then
        echo "FS_BENCH_ROOT is required for fswalk bench set" >&2
        exit 2
    fi
    BENCHES=(fswalk treewalk dircount fsinventory)
else
    if [[ -n "${FS_BENCH_ROOT:-}" ]]; then
        BENCHES+=(fswalk treewalk dircount fsinventory)
    fi
fi

LIST_PATH=""
TREE_LIST_PATH=""
for bench in "${BENCHES[@]}"; do
    if [[ "$bench" == "fswalk" ]]; then
        if [[ -n "${FS_BENCH_LIST:-}" ]]; then
            LIST_PATH="$FS_BENCH_LIST"
        elif [[ -n "${FS_BENCH_LIST_FIXED:-}" ]]; then
            LIST_PATH="$ROOT/tools/bench/data/fswalk_list.txt"
            META_PATH="$ROOT/tools/bench/data/fswalk_list.meta"
            if [[ ! -f "$LIST_PATH" ]]; then
                mkdir -p "$ROOT/tools/bench/data"
                "$ROOT/tools/bench/fswalk_list.sh" "$FS_BENCH_ROOT" "$LIST_PATH" "${FS_BENCH_MAX_DEPTH:-6}"
                {
                    echo "root=$FS_BENCH_ROOT"
                    echo "max_depth=${FS_BENCH_MAX_DEPTH:-6}"
                    echo "generated=$(date +%Y-%m-%d)"
                } > "$META_PATH"
            fi
        else
            LIST_PATH="$OUT_DIR/fswalk_list.txt"
            "$ROOT/tools/bench/fswalk_list.sh" "$FS_BENCH_ROOT" "$LIST_PATH" "${FS_BENCH_MAX_DEPTH:-6}"
        fi
        export FS_BENCH_LIST_PATH="$LIST_PATH"
        break
    fi
done

for bench in "${BENCHES[@]}"; do
    if [[ "$bench" == "treewalk" || "$bench" == "dircount" || "$bench" == "fsinventory" ]]; then
        if [[ -n "${FS_BENCH_TREEWALK_LIST:-}" ]]; then
            TREE_LIST_PATH="$FS_BENCH_TREEWALK_LIST"
        elif [[ -n "${FS_BENCH_TREEWALK_LIST_FIXED:-}" ]]; then
            TREE_LIST_PATH="$ROOT/tools/bench/data/treewalk_dirs.txt"
            META_PATH="$ROOT/tools/bench/data/treewalk_dirs.meta"
            if [[ ! -f "$TREE_LIST_PATH" ]]; then
                mkdir -p "$ROOT/tools/bench/data"
                "$ROOT/tools/bench/treewalk_list.sh" "$FS_BENCH_ROOT" "$TREE_LIST_PATH" "${FS_BENCH_MAX_DEPTH:-6}"
                {
                    echo "root=$FS_BENCH_ROOT"
                    echo "max_depth=${FS_BENCH_MAX_DEPTH:-6}"
                    echo "generated=$(date +%Y-%m-%d)"
                } > "$META_PATH"
            fi
        fi
        if [[ -n "$TREE_LIST_PATH" ]]; then
            export FS_BENCH_TREEWALK_LIST_PATH="$TREE_LIST_PATH"
        fi
        break
    fi
done

for bench in "${BENCHES[@]}"; do
    # compile Aster source to assembly (Aster-only backend by default)
    if [[ "$bench" == "fswalk" || "$bench" == "treewalk" || "$bench" == "dircount" || "$bench" == "fsinventory" ]]; then
        ASTER_BACKEND="${ASTER_BACKEND:-c}" "$ROOT/tools/build/asterc.sh" "$ROOT/aster/bench/fswalk/fswalk.as" "$OUT_DIR/aster_${bench}.S"
        clang -c "$OUT_DIR/aster_${bench}.S" -I"$ROOT/asm/macros" -o "$OUT_DIR/aster_${bench}.o"
        clang "$OUT_DIR/aster_${bench}.o" -o "$OUT_DIR/aster_${bench}"
        clang++ "$ROOT/aster/bench/fswalk/cpp.cpp" -O3 -std=c++17 -o "$OUT_DIR/cpp_${bench}"
        rustc -O "$ROOT/aster/bench/fswalk/rust.rs" -o "$OUT_DIR/rust_${bench}"
        continue
    fi

    ASTER_BACKEND="${ASTER_BACKEND:-c}" "$ROOT/tools/build/asterc.sh" "$ROOT/aster/bench/${bench}/${bench}.as" "$OUT_DIR/aster_${bench}.S"

    clang -c "$OUT_DIR/aster_${bench}.S" -I"$ROOT/asm/macros" -o "$OUT_DIR/aster_${bench}.o"
    clang "$OUT_DIR/aster_${bench}.o" -o "$OUT_DIR/aster_${bench}"
    clang++ "$ROOT/aster/bench/${bench}/cpp.cpp" -O3 -o "$OUT_DIR/cpp_${bench}"
    rustc -O "$ROOT/aster/bench/${bench}/rust.rs" -o "$OUT_DIR/rust_${bench}"

done

python3 - <<'PY'
import os
import subprocess
import time
import statistics
import math

bench_set = os.environ.get("BENCH_SET", "all")
root = os.environ.get("FS_BENCH_ROOT")

if bench_set == "kernels":
    benches = ["dot", "gemm", "stencil", "sort", "json", "hashmap", "regex", "async_io"]
elif bench_set == "fswalk":
    benches = ["fswalk", "treewalk", "dircount", "fsinventory"]
else:
    benches = ["dot", "gemm", "stencil", "sort", "json", "hashmap", "regex", "async_io"]
    if root:
        benches.extend(["fswalk", "treewalk", "dircount", "fsinventory"])

RUNS = 6
WARMUP = 1
FSWALK_RUNS = int(os.environ.get("FS_BENCH_FSWALK_RUNS", "2"))
FSWALK_WARMUP = int(os.environ.get("FS_BENCH_FSWALK_WARMUP", "0"))

bins = {
    "aster": "./tools/bench/out/aster_{}",
    "cpp": "./tools/bench/out/cpp_{}",
    "rust": "./tools/bench/out/rust_{}",
}

def bench(cmd, args, runs=RUNS, warmup=WARMUP, env=None):
    times = []
    for i in range(runs):
        start = time.perf_counter()
        subprocess.run([cmd, *args], check=True, stdout=subprocess.DEVNULL, env=env)
        dt = time.perf_counter() - start
        if i >= warmup:
            times.append(dt)
    return times

def stdev(values):
    return statistics.stdev(values) if len(values) > 1 else 0.0

results = {}
ratios = []

for bench_name in benches:
    results[bench_name] = {}
    args = []
    if bench_name == "fswalk":
        args = [root]
        runs = FSWALK_RUNS
        warmup = FSWALK_WARMUP
    elif bench_name == "treewalk":
        args = [root]
        runs = FSWALK_RUNS
        warmup = FSWALK_WARMUP
    elif bench_name == "dircount":
        args = [root]
        runs = FSWALK_RUNS
        warmup = FSWALK_WARMUP
    elif bench_name == "fsinventory":
        args = [root]
        runs = FSWALK_RUNS
        warmup = FSWALK_WARMUP
    else:
        runs = RUNS
        warmup = WARMUP

    for lang, tpl in bins.items():
        env = os.environ.copy()
        if bench_name == "fswalk":
            list_path = env.get("FS_BENCH_LIST_PATH") or env.get("FS_BENCH_LIST")
            if list_path:
                env["FS_BENCH_LIST"] = list_path
            env["FS_BENCH_CPP_MODE"] = "fts"
        elif bench_name == "treewalk":
            env.pop("FS_BENCH_LIST", None)
            tree_list = env.get("FS_BENCH_TREEWALK_LIST_PATH") or env.get("FS_BENCH_TREEWALK_LIST")
            if tree_list:
                env["FS_BENCH_TREEWALK_LIST"] = tree_list
            if "FS_BENCH_TREEWALK_MODE" not in env:
                env["FS_BENCH_TREEWALK_MODE"] = "bulk"
            if "FS_BENCH_CPP_MODE" not in env:
                if env.get("FS_BENCH_TREEWALK_MODE") == "bulk":
                    env["FS_BENCH_CPP_MODE"] = "bulk"
                else:
                    env["FS_BENCH_CPP_MODE"] = "fts"
        elif bench_name == "dircount":
            env.pop("FS_BENCH_LIST", None)
            tree_list = env.get("FS_BENCH_TREEWALK_LIST_PATH") or env.get("FS_BENCH_TREEWALK_LIST")
            if tree_list:
                env["FS_BENCH_TREEWALK_LIST"] = tree_list
            if "FS_BENCH_TREEWALK_MODE" not in env:
                env["FS_BENCH_TREEWALK_MODE"] = "bulk"
            if "FS_BENCH_CPP_MODE" not in env:
                if env.get("FS_BENCH_TREEWALK_MODE") == "bulk":
                    env["FS_BENCH_CPP_MODE"] = "bulk"
                else:
                    env["FS_BENCH_CPP_MODE"] = "fts"
            env["FS_BENCH_COUNT_ONLY"] = "1"
        elif bench_name == "fsinventory":
            env.pop("FS_BENCH_LIST", None)
            tree_list = env.get("FS_BENCH_TREEWALK_LIST_PATH") or env.get("FS_BENCH_TREEWALK_LIST")
            if tree_list:
                env["FS_BENCH_TREEWALK_LIST"] = tree_list
            if "FS_BENCH_TREEWALK_MODE" not in env:
                env["FS_BENCH_TREEWALK_MODE"] = "bulk"
            if "FS_BENCH_CPP_MODE" not in env:
                if env.get("FS_BENCH_TREEWALK_MODE") == "bulk":
                    env["FS_BENCH_CPP_MODE"] = "bulk"
                else:
                    env["FS_BENCH_CPP_MODE"] = "fts"
            env["FS_BENCH_INVENTORY"] = "1"
        times = bench(tpl.format(bench_name), args, runs=runs, warmup=warmup, env=env)
        results[bench_name][lang] = {
            "min": min(times),
            "avg": statistics.mean(times),
            "median": statistics.median(times),
            "stdev": stdev(times),
            "runs": len(times),
        }

    aster = results[bench_name]["aster"]["median"]
    cpp = results[bench_name]["cpp"]["median"]
    rust = results[bench_name]["rust"]["median"]
    baseline = min(cpp, rust)
    ratios.append(aster / baseline)

    print(f"Benchmark: {bench_name}")
    for lang in ("aster", "cpp", "rust"):
        s = results[bench_name][lang]
        print(
            f"{lang:>5}: median {s['median']:.4f}s  avg {s['avg']:.4f}s  "
            f"min {s['min']:.4f}s  stdev {s['stdev']:.4f}s  runs {s['runs']}"
        )
    print(f"perf delta (median): aster/baseline {aster / baseline:.3f}x\n")

if ratios:
    geom = math.exp(sum(math.log(r) for r in ratios) / len(ratios))
    print(f"Geometric mean (aster/baseline): {geom:.3f}x")
PY
