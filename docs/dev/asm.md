# Assembly (Developer Notes)

The Aster compiler and runtime are implemented "assembly-first": performance
critical paths use `.S` sources with a macro layer for readability.

For the canonical conventions, see `docs/spec/assembly-conventions.md`.

## Layout

- `asm/macros/`: macro includes (`base.inc`, ABI aliases, helpers)
- `asm/runtime/`: runtime primitives and helpers
- `asm/compiler/`: compiler implementation (mix of asm + small C/ObjC helpers)
- `asm/driver/`: the `asterc` driver (CLI, clang invocation, linking)
- `asm/tests/`: unit tests for asm components

## Building

Build the compiler:

```bash
bash tools/build/build.sh asm/driver/asterc.S
```

Build and run an assembly unit test:

```bash
bash tools/build/build.sh asm/tests/hello.S
tools/build/out/hello
```

Run all asm tests:

```bash
bash asm/tests/run.sh
```

## Debugging

- Use `ASTER_DEBUG=1` (driver debug mode) when you want DWARF symbols and frame
  pointers in produced binaries.
- Keep changes small and covered by `asm/tests/` where possible.
