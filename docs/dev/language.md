# Language Developer Notes

This document describes the **Aster language as implemented today**. The
bench-complete subset is specified in `docs/spec/aster1.md`.

## Source Structure And Modules

- One file is one module.
- `use foo.bar` imports another module.
- Current import semantics are include-style:
  - `use` directives must appear in the preamble (top-of-file before code).

See `docs/dev/compiler.md` for the exact mechanics.

## Basic Syntax

- Indentation-based blocks.
- Comments start with `#` to end of line.
- Control flow:
  - `if <cond> then ... [else ...]`
  - `while <cond> do ...`
  - `break`, `continue`, `return`

## Types (Current)

Core scalar types:

- Integers: `i8/u8/i16/u16/i32/u32/i64/u64`, `usize/isize`
- Floats: `f32/f64`

Pointer-like types (lowered to pointers in LLVM IR):

- `ptr of T`
- `slice of T` (currently pointer-only, no embedded length)
- `ref T`, `mut ref T` (borrow-like, implemented as pointers)

FFI convenience aliases:

- `String`, `MutString`: C `char*`-style pointers
- `File`: opaque `FILE*` for stdio externs

## Declarations

### Functions

```aster
def add1(x is i32) returns i32
    return x + 1
```

### Locals (`var`/`let`)

Locals can be typed explicitly:

```aster
var x is i32 = 42
```

Or inferred from the initializer expression:

```aster
var x = 42
```

Notes:
- Inference requires an initializer (`var x = <Expr>`).
- Inference is implemented in the compiler scan pass so the type is known
  before codegen.

### Structs

```aster
struct Pair
    var a is i32
    var b is i32
```

Struct layout is C-like (field order, alignment, padding). Current semantics are
storage-based (bytewise copies).

### Externs (C ABI)

```aster
extern def malloc(n is usize) returns MutString
extern def free(p is MutString) returns ()
```

## Effects: `noalloc`

`noalloc` is a transitive effect used to keep hot loops allocation-free:

```aster
noalloc def dot(a is slice of f64, b is slice of f64, n is usize) returns f64
    var sum is f64 = 0.0
    var i is usize = 0
    while i < n do
        sum = sum + a[i] * b[i]
        i = i + 1
    return sum
```

The compiler rejects `noalloc` functions that (directly or indirectly) call
allocator functions.

## Memory Model Notes

- Pointer arithmetic and indexing are unchecked. Out-of-bounds dereference is
  undefined behavior (this is intentional for optimization).
- Many stdlib modules are thin FFI wrappers around libc and OS APIs.

See `docs/spec/memory_effects_ffi.md`.

## Common Patterns

### Out-Params Over Struct Returns

Many internal libraries prefer:

- `*_init(out, ...) returns i32` for fallible allocation
- `*_free(x)` for cleanup

This avoids relying on complex rvalue/return semantics.

### Deterministic Outputs For Tests

Tests typically:

- Print `ok` on success.
- Exit non-zero on failure.
- Use `.stdout` golden files only when needed.

## Where To Add Examples

- Runnable apps: `aster/apps/<name>/<name>.as`
- Benchmarks: `aster/bench/<bench>/`
- Tests:
  - compile+run ok: `aster/tests/pass/`
  - expected compile error: `aster/tests/fail/`
  - deterministic AST/HIR dumps: `aster/tests/ir/`

