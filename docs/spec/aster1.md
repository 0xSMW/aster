# Aster1 (MVP) Language Subset

This document defines the **bench-complete** Aster surface supported by the
production `asterc` compiler today (the subset required to compile and run the
benchmark suite from `.as` source).

Status: 2026-02-06

## Goals

- High readability, indentation-based syntax.
- Direct access to low-level performance primitives (FFI, pointers, explicit
  types).
- A stable MVP that benchmarks can depend on.

## Non-Goals (For Aster1)

- Whole-program generics/traits, modules/imports, and a full stdlib.
- Ownership/borrow checking.
- Full struct rvalue semantics (Aster1 represents structs by storage).

## Lexical Structure

- UTF-8 source is accepted; tokenization is byte-oriented.
- Newlines and indentation define block structure.
- Comments start with `#` and run to end-of-line.

### Literals

- Integer: decimal (`123`) and hex (`0xFF`).
- Float: `digits '.' digits` (e.g. `0.0`, `3.1415`).
- String: double-quoted with basic escapes (`\\n`, `\\r`, `\\t`, `\\\\`, `\\"`).
- Char: single-quoted with basic escapes (`'a'`, `'\\n'`, `'\\''`).
- `null`, `true`, `false`.

## Declarations

### Constants

```aster
const N is usize = 1024
const MSG is String = "hello"
const NL is u8 = '\n'
```

Constants are compile-time and may be `int`, `float`, `string`, or `char`.

### Extern Functions (C ABI)

```aster
extern def malloc(n is usize) returns String
extern def free(p is String) returns ()
extern def printf(fmt is String, a is u64) returns i32
```

- The ABI is C ABI.
- `String`/`MutString` are currently represented as `ptr u8` (NUL-terminated).
- `()` is the void type.

### Structs

```aster
struct Point
    var x is f64
    var y is f64
```

Struct layout is C-like (field order, alignment, padding). In Aster1, **struct
values are represented by their storage**; copying is bytewise.

### Functions

```aster
def main() returns i32
    return 0
```

## Types

Builtins:
- `i8`, `u8`, `i16`, `u16`, `i32`, `u32`, `i64`, `u64`, `usize`, `isize`
- `f64`
- `void` and `()` (void)
- `String`, `MutString`, `File` (currently opaque pointers for FFI)

Pointer-like:
- `ptr of T` (opaque pointer in LLVM IR, pointee tracked for codegen)
- `slice of T` (currently modeled as `ptr of T` in Aster1)
- `ref T` and `mut ref T` (currently modeled as pointers in Aster1)

## Statements

- `var name is Type = expr`
- `let name is Type = expr`
- Assignment: `lvalue = expr`
- `if cond then ...` with optional `else` / `else if`
- `while cond do ...`
- `break`, `continue`
- `return` / `return expr`

**Explicit types only:** locals must use `is Type` (no type inference in Aster1).

## Expressions

- Arithmetic: `+ - * /`
- Bitwise: `& | ^`, shifts `<< >>`
- Comparison: `< <= > >= == !=`, pointer equality via `is` / `is not`
- Boolean: `and`, `or`, unary `not` (short-circuit in conditions)
- Unary: `-expr`, `&lvalue`, `*ptr`
- Call: `f(a, b, c)`
- Indexing: `ptr[i]`
- Field access: `struct_lvalue.field`

## Compiler Pipeline

`asterc` currently compiles:

1. Aster source -> tokens (assembly lexer)
2. Parse + typecheck (Aster1 rules)
3. Emit LLVM IR (`.ll`)
4. Invoke `clang -O3` to produce the executable

## Tests

The Aster1 subset is exercised by:

- `aster/tests/pass/` (must compile and run)
- `aster/tests/fail/` (must fail compilation)

Run: `bash aster/tests/run.sh`

## Lookahead: tinygrad-as-Aster

To support a native tinygrad port without breaking Aster1, the design needs:

- SIMD-friendly numerics and stable scalar semantics (`f32`, vector types later).
- Explicit memory layout controls for tensors (row-major/strides, packed structs).
- A kernel authoring path: predictable loops, pointers/slices, and FFI.
- A path to parametric polymorphism (generics/traits) that can be layered above
  Aster1 without changing Aster1 semantics.

