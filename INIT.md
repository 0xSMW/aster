# Aster language and compiler production specification (v1.0 engineering spec)

This document defines the production-grade requirements for the Aster language, compiler, runtime, standard library, build tool, and benchmark system. The intent is to build a real, competitive compiler and ecosystem, not a prototype. Any implementation decisions must satisfy the constraints here unless amended by a written spec update.

## Task Tracker (kept current)

Updated: 2026-01-31
Legend: [x] done, [ ] todo, [~] in progress

- [x] Define concrete repo skeleton and create workspace scaffolding (Cargo workspace, crates, CI).
- [x] Expand IR and type system specs (AST/HIR/MIR schemas, invariants).
- [x] Add formal grammar appendix (EBNF).

- [ ] Frontend: implement indentation-aware lexer with spans (aster_frontend).
- [ ] Frontend: implement CST parser with error recovery + precedence.
- [ ] Frontend: build AST lowering + AST serialization in aster_ast.
- [ ] Formatter: implement asterfmt over CST with deterministic whitespace rules.

- [ ] Name resolution: symbol tables, def IDs, module imports (aster_hir).
- [ ] HIR lowering: resolve paths + attach DefIds and symbols.
- [ ] Type checking: constraints + unification + numeric literal typing.
- [ ] Trait solver: scoped resolution + caching + coherence checks.

- [ ] MIR builder: build CFG + basic blocks + SSA locals.
- [ ] MIR verifier: structural invariants + dominance checks.
- [ ] Borrow checker: lifetime inference + borrow graph validation.
- [ ] Escape analysis: stack promotion + allocation reporting.

- [ ] Optimizations: const fold, DCE, CSE, LICM, bounds-check elim.
- [ ] Inliner: threshold-based with size/compile-time knobs.
- [ ] Codegen: Cranelift dev backend + LLVM release backend.
- [ ] Debug info: DWARF emission + stable symbol mangling.

- [ ] Module interface: `.asmod` format + hashing + dep metadata.
- [ ] Incremental: content-addressed cache + invalidation strategy.
- [ ] aster CLI: aster.toml, lockfile, dep resolver, build graph.

- [ ] Runtime: panic runtime + stack traces + alloc hooks.
- [ ] Stdlib core + alloc + io + sync + time + math + test.

- [ ] Bench harness: datasets + C++/Rust baselines + runner.
- [ ] Dashboards: perf time series + regression detection.

Keep this list updated as work progresses.

## 1) Product goals

Aster is a statically typed, ahead-of-time compiled, native-code language with Python/Ruby-like ergonomics and C++/Rust-class performance on algorithmic kernels.

Primary objectives:
- Predictable performance: typed hot loops compile to tight machine code with no hidden dynamic dispatch or mandatory GC barriers.
- Compilation speed: fast incremental builds in dev mode; optimized binaries in release mode.
- Allocation transparency: inner-loop allocations can be forbidden and audited by the compiler.
- Interop: first-class C ABI interoperability.
- Benchmark-driven evolution: every optimization must improve or preserve a benchmark-based objective function.

Non-negotiable acceptance gates (must be measurable):
- Runtime performance: kernels within 1.05-1.25x of the C++/Rust baseline on the majority of core benchmarks.
- Noalloc enforcement: @noalloc must be sound and enforced transitively.
- Incremental rebuilds: small edits in a leaf module should not trigger whole-program rebuilds.
- Deterministic builds: same inputs produce identical outputs (bit-for-bit) for release builds, modulo toolchain version IDs.

## 2) Repository skeleton and build system (concrete)

### 2.1 Workspace layout (actual directories)

This repo is a Rust workspace and the canonical structure is:

```
.
├─ Cargo.toml               # workspace
├─ rust-toolchain.toml      # pinned toolchain
├─ crates/
│  ├─ aster/                # `aster` CLI (build/run/test/bench)
│  ├─ asterc/               # compiler driver (invoked by aster)
│  ├─ aster_frontend/       # lexer, parser, CST/AST
│  ├─ aster_ast/            # AST data model
│  ├─ aster_hir/            # HIR data model
│  ├─ aster_mir/            # MIR data model
│  ├─ aster_typeck/         # type checking + inference
│  ├─ aster_codegen/        # Cranelift/LLVM backends
│  ├─ aster_runtime/        # runtime hooks + panic + alloc
│  ├─ aster_diagnostics/    # diagnostics, spans, reporting
│  ├─ aster_span/           # FileId, Span, SourceMap
│  ├─ asterfmt/             # formatter
│  └─ asterlsp/             # LSP server
├─ stdlib/                  # stdlib source (Aster)
├─ tests/                   # compiler + stdlib tests
├─ tools/                   # bindgen, docgen, perf tools
├─ perf/                    # self-profile tooling
├─ aster-bench/             # benchmarks + harness
└─ .github/workflows/ci.yml
```

This skeleton is already created in the repo and should be filled in place (do not reorganize unless spec changes).

### 2.2 Crate responsibilities

- `aster`: user-facing CLI, invokes `asterc` and manages build graph and caching.
- `asterc`: compiler driver, orchestrates frontend, passes, and codegen.
- `aster_frontend`: lexing, parsing, CST building, AST construction.
- `aster_ast`: AST data types and serialization helpers.
- `aster_hir`: HIR data types and IDs for resolved symbols.
- `aster_mir`: MIR data types and SSA invariants.
- `aster_typeck`: type inference, constraint solving, trait resolution.
- `aster_codegen`: Cranelift + LLVM integration, target lowering.
- `aster_runtime`: panic runtime, alloc hooks, stack traces, noalloc enforcement.
- `aster_diagnostics`: diagnostics engine, error codes, linting.
- `aster_span`: source map, FileId, Span.
- `asterfmt`: stable formatter.
- `asterlsp`: LSP server.

### 2.3 Build system

- Rust workspace with pinned toolchain in `rust-toolchain.toml`.
- `aster` uses aster.toml manifests and a lockfile for deterministic builds.
- Build modes:
  - dev: Cranelift backend, incremental on, debug info on.
  - release: LLVM backend, full optimizations, optional LTO.
  - bench: release + instrumentation.
- External dependencies:
  - LLVM (preferred via llvm-sys or equivalent)
  - Cranelift (bytecodealliance crates)
  - SIMD intrinsics (std or target-specific)

### 2.4 CI and quality gates

The CI configuration (`.github/workflows/ci.yml`) must enforce:
- `cargo fmt --check`
- `cargo clippy -- -D warnings`
- `cargo test --workspace`
- (Later) benchmark smoke suite

## 3) Language design (surface syntax and semantics)

### 3.1 Lexing and formatting
- Indentation defines blocks. Tabs are illegal.
- Indent unit is 4 spaces.
- Whitespace rules are deterministic and enforced by asterfmt.
- Comments: `#` to end of line.
- Identifiers are Unicode-normalized to NFC; keywords are ASCII.
- Strings are UTF-8; `str` is a borrowed UTF-8 view with explicit length.

### 3.2 Evaluation order
- Left-to-right for expressions and argument lists.
- No hidden reordering of side effects.

### 3.3 Types
- Static typing with local type inference.
- Explicit types required for public API surfaces: exported functions, module constants, struct fields, trait methods.
- No whole-program inference.

Built-in types:
- Integers: i8 i16 i32 i64 isize, u8 u16 u32 u64 usize
- Floats: f32 f64
- bool, char (Unicode scalar)
- str (borrowed UTF-8 view), String (owning)
- slice[T] (borrowed contiguous view), Array[T] (owning growable)
- span[T, N] (fixed-size stack value)
- ptr[T] (unsafe raw pointer)
- Option[T], Result[T, E]

### 3.4 Structs, enums, classes
- struct: value type with predictable layout
- enum: tagged union with niche-filling where possible
- class: reference type with explicit heap allocation
- layout control via @repr(C), @packed, @align(n)

### 3.5 Traits and generics
- Traits (interfaces) with explicit bounds for operator overloading and constraints.
- Default monomorphization for generics.
- Optional dictionary-passing mode for code size and compile-time control.
- Dynamic dispatch only via `dyn Trait` and explicit vtable types.

Trait resolution rules:
- Scoped resolution (module + imports); no global search.
- Coherence rules to prevent conflicting impls.
- Deterministic, cached resolution results keyed by module interface hash.

### 3.6 Ownership and borrowing
- Value types are moved by default, copied only for Copy types.
- Borrowing rules: any number of immutable borrows OR one mutable borrow per scope.
- Non-lexical lifetime shortening allowed where proven.
- Interior mutability only via explicit types (Cell, Mutex, Atomic).
- Unsafe blocks exist but must be explicit and auditable.

### 3.7 Effects and purity
- Functions are effect-pure by default (no implicit global state mutations).
- Side effects must use explicit effectful APIs or marked effect types.
- Effect inference allowed within a function body; public signatures must declare effects.

### 3.8 Error handling
- Result[T, E] with `try` for propagation and `catch` for recovery.
- `panic` for unrecoverable invariants.
- No implicit exceptions in v1.0.

### 3.9 Concurrency and async
- Native threads and atomics in core.
- async/await compiled to state machines.
- Data-race freedom in safe code; Send/Sync-like traits required for thread transfer.
- Memory model consistent with C11/C++11 atomics.

## 4) Compiler architecture (detailed)

### 4.1 Source infrastructure

All IR nodes must carry spans and stable IDs.

```
FileId: u32
Span { file: FileId, lo: u32, hi: u32 }
NodeId: u32                 # local ID within a compilation unit
DefId { crate_id: u32, idx: u32 }  # globally unique
SymbolId: u32               # interned string ID
TypeId: u32                 # interned type ID
```

Source maps must support:
- file -> line/column mapping
- macro expansion tracking
- deterministic ordering

### 4.2 AST schema (producer: parser)

AST is purely syntactic with minimal desugaring.

```
Module {
  name: Path,
  items: Vec<Item>,
  span: Span
}

Item = Function | Struct | Enum | Class | Trait | Impl | Const | Use

Function {
  name: Ident,
  params: Vec<Param>,
  ret: TypeRef,
  body: Block,
  attrs: Vec<Attr>,
  vis: Visibility,
  span: Span
}

Param { name: Ident, ty: TypeRef, span: Span }

Block { stmts: Vec<Stmt>, span: Span }

Stmt = Let | Assign | Expr | Return | If | While | ForRange | Break | Continue | Defer | Require

Expr =
  Lit | Name | Call | Index | Field | Unary | Binary | Cast | IfExpr | BlockExpr |
  StructLit | ArrayLit | Range | Lambda

TypeRef =
  Path | Slice(TypeRef) | Array(TypeRef, ConstExpr) | Ptr(TypeRef) | Ref(TypeRef, Mut) |
  Tuple(Vec<TypeRef>) | Fn(Vec<TypeRef>, TypeRef) | Generic(Path, Vec<TypeRef>)
```

### 4.3 HIR schema (producer: name resolution)

HIR is name-resolved and assigns DefIds to all items and bindings.

```
HirModule {
  crate_id: u32,
  items: Vec<HirItem>,
  symbols: SymbolTable
}

HirItem::Function(HirFunction)
HirFunction { def_id: DefId, params: Vec<HirParam>, ret: TypeRef, body: HirBody, attrs, vis }
HirParam { local_id: LocalId, name: SymbolId, ty: TypeRef }
HirBody { blocks: Vec<HirBlock> }

HirExpr carries resolved paths and DefIds for names.
```

### 4.4 Type system schema

```
TypeKind =
  | Primitive(i8/i16/i32/i64/isize/u8/u16/u32/u64/usize/f32/f64/bool/char)
  | Str | String
  | Slice(TypeId)
  | Array(TypeId, Const)
  | Span(TypeId, Const)
  | Ptr(TypeId, Mut)
  | Ref(TypeId, Mut, Region)
  | Tuple(Vec<TypeId>)
  | Struct(DefId, Subst)
  | Enum(DefId, Subst)
  | Class(DefId, Subst)
  | TraitObject(DefId, Subst)   # dyn Trait
  | Fn(Vec<TypeId>, TypeId, Effects)
  | Generic(ParamId)

Const = Int(i64) | Bool(bool) | Param(ParamId)

GenericParam = TypeParam | ConstParam | RegionParam
Subst = Vec<GenericArg>
GenericArg = Type(TypeId) | Const(Const) | Region(Region)

Region = Static | Param(RegionParamId) | Inferred

Effects = { alloc: bool, io: bool, unsafe: bool, async: bool, ... }
```

Type inference:
- Hindley-Milner style with constraints and unification.
- Trait constraints are solved by a scoped trait solver with caching.

### 4.5 MIR schema (producer: lowering from HIR + typeck)

MIR is SSA-based with explicit control flow graph.

```
MirBody {
  blocks: Vec<BasicBlock>
  locals: Vec<LocalDecl>
  args: Vec<LocalId>
  ret_local: LocalId
}

BasicBlock { stmts: Vec<Statement>, terminator: Terminator }

Statement =
  | Assign(Place, Rvalue)
  | StorageLive(LocalId)
  | StorageDead(LocalId)
  | Validate(Place, ValidationKind)
  | Nop

Rvalue =
  | Use(Operand)
  | BinaryOp(Op, Operand, Operand)
  | UnaryOp(Op, Operand)
  | Cast(Operand, TypeId)
  | Ref(Place, BorrowKind)
  | Len(Place)
  | Index(Place, Operand)
  | Aggregate(AggregateKind, Vec<Operand>)

Operand = Copy(Place) | Move(Place) | Constant(Const)

Place = Local(LocalId, Projection[])   # Projection: Field, Index, Deref

Terminator =
  | Return
  | Goto(BasicBlockId)
  | SwitchInt { discr: Operand, targets: Vec<(i64, BasicBlockId)>, otherwise: BasicBlockId }
  | Call { func: Operand, args: Vec<Operand>, dest: Place, target: BasicBlockId, unwind: BasicBlockId? }
  | Assert { cond: Operand, target: BasicBlockId, msg: AssertMsg }
  | Unreachable
```

MIR invariants:
- SSA: each Local is assigned exactly once unless marked mutable and SSA-lifted.
- All places are in-bounds unless wrapped by explicit bounds-check instructions.
- No implicit heap allocation; allocations appear as explicit runtime calls.

### 4.6 Borrow checking and escape analysis

- Borrow checker operates on MIR with lifetimes inferred from HIR scopes.
- Escape analysis determines stack vs heap allocation.
- @noalloc attribute is enforced by verifying no allocation paths in call graph.

### 4.7 Module interface (.asmod)

Module interface is a binary format with a JSON debug export. Contents:

```
Header { magic, version, target_triple, compiler_version, hash }
Exports {
  functions: [ { def_id, name, params, ret, abi, effects } ]
  types: [ { def_id, kind, layout, generics } ]
  traits: [ { def_id, methods, bounds } ]
  impls: [ { trait_def_id, type_def_id, where_clauses } ]
  consts: [ { name, ty, value } ]
}
Dependencies { module_name, module_hash }
```

The `.asmod` hash is used for incremental compilation caching and invalidation.

## 5) Backends

### 5.1 Dev backend (Cranelift)
- Fast compile, minimal optimization, correct ABI.
- Used for `aster build` and `aster test` in dev mode.

### 5.2 Release backend (LLVM)
- Full optimization, LTO options, vectorization enabled.
- Used for `aster build --release` and `aster bench`.

### 5.3 Cross-platform
- Target triples supported: macOS (arm64/x86_64), Linux (x86_64/arm64), Windows (x86_64).
- Cross-compilation via target sysroot and prebuilt stdlib.

## 6) Runtime and standard library

Runtime:
- Deterministic destruction (RAII and defer).
- Panic runtime with stack traces and abort option.
- Allocation hooks for @noalloc and alloc reports.

Stdlib (v1.0 minimum):
- core, alloc, io, time, sync, math, test
- prebuilt artifacts per target triple
- zero-cost abstractions where performance-critical

## 7) Diagnostics and developer experience

Compiler diagnostics must include:
- precise spans and multi-span notes
- type mismatch explanations with expected/actual types
- borrow checker errors with lifetime hints
- @noalloc violations with call chain
- alloc report in JSON

Tooling:
- asterfmt: deterministic formatting
- asterlsp: goto definition, hover type, semantic tokens, formatting on save
- aster doc: API docs with type and effect signatures

## 8) Build tool (aster CLI)

Command surface:
- `aster init`, `aster build`, `aster run`, `aster test`, `aster bench`
- `aster fmt`, `aster doc`, `aster lsp`

Manifest:
- `aster.toml` defines package, targets, dependencies, features
- lockfile required for reproducibility

## 9) Benchmark system (production requirement)

Benchmarks are mandatory and gate optimization changes.

Bench structure:
- Each benchmark: `bench.json`, `datasets/`, `ref/`, `impl/aster`, `impl/cpp`, `impl/rust`

Core algorithm set (must be implemented in Aster/C++/Rust):
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

## 10) CI and quality gates

CI must include:
- Lint, format, unit tests
- Integration tests for compiler + stdlib
- Smoke benchmark suite (<10 min)
- Nightly core suite
- Weekly full suite + perf counters

Quality requirements:
- Fuzzing of lexer/parser/typechecker
- IR verifier on every pass
- Deterministic build verification

## 11) Security and reproducibility

- Hermetic builds with cached dependencies
- No network access during compilation except explicit package fetch
- Reproducible releases with pinned toolchains

## 12) Implementation roadmap (production)

Phase 0: Parser + formatter + module system skeleton
- Exit: stable formatting, deterministic AST, module import graph works

Phase 1: Typed core + numeric loops + slices
- Exit: kernel suite runs correctly; dot/matmul within 3-10x baseline

Phase 2: MIR + basic optimizations + bounds-check elimination
- Exit: kernel suite within 1.5-2x baseline

Phase 3: Borrow/escape analysis + @noalloc + alloc report
- Exit: inner-loop allocations eliminated where provable

Phase 4: Generics + traits + monomorphization + inliner
- Exit: data-structure suite within 1.2-1.7x baseline

Phase 5: LLVM backend + ThinLTO + vectorization
- Exit: core suite within 1.05-1.25x baseline

Phase 6: Concurrency + async + stdlib maturity
- Exit: concurrency suite competitive; safe code race-free

Phase 7: Autotuning + regression gates + dashboards
- Exit: automated knob tuning yields net improvements

## 13) Definition of done (production)

The compiler is production-ready when:
- It builds the stdlib and all core benchmarks on all target triples.
- It passes CI gates and has no known correctness bugs in the core spec.
- It meets performance gates on the core benchmark suite.
- It ships with stable formatting, LSP, and package management.

## Appendix A: Formal grammar (EBNF)

Lexical tokens:
- IDENT, INT, FLOAT, STRING
- NEWLINE, INDENT, DEDENT

EBNF:

```
module      = "module" path NEWLINE { item } EOF ;
path        = IDENT { "." IDENT } ;

item        = function | struct | enum | trait | impl | const | use ;

function    = "def" IDENT "(" params ")" "->" type ":" block ;
params      = [ param { "," param } ] ;
param       = IDENT ":" type ;

struct      = "struct" IDENT [ generics ] ":" block ;
enum        = "enum" IDENT [ generics ] ":" block ;
trait       = "trait" IDENT [ generics ] ":" block ;
impl        = "impl" [ generics ] type ":" block ;
const       = "const" IDENT ":" type "=" expr NEWLINE ;
use         = "use" path NEWLINE ;

block       = NEWLINE INDENT { stmt } DEDENT ;

stmt        = let_stmt | assign_stmt | if_stmt | while_stmt | for_stmt |
              return_stmt | break_stmt | continue_stmt | defer_stmt |
              require_stmt | expr_stmt ;

let_stmt    = [ "var" ] IDENT [ ":" type ] "=" expr NEWLINE ;
assign_stmt = lvalue assign_op expr NEWLINE ;
assign_op   = "=" | "+=" | "-=" | "*=" | "/=" | "%=" ;

if_stmt     = "if" expr ":" block [ "elif" expr ":" block ] [ "else" ":" block ] ;
while_stmt  = "while" expr ":" block ;
for_stmt    = "for" IDENT "in" expr ".." expr ":" block ;
return_stmt = "return" [ expr ] NEWLINE ;
break_stmt  = "break" NEWLINE ;
continue_stmt = "continue" NEWLINE ;
defer_stmt  = "defer" block ;
require_stmt = "require" expr NEWLINE ;
expr_stmt   = expr NEWLINE ;

lvalue      = IDENT { ( "." IDENT ) | ( "[" expr "]" ) } ;

expr        = or_expr ;
or_expr     = and_expr { "or" and_expr } ;
and_expr    = eq_expr { "and" eq_expr } ;
eq_expr     = cmp_expr { ("=="|"!=") cmp_expr } ;
cmp_expr    = add_expr { ("<"|"<="|">"|">=") add_expr } ;
add_expr    = mul_expr { ("+"|"-") mul_expr } ;
mul_expr    = unary_expr { ("*"|"/"|"%") unary_expr } ;
unary_expr  = ("-"|"not") unary_expr | call_expr ;

call_expr   = primary { "(" [ args ] ")" | "[" expr "]" | "." IDENT } ;
args        = expr { "," expr } ;

primary     = INT | FLOAT | STRING | "true" | "false" | IDENT | "(" expr ")" ;

 type       = path | "slice" "[" type "]" | "span" "[" type "," INT "]" |
              "ptr" "[" type "]" | "ref" "[" type "]" |
              "(" type { "," type } ")" ;
```

End of spec.
