# ML "Must Pass" Subset (v1)

This file records a curated subset of `libraries/tinygrad/test/` that the Aster
port is expected to match early, plus how the current golden-vector harness
covers it.

## Target Subset (Initial)

- `libraries/tinygrad/test/test_tiny.py::TestTiny::test_plus`
  - Covered by: `add_f32_*` golden cases (elementwise add + checks).
- `libraries/tinygrad/test/test_tiny.py::TestTiny::test_gemm`
  - Covered by: `matmul_f32_*` golden cases (matmul + scalar reduction + grads).
- `libraries/tinygrad/test/unit/test_gradient.py` (selected)
  - Covered by: `*_grad` fields in golden cases (`add`, `matmul`, `permute`).

## Notes

- This is intentionally small to keep iteration tight while we bring up the
  `aster_ml` core IR/autograd/scheduler stack.
