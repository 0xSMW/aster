# Aster Memory Model, Effects, and FFI ABI (Draft)

Status: draft (post-Aster1)

This document is the **authoritative** description of:
- Aster's low-level memory behavior (what is defined vs undefined),
- the effect system surface (`noalloc`, `unsafe`, IO/network effects),
- and the foreign-function interface ABI (C interop).

It is written to support high-performance numerical/scientific workloads and to
keep the compiler free to optimize aggressively without violating language
promises.

## Memory Model

### Values, References, and Pointers

- **Value types** live in registers or stack slots and follow normal SSA/lifetime
  semantics in the compiler.
- `ref T` and `mut ref T` are **borrowed** references. They are intended to be
  statically checked (see Borrowing).
- `ptr of T` is an **opaque raw pointer**. It is not statically tracked for
  safety and may alias freely.
- `slice of T` is a fat pointer in the full language (pointer + length). In
  Aster1 it is modeled as `ptr of T` for simplicity.

### Defined vs Undefined Behavior (UB)

The following are **undefined behavior** (the compiler may assume they never
happen):
- Dereferencing a null pointer/reference.
- Dereferencing a pointer/reference that does not point to a live object.
- Out-of-bounds access on a slice/array when bounds checks are enabled.
- Misaligned loads/stores for a type's required alignment.
- Violating `mut ref` uniqueness rules (aliasing a mutable reference).
- Data races (concurrent unsynchronized mutation) once threads are supported.

### Integers and Floats

- Integer arithmetic is **two's complement modular arithmetic** (wraps on
  overflow) for all fixed-width integer types. Signedness affects comparisons,
  shifts, casts, and formatting, but not the underlying bit pattern.
- Shifts are defined for shift counts in-range (`0 <= n < bit_width`). Shifting
  by an out-of-range amount is UB.
- Floating point uses IEEE-754 semantics for the underlying hardware unless an
  explicit fast-math mode is enabled by the compiler profile.

### Aliasing (Borrowing)

The intended aliasing model is:
- `ref T` permits shared aliasing (many `ref` to the same location is ok).
- `mut ref T` is **unique**: at any point in time there may be at most one live
  `mut ref` to a given location, and no `ref` may alias it.
- Raw pointers (`ptr of T`) are outside the borrow checker and must be used
  carefully; mixing raw pointers and references is `unsafe`.

Borrow checking is staged in; Aster1 does not enforce all of this yet.

## Effects

### Overview

Aster is effect-pure by default. Effects are explicit in function signatures and
are enforced transitively.

Planned effect kinds:
- `noalloc`: function (and all callees) must not allocate.
- `unsafe`: function may perform operations that can cause UB if misused (raw
  pointer deref, FFI, etc).
- `io`: filesystem/process/time operations.
- `net`: networking operations (DNS/TCP/TLS/HTTP).

### `noalloc`

`noalloc` is designed for inner-loop HPC kernels and is a non-negotiable
performance contract.

Rules:
- A `noalloc` function must not call allocating APIs (`malloc`, `calloc`, any
  stdlib allocator) unless those calls are proven dead/elided.
- A `noalloc` function may call another function only if that function is also
  `noalloc` (or is proven not to allocate).
- `noalloc` must be sound under inlining and LTO; it is a property of the IR,
  not of source formatting.

Implementation note: the compiler should tag known allocator symbols and treat
them as effectful.

## FFI ABI (C)

### Calling Convention

The default ABI for `extern def` is the platform C ABI:
- Darwin arm64: AAPCS64 / Apple arm64 ABI.
- x86_64: SysV AMD64 ABI.

### Type Mapping

Scalar mapping (Aster -> C):
- `i8/u8` -> `int8_t/uint8_t`
- `i16/u16` -> `int16_t/uint16_t`
- `i32/u32` -> `int32_t/uint32_t`
- `i64/u64` -> `int64_t/uint64_t`
- `isize/usize` -> `intptr_t/uintptr_t`
- `f64` -> `double`
- `()` / `void` -> `void`

Pointer-like:
- `String` / `MutString` -> `char*` / `unsigned char*` (NUL-terminated by
  convention; not length-tracked)
- `ptr of T` -> `T*` (opaque pointer at the ABI level)
- `ref T` / `mut ref T` -> `T*` (borrow rules are Aster-level only)
- `slice of T` -> planned as `(T*, usize)` in the full language; Aster1 treats
  it as `T*`

### Struct Layout

Struct layout is C-compatible:
- field order is preserved,
- alignment is natural alignment per field,
- padding follows the platform ABI.

### Variadics

Some libc functions are true C variadics. When declared as variadic in Aster,
they lower to `...` in LLVM IR/ABI. Example: `printf`.

## Tooling Notes

This spec is paired with:
- `docs/spec/aster1.md` for the current MVP subset,
- `INIT.md` Section 4 for the staged implementation plan.

