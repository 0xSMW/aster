# FFI (C ABI) (Aster1)

Aster1 calls C functions via `extern def` with explicit types.

Example:

```aster
extern def printf(fmt is String) returns i32

def main() returns i32
    printf("hello\n")
    return 0
```

Notes:
- Pointers and strings are currently represented as `ptr`/`String` (C `char*`).
- Structs used for FFI must match the platform ABI; see `docs/spec/memory_effects_ffi.md`.
- For variadic functions, the compiler has a conservative allowlist (currently includes `printf`, `open`, `openat`).

