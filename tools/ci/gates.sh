#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

bash "$ROOT/tools/ci/toolchains.sh"

# 1) Build the real compiler binary.
bash "$ROOT/tools/build/build.sh" "$ROOT/asm/driver/asterc.S"

# 1.5) Cache + module import smoke: ensure ASTER_CACHE hits without needing clang.
# (Second invocation forces cache usage by removing `clang` from PATH.)
CACHE_SMOKE_DIR="$ROOT/.context/ci/cache_smoke"
rm -rf "$CACHE_SMOKE_DIR"
mkdir -p "$CACHE_SMOKE_DIR"
CACHE_SMOKE_BIN="$ROOT/.context/ci/cache_smoke_bin"
rm -f "$CACHE_SMOKE_BIN" "$CACHE_SMOKE_BIN.ll"

ASTER_CACHE=1 ASTER_CACHE_DIR="$CACHE_SMOKE_DIR" "$ROOT/tools/build/out/asterc" \
  "$ROOT/aster/tests/pass/use_core_io.as" "$CACHE_SMOKE_BIN"
"$CACHE_SMOKE_BIN" | grep -q '^ok$'

rm -f "$CACHE_SMOKE_BIN" "$CACHE_SMOKE_BIN.ll"
PATH="/nonexistent" ASTER_CACHE=1 ASTER_CACHE_DIR="$CACHE_SMOKE_DIR" "$ROOT/tools/build/out/asterc" \
  "$ROOT/aster/tests/pass/use_core_io.as" "$CACHE_SMOKE_BIN"
"$CACHE_SMOKE_BIN" | grep -q '^ok$'

# 1.6) Lockfile deps smoke: ensure `dep <name> <path>` entries in aster.lock (v1)
# are honored for module resolution.
DEP_SMOKE_DIR="$ROOT/.context/ci/dep_smoke"
rm -rf "$DEP_SMOKE_DIR"
mkdir -p "$DEP_SMOKE_DIR/src" "$DEP_SMOKE_DIR/libraries/foo/src"
cat >"$DEP_SMOKE_DIR/aster.toml" <<'TOML'
name = "dep-smoke"
version = "0.0.0"
TOML
cat >"$DEP_SMOKE_DIR/aster.lock" <<'LOCK'
lock_version = 1
dep foo libraries/foo
LOCK
cat >"$DEP_SMOKE_DIR/libraries/foo/src/lib.as" <<'AS'
def add1(x is i32) returns i32
    return x + 1
AS
cat >"$DEP_SMOKE_DIR/libraries/foo/src/bar.as" <<'AS'
def add2(x is i32) returns i32
    return x + 2
AS
cat >"$DEP_SMOKE_DIR/src/main.as" <<'AS'
use foo
use foo.bar

extern def printf(fmt is String) returns i32

def main() returns i32
    if foo.add1(41) != 42 then
        return 1
    if foo.bar.add2(40) != 42 then
        return 1
    printf("ok\n")
    return 0
AS
DEP_SMOKE_BIN="$DEP_SMOKE_DIR/out"
rm -f "$DEP_SMOKE_BIN" "$DEP_SMOKE_BIN.ll"
"$ROOT/tools/build/out/asterc" "$DEP_SMOKE_DIR/src/main.as" "$DEP_SMOKE_BIN"
"$DEP_SMOKE_BIN" | grep -q '^ok$'

# 2) Run low-level asm unit tests.
bash "$ROOT/asm/tests/run.sh"

# 2.5) Run Aster-level compiler tests (real asterc).
bash "$ROOT/aster/tests/run.sh"

# 2.55) IR conformance (AST/HIR dumps are deterministic).
bash "$ROOT/aster/tests/ir/run.sh"

# 2.6) Optional compiler fuzzing (crash-only, deterministic by default).
# Enable via: ASTER_CI_FUZZ=1 tools/ci/gates.sh
if [[ -n "${ASTER_CI_FUZZ:-}" && "${ASTER_CI_FUZZ}" != "0" ]]; then
  FUZZ_ITERS="${ASTER_CI_FUZZ_ITERS:-25}" \
  FUZZ_MAX_BYTES="${ASTER_CI_FUZZ_MAX_BYTES:-256}" \
  FUZZ_SEED="${ASTER_CI_FUZZ_SEED:-1}" \
  FUZZ_DETERMINISTIC=1 \
  bash "$ROOT/tools/fuzz/run.sh"
fi

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
