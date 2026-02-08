# Aster Benchmarks

This file tracks benchmark runs and deltas over time.

## Policy Note (2026-02-06)

As of 2026-02-06 we enforce a "no compiler shims" policy: benchmark binaries must
be produced by the real Aster compiler (`asterc`) compiling `.as` source (no
Python transpilers, no pre-generated/hand-written assembly templates). Runs
recorded before that compiler exists are legacy and should not be treated as the
authoritative performance score for the project.

## Environment
- Host: Darwin arm64
- Clang: Apple clang 17.0.0 (clang-1700.6.3.2)
- Rust: rustc 1.92.0 (ded5c06cf 2025-12-08)
- Date: 2026-02-04

## Run 001 — dot baseline (hand-written assembly)
Command: `tools/bench/run.sh`

Benchmark: dot (N=5,000,000, REPS=3)
- aster: avg 0.2115s, min 0.0333s (runs 3)
- cpp:   avg 0.1399s, min 0.0193s (runs 3)
- rust:  avg 0.1693s, min 0.0199s (runs 3)

Perf delta (avg):
- aster/cpp  = 1.512x
- aster/rust = 1.249x

Notes:
- Aster kernel is hand-written assembly (not compiler-generated yet).

## Run 002 — dot vectorized + aligned + prefetch (posix_memalign)
Command: `tools/bench/run.sh`

Benchmark: dot (N=5,000,000, REPS=3)
- aster: avg 0.2982s, min 0.0234s (runs 3)
- cpp:   avg 0.1620s, min 0.0173s (runs 3)
- rust:  avg 0.1459s, min 0.0175s (runs 3)

Perf delta (avg):
- aster/cpp  = 1.841x
- aster/rust = 2.044x

Notes:
- Aster kernel uses NEON vectorization + prefetch + aligned allocation.
- Variance appears high; need more stable measurement.

## Run 003 — dot vectorized + prefetch (malloc)
Command: `tools/bench/run.sh`

Benchmark: dot (N=5,000,000, REPS=3)
- aster: avg 0.2775s, min 0.0218s (runs 3)
- cpp:   avg 0.0567s, min 0.0152s (runs 3)
- rust:  avg 0.0986s, min 0.0157s (runs 3)

Perf delta (avg):
- aster/cpp  = 4.896x
- aster/rust = 2.813x

Notes:
- Aster kernel uses NEON vectorization + prefetch; allocation reverted to malloc.
- Variance is high (min vs avg suggests outliers). Consider warmup/median reporting.

## Run 004 — dot vectorized + vector fill + median reporting
Command: `tools/bench/run.sh` (warmup 1, 6 runs, median over 5)

Benchmark: dot (N=5,000,000, REPS=3)
- aster: median 0.0173s, avg 0.0176s, min 0.0172s (runs 5)
- cpp:   median 0.0171s, avg 0.0170s, min 0.0157s (runs 5)
- rust:  median 0.0172s, avg 0.0172s, min 0.0157s (runs 5)

Perf delta (median):
- aster/cpp  = 1.014x
- aster/rust = 1.008x

Notes:
- Added vectorized fill loops and switched bench reporting to median with warmup.
- Median now shows near parity; prior averages were skewed by outliers.

## Run 005 — dot + gemm + stencil (median, warmup)
Command: `tools/bench/run.sh` (warmup 1, 6 runs, median over 5)

Benchmark: dot
- aster: median 0.0173s, avg 0.0195s, min 0.0166s (runs 5)
- cpp:   median 0.0167s, avg 0.0209s, min 0.0157s (runs 5)
- rust:  median 0.0177s, avg 0.0177s, min 0.0167s (runs 5)
- perf delta (median): aster/baseline 1.038x

Benchmark: gemm
- aster: median 0.0041s, avg 0.0042s, min 0.0040s (runs 5)
- cpp:   median 0.0031s, avg 0.0031s, min 0.0027s (runs 5)
- rust:  median 0.0033s, avg 0.0034s, min 0.0030s (runs 5)
- perf delta (median): aster/baseline 1.345x

Benchmark: stencil
- aster: median 0.0045s, avg 0.0046s, min 0.0042s (runs 5)
- cpp:   median 0.0037s, avg 0.0037s, min 0.0033s (runs 5)
- rust:  median 0.0043s, avg 0.0042s, min 0.0039s (runs 5)
- perf delta (median): aster/baseline 1.213x

Geometric mean (aster/baseline): 1.192x

Notes:
- Added GEMM and stencil kernels with C++/Rust baselines.
- Aster kernels are hand-written assembly for now (compiler stub copies templates).

## Run 006 — gemm vectorized + stencil vectorized (median, warmup)
Command: `tools/bench/run.sh` (warmup 1, 6 runs, median over 5)

Benchmark: dot
- aster: median 0.0168s, avg 0.0168s, min 0.0162s (runs 5)
- cpp:   median 0.0175s, avg 0.0174s, min 0.0162s (runs 5)
- rust:  median 0.0185s, avg 0.0185s, min 0.0173s (runs 5)
- perf delta (median): aster/baseline 0.961x

Benchmark: gemm
- aster: median 0.0038s, avg 0.0040s, min 0.0034s (runs 5)
- cpp:   median 0.0033s, avg 0.0046s, min 0.0029s (runs 5)
- rust:  median 0.0032s, avg 0.0033s, min 0.0030s (runs 5)
- perf delta (median): aster/baseline 1.187x

Benchmark: stencil
- aster: median 0.0038s, avg 0.0038s, min 0.0036s (runs 5)
- cpp:   median 0.0036s, avg 0.0036s, min 0.0029s (runs 5)
- rust:  median 0.0032s, avg 0.0035s, min 0.0031s (runs 5)
- perf delta (median): aster/baseline 1.184x

Geometric mean (aster/baseline): 1.105x

Notes:
- GEMM inner loop now vectorized on j (2 doubles per iter).
- Stencil inner loop vectorized (2 doubles per iter) with row-pointer arithmetic.

## Run 007 — gemm unroll + stencil vector + fswalk (median, warmup)
Command: `FS_BENCH_ROOT=/Users/stephenwalker FS_BENCH_MAX_DEPTH=5 tools/bench/run.sh`

Benchmark: dot
- aster: median 0.0169s, avg 0.0174s, min 0.0162s (runs 5)
- cpp:   median 0.0164s, avg 0.0171s, min 0.0162s (runs 5)
- rust:  median 0.0167s, avg 0.0167s, min 0.0162s (runs 5)
- perf delta (median): aster/baseline 1.032x

Benchmark: gemm
- aster: median 0.0032s, avg 0.0032s, min 0.0030s (runs 5)
- cpp:   median 0.0035s, avg 0.0033s, min 0.0027s (runs 5)
- rust:  median 0.0033s, avg 0.0034s, min 0.0031s (runs 5)
- perf delta (median): aster/baseline 0.976x

Benchmark: stencil
- aster: median 0.0035s, avg 0.0037s, min 0.0033s (runs 5)
- cpp:   median 0.0032s, avg 0.0033s, min 0.0027s (runs 5)
- rust:  median 0.0033s, avg 0.0034s, min 0.0030s (runs 5)
- perf delta (median): aster/baseline 1.094x

Benchmark: fswalk (FS_BENCH_ROOT=/Users/stephenwalker, FS_BENCH_MAX_DEPTH=5)
- aster: median 15.0815s, avg 15.0815s, min 15.0060s (runs 2)
- cpp:   median 3.0765s, avg 3.0765s, min 0.6557s (runs 2)
- rust:  median 22.2365s, avg 22.2365s, min 22.0266s (runs 2)
- perf delta (median): aster/baseline 4.902x

Geometric mean (aster/baseline): 1.524x

Notes:
- fswalk uses a C helper via fts(3) for Aster; C++ uses std::filesystem; Rust uses manual read_dir.
- fswalk runs use fewer iterations (2) to limit traversal time.

## Run 008 — Aster0 compiled from .as (dot/gemm/stencil)
Command: `tools/bench/run.sh`

Benchmark: dot
- aster: median 0.0177s, avg 0.0254s, min 0.0173s (runs 5)
- cpp:   median 0.0187s, avg 0.0193s, min 0.0184s (runs 5)
- rust:  median 0.0174s, avg 0.0176s, min 0.0170s (runs 5)
- perf delta (median): aster/baseline 1.018x

Benchmark: gemm
- aster: median 0.0032s, avg 0.0034s, min 0.0028s (runs 5)
- cpp:   median 0.0031s, avg 0.0031s, min 0.0026s (runs 5)
- rust:  median 0.0039s, avg 0.0039s, min 0.0033s (runs 5)
- perf delta (median): aster/baseline 1.019x

Benchmark: stencil
- aster: median 0.0036s, avg 0.0037s, min 0.0035s (runs 5)
- cpp:   median 0.0036s, avg 0.0036s, min 0.0033s (runs 5)
- rust:  median 0.0033s, avg 0.0036s, min 0.0030s (runs 5)
- perf delta (median): aster/baseline 1.077x

Geometric mean (aster/baseline): 1.038x

Notes:
- Benchmarks now compile Aster .as sources via the Aster0 stub compiler.

## Run 009 — fswalk list mode (replay) + Aster0 compiled
Command: `FS_BENCH_ROOT=/Users/stephenwalker/.codex/worktrees/046e/aster FS_BENCH_LIST=/tmp/fswalk.list tools/bench/run.sh`

Benchmark: dot
- aster: median 0.0181s, avg 0.0181s, min 0.0168s (runs 5)
- cpp:   median 0.0181s, avg 0.0181s, min 0.0170s (runs 5)
- rust:  median 0.0183s, avg 0.0182s, min 0.0172s (runs 5)
- perf delta (median): aster/baseline 0.995x

Benchmark: gemm
- aster: median 0.0033s, avg 0.0033s, min 0.0030s (runs 5)
- cpp:   median 0.0029s, avg 0.0029s, min 0.0026s (runs 5)
- rust:  median 0.0035s, avg 0.0035s, min 0.0032s (runs 5)
- perf delta (median): aster/baseline 1.140x

Benchmark: stencil
- aster: median 0.0038s, avg 0.0041s, min 0.0036s (runs 5)
- cpp:   median 0.0030s, avg 0.0031s, min 0.0027s (runs 5)
- rust:  median 0.0034s, avg 0.0036s, min 0.0032s (runs 5)
- perf delta (median): aster/baseline 1.247x

Benchmark: fswalk (list replay: /tmp/fswalk.list)
- aster: median 0.1209s, avg 0.1209s, min 0.0028s (runs 2)
- cpp:   median 0.0620s, avg 0.0620s, min 0.0031s (runs 2)
- rust:  median 0.1224s, avg 0.1224s, min 0.0030s (runs 2)
- perf delta (median): aster/baseline 1.949x

Geometric mean (aster/baseline): 1.289x

Notes:
- fswalk list replay isolates stat overhead; traversal is pre-generated by `tools/bench/fswalk_list.sh`.

## Run 010 — fswalk compiled from Aster (list mode, no helpers)
Command: `FS_BENCH_ROOT=/Users/stephenwalker/.codex/worktrees/046e/aster tools/bench/run.sh`

Benchmark: dot
- aster: median 0.0201s, avg 0.0201s, min 0.0183s (runs 5)
- cpp:   median 0.0166s, avg 0.0167s, min 0.0164s (runs 5)
- rust:  median 0.0172s, avg 0.0173s, min 0.0166s (runs 5)
- perf delta (median): aster/baseline 1.211x

Benchmark: gemm
- aster: median 0.0032s, avg 0.0032s, min 0.0029s (runs 5)
- cpp:   median 0.0033s, avg 0.0033s, min 0.0028s (runs 5)
- rust:  median 0.0034s, avg 0.0033s, min 0.0028s (runs 5)
- perf delta (median): aster/baseline 0.956x

Benchmark: stencil
- aster: median 0.0046s, avg 0.0045s, min 0.0040s (runs 5)
- cpp:   median 0.0034s, avg 0.0036s, min 0.0032s (runs 5)
- rust:  median 0.0040s, avg 0.0039s, min 0.0034s (runs 5)
- perf delta (median): aster/baseline 1.350x

Benchmark: fswalk (list replay: tools/bench/out/fswalk_list.txt)
- aster: median 0.1175s, avg 0.1175s, min 0.0030s (runs 2)
- cpp:   median 0.0609s, avg 0.0609s, min 0.0061s (runs 2)
- rust:  median 0.1992s, avg 0.1992s, min 0.0169s (runs 2)
- perf delta (median): aster/baseline 1.931x

Geometric mean (aster/baseline): 1.318x

Notes:
- Aster fswalk is now compiled from Aster source (no custom C/ASM helper).
- List replay file is generated automatically by the bench harness when FS_BENCH_ROOT is set.

## Run 011 — fswalk Aster list mode (fgets buffer)
Command: `FS_BENCH_ROOT=/Users/stephenwalker/.codex/worktrees/046e/aster tools/bench/run.sh`

Benchmark: dot
- aster: median 0.0174s, avg 0.0181s, min 0.0168s (runs 5)
- cpp:   median 0.0175s, avg 0.0172s, min 0.0161s (runs 5)
- rust:  median 0.0166s, avg 0.0176s, min 0.0156s (runs 5)
- perf delta (median): aster/baseline 1.052x

Benchmark: gemm
- aster: median 0.0033s, avg 0.0033s, min 0.0030s (runs 5)
- cpp:   median 0.0027s, avg 0.0028s, min 0.0026s (runs 5)
- rust:  median 0.0033s, avg 0.0033s, min 0.0030s (runs 5)
- perf delta (median): aster/baseline 1.187x

Benchmark: stencil
- aster: median 0.0033s, avg 0.0036s, min 0.0032s (runs 5)
- cpp:   median 0.0032s, avg 0.0032s, min 0.0028s (runs 5)
- rust:  median 0.0040s, avg 0.0041s, min 0.0033s (runs 5)
- perf delta (median): aster/baseline 1.051x

Benchmark: fswalk (list replay: tools/bench/out/fswalk_list.txt)
- aster: median 0.1780s, avg 0.1780s, min 0.0031s (runs 2)
- cpp:   median 0.0963s, avg 0.0963s, min 0.0025s (runs 2)
- rust:  median 0.0644s, avg 0.0644s, min 0.0035s (runs 2)
- perf delta (median): aster/baseline 2.763x

Geometric mean (aster/baseline): 1.380x

Notes:
- fswalk uses fgets + fixed buffer + stat/lstat selection; variance appears high on small list sizes.

## Run 012 — fswalk list scan (buffered read, 5 runs)
Command: `FS_BENCH_ROOT=/Users/stephenwalker/.codex/worktrees/046e/aster FS_BENCH_MAX_DEPTH=10 FS_BENCH_FSWALK_RUNS=5 FS_BENCH_FSWALK_WARMUP=1 tools/bench/run.sh`

Benchmark: dot
- aster: median 0.0192s, avg 0.0206s, min 0.0165s (runs 5)
- cpp:   median 0.0182s, avg 0.0193s, min 0.0163s (runs 5)
- rust:  median 0.0182s, avg 0.0183s, min 0.0172s (runs 5)
- perf delta (median): aster/baseline 1.056x

Benchmark: gemm
- aster: median 0.0036s, avg 0.0037s, min 0.0032s (runs 5)
- cpp:   median 0.0034s, avg 0.0035s, min 0.0033s (runs 5)
- rust:  median 0.0039s, avg 0.0038s, min 0.0029s (runs 5)
- perf delta (median): aster/baseline 1.058x

Benchmark: stencil
- aster: median 0.0042s, avg 0.0042s, min 0.0040s (runs 5)
- cpp:   median 0.0036s, avg 0.0037s, min 0.0034s (runs 5)
- rust:  median 0.0035s, avg 0.0040s, min 0.0034s (runs 5)
- perf delta (median): aster/baseline 1.184x

Benchmark: fswalk (list replay: tools/bench/out/fswalk_list.txt)
- aster: median 0.0027s, avg 0.0027s, min 0.0023s (runs 4)
- cpp:   median 0.0031s, avg 0.0031s, min 0.0029s (runs 4)
- rust:  median 0.0029s, avg 0.0033s, min 0.0026s (runs 4)
- perf delta (median): aster/baseline 0.933x

Geometric mean (aster/baseline): 1.054x

Notes:
- List file size remained small (133 paths); consider a larger root for more stable fswalk signals.

## Run 013 — fixed dataset list (500k paths) + variance stats
Command: `FS_BENCH_ROOT=/Users/stephenwalker FS_BENCH_LIST_FIXED=1 FS_BENCH_FSWALK_RUNS=6 FS_BENCH_FSWALK_WARMUP=1 tools/bench/run.sh`

Benchmark: dot
- aster: median 0.0568s, avg 0.0575s, min 0.0417s, stdev 0.0112s (runs 5)
- cpp:   median 0.0336s, avg 0.0425s, min 0.0251s, stdev 0.0194s (runs 5)
- rust:  median 0.0255s, avg 0.0242s, min 0.0206s, stdev 0.0026s (runs 5)
- perf delta (median): aster/baseline 2.228x

Benchmark: gemm
- aster: median 0.0080s, avg 0.0081s, min 0.0064s, stdev 0.0017s (runs 5)
- cpp:   median 0.0176s, avg 0.0177s, min 0.0071s, stdev 0.0116s (runs 5)
- rust:  median 0.0151s, avg 0.0140s, min 0.0053s, stdev 0.0072s (runs 5)
- perf delta (median): aster/baseline 0.527x

Benchmark: stencil
- aster: median 0.0058s, avg 0.0055s, min 0.0042s, stdev 0.0009s (runs 5)
- cpp:   median 0.0085s, avg 0.0107s, min 0.0065s, stdev 0.0047s (runs 5)
- rust:  median 0.0084s, avg 0.0083s, min 0.0068s, stdev 0.0016s (runs 5)
- perf delta (median): aster/baseline 0.690x

Benchmark: fswalk (fixed list: tools/bench/data/fswalk_list.txt)
- aster: median 22.2646s, avg 25.5260s, min 21.1895s, stdev 8.2187s (runs 5)
- cpp:   median 20.6899s, avg 22.4724s, min 20.3314s, stdev 4.2086s (runs 5)
- rust:  median 26.3230s, avg 27.0593s, min 21.6783s, stdev 4.0947s (runs 5)
- perf delta (median): aster/baseline 1.076x

Geometric mean (aster/baseline): 0.966x

Notes:
- Fixed list includes ~509k paths (depth 5) with some permission-skipped entries.
- Large fswalk runs may impact cache state; consider running kernel benches separately.

## Run 014 — kernels only (Aster main compiled from Aster0)
Command: `BENCH_SET=kernels tools/bench/run.sh`

Benchmark: dot
- aster: median 0.0180s, avg 0.0182s, min 0.0161s, stdev 0.0018s (runs 5)
- cpp:   median 0.0163s, avg 0.0168s, min 0.0157s, stdev 0.0013s (runs 5)
- rust:  median 0.0178s, avg 0.0176s, min 0.0160s, stdev 0.0009s (runs 5)
- perf delta (median): aster/baseline 1.104x

Benchmark: gemm
- aster: median 0.0028s, avg 0.0034s, min 0.0024s, stdev 0.0013s (runs 5)
- cpp:   median 0.0037s, avg 0.0039s, min 0.0034s, stdev 0.0005s (runs 5)
- rust:  median 0.0037s, avg 0.0037s, min 0.0033s, stdev 0.0003s (runs 5)
- perf delta (median): aster/baseline 0.764x

Benchmark: stencil
- aster: median 0.0042s, avg 0.0044s, min 0.0036s, stdev 0.0009s (runs 5)
- cpp:   median 0.0033s, avg 0.0033s, min 0.0030s, stdev 0.0003s (runs 5)
- rust:  median 0.0044s, avg 0.0041s, min 0.0035s, stdev 0.0006s (runs 5)
- perf delta (median): aster/baseline 1.294x

Geometric mean (aster/baseline): 1.030x

Notes:
- Kernels run without fswalk to reduce cache effects.

## Run 015 — fswalk only (fixed list, 6 runs)
Command: `BENCH_SET=fswalk FS_BENCH_ROOT=/Users/stephenwalker FS_BENCH_LIST_FIXED=1 FS_BENCH_FSWALK_RUNS=6 FS_BENCH_FSWALK_WARMUP=1 tools/bench/run.sh`

Benchmark: fswalk (fixed list: tools/bench/data/fswalk_list.txt)
- aster: median 20.3798s, avg 20.5668s, min 20.3343s, stdev 0.3191s (runs 5)
- cpp:   median 20.6016s, avg 20.5832s, min 20.4832s, stdev 0.0832s (runs 5)
- rust:  median 20.5493s, avg 21.7224s, min 20.4178s, stdev 2.3993s (runs 5)
- perf delta (median): aster/baseline 0.992x

Geometric mean (aster/baseline): 0.992x

Notes:
- Fswalk run isolated from kernel benchmarks to reduce cache interference.

## Run 016 — kernels only + sort (Aster main from Aster0)
Command: `BENCH_SET=kernels tools/bench/run.sh`

Benchmark: dot
- aster: median 0.0171s, avg 0.0174s, min 0.0156s, stdev 0.0013s (runs 5)
- cpp:   median 0.0159s, avg 0.0162s, min 0.0152s, stdev 0.0009s (runs 5)
- rust:  median 0.0175s, avg 0.0173s, min 0.0160s, stdev 0.0009s (runs 5)
- perf delta (median): aster/baseline 1.072x

Benchmark: gemm
- aster: median 0.0029s, avg 0.0029s, min 0.0026s, stdev 0.0002s (runs 5)
- cpp:   median 0.0029s, avg 0.0029s, min 0.0026s, stdev 0.0003s (runs 5)
- rust:  median 0.0032s, avg 0.0032s, min 0.0032s, stdev 0.0000s (runs 5)
- perf delta (median): aster/baseline 0.992x

Benchmark: stencil
- aster: median 0.0029s, avg 0.0029s, min 0.0025s, stdev 0.0003s (runs 5)
- cpp:   median 0.0031s, avg 0.0032s, min 0.0030s, stdev 0.0002s (runs 5)
- rust:  median 0.0034s, avg 0.0035s, min 0.0029s, stdev 0.0004s (runs 5)
- perf delta (median): aster/baseline 0.948x

Benchmark: sort
- aster: median 0.0142s, avg 0.0151s, min 0.0132s, stdev 0.0024s (runs 5)
- cpp:   median 0.0134s, avg 0.0133s, min 0.0126s, stdev 0.0006s (runs 5)
- rust:  median 0.0069s, avg 0.0074s, min 0.0061s, stdev 0.0013s (runs 5)
- perf delta (median): aster/baseline 2.041x

Geometric mean (aster/baseline): 1.197x

Notes:
- Sort benchmark uses iterative quicksort in Aster and std::sort / sort_unstable for baselines.

## Run 017 — fswalk only (fixed list, 6 runs)
Command: `BENCH_SET=fswalk FS_BENCH_ROOT=/Users/stephenwalker FS_BENCH_LIST_FIXED=1 FS_BENCH_FSWALK_RUNS=6 FS_BENCH_FSWALK_WARMUP=1 tools/bench/run.sh`

Benchmark: fswalk (fixed list: tools/bench/data/fswalk_list.txt)
- aster: median 19.8405s, avg 19.9205s, min 19.7155s, stdev 0.2755s (runs 5)
- cpp:   median 19.7914s, avg 20.0708s, min 19.6381s, stdev 0.7614s (runs 5)
- rust:  median 20.3914s, avg 20.4441s, min 20.0178s, stdev 0.4021s (runs 5)
- perf delta (median): aster/baseline 1.002x

Geometric mean (aster/baseline): 1.002x

Notes:
- Fswalk run isolated from kernel benchmarks to reduce cache interference.

## Run 018 — kernels expanded (json/hashmap/regex/async) + ASM backend for core kernels
Command: `BENCH_SET=kernels tools/bench/run.sh`

Benchmark: dot
- aster: median 0.0168s, avg 0.0169s, min 0.0159s, stdev 0.0007s (runs 5)
- cpp:   median 0.0182s, avg 0.0182s, min 0.0170s, stdev 0.0009s (runs 5)
- rust:  median 0.0172s, avg 0.0170s, min 0.0157s, stdev 0.0008s (runs 5)
- perf delta (median): aster/baseline 0.974x

Benchmark: gemm
- aster: median 0.0031s, avg 0.0032s, min 0.0030s, stdev 0.0003s (runs 5)
- cpp:   median 0.0028s, avg 0.0029s, min 0.0027s, stdev 0.0003s (runs 5)
- rust:  median 0.0033s, avg 0.0033s, min 0.0031s, stdev 0.0002s (runs 5)
- perf delta (median): aster/baseline 1.087x

Benchmark: stencil
- aster: median 0.0037s, avg 0.0036s, min 0.0034s, stdev 0.0002s (runs 5)
- cpp:   median 0.0030s, avg 0.0030s, min 0.0028s, stdev 0.0001s (runs 5)
- rust:  median 0.0033s, avg 0.0033s, min 0.0031s, stdev 0.0002s (runs 5)
- perf delta (median): aster/baseline 1.254x

Benchmark: sort
- aster: median 0.0182s, avg 0.0181s, min 0.0175s, stdev 0.0005s (runs 5)
- cpp:   median 0.0125s, avg 0.0124s, min 0.0118s, stdev 0.0004s (runs 5)
- rust:  median 0.0060s, avg 0.0060s, min 0.0055s, stdev 0.0006s (runs 5)
- perf delta (median): aster/baseline 3.014x

Benchmark: json
- aster: median 0.0033s, avg 0.0035s, min 0.0029s, stdev 0.0006s (runs 5)
- cpp:   median 0.0032s, avg 0.0033s, min 0.0029s, stdev 0.0004s (runs 5)
- rust:  median 0.0030s, avg 0.0031s, min 0.0028s, stdev 0.0002s (runs 5)
- perf delta (median): aster/baseline 1.103x

Benchmark: hashmap
- aster: median 0.0069s, avg 0.0066s, min 0.0060s, stdev 0.0005s (runs 5)
- cpp:   median 0.0068s, avg 0.0066s, min 0.0060s, stdev 0.0004s (runs 5)
- rust:  median 0.0062s, avg 0.0064s, min 0.0059s, stdev 0.0004s (runs 5)
- perf delta (median): aster/baseline 1.118x

Benchmark: regex
- aster: median 0.0042s, avg 0.0042s, min 0.0039s, stdev 0.0002s (runs 5)
- cpp:   median 0.0041s, avg 0.0043s, min 0.0038s, stdev 0.0005s (runs 5)
- rust:  median 0.0044s, avg 0.0044s, min 0.0042s, stdev 0.0002s (runs 5)
- perf delta (median): aster/baseline 1.032x

Benchmark: async_io
- aster: median 0.0051s, avg 0.0051s, min 0.0048s, stdev 0.0002s (runs 5)
- cpp:   median 0.0055s, avg 0.0053s, min 0.0049s, stdev 0.0003s (runs 5)
- rust:  median 0.0052s, avg 0.0051s, min 0.0048s, stdev 0.0003s (runs 5)
- perf delta (median): aster/baseline 0.972x

Geometric mean (aster/baseline): 1.221x

Notes:
- Kernels use ASTER_BACKEND=asm for dot/gemm/stencil/sort; new benches use C-emit backend.
- Sort remains the largest drag vs baselines.

## Run 019 — kernels expanded, radix sort (Aster0 C-emit for sort)
Command: `BENCH_SET=kernels tools/bench/run.sh`

Benchmark: dot
- aster: median 0.0168s, avg 0.0169s, min 0.0165s, stdev 0.0003s (runs 5)
- cpp:   median 0.0167s, avg 0.0164s, min 0.0154s, stdev 0.0006s (runs 5)
- rust:  median 0.0176s, avg 0.0172s, min 0.0160s, stdev 0.0008s (runs 5)
- perf delta (median): aster/baseline 1.011x

Benchmark: gemm
- aster: median 0.0030s, avg 0.0030s, min 0.0028s, stdev 0.0002s (runs 5)
- cpp:   median 0.0033s, avg 0.0033s, min 0.0028s, stdev 0.0004s (runs 5)
- rust:  median 0.0037s, avg 0.0037s, min 0.0033s, stdev 0.0004s (runs 5)
- perf delta (median): aster/baseline 0.896x

Benchmark: stencil
- aster: median 0.0038s, avg 0.0038s, min 0.0036s, stdev 0.0003s (runs 5)
- cpp:   median 0.0041s, avg 0.0041s, min 0.0035s, stdev 0.0005s (runs 5)
- rust:  median 0.0038s, avg 0.0039s, min 0.0035s, stdev 0.0003s (runs 5)
- perf delta (median): aster/baseline 0.993x

Benchmark: sort
- aster: median 0.0047s, avg 0.0047s, min 0.0044s, stdev 0.0003s (runs 5)
- cpp:   median 0.0133s, avg 0.0140s, min 0.0127s, stdev 0.0016s (runs 5)
- rust:  median 0.0063s, avg 0.0062s, min 0.0056s, stdev 0.0005s (runs 5)
- perf delta (median): aster/baseline 0.739x

Benchmark: json
- aster: median 0.0033s, avg 0.0032s, min 0.0031s, stdev 0.0001s (runs 5)
- cpp:   median 0.0032s, avg 0.0033s, min 0.0030s, stdev 0.0003s (runs 5)
- rust:  median 0.0035s, avg 0.0035s, min 0.0032s, stdev 0.0002s (runs 5)
- perf delta (median): aster/baseline 1.019x

Benchmark: hashmap
- aster: median 0.0069s, avg 0.0069s, min 0.0063s, stdev 0.0005s (runs 5)
- cpp:   median 0.0061s, avg 0.0060s, min 0.0056s, stdev 0.0003s (runs 5)
- rust:  median 0.0068s, avg 0.0065s, min 0.0057s, stdev 0.0007s (runs 5)
- perf delta (median): aster/baseline 1.134x

Benchmark: regex
- aster: median 0.0040s, avg 0.0039s, min 0.0036s, stdev 0.0002s (runs 5)
- cpp:   median 0.0041s, avg 0.0041s, min 0.0037s, stdev 0.0003s (runs 5)
- rust:  median 0.0043s, avg 0.0044s, min 0.0041s, stdev 0.0004s (runs 5)
- perf delta (median): aster/baseline 0.967x

Benchmark: async_io
- aster: median 0.0055s, avg 0.0057s, min 0.0054s, stdev 0.0004s (runs 5)
- cpp:   median 0.0056s, avg 0.0055s, min 0.0050s, stdev 0.0003s (runs 5)
- rust:  median 0.0062s, avg 0.0063s, min 0.0057s, stdev 0.0006s (runs 5)
- perf delta (median): aster/baseline 0.995x

Geometric mean (aster/baseline): 0.963x

Notes:
- Sort switched to radix sort; Aster now beats both baselines on sort.
- Core kernels use asm backend for dot/gemm/stencil; others use C-emit backend.

## Run 020 — kernels (Aster-only backend, no asm templates)
Command: `BENCH_SET=kernels tools/bench/run.sh`

Benchmark: dot
- aster: median 0.0336s, avg 0.0334s, min 0.0292s, stdev 0.0031s (runs 5)
- cpp:   median 0.0413s, avg 0.0460s, min 0.0299s, stdev 0.0180s (runs 5)
- rust:  median 0.0313s, avg 0.0330s, min 0.0293s, stdev 0.0039s (runs 5)
- perf delta (median): aster/baseline 1.076x

Benchmark: gemm
- aster: median 0.0071s, avg 0.0076s, min 0.0063s, stdev 0.0015s (runs 5)
- cpp:   median 0.0083s, avg 0.0083s, min 0.0061s, stdev 0.0019s (runs 5)
- rust:  median 0.0095s, avg 0.0088s, min 0.0074s, stdev 0.0012s (runs 5)
- perf delta (median): aster/baseline 0.854x

Benchmark: stencil
- aster: median 0.0097s, avg 0.0090s, min 0.0069s, stdev 0.0015s (runs 5)
- cpp:   median 0.0046s, avg 0.0045s, min 0.0039s, stdev 0.0005s (runs 5)
- rust:  median 0.0054s, avg 0.0055s, min 0.0043s, stdev 0.0011s (runs 5)
- perf delta (median): aster/baseline 2.106x

Benchmark: sort
- aster: median 0.0071s, avg 0.0069s, min 0.0063s, stdev 0.0005s (runs 5)
- cpp:   median 0.0152s, avg 0.0152s, min 0.0148s, stdev 0.0003s (runs 5)
- rust:  median 0.0089s, avg 0.0081s, min 0.0065s, stdev 0.0012s (runs 5)
- perf delta (median): aster/baseline 0.794x

Benchmark: json
- aster: median 0.0049s, avg 0.0047s, min 0.0036s, stdev 0.0007s (runs 5)
- cpp:   median 0.0054s, avg 0.0055s, min 0.0044s, stdev 0.0010s (runs 5)
- rust:  median 0.0037s, avg 0.0037s, min 0.0032s, stdev 0.0005s (runs 5)
- perf delta (median): aster/baseline 1.317x

Benchmark: hashmap
- aster: median 0.0096s, avg 0.0098s, min 0.0090s, stdev 0.0007s (runs 5)
- cpp:   median 0.0106s, avg 0.0103s, min 0.0094s, stdev 0.0008s (runs 5)
- rust:  median 0.0124s, avg 0.0128s, min 0.0113s, stdev 0.0012s (runs 5)
- perf delta (median): aster/baseline 0.910x

Benchmark: regex
- aster: median 0.0087s, avg 0.0104s, min 0.0059s, stdev 0.0045s (runs 5)
- cpp:   median 0.0061s, avg 0.0063s, min 0.0059s, stdev 0.0005s (runs 5)
- rust:  median 0.0067s, avg 0.0071s, min 0.0057s, stdev 0.0015s (runs 5)
- perf delta (median): aster/baseline 1.423x

Benchmark: async_io
- aster: median 0.0078s, avg 0.0081s, min 0.0073s, stdev 0.0007s (runs 5)
- cpp:   median 0.0073s, avg 0.0073s, min 0.0067s, stdev 0.0006s (runs 5)
- rust:  median 0.0075s, avg 0.0088s, min 0.0072s, stdev 0.0020s (runs 5)
- perf delta (median): aster/baseline 1.060x

Geometric mean (aster/baseline): 1.136x

Notes:
- All kernel benches compiled from Aster source via the C-emit backend (no asm templates).

## Run 021 — fswalk list mode + treewalk live (fts)
Command: `FS_BENCH_ROOT=/Users/stephenwalker FS_BENCH_MAX_DEPTH=5 FS_BENCH_LIST_FIXED=1 BENCH_SET=fswalk tools/bench/run.sh`

Benchmark: fswalk
- aster: median 21.3170s, avg 21.3170s, min 20.5926s, stdev 1.0245s (runs 2)
- cpp:   median 23.6803s, avg 23.6803s, min 23.6413s, stdev 0.0552s (runs 2)
- rust:  median 22.3545s, avg 22.3545s, min 20.2235s, stdev 3.0136s (runs 2)
- perf delta (median): aster/baseline 0.954x

Benchmark: treewalk
- aster: median 14.2898s, avg 14.2898s, min 11.3370s, stdev 4.1760s (runs 2)
- cpp:   median 13.2077s, avg 13.2077s, min 12.8786s, stdev 0.4654s (runs 2)
- rust:  median 17.8053s, avg 17.8053s, min 13.2956s, stdev 6.3776s (runs 2)
- perf delta (median): aster/baseline 1.082x

Geometric mean (aster/baseline): 1.016x

Notes:
- fswalk runs in list/replay mode (fixed dataset from tools/bench/data/fswalk_list.txt).
- treewalk runs live traversal using fts in Aster and C++ (`FS_BENCH_CPP_MODE=fts`), Rust uses manual stack.

## Run 022 — kernels (C-emit hints + blocked stencil + FSM regex + pointer JSON)
Command: `BENCH_SET=kernels tools/bench/run.sh`

Benchmark: dot
- aster: median 0.0141s, avg 0.0154s, min 0.0136s, stdev 0.0021s (runs 5)
- cpp:   median 0.0161s, avg 0.0188s, min 0.0151s, stdev 0.0044s (runs 5)
- rust:  median 0.0162s, avg 0.0161s, min 0.0151s, stdev 0.0007s (runs 5)
- perf delta (median): aster/baseline 0.876x

Benchmark: gemm
- aster: median 0.0025s, avg 0.0026s, min 0.0024s, stdev 0.0002s (runs 5)
- cpp:   median 0.0039s, avg 0.0042s, min 0.0037s, stdev 0.0005s (runs 5)
- rust:  median 0.0042s, avg 0.0042s, min 0.0038s, stdev 0.0003s (runs 5)
- perf delta (median): aster/baseline 0.632x

Benchmark: stencil
- aster: median 0.0031s, avg 0.0032s, min 0.0029s, stdev 0.0003s (runs 5)
- cpp:   median 0.0044s, avg 0.0042s, min 0.0038s, stdev 0.0003s (runs 5)
- rust:  median 0.0034s, avg 0.0038s, min 0.0033s, stdev 0.0007s (runs 5)
- perf delta (median): aster/baseline 0.906x

Benchmark: sort
- aster: median 0.0060s, avg 0.0060s, min 0.0052s, stdev 0.0009s (runs 5)
- cpp:   median 0.0148s, avg 0.0148s, min 0.0131s, stdev 0.0014s (runs 5)
- rust:  median 0.0095s, avg 0.0092s, min 0.0052s, stdev 0.0034s (runs 5)
- perf delta (median): aster/baseline 0.632x

Benchmark: json
- aster: median 0.0028s, avg 0.0029s, min 0.0025s, stdev 0.0003s (runs 5)
- cpp:   median 0.0031s, avg 0.0033s, min 0.0028s, stdev 0.0005s (runs 5)
- rust:  median 0.0032s, avg 0.0033s, min 0.0031s, stdev 0.0001s (runs 5)
- perf delta (median): aster/baseline 0.902x

Benchmark: hashmap
- aster: median 0.0075s, avg 0.0073s, min 0.0065s, stdev 0.0007s (runs 5)
- cpp:   median 0.0078s, avg 0.0077s, min 0.0068s, stdev 0.0005s (runs 5)
- rust:  median 0.0063s, avg 0.0063s, min 0.0061s, stdev 0.0001s (runs 5)
- perf delta (median): aster/baseline 1.188x

Benchmark: regex
- aster: median 0.0063s, avg 0.0066s, min 0.0060s, stdev 0.0007s (runs 5)
- cpp:   median 0.0041s, avg 0.0042s, min 0.0041s, stdev 0.0002s (runs 5)
- rust:  median 0.0049s, avg 0.0052s, min 0.0044s, stdev 0.0009s (runs 5)
- perf delta (median): aster/baseline 1.544x

Benchmark: async_io
- aster: median 0.0059s, avg 0.0060s, min 0.0055s, stdev 0.0006s (runs 5)
- cpp:   median 0.0051s, avg 0.0051s, min 0.0048s, stdev 0.0003s (runs 5)
- rust:  median 0.0062s, avg 0.0061s, min 0.0053s, stdev 0.0007s (runs 5)
- perf delta (median): aster/baseline 1.168x

Geometric mean (aster/baseline): 0.941x

Notes:
- C-emit adds `__restrict__` for slice pointers and `#pragma clang loop vectorize` for while loops.
- Stencil uses tiled loops with hoisted row offsets.
- Regex uses a single-pass FSM instead of nested loops.
- JSON parser uses pointer-based scanning.

## Run 023 — fswalk list mode + treewalk bulk (getattrlistbulk)
Command: `FS_BENCH_ROOT=/Users/stephenwalker FS_BENCH_MAX_DEPTH=5 FS_BENCH_LIST_FIXED=1 BENCH_SET=fswalk tools/bench/run.sh`

Benchmark: fswalk
- aster: median 17.5572s, avg 17.5572s, min 15.0252s, stdev 3.5808s (runs 2)
- cpp:   median 20.7003s, avg 20.7003s, min 20.0193s, stdev 0.9632s (runs 2)
- rust:  median 21.6797s, avg 21.6797s, min 20.9330s, stdev 1.0560s (runs 2)
- perf delta (median): aster/baseline 0.848x

Benchmark: treewalk
- aster: median 18.3936s, avg 18.3936s, min 14.9262s, stdev 4.9036s (runs 2)
- cpp:   median 15.9662s, avg 15.9662s, min 13.3728s, stdev 3.6677s (runs 2)
- rust:  median 20.2379s, avg 20.2379s, min 18.6796s, stdev 2.2039s (runs 2)
- perf delta (median): aster/baseline 1.152x

Geometric mean (aster/baseline): 0.988x

Notes:
- treewalk uses getattrlistbulk in Aster (`FS_BENCH_TREEWALK_MODE=bulk`); C++ uses fts; Rust uses manual stack.
- fswalk remains list/replay mode with fixed dataset.

## Run 024 — kernels (regex pointer scan + hashmap unroll)
Command: `BENCH_SET=kernels tools/bench/run.sh`

Benchmark: dot
- aster: median 0.0136s, avg 0.0135s, min 0.0131s, stdev 0.0003s (runs 5)
- cpp:   median 0.0170s, avg 0.0172s, min 0.0151s, stdev 0.0016s (runs 5)
- rust:  median 0.0173s, avg 0.0177s, min 0.0163s, stdev 0.0015s (runs 5)
- perf delta (median): aster/baseline 0.801x

Benchmark: gemm
- aster: median 0.0029s, avg 0.0030s, min 0.0028s, stdev 0.0004s (runs 5)
- cpp:   median 0.0035s, avg 0.0034s, min 0.0029s, stdev 0.0004s (runs 5)
- rust:  median 0.0036s, avg 0.0036s, min 0.0034s, stdev 0.0002s (runs 5)
- perf delta (median): aster/baseline 0.846x

Benchmark: stencil
- aster: median 0.0030s, avg 0.0030s, min 0.0028s, stdev 0.0002s (runs 5)
- cpp:   median 0.0031s, avg 0.0031s, min 0.0029s, stdev 0.0002s (runs 5)
- rust:  median 0.0034s, avg 0.0035s, min 0.0032s, stdev 0.0004s (runs 5)
- perf delta (median): aster/baseline 0.979x

Benchmark: sort
- aster: median 0.0048s, avg 0.0048s, min 0.0043s, stdev 0.0004s (runs 5)
- cpp:   median 0.0136s, avg 0.0137s, min 0.0127s, stdev 0.0009s (runs 5)
- rust:  median 0.0057s, avg 0.0056s, min 0.0052s, stdev 0.0003s (runs 5)
- perf delta (median): aster/baseline 0.842x

Benchmark: json
- aster: median 0.0035s, avg 0.0035s, min 0.0032s, stdev 0.0003s (runs 5)
- cpp:   median 0.0031s, avg 0.0032s, min 0.0028s, stdev 0.0004s (runs 5)
- rust:  median 0.0033s, avg 0.0034s, min 0.0031s, stdev 0.0003s (runs 5)
- perf delta (median): aster/baseline 1.128x

Benchmark: hashmap
- aster: median 0.0059s, avg 0.0062s, min 0.0057s, stdev 0.0005s (runs 5)
- cpp:   median 0.0066s, avg 0.0066s, min 0.0062s, stdev 0.0002s (runs 5)
- rust:  median 0.0074s, avg 0.0073s, min 0.0065s, stdev 0.0006s (runs 5)
- perf delta (median): aster/baseline 0.895x

Benchmark: regex
- aster: median 0.0043s, avg 0.0044s, min 0.0040s, stdev 0.0004s (runs 5)
- cpp:   median 0.0045s, avg 0.0046s, min 0.0038s, stdev 0.0006s (runs 5)
- rust:  median 0.0057s, avg 0.0055s, min 0.0047s, stdev 0.0007s (runs 5)
- perf delta (median): aster/baseline 0.958x

Benchmark: async_io
- aster: median 0.0051s, avg 0.0052s, min 0.0049s, stdev 0.0003s (runs 5)
- cpp:   median 0.0047s, avg 0.0050s, min 0.0043s, stdev 0.0006s (runs 5)
- rust:  median 0.0054s, avg 0.0054s, min 0.0051s, stdev 0.0002s (runs 5)
- perf delta (median): aster/baseline 1.080x

Geometric mean (aster/baseline): 0.935x

Notes:
- Regex uses pointer scanning with b* skipping; hashmap uses 2-way probe unroll and precomputed mask.

## Run 025 — fswalk list mode + treewalk bulk (file size via ATTR_FILE_DATALENGTH)
Command: `FS_BENCH_ROOT=/Users/stephenwalker FS_BENCH_MAX_DEPTH=5 FS_BENCH_LIST_FIXED=1 BENCH_SET=fswalk tools/bench/run.sh`

Benchmark: fswalk
- aster: median 21.1885s, avg 21.1885s, min 20.1048s, stdev 1.5326s (runs 2)
- cpp:   median 23.4505s, avg 23.4505s, min 21.5252s, stdev 2.7228s (runs 2)
- rust:  median 20.0820s, avg 20.0820s, min 19.9654s, stdev 0.1648s (runs 2)
- perf delta (median): aster/baseline 1.055x

Benchmark: treewalk
- aster: median 11.2452s, avg 11.2452s, min 11.0493s, stdev 0.2770s (runs 2)
- cpp:   median 10.2205s, avg 10.2205s, min 9.2664s, stdev 1.3493s (runs 2)
- rust:  median 18.5132s, avg 18.5132s, min 10.2383s, stdev 11.7026s (runs 2)
- perf delta (median): aster/baseline 1.100x

Geometric mean (aster/baseline): 1.077x

Notes:
- treewalk uses getattrlistbulk with ATTR_FILE_DATALENGTH (no per-file fstatat).
- fswalk remains list/replay mode with fixed dataset.

## Run 026 — kernels (JSON digit unroll + robin hood hashmap)
Command: `BENCH_SET=kernels tools/bench/run.sh`

Benchmark: dot
- aster: median 0.0119s, avg 0.0120s, min 0.0115s, stdev 0.0004s (runs 5)
- cpp:   median 0.0151s, avg 0.0150s, min 0.0143s, stdev 0.0005s (runs 5)
- rust:  median 0.0160s, avg 0.0162s, min 0.0157s, stdev 0.0005s (runs 5)
- perf delta (median): aster/baseline 0.790x

Benchmark: gemm
- aster: median 0.0029s, avg 0.0030s, min 0.0028s, stdev 0.0002s (runs 5)
- cpp:   median 0.0031s, avg 0.0031s, min 0.0029s, stdev 0.0002s (runs 5)
- rust:  median 0.0034s, avg 0.0033s, min 0.0030s, stdev 0.0002s (runs 5)
- perf delta (median): aster/baseline 0.951x

Benchmark: stencil
- aster: median 0.0034s, avg 0.0034s, min 0.0031s, stdev 0.0002s (runs 5)
- cpp:   median 0.0037s, avg 0.0036s, min 0.0030s, stdev 0.0005s (runs 5)
- rust:  median 0.0035s, avg 0.0036s, min 0.0033s, stdev 0.0004s (runs 5)
- perf delta (median): aster/baseline 0.958x

Benchmark: sort
- aster: median 0.0049s, avg 0.0050s, min 0.0047s, stdev 0.0003s (runs 5)
- cpp:   median 0.0126s, avg 0.0131s, min 0.0121s, stdev 0.0011s (runs 5)
- rust:  median 0.0055s, avg 0.0055s, min 0.0052s, stdev 0.0002s (runs 5)
- perf delta (median): aster/baseline 0.884x

Benchmark: json
- aster: median 0.0033s, avg 0.0032s, min 0.0029s, stdev 0.0002s (runs 5)
- cpp:   median 0.0037s, avg 0.0035s, min 0.0030s, stdev 0.0004s (runs 5)
- rust:  median 0.0035s, avg 0.0037s, min 0.0034s, stdev 0.0005s (runs 5)
- perf delta (median): aster/baseline 0.918x

Benchmark: hashmap
- aster: median 0.0068s, avg 0.0068s, min 0.0062s, stdev 0.0005s (runs 5)
- cpp:   median 0.0060s, avg 0.0061s, min 0.0057s, stdev 0.0003s (runs 5)
- rust:  median 0.0063s, avg 0.0063s, min 0.0057s, stdev 0.0005s (runs 5)
- perf delta (median): aster/baseline 1.133x

Benchmark: regex
- aster: median 0.0041s, avg 0.0041s, min 0.0039s, stdev 0.0002s (runs 5)
- cpp:   median 0.0041s, avg 0.0042s, min 0.0039s, stdev 0.0003s (runs 5)
- rust:  median 0.0043s, avg 0.0043s, min 0.0039s, stdev 0.0003s (runs 5)
- perf delta (median): aster/baseline 0.987x

Benchmark: async_io
- aster: median 0.0048s, avg 0.0048s, min 0.0045s, stdev 0.0002s (runs 5)
- cpp:   median 0.0051s, avg 0.0051s, min 0.0048s, stdev 0.0002s (runs 5)
- rust:  median 0.0049s, avg 0.0050s, min 0.0048s, stdev 0.0002s (runs 5)
- perf delta (median): aster/baseline 0.976x

Geometric mean (aster/baseline): 0.945x

Notes:
- JSON parser unrolls 4 digits per iteration; hashmap switched to robin hood with probe distance tracking.

## Run 027 — fswalk list mode + treewalk bulk (bigger buffer)
Command: `FS_BENCH_ROOT=/Users/stephenwalker FS_BENCH_MAX_DEPTH=5 FS_BENCH_LIST_FIXED=1 BENCH_SET=fswalk tools/bench/run.sh`

Benchmark: fswalk
- aster: median 21.2339s, avg 21.2339s, min 19.5309s, stdev 2.4084s (runs 2)
- cpp:   median 22.3634s, avg 22.3634s, min 20.4699s, stdev 2.6779s (runs 2)
- rust:  median 21.0287s, avg 21.0287s, min 20.7598s, stdev 0.3803s (runs 2)
- perf delta (median): aster/baseline 1.010x

Benchmark: treewalk
- aster: median 11.5275s, avg 11.5275s, min 11.4422s, stdev 0.1207s (runs 2)
- cpp:   median 10.7622s, avg 10.7622s, min 9.8668s, stdev 1.2663s (runs 2)
- rust:  median 17.6334s, avg 17.6334s, min 13.1647s, stdev 6.3197s (runs 2)
- perf delta (median): aster/baseline 1.071x

Geometric mean (aster/baseline): 1.040x

Notes:
- treewalk uses 256KB bulk buffer (override via FS_BENCH_BULK_BUF).

## Run 028 — kernels (JSON 8-byte pre-scan + packed robin hood)
Command: `BENCH_SET=kernels tools/bench/run.sh`

Benchmark: dot
- aster: median 0.0145s, avg 0.0141s, min 0.0131s, stdev 0.0007s (runs 5)
- cpp:   median 0.0171s, avg 0.0170s, min 0.0163s, stdev 0.0007s (runs 5)
- rust:  median 0.0174s, avg 0.0173s, min 0.0167s, stdev 0.0004s (runs 5)
- perf delta (median): aster/baseline 0.848x

Benchmark: gemm
- aster: median 0.0033s, avg 0.0033s, min 0.0032s, stdev 0.0001s (runs 5)
- cpp:   median 0.0032s, avg 0.0032s, min 0.0029s, stdev 0.0002s (runs 5)
- rust:  median 0.0054s, avg 0.0055s, min 0.0038s, stdev 0.0016s (runs 5)
- perf delta (median): aster/baseline 1.030x

Benchmark: stencil
- aster: median 0.0034s, avg 0.0034s, min 0.0032s, stdev 0.0002s (runs 5)
- cpp:   median 0.0036s, avg 0.0037s, min 0.0033s, stdev 0.0005s (runs 5)
- rust:  median 0.0035s, avg 0.0036s, min 0.0032s, stdev 0.0003s (runs 5)
- perf delta (median): aster/baseline 0.996x

Benchmark: sort
- aster: median 0.0051s, avg 0.0052s, min 0.0047s, stdev 0.0004s (runs 5)
- cpp:   median 0.0130s, avg 0.0128s, min 0.0124s, stdev 0.0003s (runs 5)
- rust:  median 0.0055s, avg 0.0055s, min 0.0050s, stdev 0.0004s (runs 5)
- perf delta (median): aster/baseline 0.920x

Benchmark: json
- aster: median 0.0034s, avg 0.0037s, min 0.0031s, stdev 0.0007s (runs 5)
- cpp:   median 0.0032s, avg 0.0033s, min 0.0032s, stdev 0.0002s (runs 5)
- rust:  median 0.0032s, avg 0.0034s, min 0.0031s, stdev 0.0005s (runs 5)
- perf delta (median): aster/baseline 1.054x

Benchmark: hashmap
- aster: median 0.0070s, avg 0.0069s, min 0.0063s, stdev 0.0004s (runs 5)
- cpp:   median 0.0074s, avg 0.0071s, min 0.0059s, stdev 0.0007s (runs 5)
- rust:  median 0.0073s, avg 0.0071s, min 0.0061s, stdev 0.0005s (runs 5)
- perf delta (median): aster/baseline 0.954x

Benchmark: regex
- aster: median 0.0045s, avg 0.0044s, min 0.0042s, stdev 0.0002s (runs 5)
- cpp:   median 0.0044s, avg 0.0045s, min 0.0040s, stdev 0.0004s (runs 5)
- rust:  median 0.0048s, avg 0.0048s, min 0.0043s, stdev 0.0004s (runs 5)
- perf delta (median): aster/baseline 1.009x

Benchmark: async_io
- aster: median 0.0051s, avg 0.0051s, min 0.0049s, stdev 0.0001s (runs 5)
- cpp:   median 0.0051s, avg 0.0052s, min 0.0048s, stdev 0.0003s (runs 5)
- rust:  median 0.0054s, avg 0.0055s, min 0.0053s, stdev 0.0004s (runs 5)
- perf delta (median): aster/baseline 0.993x

Geometric mean (aster/baseline): 0.974x

Notes:
- JSON adds an 8-byte pre-scan for quotes/digits; hashmap packs probe distance into key high bits.

## Run 029 — fswalk list mode + treewalk bulk (1MB buffer default)
Command: `FS_BENCH_ROOT=/Users/stephenwalker FS_BENCH_MAX_DEPTH=5 FS_BENCH_LIST_FIXED=1 BENCH_SET=fswalk tools/bench/run.sh`

Benchmark: fswalk
- aster: median 21.3040s, avg 21.3040s, min 20.7737s, stdev 0.7500s (runs 2)
- cpp:   median 22.1105s, avg 22.1105s, min 20.0014s, stdev 2.9827s (runs 2)
- rust:  median 20.2592s, avg 20.2592s, min 20.1258s, stdev 0.1887s (runs 2)
- perf delta (median): aster/baseline 1.052x

Benchmark: treewalk
- aster: median 11.1410s, avg 11.1410s, min 11.0803s, stdev 0.0858s (runs 2)
- cpp:   median 9.7955s, avg 9.7955s, min 8.9299s, stdev 1.2242s (runs 2)
- rust:  median 15.3169s, avg 15.3169s, min 9.7220s, stdev 7.9124s (runs 2)
- perf delta (median): aster/baseline 1.137x

Geometric mean (aster/baseline): 1.094x

Notes:
- treewalk uses a 1MB getattrlistbulk buffer by default (override via FS_BENCH_BULK_BUF).

## Run 030 — kernels (post-lexer x86_64 register fix)
Command: `BENCH_SET=kernels tools/bench/run.sh`

Benchmark: dot
- aster: median 0.0139s, avg 0.0138s, min 0.0126s, stdev 0.0007s (runs 5)
- cpp:   median 0.0174s, avg 0.0176s, min 0.0170s, stdev 0.0005s (runs 5)
- rust:  median 0.0189s, avg 0.0203s, min 0.0163s, stdev 0.0055s (runs 5)
- perf delta (median): aster/baseline 0.800x

Benchmark: gemm
- aster: median 0.0034s, avg 0.0032s, min 0.0026s, stdev 0.0005s (runs 5)
- cpp:   median 0.0034s, avg 0.0034s, min 0.0030s, stdev 0.0002s (runs 5)
- rust:  median 0.0034s, avg 0.0035s, min 0.0034s, stdev 0.0003s (runs 5)
- perf delta (median): aster/baseline 1.002x

Benchmark: stencil
- aster: median 0.0093s, avg 0.0096s, min 0.0093s, stdev 0.0005s (runs 5)
- cpp:   median 0.0127s, avg 0.0148s, min 0.0079s, stdev 0.0070s (runs 5)
- rust:  median 0.0081s, avg 0.0078s, min 0.0053s, stdev 0.0017s (runs 5)
- perf delta (median): aster/baseline 1.148x

Benchmark: sort
- aster: median 0.0138s, avg 0.0154s, min 0.0109s, stdev 0.0054s (runs 5)
- cpp:   median 0.0243s, avg 0.0261s, min 0.0205s, stdev 0.0055s (runs 5)
- rust:  median 0.0212s, avg 0.0223s, min 0.0154s, stdev 0.0063s (runs 5)
- perf delta (median): aster/baseline 0.649x

Benchmark: json
- aster: median 0.0102s, avg 0.0098s, min 0.0060s, stdev 0.0027s (runs 5)
- cpp:   median 0.0102s, avg 0.0120s, min 0.0067s, stdev 0.0055s (runs 5)
- rust:  median 0.0136s, avg 0.0138s, min 0.0132s, stdev 0.0007s (runs 5)
- perf delta (median): aster/baseline 1.008x

Benchmark: hashmap
- aster: median 0.0272s, avg 0.0247s, min 0.0161s, stdev 0.0070s (runs 5)
- cpp:   median 0.0248s, avg 0.0288s, min 0.0182s, stdev 0.0092s (runs 5)
- rust:  median 0.0537s, avg 0.3565s, min 0.0303s, stdev 0.4623s (runs 5)
- perf delta (median): aster/baseline 1.096x

Benchmark: regex
- aster: median 0.0099s, avg 0.0105s, min 0.0066s, stdev 0.0035s (runs 5)
- cpp:   median 0.0101s, avg 0.0113s, min 0.0080s, stdev 0.0029s (runs 5)
- rust:  median 0.0132s, avg 0.0123s, min 0.0082s, stdev 0.0027s (runs 5)
- perf delta (median): aster/baseline 0.973x

Benchmark: async_io
- aster: median 0.0190s, avg 0.0178s, min 0.0145s, stdev 0.0025s (runs 5)
- cpp:   median 0.0121s, avg 0.0129s, min 0.0090s, stdev 0.0034s (runs 5)
- rust:  median 0.0106s, avg 0.0111s, min 0.0103s, stdev 0.0008s (runs 5)
- perf delta (median): aster/baseline 1.792x

Geometric mean (aster/baseline): 1.018x

Notes:
- Kernel run captured after x86_64 lexer register fix; no kernel code changes.

## Run 031 — fswalk list mode + treewalk bulk + dircount (count-only)
Command: `FS_BENCH_ROOT=/Users/stephenwalker FS_BENCH_MAX_DEPTH=5 FS_BENCH_LIST_FIXED=1 BENCH_SET=fswalk tools/bench/run.sh`

Benchmark: fswalk
- aster: median 21.7065s, avg 21.7065s, min 19.4107s, stdev 3.2468s (runs 2)
- cpp:   median 22.4715s, avg 22.4715s, min 19.9126s, stdev 3.6188s (runs 2)
- rust:  median 20.1622s, avg 20.1622s, min 20.0128s, stdev 0.2114s (runs 2)
- perf delta (median): aster/baseline 1.077x

Benchmark: treewalk
- aster: median 11.5141s, avg 11.5141s, min 11.4405s, stdev 0.1041s (runs 2)
- cpp:   median 9.5520s, avg 9.5520s, min 8.6677s, stdev 1.2506s (runs 2)
- rust:  median 17.9049s, avg 17.9049s, min 11.7194s, stdev 8.7476s (runs 2)
- perf delta (median): aster/baseline 1.205x

Benchmark: dircount
- aster: median 13.7153s, avg 13.7153s, min 13.3595s, stdev 0.5031s (runs 2)
- cpp:   median 13.0530s, avg 13.0530s, min 10.9520s, stdev 2.9712s (runs 2)
- rust:  median 20.3114s, avg 20.3114s, min 18.9493s, stdev 1.9263s (runs 2)
- perf delta (median): aster/baseline 1.051x

Geometric mean (aster/baseline): 1.109x

Notes:
- dircount uses live traversal with FS_BENCH_COUNT_ONLY=1 and treewalk bulk mode for Aster.

## Run 032 — kernels (Aster0 for-loops + lexer/parser expansion)
Command: `BENCH_SET=kernels tools/bench/run.sh`

Benchmark: dot
- aster: median 0.0139s, avg 0.0141s, min 0.0137s, stdev 0.0005s (runs 5)
- cpp:   median 0.0179s, avg 0.0177s, min 0.0174s, stdev 0.0003s (runs 5)
- rust:  median 0.0170s, avg 0.0173s, min 0.0160s, stdev 0.0014s (runs 5)
- perf delta (median): aster/baseline 0.819x

Benchmark: gemm
- aster: median 0.0034s, avg 0.0036s, min 0.0028s, stdev 0.0008s (runs 5)
- cpp:   median 0.0031s, avg 0.0031s, min 0.0028s, stdev 0.0003s (runs 5)
- rust:  median 0.0081s, avg 0.0072s, min 0.0041s, stdev 0.0025s (runs 5)
- perf delta (median): aster/baseline 1.099x

Benchmark: stencil
- aster: median 0.0033s, avg 0.0033s, min 0.0031s, stdev 0.0002s (runs 5)
- cpp:   median 0.0031s, avg 0.0031s, min 0.0027s, stdev 0.0002s (runs 5)
- rust:  median 0.0039s, avg 0.0039s, min 0.0035s, stdev 0.0004s (runs 5)
- perf delta (median): aster/baseline 1.071x

Benchmark: sort
- aster: median 0.0046s, avg 0.0047s, min 0.0044s, stdev 0.0003s (runs 5)
- cpp:   median 0.0134s, avg 0.0137s, min 0.0128s, stdev 0.0012s (runs 5)
- rust:  median 0.0056s, avg 0.0056s, min 0.0052s, stdev 0.0002s (runs 5)
- perf delta (median): aster/baseline 0.810x

Benchmark: json
- aster: median 0.0037s, avg 0.0038s, min 0.0035s, stdev 0.0002s (runs 5)
- cpp:   median 0.0034s, avg 0.0039s, min 0.0032s, stdev 0.0008s (runs 5)
- rust:  median 0.0037s, avg 0.0038s, min 0.0032s, stdev 0.0004s (runs 5)
- perf delta (median): aster/baseline 1.091x

Benchmark: hashmap
- aster: median 0.0075s, avg 0.0074s, min 0.0065s, stdev 0.0006s (runs 5)
- cpp:   median 0.0077s, avg 0.0076s, min 0.0070s, stdev 0.0005s (runs 5)
- rust:  median 0.0073s, avg 0.0072s, min 0.0070s, stdev 0.0002s (runs 5)
- perf delta (median): aster/baseline 1.029x

Benchmark: regex
- aster: median 0.0052s, avg 0.0056s, min 0.0045s, stdev 0.0016s (runs 5)
- cpp:   median 0.0046s, avg 0.0047s, min 0.0046s, stdev 0.0001s (runs 5)
- rust:  median 0.0049s, avg 0.0054s, min 0.0047s, stdev 0.0010s (runs 5)
- perf delta (median): aster/baseline 1.114x

Benchmark: async_io
- aster: median 0.0050s, avg 0.0050s, min 0.0045s, stdev 0.0004s (runs 5)
- cpp:   median 0.0057s, avg 0.0063s, min 0.0048s, stdev 0.0016s (runs 5)
- rust:  median 0.0056s, avg 0.0054s, min 0.0049s, stdev 0.0004s (runs 5)
- perf delta (median): aster/baseline 0.887x

Geometric mean (aster/baseline): 0.982x

Notes:
- Aster0 now supports range-based `for` loops and type inference for var/let.
- Lexer/parser tests expanded; parser now uses token stream for precedence parsing.

## Run 033 — fswalk list mode + treewalk bulk + dircount (bulk options)
Command: `FS_BENCH_ROOT=/Users/stephenwalker FS_BENCH_MAX_DEPTH=5 FS_BENCH_LIST_FIXED=1 BENCH_SET=fswalk tools/bench/run.sh`

Benchmark: fswalk
- aster: median 20.0712s, avg 20.0712s, min 19.2486s, stdev 1.1632s (runs 2)
- cpp:   median 19.7804s, avg 19.7804s, min 19.5001s, stdev 0.3964s (runs 2)
- rust:  median 19.7908s, avg 19.7908s, min 19.4974s, stdev 0.4150s (runs 2)
- perf delta (median): aster/baseline 1.015x

Benchmark: treewalk
- aster: median 10.9470s, avg 10.9470s, min 10.8792s, stdev 0.0958s (runs 2)
- cpp:   median 9.3711s, avg 9.3711s, min 8.5460s, stdev 1.1669s (runs 2)
- rust:  median 15.1313s, avg 15.1313s, min 9.7846s, stdev 7.5613s (runs 2)
- perf delta (median): aster/baseline 1.168x

Benchmark: dircount
- aster: median 13.1861s, avg 13.1861s, min 12.6861s, stdev 0.7071s (runs 2)
- cpp:   median 11.8551s, avg 11.8551s, min 10.7759s, stdev 1.5263s (runs 2)
- rust:  median 19.0180s, avg 19.0180s, min 15.9859s, stdev 4.2880s (runs 2)
- perf delta (median): aster/baseline 1.112x

Geometric mean (aster/baseline): 1.097x

Notes:
- bulk mode uses FSOPT_PACK_INVAL_ATTRS + FSOPT_NOINMEMUPDATE by default (toggle via FS_BENCH_BULK_PACK/NOINMEM).

## Run 034 — fswalk/treewalk/dircount with C++ bulk (explicit)
Command: `FS_BENCH_CPP_MODE=bulk FS_BENCH_ROOT=/Users/stephenwalker FS_BENCH_MAX_DEPTH=5 FS_BENCH_LIST_FIXED=1 BENCH_SET=fswalk tools/bench/run.sh`

Benchmark: fswalk
- aster: median 27.9810s, avg 27.9810s, min 21.2081s, stdev 9.5782s (runs 2)
- cpp:   median 22.6508s, avg 22.6508s, min 21.7917s, stdev 1.2149s (runs 2)
- rust:  median 22.1760s, avg 22.1760s, min 22.1560s, stdev 0.0283s (runs 2)
- perf delta (median): aster/baseline 1.262x

Benchmark: treewalk
- aster: median 11.3404s, avg 11.3404s, min 11.0900s, stdev 0.3541s (runs 2)
- cpp:   median 11.6707s, avg 11.6707s, min 11.0882s, stdev 0.8239s (runs 2)
- rust:  median 19.1557s, avg 19.1557s, min 16.1785s, stdev 4.2103s (runs 2)
- perf delta (median): aster/baseline 0.972x

Benchmark: dircount
- aster: median 13.2493s, avg 13.2493s, min 12.8001s, stdev 0.6352s (runs 2)
- cpp:   median 24.1736s, avg 24.1736s, min 23.6533s, stdev 0.7358s (runs 2)
- rust:  median 41.7973s, avg 41.7973s, min 36.2028s, stdev 7.9119s (runs 2)
- perf delta (median): aster/baseline 0.548x

Geometric mean (aster/baseline): 0.876x

Notes:
- C++ uses getattrlistbulk path when FS_BENCH_CPP_MODE=bulk.

## Run 035 — fswalk/treewalk/dircount (aligned bulk defaults)
Command: `FS_BENCH_ROOT=/Users/stephenwalker FS_BENCH_MAX_DEPTH=5 FS_BENCH_LIST_FIXED=1 BENCH_SET=fswalk tools/bench/run.sh`

Benchmark: fswalk
- aster: median 17.5985s, avg 17.5985s, min 14.8027s, stdev 3.9538s (runs 2)
- cpp:   median 24.5382s, avg 24.5382s, min 20.4176s, stdev 5.8274s (runs 2)
- rust:  median 20.3532s, avg 20.3532s, min 19.8753s, stdev 0.6758s (runs 2)
- perf delta (median): aster/baseline 0.865x

Benchmark: treewalk
- aster: median 11.7848s, avg 11.7848s, min 11.5863s, stdev 0.2808s (runs 2)
- cpp:   median 11.4807s, avg 11.4807s, min 10.9414s, stdev 0.7627s (runs 2)
- rust:  median 17.7038s, avg 17.7038s, min 14.2920s, stdev 4.8249s (runs 2)
- perf delta (median): aster/baseline 1.026x

Benchmark: dircount
- aster: median 13.0668s, avg 13.0668s, min 12.4012s, stdev 0.9413s (runs 2)
- cpp:   median 12.8992s, avg 12.8992s, min 12.8005s, stdev 0.1395s (runs 2)
- rust:  median 24.9910s, avg 24.9910s, min 21.5431s, stdev 4.8760s (runs 2)
- perf delta (median): aster/baseline 1.013x

Geometric mean (aster/baseline): 0.965x

Notes:
- Harness defaults C++ to bulk when treewalk mode is bulk (apples-to-apples).

## Run 036 — fswalk/treewalk/dircount/fsinventory (inventory hashing + symlink count)
Command: `FS_BENCH_ROOT=/Users/stephenwalker FS_BENCH_MAX_DEPTH=5 FS_BENCH_LIST_FIXED=1 BENCH_SET=fswalk tools/bench/run.sh`

Benchmark: fswalk
- aster: median 24.1278s, avg 24.1278s, min 23.5029s, stdev 0.8838s (runs 2)
- cpp:   median 22.8432s, avg 22.8432s, min 21.7994s, stdev 1.4762s (runs 2)
- rust:  median 21.2735s, avg 21.2735s, min 21.1208s, stdev 0.2159s (runs 2)
- perf delta (median): aster/baseline 1.134x

Benchmark: treewalk
- aster: median 11.8331s, avg 11.8331s, min 11.5635s, stdev 0.3813s (runs 2)
- cpp:   median 11.9503s, avg 11.9503s, min 11.5019s, stdev 0.6341s (runs 2)
- rust:  median 19.9558s, avg 19.9558s, min 16.3132s, stdev 5.1514s (runs 2)
- perf delta (median): aster/baseline 0.990x

Benchmark: dircount
- aster: median 16.8072s, avg 16.8072s, min 14.1390s, stdev 3.7735s (runs 2)
- cpp:   median 12.9417s, avg 12.9417s, min 12.6062s, stdev 0.4744s (runs 2)
- rust:  median 21.2454s, avg 21.2454s, min 21.1810s, stdev 0.0911s (runs 2)
- perf delta (median): aster/baseline 1.299x

Benchmark: fsinventory
- aster: median 13.6479s, avg 13.6479s, min 13.3179s, stdev 0.4667s (runs 2)
- cpp:   median 13.5380s, avg 13.5380s, min 13.5352s, stdev 0.0040s (runs 2)
- rust:  median 24.1242s, avg 24.1242s, min 21.7832s, stdev 3.3106s (runs 2)
- perf delta (median): aster/baseline 1.008x

Geometric mean (aster/baseline): 1.101x

Notes:
- Added fsinventory (inventory hashing + symlink counting) to fswalk bench set.

## Run 037 — fswalk/treewalk/dircount/fsinventory (dircount name fast-path + profile hook)
Command: `FS_BENCH_ROOT=/Users/stephenwalker FS_BENCH_MAX_DEPTH=5 FS_BENCH_LIST_FIXED=1 BENCH_SET=fswalk tools/bench/run.sh`

Benchmark: fswalk
- aster: median 19.0349s, avg 19.0349s, min 17.2208s, stdev 2.5655s (runs 2)
- cpp:   median 28.0246s, avg 28.0246s, min 20.3566s, stdev 10.8442s (runs 2)
- rust:  median 32.1395s, avg 32.1395s, min 26.2363s, stdev 8.3484s (runs 2)
- perf delta (median): aster/baseline 0.679x

Benchmark: treewalk
- aster: median 24.2125s, avg 24.2125s, min 23.3364s, stdev 1.2390s (runs 2)
- cpp:   median 20.5852s, avg 20.5852s, min 15.4665s, stdev 7.2391s (runs 2)
- rust:  median 20.7593s, avg 20.7593s, min 18.2642s, stdev 3.5286s (runs 2)
- perf delta (median): aster/baseline 1.176x

Benchmark: dircount
- aster: median 13.3705s, avg 13.3705s, min 12.6237s, stdev 1.0561s (runs 2)
- cpp:   median 13.4570s, avg 13.4570s, min 12.9705s, stdev 0.6881s (runs 2)
- rust:  median 22.4042s, avg 22.4042s, min 22.2737s, stdev 0.1846s (runs 2)
- perf delta (median): aster/baseline 0.994x

Benchmark: fsinventory
- aster: median 18.2526s, avg 18.2526s, min 16.5221s, stdev 2.4473s (runs 2)
- cpp:   median 17.8643s, avg 17.8643s, min 16.1577s, stdev 2.4135s (runs 2)
- rust:  median 23.7132s, avg 23.7132s, min 22.6430s, stdev 1.5135s (runs 2)
- perf delta (median): aster/baseline 1.022x

Geometric mean (aster/baseline): 0.949x

Notes:
- Added FS_BENCH_PROFILE to get Aster timing breakdown (not enabled in this run).

## Run 038 — fswalk/treewalk/dircount/fsinventory (treewalk list/replay)
Command: `FS_BENCH_ROOT=/Users/stephenwalker FS_BENCH_MAX_DEPTH=5 FS_BENCH_LIST_FIXED=1 FS_BENCH_TREEWALK_LIST_FIXED=1 BENCH_SET=fswalk tools/bench/run.sh`

Benchmark: fswalk
- aster: median 19.9463s, avg 19.9463s, min 19.3300s, stdev 0.8715s (runs 2)
- cpp:   median 22.8778s, avg 22.8778s, min 21.6442s, stdev 1.7446s (runs 2)
- rust:  median 20.9286s, avg 20.9286s, min 19.5516s, stdev 1.9473s (runs 2)
- perf delta (median): aster/baseline 0.953x

Benchmark: treewalk
- aster: median 32.8786s, avg 32.8786s, min 32.4972s, stdev 0.5394s (runs 2)
- cpp:   median 32.5763s, avg 32.5763s, min 32.4710s, stdev 0.1490s (runs 2)
- rust:  median 65.5847s, avg 65.5847s, min 46.7113s, stdev 26.6910s (runs 2)
- perf delta (median): aster/baseline 1.009x

Benchmark: dircount
- aster: median 71.1964s, avg 71.1964s, min 39.3743s, stdev 45.0033s (runs 2)
- cpp:   median 32.9919s, avg 32.9919s, min 32.3422s, stdev 0.9189s (runs 2)
- rust:  median 50.3950s, avg 50.3950s, min 45.5744s, stdev 6.8172s (runs 2)
- perf delta (median): aster/baseline 2.158x

Benchmark: fsinventory
- aster: median 36.6200s, avg 36.6200s, min 32.4467s, stdev 5.9019s (runs 2)
- cpp:   median 33.6033s, avg 33.6033s, min 32.4536s, stdev 1.6259s (runs 2)
- rust:  median 47.3877s, avg 47.3877s, min 47.1178s, stdev 0.3816s (runs 2)
- perf delta (median): aster/baseline 1.090x

Geometric mean (aster/baseline): 1.226x

Notes:
- Treewalk list/replay is substantially slower for dircount on this dataset (large directory list).

## Run 039 — fswalk/treewalk/dircount/fsinventory (bulk buffer 2MB)
Command: `FS_BENCH_ROOT=/Users/stephenwalker FS_BENCH_MAX_DEPTH=5 FS_BENCH_LIST_FIXED=1 FS_BENCH_BULK_BUF=2097152 BENCH_SET=fswalk tools/bench/run.sh`

Benchmark: fswalk
- aster: median 20.5687s, avg 20.5687s, min 19.6007s, stdev 1.3689s (runs 2)
- cpp:   median 20.6747s, avg 20.6747s, min 19.5218s, stdev 1.6305s (runs 2)
- rust:  median 20.0820s, avg 20.0820s, min 19.6239s, stdev 0.6478s (runs 2)
- perf delta (median): aster/baseline 1.024x

Benchmark: treewalk
- aster: median 32.9315s, avg 32.9315s, min 11.1339s, stdev 30.8264s (runs 2)
- cpp:   median 12.5026s, avg 12.5026s, min 10.8864s, stdev 2.2856s (runs 2)
- rust:  median 19.8636s, avg 19.8636s, min 15.1134s, stdev 6.7177s (runs 2)
- perf delta (median): aster/baseline 2.634x

Benchmark: dircount
- aster: median 13.2183s, avg 13.2183s, min 12.6863s, stdev 0.7523s (runs 2)
- cpp:   median 12.7644s, avg 12.7644s, min 12.5185s, stdev 0.3477s (runs 2)
- rust:  median 21.2369s, avg 21.2369s, min 20.7931s, stdev 0.6276s (runs 2)
- perf delta (median): aster/baseline 1.036x

Benchmark: fsinventory
- aster: median 12.9965s, avg 12.9965s, min 12.5256s, stdev 0.6660s (runs 2)
- cpp:   median 13.1021s, avg 13.1021s, min 12.8354s, stdev 0.3771s (runs 2)
- rust:  median 30.4168s, avg 30.4168s, min 25.0997s, stdev 7.5194s (runs 2)
- perf delta (median): aster/baseline 0.992x

Geometric mean (aster/baseline): 1.290x

Notes:
- Treewalk variance is extreme on this run; likely cache noise (min 11s vs median 33s).

## Run 040 — fswalk/treewalk/dircount/fsinventory (bulk buffer 4MB)
Command: `FS_BENCH_ROOT=/Users/stephenwalker FS_BENCH_MAX_DEPTH=5 FS_BENCH_LIST_FIXED=1 FS_BENCH_BULK_BUF=4194304 BENCH_SET=fswalk tools/bench/run.sh`

Benchmark: fswalk
- aster: median 20.4291s, avg 20.4291s, min 16.2934s, stdev 5.8487s (runs 2)
- cpp:   median 27.8903s, avg 27.8903s, min 26.3128s, stdev 2.2309s (runs 2)
- rust:  median 24.9535s, avg 24.9535s, min 24.7046s, stdev 0.3521s (runs 2)
- perf delta (median): aster/baseline 0.819x

Benchmark: treewalk
- aster: median 11.8004s, avg 11.8004s, min 11.3838s, stdev 0.5892s (runs 2)
- cpp:   median 11.4024s, avg 11.4024s, min 11.1461s, stdev 0.3624s (runs 2)
- rust:  median 18.4923s, avg 18.4923s, min 14.8897s, stdev 5.0948s (runs 2)
- perf delta (median): aster/baseline 1.035x

Benchmark: dircount
- aster: median 13.5604s, avg 13.5604s, min 13.3474s, stdev 0.3012s (runs 2)
- cpp:   median 13.3911s, avg 13.3911s, min 13.0218s, stdev 0.5223s (runs 2)
- rust:  median 22.6913s, avg 22.6913s, min 21.7991s, stdev 1.2617s (runs 2)
- perf delta (median): aster/baseline 1.013x

Benchmark: fsinventory
- aster: median 13.7946s, avg 13.7946s, min 13.5788s, stdev 0.3051s (runs 2)
- cpp:   median 15.0478s, avg 15.0478s, min 13.3132s, stdev 2.4531s (runs 2)
- rust:  median 21.5135s, avg 21.5135s, min 21.1704s, stdev 0.4852s (runs 2)
- perf delta (median): aster/baseline 0.917x

Geometric mean (aster/baseline): 0.942x

## Run 041 — fswalk/treewalk/dircount/fsinventory (bulk NOINMEM=1)
Command: `FS_BENCH_ROOT=/Users/stephenwalker FS_BENCH_MAX_DEPTH=5 FS_BENCH_LIST_FIXED=1 FS_BENCH_BULK_NOINMEM=1 BENCH_SET=fswalk tools/bench/run.sh`

Benchmark: fswalk
- aster: median 17.7634s, avg 17.7634s, min 15.2759s, stdev 3.5179s (runs 2)
- cpp:   median 21.3759s, avg 21.3759s, min 21.2987s, stdev 0.1093s (runs 2)
- rust:  median 21.1725s, avg 21.1725s, min 20.9574s, stdev 0.3043s (runs 2)
- perf delta (median): aster/baseline 0.839x

Benchmark: treewalk
- aster: median 12.5747s, avg 12.5747s, min 11.4790s, stdev 1.5495s (runs 2)
- cpp:   median 11.4009s, avg 11.4009s, min 11.3486s, stdev 0.0739s (runs 2)
- rust:  median 19.6899s, avg 19.6899s, min 17.1211s, stdev 3.6328s (runs 2)
- perf delta (median): aster/baseline 1.103x

Benchmark: dircount
- aster: median 13.4352s, avg 13.4352s, min 13.0342s, stdev 0.5672s (runs 2)
- cpp:   median 13.4200s, avg 13.4200s, min 13.1086s, stdev 0.4404s (runs 2)
- rust:  median 21.9334s, avg 21.9334s, min 21.7316s, stdev 0.2854s (runs 2)
- perf delta (median): aster/baseline 1.001x

Benchmark: fsinventory
- aster: median 14.5223s, avg 14.5223s, min 14.0936s, stdev 0.6062s (runs 2)
- cpp:   median 13.4834s, avg 13.4834s, min 13.0258s, stdev 0.6471s (runs 2)
- rust:  median 24.5396s, avg 24.5396s, min 22.6874s, stdev 2.6195s (runs 2)
- perf delta (median): aster/baseline 1.077x

Geometric mean (aster/baseline): 0.999x

## Run 042 — dircount tuning (3 runs, bulk mode, 4MB default buffer)
Command: `FS_BENCH_ROOT=/Users/stephenwalker FS_BENCH_MAX_DEPTH=5 FS_BENCH_COUNT_ONLY=1 FS_BENCH_TREEWALK_MODE=bulk FS_BENCH_CPP_MODE=bulk tools/bench/out/*_dircount (manual 3-run harness)`

Benchmark: dircount
- aster: median 13.0653s, avg 13.4004s, min 13.0118s, stdev 0.6274s (runs 3)
- cpp:   median 13.8134s, avg 14.3436s, min 13.1353s, stdev 1.5432s (runs 3)
- rust:  median 27.5339s, avg 25.9498s, min 21.8247s, stdev 3.6043s (runs 3)
- perf delta (median): aster/baseline 0.946x

Notes:
- Manual 3-run harness to reduce variance for dircount only.

## Run 043 — dircount profile (Aster, bulk mode)
Command: `FS_BENCH_ROOT=/Users/stephenwalker FS_BENCH_MAX_DEPTH=5 FS_BENCH_COUNT_ONLY=1 FS_BENCH_PROFILE=1 FS_BENCH_TREEWALK_MODE=bulk tools/bench/out/aster_dircount`

Profile snapshot:
- files=401967 dirs=97373 bytes=0
- bulk_ns=12.377959s, parse_ns=0.604226s, open_ns=0.600548s
- calls=47805 entries=510283 open=25242

## Run 044 — full suite (kernels + fswalk) with 4MB default buffer
Command: `FS_BENCH_ROOT=/Users/stephenwalker FS_BENCH_MAX_DEPTH=5 FS_BENCH_LIST_FIXED=1 tools/bench/run.sh`

Benchmark: dot
- aster: median 0.0163s, avg 0.0163s, min 0.0157s, stdev 0.0006s (runs 5)
- cpp:   median 0.0194s, avg 0.0192s, min 0.0181s, stdev 0.0009s (runs 5)
- rust:  median 0.0191s, avg 0.0192s, min 0.0183s, stdev 0.0010s (runs 5)
- perf delta (median): aster/baseline 0.854x

Benchmark: gemm
- aster: median 0.0037s, avg 0.0040s, min 0.0034s, stdev 0.0006s (runs 5)
- cpp:   median 0.0040s, avg 0.0038s, min 0.0034s, stdev 0.0003s (runs 5)
- rust:  median 0.0042s, avg 0.0041s, min 0.0037s, stdev 0.0004s (runs 5)
- perf delta (median): aster/baseline 0.929x

Benchmark: stencil
- aster: median 0.0038s, avg 0.0041s, min 0.0036s, stdev 0.0007s (runs 5)
- cpp:   median 0.0040s, avg 0.0040s, min 0.0033s, stdev 0.0007s (runs 5)
- rust:  median 0.0051s, avg 0.0047s, min 0.0036s, stdev 0.0009s (runs 5)
- perf delta (median): aster/baseline 0.935x

Benchmark: sort
- aster: median 0.0056s, avg 0.0057s, min 0.0047s, stdev 0.0011s (runs 5)
- cpp:   median 0.0144s, avg 0.0145s, min 0.0137s, stdev 0.0007s (runs 5)
- rust:  median 0.0064s, avg 0.0063s, min 0.0057s, stdev 0.0004s (runs 5)
- perf delta (median): aster/baseline 0.873x

Benchmark: json
- aster: median 0.0039s, avg 0.0040s, min 0.0038s, stdev 0.0003s (runs 5)
- cpp:   median 0.0044s, avg 0.0044s, min 0.0039s, stdev 0.0003s (runs 5)
- rust:  median 0.0041s, avg 0.0041s, min 0.0036s, stdev 0.0003s (runs 5)
- perf delta (median): aster/baseline 0.941x

Benchmark: hashmap
- aster: median 0.0094s, avg 0.0094s, min 0.0082s, stdev 0.0008s (runs 5)
- cpp:   median 0.0077s, avg 0.0080s, min 0.0075s, stdev 0.0005s (runs 5)
- rust:  median 0.0081s, avg 0.0082s, min 0.0072s, stdev 0.0010s (runs 5)
- perf delta (median): aster/baseline 1.231x

Benchmark: regex
- aster: median 0.0054s, avg 0.0053s, min 0.0045s, stdev 0.0005s (runs 5)
- cpp:   median 0.0057s, avg 0.0064s, min 0.0050s, stdev 0.0018s (runs 5)
- rust:  median 0.0060s, avg 0.0061s, min 0.0053s, stdev 0.0006s (runs 5)
- perf delta (median): aster/baseline 0.953x

Benchmark: async_io
- aster: median 0.0055s, avg 0.0057s, min 0.0055s, stdev 0.0003s (runs 5)
- cpp:   median 0.0064s, avg 0.0062s, min 0.0058s, stdev 0.0003s (runs 5)
- rust:  median 0.0060s, avg 0.0059s, min 0.0055s, stdev 0.0004s (runs 5)
- perf delta (median): aster/baseline 0.931x

Benchmark: fswalk
- aster: median 15.9989s, avg 15.9989s, min 12.0428s, stdev 5.5946s (runs 2)
- cpp:   median 20.7699s, avg 20.7699s, min 20.3774s, stdev 0.5551s (runs 2)
- rust:  median 24.2434s, avg 24.2434s, min 23.4535s, stdev 1.1170s (runs 2)
- perf delta (median): aster/baseline 0.770x

Benchmark: treewalk
- aster: median 11.5306s, avg 11.5306s, min 11.5203s, stdev 0.0146s (runs 2)
- cpp:   median 11.8463s, avg 11.8463s, min 11.6750s, stdev 0.2422s (runs 2)
- rust:  median 18.5569s, avg 18.5569s, min 15.3311s, stdev 4.5620s (runs 2)
- perf delta (median): aster/baseline 0.973x

Benchmark: dircount
- aster: median 13.9425s, avg 13.9425s, min 13.1882s, stdev 1.0667s (runs 2)
- cpp:   median 13.6221s, avg 13.6221s, min 13.4907s, stdev 0.1859s (runs 2)
- rust:  median 22.1854s, avg 22.1854s, min 22.1691s, stdev 0.0231s (runs 2)
- perf delta (median): aster/baseline 1.024x

Benchmark: fsinventory
- aster: median 13.7473s, avg 13.7473s, min 13.6689s, stdev 0.1108s (runs 2)
- cpp:   median 13.9479s, avg 13.9479s, min 13.6776s, stdev 0.3823s (runs 2)
- rust:  median 24.9348s, avg 24.9348s, min 22.1587s, stdev 3.9260s (runs 2)
- perf delta (median): aster/baseline 0.986x

Geometric mean (aster/baseline): 0.944x

## Run 045 — fswalk/treewalk/dircount/fsinventory (default 4MB buffer stability)
Command: `FS_BENCH_ROOT=/Users/stephenwalker FS_BENCH_MAX_DEPTH=5 FS_BENCH_LIST_FIXED=1 BENCH_SET=fswalk tools/bench/run.sh`

Benchmark: fswalk
- aster: median 23.1093s, avg 23.1093s, min 17.1305s, stdev 8.4552s (runs 2)
- cpp:   median 31.5809s, avg 31.5809s, min 30.6073s, stdev 1.3768s (runs 2)
- rust:  median 27.5633s, avg 27.5633s, min 27.2281s, stdev 0.4741s (runs 2)
- perf delta (median): aster/baseline 0.838x

Benchmark: treewalk
- aster: median 12.4301s, avg 12.4301s, min 11.8362s, stdev 0.8400s (runs 2)
- cpp:   median 12.8673s, avg 12.8673s, min 11.0086s, stdev 2.6287s (runs 2)
- rust:  median 18.1326s, avg 18.1326s, min 15.2918s, stdev 4.0174s (runs 2)
- perf delta (median): aster/baseline 0.966x

Benchmark: dircount
- aster: median 12.7151s, avg 12.7151s, min 12.3095s, stdev 0.5736s (runs 2)
- cpp:   median 15.0282s, avg 15.0282s, min 12.2705s, stdev 3.8999s (runs 2)
- rust:  median 20.9399s, avg 20.9399s, min 20.8174s, stdev 0.1732s (runs 2)
- perf delta (median): aster/baseline 0.846x

Benchmark: fsinventory
- aster: median 15.2161s, avg 15.2161s, min 15.0665s, stdev 0.2115s (runs 2)
- cpp:   median 15.9029s, avg 15.9029s, min 15.8517s, stdev 0.0723s (runs 2)
- rust:  median 21.6875s, avg 21.6875s, min 21.5100s, stdev 0.2510s (runs 2)
- perf delta (median): aster/baseline 0.957x

Geometric mean (aster/baseline): 0.900x

Notes:
- This run used the 4MB default buffer before the 8MB default switch.

## Run 046 — fswalk/treewalk/dircount/fsinventory (bulk buffer 8MB)
Command: `FS_BENCH_ROOT=/Users/stephenwalker FS_BENCH_MAX_DEPTH=5 FS_BENCH_LIST_FIXED=1 FS_BENCH_BULK_BUF=8388608 BENCH_SET=fswalk tools/bench/run.sh`

Benchmark: fswalk
- aster: median 16.5806s, avg 16.5806s, min 13.9341s, stdev 3.7428s (runs 2)
- cpp:   median 19.8306s, avg 19.8306s, min 19.6035s, stdev 0.3211s (runs 2)
- rust:  median 20.0153s, avg 20.0153s, min 19.2815s, stdev 1.0377s (runs 2)
- perf delta (median): aster/baseline 0.836x

Benchmark: treewalk
- aster: median 11.0444s, avg 11.0444s, min 10.7920s, stdev 0.3570s (runs 2)
- cpp:   median 11.0728s, avg 11.0728s, min 10.8172s, stdev 0.3615s (runs 2)
- rust:  median 17.4647s, avg 17.4647s, min 14.1453s, stdev 4.6944s (runs 2)
- perf delta (median): aster/baseline 0.997x

Benchmark: dircount
- aster: median 12.7727s, avg 12.7727s, min 12.3254s, stdev 0.6325s (runs 2)
- cpp:   median 12.7051s, avg 12.7051s, min 12.5852s, stdev 0.1697s (runs 2)
- rust:  median 20.9731s, avg 20.9731s, min 20.7246s, stdev 0.3515s (runs 2)
- perf delta (median): aster/baseline 1.005x

Benchmark: fsinventory
- aster: median 13.4131s, avg 13.4131s, min 12.5947s, stdev 1.1573s (runs 2)
- cpp:   median 12.9316s, avg 12.9316s, min 12.7991s, stdev 0.1874s (runs 2)
- rust:  median 21.4817s, avg 21.4817s, min 21.4641s, stdev 0.0249s (runs 2)
- perf delta (median): aster/baseline 1.037x

Geometric mean (aster/baseline): 0.966x

Notes:
- 8MB buffer improved fswalk and treewalk stability; adopted as new default.

## Run 047 — full suite (after hashmap/regex/json tweaks; 8MB default)
Command: `FS_BENCH_ROOT=/Users/stephenwalker FS_BENCH_MAX_DEPTH=5 FS_BENCH_LIST_FIXED=1 tools/bench/run.sh`

Benchmark: dot
- aster: median 0.0131s, avg 0.0134s, min 0.0128s, stdev 0.0006s (runs 5)
- cpp:   median 0.0160s, avg 0.0160s, min 0.0150s, stdev 0.0010s (runs 5)
- rust:  median 0.0165s, avg 0.0171s, min 0.0162s, stdev 0.0011s (runs 5)
- perf delta (median): aster/baseline 0.823x

Benchmark: gemm
- aster: median 0.0038s, avg 0.0038s, min 0.0031s, stdev 0.0005s (runs 5)
- cpp:   median 0.0037s, avg 0.0038s, min 0.0032s, stdev 0.0006s (runs 5)
- rust:  median 0.0044s, avg 0.0044s, min 0.0037s, stdev 0.0005s (runs 5)
- perf delta (median): aster/baseline 1.020x

Benchmark: stencil
- aster: median 0.0035s, avg 0.0037s, min 0.0033s, stdev 0.0004s (runs 5)
- cpp:   median 0.0036s, avg 0.0034s, min 0.0027s, stdev 0.0004s (runs 5)
- rust:  median 0.0036s, avg 0.0036s, min 0.0032s, stdev 0.0003s (runs 5)
- perf delta (median): aster/baseline 0.997x

Benchmark: sort
- aster: median 0.0061s, avg 0.0061s, min 0.0047s, stdev 0.0012s (runs 5)
- cpp:   median 0.0147s, avg 0.0143s, min 0.0129s, stdev 0.0011s (runs 5)
- rust:  median 0.0074s, avg 0.0074s, min 0.0062s, stdev 0.0014s (runs 5)
- perf delta (median): aster/baseline 0.829x

Benchmark: json
- aster: median 0.0040s, avg 0.0040s, min 0.0036s, stdev 0.0003s (runs 5)
- cpp:   median 0.0037s, avg 0.0036s, min 0.0029s, stdev 0.0005s (runs 5)
- rust:  median 0.0035s, avg 0.0034s, min 0.0029s, stdev 0.0003s (runs 5)
- perf delta (median): aster/baseline 1.126x

Benchmark: hashmap
- aster: median 0.0069s, avg 0.0072s, min 0.0067s, stdev 0.0005s (runs 5)
- cpp:   median 0.0076s, avg 0.0076s, min 0.0066s, stdev 0.0008s (runs 5)
- rust:  median 0.0079s, avg 0.0077s, min 0.0066s, stdev 0.0011s (runs 5)
- perf delta (median): aster/baseline 0.902x

Benchmark: regex
- aster: median 0.0052s, avg 0.0053s, min 0.0051s, stdev 0.0002s (runs 5)
- cpp:   median 0.0047s, avg 0.0047s, min 0.0043s, stdev 0.0004s (runs 5)
- rust:  median 0.0050s, avg 0.0051s, min 0.0047s, stdev 0.0006s (runs 5)
- perf delta (median): aster/baseline 1.105x

Benchmark: async_io
- aster: median 0.0058s, avg 0.0060s, min 0.0051s, stdev 0.0011s (runs 5)
- cpp:   median 0.0055s, avg 0.0059s, min 0.0053s, stdev 0.0009s (runs 5)
- rust:  median 0.0057s, avg 0.0056s, min 0.0052s, stdev 0.0003s (runs 5)
- perf delta (median): aster/baseline 1.043x

Benchmark: fswalk
- aster: median 16.6558s, avg 16.6558s, min 13.4021s, stdev 4.6015s (runs 2)
- cpp:   median 20.0889s, avg 20.0889s, min 19.3710s, stdev 1.0154s (runs 2)
- rust:  median 20.0021s, avg 20.0021s, min 19.6907s, stdev 0.4405s (runs 2)
- perf delta (median): aster/baseline 0.833x

Benchmark: treewalk
- aster: median 11.1602s, avg 11.1602s, min 10.9802s, stdev 0.2545s (runs 2)
- cpp:   median 11.5661s, avg 11.5661s, min 11.0300s, stdev 0.7581s (runs 2)
- rust:  median 17.6335s, avg 17.6335s, min 14.4107s, stdev 4.5577s (runs 2)
- perf delta (median): aster/baseline 0.965x

Benchmark: dircount
- aster: median 13.5103s, avg 13.5103s, min 12.6992s, stdev 1.1471s (runs 2)
- cpp:   median 12.9383s, avg 12.9383s, min 12.5363s, stdev 0.5684s (runs 2)
- rust:  median 21.0969s, avg 21.0969s, min 20.8332s, stdev 0.3730s (runs 2)
- perf delta (median): aster/baseline 1.044x

Benchmark: fsinventory
- aster: median 13.2085s, avg 13.2085s, min 12.7497s, stdev 0.6488s (runs 2)
- cpp:   median 13.0390s, avg 13.0390s, min 12.7992s, stdev 0.3392s (runs 2)
- rust:  median 20.8749s, avg 20.8749s, min 20.8704s, stdev 0.0063s (runs 2)
- perf delta (median): aster/baseline 1.013x

Geometric mean (aster/baseline): 0.970x

## Run 048 — full suite (regex/json reverted; 8MB default)
Command: `FS_BENCH_ROOT=/Users/stephenwalker FS_BENCH_MAX_DEPTH=5 FS_BENCH_LIST_FIXED=1 tools/bench/run.sh`

Benchmark: dot
- aster: median 0.0139s, avg 0.0146s, min 0.0135s, stdev 0.0017s (runs 5)
- cpp:   median 0.0167s, avg 0.0175s, min 0.0165s, stdev 0.0012s (runs 5)
- rust:  median 0.0170s, avg 0.0172s, min 0.0166s, stdev 0.0005s (runs 5)
- perf delta (median): aster/baseline 0.832x

Benchmark: gemm
- aster: median 0.0037s, avg 0.0038s, min 0.0032s, stdev 0.0007s (runs 5)
- cpp:   median 0.0036s, avg 0.0036s, min 0.0032s, stdev 0.0004s (runs 5)
- rust:  median 0.0045s, avg 0.0043s, min 0.0035s, stdev 0.0006s (runs 5)
- perf delta (median): aster/baseline 1.023x

Benchmark: stencil
- aster: median 0.0034s, avg 0.0033s, min 0.0029s, stdev 0.0003s (runs 5)
- cpp:   median 0.0035s, avg 0.0034s, min 0.0029s, stdev 0.0004s (runs 5)
- rust:  median 0.0038s, avg 0.0037s, min 0.0032s, stdev 0.0003s (runs 5)
- perf delta (median): aster/baseline 0.986x

Benchmark: sort
- aster: median 0.0047s, avg 0.0047s, min 0.0042s, stdev 0.0004s (runs 5)
- cpp:   median 0.0125s, avg 0.0125s, min 0.0123s, stdev 0.0001s (runs 5)
- rust:  median 0.0053s, avg 0.0054s, min 0.0051s, stdev 0.0005s (runs 5)
- perf delta (median): aster/baseline 0.890x

Benchmark: json
- aster: median 0.0037s, avg 0.0043s, min 0.0032s, stdev 0.0015s (runs 5)
- cpp:   median 0.0033s, avg 0.0035s, min 0.0032s, stdev 0.0005s (runs 5)
- rust:  median 0.0049s, avg 0.0049s, min 0.0044s, stdev 0.0004s (runs 5)
- perf delta (median): aster/baseline 1.125x

Benchmark: hashmap
- aster: median 0.0077s, avg 0.0076s, min 0.0072s, stdev 0.0003s (runs 5)
- cpp:   median 0.0068s, avg 0.0074s, min 0.0059s, stdev 0.0016s (runs 5)
- rust:  median 0.0072s, avg 0.0069s, min 0.0061s, stdev 0.0005s (runs 5)
- perf delta (median): aster/baseline 1.125x

Benchmark: regex
- aster: median 0.0046s, avg 0.0046s, min 0.0039s, stdev 0.0004s (runs 5)
- cpp:   median 0.0044s, avg 0.0043s, min 0.0040s, stdev 0.0002s (runs 5)
- rust:  median 0.0058s, avg 0.0060s, min 0.0048s, stdev 0.0009s (runs 5)
- perf delta (median): aster/baseline 1.038x

Benchmark: async_io
- aster: median 0.0067s, avg 0.0064s, min 0.0047s, stdev 0.0013s (runs 5)
- cpp:   median 0.0062s, avg 0.0065s, min 0.0057s, stdev 0.0008s (runs 5)
- rust:  median 0.0057s, avg 0.0056s, min 0.0052s, stdev 0.0003s (runs 5)
- perf delta (median): aster/baseline 1.174x

Benchmark: fswalk
- aster: median 16.5027s, avg 16.5027s, min 13.5079s, stdev 4.2353s (runs 2)
- cpp:   median 21.4328s, avg 21.4328s, min 19.6288s, stdev 2.5512s (runs 2)
- rust:  median 20.3717s, avg 20.3717s, min 19.9385s, stdev 0.6127s (runs 2)
- perf delta (median): aster/baseline 0.810x

Benchmark: treewalk
- aster: median 11.0097s, avg 11.0097s, min 10.7356s, stdev 0.3876s (runs 2)
- cpp:   median 11.0680s, avg 11.0680s, min 10.8176s, stdev 0.3541s (runs 2)
- rust:  median 17.5621s, avg 17.5621s, min 14.4791s, stdev 4.3601s (runs 2)
- perf delta (median): aster/baseline 0.995x

Benchmark: dircount
- aster: median 12.8739s, avg 12.8739s, min 12.3965s, stdev 0.6751s (runs 2)
- cpp:   median 12.6258s, avg 12.6258s, min 12.2308s, stdev 0.5586s (runs 2)
- rust:  median 21.7246s, avg 21.7246s, min 20.9513s, stdev 1.0936s (runs 2)
- perf delta (median): aster/baseline 1.020x

Benchmark: fsinventory
- aster: median 13.5964s, avg 13.5964s, min 12.5961s, stdev 1.4146s (runs 2)
- cpp:   median 13.1387s, avg 13.1387s, min 12.8804s, stdev 0.3652s (runs 2)
- rust:  median 20.8218s, avg 20.8218s, min 20.6128s, stdev 0.2955s (runs 2)
- perf delta (median): aster/baseline 1.035x

Geometric mean (aster/baseline): 0.998x

## Build timing snapshot — asterc (hashmap)
Command: `ASTER_TIMING=1 ASTER_CACHE=0 tools/build/asterc.sh aster/bench/hashmap/hashmap.as tools/bench/out/aster_hashmap.S`

Timing:
- parse_ns=14292
- emit_ns=740541
- clang_ns=296432083
- total_ns=297186916

## Epoch — real `asterc` (compiler-produced benchmarks)

Started: 2026-02-06

Notes:
- Bench binaries are compiled from `.as` source by the real compiler at `tools/build/out/asterc` (no shims/templates).
- Current compiler pipeline: Aster source -> LLVM IR (`.ll`) -> `clang -O3` -> executable.

## Run 049 — `tools/ci/gates.sh` (real `asterc`, synthetic FS dataset)
Command: `tools/ci/gates.sh`

Environment:
- Host: Darwin arm64
- Clang: Apple clang 17.0.0 (clang-1700.6.3.2)
- Rust: rustc 1.92.0 (ded5c06cf 2025-12-08)
- Date: 2026-02-06

FS dataset:
- FS_BENCH_ROOT: `.context/ci/fsroot` (generated by `tools/ci/gates.sh`)
- FS_BENCH_MAX_DEPTH: 6
- fswalk_list.txt: sha256=2c25e78cd8aa21006c53296aa03f47d6f65fec50bb682ff8c5fefc33ef4e9343, bytes=885, lines=11

Benchmark: dot
- aster: median 0.0177s  avg 0.0176s  min 0.0165s  stdev 0.0007s  runs 5
- cpp:   median 0.0171s  avg 0.0174s  min 0.0169s  stdev 0.0008s  runs 5
- rust:  median 0.0163s  avg 0.0167s  min 0.0160s  stdev 0.0008s  runs 5
- perf delta (median): aster/baseline 1.086x

Benchmark: gemm
- aster: median 0.0031s  avg 0.0032s  min 0.0030s  stdev 0.0003s  runs 5
- cpp:   median 0.0037s  avg 0.0039s  min 0.0031s  stdev 0.0006s  runs 5
- rust:  median 0.0038s  avg 0.0043s  min 0.0032s  stdev 0.0015s  runs 5
- perf delta (median): aster/baseline 0.840x

Benchmark: stencil
- aster: median 0.0033s  avg 0.0035s  min 0.0031s  stdev 0.0004s  runs 5
- cpp:   median 0.0033s  avg 0.0034s  min 0.0030s  stdev 0.0004s  runs 5
- rust:  median 0.0030s  avg 0.0032s  min 0.0030s  stdev 0.0003s  runs 5
- perf delta (median): aster/baseline 1.075x

Benchmark: sort
- aster: median 0.0044s  avg 0.0044s  min 0.0042s  stdev 0.0002s  runs 5
- cpp:   median 0.0125s  avg 0.0125s  min 0.0121s  stdev 0.0003s  runs 5
- rust:  median 0.0053s  avg 0.0055s  min 0.0049s  stdev 0.0007s  runs 5
- perf delta (median): aster/baseline 0.828x

Benchmark: json
- aster: median 0.0023s  avg 0.0023s  min 0.0020s  stdev 0.0002s  runs 5
- cpp:   median 0.0031s  avg 0.0031s  min 0.0029s  stdev 0.0002s  runs 5
- rust:  median 0.0035s  avg 0.0035s  min 0.0033s  stdev 0.0003s  runs 5
- perf delta (median): aster/baseline 0.748x

Benchmark: hashmap
- aster: median 0.0061s  avg 0.0060s  min 0.0055s  stdev 0.0003s  runs 5
- cpp:   median 0.0061s  avg 0.0060s  min 0.0054s  stdev 0.0004s  runs 5
- rust:  median 0.0062s  avg 0.0063s  min 0.0061s  stdev 0.0002s  runs 5
- perf delta (median): aster/baseline 0.993x

Benchmark: regex
- aster: median 0.0045s  avg 0.0046s  min 0.0043s  stdev 0.0003s  runs 5
- cpp:   median 0.0042s  avg 0.0042s  min 0.0039s  stdev 0.0003s  runs 5
- rust:  median 0.0045s  avg 0.0045s  min 0.0039s  stdev 0.0004s  runs 5
- perf delta (median): aster/baseline 1.050x

Benchmark: async_io
- aster: median 0.0050s  avg 0.0050s  min 0.0046s  stdev 0.0002s  runs 5
- cpp:   median 0.0049s  avg 0.0048s  min 0.0046s  stdev 0.0002s  runs 5
- rust:  median 0.0066s  avg 0.0065s  min 0.0056s  stdev 0.0008s  runs 5
- perf delta (median): aster/baseline 1.007x

Benchmark: fswalk
- aster: median 0.0028s  avg 0.0939s  min 0.0027s  stdev 0.1579s  runs 3
- cpp:   median 0.0031s  avg 0.0501s  min 0.0028s  stdev 0.0817s  runs 3
- rust:  median 0.0033s  avg 0.0507s  min 0.0028s  stdev 0.0825s  runs 3
- perf delta (median): aster/baseline 0.899x

Benchmark: treewalk
- aster: median 0.0035s  avg 0.0034s  min 0.0024s  stdev 0.0010s  runs 3
- cpp:   median 0.0032s  avg 0.0041s  min 0.0032s  stdev 0.0015s  runs 3
- rust:  median 0.0028s  avg 0.0091s  min 0.0023s  stdev 0.0114s  runs 3
- perf delta (median): aster/baseline 1.224x

Benchmark: dircount
- aster: median 0.0026s  avg 0.0030s  min 0.0022s  stdev 0.0011s  runs 3
- cpp:   median 0.0030s  avg 0.0036s  min 0.0030s  stdev 0.0012s  runs 3
- rust:  median 0.0029s  avg 0.0093s  min 0.0025s  stdev 0.0114s  runs 3
- perf delta (median): aster/baseline 0.882x

Benchmark: fsinventory
- aster: median 0.0021s  avg 0.0027s  min 0.0021s  stdev 0.0011s  runs 3
- cpp:   median 0.0032s  avg 0.0038s  min 0.0029s  stdev 0.0012s  runs 3
- rust:  median 0.0029s  avg 0.0092s  min 0.0025s  stdev 0.0112s  runs 3
- perf delta (median): aster/baseline 0.732x

Geometric mean (aster/baseline): 0.936x

## Run 050 — `tools/ci/gates.sh` (real `asterc`, synthetic FS dataset, fixed lists)
Command: `tools/ci/gates.sh`

Environment:
- Host: Darwin arm64
- Clang: Apple clang 17.0.0 (clang-1700.6.3.2)
- Rust: rustc 1.92.0 (ded5c06cf 2025-12-08)
- Date: 2026-02-06

FS dataset:
- FS_BENCH_ROOT: `.context/ci/fsroot` (generated by `tools/ci/gates.sh`)
- FS_BENCH_MAX_DEPTH: 6
- fswalk_list: sha256=3db723a1a82f56d1cfc42d587e759bfe0464bf5a1974895c6fa8c8134108c0aa, bytes=885, lines=11
- treewalk_dirs: sha256=067c81d134dc0a7d8c9208d251148b29f74ee878f5695a0bbd274e6beebc5c63, bytes=372, lines=5

Benchmark: dot
- aster: median 0.0158s  avg 0.0158s  min 0.0146s  stdev 0.0008s  runs 5
- cpp:   median 0.0161s  avg 0.0160s  min 0.0154s  stdev 0.0005s  runs 5
- rust:  median 0.0171s  avg 0.0172s  min 0.0163s  stdev 0.0007s  runs 5
- perf delta (median): aster/baseline 0.980x

Benchmark: gemm
- aster: median 0.0033s  avg 0.0034s  min 0.0028s  stdev 0.0004s  runs 5
- cpp:   median 0.0030s  avg 0.0030s  min 0.0025s  stdev 0.0004s  runs 5
- rust:  median 0.0038s  avg 0.0037s  min 0.0032s  stdev 0.0002s  runs 5
- perf delta (median): aster/baseline 1.096x

Benchmark: stencil
- aster: median 0.0033s  avg 0.0033s  min 0.0028s  stdev 0.0004s  runs 5
- cpp:   median 0.0028s  avg 0.0029s  min 0.0028s  stdev 0.0001s  runs 5
- rust:  median 0.0033s  avg 0.0033s  min 0.0031s  stdev 0.0002s  runs 5
- perf delta (median): aster/baseline 1.146x

Benchmark: sort
- aster: median 0.0043s  avg 0.0043s  min 0.0041s  stdev 0.0002s  runs 5
- cpp:   median 0.0122s  avg 0.0123s  min 0.0119s  stdev 0.0003s  runs 5
- rust:  median 0.0052s  avg 0.0051s  min 0.0048s  stdev 0.0002s  runs 5
- perf delta (median): aster/baseline 0.837x

Benchmark: json
- aster: median 0.0020s  avg 0.0021s  min 0.0018s  stdev 0.0003s  runs 5
- cpp:   median 0.0029s  avg 0.0029s  min 0.0027s  stdev 0.0003s  runs 5
- rust:  median 0.0038s  avg 0.0039s  min 0.0030s  stdev 0.0008s  runs 5
- perf delta (median): aster/baseline 0.716x

Benchmark: hashmap
- aster: median 0.0065s  avg 0.0066s  min 0.0060s  stdev 0.0006s  runs 5
- cpp:   median 0.0067s  avg 0.0067s  min 0.0061s  stdev 0.0005s  runs 5
- rust:  median 0.0065s  avg 0.0066s  min 0.0063s  stdev 0.0003s  runs 5
- perf delta (median): aster/baseline 1.010x

Benchmark: regex
- aster: median 0.0043s  avg 0.0044s  min 0.0041s  stdev 0.0003s  runs 5
- cpp:   median 0.0040s  avg 0.0040s  min 0.0037s  stdev 0.0002s  runs 5
- rust:  median 0.0044s  avg 0.0044s  min 0.0041s  stdev 0.0003s  runs 5
- perf delta (median): aster/baseline 1.076x

Benchmark: async_io
- aster: median 0.0048s  avg 0.0048s  min 0.0047s  stdev 0.0002s  runs 5
- cpp:   median 0.0049s  avg 0.0049s  min 0.0046s  stdev 0.0002s  runs 5
- rust:  median 0.0050s  avg 0.0050s  min 0.0047s  stdev 0.0003s  runs 5
- perf delta (median): aster/baseline 0.984x

Benchmark: fswalk
- aster: median 0.0029s  avg 0.0897s  min 0.0024s  stdev 0.1507s  runs 3
- cpp:   median 0.0035s  avg 0.0493s  min 0.0029s  stdev 0.0799s  runs 3
- rust:  median 0.0028s  avg 0.0516s  min 0.0025s  stdev 0.0847s  runs 3
- perf delta (median): aster/baseline 1.039x

Benchmark: treewalk
- aster: median 0.0027s  avg 0.0031s  min 0.0025s  stdev 0.0008s  runs 3
- cpp:   median 0.0029s  avg 0.0036s  min 0.0029s  stdev 0.0012s  runs 3
- rust:  median 0.0029s  avg 0.0091s  min 0.0024s  stdev 0.0111s  runs 3
- perf delta (median): aster/baseline 0.904x

Benchmark: dircount
- aster: median 0.0040s  avg 0.0040s  min 0.0038s  stdev 0.0002s  runs 3
- cpp:   median 0.0032s  avg 0.0041s  min 0.0028s  stdev 0.0019s  runs 3
- rust:  median 0.0029s  avg 0.0093s  min 0.0028s  stdev 0.0111s  runs 3
- perf delta (median): aster/baseline 1.385x

Benchmark: fsinventory
- aster: median 0.0024s  avg 0.0031s  min 0.0022s  stdev 0.0013s  runs 3
- cpp:   median 0.0032s  avg 0.0037s  min 0.0031s  stdev 0.0010s  runs 3
- rust:  median 0.0029s  avg 0.0093s  min 0.0026s  stdev 0.0113s  runs 3
- perf delta (median): aster/baseline 0.831x

Geometric mean (aster/baseline): 0.987x
Win rate (aster < baseline): 6/12 = 50.0%
Margin >=5% faster (<=0.95x): 4/12 = 33.3%
Margin >=15% faster (<=0.85x): 3/12 = 25.0%

## Run 051 — `tools/ci/gates.sh` (real `asterc`, build timing enabled)
Command: `BENCH_BUILD_TIMING=1 tools/ci/gates.sh`

Environment:
- Host: Darwin arm64
- Clang: Apple clang 17.0.0 (clang-1700.6.3.2)
- Rust: rustc 1.92.0 (ded5c06cf 2025-12-08)
- Date: 2026-02-06

FS dataset:
- FS_BENCH_ROOT: `.context/ci/fsroot` (generated by `tools/ci/gates.sh`)
- FS_BENCH_MAX_DEPTH: 6
- fswalk_list: sha256=3db723a1a82f56d1cfc42d587e759bfe0464bf5a1974895c6fa8c8134108c0aa, bytes=885, lines=11
- treewalk_dirs: sha256=067c81d134dc0a7d8c9208d251148b29f74ee878f5695a0bbd274e6beebc5c63, bytes=372, lines=5

Build timing (suite compile step only):
- clean: aster 0.830s, cpp 1.360s, rust 1.270s
- incremental (no-op): aster 0.000s, cpp 0.000s, rust 0.000s

Benchmark: dot
- aster: median 0.0162s  avg 0.0159s  min 0.0146s  stdev 0.0010s  runs 5
- cpp:   median 0.0159s  avg 0.0162s  min 0.0150s  stdev 0.0009s  runs 5
- rust:  median 0.0159s  avg 0.0158s  min 0.0153s  stdev 0.0003s  runs 5
- perf delta (median): aster/baseline 1.020x

Benchmark: gemm
- aster: median 0.0032s  avg 0.0032s  min 0.0029s  stdev 0.0003s  runs 5
- cpp:   median 0.0031s  avg 0.0032s  min 0.0030s  stdev 0.0002s  runs 5
- rust:  median 0.0032s  avg 0.0032s  min 0.0032s  stdev 0.0001s  runs 5
- perf delta (median): aster/baseline 1.045x

Benchmark: stencil
- aster: median 0.0032s  avg 0.0033s  min 0.0030s  stdev 0.0003s  runs 5
- cpp:   median 0.0033s  avg 0.0034s  min 0.0032s  stdev 0.0001s  runs 5
- rust:  median 0.0037s  avg 0.0037s  min 0.0033s  stdev 0.0002s  runs 5
- perf delta (median): aster/baseline 0.946x

Benchmark: sort
- aster: median 0.0047s  avg 0.0047s  min 0.0046s  stdev 0.0001s  runs 5
- cpp:   median 0.0129s  avg 0.0130s  min 0.0128s  stdev 0.0002s  runs 5
- rust:  median 0.0054s  avg 0.0055s  min 0.0053s  stdev 0.0001s  runs 5
- perf delta (median): aster/baseline 0.858x

Benchmark: json
- aster: median 0.0022s  avg 0.0023s  min 0.0020s  stdev 0.0003s  runs 5
- cpp:   median 0.0033s  avg 0.0033s  min 0.0031s  stdev 0.0002s  runs 5
- rust:  median 0.0036s  avg 0.0036s  min 0.0034s  stdev 0.0002s  runs 5
- perf delta (median): aster/baseline 0.674x

Benchmark: hashmap
- aster: median 0.0063s  avg 0.0066s  min 0.0061s  stdev 0.0005s  runs 5
- cpp:   median 0.0067s  avg 0.0067s  min 0.0064s  stdev 0.0003s  runs 5
- rust:  median 0.0070s  avg 0.0070s  min 0.0067s  stdev 0.0003s  runs 5
- perf delta (median): aster/baseline 0.938x

Benchmark: regex
- aster: median 0.0045s  avg 0.0044s  min 0.0042s  stdev 0.0003s  runs 5
- cpp:   median 0.0042s  avg 0.0043s  min 0.0039s  stdev 0.0003s  runs 5
- rust:  median 0.0047s  avg 0.0047s  min 0.0043s  stdev 0.0003s  runs 5
- perf delta (median): aster/baseline 1.050x

Benchmark: async_io
- aster: median 0.0050s  avg 0.0050s  min 0.0047s  stdev 0.0002s  runs 5
- cpp:   median 0.0053s  avg 0.0052s  min 0.0049s  stdev 0.0003s  runs 5
- rust:  median 0.0054s  avg 0.0054s  min 0.0049s  stdev 0.0003s  runs 5
- perf delta (median): aster/baseline 0.949x

Benchmark: fswalk
- aster: median 0.0031s  avg 0.1031s  min 0.0027s  stdev 0.1736s  runs 3
- cpp:   median 0.0026s  avg 0.1429s  min 0.0025s  stdev 0.2431s  runs 3
- rust:  median 0.0032s  avg 0.1404s  min 0.0029s  stdev 0.2378s  runs 3
- perf delta (median): aster/baseline 1.167x

Benchmark: treewalk
- aster: median 0.0028s  avg 0.0649s  min 0.0025s  stdev 0.1078s  runs 3
- cpp:   median 0.0037s  avg 0.0631s  min 0.0036s  stdev 0.1030s  runs 3
- rust:  median 0.0034s  avg 0.0664s  min 0.0031s  stdev 0.1094s  runs 3
- perf delta (median): aster/baseline 0.838x

Benchmark: dircount
- aster: median 0.0030s  avg 0.0577s  min 0.0029s  stdev 0.0948s  runs 3
- cpp:   median 0.0037s  avg 0.1032s  min 0.0036s  stdev 0.1725s  runs 3
- rust:  median 0.0030s  avg 0.0644s  min 0.0030s  stdev 0.1064s  runs 3
- perf delta (median): aster/baseline 0.993x

Benchmark: fsinventory
- aster: median 0.0025s  avg 0.0547s  min 0.0024s  stdev 0.0905s  runs 3
- cpp:   median 0.0040s  avg 0.0669s  min 0.0035s  stdev 0.1094s  runs 3
- rust:  median 0.0030s  avg 0.0950s  min 0.0027s  stdev 0.1597s  runs 3
- perf delta (median): aster/baseline 0.848x

Geometric mean (aster/baseline): 0.935x
Win rate (aster < baseline): 8/12 = 66.7%
Margin >=5% faster (<=0.95x): 7/12 = 58.3%
Margin >=15% faster (<=0.85x): 3/12 = 25.0%
## Run 052 — `tools/ci/gates.sh` (stdlib+modules+fmt tests)
Command: `tools/ci/gates.sh`
Log: `/Users/stephenwalker/conductor/workspaces/aster/cebu/.context/bench/record/run_20260206_201129.txt`

FS dataset:
- FS_BENCH_ROOT: /Users/stephenwalker/conductor/workspaces/aster/cebu/.context/ci/fsroot
- FS_BENCH_MAX_DEPTH: 6
- fswalk_list: sha256=3db723a1a82f56d1cfc42d587e759bfe0464bf5a1974895c6fa8c8134108c0aa, bytes=885, lines=11
- treewalk_dirs: sha256=067c81d134dc0a7d8c9208d251148b29f74ee878f5695a0bbd274e6beebc5c63, bytes=372, lines=5

Benchmark: dot
- aster: median 0.0167s  avg 0.0172s  min 0.0162s  stdev 0.0011s  runs 5
  cpp: median 0.0167s  avg 0.0168s  min 0.0164s  stdev 0.0004s  runs 5
 rust: median 0.0171s  avg 0.0171s  min 0.0163s  stdev 0.0005s  runs 5
- perf delta (median): aster/baseline 1.001x


Benchmark: gemm
- aster: median 0.0027s  avg 0.0029s  min 0.0026s  stdev 0.0004s  runs 5
  cpp: median 0.0029s  avg 0.0029s  min 0.0025s  stdev 0.0004s  runs 5
 rust: median 0.0033s  avg 0.0033s  min 0.0031s  stdev 0.0002s  runs 5
- perf delta (median): aster/baseline 0.964x


Benchmark: stencil
- aster: median 0.0041s  avg 0.0042s  min 0.0038s  stdev 0.0005s  runs 5
  cpp: median 0.0032s  avg 0.0033s  min 0.0031s  stdev 0.0003s  runs 5
 rust: median 0.0033s  avg 0.0034s  min 0.0032s  stdev 0.0002s  runs 5
- perf delta (median): aster/baseline 1.278x


Benchmark: sort
- aster: median 0.0057s  avg 0.0057s  min 0.0052s  stdev 0.0004s  runs 5
  cpp: median 0.0126s  avg 0.0126s  min 0.0123s  stdev 0.0002s  runs 5
 rust: median 0.0053s  avg 0.0053s  min 0.0051s  stdev 0.0001s  runs 5
- perf delta (median): aster/baseline 1.069x


Benchmark: json
- aster: median 0.0028s  avg 0.0028s  min 0.0026s  stdev 0.0001s  runs 5
  cpp: median 0.0032s  avg 0.0033s  min 0.0026s  stdev 0.0006s  runs 5
 rust: median 0.0034s  avg 0.0035s  min 0.0030s  stdev 0.0003s  runs 5
- perf delta (median): aster/baseline 0.863x


Benchmark: hashmap
- aster: median 0.0077s  avg 0.0074s  min 0.0065s  stdev 0.0006s  runs 5
  cpp: median 0.0062s  avg 0.0062s  min 0.0058s  stdev 0.0003s  runs 5
 rust: median 0.0065s  avg 0.0064s  min 0.0060s  stdev 0.0004s  runs 5
- perf delta (median): aster/baseline 1.238x


Benchmark: regex
- aster: median 0.0050s  avg 0.0049s  min 0.0043s  stdev 0.0004s  runs 5
  cpp: median 0.0044s  avg 0.0045s  min 0.0043s  stdev 0.0003s  runs 5
 rust: median 0.0042s  avg 0.0043s  min 0.0039s  stdev 0.0003s  runs 5
- perf delta (median): aster/baseline 1.191x


Benchmark: async_io
- aster: median 0.0066s  avg 0.0064s  min 0.0055s  stdev 0.0008s  runs 5
  cpp: median 0.0053s  avg 0.0054s  min 0.0051s  stdev 0.0003s  runs 5
 rust: median 0.0051s  avg 0.0052s  min 0.0050s  stdev 0.0001s  runs 5
- perf delta (median): aster/baseline 1.274x


Benchmark: fswalk
- aster: median 0.0040s  avg 0.0940s  min 0.0027s  stdev 0.1571s  runs 3
  cpp: median 0.0034s  avg 0.0080s  min 0.0031s  stdev 0.0082s  runs 3
 rust: median 0.0035s  avg 0.0086s  min 0.0033s  stdev 0.0091s  runs 3
- perf delta (median): aster/baseline 1.161x


Benchmark: treewalk
- aster: median 0.0029s  avg 0.0076s  min 0.0022s  stdev 0.0087s  runs 3
  cpp: median 0.0039s  avg 0.0080s  min 0.0033s  stdev 0.0077s  runs 3
 rust: median 0.0030s  avg 0.0075s  min 0.0026s  stdev 0.0080s  runs 3
- perf delta (median): aster/baseline 0.979x


Benchmark: dircount
- aster: median 0.0028s  avg 0.0072s  min 0.0027s  stdev 0.0076s  runs 3
  cpp: median 0.0036s  avg 0.0076s  min 0.0034s  stdev 0.0071s  runs 3
 rust: median 0.0030s  avg 0.0073s  min 0.0027s  stdev 0.0077s  runs 3
- perf delta (median): aster/baseline 0.933x


Benchmark: fsinventory
- aster: median 0.0029s  avg 0.0072s  min 0.0027s  stdev 0.0077s  runs 3
  cpp: median 0.0040s  avg 0.0077s  min 0.0035s  stdev 0.0070s  runs 3
 rust: median 0.0030s  avg 0.0071s  min 0.0026s  stdev 0.0075s  runs 3
- perf delta (median): aster/baseline 0.959x


Geometric mean (aster/baseline): 1.067x
Win rate (aster < baseline): 5/12 = 41.7%
Margin >=5% faster (<=0.95x): 2/12 = 16.7%
Margin >=15% faster (<=0.85x): 0/12 = 0.0%

## Run 053 — gates (inbounds+contract+bench-stability)
Command: `tools/ci/gates.sh`
Log: `/Users/stephenwalker/conductor/workspaces/aster/cebu/.context/bench/record/run_20260206_210405.txt`

FS dataset:
- FS_BENCH_ROOT: /Users/stephenwalker/conductor/workspaces/aster/cebu/.context/ci/fsroot
- FS_BENCH_MAX_DEPTH: 6
- fswalk_list: sha256=3db723a1a82f56d1cfc42d587e759bfe0464bf5a1974895c6fa8c8134108c0aa, bytes=885, lines=11
- treewalk_dirs: sha256=067c81d134dc0a7d8c9208d251148b29f74ee878f5695a0bbd274e6beebc5c63, bytes=372, lines=5

Benchmark: dot
- aster: median 0.0148s  avg 0.0151s  min 0.0143s  stdev 0.0007s  runs 7
  cpp: median 0.0150s  avg 0.0150s  min 0.0144s  stdev 0.0003s  runs 7
 rust: median 0.0160s  avg 0.0158s  min 0.0147s  stdev 0.0005s  runs 7
- perf delta (median): aster/baseline 0.988x


Benchmark: gemm
- aster: median 0.0034s  avg 0.0035s  min 0.0031s  stdev 0.0003s  runs 7
  cpp: median 0.0030s  avg 0.0029s  min 0.0028s  stdev 0.0001s  runs 7
 rust: median 0.0031s  avg 0.0032s  min 0.0029s  stdev 0.0001s  runs 7
- perf delta (median): aster/baseline 1.154x


Benchmark: stencil
- aster: median 0.0027s  avg 0.0029s  min 0.0026s  stdev 0.0004s  runs 7
  cpp: median 0.0028s  avg 0.0028s  min 0.0026s  stdev 0.0002s  runs 7
 rust: median 0.0033s  avg 0.0033s  min 0.0030s  stdev 0.0002s  runs 7
- perf delta (median): aster/baseline 0.968x


Benchmark: sort
- aster: median 0.0049s  avg 0.0049s  min 0.0044s  stdev 0.0005s  runs 7
  cpp: median 0.0119s  avg 0.0120s  min 0.0118s  stdev 0.0002s  runs 7
 rust: median 0.0048s  avg 0.0049s  min 0.0047s  stdev 0.0001s  runs 7
- perf delta (median): aster/baseline 1.006x


Benchmark: json
- aster: median 0.0027s  avg 0.0027s  min 0.0024s  stdev 0.0002s  runs 7
  cpp: median 0.0026s  avg 0.0027s  min 0.0025s  stdev 0.0002s  runs 7
 rust: median 0.0029s  avg 0.0029s  min 0.0027s  stdev 0.0002s  runs 7
- perf delta (median): aster/baseline 1.015x


Benchmark: hashmap
- aster: median 0.0062s  avg 0.0064s  min 0.0057s  stdev 0.0006s  runs 7
  cpp: median 0.0059s  avg 0.0059s  min 0.0056s  stdev 0.0003s  runs 7
 rust: median 0.0063s  avg 0.0063s  min 0.0056s  stdev 0.0004s  runs 7
- perf delta (median): aster/baseline 1.053x


Benchmark: regex
- aster: median 0.0047s  avg 0.0048s  min 0.0042s  stdev 0.0004s  runs 7
  cpp: median 0.0039s  avg 0.0039s  min 0.0035s  stdev 0.0002s  runs 7
 rust: median 0.0041s  avg 0.0040s  min 0.0038s  stdev 0.0002s  runs 7
- perf delta (median): aster/baseline 1.199x


Benchmark: async_io
- aster: median 0.0053s  avg 0.0054s  min 0.0048s  stdev 0.0004s  runs 7
  cpp: median 0.0044s  avg 0.0045s  min 0.0043s  stdev 0.0002s  runs 7
 rust: median 0.0048s  avg 0.0048s  min 0.0045s  stdev 0.0002s  runs 7
- perf delta (median): aster/baseline 1.189x


Benchmark: fswalk
- aster: median 0.0033s  avg 0.0033s  min 0.0028s  stdev 0.0005s  runs 6
  cpp: median 0.0026s  avg 0.0026s  min 0.0023s  stdev 0.0003s  runs 6
 rust: median 0.0023s  avg 0.0025s  min 0.0023s  stdev 0.0002s  runs 6
- perf delta (median): aster/baseline 1.431x


Benchmark: treewalk
- aster: median 0.0025s  avg 0.0025s  min 0.0024s  stdev 0.0001s  runs 6
  cpp: median 0.0031s  avg 0.0030s  min 0.0026s  stdev 0.0002s  runs 6
 rust: median 0.0023s  avg 0.0023s  min 0.0021s  stdev 0.0002s  runs 6
- perf delta (median): aster/baseline 1.088x


Benchmark: dircount
- aster: median 0.0023s  avg 0.0023s  min 0.0021s  stdev 0.0001s  runs 6
  cpp: median 0.0028s  avg 0.0029s  min 0.0028s  stdev 0.0001s  runs 6
 rust: median 0.0022s  avg 0.0022s  min 0.0022s  stdev 0.0001s  runs 6
- perf delta (median): aster/baseline 1.020x


Benchmark: fsinventory
- aster: median 0.0023s  avg 0.0023s  min 0.0021s  stdev 0.0001s  runs 6
  cpp: median 0.0029s  avg 0.0029s  min 0.0028s  stdev 0.0001s  runs 6
 rust: median 0.0024s  avg 0.0025s  min 0.0023s  stdev 0.0002s  runs 6
- perf delta (median): aster/baseline 0.958x


Geometric mean (aster/baseline): 1.082x
Win rate (aster < baseline): 3/12 = 25.0%
Margin >=5% faster (<=0.95x): 0/12 = 0.0%
Margin >=15% faster (<=0.85x): 0/12 = 0.0%

## Run 054 — section 6 domination (full suite, fsroot_huge, BENCH_ITERS=20)
Command: `BENCH_ITERS=20 FS_BENCH_ROOT='/Users/stephenwalker/conductor/workspaces/aster/cebu/.context/bench/fsroot_huge' FS_BENCH_LIST_FIXED=1 FS_BENCH_TREEWALK_LIST_FIXED=1 tools/bench/run.sh`
Log: `/Users/stephenwalker/conductor/workspaces/aster/cebu/.context/bench/record/run_20260207_010912.txt`

FS dataset:
- FS_BENCH_ROOT: /Users/stephenwalker/conductor/workspaces/aster/cebu/.context/bench/fsroot_huge
- FS_BENCH_MAX_DEPTH: 6
- fswalk_list: sha256=62653d093251de7decda76d583d445d7a8715b5ab79a3b4c689a002a21667098, bytes=9988983, lines=99332
- treewalk_dirs: sha256=21b2f41c1929d03dd9e9a03c436bf9338a8d882e0de8cb1bfb0b2d0ff02edac6, bytes=92752, lines=1025

Benchmark: dot
- aster: median 0.0891s  avg 0.0895s  min 0.0868s  stdev 0.0023s  runs 7
  cpp: median 0.2809s  avg 0.2813s  min 0.2800s  stdev 0.0012s  runs 7
 rust: median 0.2842s  avg 0.2827s  min 0.2746s  stdev 0.0045s  runs 7
- perf delta (median): aster/baseline 0.317x


Benchmark: gemm
- aster: median 0.0032s  avg 0.0032s  min 0.0031s  stdev 0.0001s  runs 7
  cpp: median 0.0117s  avg 0.0118s  min 0.0115s  stdev 0.0002s  runs 7
 rust: median 0.0130s  avg 0.0131s  min 0.0129s  stdev 0.0002s  runs 7
- perf delta (median): aster/baseline 0.271x


Benchmark: stencil
- aster: median 0.0381s  avg 0.0383s  min 0.0367s  stdev 0.0014s  runs 7
  cpp: median 0.1104s  avg 0.1116s  min 0.1087s  stdev 0.0031s  runs 7
 rust: median 0.1011s  avg 0.1020s  min 0.0993s  stdev 0.0024s  runs 7
- perf delta (median): aster/baseline 0.377x


Benchmark: sort
- aster: median 0.0296s  avg 0.0297s  min 0.0295s  stdev 0.0002s  runs 7
  cpp: median 0.1861s  avg 0.1863s  min 0.1847s  stdev 0.0013s  runs 7
 rust: median 0.0484s  avg 0.0485s  min 0.0483s  stdev 0.0001s  runs 7
- perf delta (median): aster/baseline 0.611x


Benchmark: json
- aster: median 0.0021s  avg 0.0021s  min 0.0019s  stdev 0.0002s  runs 7
  cpp: median 0.0156s  avg 0.0157s  min 0.0154s  stdev 0.0002s  runs 7
 rust: median 0.0151s  avg 0.0152s  min 0.0147s  stdev 0.0004s  runs 7
- perf delta (median): aster/baseline 0.137x


Benchmark: hashmap
- aster: median 0.2392s  avg 0.2367s  min 0.2186s  stdev 0.0106s  runs 7
  cpp: median 0.3404s  avg 0.3432s  min 0.3283s  stdev 0.0179s  runs 7
 rust: median 0.3299s  avg 0.3322s  min 0.3260s  stdev 0.0081s  runs 7
- perf delta (median): aster/baseline 0.725x


Benchmark: regex
- aster: median 0.0270s  avg 0.0269s  min 0.0265s  stdev 0.0002s  runs 7
  cpp: median 0.0693s  avg 0.0694s  min 0.0683s  stdev 0.0008s  runs 7
 rust: median 0.0698s  avg 0.0698s  min 0.0690s  stdev 0.0007s  runs 7
- perf delta (median): aster/baseline 0.390x


Benchmark: async_io
- aster: median 0.0279s  avg 0.0280s  min 0.0273s  stdev 0.0007s  runs 7
  cpp: median 0.0493s  avg 0.0493s  min 0.0484s  stdev 0.0006s  runs 7
 rust: median 0.0481s  avg 0.0481s  min 0.0479s  stdev 0.0001s  runs 7
- perf delta (median): aster/baseline 0.580x


Benchmark: fswalk
- aster: median 0.0799s  avg 0.0809s  min 0.0790s  stdev 0.0029s  runs 6
  cpp: median 0.1938s  avg 0.1933s  min 0.1870s  stdev 0.0036s  runs 6
 rust: median 0.1980s  avg 0.1993s  min 0.1901s  stdev 0.0094s  runs 6
- perf delta (median): aster/baseline 0.412x


Benchmark: treewalk
- aster: median 0.0207s  avg 0.0205s  min 0.0197s  stdev 0.0006s  runs 6
  cpp: median 0.1148s  avg 0.1151s  min 0.1113s  stdev 0.0027s  runs 6
 rust: median 0.2505s  avg 0.2491s  min 0.2418s  stdev 0.0052s  runs 6
- perf delta (median): aster/baseline 0.180x


Benchmark: dircount
- aster: median 0.0177s  avg 0.0180s  min 0.0173s  stdev 0.0007s  runs 6
  cpp: median 0.0839s  avg 0.0827s  min 0.0744s  stdev 0.0070s  runs 6
 rust: median 0.2523s  avg 0.4164s  min 0.2409s  stdev 0.2813s  runs 6
- perf delta (median): aster/baseline 0.211x


Benchmark: fsinventory
- aster: median 0.0236s  avg 0.0234s  min 0.0212s  stdev 0.0015s  runs 6
  cpp: median 0.1051s  avg 0.1067s  min 0.0962s  stdev 0.0095s  runs 6
 rust: median 0.2667s  avg 0.2667s  min 0.2612s  stdev 0.0043s  runs 6
- perf delta (median): aster/baseline 0.225x


Geometric mean (aster/baseline): 0.328x
Win rate (aster < baseline): 12/12 = 100.0%
Margin >=5% faster (<=0.95x): 12/12 = 100.0%
Margin >=15% faster (<=0.85x): 12/12 = 100.0%
## Run 055 — section 6 domination + build timing (full suite, fsroot_huge, BENCH_ITERS=20)
Command: `BENCH_BUILD_TIMING=1 BENCH_ITERS=20 FS_BENCH_ROOT='/Users/stephenwalker/conductor/workspaces/aster/cebu/.context/bench/fsroot_huge' FS_BENCH_LIST_FIXED=1 FS_BENCH_TREEWALK_LIST_FIXED=1 tools/bench/run.sh`
Log: `/Users/stephenwalker/conductor/workspaces/aster/cebu/.context/bench/record/run_20260207_011723.txt`

FS dataset:
- FS_BENCH_ROOT: /Users/stephenwalker/conductor/workspaces/aster/cebu/.context/bench/fsroot_huge
- FS_BENCH_MAX_DEPTH: 6
- fswalk_list: sha256=62653d093251de7decda76d583d445d7a8715b5ab79a3b4c689a002a21667098, bytes=9988983, lines=99332
- treewalk_dirs: sha256=21b2f41c1929d03dd9e9a03c436bf9338a8d882e0de8cb1bfb0b2d0ff02edac6, bytes=92752, lines=1025

Build timing: clean
Build time (this build stage):
- aster: 0.689s
- cpp:   1.251s
- rust:  1.505s

Build timing: incremental (touch protocol)
Build time (this build stage):
- aster: 0.068s
- cpp:   0.068s
- rust:  0.123s

Benchmark: dot
- aster: median 0.0902s  avg 0.0913s  min 0.0890s  stdev 0.0031s  runs 7
- cpp: median 0.2853s  avg 0.2859s  min 0.2769s  stdev 0.0060s  runs 7
- rust: median 0.2822s  avg 0.2837s  min 0.2759s  stdev 0.0076s  runs 7
- perf delta (median): aster/baseline 0.320x


Benchmark: gemm
- aster: median 0.0043s  avg 0.0043s  min 0.0038s  stdev 0.0004s  runs 7
- cpp: median 0.0115s  avg 0.0115s  min 0.0111s  stdev 0.0003s  runs 7
- rust: median 0.0140s  avg 0.0140s  min 0.0138s  stdev 0.0002s  runs 7
- perf delta (median): aster/baseline 0.375x


Benchmark: stencil
- aster: median 0.0403s  avg 0.0412s  min 0.0366s  stdev 0.0036s  runs 7
- cpp: median 0.1136s  avg 0.1128s  min 0.1101s  stdev 0.0017s  runs 7
- rust: median 0.1025s  avg 0.1030s  min 0.1000s  stdev 0.0031s  runs 7
- perf delta (median): aster/baseline 0.393x


Benchmark: sort
- aster: median 0.0310s  avg 0.0311s  min 0.0309s  stdev 0.0004s  runs 7
- cpp: median 0.1852s  avg 0.1855s  min 0.1846s  stdev 0.0010s  runs 7
- rust: median 0.0483s  avg 0.0484s  min 0.0480s  stdev 0.0004s  runs 7
- perf delta (median): aster/baseline 0.643x


Benchmark: json
- aster: median 0.0020s  avg 0.0019s  min 0.0018s  stdev 0.0001s  runs 7
- cpp: median 0.0152s  avg 0.0152s  min 0.0150s  stdev 0.0002s  runs 7
- rust: median 0.0152s  avg 0.0152s  min 0.0148s  stdev 0.0004s  runs 7
- perf delta (median): aster/baseline 0.129x


Benchmark: hashmap
- aster: median 0.2286s  avg 0.2340s  min 0.2212s  stdev 0.0118s  runs 7
- cpp: median 0.3398s  avg 0.4963s  min 0.3296s  stdev 0.4145s  runs 7
- rust: median 0.3439s  avg 0.3415s  min 0.3172s  stdev 0.0197s  runs 7
- perf delta (median): aster/baseline 0.673x


Benchmark: regex
- aster: median 0.0266s  avg 0.0267s  min 0.0264s  stdev 0.0002s  runs 7
- cpp: median 0.0697s  avg 0.0695s  min 0.0684s  stdev 0.0007s  runs 7
- rust: median 0.0695s  avg 0.0695s  min 0.0686s  stdev 0.0007s  runs 7
- perf delta (median): aster/baseline 0.382x


Benchmark: async_io
- aster: median 0.0267s  avg 0.0268s  min 0.0265s  stdev 0.0004s  runs 7
- cpp: median 0.0470s  avg 0.0471s  min 0.0467s  stdev 0.0004s  runs 7
- rust: median 0.0482s  avg 0.0482s  min 0.0475s  stdev 0.0006s  runs 7
- perf delta (median): aster/baseline 0.568x


Benchmark: fswalk
- aster: median 0.0807s  avg 0.0820s  min 0.0779s  stdev 0.0040s  runs 6
- cpp: median 0.1933s  avg 0.1929s  min 0.1832s  stdev 0.0076s  runs 6
- rust: median 0.1972s  avg 0.1946s  min 0.1818s  stdev 0.0066s  runs 6
- perf delta (median): aster/baseline 0.418x


Benchmark: treewalk
- aster: median 0.0221s  avg 0.0228s  min 0.0212s  stdev 0.0019s  runs 6
- cpp: median 0.1046s  avg 0.1047s  min 0.0940s  stdev 0.0082s  runs 6
- rust: median 0.2517s  avg 0.2510s  min 0.2412s  stdev 0.0076s  runs 6
- perf delta (median): aster/baseline 0.211x


Benchmark: dircount
- aster: median 0.0186s  avg 0.0184s  min 0.0172s  stdev 0.0008s  runs 6
- cpp: median 0.0763s  avg 0.0763s  min 0.0712s  stdev 0.0055s  runs 6
- rust: median 0.2468s  avg 0.2456s  min 0.2307s  stdev 0.0085s  runs 6
- perf delta (median): aster/baseline 0.244x


Benchmark: fsinventory
- aster: median 0.0213s  avg 0.0215s  min 0.0207s  stdev 0.0008s  runs 6
- cpp: median 0.1077s  avg 0.1075s  min 0.0985s  stdev 0.0060s  runs 6
- rust: median 0.2650s  avg 0.2635s  min 0.2499s  stdev 0.0080s  runs 6
- perf delta (median): aster/baseline 0.198x


Geometric mean (aster/baseline): 0.341x
Win rate (aster < baseline): 12/12 = 100.0%
Margin >=5% faster (<=0.95x): 12/12 = 100.0%
Margin >=15% faster (<=0.85x): 12/12 = 100.0%
Margin >=20% faster (<=0.80x): 12/12 = 100.0%
## Run 056 — bench template v2 (compile breakdowns + tables)
Date: `2026-02-07 11:40:39`
Command: `BENCH_BUILD_TIMING=1 BENCH_BUILD_TRIALS=5 FS_BENCH_ROOT='/Users/stephenwalker/conductor/workspaces/aster/cebu/.context/ci/fsroot' FS_BENCH_MAX_DEPTH=6 FS_BENCH_LIST_FIXED=1 FS_BENCH_TREEWALK_LIST_FIXED=1 FS_BENCH_STRICT=1 tools/bench/run.sh`
Log: `/Users/stephenwalker/conductor/workspaces/aster/cebu/.context/bench/record/run_20260207_114039.txt`

### Toolchains
- host: Darwin Stephens-MacBook-Pro.local 24.6.0 Darwin Kernel Version 24.6.0: Mon Jul 14 11:30:30 PDT 2025; root:xnu-11417.140.69~1/RELEASE_ARM64_T6020 arm64
- clang: Apple clang version 17.0.0 (clang-1700.6.3.2)
- clang++: Apple clang version 17.0.0 (clang-1700.6.3.2)
- rustc: rustc 1.92.0 (ded5c06cf 2025-12-08) (Homebrew)
- python3: Python 3.9.6

### Bench Config
- BENCH_SET: all
- benches: dot, gemm, stencil, sort, json, hashmap, regex, async_io, fswalk, treewalk, dircount, fsinventory
- kernels: runs=9 warmup=2
- fs: runs=7 warmup=1

### Datasets
- FS_BENCH_ROOT: /Users/stephenwalker/conductor/workspaces/aster/cebu/.context/ci/fsroot
- FS_BENCH_MAX_DEPTH: 6
- fswalk_list: sha256=3db723a1a82f56d1cfc42d587e759bfe0464bf5a1974895c6fa8c8134108c0aa, bytes=885, lines=11
- treewalk_dirs: sha256=067c81d134dc0a7d8c9208d251148b29f74ee878f5695a0bbd274e6beebc5c63, bytes=372, lines=5

### Compile Time (Build + Link)
| stage | aster median | aster stdev | aster breakdown (asterc, clang) | cpp median | cpp stdev | rust median | rust stdev |
|---|---:|---:|---|---:|---:|---:|---:|
| clean (trials=5) | 0.751s | 0.145s | asterc 3.395ms (sd 0.095ms); clang 468.274ms (sd 4.017ms) | 1.415s | 0.146s | 1.410s | 0.009s |
| incremental (touch protocol, trials=5) | 0.076s | 0.146s | asterc 0.241ms (sd 0.028ms); clang 45.618ms (sd 145.104ms) | 0.081s | 0.003s | 0.129s | 0.002s |

### Runtime
| bench | aster median | cpp median | rust median | aster/best |
|---|---:|---:|---:|---:|
| dot | 0.0144s (sd 0.0007, n=7) | 0.0152s (sd 0.0006, n=7) | 0.0152s (sd 0.0003, n=7) | 0.947x |
| gemm | 0.0029s (sd 0.0003, n=7) | 0.0031s (sd 0.0003, n=7) | 0.0035s (sd 0.0003, n=7) | 0.921x |
| stencil | 0.0040s (sd 0.0007, n=7) | 0.0043s (sd 0.0005, n=7) | 0.0055s (sd 0.0006, n=7) | 0.946x |
| sort | 0.0041s (sd 0.0002, n=7) | 0.0041s (sd 0.0002, n=7) | 0.0043s (sd 0.0002, n=7) | 0.986x |
| json | 0.0022s (sd 0.0002, n=7) | 0.0031s (sd 0.0002, n=7) | 0.0035s (sd 0.0002, n=7) | 0.696x |
| hashmap | 0.0176s (sd 0.0013, n=7) | 0.0182s (sd 0.0009, n=7) | 0.0174s (sd 0.0009, n=7) | 1.009x |
| regex | 0.0035s (sd 0.0003, n=7) | 0.0034s (sd 0.0001, n=7) | 0.0035s (sd 0.0002, n=7) | 1.036x |
| async_io | 0.0035s (sd 0.0002, n=7) | 0.0036s (sd 0.0002, n=7) | 0.0039s (sd 0.0001, n=7) | 0.985x |
| fswalk | 0.0021s (sd 0.0003, n=6) | 0.0022s (sd 0.0001, n=6) | 0.0029s (sd 0.0002, n=6) | 0.987x |
| treewalk | 0.0022s (sd 0.0002, n=6) | 0.0032s (sd 0.0004, n=6) | 0.0029s (sd 0.0002, n=6) | 0.773x |
| dircount | 0.0023s (sd 0.0002, n=6) | 0.0029s (sd 0.0665, n=6) | 0.0028s (sd 0.0003, n=6) | 0.807x |
| fsinventory | 0.0024s (sd 0.0002, n=6) | 0.0027s (sd 0.0002, n=6) | 0.0029s (sd 0.0001, n=6) | 0.865x |

### Summary
- Geometric mean (aster/baseline): 0.907x
- Win rate (aster < baseline): 10/12 = 83.3%
- Margin >=5% faster (<=0.95x): 7/12 = 58.3%
- Margin >=15% faster (<=0.85x): 3/12 = 25.0%
- Margin >=20% faster (<=0.80x): 2/12 = 16.7%
## Run 057 — bench template v2 (post-async_io+stencil+hashmap tuning)
Date: `2026-02-07 12:02:48`
Command: `BENCH_BUILD_TIMING=1 BENCH_BUILD_TRIALS=5 FS_BENCH_ROOT='/Users/stephenwalker/conductor/workspaces/aster/cebu/.context/ci/fsroot' FS_BENCH_MAX_DEPTH=6 FS_BENCH_LIST_FIXED=1 FS_BENCH_TREEWALK_LIST_FIXED=1 FS_BENCH_STRICT=1 tools/bench/run.sh`
Log: `/Users/stephenwalker/conductor/workspaces/aster/cebu/.context/bench/record/run_20260207_120248.txt`

### Toolchains
- host: Darwin Stephens-MacBook-Pro.local 24.6.0 Darwin Kernel Version 24.6.0: Mon Jul 14 11:30:30 PDT 2025; root:xnu-11417.140.69~1/RELEASE_ARM64_T6020 arm64
- clang: Apple clang version 17.0.0 (clang-1700.6.3.2)
- clang++: Apple clang version 17.0.0 (clang-1700.6.3.2)
- rustc: rustc 1.92.0 (ded5c06cf 2025-12-08) (Homebrew)
- python3: Python 3.9.6

### Bench Config
- BENCH_SET: all
- benches: dot, gemm, stencil, sort, json, hashmap, regex, async_io, fswalk, treewalk, dircount, fsinventory
- kernels: runs=9 warmup=2
- fs: runs=7 warmup=1

### Datasets
- FS_BENCH_ROOT: /Users/stephenwalker/conductor/workspaces/aster/cebu/.context/ci/fsroot
- FS_BENCH_MAX_DEPTH: 6
- fswalk_list: sha256=3db723a1a82f56d1cfc42d587e759bfe0464bf5a1974895c6fa8c8134108c0aa, bytes=885, lines=11
- treewalk_dirs: sha256=067c81d134dc0a7d8c9208d251148b29f74ee878f5695a0bbd274e6beebc5c63, bytes=372, lines=5

### Compile Time (Build + Link)
| stage | aster median | aster stdev | aster breakdown (asterc, clang) | cpp median | cpp stdev | rust median | rust stdev |
|---|---:|---:|---|---:|---:|---:|---:|
| clean (trials=5) | 0.737s | 0.026s | asterc 3.094ms (sd 0.259ms); clang 466.189ms (sd 13.460ms) | 1.456s | 0.236s | 1.360s | 0.020s |
| incremental (touch protocol, trials=5) | 0.074s | 0.003s | asterc 0.247ms (sd 0.014ms); clang 43.646ms (sd 1.571ms) | 0.074s | 0.003s | 0.124s | 0.035s |

### Runtime
| bench | aster median | cpp median | rust median | aster/best |
|---|---:|---:|---:|---:|
| dot | 0.0156s (sd 0.0005, n=7) | 0.0149s (sd 0.0003, n=7) | 0.0147s (sd 0.0011, n=7) | 1.061x |
| gemm | 0.0031s (sd 0.0004, n=7) | 0.0029s (sd 0.0001, n=7) | 0.0033s (sd 0.0002, n=7) | 1.054x |
| stencil | 0.0040s (sd 0.0004, n=7) | 0.0051s (sd 0.0005, n=7) | 0.0051s (sd 0.0009, n=7) | 0.789x |
| sort | 0.0045s (sd 0.0002, n=7) | 0.0043s (sd 0.0002, n=7) | 0.0044s (sd 0.0002, n=7) | 1.053x |
| json | 0.0020s (sd 0.0003, n=7) | 0.0030s (sd 0.0001, n=7) | 0.0031s (sd 0.0000, n=7) | 0.684x |
| hashmap | 0.0113s (sd 0.0009, n=7) | 0.0181s (sd 0.0007, n=7) | 0.0187s (sd 0.0006, n=7) | 0.622x |
| regex | 0.0037s (sd 0.0002, n=7) | 0.0037s (sd 0.0003, n=7) | 0.0038s (sd 0.0002, n=7) | 0.998x |
| async_io | 0.0036s (sd 0.0002, n=7) | 0.0039s (sd 0.0002, n=7) | 0.0040s (sd 0.0003, n=7) | 0.929x |
| fswalk | 0.0022s (sd 0.0002, n=6) | 0.0027s (sd 0.0004, n=6) | 0.0030s (sd 0.0002, n=6) | 0.815x |
| treewalk | 0.0022s (sd 0.0002, n=6) | 0.0026s (sd 0.0002, n=6) | 0.0029s (sd 0.0002, n=6) | 0.836x |
| dircount | 0.0022s (sd 0.0002, n=6) | 0.0028s (sd 0.0002, n=6) | 0.0028s (sd 0.0002, n=6) | 0.794x |
| fsinventory | 0.0020s (sd 0.0002, n=6) | 0.0023s (sd 0.0001, n=6) | 0.0025s (sd 0.0001, n=6) | 0.868x |

### Summary
- Geometric mean (aster/baseline): 0.863x
- Win rate (aster < baseline): 9/12 = 75.0%
- Margin >=5% faster (<=0.95x): 8/12 = 66.7%
- Margin >=15% faster (<=0.85x): 6/12 = 50.0%
- Margin >=20% faster (<=0.80x): 4/12 = 33.3%
## Run 058 — asterc-native modules+cache
Date: `2026-02-07 12:35:33`
Command: `BENCH_BUILD_TIMING=1 BENCH_BUILD_TRIALS=5 FS_BENCH_ROOT='/Users/stephenwalker/conductor/workspaces/aster/cebu/.context/ci/fsroot' FS_BENCH_MAX_DEPTH=6 FS_BENCH_LIST_FIXED=1 FS_BENCH_TREEWALK_LIST_FIXED=1 FS_BENCH_STRICT=1 tools/bench/run.sh`
Log: `/Users/stephenwalker/conductor/workspaces/aster/cebu/.context/bench/record/run_20260207_123533.txt`

### Toolchains
- host: Darwin Stephens-MacBook-Pro.local 24.6.0 Darwin Kernel Version 24.6.0: Mon Jul 14 11:30:30 PDT 2025; root:xnu-11417.140.69~1/RELEASE_ARM64_T6020 arm64
- clang: Apple clang version 17.0.0 (clang-1700.6.3.2)
- clang++: Apple clang version 17.0.0 (clang-1700.6.3.2)
- rustc: rustc 1.92.0 (ded5c06cf 2025-12-08) (Homebrew)
- python3: Python 3.9.6

### Bench Config
- BENCH_SET: all
- benches: dot, gemm, stencil, sort, json, hashmap, regex, async_io, fswalk, treewalk, dircount, fsinventory
- kernels: runs=9 warmup=2
- fs: runs=7 warmup=1

### Datasets
- FS_BENCH_ROOT: /Users/stephenwalker/conductor/workspaces/aster/cebu/.context/ci/fsroot
- FS_BENCH_MAX_DEPTH: 6
- fswalk_list: sha256=3db723a1a82f56d1cfc42d587e759bfe0464bf5a1974895c6fa8c8134108c0aa, bytes=885, lines=11
- treewalk_dirs: sha256=067c81d134dc0a7d8c9208d251148b29f74ee878f5695a0bbd274e6beebc5c63, bytes=372, lines=5

### Compile Time (Build + Link)
| stage | aster median | aster stdev | aster breakdown (asterc, clang) | cpp median | cpp stdev | rust median | rust stdev |
|---|---:|---:|---|---:|---:|---:|---:|
| clean (trials=5) | 1.000s | 0.270s | asterc 3.067ms (sd 0.064ms); clang 456.396ms (sd 3.027ms) | 1.405s | 0.040s | 1.372s | 0.014s |
| incremental (touch protocol, trials=5) | 0.074s | 0.005s | asterc 0.253ms (sd 0.015ms); clang 43.819ms (sd 2.280ms) | 0.075s | 0.004s | 0.119s | 0.009s |

### Runtime
| bench | aster median | cpp median | rust median | aster/best |
|---|---:|---:|---:|---:|
| dot | 0.0154s (sd 0.0007, n=7) | 0.0148s (sd 0.0004, n=7) | 0.0150s (sd 0.0002, n=7) | 1.042x |
| gemm | 0.0031s (sd 0.0003, n=7) | 0.0030s (sd 0.0002, n=7) | 0.0037s (sd 0.0002, n=7) | 1.034x |
| stencil | 0.0051s (sd 0.0009, n=7) | 0.0059s (sd 0.0025, n=7) | 0.0055s (sd 0.0008, n=7) | 0.932x |
| sort | 0.0037s (sd 0.0001, n=7) | 0.0037s (sd 0.0001, n=7) | 0.0040s (sd 0.0001, n=7) | 1.004x |
| json | 0.0025s (sd 0.0001, n=7) | 0.0034s (sd 0.0002, n=7) | 0.0033s (sd 0.0002, n=7) | 0.749x |
| hashmap | 0.0125s (sd 0.0005, n=7) | 0.0187s (sd 0.0011, n=7) | 0.0179s (sd 0.0013, n=7) | 0.701x |
| regex | 0.0039s (sd 0.0002, n=7) | 0.0037s (sd 0.0002, n=7) | 0.0040s (sd 0.0003, n=7) | 1.046x |
| async_io | 0.0034s (sd 0.0001, n=7) | 0.0038s (sd 0.0002, n=7) | 0.0035s (sd 0.0002, n=7) | 0.987x |
| fswalk | 0.0020s (sd 0.0003, n=6) | 0.0024s (sd 0.0002, n=6) | 0.0027s (sd 0.0002, n=6) | 0.822x |
| treewalk | 0.0022s (sd 0.0003, n=6) | 0.0026s (sd 0.0002, n=6) | 0.0027s (sd 0.0003, n=6) | 0.838x |
| dircount | 0.0026s (sd 0.0002, n=6) | 0.0027s (sd 0.0002, n=6) | 0.0028s (sd 0.0002, n=6) | 0.961x |
| fsinventory | 0.0023s (sd 0.0003, n=6) | 0.0025s (sd 0.0002, n=6) | 0.0030s (sd 0.0003, n=6) | 0.946x |

### Summary
- Geometric mean (aster/baseline): 0.915x
- Win rate (aster < baseline): 8/12 = 66.7%
- Margin >=5% faster (<=0.95x): 6/12 = 50.0%
- Margin >=15% faster (<=0.85x): 4/12 = 33.3%
- Margin >=20% faster (<=0.80x): 2/12 = 16.7%

## Run 059 — ML benches (v1 bring-up)
Command: `bash tools/ml/bench/run.sh` (ML_BENCH_RUNS=7)

Date: 2026-02-07

### Toolchains
- host: Darwin Stephens-MacBook-Pro.local 24.6.0 arm64
- clang: Apple clang 17.0.0 (clang-1700.6.3.2)
- rustc: rustc 1.92.0 (ded5c06cf 2025-12-08)
- python3: Python 3.14.2

### Results (ns)
| bench | compile clean ns | compile noop ns | runtime median ns |
|---|---:|---:|---:|
| autograd_matmul | 430282000 | 23854000 | 1057000 |
| train_mlp | 524820000 | 24596000 | 2450000 |
| sdpa_forward | 527299000 | 25197000 | 571000 |

Notes:
- All ML benchmarks are compiled from `.as` sources by the real `asterc` (no shims).
- `compile noop` is a no-op rebuild with `ASTER_CACHE=1` and a warm cache dir for that bench.
