# How Aster Hill-Climbed Past C++ and Rust (from `BENCH.md`)

This is a narrative summary of what `BENCH.md` shows: the concrete steps that turned Aster from “assembly kernels + noisy timings” into a real `.as` compiler (`tools/build/out/asterc`) whose benchmark binaries beat both C++ and Rust on runtime and build time.

## 1) We Fixed the Benchmarking Before We “Fixed Performance”

Early dot runs (Run 001–003) were dominated by variance (min vs avg wildly diverged). The first real unlock was **measurement hygiene**:

- **Warmup + median reporting** replaced “avg of a few runs” (Run 004).
- The suite expanded beyond a single kernel (Run 005), which prevented overfitting to dot.
- FS benchmarks got **list/replay modes** plus fixed datasets and later sha256 + size metadata, so runs were reproducible and comparable over time (e.g., Run 009, Run 013, Run 054–055).
- The harness split “kernels” vs “fswalk” when cache interference was polluting signals (Run 014–015).

Result: changes started producing trustworthy deltas instead of “fast once, slow twice” noise.

## 2) We Stopped Cheating (on Purpose): “No Shims” and a Real `asterc`

The file explicitly calls out that early performance was not an authoritative score because kernels were hand-written or template-copied assembly.

Key pivot points:

- **Policy note (2026-02-06)**: benchmark binaries must be produced by real `asterc` compiling `.as` (no Python transpilers, no asm templates as a stand-in).
- **Epoch — real `asterc` (Started: 2026-02-06)**: Aster programs were compiled from `.as` by `tools/build/out/asterc` with the pipeline:
  - Aster source -> LLVM IR (`.ll`) -> `clang -O3` -> executable.
  - (See “Epoch — real `asterc`” and Runs 049+.)

This matters because later wins (Runs 054–055) are wins by a real compiler, not by hand-tuned one-off artifacts.

## 3) We Won by Combining “Compiler Guarantees” with “Library Algorithms”

`BENCH.md` shows the pattern: performance moved most when we gave the optimizer what it needs (aliasing, loop structure) *and* changed algorithms/data structures.

Compiler/codegen levers that show up repeatedly:

- Making loops vectorizable (earlier NEON kernels; later C-emit improvements):
  - Adding `__restrict__`-style non-aliasing for slice pointers.
  - Adding explicit loop vectorization hints (`#pragma clang loop vectorize`) for “while”-shaped loops. (Run 022 notes.)
- Reducing address arithmetic and enabling hoisting:
  - Stencil rewrites to hoist row offsets / use tiling. (Run 022 notes.)

Algorithm/data-structure levers that show up repeatedly:

- **Sort**: switching to **radix sort** to beat comparison-based baselines. (Run 019 notes.)
- **Hashmap**: stepping through probe strategies:
  - unrolling probes, precomputing masks (Run 024),
  - Robin Hood hashing with probe-distance tracking (Run 026),
  - packing metadata into high bits (Run 028).
- **Regex**: replacing nested/branchy matching with a **single-pass FSM** and then pointer scanning. (Run 022 and Run 024 notes.)
- **JSON**: pointer-based scanning, digit unrolling, and wider pre-scan tricks (Runs 022, 026, 028 notes).

The consistent theme is that Aster’s “high-level” code was rewritten into shapes that compilers can optimize aggressively (contiguous memory, predictable control flow), and then `asterc` ensured those shapes survived to optimized machine code.

## 4) We Used OS Primitives Where They Beat Language Libraries (FS Benches)

The fs benchmarks are where “language-level” performance meets system calls. `BENCH.md` records multiple iterations on:

- Moving from traversal helpers to compiled Aster implementations (Run 010 notes).
- Introducing and tuning **bulk attribute retrieval** (`getattrlistbulk`) and buffer sizing (Run 023, Runs 039–046).
- Adding inventory-style work (hashing, symlink counting) to avoid benchmark loopholes and keep the workload realistic (Run 036 notes).

This is one of the big sources of “Aster beats both baselines” behavior: Aster adopted the fastest available OS path and then tuned it.

## 5) Build Time: A Small Front-End + Caching Beat Big Toolchains

`BENCH.md` includes a compiler timing snapshot showing `asterc`’s own work is tiny compared to the backend:

- parse on the order of ~10s of microseconds, emit under 1ms, while the `clang -O3` stage was ~300ms (timing snapshot before Run 049).

Then the suite began recording **clean vs incremental** build timings in the gate runs (Run 051, and again in Run 055).

In the final recorded domination run (Run 055), the benchmark harness reports:

- Clean build: **aster 0.689s**, cpp 1.251s, rust 1.505s.
- Incremental build (touch protocol): **aster 0.068s**, cpp 0.068s, rust 0.123s.

The practical takeaway: Aster’s compilation pipeline stayed small and cache-friendly, so even when using `clang` as the optimizer/assembler, total “build the suite” time stayed lower than both baselines.

## 6) The End State: “Section 6 Domination” (Beating Both on Every Benchmark)

The project’s “Performance Domination” milestone (INIT section 6) is concretely evidenced by Runs 054–055:

- Full suite, fixed hashed datasets, higher iteration count (`BENCH_ITERS=20`).
- **Win rate 12/12 = 100%**, and every benchmark is at least 15% faster than the faster of C++/Rust.
- Geometric mean (aster/baseline) around **0.33–0.34x**, i.e. roughly **3x faster** than the best baseline on average.

That outcome is not from a single trick; it’s the compound effect of:

- stable measurement,
- removing non-compiler “wins,”
- designing semantics and codegen to keep loops vectorizable,
- selecting faster algorithms/data structures for the workload,
- using the fastest OS interfaces for filesystem-heavy work,
- and continuously recording deltas so regressions and noise were visible immediately.

