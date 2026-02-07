# Release Engineering

## Build A Release Package

This produces a versioned `.tgz` under `.context/release/out/` and writes:
- a package tarball
- a `.sha256` checksums file
- a `RELEASE_INFO.txt` stamp (also embedded in the tarball)

```bash
bash tools/release/build.sh
```

Notes:
- `tools/release/build.sh` runs the full green gate (`tools/ci/gates.sh`) first.
- Version is sourced from `aster.toml`.

## Install

Install `aster`, `asterc`, and `asterfmt` to a prefix (default `$HOME/.local`):

```bash
bash tools/release/install.sh --prefix "$HOME/.local"
```

Uninstall:

```bash
bash tools/release/uninstall.sh --prefix "$HOME/.local"
```

