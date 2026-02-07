# tinygrad Parity Target (Aster ML v1)

Reference implementation:
- `libraries/tinygrad/` (python)

This doc defines what "v1 parity" means for the Aster port.

## Parity Surface (v1)

The Aster port must be able to run and match (within tight numerical tolerances):

- Core dtype system: `tinygrad/dtype.py`
- Device + buffer model: `tinygrad/device.py`
- UOp IR + rewrite engine: `tinygrad/uop/*`
- Tensor API: `tinygrad/tensor.py`
- Movement/shape semantics: `tinygrad/mixin/movement.py` + UOp shape rules
- Math/reduction ops used by:
  - `libraries/tinygrad/test/` (unit tests)
  - `tinygrad/apps/llm.py` (smoke)
- Autograd: `tinygrad/gradient.py` + `Tensor.backward`
- Scheduling + memory planning:
  - `tinygrad/engine/schedule.py`
  - `tinygrad/engine/memory.py`
- Codegen pipeline:
  - `tinygrad/codegen/*`
  - `tinygrad/renderer/*`
- CPU backend:
  - `tinygrad/runtime/ops_cpu.py`
- macOS Metal backend:
  - `tinygrad/runtime/ops_metal.py`
- Serialization/model IO:
  - `tinygrad/nn/state.py`
- NN layers + optimizers:
  - `tinygrad/nn/*`

## Acceptance Criteria

1. **Golden vector parity** (deterministic):
   - For a curated set of ops/shapes/dtypes, Aster results must match python
     tinygrad within tolerance.
   - Gradients must match for the curated set.

2. **Test parity** (subset then full):
   - Aster must pass a curated "must pass" subset of `libraries/tinygrad/test/`
     (recorded in the harness config).
   - Then expand to the full `libraries/tinygrad/test/` suite as coverage grows.

3. **Caching behavior is preserved**:
   - UOp hash-consing and schedule cache keys must remain stable and effective.

## Mapping To Aster Modules

Planned Aster module tree (subject to change as parity work proceeds):

- `src/aster_ml/dtype.as`
- `src/aster_ml/device.as`
- `src/aster_ml/uop/*.as`
- `src/aster_ml/tensor.as`
- `src/aster_ml/gradient.as`
- `src/aster_ml/engine/*.as`
- `src/aster_ml/codegen/*.as`
- `src/aster_ml/runtime/*.as`
- `src/aster_ml/nn/*.as`

## Running The Reference Tests

The python reference is used only as a correctness oracle and for generating
golden vectors.

Example (from repo root):

```bash
python3 -c "import sys; sys.path.insert(0,'libraries/tinygrad'); import tinygrad; print(tinygrad.__version__ if hasattr(tinygrad,'__version__') else 'ok')"
```

