Aster standard library source code.

Current state (Aster1/MVP):
- The shared "core stdlib" modules live under `src/core/` at the repo root and are included via `use ...` (build-time expansion).
- Long-term, this folder will become the packaged stdlib crate(s) once the module/package system is fully implemented.
