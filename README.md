# Aster

A statically typed, ahead-of-time compiled, native-code programming language with Python/Ruby-like ergonomics and C++/Rust-class performance. Aster began as a single prompt and represents 50+ iterations with gpt-5.2/3-codex. This project exists as an experiment and analysis of novel computer science capabilities in Codex models. 

```aster
def dot(a is slice of f64, b is slice of f64, n is usize) returns f64
    var sum is f64 = 0.0
    var i is usize = 0
    while i < n do
        sum = sum + a[i] * b[i]
        i = i + 1
    return sum
```

## Why Aster?

Aster targets the gap between languages that are pleasant to write and languages that run fast. The design principles are:

- **Predictable performance** — typed hot loops compile to tight machine code with no hidden dynamic dispatch or GC barriers.
- **Fast compilation** — incremental builds in dev mode; optimized binaries in release mode.
- **Allocation transparency** — inner-loop allocations can be forbidden and audited via `noalloc`, enforced transitively by the compiler.
- **C interop** — first-class C ABI interoperability with `extern` declarations.
- **Benchmark-driven evolution** — every optimization must improve a benchmark-based objective function.

## Performance

Aster is benchmarked continuously against C++ and Rust baselines under pinned toolchains. The headline metric is the geometric mean of `(Aster median / min(C++, Rust median))` across the full suite.

**Latest result (Run 048): 0.998x geometric mean** — near parity with C++/Rust.

| Benchmark | Ratio | | Benchmark | Ratio |
|-----------|-------|-|-----------|-------|
| dot | 0.832x | | fswalk | 0.810x |
| gemm | 1.023x | | treewalk | 0.995x |
| stencil | 0.986x | | dircount | 1.020x |
| sort | 0.890x | | fsinventory | 1.035x |
| json | 1.125x | | | |
| hashmap | 1.125x | | | |
| regex | 1.038x | | | |
| async_io | 1.174x | | | |

> Ratios < 1.0 mean Aster is faster than the baseline. Environment: Darwin arm64, Apple Clang 17.0.0, Rust 1.92.0.

Full benchmark history is tracked in [`BENCH.md`](BENCH.md).

## Language Overview

### Syntax at a glance

Aster uses indentation-based blocks, keyword-driven type annotations, and explicit control flow:

```aster
class Counter
    var value is i64

    def init(start is i64) returns Self
        let self is Self = alloc Counter
        self.value = start
        return self

    def inc(self is ref Self) returns i64
        self.value = self.value + 1
        return self.value

trait Printable
    def print(self is ref Self) returns Result of ()

impl Printable for Counter
    def print(self is ref Self) returns Result of ()
        io.print("count=", self.value)
        return Ok(())
```

### Generics and traits

```aster
trait Ord of T
    def lt(a is T, b is T) returns bool

def max of T where T is Ord (a is T, b is T) returns T
    if Ord.lt(a, b) then
        return b
    return a
```

### Data-oriented / numerical (`noalloc`)

```aster
noalloc def matmul(
    a is slice of f64,
    b is slice of f64,
    out is mut ref slice of f64,
    n is usize,
) returns ()
    var i is usize = 0
    while i < n do
        var j is usize = 0
        while j < n do
            var sum is f64 = 0.0
            var k is usize = 0
            while k < n do
                sum = sum + a[i * n + k] * b[k * n + j]
                k = k + 1
            out[i * n + j] = sum
            j = j + 1
        i = i + 1
```

### Async

```aster
async def fetch_all(urls is slice of String) returns Array of Result of (String, Error)
    let tasks is Array of Task of Result of (String, Error) = Array.new()
    for each url in urls do
        tasks.push(task.spawn(http.get, url))
    return await task.join_all(tasks)
```

### FFI

```aster
extern def memcpy(dst is ptr of u8, src is ptr of u8, n is usize) returns ptr of u8

unsafe def fill(buf is ptr of u8, n is usize, value is u8) returns ()
    var i is usize = 0
    while i < n do
        *(buf + i) = value
        i = i + 1
```

### Key conventions

| Rule | Convention |
|------|-----------|
| Indentation | 4 spaces (tabs are illegal) |
| Naming | `snake_case` functions/variables, `CamelCase` types, `SCREAMING_SNAKE` constants |
| Type annotations | `var x is i64 = 42` |
| Return types | `def foo() returns i64` |
| Type constructors | `Array of T`, `slice of T`, `ptr of T` |
| Block delimiters | `then` / `do` (blocks end by dedent) |
| Default int/float | `i64` / `f64` (overridable with suffixes: `42u32`, `3.0f32`) |
| Error handling | `Result` and `try` (no implicit exceptions) |
| Memory | Value types on stack; heap requires `class` or explicit `alloc` |
| Borrowing | Explicit `ref` / `mut ref`; moves by default for non-Copy types |
| Modules | One file = one module; `use foo.bar` (no star imports) |

## Project Structure

```
aster/
├── asm/
│   ├── macros/          # Macro-assembly utilities (arena, vec, string, hash)
│   ├── compiler/        # Lexer, parser, AST, HIR, MIR, codegen (in assembly)
│   ├── runtime/         # Panic, alloc hooks, stack traces
│   ├── driver/          # aster CLI and build graph
│   └── tests/           # Assembly unit tests
├── aster/
│   ├── stdlib/          # Aster standard library
│   ├── tests/           # Language-level tests
│   └── bench/           # Benchmark kernels (dot, gemm, sort, json, ...)
├── tools/
│   ├── build/           # Build scripts (asterc compiler, module builder)
│   └── bench/           # Benchmark harness and baseline runners
├── docs/
│   └── spec/            # Language, ABI, and IR documentation
├── INIT.md              # Production spec and task tracker
├── BENCH.md             # Benchmark history and deltas
└── NEXT.md              # Current status and handoff notes
```

## Getting Started

### Prerequisites

- macOS (arm64 or x86_64) or Linux (x86_64)
- Python 3
- Clang (Apple Clang 17+ or LLVM Clang)
- Rust toolchain (for baseline benchmarks only)

### Running Benchmarks

Kernel benchmarks (compute-bound):

```bash
BENCH_SET=kernels tools/bench/run.sh
```

Filesystem benchmarks (I/O-bound):

```bash
FS_BENCH_ROOT=$HOME \
FS_BENCH_MAX_DEPTH=5 \
FS_BENCH_LIST_FIXED=1 \
BENCH_SET=fswalk \
tools/bench/run.sh
```

Full suite:

```bash
FS_BENCH_ROOT=$HOME \
FS_BENCH_MAX_DEPTH=5 \
FS_BENCH_LIST_FIXED=1 \
tools/bench/run.sh
```

Results are written to `tools/bench/out/`.

### Compiling Aster Source

The current toolchain uses an Aster0 subset compiler that transpiles to C and then to assembly via Clang:

```bash
# Compile an Aster source file
tools/build/asterc.sh aster/bench/dot/dot.as tools/bench/out/aster_dot.S

# Build an assembly test
tools/build/build.sh asm/tests/hello.S
```

Environment variables for the compiler:

| Variable | Default | Description |
|----------|---------|-------------|
| `ASTER_BACKEND` | `c` | Backend: `c` (Aster0 -> C -> asm) or `asm` (template) |
| `ASTER_CACHE` | `1` | Content-hash build cache |
| `ASTER_TIMING` | `0` | Print per-phase timing (parse/emit/clang) |

## Architecture

### Compiler Pipeline

The production compiler (in progress) follows this pipeline, implemented in assembly:

```
Source → Lexer (indentation-aware) → Tokens
     → Parser → CST
     → AST build + desugar
     → Name resolution → HIR with DefIds
     → Type checking + effect checking
     → MIR/SSA build + verifier
     → Optimizer passes (const fold, DCE, CSE, LICM, bounds-check elim)
     → Codegen to assembly
     → Assemble + link → binary
```

All stages share an arena allocator with stable IDs. No stage allocates inside hot loops unless explicitly annotated.

### Bootstrapping Path

| Stage | Description |
|-------|-------------|
| **Stage 0** (done) | Macro-assembly library, test runner, build scripts |
| **Stage 1** (current) | Aster0 subset compiler; lexer/parser in assembly |
| **Stage 2** | HIR, MIR, basic optimizations (const fold, DCE) |
| **Stage 3** | Borrow checking, escape analysis, `noalloc` enforcement |
| **Stage 4** | Performance convergence (LICM, CSE, vectorization, incremental compilation) |
| **Stage 5** | Self-hosting: compile the compiler with itself |

### Implementation

The compiler and runtime are written in assembly (arm64 + x86_64) with a macro-assembly layer for readability. Core runtime primitives (arena allocator, strings, vectors, hash maps) are implemented in `asm/runtime/` and `asm/macros/`.

The current working system is an **Aster0 subset compiler** written in Python (`tools/build/asterc.py`) that compiles benchmark kernels through a C intermediate to produce competitive native code. This serves as the proving ground while the assembly-first production compiler is built.

## Benchmark Suite

The benchmark suite is the primary objective function for development. All optimizer changes must improve the geometric mean or improve at least 70% of benchmarks.

**Kernel benchmarks:** dot product, blocked GEMM, 2D stencil, radix sort, JSON parsing, hash map operations, regex matching, async I/O.

**Filesystem benchmarks:** list/replay traversal (`fswalk`), live traversal with `getattrlistbulk` (`treewalk`), count-only traversal (`dircount`), inventory with hashing (`fsinventory`).

Scoring: `baseline = min(C++, Rust)` under pinned toolchains. Headline = geometric mean of `Aster / baseline` across all benchmarks.

## Status

Aster is in **active early development**. The benchmark harness is functional and shows near-parity performance with C++/Rust. The assembly-first production compiler is under construction.

What works today:
- Aster0 subset compiler for all benchmark kernels
- Full benchmark harness with C++/Rust baselines
- Assembly runtime primitives (arena, vec, string, hash)
- Lexer and parser stubs in assembly (arm64 + x86_64)

What's in progress:
- Production compiler frontend (lexer, parser, AST) in assembly
- Full type system and borrow checker
- Self-hosting path

See [`INIT.md`](INIT.md) for the full production spec and task tracker, and [`NEXT.md`](NEXT.md) for current status.

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.
