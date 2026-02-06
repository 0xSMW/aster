# Benchmark Harness

The benchmark runner compiles and runs:
- Aster sources via the real compiler (`tools/build/out/asterc`).
- C++ baselines via `clang++ -O3`.
- Rust baselines via `rustc -O`.

## Run

All benches (kernels + fs benches when `FS_BENCH_ROOT` is set):
```bash
tools/bench/run.sh
```

Kernels only:
```bash
BENCH_SET=kernels tools/bench/run.sh
```

Filesystem benches only:
```bash
BENCH_SET=fswalk FS_BENCH_ROOT=/path/to/root tools/bench/run.sh
```

## Fixed FS Inputs (Recommended)

For repeatable fswalk/treewalk inputs, enable fixed list modes. The runner will
cache deterministic lists under `.context/bench/data/` and write a `.meta` file
with `sha256/bytes/lines`.

```bash
FS_BENCH_ROOT=/path/to/root \
FS_BENCH_MAX_DEPTH=6 \
FS_BENCH_LIST_FIXED=1 \
FS_BENCH_TREEWALK_LIST_FIXED=1 \
FS_BENCH_STRICT=1 \
tools/bench/run.sh
```

Useful knobs:
- `FS_BENCH_LIST_MAX_LINES`, `FS_BENCH_TREEWALK_LIST_MAX_LINES`: cap list size.
- `FS_BENCH_TREEWALK_MODE`: `bulk` (getattrlistbulk) or `fts`.
- `FS_BENCH_CPP_MODE`: force C++ mode (`fts` or `bulk`) for apples-to-apples.
