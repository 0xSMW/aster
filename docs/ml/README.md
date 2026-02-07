# Aster ML (tinygrad Port) (WIP)

This folder tracks the post-production ML work: a native Aster port of
[`tinygrad`](../../libraries/tinygrad/).

Goals:
- Define a concrete parity target surface for v1.
- Build a deterministic python parity harness (golden vectors + gradients).
- Implement the Aster port (`aster_ml`) with CPU + Metal backends on macOS.

Entry docs:
- `docs/ml/tinygrad_parity.md`: v1 parity surface + acceptance criteria.
- `docs/ml/architecture.md`: module boundaries + ABI conventions.
- `tools/ml/must_pass.md`: curated "must pass" subset tracker.

Quickstart:

```bash
# Generates golden vectors using python tinygrad and runs the generated Aster parity runner.
bash tools/ml/run.sh
```

Env knobs:
- `ML_GOLDEN_SEED=...` (default: 1)
- `ML_GOLDEN_FUZZ_CASES=...` (default: 5; each adds add/matmul/permute cases)
