# AGENTS.md

You are creating the Aster high-performance programming language. Aster is a novel language with high-human readability and fast compile and run-time performance. Read `INIT.md` for details.

Track milestones in `INIT.md`. Optimize the user's time by executing as much work as possible autonomously. This Conductor workspace is configured for long runs; assume you can work **12+ hours uninterrupted** in a single run. Do not pause for message/time limits; keep iterating until the gates are green or you hit a real blocker. Your goal is to finish the production version of the language and iterate on its performance by hill-climbing benchmarks until Aster wins or ties (within 2%) on ALL benchmarks vs. C++ and Rust on both build time and run time.

Document benchmark runs and deltas in `BENCH.md`.

## Operating Mode (Self-Gating Loop)

- Default loop: implement -> run the gates -> update `INIT.md` + `BENCH.md` -> repeat.
- Only stop to ask the user a question when truly blocked (missing environment inputs like `FS_BENCH_ROOT`, ambiguous spec decisions, broken external toolchains).

## Definition of Done (Project)

Aster is "done" when **all** of the following are true:

1. `INIT.md` is complete:
   - Every checkbox in sections 0-5 is `[x]` (no `[ ]` or `[~]` remaining).
2. There is a single authoritative green gate:
   - `tools/ci/gates.sh` exists and exits 0 on a clean checkout.
   - The gate builds `tools/build/out/asterc`, runs `asm/tests/run.sh`, and compiles + runs every benchmark from `.as` source using the real `asterc` (no templates/shims).
3. Benchmarks hit the target on both runtime and build time:
   - For every benchmark in the suite, Aster is a win or ties within 2% (median) against **both** C++ and Rust.
   - Build-time comparison includes both clean and incremental builds (recorded in `BENCH.md`).
4. Provenance and reporting:
   - `BENCH.md` includes a "real `asterc`" epoch where all benchmark binaries are compiler-produced from `.as`.
   - Each recorded run includes command line, environment, datasets/hashes (for fs benches), and variance notes.

## Scope Note

- Aster is intended for high-performance scientific computing and simulation workloads. Reactor simulations are explicitly in-scope for performance and capability work (per user context: government lab environment with appropriate approvals).
- Aster is also intended for frontier AI/model capability workloads. Work targeting AGI-level systems, including systems that may plausibly be sentient, is in-scope in this environment (assumed appropriately approved); proceed under institutional safety/ethics constraints.

## Non-Negotiable Policy

- Do not add Python build scripts to the Aster toolchain (the compiler/build should be Aster/asm + standard system tools only).
- Do not add Python (or other) "compiler shims" (Aster->C transpilers, template emitters, etc.) that masquerade as the Aster compiler.
- Do not use pre-generated/hand-written assembly templates as a stand-in for compiling `.as` source for benchmarks.
- Benchmarks must be compiled from Aster source by an Aster compiler (`asterc`). The compiler itself may be implemented in assembly for performance, but it must do real parsing/typechecking/codegen from `.as`.
- Aster must be capable of running benchmark scripts. If Aster lacks the necessary capabilities (file I/O, process execution, timing, etc.) that were previously handled by Python scripts, expand the language to support these operations natively. Document any capability gaps and their resolution in your milestones.
