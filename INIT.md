# Aster language and compiler production specification (v2.0, assembly-first)

This document defines the production-grade requirements for the Aster language, compiler, runtime, standard library, build tool, and benchmark system. The implementation is assembly-first to maximize performance and to minimize runtime overhead. The language surface remains high-level and ergonomic like Ruby/Python.

## Task Tracker (kept current)

Updated: 2026-02-04
Legend: [x] done, [ ] todo, [~] in progress

- [x] Reset workspace to assembly-first plan and clean repo.
- [x] Create assembly-first repo skeleton and macro scaffolding.
- [x] Define assembly macro conventions, ABI, and object format targets.
- [x] Add minimal build script and hello assembly test.
- [x] Implement Aster0 bench compiler stub (template emitter + Aster->C for fswalk).
- [x] Implement fswalk list replay with no helper objects (pure Aster + libc).
- [x] Align fswalk list parsing across Aster/C++/Rust with raw byte scan.
- [x] Split benchmark runs (kernels vs fswalk) to reduce cache interference.
- [x] Add fixed fswalk dataset + metadata for repeatable runs.
- [x] Add treewalk benchmark (live traversal) alongside fswalk list mode.
- [x] Implement fswalk live traversal in Aster via fts (no helpers).
- [x] Force C++ fswalk traversal to fts in harness for apples-to-apples.
- [x] Add C++ treewalk bulk mode and align harness defaults with Aster bulk.
- [x] Default benchmark harness to Aster-only backend (no asm templates).
- [x] Add treewalk bulk mode using getattrlistbulk (Aster-only, no helpers).
- [x] Add C-emit vectorization hints (`__restrict__`, clang loop pragmas).
- [x] Tune kernel Aster0 sources (tiled stencil, FSM regex, pointer JSON).
- [x] Add treewalk bulk file sizes via ATTR_FILE_DATALENGTH (no per-file fstatat).
- [x] Add treewalk bulk buffer override (FS_BENCH_BULK_BUF).
- [x] Optimize bench kernels (regex pointer scan, JSON digit unroll, robin hood hashmap).
- [x] Add JSON 8-byte pre-scan and packed robin hood metadata.
- [x] Increase treewalk bulk buffer default to 1MB.
- [x] Add x86_64 support for arena + string + hash runtime primitives.
- [x] Compile dot/gemm/stencil from Aster source (Aster0 -> C -> asm).
- [x] Add Aster0 build cache (content hash + backend key).
- [x] Add direct-ASM backend for kernel benchmarks (dot/gemm/stencil/sort).
- [ ] (optional) Add ASM templates for microbench experiments (not used for scoring).
- [x] Add module graph builder + cache (aster_build.py) with fixtures.
- [x] Implement macro primitives in assembly (arena, vec, string, hash).
- [x] Add x86_64 support for vec + span + diagnostics + lexer + parser stubs.
- [x] Add lexer indentation + parser expr assembly tests (arm64 + x86_64).
- [~] Implement aster_span core types in assembly (FileId, Span, SourceMap).
- [~] Implement aster_diagnostics in assembly (spans, reports).
- [~] Implement aster_frontend lexer (indentation, spans, tokens) in assembly.
- [~] Implement CST parser with error recovery + precedence in assembly.
- [ ] Implement aster_ast data model + serialization helpers in assembly.
- [ ] Implement HIR + desugaring pipeline (surface -> HIR).
- [ ] Implement name resolution, symbol tables, and module imports.
- [ ] Implement type checking (constraints + unification) and effects.
- [ ] Implement borrow rules, `noalloc` checking, and effect enforcement.
- [ ] Implement MIR/SSA builder and verifier.
- [ ] Implement optimizer passes (const fold, DCE, CSE, LICM, bounds-check elim).
- [ ] Implement inliner and register allocator tuned for build time and runtime.
- [ ] Implement codegen to assembly for target triples (start with host).
- [ ] Implement runtime (panic, alloc hooks, stack traces) and core stdlib.
- [ ] Implement aster CLI (build, run, test, bench) and minimal package graph.
- [~] Implement benchmark harness with C++/Rust baselines and dashboards.
- [ ] Add treewalk benchmark controls (list vs live) to aster CLI and bench docs.
- [ ] Add dataset manifest + hash capture for fswalk/treewalk runs in BENCH.md automation.
- [ ] Implement stdlib fs traversal APIs (fts/opendir) to replace direct libc calls in benches.
- [~] Extend Aster0 subset (arrays, structs, calls, externs; added for-loops + type inference) until real frontend is ready.
- [~] Extend Aster0 subset to cover structs/slices/return conventions (remove C transpile step).
- [x] Aster0: handle `use` lines + extern prototypes in C-emit for modules.
- [ ] Replace Aster0 stub with true frontend -> IR -> codegen (self-hosted path).
- [ ] Add asterfmt deterministic formatter and formatting tests.
- [ ] Add language spec for memory model, effects, and FFI ABI.
- [ ] Add conformance test suite (parser/type/IR/codegen) + fuzzing harness.
- [ ] Add perf governance (pinned toolchains, perf CI, BENCH.md automation).
- [x] Stabilize fswalk dataset sizing (configurable list size + repeatability checks).
- [x] Add benchmark variance tracking (N runs, stddev, cache-state notes).
- [x] Add benchmark isolation modes to CLI (kernels vs IO benches).
- [x] Expand benchmark suite (JSON parse, regex, sort, hashmap, async IO, treewalk).
- [x] Add dircount benchmark (live traversal count-only).
- [x] Add fsinventory benchmark (live traversal inventory: files/dirs/symlinks + name hash).
- [~] Implement deterministic build cache + incremental recompilation DAG.
- [x] Define stdlib ABI for slices/strings/arrays (layout + calling convention).
- [ ] Implement borrow checker prototype for `ref`/`mut ref` and `noalloc` enforcement.
- [ ] Add debug info + symbolization (DWARF, stack traces).
- [ ] Build test runner + golden output harness for stdlib and compiler tests.
- [ ] Add module/package registry layout and lockfile semantics.
- [ ] Add release engineering (versioning, packages, installer, docs site).

Keep this list updated as work progresses.

## 1) Product goals

Aster is a statically typed, ahead-of-time compiled, native-code language with Python/Ruby-like ergonomics and C++/Rust-class performance on algorithmic kernels. The compiler and runtime are implemented in assembly for maximum performance and control.

Primary objectives:
- Predictable performance: typed hot loops compile to tight machine code with no hidden dynamic dispatch or mandatory GC barriers.
- Compilation speed: fast incremental builds in dev mode; optimized binaries in release mode.
- Allocation transparency: inner-loop allocations can be forbidden and audited by the compiler.
- Interop: first-class C ABI interoperability.
- Benchmark-driven evolution: every optimization must improve or preserve a benchmark-based objective function.

Non-negotiable acceptance gates (must be measurable):
- Runtime performance: kernels within 1.05-1.25x of the C++/Rust baseline on the majority of core benchmarks.
- Build performance: >80% win rate vs C++ and Rust on build time and run time under pinned toolchains.
- Noalloc enforcement: `noalloc` must be sound and enforced transitively.
- Incremental rebuilds: small edits in a leaf module should not trigger whole-program rebuilds.
- Deterministic builds: same inputs produce identical outputs (bit-for-bit) for release builds, modulo toolchain version IDs.

## 2) Assembly-first implementation constraints

- The compiler, runtime, and core tooling are written in assembly for the primary target(s).
- Use a small macro-assembly layer to keep code readable and to enforce calling conventions.
- All compiler data structures use arena allocation with explicit lifetimes and reuse.
- The compiler must be self-contained with minimal external dependencies (assembler and linker only).
- The first supported target is the host target (x86_64 SysV or arm64 macOS), with additional targets added later.

## 3) Repository layout (assembly-first)

```
.
├─ INIT.md
├─ AGENTS.md
├─ asm/
│  ├─ macros/              # macro-assembly utilities (strings, vectors, hash maps)
│  ├─ compiler/            # lexer, parser, AST, HIR, MIR, codegen
│  ├─ runtime/             # panic, alloc hooks, stack traces
│  ├─ driver/              # aster CLI and build graph
│  └─ tests/               # low-level unit tests in assembly
├─ aster/
│  ├─ stdlib/              # Aster standard library source
│  ├─ tests/               # language-level tests
│  └─ bench/               # Aster benchmarks
├─ tools/
│  ├─ build/               # build scripts for asm -> obj -> exe
│  └─ bench/               # harness and baseline runners
└─ docs/
   └─ spec/                # language, ABI, IR documentation
```

## 4) Convention over configuration (language author rules)

These rules remove configuration choices and make code and projects predictable.

Project layout and build:
- One module per file; module name equals the file path relative to project root.
- Entry point is `src/main.as` containing `def main()`; libraries use `src/lib.as`.
- The build root is the directory containing `aster.toml`; if missing, the current directory is the root.
- Default build profile is `dev`; `release` and `bench` are fixed profiles with no custom variants.
- Dependencies resolve from `aster.toml` and a lockfile; no alternate registries without explicit tooling.

Naming and style:
- 4-space indentation; tabs are illegal.
- `snake_case` for functions and variables, `CamelCase` for types, `SCREAMING_SNAKE` for constants.
- Single quotes for chars, double quotes for strings.
- Type annotations use the keyword `is`; return types use the keyword `returns`.
- Block headers use `then` or `do`; blocks end by indentation (no trailing `:` or `end`).
- Type constructors use `of`: `Array of T`, `Result of (T, E)`, `slice of T`, `ptr of T`.
- Modifiers are keywords: `async`, `extern`, `unsafe`, `noalloc`.
- Trailing commas are required in multiline lists (params, array literals, struct literals).
- Formatting is owned by `asterfmt`; manual formatting is not a supported workflow.

Typing and effects:
- Public items must declare explicit types; local variables can be inferred.
- Default integer type is `i64`; default float type is `f64`.
- Numeric literal suffixes override defaults (`42u32`, `3.0f32`).
- Functions are effect-pure by default; effectful functions must declare effects in the signature.
- Error handling uses `Result` and `try`; exceptions are not implicit.

Memory and performance:
- Value types live on the stack by default; heap allocation requires `class` or explicit `alloc`.
- `noalloc` is enforced transitively and is the default for `core` and `bench` modules.
- Borrowing is explicit with `ref`/`mut ref`; moves are default for non-Copy types.
- Bounds checks are required unless the compiler can prove safety or the code opts into `unsafe`.

Modules and interoperability:
- Imports use `use foo.bar` only; star imports are forbidden.
- C interop uses `extern` declarations and the C ABI by default.
- Stable symbol mangling is deterministic across builds.

## 5) Language capability guide (MECE examples)

The following examples are mutually exclusive and collectively exhaustive across
the major paradigms taught in standard programming curricula. Each snippet is a
capability target for the compiler and runtime, and should be kept in sync with
the implementation roadmap.

1) Imperative / procedural (control flow, loops, state)

```aster
def checksum(bytes is slice of u8) returns u32
    var sum is u32 = 0
    var i is usize = 0
    while i < bytes.len() do
        sum = sum + bytes[i]
        i = i + 1
    return sum
```

2) Object-oriented (encapsulation, methods, interfaces)

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

3) Functional (higher-order functions, immutability)

```aster
def square(x is i64) returns i64
    return x * x

def sum_squares(nums is slice of i64) returns i64
    let mapped is Array of i64 = nums.map(square)
    return mapped.fold(0, add)

def add(a is i64, b is i64) returns i64
    return a + b
```

4) Generic / parametric polymorphism (type abstraction)

```aster
trait Ord of T
    def lt(a is T, b is T) returns bool

def max of T where T is Ord (a is T, b is T) returns T
    if Ord.lt(a, b) then
        return b
    return a
```

5) Data-oriented / numerical (arrays, spans, noalloc)

```aster
noalloc def matmul(a is slice of f64, b is slice of f64, out is mut ref slice of f64, n is usize) returns ()
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

6) Concurrent / async (tasks, await, channels)

```aster
async def fetch_all(urls is slice of String) returns Array of Result of (String, Error)
    let tasks is Array of Task of Result of (String, Error) = Array.new()
    for each url in urls do
        tasks.push(task.spawn(http.get, url))
    return await task.join_all(tasks)
```

7) Systems / low-level (unsafe, FFI, explicit memory)

```aster
extern def memcpy(dst is ptr of u8, src is ptr of u8, n is usize) returns ptr of u8

unsafe def fill(buf is ptr of u8, n is usize, value is u8) returns ()
    var i is usize = 0
    while i < n do
        *(buf + i) = value
        i = i + 1
```

8) Scripting / automation (files, text, JSON, CLI)

```aster
def main() returns Result of ()
    let args is Array of String = os.args()
    if args.len() < 2 then
        io.print("usage: logcount <path>")
        return Ok(())

    let text is String = fs.read_file(args[1])?
    let doc is Json = json.parse(text)?
    let events is Array of Json = doc.get("events")?.as_array()?
    let errors is usize = events.filter(is_error_event).len()
    io.print("errors=", errors)
    return Ok(())

def is_error_event(event is Json) returns bool
    return event.get("level")?.as_str()? == "ERROR"
```

## 6) Source infrastructure (assembly data model)

All IR nodes carry spans and stable IDs. IDs are 32-bit to keep structures compact.

```
FileId: u32
Span { file: FileId, lo: u32, hi: u32 }
NodeId: u32
DefId { crate_id: u32, idx: u32 }
SymbolId: u32
TypeId: u32
```

Source maps must support:
- file -> line/column mapping
- macro expansion tracking
- deterministic ordering

## 7) Compiler architecture (assembly-first)

Pipeline stages:
1) Lexing (indentation-aware) -> tokens
2) Parsing -> CST
3) AST build + desugar
4) Name resolution -> HIR with DefIds
5) Type checking + effect checking
6) MIR/SSA build + verifier
7) Optimizer passes
8) Codegen to assembly
9) Assemble + link -> binary

Implementation constraints:
- All stages share an arena allocator and stable IDs.
- Diagnostics are created during all stages and rendered at the end.
- No stage allocates inside hot loops unless explicitly annotated.

## 8) Bootstrapping strategy (zero to self-hosting)

Stage 0: Toolchain and macro-assembly library
- Pick primary assembler and linker for the host target.
- Implement macro library for strings, vectors, hash maps, and arenas.
- Build a minimal test runner for assembly unit tests.

Stage 1: Aster0 compiler (assembly)
- Implement lexer, parser, and a tiny type checker for numeric code.
- Generate assembly directly (no optimizer yet).
- Support basic functions, structs, loops, and arrays.

Stage 2: Aster1 compiler (assembly)
- Add HIR, MIR, and basic optimizations (const fold, DCE).
- Implement bounds-check elimination where provable.
- Add diagnostics with spans and multi-span notes.

Stage 3: Aster2 compiler (assembly)
- Add borrow checking, escape analysis, and `noalloc` enforcement.
- Add inliner and a basic register allocator tuned for build time.
- Expand stdlib and add benchmark harness.

Stage 4: Performance convergence
- Implement LICM, CSE, and peephole optimizations.
- Add vectorization patterns for common kernels.
- Add incremental compilation with module interfaces.

Stage 5: Maturity and portability
- Add second target triple and cross-compile toolchain.
- Stabilize ABI, module format, and deterministic builds.
- Enable self-hosting by compiling the compiler with itself.

## 9) Benchmarks and hill-climbing

Benchmarks gate all optimizer changes.

Core algorithm set:
1) Blocked GEMM
2) FFT (radix-2 or mixed-radix)
3) 2D/3D stencil
4) N-body
5) SpMV (CSR/ELL)
6) Dijkstra (binary heap)
7) Radix sort
8) Robin Hood hash table
9) Aho-Corasick
10) LZ77/LZ4-style compression
11) Filesystem traversal (list/replay + stat)
12) Tree traversal (live directory walk + metadata)
13) Filesystem inventory (live traversal + counts + name hash)

Metrics:
- runtime wall/user
- peak RSS
- compile time per phase
- binary size
- hardware counters (perf) on Linux

Scoring:
- Baseline = min(C++, Rust) under pinned toolchains
- Score = Aster / baseline
- Headline = geometric mean over core benchmarks
- Regression gate on statistical significance

Hill-climbing protocol:
- Every optimization change runs the benchmark suite.
- Only adopt changes that improve the geometric mean or improve at least 70% of benchmarks.
- Tune thresholds for inlining, unrolling, and vectorization with automated sweeps.

## 10) Definition of done (production)

The compiler is production-ready when:
- It builds the stdlib and all core benchmarks on all supported targets.
- It passes CI gates and has no known correctness bugs in the core spec.
- It meets performance gates on the core benchmark suite.
- It ships with stable formatting, LSP, and package management.

End of spec.
