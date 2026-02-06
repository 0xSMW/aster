Build scripts and tooling for assembling and linking the compiler.

Key tools:
- `asterc.py`: Aster0 compiler stub (Aster subset -> C -> asm or asm templates).
- `aster_build.py`: module graph builder with a simple incremental cache.
- `build.sh`: low-level asm build helper.
- `test_build.sh`: smoke test for the module graph builder (uses fixtures).

Example:
```
tools/build/aster_build.py --root tools/build/fixtures/sample --entry main --out /tmp/aster_build_test
```
