# Learn Aster (WIP)

This folder is the living "how to use the language" docs as Aster evolves.

## Quickstart

Build the compiler:

```bash
bash tools/build/build.sh asm/driver/asterc.S
```

Compile and run a sample app (with `use` imports expanded by the build tool):

```bash
ASTER_CACHE=1 tools/build/asterc.sh aster/apps/hello/hello.as .context/hello
.context/hello
```

Format Aster source:

```bash
tools/asterfmt/asterfmt aster/apps/hello/hello.as
tools/asterfmt/asterfmt --check aster/apps/hello/hello.as
```

## Topics

- `use` imports (current semantics: build-time include of `src/<mod>.as`)
- FFI (C ABI) and common libc calls
- Effects (`noalloc`) and performance conventions

Contributor docs:
- `docs/dev/README.md`
