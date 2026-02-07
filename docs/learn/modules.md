# Modules (`use`) (Current Aster1 Semantics)

Today, `use` is a build-time include mechanism (not a namespaced module system).

Example:

```aster
use core.io

def main() returns i32
    println("hi")
    return 0
```

Build-time expansion:
- `use core.io` is expanded to the file `src/core/io.as` under the nearest parent directory that contains `aster.toml`.
- Expansion is transitive (modules can `use` other modules).
- Each module file is included at most once (cycle protection).

Notes:
- This is intentionally simple for the MVP. A real module system (namespaces, separate compilation, interfaces) will land later.
- When using `ASTER_CACHE=1`, the cache key includes the fully-expanded combined source so edits in dependencies correctly invalidate builds.

## Local Deps (`aster.lock`)

To make dependency resolution deterministic, a package can include an `aster.lock`
file (next to `aster.toml`) with `lock_version = 1` and one or more dep entries:

```text
lock_version = 1
dep foo libraries/foo
```

Resolution:
- `use foo` resolves to `libraries/foo/src/lib.as`
- `use foo.bar` resolves to `libraries/foo/src/bar.as`

Convenience:
- Add/update a dep: `tools/aster/aster dep add foo libraries/foo`
- List deps: `tools/aster/aster dep ls`
