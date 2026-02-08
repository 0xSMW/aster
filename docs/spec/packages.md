# Packages and Lockfiles

This document defines the current package boundary semantics for the Aster build tools.

## `aster.toml`

The presence of an `aster.toml` file defines a package root.

Current fields:
- `name` (string)
- `version` (string)

Future fields (not implemented yet):
- `deps` (registry or local path dependencies)
- build profiles and feature flags

## Module Layout

Within a package root:
- modules live at `src/<path>.as`
- `use foo.bar` resolves to `src/foo/bar.as` (build-time include in Aster1)

## `aster.lock`

The lockfile exists to make dependency resolution deterministic once package deps land.

Current (`lock_version = 1`):
- local path dependencies are recorded as:
  - `dep <name> <path>`
- `<path>` is resolved relative to the package root (dir containing `aster.toml`).

Resolution rules:
- If `dep foo <path>` exists:
  - `use foo` resolves to `<path>/src/lib.as`
  - `use foo.bar` resolves to `<path>/src/bar.as`
- Otherwise (no `dep` entry):
  - `use foo.bar` resolves to `<root>/src/foo/bar.as`

Convention:
- deps typically live under `libraries/<name>/` (gitignored) so module names
  remain stable and concise (e.g. `libraries/foo/src/lib.as` becomes module `foo`).

Future:
- record resolved deps (name, source, version, content hashes)
- support offline/reproducible builds
