#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
"$ROOT/tools/build/aster_build.py" --root "$ROOT/tools/build/fixtures/sample" --entry main --out /tmp/aster_build_test
