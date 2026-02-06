# Macro library scaffolding

This directory holds the assembly macro library used by the compiler, runtime,
and build driver. The macro set is split into shared and arch-specific layers.

Planned includes:
- `base.inc` for shared helpers (labels, alignment, sections)
- `abi_x86_64.inc` for SysV register aliases and prologues
- `abi_arm64.inc` for arm64 register aliases and prologues
- `string.inc`, `vec.inc`, `hash.inc`, `arena.inc` for core data structures

See `docs/spec/assembly-conventions.md` for the authoritative conventions.
