# Aster

A statically typed, ahead-of-time compiled, native-code programming language with high readability and predictable performance.

This repo ships:

- A real compiler: `tools/build/out/asterc` compiles `.as` source to a native executable by emitting LLVM IR and invoking `clang`.
- A single authoritative gate: `bash tools/ci/gates.sh` (compiler build, asm tests, Aster tests, ML parity, and the benchmark suite).
- A benchmark harness with C++/Rust baselines: `bash tools/bench/run.sh` (history + provenance in `BENCH.md`).

```aster
use core.io

def main() returns i32
    println("hello from aster")
    return 0
```

## Why Aster?

Aster targets the gap between languages that are pleasant to write and languages that run fast. The design principles are:

- **Predictable performance** — typed hot loops compile to tight machine code with no hidden dynamic dispatch or GC barriers.
- **Fast compilation** — content-hash build cache and incremental no-op rebuilds.
- **Allocation transparency** — inner-loop allocations can be forbidden and audited via `noalloc`, enforced transitively by the compiler.
- **C interop** — first-class C ABI interoperability with `extern` declarations.
- **Benchmark-driven evolution** — performance changes are measured against C++ and Rust baselines.

## Performance

Benchmark history is tracked in [`BENCH.md`](BENCH.md).

Note: `BENCH.md` includes a "real `asterc`" epoch where all benchmarks are
compiled from `.as` source by `tools/build/out/asterc` (no shims/templates).

## Docs

- Learning Aster: `docs/learn/README.md`
- Developer docs (compiler/runtime/bench): `docs/dev/README.md`
- ML (tinygrad-inspired): `docs/ml/README.md`
- Aster1 subset (authoritative): `docs/spec/aster1.md`

## Language Overview (Aster1 Subset)

Aster uses indentation-based blocks, explicit control flow, and a C-friendly ABI.

```aster
extern def malloc(n is usize) returns MutString
extern def free(p is MutString) returns ()

def main() returns i32
    var p is MutString = malloc(16)
    if p is null then
        return 1
    free(p)
    return 0
```

Notes:
- `use foo.bar` imports a module (one file = one module).
- `slice of T` is currently a pointer-like type (no embedded length).
- `noalloc` is a transitive effect that forbids allocation inside hot loops.

For the authoritative, bench-complete subset, see `docs/spec/aster1.md`.

## Project Structure

```
asm/           # compiler/runtime (asm + C/ObjC helpers) + asm unit tests
aster/         # apps, Aster tests, benchmark sources, fixtures
docs/          # language/perf/ML docs
libraries/     # reference code (python tinygrad oracle)
src/           # stdlib + `aster_ml` modules
tools/         # build, CI gate, bench harness, ML harnesses
INIT.md        # authoritative spec + milestone tracker
BENCH.md       # benchmark history (incl. "real asterc" epoch)
```

## Getting Started

### Prerequisites

- macOS (arm64 or x86_64) or Linux (x86_64)
- Python 3 (ML oracle + reporting only; not part of the compiler/toolchain)
- Clang (Apple Clang 17+ or LLVM Clang)
- Rust toolchain (for baseline benchmarks only)

### Quickstart (Single Gate)

```bash
bash tools/ci/gates.sh
```

### Build The Compiler

```bash
bash tools/build/build.sh asm/driver/asterc.S   # -> tools/build/out/asterc
```

### Compile And Run A Program

```bash
tools/build/asterc.sh aster/apps/hello/hello.as /tmp/hello
/tmp/hello
```

### Project CLI (`tools/aster/aster`)

```bash
# Build/run with the content-hash cache enabled:
ASTER_CACHE=1 tools/aster/aster run aster/apps/hello/hello.as

# Run the Aster test suite:
ASTER_CACHE=1 tools/aster/aster test

# Run the benchmark suite:
ASTER_CACHE=1 tools/aster/aster bench
```

### Tests (Direct)

```bash
bash asm/tests/run.sh
bash aster/tests/run.sh
bash aster/tests/ir/run.sh
```

### Running Benchmarks

Kernel benchmarks (compute-bound):

```bash
BENCH_SET=kernels tools/bench/run.sh
```

Filesystem benchmarks (I/O-bound):

```bash
FS_BENCH_ROOT=$HOME \
FS_BENCH_MAX_DEPTH=5 \
FS_BENCH_LIST_FIXED=1 \
BENCH_SET=fswalk \
tools/bench/run.sh
```

Full suite:

```bash
FS_BENCH_ROOT=$HOME \
FS_BENCH_MAX_DEPTH=5 \
FS_BENCH_LIST_FIXED=1 \
tools/bench/run.sh
```

Results are written to `$BENCH_OUT_DIR` (default: `.context/bench/out`).

### ML (tinygrad-Inspired, v1)

ML lives under `src/aster_ml/` with correctness guarded by pass tests and a
deterministic golden-vector harness.

```bash
# Generate golden vectors using python tinygrad and run the generated Aster runner.
bash tools/ml/run.sh

# Compile+run ML microbenches (compile clean + compile noop + runtime median).
bash tools/ml/bench/run.sh
```

See `docs/ml/README.md` for details.

### Compiler Environment Variables

The compiler supports cache and link toggles (the gate uses these for coverage):

| Variable | Default | Description |
|----------|---------|-------------|
| `ASTER_COMPILER` | `tools/build/out/asterc` | Path to the `asterc` binary |
| `ASTER_CACHE` | unset | Enable content-hash build cache when set to `1` |
| `ASTER_CACHE_DIR` | `.context/build/cache` | Cache root (when `ASTER_CACHE=1`) |

## Status

The authoritative project tracker is `INIT.md`. The authoritative performance
log is `BENCH.md`. The single CI gate is `tools/ci/gates.sh`.

## Benchmark Suite

The benchmark suite is the primary objective function for development. All optimizer changes must improve the geometric mean or improve at least 70% of benchmarks.

**Kernel benchmarks:** dot product, blocked GEMM, 2D stencil, radix sort, JSON parsing, hash map operations, regex matching, async I/O.

**Filesystem benchmarks:** list/replay traversal (`fswalk`), live traversal with `getattrlistbulk` (`treewalk`), count-only traversal (`dircount`), inventory with hashing (`fsinventory`).

Scoring: `baseline = min(C++, Rust)` under pinned toolchains. Headline = geometric mean of `Aster / baseline` across all benchmarks.

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.
