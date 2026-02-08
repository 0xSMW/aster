# Developer Docs

This folder is for contributors working on the Aster compiler, runtime, standard
library, benchmarks, and the tinygrad-inspired ML stack.

If you are looking for the language subset supported by the production compiler,
start at `docs/spec/aster1.md`.

## Quick Commands

Single authoritative gate:

```bash
bash tools/ci/gates.sh
```

Build the compiler:

```bash
bash tools/build/build.sh asm/driver/asterc.S   # -> tools/build/out/asterc
```

Run tests:

```bash
bash asm/tests/run.sh
bash aster/tests/run.sh
bash aster/tests/ir/run.sh
```

Run the benchmark suite:

```bash
FS_BENCH_ROOT=$HOME FS_BENCH_MAX_DEPTH=5 FS_BENCH_LIST_FIXED=1 bash tools/bench/run.sh
```

ML correctness + benches:

```bash
bash tools/ml/run.sh        # python tinygrad oracle -> golden -> Aster parity runner
bash tools/ml/bench/run.sh  # compile clean + compile noop + runtime medians
```

## Repo Map (Contributor View)

- `asm/`
  - `asm/driver/asterc.S`: compiler driver (CLI, caching, clang invocation, link flags)
  - `asm/compiler/asterc1_core.c`: compiler core (module graph, lexer/parser/typecheck/IR emit)
  - `asm/runtime/`: low-level runtime helpers
  - `asm/tests/`: assembly unit tests
- `src/`
  - `src/core/*.as`: stdlib modules (`core.io`, `core.fs`, `core.http`, ...)
  - `src/aster_ml/*.as`: ML stack (dtype/device/buffer/tensor/autograd/schedule/runtime/nn/state)
- `aster/`
  - `aster/apps/`: runnable example programs
  - `aster/tests/`: language-level tests (pass/fail) and IR golden dumps
  - `aster/bench/`: benchmark sources (Aster + C++ + Rust)
- `tools/`
  - `tools/ci/gates.sh`: the only green gate
  - `tools/build/`: build wrappers
  - `tools/bench/`: benchmark harness
  - `tools/ml/`: ML parity + bench harnesses (python is oracle only)
- `INIT.md`: authoritative task tracker/spec
- `BENCH.md`: benchmark history with provenance

## What To Read Next

- Compiler internals: `docs/dev/compiler.md`
- Language notes (as implemented): `docs/dev/language.md`
- Stdlib + FFI notes: `docs/dev/stdlib.md`
- Assembly notes: `docs/dev/asm.md`
- Tests and gates: `docs/dev/testing.md`
- Bench harness: `docs/dev/bench.md`
- Examples: `docs/dev/examples.md`
