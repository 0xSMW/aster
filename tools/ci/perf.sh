#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

UNAME_S="$(uname -s 2>/dev/null || true)"
IS_DARWIN=0
if [[ "$UNAME_S" == "Darwin" ]]; then
  IS_DARWIN=1
fi

# Pinned toolchains for "official" perf comparisons. See docs/perf.md.
PIN_CLANG_DARWIN="${PERF_PIN_CLANG:-Apple clang version 17.0.0 (clang-1700.6.3.2)}"
PIN_RUST_DARWIN="${PERF_PIN_RUST:-rustc 1.92.0 (ded5c06cf 2025-12-08) (Homebrew)}"
PIN_PY_DARWIN="${PERF_PIN_PY:-Python 3.14.2}"

STRICT="${PERF_STRICT:-0}" # 1 = fail if pinned toolchains don't match (Darwin only)

check_pin() {
  local name="$1"
  local got="$2"
  local want="$3"
  if [[ "$got" != "$want" ]]; then
    echo "warning: pinned toolchain mismatch for $name" >&2
    echo "  want: $want" >&2
    echo "   got: $got" >&2
    if [[ "$STRICT" == "1" ]]; then
      exit 2
    fi
  fi
}

echo "Perf governance:"
bash "$ROOT/tools/ci/toolchains.sh"

if [[ "$IS_DARWIN" -eq 1 ]]; then
  if command -v clang >/dev/null 2>&1; then
    check_pin "clang" "$(clang --version | head -n 1)" "$PIN_CLANG_DARWIN"
  fi
  if command -v rustc >/dev/null 2>&1; then
    check_pin "rustc" "$(rustc --version)" "$PIN_RUST_DARWIN"
  fi
  if command -v python3 >/dev/null 2>&1; then
    check_pin "python3" "$(python3 --version 2>&1)" "$PIN_PY_DARWIN"
  fi
fi

# Deterministic perf output dir (kept separate from ad-hoc bench runs).
OUT_DIR="${PERF_OUT_DIR:-$ROOT/.context/perf/out}"
mkdir -p "$OUT_DIR"
export BENCH_OUT_DIR="$OUT_DIR"

# Deterministic FS root so perf runs don't depend on external paths.
FSROOT="${PERF_FSROOT:-$ROOT/.context/perf/fsroot}"
mkdir -p "$FSROOT"
if [[ ! -f "$FSROOT/.aster_perf_seed" ]]; then
  mkdir -p "$FSROOT/a/b" "$FSROOT/a/c" "$FSROOT/d"
  printf "hello\n" >"$FSROOT/a/file1.txt"
  printf "world\n" >"$FSROOT/a/b/file2.txt"
  printf "aster\n" >"$FSROOT/a/c/file3.txt"
  printf "perf\n" >"$FSROOT/d/file4.txt"
  printf "seed\n" >"$FSROOT/.aster_perf_seed"
  if [[ ! -e "$FSROOT/link_to_file1" ]]; then
    ln -s "a/file1.txt" "$FSROOT/link_to_file1" || true
  fi
fi

export FS_BENCH_ROOT="$FSROOT"
export FS_BENCH_MAX_DEPTH="${PERF_FS_MAX_DEPTH:-6}"
export FS_BENCH_LIST_FIXED=1
export FS_BENCH_TREEWALK_LIST_FIXED=1
export FS_BENCH_STRICT=1

# Fair defaults: portable treewalk mode (fts) and consistent competitor mode.
export FS_BENCH_TREEWALK_MODE="${PERF_FS_TREEWALK_MODE:-fts}"
export FS_BENCH_CPP_MODE="${PERF_FS_CPP_MODE:-fts}"

# Perf runs always record build timing (clean + incremental).
export BENCH_BUILD_TIMING=1
export BENCH_BUILD_TRIALS="${PERF_BUILD_TRIALS:-5}"

# Allow perf CI to override which suite is run (kernels|fswalk|all).
export BENCH_SET="${PERF_BENCH_SET:-all}"

# Optional: tune IO-run counts (bench runner supports overriding FS runs/warmup).
if [[ -n "${PERF_FS_IO_RUNS:-}" ]]; then
  export FS_BENCH_IO_RUNS="$PERF_FS_IO_RUNS"
fi
if [[ -n "${PERF_FS_IO_WARMUP:-}" ]]; then
  export FS_BENCH_IO_WARMUP="$PERF_FS_IO_WARMUP"
fi

export BENCH_NOTE="${BENCH_NOTE:-perf ci (pinned env): tools/ci/perf.sh}"

bash "$ROOT/tools/bench/run.sh"
