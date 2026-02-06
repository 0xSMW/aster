# Aster LeetCode Hard Conformance Suite (15 Native Aster Tests)

## Executive Summary
The goal is to add a language-level conformance suite that consists of 15 classic LeetCode "Hard" problems implemented natively in Aster (`.as`). These are not benchmarks; they are correctness and capability gates that force Aster's compiler/runtime/stdlib to support real algorithmic workloads (data structures, recursion, dynamic allocation, and string processing). The suite should run as part of the existing green gate: `tools/ci/gates.sh` already runs `aster/tests/run.sh`, so the simplest integration is to extend `aster/tests/run.sh` to also compile+run `aster/tests/leetcode/*.as`.

Instead of migrating CURSED syntax/tests, we use the LeetCode problem set as the source of truth and implement each solution and its checks in Aster. Each test program should be deterministic, contain multiple test cases (including edge cases), and return non-zero on failure. Where outputs are complex (boards/strings/lists), tests should validate the result structurally (length, element-by-element equality, invariants) and/or compare against fixed expected outputs for small inputs.

This suite intentionally drives missing capabilities: basic containers (vec/stack/deque/heap/hash set), pointer-based data structures (lists/trees), and baseline string utilities. It also provides a practical north star for future stdlib/imports work: once module imports exist, shared helpers can be factored out of individual test files.

## Scope Reviewed
- Aster gate + test harness:
  - `tools/ci/gates.sh`
  - `aster/tests/run.sh`
  - `aster/tests/pass/*`, `aster/tests/fail/*`
- Aster "systems style" Aster programs (structs/pointers/FFI):
  - `aster/bench/fswalk/fswalk.as`
- CURSED repo as reference for categories (not to be ported):
  - `.context/vendor/cursed/test_suite/leetcode_comprehensive_suite/*`
  - `.context/vendor/cursed/test_suite/test_programs/leetcode/*`

## Current Behavior Map

### Existing Aster Test Harness
- `aster/tests/run.sh` compiles and runs:
  - `aster/tests/pass/*.as` (must compile and exit 0)
  - `aster/tests/fail/*.as` (must fail to compile)
- `tools/ci/gates.sh` runs `aster/tests/run.sh` (so adding new Aster tests there automatically tightens the main gate).

### Proposed Integration Point
- Add a new directory: `aster/tests/leetcode/`.
- Extend `aster/tests/run.sh` with a third loop (like pass tests) over `aster/tests/leetcode/*.as`.
  - Each leetcode test is expected to compile and exit 0.
  - Stdout/stderr should be captured in `$ASTER_TEST_OUT_DIR` like existing tests.

## Proposed Suite: 15 Classic LeetCode Hard Problems
Each bullet is intended to become one Aster test file `aster/tests/leetcode/<id>_<slug>.as`.

1. `10` Regular Expression Matching
   - Drives: string indexing, DP table/rolling DP, boolean logic.
   - Tests: canonical examples for `.` and `*` plus empty-string edges.

2. `23` Merge k Sorted Lists
   - Drives: structs + pointers, heap/priority-queue, list traversal, memory management.
   - Tests: k=0, k=1, mixed empty lists, small known merge result.

3. `25` Reverse Nodes in k-Group
   - Drives: pointer manipulation, loop invariants, list construction.
   - Tests: k=1, k>len, k divides length, k does not divide length.

4. `32` Longest Valid Parentheses
   - Drives: stack of indices, string scanning.
   - Tests: "(()", ")()())", "", "()(())".

5. `37` Sudoku Solver
   - Drives: backtracking recursion, 2D array board, bitmask constraints.
   - Tests: one fixed puzzle with known solution; validate solved board is consistent.

6. `41` First Missing Positive
   - Drives: in-place array mutation, bounds checks, O(n) scan.
   - Tests: [1,2,0], [3,4,-1,1], [7,8,9,11,12], [1].

7. `42` Trapping Rain Water
   - Drives: two-pointer scan or stack method, integer arithmetic.
   - Tests: [0,1,0,2,1,0,1,3,2,1,2,1] -> 6; monotonic cases -> 0.

8. `44` Wildcard Matching
   - Drives: DP or greedy with backtracking pointers, string indexing.
   - Tests: canonical cases for `?` and `*`, including consecutive `*`.

9. `52` N-Queens II
   - Drives: recursion/backtracking, bit operations/masks.
   - Tests: n=1 -> 1, n=4 -> 2, n=8 -> 92 (optional if runtime acceptable).

10. `72` Edit Distance
    - Drives: DP (O(mn)), string indexing.
    - Tests: ("horse","ros")->3, ("intention","execution")->5, ("","")->0.

11. `84` Largest Rectangle in Histogram
    - Drives: monotonic stack, integer arithmetic.
    - Tests: [2,1,5,6,2,3] -> 10; [2,4] -> 4; [] -> 0.

12. `124` Binary Tree Maximum Path Sum
    - Drives: tree struct pointers, recursion, global max tracking.
    - Tests: [-10,9,20,null,null,15,7] -> 42; [1,2,3] -> 6.

13. `127` Word Ladder
    - Drives: BFS queue, hash set/dictionary, string transforms.
    - Tests: small dictionary example (hit->cog) -> 5; unreachable -> 0.

14. `239` Sliding Window Maximum
    - Drives: deque/ring-buffer, array output validation.
    - Tests: [1,3,-1,-3,5,3,6,7], k=3 -> [3,3,5,5,6,7]; k=1 -> input.

15. `312` Burst Balloons
    - Drives: interval DP, O(n^3) loops with n small in tests.
    - Tests: [3,1,5,8] -> 167; [] -> 0; [1] -> 1.

## Capability Checklist (What Aster Must Support to Pass the Suite)
These are *capabilities* implied by the suite; the actual implementation location can be per-test or factored later into stdlib.

- Deterministic program execution and integer correctness.
- Structs + pointers (`struct` node types; address-of; null checks).
- Dynamic allocation (`malloc`/`free`) for nodes and arrays.
- 1D/2D array operations via pointer math + explicit lengths.
- Basic containers (non-generic is fine initially):
  - dynamic array (vec) for `i32`/`usize`/node pointers
  - stack (vec)
  - deque (ring buffer) for indices
  - binary heap for list node pointers (min-heap)
  - hash set/map adequate for small string keys (Word Ladder)
- String utilities:
  - `strlen`, equality compare, char access, copying slices
  - optional: hashing of small strings
- Recursion support and predictable stack behavior (Sudoku, N-Queens, trees).

## Risks and Guardrails
- Some problems (Word Ladder, Sudoku) can blow up runtime if test cases are too large. Keep test inputs small and deterministic.
- Without module imports, helper code duplication will be high. Accept this short-term; add a follow-up milestone to factor helpers once imports exist.
- String-heavy problems require careful definition of Aster string representation (null-terminated pointers vs (ptr,len)). Tests should be explicit about lengths and null termination.
- Backtracking recursion depth must be bounded in tests to avoid stack issues during early bring-up.

## Open Questions / Assumptions
- Should these be "compiler tests" (fast, small inputs) or also include at least one "stress" case per problem?
- Do we want a C++/Rust oracle runner for a subset of problems to validate Aster outputs during development, or only fixed expected outputs?
- Preferred output convention on failure: `printf` diagnostics vs returning an error code only.

## References
- `tools/ci/gates.sh`
- `aster/tests/run.sh`
- `aster/bench/fswalk/fswalk.as`
- `.context/vendor/cursed/test_suite/leetcode_comprehensive_suite/`
- `.context/vendor/cursed/test_suite/test_programs/leetcode/`

