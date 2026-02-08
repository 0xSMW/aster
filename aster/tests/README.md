# Aster Tests

Language-level conformance tests compiled by the real `asterc`.

Layout:
- `pass/`: must compile and run (exit 0). Optional golden outputs:
  - `pass/<name>.stdout`
  - `pass/<name>.stderr`
- `fail/`: must fail compilation.

Run:
```bash
bash aster/tests/run.sh
```

Notes:
- The runner compiles via `tools/build/asterc.sh`, so tests can use `use foo.bar`
  preambles (expanded as a build-time include from `<root>/src/`).
- Artifacts default to `.context/aster/tests/out` (override `ASTER_TEST_OUT_DIR`).
