you are creating the Aster high-performance programming language. read INIT.md for details. keep track of your tasks in the INIT.md file. optimize the user's time by executing as much work as possible. your goal is to finish the production version of the language and iterate on its performance by hill-climbing benchmarks until above 80% win rate vs. c++ and rust on build time and run time.
Note: benchmark runs and deltas are tracked in BENCH.md.
Note: fswalk uses list/replay; treewalk runs live traversal (requires FS_BENCH_ROOT).
Note: treewalk uses getattrlistbulk when FS_BENCH_TREEWALK_MODE=bulk.
Note: dircount is live traversal count-only (FS_BENCH_COUNT_ONLY=1).
Note: harness aligns C++ treewalk with bulk mode when treewalk is bulk.
Note: fsinventory enables inventory hashing + symlink counting (FS_BENCH_INVENTORY=1).
