# Testing And Gates

This repo is run by a single authoritative gate:

```bash
bash tools/ci/gates.sh
```

It is designed to be green on a clean checkout.

## Test Layers

### 1) asm unit tests

```bash
bash asm/tests/run.sh
```

These validate low-level runtime and frontend primitives in assembly.

### 2) Aster language tests (compile+run)

```bash
bash aster/tests/run.sh
```

Conventions:
- `aster/tests/pass/*.as`: must compile and exit 0. Prefer printing `ok`.
- `aster/tests/fail/*.as`: must fail compilation.
- Optional golden files:
  - `aster/tests/pass/<name>.stdout`
  - `aster/tests/pass/<name>.stderr`

### 3) Deterministic AST/HIR dumps

```bash
bash aster/tests/ir/run.sh
```

This uses:
- `ASTER_DUMP_AST=/path`
- `ASTER_DUMP_HIR=/path`

and compares against tracked goldens in `aster/tests/ir/`.

### 4) ML parity (python tinygrad oracle)

```bash
bash tools/ml/run.sh
```

The gate runs a small deterministic configuration:
- `ML_GOLDEN_SEED` (default: 1)
- `ML_GOLDEN_FUZZ_CASES` (default: 5 in gate)

Policy note: Python is used only as a correctness oracle and is not part of the
compiler/toolchain.

### 5) Benchmarks

```bash
bash tools/bench/run.sh
```

The gate uses a synthetic FS dataset under `.context/ci/fsroot` so the IO
benchmarks are runnable everywhere.

## Adding A New Test

Recommended patterns:

- For compiler/language behavior: add a file under `aster/tests/pass/` or
  `aster/tests/fail/`.
- Keep runtime output stable and small.
- Only use `.stdout` goldens when checking exact output matters.

## Debugging Failures

Useful steps:

1. Re-run the failing test with cache disabled:
   - `ASTER_CACHE=0 bash aster/tests/run.sh`
2. Inspect the generated LLVM IR in `.context/aster/tests/out/<test>.ll`.
3. If the failure is in linking, check whether the unit imported `core.http`
   or `aster_ml.runtime.ops_metal` (these trigger auto-link objects/frameworks).

## Optional Fuzzing

The gate can run deterministic crash-only fuzzing when enabled:

```bash
ASTER_CI_FUZZ=1 bash tools/ci/gates.sh
```

Or directly:

```bash
bash tools/fuzz/run.sh
```

