# Packages and Lockfiles (WIP)

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

Current:
- `lock_version = 0`
- no dependencies are recorded yet

Future:
- record resolved deps (name, source, version, content hashes)
- support offline/reproducible builds

