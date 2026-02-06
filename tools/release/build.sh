#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${RELEASE_OUT_DIR:-$ROOT/.context/release/out}"
mkdir -p "$OUT_DIR"

version="$(grep -E '^version[[:space:]]*=' "$ROOT/aster.toml" | head -n 1 | sed -E 's/.*\"([^\"]+)\".*/\\1/' || true)"
if [[ -z "$version" ]]; then
  version="0.0.0"
fi

host="$(uname -s | tr '[:upper:]' '[:lower:]')"
arch="$(uname -m)"

echo "release: version=$version host=$host arch=$arch"

# Build + gate.
bash "$ROOT/tools/ci/gates.sh"

pkg="$OUT_DIR/aster-${version}-${host}-${arch}.tgz"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/aster-release.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/aster"
cp -R "$ROOT/asm" "$tmp/aster/"
cp -R "$ROOT/aster" "$tmp/aster/"
cp -R "$ROOT/docs" "$tmp/aster/"
cp -R "$ROOT/tools" "$tmp/aster/"
cp "$ROOT/README.md" "$tmp/aster/"
cp "$ROOT/LICENSE" "$tmp/aster/" 2>/dev/null || true
cp "$ROOT/INIT.md" "$tmp/aster/"
cp "$ROOT/BENCH.md" "$tmp/aster/"
cp "$ROOT/aster.toml" "$tmp/aster/"
cp "$ROOT/aster.lock" "$tmp/aster/"

# Include a built compiler binary for convenience.
mkdir -p "$tmp/aster/tools/build/out"
cp "$ROOT/tools/build/out/asterc" "$tmp/aster/tools/build/out/asterc"

tar -C "$tmp" -czf "$pkg" aster
echo "release: wrote $pkg"
