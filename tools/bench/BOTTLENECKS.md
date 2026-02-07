# Benchmark Bottlenecks (Tracked)

Updated: 2026-02-07

This file tracks the current top suspected bottlenecks for each benchmark plus the next planned optimization(s) to keep Aster at (or below) the `<=0.80x` domination target against the fastest baseline (min of C++ and Rust).

Evidence rule:
- If a bottleneck is not backed by a profile (Instruments, `sample`, or compiler IR inspection), label it **(suspected)**.
- When confirmed, record the supporting run/log in `BENCH.md` and update the entry to **(confirmed)**.

## dot
- Bottleneck 1: process startup / libc call overhead dominates at very small sizes (**suspected**).
- Bottleneck 2: missed vectorization due to aliasing/stride patterns (**suspected**).
- Bottleneck 3: reduction tree vs scalar accumulation (FP associativity constraints) (**suspected**).
- Plan: keep data contiguous + restrict-like semantics; widen to NEON/AVX and use unrolled reduction.

## gemm
- Bottleneck 1: BLAS dispatch overhead at tiny matrices (**suspected**).
- Bottleneck 2: cache blocking parameters not tuned for M1/M2 L1/L2 sizes (**suspected**).
- Bottleneck 3: packing cost vs compute at current sizes (**suspected**).
- Plan: introduce size-specialized microkernels; tune packing/blocking; avoid dynamic dispatch in the hot path.

## stencil
- Bottleneck 1: memory bandwidth (streaming loads/stores) (**suspected**).
- Bottleneck 2: halo handling / branchy edge conditions (**suspected**).
- Bottleneck 3: thread partitioning overhead at small heights (**suspected**).
- Plan: tile + vectorize inner loops; hoist address arithmetic; specialize edge handling; tune thread chunk sizes.

## sort
- Bottleneck 1: radix histogram/scatter cache misses (**suspected**).
- Bottleneck 2: extra passes due to key width and sign handling (**suspected**).
- Bottleneck 3: allocation/copy traffic between buffers (**suspected**).
- Plan: reduce passes (byte/word grouping), prefetch/scatter tuning, reuse scratch buffers, and ensure stable alignment.

## json
- Bottleneck 1: UTF-8/escape handling branches (**suspected**).
- Bottleneck 2: number parsing (digits -> int/float) (**suspected**).
- Bottleneck 3: bounds checks / pointer chasing in scanner (**suspected**).
- Plan: widen pre-scan for structural chars, branchless digit loops, and tighten bounds-check elimination.

## hashmap
- Bottleneck 1: probe loop latency (dependent loads) (**suspected**).
- Bottleneck 2: hash quality vs mixing cost (**suspected**).
- Bottleneck 3: resize/rehash spikes (allocation + memcpy) (**suspected**).
- Plan: keep probe loops unrolled and branch-light; consider SIMD probe metadata; implement amortized growth policies and reuse arenas.

## regex
- Bottleneck 1: branch mispredicts in matcher state machine (**suspected**).
- Bottleneck 2: backtracking / worst-case inputs (even if avoided, guardrails matter) (**suspected**).
- Bottleneck 3: UTF-8 decoding if non-ASCII enabled (**suspected**).
- Plan: keep single-pass DFA/FSM shapes; precompute tables; add fast ASCII path with validated UTF-8 fallback.

## async_io
- Bottleneck 1: syscall overhead (read/write/kevent/kqueue equivalents) (**suspected**).
- Bottleneck 2: allocator overhead for per-request bookkeeping (**suspected**).
- Bottleneck 3: thread handoff / synchronization (**suspected**).
- Plan: batch syscalls, reuse request buffers, reduce locking, and keep hot structures cache-friendly.

## fswalk (list/replay)
- Bottleneck 1: per-path `stat`/`lstat` syscalls (**suspected**).
- Bottleneck 2: path parsing and NUL-termination work (**suspected**).
- Bottleneck 3: cache effects from large path lists (**suspected**).
- Plan: bulk metadata where possible; keep byte-scan parser; tune list chunking and minimize per-line branching.

## treewalk (live traversal)
- Bottleneck 1: directory enumeration syscalls and vnode caching (**suspected**).
- Bottleneck 2: getattr bulk decode / buffer sizing (**suspected**).
- Bottleneck 3: work inflation from extra metadata (inventory mode) (**suspected**).
- Plan: keep bulk mode default; tune `FS_BENCH_BULK_BUF`; minimize decode and hashing overhead.

## dircount
- Bottleneck 1: traversal API overhead (fts vs bulk) (**suspected**).
- Bottleneck 2: recursion/stack management in bulk walk (**suspected**).
- Bottleneck 3: symlink handling / follow rules (**suspected**).
- Plan: ensure bulk path stays branch-light; tighten stack representation; keep follow/no-follow fast paths.

## fsinventory
- Bottleneck 1: per-entry name hashing (**suspected**).
- Bottleneck 2: metadata decode for object type and sizes (**suspected**).
- Bottleneck 3: cache misses from touching more data per entry (**suspected**).
- Plan: vectorize/unalign-safe hash loop; reduce loads; ensure bulk buffers sized to avoid extra syscalls.

