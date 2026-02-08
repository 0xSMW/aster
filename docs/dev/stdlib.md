# Stdlib And FFI (Developer Notes)

Stdlib sources live under `src/core/`.

Aster is intentionally "thin": many modules are small wrappers over libc/OS APIs
so the language can be used for systems programming and benchmarking early.

## Core Modules

Commonly imported modules:

- `src/core/libc.as`
  - Central place for shared libc externs (malloc/free/stdio/etc).
- `src/core/io.as`
  - Convenience printing helpers (`println`, `print_u64`, ...).
- `src/core/time.as`
  - Time helpers (ns timers used by benchmarks).
- `src/core/fs.as`
  - Filesystem traversal APIs (fts/opendir/getattrlistbulk wrappers).
- `src/core/net.as`
  - Minimal TLS socket layer (runtime helper in C).
- `src/core/http.as`
  - Minimal HTTP/1.1 client + SSE parsing on top of `core.net`.

## Where Externs Live

Preferred pattern:
- Put shared libc externs in `src/core/libc.as`.

Pragmatic exceptions:
- Some modules declare externs locally to avoid pulling extra declarations into
  every file that imports `core.libc`.

## FFI Types

The compiler models some C-friendly aliases:

- `String` / `MutString`: byte pointers (NUL-terminated by convention)
- `File`: `FILE*` for stdio APIs

These are meant for interop, not for high-level string safety.

## Auto-Linked Runtime Helpers

Some stdlib modules require helper objects linked into produced binaries:

- Importing `core.net`/`core.http` auto-links `tools/build/out/net_tls_rt.o` and
  the required macOS frameworks.
- Importing `aster_ml.runtime.ops_metal` auto-links `tools/build/out/ml_metal_rt.o`
  plus Metal/Foundation frameworks.

This is handled by `asterc` at link time (see `docs/dev/compiler.md`).

## Safety And Determinism

- Treat pointer arithmetic and indexing as unsafe; the compiler does not insert
  bounds checks in hot code paths.
- Prefer deterministic IO in tests (fixed inputs, small outputs).

For the memory model and effects, see `docs/spec/memory_effects_ffi.md`.

