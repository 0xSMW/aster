# Aster ML Architecture + ABI (v1)

This doc defines the **module boundaries** and **stable ABIs** for `aster_ml`.
The intent is to port tinygrad semantics where it matters, while keeping the
implementation Aster-friendly (explicit memory, no hidden allocations).

Status: v1 complete (2026-02-07)

## Design Constraints

- Aster currently has limited struct rvalue/return support; prefer **out-params**
  and pointer-based APIs.
- `slice of T` is currently modeled as a `ptr of T` (no length), so APIs must
  carry explicit lengths/shapes where needed.
- ML correctness harnesses may use Python as an oracle, but **production ML**
  must be native Aster + system toolchains only.

## Module Boundaries (Public Surface)

Target module tree (stable names):

- `aster_ml.dtype`
  - DType codes + promotion lattice + (lossless/safe) cast rules.
- `aster_ml.device`
  - Device selection/canonicalization and backend registration.
- `aster_ml.buffer`
  - Raw buffers, sub-buffers/views, allocators, and host<->device copies.
- `aster_ml.uop.*`
  - UOp IR, hash-consing, pattern matching + rewrite engine, symbolic ints.
- `aster_ml.tensor`
  - Tensor front-end API that builds UOps and provides eager helpers.
- `aster_ml.gradient`
  - Reverse-mode autograd over UOp graphs (rule-based).
- `aster_ml.engine.*`
  - Scheduling, exec-items, schedule caching, memory planning/lifetimes.
- `aster_ml.codegen.*`
  - Linearization and renderers (C-like CPU, Metal).
- `aster_ml.runtime.*`
  - Backends: CPU runtime, Metal runtime, compile caches, launch ABI.
- `aster_ml.nn.*`
  - Model components and serialization/state.

## ABI Conventions (Non-Negotiable)

### 1) Allocation Ownership

- `*_init(out, ...)` allocates any owned heap memory and returns `0` on success,
  non-zero on failure.
- `*_free(x)` frees owned heap memory and zeroes the struct to a safe state.
- Functions that return heap memory must take an explicit `out` pointer (no
  hidden ownership transfer via struct returns).

### 2) Error Signaling

- ML core returns `i32` status codes:
  - `0`: success
  - non-zero: error (module-specific codes; v1 uses `1` for generic failure)
- No panics in hot-path kernels. Panics are allowed in harness/test mode only.

### 3) Scalar Types

- Float: `f32` is the default ML scalar.
- Indices/shapes: `usize` (matches host pointer width).
- DTypes and devices are encoded as small integers (`i32`).

### 4) Buffer ABI (v1)

`aster_ml.buffer.Buffer` is the stable raw memory object:

- `data`: byte pointer (host or device address space)
- `bytes`: allocation size in bytes
- `dtype`: element dtype code
- `device`: device code

Views/sub-buffers are represented by `(base_buffer, byte_offset, bytes)` in v1,
not by pointer arithmetic at call sites.

### 5) Tensor ABI (v1)

For v1 we standardize on a dense strided tensor descriptor:

- storage: `Buffer` + `byte_offset`
- `ndim`: `usize`
- `shape`: pointer to `usize[ndim]` (owned by the tensor)
- `strides`: pointer to `isize[ndim]` (owned by the tensor)
- dtype/device: copied from the buffer at construction

Contiguity is defined by standard row-major strides.

## tinygrad Parity vs Aster-Native Choices

Match tinygrad semantics for:
- dtype promotion/lossless rules (where defined)
- broadcast/movement rules
- UOp caching + schedule caching keys
- autograd accumulation semantics

Allow Aster-native replacements for:
- internal container implementations (hash tables, vectors)
- memory allocators/pools (as long as externally-observable semantics match)
- backend compile caching layout/paths
