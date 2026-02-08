#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${BENCH_OUT_DIR:-$ROOT/.context/bench/out}"
export BENCH_OUT_DIR="$OUT_DIR"
mkdir -p "$OUT_DIR"

DATA_DIR="$ROOT/.context/bench/data"
mkdir -p "$DATA_DIR"

UNAME_S="$(uname -s 2>/dev/null || true)"
IS_DARWIN=0
if [[ "$UNAME_S" == "Darwin" ]]; then
    IS_DARWIN=1
fi

echo "Toolchains:"
echo "- host: $(uname -a)"
echo "- clang: $(clang --version | head -n 1)"
echo "- clang++: $(clang++ --version | head -n 1)"
echo "- rustc: $(rustc --version)"
echo "- python3: $(python3 --version)"
echo ""

# Baseline compilation flags for the C++/Rust competitors.
# Note: keep these "reasonable" for build-time comparisons; focus on
# CPU tuning and algorithmic improvements first.
CPP_FLAGS_BASE=(-O3 -DNDEBUG -march=native -mtune=native -std=c++17)
CPP_FLAGS_MATH=(-ffast-math -fno-math-errno -fno-trapping-math)
RUST_FLAGS_BASE=(-O -C target-cpu=native -C panic=abort)

now_ns() {
    python3 - <<'PY'
import time
print(time.time_ns())
PY
}

bump_mtime() {
    local path="$1"
    python3 - <<'PY' "$path"
import os
import sys
import time

p = sys.argv[1]
# Nudge into the future by 2s so `test -nt` (which may only compare seconds on
# some platforms/filesystems) reliably detects "newer than output".
now = time.time_ns() + 2_000_000_000
os.utime(p, ns=(now, now))
PY
}

needs_build() {
    local out="$1"
    local src="$2"
    local dep="${3:-}"
    if [[ -n "${BENCH_REBUILD:-}" ]]; then
        return 0
    fi
    if [[ ! -f "$out" ]]; then
        return 0
    fi
    if [[ "$src" -nt "$out" ]]; then
        return 0
    fi
    if [[ -n "$dep" && -f "$dep" && "$dep" -nt "$out" ]]; then
        return 0
    fi
    return 1
}

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

# Optional: run just a subset (comma-separated), e.g. BENCH_ONLY=stencil,hashmap.
if [[ -n "${BENCH_ONLY:-}" ]]; then
    IFS=',' read -r -a BENCHES <<<"$BENCH_ONLY"
fi

LIST_PATH=""
TREE_LIST_PATH=""
FSWALK_META_PATH=""
TREE_META_PATH=""
for bench in "${BENCHES[@]}"; do
    if [[ "$bench" == "fswalk" ]]; then
        if [[ -n "${FS_BENCH_LIST:-}" ]]; then
            LIST_PATH="$FS_BENCH_LIST"
        elif [[ -n "${FS_BENCH_LIST_FIXED:-}" ]]; then
            if [[ -z "${FS_BENCH_ROOT:-}" ]]; then
                echo "FS_BENCH_ROOT is required when FS_BENCH_LIST_FIXED is set" >&2
                exit 2
            fi
            DEPTH="${FS_BENCH_MAX_DEPTH:-6}"
            MAX_LINES="${FS_BENCH_LIST_MAX_LINES:-}"
            key="fswalk|$FS_BENCH_ROOT|$DEPTH|$MAX_LINES"
            id="$(printf '%s' "$key" | shasum -a 256 | awk '{print $1}' | cut -c1-16)"
            LIST_PATH="$DATA_DIR/fswalk_list_${id}.txt"
            META_PATH="$DATA_DIR/fswalk_list_${id}.meta"
            FSWALK_META_PATH="$META_PATH"
            if [[ ! -f "$LIST_PATH" ]]; then
                "$ROOT/tools/bench/fswalk_list.sh" "$FS_BENCH_ROOT" "$LIST_PATH" "$DEPTH" "${MAX_LINES:-}"
            fi
            sha="$(shasum -a 256 "$LIST_PATH" | awk '{print $1}')"
            bytes="$(wc -c < "$LIST_PATH" | tr -d ' ')"
            lines="$(wc -l < "$LIST_PATH" | tr -d ' ')"
            generated="$(grep '^generated=' "$META_PATH" 2>/dev/null | head -n 1 | cut -d= -f2- || true)"
            if [[ -z "$generated" ]]; then
                generated="$(date +%Y-%m-%d)"
            fi
            old_sha="$(grep '^sha256=' "$META_PATH" 2>/dev/null | head -n 1 | cut -d= -f2- || true)"
            if [[ -n "$old_sha" && "$old_sha" != "$sha" ]]; then
                msg="fixed fswalk list changed: $LIST_PATH (meta sha256=$old_sha, current sha256=$sha)"
                if [[ -n "${FS_BENCH_STRICT:-}" ]]; then
                    echo "$msg" >&2
                    exit 2
                fi
                echo "warning: $msg" >&2
            fi
            {
                echo "root=$FS_BENCH_ROOT"
                echo "max_depth=$DEPTH"
                if [[ -n "$MAX_LINES" ]]; then
                    echo "max_lines=$MAX_LINES"
                fi
                echo "generated=$generated"
                echo "sha256=$sha"
                echo "bytes=$bytes"
                echo "lines=$lines"
            } > "$META_PATH"
        else
            LIST_PATH="$OUT_DIR/fswalk_list.txt"
            "$ROOT/tools/bench/fswalk_list.sh" "$FS_BENCH_ROOT" "$LIST_PATH" "${FS_BENCH_MAX_DEPTH:-6}" "${FS_BENCH_LIST_MAX_LINES:-}"
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
            if [[ -z "${FS_BENCH_ROOT:-}" ]]; then
                echo "FS_BENCH_ROOT is required when FS_BENCH_TREEWALK_LIST_FIXED is set" >&2
                exit 2
            fi
            DEPTH="${FS_BENCH_MAX_DEPTH:-6}"
            MAX_LINES="${FS_BENCH_TREEWALK_LIST_MAX_LINES:-}"
            key="treewalk|$FS_BENCH_ROOT|$DEPTH|$MAX_LINES"
            id="$(printf '%s' "$key" | shasum -a 256 | awk '{print $1}' | cut -c1-16)"
            TREE_LIST_PATH="$DATA_DIR/treewalk_dirs_${id}.txt"
            META_PATH="$DATA_DIR/treewalk_dirs_${id}.meta"
            TREE_META_PATH="$META_PATH"
            if [[ ! -f "$TREE_LIST_PATH" ]]; then
                "$ROOT/tools/bench/treewalk_list.sh" "$FS_BENCH_ROOT" "$TREE_LIST_PATH" "$DEPTH" "${MAX_LINES:-}"
            fi
            sha="$(shasum -a 256 "$TREE_LIST_PATH" | awk '{print $1}')"
            bytes="$(wc -c < "$TREE_LIST_PATH" | tr -d ' ')"
            lines="$(wc -l < "$TREE_LIST_PATH" | tr -d ' ')"
            generated="$(grep '^generated=' "$META_PATH" 2>/dev/null | head -n 1 | cut -d= -f2- || true)"
            if [[ -z "$generated" ]]; then
                generated="$(date +%Y-%m-%d)"
            fi
            old_sha="$(grep '^sha256=' "$META_PATH" 2>/dev/null | head -n 1 | cut -d= -f2- || true)"
            if [[ -n "$old_sha" && "$old_sha" != "$sha" ]]; then
                msg="fixed treewalk dirs list changed: $TREE_LIST_PATH (meta sha256=$old_sha, current sha256=$sha)"
                if [[ -n "${FS_BENCH_STRICT:-}" ]]; then
                    echo "$msg" >&2
                    exit 2
                fi
                echo "warning: $msg" >&2
            fi
            {
                echo "root=$FS_BENCH_ROOT"
                echo "max_depth=$DEPTH"
                if [[ -n "$MAX_LINES" ]]; then
                    echo "max_lines=$MAX_LINES"
                fi
                echo "generated=$generated"
                echo "sha256=$sha"
                echo "bytes=$bytes"
                echo "lines=$lines"
            } > "$META_PATH"
        fi
        if [[ -n "$TREE_LIST_PATH" ]]; then
            export FS_BENCH_TREEWALK_LIST_PATH="$TREE_LIST_PATH"
        fi
        break
    fi
done

if [[ -n "${FS_BENCH_ROOT:-}" ]]; then
    if [[ -n "${BENCH_NOTE:-}" ]]; then
        echo "Note: $BENCH_NOTE"
    fi
    echo "FS dataset:"
    echo "- FS_BENCH_ROOT: $FS_BENCH_ROOT"
    echo "- FS_BENCH_MAX_DEPTH: ${FS_BENCH_MAX_DEPTH:-6}"
    _meta_get() {
        local key="$1"
        local path="$2"
        grep "^${key}=" "$path" 2>/dev/null | head -n 1 | cut -d= -f2- || true
    }
    if [[ -n "$FSWALK_META_PATH" && -f "$FSWALK_META_PATH" ]]; then
        echo "- fswalk_list: sha256=$(_meta_get sha256 "$FSWALK_META_PATH"), bytes=$(_meta_get bytes "$FSWALK_META_PATH"), lines=$(_meta_get lines "$FSWALK_META_PATH")"
    fi
    if [[ -n "$TREE_META_PATH" && -f "$TREE_META_PATH" ]]; then
        echo "- treewalk_dirs: sha256=$(_meta_get sha256 "$TREE_META_PATH"), bytes=$(_meta_get bytes "$TREE_META_PATH"), lines=$(_meta_get lines "$TREE_META_PATH")"
    fi
    echo ""
fi

build_all() {
    local timing="${1:-0}" # 1 = measure
    local dep_asterc="$ROOT/tools/build/out/asterc"

    local total_ns_aster=0
    local total_ns_asterc=0
    local total_ns_clang=0
    local total_ns_cpp=0
    local total_ns_rust=0

    local fs_built=0
    for bench in "${BENCHES[@]}"; do
        if [[ "$bench" == "fswalk" || "$bench" == "treewalk" || "$bench" == "dircount" || "$bench" == "fsinventory" ]]; then
            # All fs benches share the same source and dispatch by env vars.
            # Compile once per language, then copy to the other names.
            local aster_src="$ROOT/aster/bench/fswalk/fswalk.as"
            local cpp_src="$ROOT/aster/bench/fswalk/cpp.cpp"
            local rust_src="$ROOT/aster/bench/fswalk/rust.rs"

            if [[ "$fs_built" -eq 0 ]]; then
                if needs_build "$OUT_DIR/aster_fswalk" "$aster_src" "$dep_asterc"; then
                    local t0=0 t1=0
                    if [[ "$timing" -eq 1 ]]; then
                        t0="$(now_ns)"
                        local out rc
                        rc=0
                        set +e
                        out="$({ ASTER_TIMING=1 ASTER_NATIVE="${ASTER_NATIVE:-1}" ASTER_FAST_MATH="${ASTER_FAST_MATH:-1}" ASTER_LINK_OBJ="$ROOT/tools/build/out/fswalk_rt.o" "$ROOT/tools/build/asterc.sh" "$aster_src" "$OUT_DIR/aster_fswalk"; } 2>&1)"
                        rc=$?
                        set -e
                        if [[ "$rc" -ne 0 ]]; then
                            printf '%s\n' "$out" >&2
                            return "$rc"
                        fi
                        t1="$(now_ns)"
                        total_ns_aster=$(( total_ns_aster + (t1 - t0) ))

                        local tl
                        tl="$(printf '%s\n' "$out" | grep '^ASTER_TIMING ' | tail -n 1 || true)"
                        if [[ -n "$tl" ]]; then
                            local a_ns=0 c_ns=0
                            if [[ "$tl" =~ asterc_ns=([0-9]+) ]]; then a_ns="${BASH_REMATCH[1]}"; fi
                            if [[ "$tl" =~ clang_ns=([0-9]+) ]]; then c_ns="${BASH_REMATCH[1]}"; fi
                            total_ns_asterc=$(( total_ns_asterc + a_ns ))
                            total_ns_clang=$(( total_ns_clang + c_ns ))
                        fi
                    else
                        ASTER_NATIVE="${ASTER_NATIVE:-1}" ASTER_FAST_MATH="${ASTER_FAST_MATH:-1}" ASTER_LINK_OBJ="$ROOT/tools/build/out/fswalk_rt.o" "$ROOT/tools/build/asterc.sh" "$aster_src" "$OUT_DIR/aster_fswalk"
                    fi
                fi
                if needs_build "$OUT_DIR/cpp_fswalk" "$cpp_src"; then
                    local t0=0 t1=0
                    if [[ "$timing" -eq 1 ]]; then t0="$(now_ns)"; fi
                    clang++ "$cpp_src" "${CPP_FLAGS_BASE[@]}" "${CPP_FLAGS_MATH[@]}" -o "$OUT_DIR/cpp_fswalk"
                    if [[ "$timing" -eq 1 ]]; then t1="$(now_ns)"; total_ns_cpp=$(( total_ns_cpp + (t1 - t0) )); fi
                fi
                if needs_build "$OUT_DIR/rust_fswalk" "$rust_src"; then
                    local t0=0 t1=0
                    if [[ "$timing" -eq 1 ]]; then t0="$(now_ns)"; fi
                    rustc "${RUST_FLAGS_BASE[@]}" "$rust_src" -o "$OUT_DIR/rust_fswalk"
                    if [[ "$timing" -eq 1 ]]; then t1="$(now_ns)"; total_ns_rust=$(( total_ns_rust + (t1 - t0) )); fi
                fi
                fs_built=1
            fi

            if [[ "$bench" != "fswalk" ]]; then
                if needs_build "$OUT_DIR/aster_${bench}" "$OUT_DIR/aster_fswalk"; then
                    cp -f "$OUT_DIR/aster_fswalk" "$OUT_DIR/aster_${bench}"
                fi
                if needs_build "$OUT_DIR/cpp_${bench}" "$OUT_DIR/cpp_fswalk"; then
                    cp -f "$OUT_DIR/cpp_fswalk" "$OUT_DIR/cpp_${bench}"
                fi
                if needs_build "$OUT_DIR/rust_${bench}" "$OUT_DIR/rust_fswalk"; then
                    cp -f "$OUT_DIR/rust_fswalk" "$OUT_DIR/rust_${bench}"
                fi
            fi
            continue
        fi

        # Kernel benches compile each benchmark's source independently.
        local aster_src="$ROOT/aster/bench/${bench}/${bench}.as"
        local cpp_src="$ROOT/aster/bench/${bench}/cpp.cpp"
        local rust_src="$ROOT/aster/bench/${bench}/rust.rs"

        if needs_build "$OUT_DIR/aster_${bench}" "$aster_src" "$dep_asterc"; then
            local t0=0 t1=0
            if [[ "$timing" -eq 1 ]]; then
                t0="$(now_ns)"
                local out rc
                rc=0
                set +e
                if [[ "$bench" == "gemm" ]]; then
                    out="$({ ASTER_TIMING=1 ASTER_NATIVE="${ASTER_NATIVE:-1}" ASTER_FAST_MATH="${ASTER_FAST_MATH:-1}" ASTER_LINK_ACCELERATE=1 "$ROOT/tools/build/asterc.sh" "$aster_src" "$OUT_DIR/aster_${bench}"; } 2>&1)"
                elif [[ "$bench" == "stencil" ]]; then
                    out="$({ ASTER_TIMING=1 ASTER_NATIVE="${ASTER_NATIVE:-1}" ASTER_FAST_MATH="${ASTER_FAST_MATH:-1}" ASTER_LINK_OBJ="$ROOT/tools/build/out/stencil_rt.o" "$ROOT/tools/build/asterc.sh" "$aster_src" "$OUT_DIR/aster_${bench}"; } 2>&1)"
                else
                    out="$({ ASTER_TIMING=1 ASTER_NATIVE="${ASTER_NATIVE:-1}" ASTER_FAST_MATH="${ASTER_FAST_MATH:-1}" "$ROOT/tools/build/asterc.sh" "$aster_src" "$OUT_DIR/aster_${bench}"; } 2>&1)"
                fi
                rc=$?
                set -e
                if [[ "$rc" -ne 0 ]]; then
                    printf '%s\n' "$out" >&2
                    return "$rc"
                fi
                t1="$(now_ns)"
                total_ns_aster=$(( total_ns_aster + (t1 - t0) ))

                local tl
                tl="$(printf '%s\n' "$out" | grep '^ASTER_TIMING ' | tail -n 1 || true)"
                if [[ -n "$tl" ]]; then
                    local a_ns=0 c_ns=0
                    if [[ "$tl" =~ asterc_ns=([0-9]+) ]]; then a_ns="${BASH_REMATCH[1]}"; fi
                    if [[ "$tl" =~ clang_ns=([0-9]+) ]]; then c_ns="${BASH_REMATCH[1]}"; fi
                    total_ns_asterc=$(( total_ns_asterc + a_ns ))
                    total_ns_clang=$(( total_ns_clang + c_ns ))
                fi
            else
                if [[ "$bench" == "gemm" ]]; then
                    ASTER_NATIVE="${ASTER_NATIVE:-1}" ASTER_FAST_MATH="${ASTER_FAST_MATH:-1}" ASTER_LINK_ACCELERATE=1 "$ROOT/tools/build/asterc.sh" "$aster_src" "$OUT_DIR/aster_${bench}"
                elif [[ "$bench" == "stencil" ]]; then
                    ASTER_NATIVE="${ASTER_NATIVE:-1}" ASTER_FAST_MATH="${ASTER_FAST_MATH:-1}" ASTER_LINK_OBJ="$ROOT/tools/build/out/stencil_rt.o" "$ROOT/tools/build/asterc.sh" "$aster_src" "$OUT_DIR/aster_${bench}"
                else
                    ASTER_NATIVE="${ASTER_NATIVE:-1}" ASTER_FAST_MATH="${ASTER_FAST_MATH:-1}" "$ROOT/tools/build/asterc.sh" "$aster_src" "$OUT_DIR/aster_${bench}"
                fi
            fi
        fi
        if needs_build "$OUT_DIR/cpp_${bench}" "$cpp_src"; then
            local t0=0 t1=0
            if [[ "$timing" -eq 1 ]]; then t0="$(now_ns)"; fi
            cpp_flags=("${CPP_FLAGS_BASE[@]}" "${CPP_FLAGS_MATH[@]}")
            if [[ "$bench" == "stencil" ]]; then
                cpp_flags+=(-pthread)
            fi
            if [[ "$bench" == "gemm" && "$IS_DARWIN" -eq 1 ]]; then
                cpp_flags+=(-framework Accelerate)
            fi
            clang++ "$cpp_src" "${cpp_flags[@]}" -o "$OUT_DIR/cpp_${bench}"
            if [[ "$timing" -eq 1 ]]; then t1="$(now_ns)"; total_ns_cpp=$(( total_ns_cpp + (t1 - t0) )); fi
        fi
        if needs_build "$OUT_DIR/rust_${bench}" "$rust_src"; then
            local t0=0 t1=0
            if [[ "$timing" -eq 1 ]]; then t0="$(now_ns)"; fi
            rustc "${RUST_FLAGS_BASE[@]}" "$rust_src" -o "$OUT_DIR/rust_${bench}"
            if [[ "$timing" -eq 1 ]]; then t1="$(now_ns)"; total_ns_rust=$(( total_ns_rust + (t1 - t0) )); fi
        fi
    done

    if [[ "$timing" -eq 1 ]]; then
        echo "BUILD_STAGE aster_ns=$total_ns_aster asterc_ns=$total_ns_asterc clang_ns=$total_ns_clang cpp_ns=$total_ns_cpp rust_ns=$total_ns_rust"
    fi
}

if [[ -n "${BENCH_BUILD_TIMING:-}" ]]; then
    TRIALS="${BENCH_BUILD_TRIALS:-7}"

    collect_build_stats() {
        local stage="$1" # clean|incremental
        local aster_ns_list=()
        local cpp_ns_list=()
        local rust_ns_list=()
        local asterc_ns_list=()
        local clang_ns_list=()

        for t in $(seq 1 "$TRIALS"); do
            if [[ "$stage" == "clean" ]]; then
                rm -f "$OUT_DIR"/aster_* "$OUT_DIR"/cpp_* "$OUT_DIR"/rust_* 2>/dev/null || true
                rm -f "$OUT_DIR"/*.ll 2>/dev/null || true
            else
                # Force a minimal rebuild via deterministic mtime bumps so `-nt`
                # checks don't accidentally no-op on coarse timestamp filesystems.
                if [[ "$BENCH_SET" == "fswalk" ]]; then
                    bump_mtime "$ROOT/aster/bench/fswalk/fswalk.as"
                    bump_mtime "$ROOT/aster/bench/fswalk/cpp.cpp"
                    bump_mtime "$ROOT/aster/bench/fswalk/rust.rs"
                else
                    bump_mtime "$ROOT/aster/bench/dot/dot.as"
                    bump_mtime "$ROOT/aster/bench/dot/cpp.cpp"
                    bump_mtime "$ROOT/aster/bench/dot/rust.rs"
                fi
            fi

            line="$(build_all 1)"
            local aster_ns=0 cpp_ns=0 rust_ns=0 asterc_ns=0 clang_ns=0
            for kv in $line; do
                case "$kv" in
                    aster_ns=*) aster_ns="${kv#aster_ns=}" ;;
                    cpp_ns=*) cpp_ns="${kv#cpp_ns=}" ;;
                    rust_ns=*) rust_ns="${kv#rust_ns=}" ;;
                    asterc_ns=*) asterc_ns="${kv#asterc_ns=}" ;;
                    clang_ns=*) clang_ns="${kv#clang_ns=}" ;;
                esac
            done

            aster_ns_list+=("$aster_ns")
            cpp_ns_list+=("$cpp_ns")
            rust_ns_list+=("$rust_ns")
            asterc_ns_list+=("$asterc_ns")
            clang_ns_list+=("$clang_ns")
        done

        ASTER_NS_LIST="$(IFS=,; echo "${aster_ns_list[*]}")" \
        CPP_NS_LIST="$(IFS=,; echo "${cpp_ns_list[*]}")" \
        RUST_NS_LIST="$(IFS=,; echo "${rust_ns_list[*]}")" \
        ASTERC_NS_LIST="$(IFS=,; echo "${asterc_ns_list[*]}")" \
        CLANG_NS_LIST="$(IFS=,; echo "${clang_ns_list[*]}")" \
        python3 - <<'PY'
import os
import statistics

def parse_csv(name: str):
    s = os.environ.get(name, "")
    vals = [int(x) for x in s.split(",") if x.strip()]
    if not vals:
        return [0]
    return vals

def stats(vals):
    med = statistics.median(vals)
    sd = statistics.stdev(vals) if len(vals) > 1 else 0.0
    return med, sd

def fmt_s(ns, decimals=3):
    return f"{ns/1e9:.{decimals}f}s"

def fmt_ms(ns):
    return f"{ns/1e6:.3f}ms"

aster = parse_csv("ASTER_NS_LIST")
cpp = parse_csv("CPP_NS_LIST")
rust = parse_csv("RUST_NS_LIST")
astc = parse_csv("ASTERC_NS_LIST")
clang = parse_csv("CLANG_NS_LIST")

am, asd = stats(aster)
cm, csd = stats(cpp)
rm, rsd = stats(rust)
astm, astsd = stats(astc)
clm, clsd = stats(clang)

print(f"- aster: median {fmt_s(am)}  stdev {fmt_s(asd)}  breakdown: asterc {fmt_ms(astm)} (sd {fmt_ms(astsd)}), clang {fmt_ms(clm)} (sd {fmt_ms(clsd)})")
print(f"- cpp:   median {fmt_s(cm)}  stdev {fmt_s(csd)}")
print(f"- rust:  median {fmt_s(rm)}  stdev {fmt_s(rsd)}")
PY
    }

    echo "Build timing: clean (trials=$TRIALS)"
    collect_build_stats clean
    echo ""

    echo "Build timing: incremental (touch protocol, trials=$TRIALS)"
    collect_build_stats incremental
    echo ""
else
    build_all 0
fi

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

only = os.environ.get("BENCH_ONLY")
if only:
    benches = [b.strip() for b in only.split(",") if b.strip()]

# Use more iterations than "feel good" microbench defaults. Many of the benches
# are in the single-digit millisecond range, where process startup jitter can
# materially move the median. Extra runs + warmup reduces volatility.
RUNS = 9
WARMUP = 2

def _env_int(*keys: str, default: int) -> int:
    for k in keys:
        v = os.environ.get(k)
        if v is not None:
            return int(v)
    return default

FSWALK_RUNS = _env_int("FS_BENCH_IO_RUNS", "FS_BENCH_FSWALK_RUNS", default=7)
FSWALK_WARMUP = _env_int("FS_BENCH_IO_WARMUP", "FS_BENCH_FSWALK_WARMUP", default=1)

print("Bench config:")
print(f"- BENCH_SET: {bench_set}")
if only:
    print(f"- BENCH_ONLY: {only}")
print(f"- benches: {', '.join(benches)}")
print(f"- kernels: runs={RUNS} warmup={WARMUP}")
print(f"- fs: runs={FSWALK_RUNS} warmup={FSWALK_WARMUP}")
print("")

bins = {
    "aster": os.path.join(os.environ.get("BENCH_OUT_DIR", "./tools/bench/out"), "aster_{}"),
    "cpp": os.path.join(os.environ.get("BENCH_OUT_DIR", "./tools/bench/out"), "cpp_{}"),
    "rust": os.path.join(os.environ.get("BENCH_OUT_DIR", "./tools/bench/out"), "rust_{}"),
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
lang_keys = ["aster", "cpp", "rust"]

for bi, bench_name in enumerate(benches):
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

    # Rotate the per-benchmark execution order to avoid systematic "first one
    # pays cold-start" bias against a single language.
    rot = bi % len(lang_keys)
    lang_order = lang_keys[rot:] + lang_keys[:rot]
    for lang in lang_order:
        tpl = bins[lang]
        env = os.environ.copy()
        if bench_name == "fswalk":
            if "FS_BENCH_CPP_MODE" not in env:
                env["FS_BENCH_CPP_MODE"] = "fts"
            list_path = env.get("FS_BENCH_LIST_PATH") or env.get("FS_BENCH_LIST")
            if list_path:
                env["FS_BENCH_LIST"] = list_path
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
    total = len(ratios)
    wins = sum(1 for r in ratios if r < 1.0)
    m5 = sum(1 for r in ratios if r <= 0.95)   # at least 5% faster
    m15 = sum(1 for r in ratios if r <= 0.85)  # at least 15% faster
    m20 = sum(1 for r in ratios if r <= 0.80)  # at least 20% faster (domination)
    print(f"Win rate (aster < baseline): {wins}/{total} = {wins/total*100:.1f}%")
    print(f"Margin >=5% faster (<=0.95x): {m5}/{total} = {m5/total*100:.1f}%")
    print(f"Margin >=15% faster (<=0.85x): {m15}/{total} = {m15/total*100:.1f}%")
    print(f"Margin >=20% faster (<=0.80x): {m20}/{total} = {m20/total*100:.1f}%")

    if os.environ.get("BENCH_REQUIRE_DOMINATION"):
        if m20 != total:
            raise SystemExit(3)
PY
