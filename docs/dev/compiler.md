# Compiler Developer Guide

This document is about **how the production compiler works today** and where to
change it. The authoritative language subset is `docs/spec/aster1.md`.

## High-Level Pipeline

`tools/build/out/asterc` compiles `.as` source to a native executable:

1. **Module graph + preprocessing**
   - Resolve `use <module>` imports from `src/<module>.as` and `aster.lock` deps.
   - Build a deterministic module order.
   - Concatenate module sources into one compilation unit.
2. **Frontend**
   - Lex (indentation-aware).
   - Parse (module items, statements, expressions).
   - Typecheck (Aster1 rules + some post-MVP conveniences like local inference).
   - Effects (`noalloc`) enforcement.
3. **Codegen**
   - Emit LLVM IR to `<out>.ll`.
4. **Native build**
   - Invoke `clang` to compile+link the IR into the final executable.

The single green gate is `tools/ci/gates.sh`.

## Key Files

Driver (CLI + clang invocation):
- `asm/driver/asterc.S`

Compiler core (module graph, lexer/parser/typecheck/codegen, cache):
- `asm/compiler/asterc1_core.c`

Build script (builds `asterc` from asm + C/ObjC helpers):
- `tools/build/build.sh`

## Compilation Unit And Imports (`use`)

### Current Semantics (Include-Style Preamble)

`use` imports are currently include-style:

- Only `use` lines in the **preamble** are treated as imports.
  - Preamble = initial sequence of blank/comment/`use` lines.
- After the first non-blank, non-comment, non-`use` line, `use` stops being
  treated as an import directive.

This is enforced during unit construction in `asm/compiler/asterc1_core.c`.

### Module Resolution

Import names map to paths:

- `use core.io` => `src/core/io.as`
- With lockfile deps (`aster.lock` v1):
  - `dep foo libraries/foo`
  - `use foo` => `libraries/foo/src/lib.as`
  - `use foo.bar` => `libraries/foo/src/bar.as`

The CI gate includes a lockfile dependency smoke test (see `tools/ci/gates.sh`).

### Deterministic Concatenation

The unit source includes markers:

- `# --- module: <path> ---`
- `# --- use: <import> ---` (original imports are preserved for name resolution)

These markers are also hashed as part of the cache key so builds are stable.

## Build Cache (Content-Hash)

The compiler supports a unit-level build cache:

- Enable: `ASTER_CACHE=1`
- Optional cache root: `ASTER_CACHE_DIR=<dir>`

Cache key includes:

- Unit sha256 (concatenated module content).
- `asterc` binary hash (so cache is invalidated when the compiler changes).
- Link and codegen flags (O-level, fast-math, debug, "native", and unit flags).

The gate includes a cache smoke test that:

1. Builds once with clang present.
2. Removes `clang` from `PATH` and ensures the cached build still works.

## Driver Details (clang + linking)

### CLI Contract

The compiler is invoked as:

```bash
tools/build/out/asterc <input.as> <output>
```

It writes LLVM IR to `<output>.ll` and produces the final executable at
`<output>`.

### Output Files

`asterc` produces:

- `<out>`: final executable
- `<out>.ll`: emitted LLVM IR (kept for debugging)

### Auto-Link Helpers (Net/Metal)

Some stdlib modules require runtime helper objects (C/ObjC):

- If the unit imports `src/core/net.as` or `src/core/http.as`, the driver
  auto-links `tools/build/out/net_tls_rt.o` and the required frameworks.
- If the unit imports `src/aster_ml/runtime/ops_metal.as`, the driver auto-links
  `tools/build/out/ml_metal_rt.o` and `-framework Metal -framework Foundation`.

This logic is driven by unit flags set during module graph construction and is
implemented in `asm/driver/asterc.S`.

### Optional Link Flags

- Link an extra object manually: `ASTER_LINK_OBJ=/abs/path/to/foo.o`
- Link Accelerate (macOS): `ASTER_LINK_ACCELERATE=1`

### Timing

Enable end-to-end timing from the driver:

- `ASTER_TIMING=1`

The driver prints a single line with `asterc` time, `clang` time, and total
time. The benchmark harness consumes this to separate compiler vs linker time.

## Debugging And Introspection

### AST/HIR Dumps

The compiler can write deterministic dumps:

- `ASTER_DUMP_AST=/tmp/out.ast`
- `ASTER_DUMP_HIR=/tmp/out.hir`

IR golden tests live under `aster/tests/ir/` and are checked by
`aster/tests/ir/run.sh`.

### Common Debug Workflow

1. Compile a small test with cache disabled to force codegen:
   - `ASTER_CACHE=0 tools/build/asterc.sh aster/tests/pass/use_core_io.as /tmp/t`
2. Inspect `/tmp/t.ll`.
3. If a change affects AST/HIR shape, update the IR golden dumps.

## Environment Variable Reference

| Variable | Meaning |
|---|---|
| `ASTER_CACHE=1` | Enable unit-level content-hash build cache |
| `ASTER_CACHE_DIR` | Cache root (default: `<root>/.context/build/cache`) |
| `ASTER_DEBUG=1` | Build with `-O0 -g` (and keep frame pointers) |
| `ASTER_OLEVEL` | Override optimization level (`0`, `2`, `3`) |
| `ASTER_NATIVE=1` | Pass `-mcpu=native`/`-march=native` (platform dependent) |
| `ASTER_FAST_MATH=1` | Pass `-ffast-math` to clang |
| `ASTER_DUMP_AST` | Write deterministic AST dump to path |
| `ASTER_DUMP_HIR` | Write deterministic HIR dump to path |
| `ASTER_LINK_OBJ` | Link an extra `.o` into the produced binary |
| `ASTER_LINK_ACCELERATE=1` | Link Accelerate framework (macOS) |
| `ASTER_TIMING=1` | Print driver timing breakdown |

## Adding/Changing Language Features

Recommended workflow:

1. Add a failing test under `aster/tests/pass/` or `aster/tests/fail/`.
2. Make the smallest change in `asm/compiler/asterc1_core.c` to pass the test.
3. Run the full gate: `bash tools/ci/gates.sh`.

If the change touches IR structure, also run:

- `bash aster/tests/ir/run.sh`

## Conventions

- Keep compilation deterministic by default.
- Avoid hidden allocations in hot paths (especially lexer/parser).
- Prefer adding coverage via `aster/tests/pass/` and `tools/ml/run.sh` parity.
