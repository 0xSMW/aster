# Performance Governance

This document describes how Aster performance is measured and kept stable over
time.

## Goals

- Keep benchmark runs **reproducible** (pinned toolchains, fixed datasets).
- Make perf regressions easy to detect (single command, CI-friendly).
- Keep comparisons **fair** across Aster/C++/Rust (same datasets, aligned modes).

## Pinned Toolchains (Official Runs)

Performance numbers recorded in `BENCH.md` should be produced under pinned
toolchains. On macOS, the current pins are:

- `clang`: `Apple clang version 17.0.0 (clang-1700.6.3.2)`
- `rustc`: `rustc 1.92.0 (ded5c06cf 2025-12-08) (Homebrew)`
- `python3` (reporting only): `Python 3.14.2`

Check your toolchains:
```bash
bash tools/ci/toolchains.sh
```

## Perf CI Hook

Run the pinned, deterministic perf harness:
```bash
bash tools/ci/perf.sh
```

What it does:
- Creates a deterministic filesystem root under `.context/perf/fsroot` so fs
  benchmarks don't depend on external paths.
- Enables fixed list modes (`FS_BENCH_LIST_FIXED=1`, `FS_BENCH_TREEWALK_LIST_FIXED=1`)
  and strict dataset checking (`FS_BENCH_STRICT=1`).
- Forces a portable treewalk mode (`FS_BENCH_TREEWALK_MODE=fts`) and aligns C++
  to the same mode (`FS_BENCH_CPP_MODE=fts`).
- Runs `tools/bench/run.sh` with build timing enabled (clean + incremental).

Useful overrides:
- `PERF_BENCH_SET=kernels` (or `fswalk` / `all`)
- `PERF_BUILD_TRIALS=3` (faster; noisier)
- `PERF_STRICT=1` (macOS only): fail if toolchain versions don't match pins

## Recording `BENCH.md` Runs

For a `BENCH.md`-ready snippet, use the recorder:
```bash
BENCH_RECORD_TITLE="perf run" \
BENCH_RECORD_CMD="bash tools/ci/perf.sh" \
tools/bench/record_run.sh
```

