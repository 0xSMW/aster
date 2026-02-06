#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# 1) Build the real compiler binary.
bash "$ROOT/tools/build/build.sh" "$ROOT/asm/driver/asterc.S"

# 2) Run low-level asm unit tests.
bash "$ROOT/asm/tests/run.sh"

# 2.5) Run Aster-level compiler tests (real asterc).
bash "$ROOT/aster/tests/run.sh"

# 3) Run the benchmark suite (compile + run). For IO benches, ensure a small,
# deterministic FS root exists so this gate is runnable on a clean checkout.
FSROOT="$ROOT/.context/ci/fsroot"
mkdir -p "$FSROOT"

if [[ ! -f "$FSROOT/.aster_ci_seed" ]]; then
  mkdir -p "$FSROOT/a/b" "$FSROOT/a/c" "$FSROOT/d"
  printf "hello\n" >"$FSROOT/a/file1.txt"
  printf "world\n" >"$FSROOT/a/b/file2.txt"
  printf "aster\n" >"$FSROOT/a/c/file3.txt"
  printf "bench\n" >"$FSROOT/d/file4.txt"
  printf "seed\n" >"$FSROOT/.aster_ci_seed"
  if [[ ! -e "$FSROOT/link_to_file1" ]]; then
    ln -s "a/file1.txt" "$FSROOT/link_to_file1" || true
  fi
fi

export FS_BENCH_ROOT="$FSROOT"
export FS_BENCH_MAX_DEPTH="${FS_BENCH_MAX_DEPTH:-6}"
# Use fixed list modes so fs dataset inputs are stable and metadata (sha/bytes/lines)
# is captured for BENCH.md provenance.
export FS_BENCH_LIST_FIXED=1
export FS_BENCH_TREEWALK_LIST_FIXED=1
export FS_BENCH_STRICT=1

bash "$ROOT/tools/bench/run.sh"
