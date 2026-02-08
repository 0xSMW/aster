# Adversarial Upgrades: Make C++/Rust Baselines Harder To Beat

This repo’s benchmark baselines leave a lot of performance on the table in C++ and Rust (often algorithmic, not just flags). Below is a concrete set of upgrades that would materially raise the bar so Aster has to keep earning wins.

Scope: proposals only (no code changes yet).

---

## 0) Global: Compile/Link Like You Mean It

Today `tools/bench/run.sh` compiles C++ as `clang++ … -O3` and Rust as `rustc -O …` with no CPU tuning, no LTO, and minimal “fast math” enabling. This alone can be a large gap on numeric kernels.

### C++ (clang++)
Recommended baseline flags (runtime-focused, still reasonable build time):
- `-O3 -DNDEBUG -march=native -mtune=native`
- Numeric benches only: `-ffast-math -fno-math-errno -fno-trapping-math`
- If build-time is still acceptable: `-flto=thin`
- Optional: `-fno-exceptions -fno-rtti` (mostly build-size; small runtime impact here)

### Rust (rustc)
Recommended baseline flags (runtime-focused):
- `-O -C target-cpu=native`
- `-C panic=abort` (removes unwinding machinery; smaller/faster)
- If build-time allows: `-C lto=thin` (or `fat`), `-C codegen-units=1`

Build-time adversarial note:
- If the scorecard includes build time, you want a “balanced” profile: avoid LTO and `codegen-units=1`, but still take `target-cpu=native` and algorithmic upgrades (below). Those typically buy most runtime wins without huge compile-time cost.

---

## 1) Benchmark-by-Benchmark Upgrades

### `dot`
Current C++/Rust use a single accumulator (dependency chain) and rely on auto-vectorization.

High-impact changes:
- Copy Aster’s ILP strategy: 4-8 independent accumulators + unrolled loop + pointer iteration.
- Use aligned allocation and alignment hints:
  - C++: `posix_memalign` (64B) + `__builtin_assume_aligned`.
  - Rust: `Vec<f64>` is typically 8/16B aligned; consider `std::alloc` for 64B and use `unsafe` pointers.
- Explicit SIMD:
  - x86_64: AVX2/AVX-512 intrinsics (`_mm256_fmadd_pd`, horizontal sum).
  - aarch64: NEON (`vfmaq_f64`), process 2-4 doubles per lane.
- Numerical flags: enable `-ffast-math` for C++ dot (safe here; values are small and exactly representable).

Stretch (if you allow platform libs):
- Call Accelerate `vDSP_dotprD`/`cblas_ddot` for C++/Rust too.

### `gemm`
Aster uses Accelerate BLAS (`cblas_dgemm`) while C++/Rust do naive triple loops. This is a “free win” for Aster.

High-impact changes:
- Switch C++ and Rust GEMM to call `cblas_dgemm` (Accelerate) exactly like Aster.
  - C++: add `-framework Accelerate` and declare `extern "C" void cblas_dgemm(...);`.
  - Rust: `#[link(name="Accelerate", kind="framework")] extern "C" { fn cblas_dgemm(...); }`.
- Avoid clearing `c` manually by using BLAS `beta=0.0` (already what Aster does).

If you refuse BLAS:
- Implement a blocked GEMM (cache tiling) + small microkernel (register blocking) + `restrict` pointers. Even a simple `i0..i0+BI`, `k0..k0+BK`, `j0..j0+BJ` tiler will close most of the gap.

### `stencil`
Aster uses a multithreaded pthread runtime helper; C++/Rust are single-thread scalar loops.

High-impact changes:
- Add multithreading to C++ and Rust:
  - Partition rows across threads (static chunking).
  - Use a spin barrier or `pthread_barrier_t` to swap buffers each step.
  - Cap threads (Aster caps at 8) to avoid oversubscription.
- Inner-loop micro-opts:
  - Precompute row pointers (`row`, `row_up`, `row_dn`) to avoid `i*W` per cell.
  - Add `restrict`/`__restrict` in C++ and use raw pointers in Rust to eliminate bounds checks.
  - Unroll the `j` loop (4-8) and let the compiler vectorize; optionally explicit SIMD.

### `sort`
Aster uses an LSD radix sort (11-bit digits, 6 passes). C++/Rust use comparison sort.

High-impact changes:
- Replace `std::sort` / `sort_unstable` with radix sort for `u64`.
  - Match Aster: 11-bit digit, 2048-bucket counting, 6 passes.
  - Allocate `tmp` and `counts` once (outside the iteration loop) and reuse.
  - Backward scatter for stability (Aster does this).
- Optional: tune digit width (8/11/12 bits) based on L1/L2 behavior on your target CPU.
- Optional: parallel radix sort (split into chunks, per-thread histograms, prefix sum, scatter).

### `json`
Aster’s JSON micro-parser is optimized (8-byte “skip scan” + 4-digit chunk parsing). C++/Rust are byte-at-a-time.

High-impact changes:
- Implement the same fast-path structure in C++ and Rust:
  - While `i+8 <= len`: load 8 bytes and quickly decide whether any byte is `"` or a digit; if not, `i += 8`.
  - For digit runs: parse 4 digits at a time (`num = num*10000 + …`) then finish scalar.
- Remove bounds checks in Rust:
  - Use `unsafe` pointer iteration and a checked end pointer.
- Use SWAR tricks for digit detection (optional but big):
  - A fast “any is digit” test on 8 bytes avoids 8 separate compares.

If you allow external libs:
- C++: simdjson “ondemand” (would obliterate this micro-benchmark).
- Rust: `simd-json` or `serde_json` with tuned features, but note this changes benchmark intent.

### `hashmap`
Aster exploits benchmark-specific facts:
- Hash is `key & MASK` (LCG is full-period mod 2^k, so low bits are “good enough” here).
- Lookup loop assumes keys are present (`map_get_present`), eliminating the empty-slot branch.
- Key/value are packed in one array to keep loads on the same cache line.

High-impact changes:
- Make C++/Rust do the same:
  - Table layout: single `u64 tab[CAP*2]` storing `(key,val)` pairs.
  - Hash: `idx = key & (CAP-1)`.
  - Probe step: `base = (idx*2) & (CAP*2-1)` and `base = (base+2) & mask`.
  - Lookup: use a “present” version with *no* empty-slot check (since lookups are for inserted keys).
- Rust: use `get_unchecked`/raw pointers to remove bounds checks in the probe loop.
- Optional: prefetch next probe line (`__builtin_prefetch` / `core::arch` prefetch) and unroll probe by 2.

### `regex`
This benchmark is effectively the fixed regex `ab*c`. C++/Rust currently do a nested scan on every `a`.

High-impact changes:
- Replace the backtracking-ish scan with a 2-state DFA like Aster:
  - `state=0` seek `a`
  - `state=1` after `a`: accept `b*`, count match on `c`, reset on `x` (or anything else)
- Optimize the generator:
  - Replace `if/else` (C++) and `match` (Rust) with a packed LUT (`0x78636261`) and shifting to pick `a/b/c/x` from `r`.

Stretch:
- Process 8 or 16 bytes at a time and update DFA via bitmasks (SIMD “vectorized DFA”), but the simple DFA already closes most of the gap.

### `async_io`
C++/Rust do `poll()` every iteration; Aster just `write()` then blocking `read()`.

High-impact changes:
- Remove `poll()` from C++/Rust and do exactly what Aster does:
  - `write(wfd, buf, CHUNK); read(rfd, buf, CHUNK);`
- Make the syscalls robust without adding overhead:
  - Avoid looped partial reads/writes unless you actually see partial transfers on the platform; pipes with 4KB chunks typically complete.

### `fswalk` / `treewalk` / `dircount` / `fsinventory`
Aster uses multithreaded helpers (`fswalk_rt.o`) for list-mode stat and bulk tree enumeration; Rust uses high-level `std::fs` APIs; C++ is decent but largely single-threaded.

High-impact changes (C++):
- Parallelize list-mode (`FS_BENCH_LIST`) stat:
  - Read list once, split by line boundaries, N worker threads call `lstat/stat` and accumulate into thread-local counters, then reduce.
- Parallelize bulk treewalk list (`FS_BENCH_TREEWALK_LIST`):
  - Each thread gets a subset of directory roots; each thread owns its own `getattrlistbulk` buffer to avoid contention.
- Bulk parsing micro-opts:
  - Avoid repeated `memcpy` where safe; keep parsing pointer-aligned and use `__builtin_assume_aligned`.
  - Use `openat` flags like `O_CLOEXEC` and consider `F_NOCACHE` toggles only if they help (usually don’t for cached walks).

High-impact changes (Rust):
- Stop using `PathBuf`/`read_dir` in hot traversal loops:
  - Use FFI to macOS `getattrlistbulk` + `openat` (same API C++ already uses) for the bulk modes.
  - Keep a manual stack of directory fds (like the C++ bulk mode) to avoid allocating paths.
- If you must stay in list mode:
  - Multi-thread metadata/stat like above.
  - Use `std::os::unix::fs::MetadataExt` to pull mode/size quickly.

---

## 2) Quick “Parity” Checklist (What To Fix First)

If the goal is “make Aster’s current wins go away quickly”, do these in order:
1. `gemm`: call BLAS in C++/Rust (Accelerate) to match Aster.
2. `stencil`: add multithreading (Aster already parallelizes).
3. `sort`: switch to radix sort.
4. `hashmap`: use low-bit hash + packed table + present-only get.
5. `regex`: switch to DFA + LUT-based generator.
6. `async_io`: remove `poll()`.
7. `json`: add 8-byte skip scan + 4-digit parsing + `unsafe`/pointer loops.
8. Global flags: `-march=native` / `-C target-cpu=native`.

