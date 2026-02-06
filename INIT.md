# Aster language and compiler production specification (v2.0, assembly-first)

This document defines the production-grade requirements for the Aster language, compiler, runtime, standard library, build tool, and benchmark system. The implementation is assembly-first to maximize performance and to minimize runtime overhead. The language surface remains high-level and ergonomic like Ruby/Python.

## Non-Negotiable Policy: No Compiler Shims

- Do not add Python build scripts to the Aster toolchain (the compiler/build should be Aster/asm + standard system tools only).
- Do not build "compiler shims" in Python (or any other language) that masquerade as the Aster compiler (e.g. Aster->C transpilers, template emitters, etc.).
- Do not use pre-generated/hand-written assembly templates as a stand-in for compiling `.as` source for benchmarks.
- Benchmarks must be compiled from Aster source by an Aster compiler (`asterc`). The compiler itself may be implemented in assembly for performance, but it must do real parsing/typechecking/codegen from `.as`.

## Task Tracker (kept current)

Updated: 2026-02-06
Legend: [x] done, [ ] todo, [~] in progress

### 0) Policy / Hygiene
- [x] Reset workspace to assembly-first plan and clean repo.
- [x] Create assembly-first repo skeleton and macro scaffolding.
- [x] Add repo `.gitignore` for local/generated artifacts.
- [x] Add/affirm "no compiler shims" policy in `INIT.md` and `AGENTS.md`.
- [x] Purge shim-based benchmark "compilers" and template backends from the repo (policy enforcement).
- [x] Deprecate `NEXT.md` and keep all handoff/status info in `INIT.md`.
- [x] Clone tinygrad reference repo into `libraries/tinygrad` for Aster ML port planning (2026-02-06).
- [x] Add single authoritative green gate script at `tools/ci/gates.sh`.

### 1) Low-Level Runtime + Test Infrastructure (asm)
- [x] Define assembly macro conventions, ABI, and object format targets.
- [x] Add minimal build script and hello assembly test.
- [x] Implement macro primitives in assembly (arena, vec, string, hash).
- [x] Add x86_64 support for arena + string + hash runtime primitives.
- [x] Add x86_64 support for vec + span + diagnostics + lexer + parser stubs.
- [x] Add lexer indentation + parser expr assembly tests (arm64 + x86_64).
- [x] asm: fix arm64 `parser_expr` hang (LR clobber) + fix runtime caller-saved clobbers (`vec_push`, `map_init`).

### 2) Benchmark Suite (sources + harness)
- [ ] Implement fswalk list replay with no helper objects (pure Aster + libc).
- [ ] Align fswalk list parsing across Aster/C++/Rust with raw byte scan.
- [ ] Split benchmark runs (kernels vs fswalk) to reduce cache interference.
- [ ] Add fixed fswalk dataset + metadata for repeatable runs.
- [ ] Add treewalk benchmark (live traversal) alongside fswalk list mode.
- [ ] Implement fswalk live traversal in Aster via fts (no helpers).
- [ ] Force C++ fswalk traversal to fts in harness for apples-to-apples.
- [ ] Add C++ treewalk bulk mode and align harness defaults with Aster bulk.
- [ ] Add treewalk bulk mode using getattrlistbulk (Aster-only, no helpers).
- [ ] Add treewalk bulk file sizes via ATTR_FILE_DATALENGTH (no per-file fstatat).
- [ ] Add treewalk bulk buffer override (FS_BENCH_BULK_BUF).
- [ ] Increase treewalk bulk buffer default to 8 MiB (FS_BENCH_BULK_BUF).
- [ ] Expand benchmark suite (JSON, regex, sort, hashmap, async IO, fs benches).
- [ ] Add dircount benchmark (live traversal count-only).
- [ ] Add fsinventory benchmark (live traversal inventory: files/dirs/symlinks + name hash).
- [ ] Bench harness: record `sha256/bytes/lines` for fixed fswalk/treewalk datasets (stricter comparisons).
- [ ] Add benchmark variance tracking (N runs, stddev, cache-state notes).
- [ ] Add benchmark isolation modes to CLI (kernels vs IO benches).
- [ ] Stabilize fswalk dataset sizing (configurable list size + repeatability checks).
- [ ] Benchmark harness: C++/Rust baselines + suite scoring (median, win-rate, geomean).
- [ ] Tune/optimize benchmark sources (kernel-level Aster code).

### 3) Compiler MVP: `asterc` (real; bench-complete subset)
- [x] Aster1(MVP): define the bench-complete language subset (syntax + semantics + ABI) with examples + tests.
      Include "lookahead" requirements for tinygrad-as-Aster (SIMD-friendly numerics, explicit memory layout, kernels, and a path to generics/traits without breaking the MVP).
- [x] `asm/driver/asterc.S`: compiler CLI (compile `.as` -> `.ll` -> exe), deterministic output, and errors.
- [x] Frontend: finish `aster_span` core types (FileId, Span, SourceMap).
- [x] Frontend: finish `aster_diagnostics` (spans, reports) and render to stderr.
- [x] Frontend: lexer (indentation, spans, tokens) including string/char literals and comments.
- [x] Frontend: parser (module items + statements/exprs needed by benchmarks).
- [x] Type system (MVP): explicit types only; validate calls/returns; C-ABI externs.
- [x] Codegen (MVP, host arch first): AST->LLVM IR for the bench subset (no HIR/MIR required for correctness).
- [x] Link: invoke system compiler/linker (clang/ld) from `asterc` to produce an executable.
- [x] E2E smoke: compile+run every benchmark with small inputs (fast), as a gating test.
- [x] Integration: `tools/bench/run.sh` must build Aster binaries only via `tools/build/out/asterc` (no shims).

### 4) Compiler IR + Language Semantics (post-MVP)
- [ ] Implement aster_ast data model + serialization helpers in assembly.
- [ ] Implement HIR + desugaring pipeline (surface -> HIR).
- [~] Implement name resolution, symbol tables, and module imports.
- [ ] Implement type checking (constraints + unification) and effects.
- [~] Implement borrow rules, `noalloc` checking, and effect enforcement.
- [ ] Implement MIR/SSA builder and verifier.
- [ ] Implement optimizer passes (const fold, DCE, CSE, LICM, bounds-check elim).
- [ ] Implement inliner and register allocator tuned for build time and runtime.
- [x] Define stdlib ABI for slices/strings/arrays (layout + calling convention).
- [~] Build system: native module graph + deterministic incremental compilation in `asterc` (no Python).
- [~] Implement runtime (panic, alloc hooks, stack traces) and core stdlib.
- [ ] Implement stdlib fs traversal APIs (fts/opendir) to replace direct libc calls in benches.
- [ ] Implement stdlib networking (`net`, `http`) for remote API clients:
      TCP + DNS + TLS + HTTP client with streaming responses (SSE-style) on macOS first.
      Target: Aster can consume OpenAI-style streaming APIs natively (no shelling out).
      Compatibility target: `https://platform.openai.com/docs/llms.txt` (streaming, tool-calls, JSON).
- [x] Implement aster CLI (build, run, test, bench) and minimal package graph.
- [x] Add treewalk benchmark controls (list vs live) to aster CLI and bench docs.
- [x] Add dataset manifest + hash capture for fswalk/treewalk runs in BENCH.md automation.
- [x] Add asterfmt deterministic formatter and formatting tests.
- [x] Add language spec for memory model, effects, and FFI ABI.
- [~] Add conformance test suite (parser/type/IR/codegen) + fuzzing harness.
- [~] Add perf governance (pinned toolchains, perf CI, `BENCH.md` automation).
- [~] Add debug info + symbolization (DWARF, stack traces).
- [x] Build test runner + golden output harness for stdlib and compiler tests.
- [~] Add module/package registry layout and lockfile semantics.
- [~] Add release engineering (versioning, packages, installer, docs site).
- [~] Docs + sample apps (continuous):
      maintain `docs/learn/` tutorials and `aster/apps/` sample apps as features land
      (FFI, fs tools, perf kernels, and at least one streaming HTTP client example, e.g. OpenAI chat stream).

### 5) Performance Hill-Climb (after real compiler produces the binaries)
- [x] Add build-time measurement (clean + incremental) to `tools/bench/run.sh` and record in `BENCH.md`.
- [x] Start a new `BENCH.md` epoch for real-`asterc` results (legacy shim-era runs are non-authoritative).
- [~] Hill-climb runtime and build-time toward sustained +5-15% margin vs best baseline (json/hashmap/async_io first).
- [~] Implement deterministic build cache + incremental recompilation DAG.

### 6) Performance Domination (>=20% Faster on Every Benchmark)
- [ ] Define the target: for every benchmark in the suite, Aster median runtime must be `<= 0.80x` the best baseline (min of C++ and Rust) on the same host/toolchains/datasets.
- [ ] Extend suite scoring to report `win>=20%` counts per benchmark and require 100% for this milestone.
- [ ] Bench harness: add compile-time measurement and reporting for Aster/C++/Rust (clean + incremental), recorded alongside runtime results in `BENCH.md`.
      Clean: fresh build from scratch; Incremental: minimal edit + rebuild (define a standard touch/edit protocol per language).
- [ ] Bench harness: include end-to-end compile+link time and (when feasible) compiler-only time breakdowns (`asterc` time vs `clang/ld` time; `rustc` vs link) and report medians + variance.
- [ ] Standardize `BENCH.md` run templates to include: runtime table, compile-time table (clean+incremental), command lines, toolchains, dataset hashes, and variance notes.
- [ ] Add an automated hill-climb loop to the bench harness:
      run targeted subsets quickly, accept/reject changes based on suite score, and emit a delta summary suitable for pasting into `BENCH.md`.
- [ ] For each benchmark, maintain a tracked list of the current top 3 suspected bottlenecks (profile-guided) and the planned optimization(s) to clear the `<=0.80x` target.

### 7) ML (post-production)
- [ ] ML: tinygrad port audit + parity target definition.
      Define the v1 parity surface against the existing python tinygrad repo in `libraries/tinygrad/`:
      `tinygrad/tensor.py`, `tinygrad/uop/*`, `tinygrad/engine/*`, `tinygrad/codegen/*`, `tinygrad/renderer/*`,
      `tinygrad/device.py`, `tinygrad/runtime/ops_cpu.py`, `tinygrad/runtime/ops_metal.py`, and `tinygrad/nn/*`.
      Use `libraries/tinygrad/test/` (plus `tinygrad/apps/llm.py`) as the behavioral spec to track.
- [ ] ML: python tinygrad parity harness (golden outputs + fuzz/property tests).
      Generate golden vectors (inputs/seeds + expected outputs/gradients) from python tinygrad and run them against the Aster port.
      Include deterministic seeding, dtype/shape fuzzing, and a curated "must pass" subset from `libraries/tinygrad/test/`.
- [ ] ML: `aster_ml` module architecture + ABI.
      Define module boundaries and stable ABIs for: dtype/promotion, Tensor/IR, scheduling, codegen/renderers, device/runtime, nn/state.
      Explicitly document which pieces are intended to match tinygrad semantics vs Aster-native replacements.
- [ ] ML: core dtype system parity (`tinygrad/dtype.py`).
      Implement `DType`/promotion, casts/bitcasts, and the "safe dtype" mapping used by serialization.
- [ ] ML: device/buffer model parity (`tinygrad/device.py`).
      Implement `Device` selection/canonicalization, `Buffer` (including views/sub-buffers), allocators, and host<->device copy semantics.
- [ ] ML: core IR + rewrite engine parity (`tinygrad/uop/*`).
      Implement `Ops`, `UOp` (hash-consing + stable keys), `UPat`/PatternMatcher, graph rewrite, and symbolic ints/Variables.
      Preserve caching behavior (UOp cache + schedule cache keys) as a first-order performance requirement.
- [ ] ML: Tensor front-end parity (`tinygrad/tensor.py`).
      Tensor construction paths (scalar/list/bytes, disk tensors, `from_url`, `from_blob`), movement + math APIs, contiguity rules,
      and data extraction (`data`, `item`, `tolist`, host `numpy`-style view equivalents).
- [ ] ML: movement/shape semantics parity (`tinygrad/mixin/movement.py` + UOp shape rules).
      Broadcasting, reshape/expand/permute/pad/shrink/flip, slicing/indexing/setitem semantics, and reduction axis behavior.
- [ ] ML: math/reduction op parity (Tensor ops used by tests + `tinygrad/apps/llm.py`).
      Elementwise ALU, comparisons, transcendental ops, reductions (sum/max/mean), softmax/logsoftmax, matmul/conv primitives.
- [ ] ML: autograd parity (`tinygrad/gradient.py` + `Tensor.backward`/`Tensor.gradient`).
      Implement rule-based reverse-mode autograd over the IR, gradient accumulation semantics, and higher-order gradients.
- [ ] ML: scheduling + memory planning parity (`tinygrad/engine/schedule.py`, `tinygrad/engine/memory.py`).
      Create deterministic `ExecItem` schedules from tensor sinks, dependency ordering, schedule caching, and buffer lifetime/memory planning.
- [ ] ML: codegen pipeline parity (`tinygrad/codegen/*`, `tinygrad/renderer/*`).
      IR -> kernel AST -> linearization -> rendering -> compile cache plumbing; implement at least a C-style renderer and a Metal renderer.
- [ ] ML: CPU backend parity (`tinygrad/runtime/ops_cpu.py`).
      Kernel compilation (clang/LLVM JIT or equivalent), launch/runtime calling convention, multithread execution, and vectorized kernels.
- [ ] ML: macOS Metal backend parity (`tinygrad/runtime/ops_metal.py`).
      Buffer management, command queue/buffers, shader compilation (source->MTLB) + caching, dispatch dims, and synchronization/profiling hooks.
- [ ] ML: serialization + model IO parity (`tinygrad/nn/state.py`).
      state_dict traversal/load, safetensors load/save, GGUF load (including required GGML quantization decode for target models),
      and gzip/tar/zip extract helpers for common datasets/weights.
- [ ] ML: nn + optim parity (`tinygrad/nn/*`).
      Layers/utilities needed by model tests (Embedding/Linear/Conv, (RMS/Layer)Norm, attention/SDPA) plus optimizers (SGD/AdamW/LAMB).
- [ ] ML: model zoo + apps smoke suite (`libraries/tinygrad/test/models/*`, `tinygrad/apps/llm.py`).
      Run representative end-to-end workloads (MNIST training, BERT-like, Whisper-like, and LLM GGUF inference) as a production gate.
- [ ] ML: ML benchmarks (new BENCH epoch; runtime + compile time).
      Add ML benchmark set(s) (training step time + inference throughput/latency) and track deltas in `BENCH.md`.

### 8) Algorithmic Conformance Suite (15 LeetCode Hard Problems in Native Aster)
- [ ] Define the suite contract and wire it into the green gate.
      Location: `aster/tests/leetcode/`.
      Harness: extend `aster/tests/run.sh` to compile+run `aster/tests/leetcode/*.as` (expected: compile ok, exit 0).
      Keep all tests deterministic (fixed inputs; no timing; bounded recursion).
- [ ] Establish test conventions for `.as` algorithm tests:
      each file contains `main()` that runs multiple cases and returns non-zero on the first failure (optionally prints diagnostics).
      Prefer structural validation (element-by-element equality, invariants) over large golden text outputs.
- [ ] Implement minimal "test-only stdlib" helpers needed by the suite (non-generic is fine initially):
      vec/stack/deque/heap, basic hashing, and string utilities (strlen/compare/copy, char access).
      Short-term: allow per-test duplication; mid-term: factor once module imports exist.
- [ ] Implement the 15-problem suite (one file per problem), based on `plan/report-2026-02-06-aster-leetcode-hard-suite.md`:
      10 Regular Expression Matching
      23 Merge k Sorted Lists
      25 Reverse Nodes in k-Group
      32 Longest Valid Parentheses
      37 Sudoku Solver
      41 First Missing Positive
      42 Trapping Rain Water
      44 Wildcard Matching
      52 N-Queens II
      72 Edit Distance
      84 Largest Rectangle in Histogram
      124 Binary Tree Maximum Path Sum
      127 Word Ladder
      239 Sliding Window Maximum
      312 Burst Balloons
- [ ] Add docs: `aster/tests/leetcode/README.md` describing how to run the suite locally and how to add new problems/cases.

Keep this list updated as work progresses.

## Compiler Capability Gates (Examples -> Bench Unlocks)

These gates define the **minimum** compiler capabilities required to reach "all
benchmarks compile and run" without shims. Each gate has a concrete Aster
example and the benchmark(s) it unlocks.

Gate 0: CLI + file IO + basic codegen to `main`
```aster
def main() returns i32
    return 0
```
Unlocks: compiler plumbing (no benches yet).

Gate 1: locals, arithmetic, comparisons, while-loops
```aster
def main() returns i32
    var i is usize = 0
    var sum is u64 = 0
    while i < 1000 do
        sum = sum + i
        i = i + 1
    return (sum != 0)
```
Unlocks: kernel control-flow backbone (dot/gemm/stencil/sort style loops).

Gate 2: extern calls + string literals (C ABI)
```aster
extern def printf(fmt is String, a is u64) returns i32
def main() returns i32
    printf("%llu\n", 123)
    return 0
```
Unlocks: most kernels (all current kernels print a result).

Gate 3: heap + pointer indexing (malloc/free + load/store)
```aster
extern def malloc(n is usize) returns String
extern def free(p is String) returns ()
extern def printf(fmt is String, a is f64) returns i32

def main() returns i32
    var n is usize = 1024
    var a is slice of f64 = malloc(n * 8)
    if a is null then
        return 1
    var i is usize = 0
    while i < n do
        a[i] = 1.0
        i = i + 1
    printf("%f\n", a[0])
    free(a)
    return 0
```
Unlocks: dot/gemm/stencil/sort/regex/async_io (and most hot loops).

Gate 4: structs + address-of + field access (FFI-friendly)
```aster
extern def pipe(fds is slice of i32) returns i32

struct FdPair
    var rfd is i32
    var wfd is i32

def main() returns i32
    var fds is FdPair
    return pipe(&fds.rfd)
```
Unlocks: async_io + parts of fswalk/treewalk that use structured FFI.

Gate 5: "fs benches" surface area (pointers-to-structs + libc structs)
- compile+run `aster/bench/fswalk/fswalk.as` end-to-end with fixed datasets.
Unlocks: fswalk/treewalk/dircount/fsinventory.

## Iteration Loop (After Gate 5)

1. Change compiler/runtime/bench source.
2. Run asm unit tests: `asm/tests/run.sh`.
3. Run fast e2e compile+run smoke for every bench (small inputs).
4. Run `BENCH_SET=kernels tools/bench/run.sh`, then full suite with fixed fs datasets.
5. Only then record a new run in `BENCH.md` (real `asterc` epoch).

## Current Status + Handoff (replaces NEXT.md)

Updated: 2026-02-06

This section is the live "where we are / how to run / what's next" handoff.
`NEXT.md` is deprecated; keep this section current instead.

Where we are:
- Active tree: `asm/`, `aster/`, `tools/`, `docs/` (old Rust workspace removed).
- Benchmark harness exists (`tools/bench/run.sh`) with C++/Rust baselines and fixed fs datasets.
- The real Aster compiler (`asterc`) is in progress in assembly (`asm/compiler/*`, `asm/driver/*`).
- Legacy shim-based benchmark compilers/templates were removed per policy; results in `BENCH.md`
  prior to the real `asterc` are legacy and not a valid score going forward.

Toolchain (today):
- `asterc` is a native compiler implemented in assembly (allowed) and must compile `.as` source.
- Build (once `asm/driver/asterc.S` exists): `tools/build/build.sh asm/driver/asterc.S`
  which outputs `tools/build/out/asterc`.
- `tools/build/asterc.sh` runs `tools/build/out/asterc` by default (override with `ASTER_COMPILER`).

Benchmark harness:
- `tools/bench/run.sh` builds Aster/C++/Rust into `$BENCH_OUT_DIR` (default:
  `.context/bench/out`), runs each bench multiple times, and reports medians +
  win-rate/margin + suite geometric mean.
- Note: it requires a working `tools/build/out/asterc` to build Aster binaries.
- Kernels only command: `BENCH_SET=kernels tools/bench/run.sh`
- Filesystem benches (fixed dataset, recommended) command:
  `FS_BENCH_ROOT=$HOME FS_BENCH_MAX_DEPTH=5 FS_BENCH_LIST_FIXED=1 BENCH_SET=fswalk tools/bench/run.sh`

Filesystem bench model (see `aster/bench/fswalk/README.md` for the full list):
- `fswalk`: list/replay mode (decouples traversal from metadata/stat).
- `treewalk`: live traversal; `FS_BENCH_TREEWALK_MODE=bulk` uses macOS `getattrlistbulk`
  and respects `FS_BENCH_BULK_BUF` (default 8388608).
- `dircount`: live traversal count-only (`FS_BENCH_COUNT_ONLY=1`).
- `fsinventory`: inventory hashing + symlink counting (`FS_BENCH_INVENTORY=1`).

Filesystem env knobs (high leverage):
- `FS_BENCH_TREEWALK_MODE=bulk|fts` (bulk uses `getattrlistbulk` on macOS).
- `FS_BENCH_CPP_MODE=bulk|fts` (force baseline traversal strategy).
- `FS_BENCH_BULK_BUF=<bytes>` (getattrlistbulk buffer size; default 8388608).
- `FS_BENCH_PROFILE=1` (Aster prints traversal timing breakdown in bulk mode).

Known macOS constraint:
- `getattrlistbulk` requires requesting `ATTR_CMN_RETURNED_ATTRS`; attempts to omit it
  to force a fixed record layout hit EINVAL.

Near-term priorities (roadmap slice):
1) Implement the real `asterc` end-to-end path: parse/typecheck/codegen `.as` -> binary.
2) Expand the Aster1(MVP) subset until **all benchmarks compile and run** under `asterc`
   (no shims), with fast e2e smoke tests for each bench.
3) Re-baseline and restart hill-climbing in `BENCH.md` only after the real compiler is
   producing the benchmark binaries.
4) As milestones land, write learning docs and sample apps so the language is teachable and
   the stdlib surface (including networking/streaming) stays grounded in real usage.

## 1) Product goals

Aster is a statically typed, ahead-of-time compiled, native-code language with Python/Ruby-like ergonomics and C++/Rust-class performance on algorithmic kernels. The compiler and runtime are implemented in assembly for maximum performance and control.

Primary objectives:
- Predictable performance: typed hot loops compile to tight machine code with no hidden dynamic dispatch or mandatory GC barriers.
- Compilation speed: fast incremental builds in dev mode; optimized binaries in release mode.
- Allocation transparency: inner-loop allocations can be forbidden and audited by the compiler.
- Interop: first-class C ABI interoperability.
- Benchmark-driven evolution: every optimization must improve or preserve a benchmark-based objective function.

Non-negotiable acceptance gates (must be measurable):
- Runtime performance: >80% win rate vs C++ and Rust, with a sustained margin target of +5-15% faster than the best baseline (track: >=5% faster on >=80% of benches and suite geomean 0.85-0.95x; target ~0.90x).
- Build performance: >80% win rate vs C++ and Rust, with the same +5-15% margin target on clean builds and incremental rebuilds under pinned toolchains.
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

Stage 1: Aster compiler MVP (assembly; bench-complete subset)
- Implement lexer, parser, and a minimal type checker for the bench subset.
- Generate assembly directly (no optimizer required for correctness).
- Support the language features used by the benchmark suite (FFI, structs, loops, pointers/slices).

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
- Goalpost update (2026-02-06): beyond reaching >80% win rate, hill-climb toward a
  sustained +5-15% margin vs the best baseline (see acceptance gates).

## 10) Definition of done (production)

The compiler is production-ready when:
- It builds the stdlib and all core benchmarks on all supported targets.
- It passes CI gates and has no known correctness bugs in the core spec.
- It meets performance gates on the core benchmark suite.
- It ships with stable formatting, LSP, and package management.

## 11) Native ML roadmap (post-production): tinygrad -> Aster

We want Aster to support modern machine learning workloads natively (training + inference) and to be able to migrate tinygrad from Python into Aster as the reference ML stack. The tinygrad repo is cloned for reference at `libraries/tinygrad` (Python source).

This work starts after the native compiler is production-ready (Section 10) so that porting effort is not wasted on compiler churn.

Phases (deliverables are cumulative):
1) Parity harness: a reproducible test suite that compares Aster ML outputs against python tinygrad for the same graphs, dtypes, seeds, and devices (CPU first). This is the correctness gate for every migration step.
2) Tensor core + runtime: native `Tensor` storage (shape/strides/views), dtype + casting rules, broadcasting, reductions, RNG, and a device abstraction that can target CPU and GPU backends with explicit memory transfer semantics.
3) Autograd: reverse-mode autograd engine with a per-op backward registry, graph/tape representation, and a memory plan (saved tensors, rematerialization, and `noalloc`-friendly hot paths).
4) Lazy IR + scheduler: tinygrad-style lazy graph, op fusion, and a scheduler that produces executable kernels with stable cache keys; include shape inference and simplification passes needed for fusion.
5) Kernel backends:
   - CPU: vectorized kernels (NEON/AVX), threaded execution, tuned matmul/conv/softmax/attention building blocks.
   - Metal (macOS): compute shader codegen/compile, pipeline + binary cache, command buffer scheduling, and buffer pooling.
   - Later: CUDA and/or Vulkan (same IR, different codegen/runtime).
6) High-level ML APIs: `nn` modules, optimizers, loss functions, mixed precision, checkpointing/serialization (at least safetensors), and data input utilities needed to train and run real models end-to-end.
7) Model/task coverage: maintain a small "model zoo" that exercises the whole stack (vision CNN, transformer encoder, small decoder-only LLM) plus inference-only targets (quantized or distilled models).
8) Benchmarks + hill-climbing: add ML benchmarks to `BENCH.md` (kernels + training steps + inference) and hill-climb compiler/runtime/kernel changes against them, just like the existing benchmark suite.

End of spec.
