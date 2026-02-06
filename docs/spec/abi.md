# Aster ABI and object format targets

This document defines the target ABIs and object formats for the assembly-first
compiler. The v1 compiler uses the platform C ABI for all generated code to
minimize interop friction and reduce initial complexity.

## 1. Targets

- Primary target is the host triple detected at build time.
- Supported v1 targets:
  - x86_64 System V (Linux and macOS)
  - arm64 macOS (AAPCS64 / Darwin)
- Additional targets are added after self-hosting is stable.

## 2. Object formats

- macOS: Mach-O (ld64 or lld)
- Linux: ELF64 (ld.lld or ld)
- Windows: COFF/PE (future)

## 3. ABI policy

- Internal Aster calls use the platform C ABI in v1.
- FFI uses the C ABI by default; `extern` declarations must match.
- Aster may introduce an internal fast ABI later behind a compiler flag.

## 4. x86_64 System V calling convention (summary)

- Integer and pointer args: RDI, RSI, RDX, RCX, R8, R9
- Floating point args: XMM0 to XMM7
- Return values: RAX for integer and pointer, XMM0 for float
- Stack alignment: 16 bytes at call boundaries
- Callee-saved: RBX, RBP, R12 to R15
- Red zone: 128 bytes below RSP available for leaf functions; disabled by default

## 5. arm64 macOS calling convention (summary)

- Integer and pointer args: X0 to X7
- Floating point args: V0 to V7
- Return values: X0 for integer and pointer, V0 for float
- Stack alignment: 16 bytes at call boundaries
- Callee-saved: X19 to X28, FP (X29), LR (X30) when used

## 6. Aggregate returns

- Small aggregates return in registers where the ABI allows.
- Aggregates larger than 16 bytes use a hidden sret pointer as the first arg.
- The compiler uses a deterministic, C-compatible layout for all public structs.

## 7. Symbol naming and sections

- Mach-O: global symbols use a leading underscore.
- ELF: global symbols use the raw symbol name.
- Sections: text, rodata, data, bss with natural alignment.

## 8. Unwinding and debug

- Unwind information uses the platform standard (eh_frame or compact unwind).
- Debug info is emitted in v2; v1 focuses on correctness and performance.

## 9. Standard library value ABI (v1 targets)

The Aster0 subset used for benchmarks models slices as raw pointers with
explicit length arguments. The production ABI uses fixed layouts for common
value types to enable interop and deterministic codegen.

### Slice

```
struct Slice[T] {
    ptr: *T
    len: usize
}
```

- Passed as two registers when possible (ptr, len).
- Returned as two registers when size permits, otherwise sret.

### String

```
struct String {
    ptr: *u8
    len: usize
}
```

- UTF-8 by convention; not null-terminated.
- Interop with C requires explicit conversion helpers.

### Array

```
struct Array[T, N] {
    data: [T; N]
}
```

- Arrays are value types with inline storage.
- Passing/returning follows the aggregate ABI rules in section 6.

### Aster0 bench subset (temporary)

- `slice of T` is treated as `*T` with length passed separately.
- `String` is treated as `char *` for libc interop.
- This will be retired once the native Aster frontend/codegen is implemented.
