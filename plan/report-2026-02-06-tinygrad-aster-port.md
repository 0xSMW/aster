# Tinygrad Codebase Map for an Aster Port (Research)

## Executive Summary
Tinygrad’s core abstraction is `Tensor`, which is a thin wrapper around a lazily-built `UOp` graph (a DAG of operations) and an optional realized `Buffer`. The user-facing `Tensor` API constructs `UOp`s for math/movement ops, and execution is triggered via `Tensor.realize`, which builds a “sink” of target tensors and turns the `UOp` graph into an ordered `ExecItem` schedule. Scheduling and execution rely on a cacheable rewrite pipeline: (1) normalize the graph, (2) “kernelize/rangeify” it into kernels, (3) linearize and render kernel source, and (4) compile and run kernels through the selected device runtime (CPU, Metal, etc.). Reverse-mode autograd is implemented by rewriting the `UOp` graph using pattern-based gradient rules (and supports higher-order gradients via `Tensor.gradient`). Device backends provide allocators, compilers, and runtime launchers; on macOS, the Metal backend compiles/loads Metal shaders and dispatches command buffers, while the CPU backend JITs kernels to executable code and can execute work across threads. Tinygrad includes extensive tests (`libraries/tinygrad/test/`) that cover correctness, JIT, scheduling, and many model-level behaviors.

For a full port from Python to Aster, the most load-bearing components to replicate are: `UOp` + pattern matching/graph rewriting, the scheduling/realization pipeline, the renderer/codegen pipeline, the device + buffer model (including views/copies), and the autograd rule registry. Higher-level pieces (nn layers, optimizers, weight formats like safetensors/GGUF, model zoo, datasets) build on those foundations and are validated by the existing test suite and apps (notably `tinygrad/apps/llm.py`).

## Scope Reviewed
- `libraries/tinygrad/tinygrad/__init__.py`
- `libraries/tinygrad/tinygrad/tensor.py`
- `libraries/tinygrad/tinygrad/gradient.py`
- `libraries/tinygrad/tinygrad/engine/schedule.py`
- `libraries/tinygrad/tinygrad/engine/realize.py`
- `libraries/tinygrad/tinygrad/engine/memory.py`
- `libraries/tinygrad/tinygrad/uop/__init__.py`
- `libraries/tinygrad/tinygrad/uop/ops.py`
- `libraries/tinygrad/tinygrad/uop/upat.py`
- `libraries/tinygrad/tinygrad/codegen/__init__.py`
- `libraries/tinygrad/tinygrad/renderer/__init__.py`
- `libraries/tinygrad/tinygrad/device.py`
- `libraries/tinygrad/tinygrad/runtime/ops_cpu.py`
- `libraries/tinygrad/tinygrad/runtime/ops_metal.py`
- `libraries/tinygrad/tinygrad/nn/__init__.py`
- `libraries/tinygrad/tinygrad/nn/optim.py`
- `libraries/tinygrad/tinygrad/nn/state.py`
- `libraries/tinygrad/tinygrad/apps/llm.py`
- `libraries/tinygrad/test/test_tensor.py` (spot check)

## Current Behavior Map

### Entry Points
- Package exports: `Tensor`, `TinyJit`, and `UOp` are exposed at import time. See `libraries/tinygrad/tinygrad/__init__.py:1`. `Variable` is defined as `UOp.variable` there as well.
- User-facing API: `Tensor` is the main surface (`libraries/tinygrad/tinygrad/tensor.py:101`). Higher-level layers live in `libraries/tinygrad/tinygrad/nn/__init__.py:1`.
- “App” example: LLM inference and weight-loading flows exist in `libraries/tinygrad/tinygrad/apps/llm.py:1`.

### State / Data Flow
1. **Graph construction**
   - Tensor operations create a new `UOp` by calling `Tensor._apply_uop` and related helpers (`libraries/tinygrad/tinygrad/tensor.py:173`).
   - `Ops` is an enum describing operation kinds (`libraries/tinygrad/tinygrad/uop/__init__.py:13`).
   - `UOp` nodes are hash-consed / cached by a metaclass (`libraries/tinygrad/tinygrad/uop/ops.py:76`, `libraries/tinygrad/tinygrad/uop/ops.py:122`).

2. **Scheduling**
   - `Tensor.realize` calls `Tensor.schedule_with_vars` which creates a `UOp.sink` over target tensors and converts it into an execution schedule (`libraries/tinygrad/tinygrad/tensor.py:253`, `libraries/tinygrad/tinygrad/tensor.py:273`).
   - The scheduler entry point is `complete_create_schedule_with_vars` (`libraries/tinygrad/tinygrad/engine/schedule.py:136`), which:
     - normalizes/caches schedules (including stripping buffer uniqueness and BIND values for cache keys),
     - optionally applies multi-device and “rangeify” transforms,
     - creates a dependency graph, linearizes it, and runs a memory planner (`libraries/tinygrad/tinygrad/engine/memory.py:50`).

3. **Execution**
   - `run_schedule` iterates `ExecItem`s, lowers each to a `Runner` (compiled kernel, copy, view op), and executes it (`libraries/tinygrad/tinygrad/engine/realize.py:193`).
   - Kernel lowering uses `get_program` to produce a `ProgramSpec` and compile code as needed (`libraries/tinygrad/tinygrad/engine/realize.py:11`, `libraries/tinygrad/tinygrad/codegen/__init__.py:150`).

4. **Autograd**
   - `Tensor.backward` computes gradients for “in-scope” tensors that require grad (`libraries/tinygrad/tinygrad/tensor.py:1032`).
   - Core gradient computation is pattern-rule based in `compute_gradient` (`libraries/tinygrad/tinygrad/gradient.py:69`) and is invoked by `Tensor.gradient` (`libraries/tinygrad/tinygrad/tensor.py:1004`).

### External Dependencies
- Python stdlib heavy use (ctypes, struct, weakref, itertools, etc).
- CPU backend uses JIT/executable memory primitives and compiler toolchains (`libraries/tinygrad/tinygrad/runtime/ops_cpu.py:70`).
- Metal backend uses Objective-C bridging and Apple’s Metal compilation/runtime APIs (`libraries/tinygrad/tinygrad/runtime/ops_metal.py:31`).
- Tests depend on NumPy, PyTorch, hypothesis (`libraries/tinygrad/test/test_tensor.py:1`).

### Error Handling / Cancellation
- Errors are primarily surfaced as Python exceptions in scheduling/lowering/compile and runtime execution (examples: schedule cache asserts and lowering exceptions).
- Device synchronization is explicit for backends (e.g., `MetalDevice.synchronize`, `libraries/tinygrad/tinygrad/runtime/ops_metal.py:46`).

## Key Findings (ranked)

1. **`UOp` graph + rewrite system is the “compiler core” of tinygrad**
   - Locations:
     - `libraries/tinygrad/tinygrad/uop/ops.py:122` (`class UOp`)
     - `libraries/tinygrad/tinygrad/uop/ops.py:911` (`class UPat`)
     - `libraries/tinygrad/tinygrad/uop/ops.py:1036` (`class PatternMatcher`)
     - `libraries/tinygrad/tinygrad/uop/ops.py:1278` (`def graph_rewrite`)
   - Observation:
     - Tinygrad builds a typed IR graph (`UOp`) and transforms it with a pattern matcher + rewrite engine before codegen/execution.
   - Relevance to a port:
     - Porting “tinygrad semantics” requires an equivalent IR, rewrite capability, and stable hashing/caching.

2. **Execution is a 2-stage process: schedule creation then schedule execution**
   - Locations:
     - `libraries/tinygrad/tinygrad/tensor.py:253` (`schedule_with_vars`)
     - `libraries/tinygrad/tinygrad/engine/schedule.py:136` (`complete_create_schedule_with_vars`)
     - `libraries/tinygrad/tinygrad/engine/realize.py:193` (`run_schedule`)
   - Observation:
     - `Tensor.realize` does not directly execute ops; it computes an `ExecItem` list and then runs it.
   - Relevance to a port:
     - The Aster implementation needs a similarly deterministic schedule boundary and cache key model if it intends to preserve lazy fusion behavior.

3. **Kernel compilation path is renderer-driven and backend-specific**
   - Locations:
     - `libraries/tinygrad/tinygrad/codegen/__init__.py:24` (`full_rewrite_to_sink`)
     - `libraries/tinygrad/tinygrad/codegen/__init__.py:150` (`get_program`)
     - `libraries/tinygrad/tinygrad/renderer/__init__.py:63` (`ProgramSpec`)
     - `libraries/tinygrad/tinygrad/runtime/ops_cpu.py:133` (`CPUDevice`)
     - `libraries/tinygrad/tinygrad/runtime/ops_metal.py:31` (`MetalDevice`)
   - Observation:
     - Rendering/compilation is abstracted behind `Renderer` and `Compiler`/runtime hooks provided by devices.
   - Relevance to a port:
     - An Aster port needs a clear boundary between IR transforms, rendering, compilation caching, and runtime dispatch.

4. **Autograd is rule-based and supports higher-order gradients**
   - Locations:
     - `libraries/tinygrad/tinygrad/gradient.py:69` (`compute_gradient`)
     - `libraries/tinygrad/tinygrad/tensor.py:1004` (`Tensor.gradient`)
     - `libraries/tinygrad/tinygrad/tensor.py:1032` (`Tensor.backward`)
   - Observation:
     - Gradients are computed by walking the `UOp` graph and applying op-specific rules (and it can be invoked repeatedly for higher-order gradients).
   - Relevance to a port:
     - Feature parity with tinygrad’s training flows requires the backward rule registry and graph-walk mechanics.

5. **Weight formats and model IO are first-class and not “just utilities”**
   - Locations:
     - `libraries/tinygrad/tinygrad/nn/state.py:40` (`safe_load_metadata`, `safe_load`, `safe_save`)
     - `libraries/tinygrad/tinygrad/nn/state.py:358` (`gguf_load`)
     - `libraries/tinygrad/tinygrad/apps/llm.py:1` (Transformer + tokenizer + GGUF loading usage)
   - Observation:
     - Tinygrad uses disk-backed tensors and parsers for common formats (safetensors, GGUF) to support real model loading.
   - Relevance to a port:
     - A complete Aster port needs binary IO, parsing, and at least a subset of quantization decode to run common model artifacts.

6. **The test suite is a practical “spec” for behaviors and corner cases**
   - Locations:
     - `libraries/tinygrad/test/` (many files; example `libraries/tinygrad/test/test_tensor.py:1`)
   - Observation:
     - Tests cover gradients, JIT, scheduling, dtype behavior, and model end-to-end flows.
   - Relevance to a port:
     - Port completeness can be defined by passing a selected subset of this suite and adding cross-impl parity checks.

## Candidate Change Points (port-relevant seams; behavior must remain identical)
- `Tensor` API and data extraction: `libraries/tinygrad/tinygrad/tensor.py` (constructor paths, movement/math ops, `realize`, `data`).
- Core IR + rewrite system: `libraries/tinygrad/tinygrad/uop/*` (Ops, UOp/UPat, PatternMatcher, symbolic behavior).
- Scheduler and memory planner: `libraries/tinygrad/tinygrad/engine/schedule.py`, `libraries/tinygrad/tinygrad/engine/memory.py`.
- Codegen pipeline and renderer interface: `libraries/tinygrad/tinygrad/codegen/__init__.py`, `libraries/tinygrad/tinygrad/renderer/__init__.py`.
- Device + runtime backends:
  - CPU JIT and allocator semantics: `libraries/tinygrad/tinygrad/runtime/ops_cpu.py`.
  - Metal compilation, buffer mgmt, dispatch: `libraries/tinygrad/tinygrad/runtime/ops_metal.py`.
- Autograd rules: `libraries/tinygrad/tinygrad/gradient.py`.
- Model IO: `libraries/tinygrad/tinygrad/nn/state.py` (safetensors, GGUF, state_dict behavior).

## Risks and Guardrails
- **View/reshape semantics**: correctness relies on consistent shape/movement behavior; mismatches will cascade into wrong indexing and gradients.
- **DType and promotion**: tinygrad’s dtype system and casts influence both correctness and kernel selection.
- **Lazy vs eager**: tinygrad fuses and schedules work; a partial port may need a compatibility mode while preserving outputs.
- **Backend parity**: CPU and Metal must agree on numerics and layout; tests that compare to NumPy/PyTorch often assume small tolerances.
- **Caching**: tinygrad aggressively caches `UOp`s and schedules; a port that lacks caching may be “correct” but unusably slow.

## Open Questions / Assumptions
- Target device order for the Aster port: CPU-only first or CPU+Metal from the start on macOS?
- Minimum model target to define “port success” (e.g., `tinygrad/apps/llm.py` GGUF inference, or training a small MNIST model).
- Required subset of the Python test suite to treat as authoritative for the port (full suite vs curated subset).
- Whether Aster intends to preserve tinygrad’s IR and rewrite approach, or to re-implement the same semantics on a different internal compiler model.

## References (paths only)
- `libraries/tinygrad/tinygrad/tensor.py`
- `libraries/tinygrad/tinygrad/uop/__init__.py`
- `libraries/tinygrad/tinygrad/uop/ops.py`
- `libraries/tinygrad/tinygrad/uop/upat.py`
- `libraries/tinygrad/tinygrad/gradient.py`
- `libraries/tinygrad/tinygrad/engine/schedule.py`
- `libraries/tinygrad/tinygrad/engine/realize.py`
- `libraries/tinygrad/tinygrad/engine/memory.py`
- `libraries/tinygrad/tinygrad/codegen/__init__.py`
- `libraries/tinygrad/tinygrad/renderer/__init__.py`
- `libraries/tinygrad/tinygrad/device.py`
- `libraries/tinygrad/tinygrad/runtime/ops_cpu.py`
- `libraries/tinygrad/tinygrad/runtime/ops_metal.py`
- `libraries/tinygrad/tinygrad/nn/state.py`
- `libraries/tinygrad/tinygrad/apps/llm.py`
- `libraries/tinygrad/test/`

