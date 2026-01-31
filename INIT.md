**Aster language specification v0.1 (engineering draft)**

**What you’re building**
Aster is a statically typed, ahead-of-time compiled, native-code language with Python/Ruby-style surface ergonomics (minimal required annotations, readable syntax, fast iteration) and C++/Rust-class runtime performance on algorithmic kernels. The core strategy is a “static-by-default” language with aggressive type inference, monomorphized generics, explicit control over allocation and aliasing when needed, and a compilation pipeline designed for both fast developer builds and highly optimized release builds.

A key implementation precedent is the “high-level SSA IR → lower to LLVM IR” model used by Swift (SIL → LLVM IR). ([Swift.org][1]) Another is using a multi-level IR stack (MLIR-style) to keep high-level structure long enough to optimize loops, arrays, and data layout before lowering to low-level IR. ([Reliable Computer Systems Lab][2]) For fast edit/compile/test cycles, Aster uses a dual-backend plan: a fast codegen backend for dev builds (Cranelift) and an optimizing backend for release builds (LLVM). ([Cranelift][3])

**Non-negotiable design constraints**
The table below is written as “hard constraints” so your team can treat them as acceptance gates during implementation.

| Area                               | Constraint                                                                                                            | Practical meaning for the team                                                                                                   |
| ---------------------------------- | --------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| Runtime performance                | Typed hot loops must compile to predictable machine code with no hidden dynamic dispatch and no mandatory GC barriers | You can support dynamic features, but the performance target applies to the statically-typed subset that benchmarks will enforce |
| Allocation transparency            | Inner-loop allocations must be preventable and auditable                                                              | Provide compiler diagnostics (“alloc report”) and a way to forbid allocation in a function                                       |
| Separate compilation + incremental | Small edits should avoid whole-program recompile                                                                      | Stable module interfaces, content-addressed caches, and parallel compilation are core requirements                               |
| Interop                            | First-class C ABI interop from day one                                                                                | The benchmark suite and real adoption both depend on it                                                                          |
| Benchmark-driven evolution         | Every optimization must be proven on a stable benchmark library                                                       | CI gates require performance regression detection and dashboards                                                                 |

**Surface syntax and core semantics**
Aster syntax aims to feel like Python: indentation-based blocks, expression-friendly constructs, and minimal punctuation.

Code examples are illustrative; the precise grammar is specified later.

```aster
module math.fast

def dot(a: slice[f64], b: slice[f64]) -> f64:
    require a.len == b.len
    var s = 0.0
    for i in 0 .. a.len:
        s += a[i] * b[i]
    return s
```

Core semantic rules (these are “spec rules,” not suggestions):
Evaluation order is left-to-right for expressions and argument lists.
Variables are immutable by default; `var` declares mutability.
Functions are pure by default only in the “effects” sense: no implicit global state; side effects require importing and using effectful APIs. This is primarily for optimization and reasoning, not for policing style.
Bounds checks are required by default; the compiler must prove-eliminate checks under optimization (loop range reasoning, slice provenance).
Integer overflow checks are enabled in debug builds and disabled (two’s complement wrap) in release builds unless explicitly requested.

**Lexical structure**
Indentation defines blocks. Tabs are illegal. Whitespace rules must be deterministic and formatter-enforceable.
Identifiers are Unicode-normalized to NFC; keywords are ASCII.
String literals are UTF-8; `str` is a UTF-8 view type with explicit length.

**Types**
Aster is statically typed, with pervasive local type inference. Public API surfaces (exported functions, module-level constants, struct fields, trait methods) require explicit types to stabilize compilation boundaries and error messages.

Value and reference types:
`struct` is a value type with predictable layout (C-like by default).
`enum` is a tagged union with layout rules that allow optimization (niche-filling when possible).
`class` is a reference type (heap allocation); use is explicit.

Core built-in types:
`i8 i16 i32 i64 isize`, `u8 u16 u32 u64 usize`, `f32 f64`, `bool`, `char` (Unicode scalar), `str` (borrowed UTF-8 view), `String` (owning), `slice[T]` (borrowed contiguous view), `Array[T]` (owning growable), `span[T, N]` (fixed-size stack value), `ptr[T]` (unsafe raw pointer), `Option[T]`, `Result[T, E]`.

Type inference rules (minimum viable, implementable):
Local variables infer from initializer.
Function return type can infer only for non-exported functions; exported functions require explicit return type.
Generic type parameters infer from arguments (bidirectional inference allowed only within a single function body to keep compile time predictable).
No global “whole-program” inference.

**Generics and dispatch model**
Performance target implies static dispatch for generic code by default.

Generics compile strategy:
Monomorphization is the default for generic functions and structs: each concrete instantiation generates specialized code.
To control code size and compile time, provide an opt-in “dictionary passing” mode for traits, plus per-function control of specialization.

Required language features:
Traits (interfaces) with explicit bounds, used for operator overloading and generic constraints.
Static dispatch when the concrete type is known.
Dynamic dispatch only when explicitly requested via `dyn Trait` (fat-pointer vtable).

Compile-time cost controls:
No unconstrained trait search across the entire universe; trait resolution must be module-scoped plus imported traits.
No compile-time execution model that allows arbitrary user code to run during type-checking (keep compile-time predictable). If you need metaprogramming, make it explicit and cacheable (see “macros” below).

**Memory management and safety model**
To hit C++/Rust-class performance across algorithmic kernels without GC overhead, Aster uses deterministic destruction and explicit ownership for heap values.

Ownership model (high level):
Values (`struct`, `enum`, `span`) are copied or moved; move is the default for non-`Copy` types.
Heap allocations occur only through explicit constructors (`new`, `Box[T]`, `Array[T]`, `String`, etc.) or via compiler-proven escape from a stack-allocation candidate.
References are either borrowed (`&T`, `&mut T`) or shared (`Shared[T]`), with shared requiring explicit atomic or non-atomic refcount selection depending on thread-safety.

Borrowing rules:
Within a scope, a value can have either multiple immutable borrows or one mutable borrow; borrows are lexical, with non-lexical lifetime shortening allowed where provable.
Interior mutability exists only through explicit types (e.g., `Cell[T]`, `Mutex[T]`), never implicitly.
“Unsafe escape hatches” exist (`unsafe` blocks), but safe code must not allow use-after-free, double free, or data races.

Deterministic destruction:
`defer` and RAII are part of the language to allow predictable resource management without GC.

Allocation auditing and enforcement:
The compiler must implement `@noalloc` (function attribute) that becomes a hard error if the function (or anything it inlines/calls) allocates.
The compiler must implement `@alloc_report` to emit a machine-readable report (JSON) listing allocation sites and reasons (explicit heap, escape, dynamic dispatch, etc.).

**Concurrency**
Baseline concurrency must match modern expectations without sacrificing performance.

Required model:
Native threads and atomics.
`async/await` compiled to state machines (no green-thread runtime requirement).
Data-race freedom in safe code: only `Send`/`Sync`-like types can cross thread boundaries; shared mutability requires synchronization primitives.
Message passing channels in stdlib; actor-like structured concurrency can be layered later.

Atomic and memory model:
Expose C11/C++11-style memory orders (`relaxed`, `acquire`, `release`, `acq_rel`, `seq_cst`) through an `Atomic[T]` API.

**Error handling**
Aster uses typed errors with zero-cost happy paths.

Primary mechanism:
`Result[T, E]` with sugar: `try expr` for propagation; `catch` blocks for recovery; `panic` for unrecoverable invariants.
No exceptions as the primary mechanism in v0.1; if exceptions are added later, they must compile to a form that does not pessimistically inhibit optimization in non-throwing code.

**Modules, packages, and build tool**
Aster requires a modern “single tool” experience comparable to Rust’s cargo.

Artifacts:
Source files: `.as` (example).
Module is a directory with a `module.asmod` interface file generated by compiler.
Package manifest: `aster.toml` (TOML chosen for human editing and tooling ecosystem).

Build modes:
`dev`: fast compile, debuggable, minimal optimization, fast backend (Cranelift), incremental on.
`release`: full optimization, LTO options, LLVM backend.
`bench`: release-like but with benchmark instrumentation toggles.

Dependency management:
Semantic versioning with lockfile.
Offline, hermetic builds supported by fetching dependencies into a local cache with checksums.

Formatter and LSP:
`aster fmt` must be stable and deterministic from day one.
Language Server Protocol implementation required early to maintain ergonomics.

**FFI**
C ABI is first-class:
`extern "C"` functions with explicit types and calling convention.
Struct layout attributes: `@repr(C)`, `@packed`, `@align(n)`.
Header ingestion can be via a separate `aster bindgen` tool that generates Aster declarations from C headers (not required for v0.1, but design should not block it).

**Macros and metaprogramming**
To avoid C++ template metaprogramming compile-time pathology and Rust procedural macro complexity, Aster uses two explicit mechanisms:

Compile-time functions (CTF):
Pure, terminating, side-effect-free evaluation on constant inputs (for sizes, offsets, static tables).
Cache key is the AST of the function plus inputs.

Syntax macros (hygienic):
Restricted, declarative macros that expand to AST, with no arbitrary filesystem/network access.
Expansions are cached and included in module interface hashes for correct incremental invalidation.

**Compiler architecture and implementation plan**
The compiler must be engineered for two competing objectives: fast iteration (compile speed) and peak optimization (runtime speed). The recommended architecture is a multi-tier IR design.

Front-end stages:
Parsing produces a concrete syntax tree with trivia retained for formatting.
Lowering produces an AST with explicit block structure and desugared indentation.
Name resolution produces a HIR (high-level IR) with unique IDs for symbols.
Type checking + inference on HIR produces a typed HIR.
Borrow/escape analysis produces a MIR (mid-level IR) suitable for optimization and codegen.

IR strategy:
Adopt an SSA-based mid-level IR with high-level semantics retained long enough for optimization (loop structure, slices, bounds, ownership). Swift’s SIL is an example of a language-specific SSA IR that retains semantic information, then lowers to LLVM IR for further optimization. ([GitHub][4])
Optionally implement MIR as a custom MLIR dialect so you can reuse MLIR passes and pattern-rewrite infrastructure; MLIR is explicitly designed to support multiple abstraction levels and extensibility for compiler infrastructure. ([Reliable Computer Systems Lab][2])
Lowering then targets either LLVM IR (release) or Cranelift IR (dev). LLVM IR is SSA-based and designed to represent high-level languages cleanly while enabling heavy optimization. ([LLVM][5]) Cranelift is positioned as a fast, relatively simple backend meant to be embedded. ([Cranelift][3])

Backends:
Dev backend: Cranelift for speed; prioritize “good enough” codegen and extremely fast compile/link. Cranelift is used in the Bytecode Alliance ecosystem and designed for embedding. ([GitHub][6])
Release backend: LLVM for peak optimization (inlining, vectorization, SLP, loop passes, LTO).

Incremental compilation design:
Each module emits a “module interface” artifact containing exported symbol signatures, trait/impl metadata needed by downstream modules, and a stable “fingerprint” for incremental invalidation.
Caches are keyed by content hashes of typed HIR plus compilation options.
Parallel compilation is required across module DAG.

Profiling and diagnostics:
`asterc -Ztime-passes` equivalent: record time spent per compiler phase and per pass.
`asterc -Zself-profile` equivalent: emit event trace for flamegraphs.
`asterc -Zmir-dump`, `-Zir-dump`: for debugging optimization correctness.
`asterc -Zopt-remarks`: emit optimization remarks, including bounds-check elimination and vectorization.

Compiler performance engineering:
Follow the same discipline modern compilers document: isolate frontend vs type inference vs codegen time; maintain compile-time benchmarks and regressions as first-class. Swift’s compiler docs include compilation performance as an explicit engineering topic; adopt a similar internal practice. ([GitHub][7])

**Standard library (v0.1 minimum)**
The v0.1 stdlib is intentionally small but performance-critical.

Required components:
`core`: primitives, memory, traits, option/result, iterators, slicing, hashing.
`alloc`: allocation API, Box, String, Array, arena allocators.
`io`: buffered IO, filesystem, networking (minimal).
`time`: monotonic clock, timers.
`sync`: atomics, mutex, rwlock, channels.
`math`: numeric traits, SIMD hooks (optional in v0.1, but design in).
`test`: unit test harness.
`bench`: optional microbenchmark API, but cross-language benchmarks should not depend on it.

The stdlib must be compiled and shipped as prebuilt artifacts per target triple to reduce build times.

**Benchmark library spec (for continuous hill-climbing)**
You’re building two things: the language/compiler and a benchmark system that continuously measures progress, flags regressions, and provides an objective function for compiler tuning.

Benchmark suite composition should explicitly mix “toy kernels,” “algorithmic kernels,” and “macro-ish” tasks to avoid overfitting.

Benchmark sources you can incorporate (and how):
LLVM test-suite is a strong template for how to structure benchmarks with reference outputs and tooling to measure runtime, compile time, and code size. ([LLVM][8])
The Computer Language Benchmarks Game provides a set of small algorithmic programs and a framework for comparative measurement; treat it as one input stream among many, not the whole truth. Use their maintained repository/site as a source of problems and datasets. ([Madnight][9])

Benchmark taxonomy (what you should implement)
Use this as the canonical set of benchmark categories; each category becomes a directory with a common harness contract.

| Category                  | Examples                                                                                                             | Primary metrics                           |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------- | ----------------------------------------- |
| Micro (language overhead) | function call, virtual call, loop overhead, bounds-check elimination, iterator fusion, small alloc/free, hash lookup | ns/op, branch-misses, allocs/op           |
| Kernels (numeric)         | dot product, matmul, FFT, convolution, n-body, spectral norm, mandelbrot                                             | throughput, vectorization %, cache-misses |
| Data structures           | hashmap insert/lookup, B-tree, sort variants, graph traversal                                                        | ops/s, peak RSS                           |
| String/bytes              | UTF-8 validation, parsing, regex-lite, base64, JSON tokenization                                                     | MB/s, peak RSS                            |
| Concurrency               | channel ping-pong, work-stealing queue, actor mailbox                                                                | msgs/s, tail latency                      |
| Compile-time              | parse/typecheck of large generic-heavy modules, incremental rebuild after small edit                                 | seconds, memory, cache hit rate           |
| End-to-end (macro)        | JSON parse + transform + serialize, HTTP routing microservice, compression (zstd-like), ray tracer                   | requests/s, p99 latency, binary size      |

Benchmark harness requirements (this is the important part)
Each benchmark is defined by a machine-readable manifest, plus implementations in Aster, C++, and Rust.

Manifest format: `bench.json` with fields `name`, `category`, `datasets`, `correctness`, `build`, `run`, `metrics`, `tags`, `timeout_s`.

Correctness rules:
Every benchmark must have either a reference output file or a deterministic output hash.
Every implementation must validate correctness before timing. If correctness fails, the benchmark is “red” and excluded from performance aggregation.

Measurement rules:
Use dedicated bare-metal runners for stable results. Containerize toolchains, but not the CPU. Pin CPU frequency and isolate cores.
For command-level benchmarking (compile and run), use a tool that supports warmups, multiple runs, outlier detection, and JSON export; hyperfine supports these directly and is appropriate for this role. ([GitHub][10])
For in-process microbenchmarks, C++ baselines can use Google Benchmark and Rust baselines can use Criterion, but your cross-language scoreboard should still be driven by the external harness so all languages run under the same measurement discipline. ([GitHub][11])

Recorded metrics (minimum set stored per (commit, runner, benchmark, dataset, implementation)):
Runtime: wall time, user CPU time.
Memory: peak RSS.
Compile time: frontend time, typecheck time, codegen time, link time.
Binary size: stripped size and text size.
Hardware counters: optional but recommended via `perf stat` on Linux (cycles, instructions, branches, branch-misses, cache-misses).

Aggregation and scoring:
For each benchmark+dataset, define `baseline = min(C++, Rust)` under pinned toolchains and flags.
Define score as `aster_time / baseline_time` for runtime metrics, and similarly for compile-time and memory if you want multi-objective.
Define the project “headline score” as geometric mean of runtime ratios across the “core” benchmark set, with a separate reported geometric mean for compile time.
Regressions are defined as a statistically significant increase in ratio over recent history; Criterion’s philosophy of “statistical confidence for detecting improvements/regressions” is the right standard even if you don’t directly use Criterion for cross-language runs. ([Docs.rs][12])

CI gating policy:
PR gate runs `smoke` suite only (fast, <10 minutes on a runner).
Nightly runs `core` suite.
Weekly runs `full` suite and hardware-counter suite.

Artifacts and dashboards:
Every run publishes a JSON bundle plus a compact HTML summary.
A time-series store tracks ratios and highlights regressions per benchmark and per compiler phase.
The dashboard must allow drilling from “headline score changed” to “which pass/feature caused it,” using compiler self-profile artifacts.

**Hill-climbing and compiler autotuning spec**
The point of “hill climbing” is to convert benchmark results into a repeatable, automatable optimization loop, without turning your compiler into an overfit benchmark machine.

Knob system (what can be tuned automatically)
Implement compiler “knobs” as explicit, typed configuration values that can be overridden at build time and recorded into artifacts for reproducibility.

| Knob                                    | Example values          | Expected impact                             |
| --------------------------------------- | ----------------------- | ------------------------------------------- |
| Inliner threshold                       | 50..300                 | trade runtime vs compile time and code size |
| Loop unroll threshold                   | 0..N                    | runtime on kernels, code size               |
| Vectorization enablement                | on/off, aggressive      | runtime on numeric, compile time            |
| Bounds-check elimination aggressiveness | conservative/aggressive | runtime on slice-heavy loops                |
| Monomorphization policy                 | full, capped, mixed     | runtime vs code size vs compile time        |
| LTO mode                                | off, thin, full         | runtime vs link time                        |
| Codegen backend in dev                  | cranelift/llvm          | compile time vs runtime in dev              |

Search algorithm
Start with deterministic coordinate descent hill-climb on one knob at a time over the `smoke` and `core` suites, then confirm improvements on `full`. Store the “winning config” per target triple. Reject any config that improves runtime score but blows compile time score beyond a budget threshold.

Objective function
Primary objective: minimize geometric mean runtime ratio over `core`.
Constraints: compile time geometric mean ratio must remain under a fixed budget; binary size ratio under a fixed budget.
Secondary objective: reduce tail latency for concurrency/macro benchmarks.

Anti-overfitting guardrails
A change can only land if it improves or does not regress a minimum fraction of benchmark categories. This prevents “win numeric kernels, lose strings and compile-time.”

**Pinned baseline toolchains and flags**
To keep comparisons meaningful, toolchains and flags must be version-pinned and recorded.

C++ baseline:
Prefer clang++ with `-O3 -march=native` and an LTO variant for “best effort.”
Also run g++ in weekly suite if you care about cross-compiler comparison.

Rust baseline:
Use stable rustc pinned to a specific version; run `--release` plus `-C target-cpu=native` for performance baseline.
Consider a “fast compile” baseline config if you want to compare dev experience (optional).

Aster:
Dev mode uses Cranelift for speed; release mode uses LLVM for peak performance. This mirrors the rationale behind treating Cranelift as a fast backend and LLVM as an optimizing backend. ([Cranelift][3])

**Implementation roadmap with exit criteria**
This is structured to keep your team from building a “pretty syntax” language that later can’t reach performance targets.

| Phase | Deliverable                                                | Exit criteria (must be measured)                                                            |
| ----- | ---------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| P0    | Parser + formatter + module system skeleton                | Stable formatting; deterministic AST; module import graph works                             |
| P1    | Typed core + codegen for integers/floats + slices + loops  | Numeric kernel suite runs correctly; dot/matmul within 3–10× baseline without optimizations |
| P2    | MIR + basic optimizations + bounds-check elimination       | Kernel suite within 1.5–2× baseline; bounds checks eliminated where provable                |
| P3    | Borrow/escape analysis + `@noalloc` + allocation reporting | Inner-loop allocations eliminated in core kernels; `@noalloc` enforced                      |
| P4    | Generics + traits + monomorphization + inliner             | Data-structure suite within 1.2–1.7× baseline; compile time budget measured and tracked     |
| P5    | Release backend (LLVM) + ThinLTO + vectorization           | Core suite reaches within 1.05–1.25× baseline on majority of kernels                        |
| P6    | Concurrency + async + stdlib maturity                      | Concurrency suite competitive; no data races in safe code                                   |
| P7    | Autotuning + regression gates + dashboards                 | Automated knob tuning produces measurable improvements without regressions                  |

**Concrete repo layout (language + benchmarks)**
This layout is designed so performance work is never blocked on language syntax work and vice versa.

`aster/` (compiler + tools)
`asterc/` (compiler)
`asterfmt/` (formatter)
`asterlsp/` (language server)
`stdlib/`
`tests/` (unit + integration + golden)
`perf/` (compiler self-profile scripts)

`aster-bench/` (benchmarks)
`benchmarks/` with subdirs by category
Each benchmark directory contains `bench.json`, `datasets/`, `ref/`, `impl/aster/`, `impl/cpp/`, `impl/rust/`
`harness/` (runner + reporters)
`reports/` (generated artifacts ignored by VCS)

**Why this can reach C++/Rust performance**
The combination of (a) static typing with inference, (b) monomorphization + static dispatch, (c) explicit ownership/borrowing to avoid GC overhead, and (d) an SSA mid-level IR that retains semantic structure long enough for bounds-check elimination and loop optimization is the established route to “high-level feel, low-level speed.” Swift’s SIL-to-LLVM structure is a concrete example of this architecture. ([GitHub][4]) MLIR-style multi-level lowering is explicitly designed to make this kind of staged optimization practical across abstraction levels. ([Reliable Computer Systems Lab][2]) A “fast backend for dev, optimizing backend for release” split is a direct way to keep iteration speed high while still pursuing peak performance. ([Cranelift][3])

If you want a reference point that explicitly targets “Python-like ergonomics with MLIR-based compilation,” Mojo’s docs describe using MLIR/LLVM-level dialects for lowering; it’s a useful conceptual precedent even if you don’t mirror its design. ([Modular Documentation][13])

[1]: https://swift.org/documentation/swift-compiler/?utm_source=chatgpt.com "Swift Compiler | Swift.org"
[2]: https://rcs.uwaterloo.ca/~ali/cs842-s23/papers/mlir.pdf?utm_source=chatgpt.com "MLIR: Scaling Compiler Infrastructure for Domain Specific ..."
[3]: https://cranelift.dev/?utm_source=chatgpt.com "Cranelift"
[4]: https://github.com/swiftlang/swift/blob/main/docs/SIL/SIL.md?utm_source=chatgpt.com "swift/docs/SIL/SIL.md at main · swiftlang/swift"
[5]: https://llvm.org/docs/LangRef.html?utm_source=chatgpt.com "LLVM Language Reference Manual"
[6]: https://github.com/bytecodealliance/wasmtime/blob/main/cranelift/README.md?utm_source=chatgpt.com "wasmtime/cranelift/README.md at main"
[7]: https://github.com/apple/swift/blob/main/docs/CompilerPerformance.md?utm_source=chatgpt.com "swift/docs/CompilerPerformance.md at main"
[8]: https://llvm.org/docs/TestSuiteGuide.html?utm_source=chatgpt.com "test-suite Guide — LLVM 23.0.0git documentation"
[9]: https://madnight.github.io/benchmarksgame/?ref=blog.paulbiggar.com&utm_source=chatgpt.com "The Computer Language Benchmarks Game"
[10]: https://github.com/sharkdp/hyperfine?utm_source=chatgpt.com "sharkdp/hyperfine: A command-line benchmarking tool"
[11]: https://github.com/google/benchmark?utm_source=chatgpt.com "google/benchmark: A microbenchmark support library"
[12]: https://docs.rs/criterion/latest/criterion/?utm_source=chatgpt.com "criterion - Rust"
[13]: https://docs.modular.com/mojo/faq/?utm_source=chatgpt.com "Mojo FAQ"

