# Benchmarks (Developer Notes)

Benchmark history and provenance are recorded in `BENCH.md`.

## Benchmark Harness

Main entrypoint:

```bash
bash tools/bench/run.sh
```

This script:

- Builds Aster benchmarks using the real compiler (`tools/build/out/asterc`).
- Builds C++ and Rust baselines for each benchmark.
- Runs with warmup and multiple trials, reporting medians and variance.
- Can record dataset hashes/bytes/lines for filesystem list inputs.

### Important Environment Knobs

Common:

- `BENCH_SET`:
  - `all` (default)
  - `kernels`
  - `fswalk`
  - etc (see `tools/bench/run.sh`)
- `BENCH_ITERS`: number of benchmark iterations (multiplies inner REPS where used)

Filesystem bench inputs:

- `FS_BENCH_ROOT`: directory to traverse
- `FS_BENCH_MAX_DEPTH`: traversal depth limit
- `FS_BENCH_LIST_FIXED=1`: use fixed list/replay inputs and capture metadata
- `FS_BENCH_TREEWALK_LIST_FIXED=1`: same for treewalk list mode
- `FS_BENCH_STRICT=1`: enforce dataset provenance checks

### Adding A New Benchmark

Add a new directory under `aster/bench/<name>/` with:

- Aster: `<name>.as`
- C++ baseline: `cpp.cpp`
- Rust baseline: `rust.rs`

Then wire it into `tools/bench/run.sh` (both build and run tables). Keep the
benchmark deterministic and make sure it prints a single line result.

## ML Benches

ML has its own lightweight bench runner:

```bash
bash tools/ml/bench/run.sh
```

It reports:

- compile clean time (ns)
- compile no-op time with cache warm (ns)
- runtime median (ns)

ML bench sources live in `aster/bench/ml/`.

## Performance Policy

- Changes must be measured and recorded.
- Keep comparisons fair:
  - same datasets
  - same toolchains
  - same flags
  - avoid "helpful" test-only shortcuts in Aster code paths used by benches

