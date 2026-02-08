Aster CLI (prototype).

This is a lightweight command-line front-end around the real compiler
(`tools/build/out/asterc`) for building and running Aster code.

Usage:
```bash
tools/aster/aster build path/to/file.as /tmp/out
tools/aster/aster run path/to/file.as -- arg1 arg2
tools/aster/aster test
tools/aster/aster bench --kernels
tools/aster/aster bench --fswalk --fs-root "$HOME" --max-depth 5 --list-fixed
```

Notes:
- This CLI supports a minimal `use foo.bar` preprocessor that concatenates
  modules from `<project_root>/src/foo/bar.as` into a single combined source
  before invoking `asterc`. This keeps the compiler MVP small while enabling
  multi-file projects.
- The project root is the nearest ancestor directory containing `aster.toml`
  (if present). If no `aster.toml` is found, the current working directory is
  used.
