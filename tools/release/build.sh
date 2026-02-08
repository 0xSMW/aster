#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${RELEASE_OUT_DIR:-$ROOT/.context/release/out}"
mkdir -p "$OUT_DIR"

version="$(grep -E '^version[[:space:]]*=' "$ROOT/aster.toml" | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/' || true)"
if [[ -z "$version" ]]; then
  version="0.0.0"
fi

host="$(uname -s | tr '[:upper:]' '[:lower:]')"
arch="$(uname -m)"

echo "release: version=$version host=$host arch=$arch"

sha256_file() {
  local path="$1"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$path" | awk '{print $1}'
    return 0
  fi
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$path" | awk '{print $1}'
    return 0
  fi
  echo "release: missing sha256 tool (need shasum or sha256sum)" >&2
  return 1
}

# Build + gate.
bash "$ROOT/tools/ci/gates.sh"

pkg="$OUT_DIR/aster-${version}-${host}-${arch}.tgz"
stamp="$OUT_DIR/aster-${version}-${host}-${arch}.stamp.txt"
checksums="$OUT_DIR/aster-${version}-${host}-${arch}.sha256"

tmp="$(mktemp -d "${TMPDIR:-/tmp}/aster-release.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

git_rev=""
git_dirty=""
if command -v git >/dev/null 2>&1; then
  if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git_rev="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || true)"
    if [[ -n "$(git -C "$ROOT" status --porcelain 2>/dev/null || true)" ]]; then
      git_dirty="dirty"
    else
      git_dirty="clean"
    fi
  fi
fi

ts_utc="$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S%z')"

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

# Version stamp (also copied next to the package).
{
  echo "Aster Release"
  echo "version: $version"
  echo "host: $host"
  echo "arch: $arch"
  echo "built_utc: $ts_utc"
  if [[ -n "$git_rev" ]]; then
    echo "git_rev: $git_rev"
    echo "git_state: $git_dirty"
  fi
  echo ""
  bash "$ROOT/tools/ci/toolchains.sh" 2>/dev/null || true
} >"$tmp/aster/RELEASE_INFO.txt"

tar -C "$tmp" -czf "$pkg" aster

# Checksums.
sha_pkg="$(sha256_file "$pkg")"
printf '%s  %s\n' "$sha_pkg" "$(basename "$pkg")" >"$checksums"

cp -f "$tmp/aster/RELEASE_INFO.txt" "$stamp"

echo "release: wrote $pkg"
echo "release: wrote $checksums"
echo "release: wrote $stamp"
