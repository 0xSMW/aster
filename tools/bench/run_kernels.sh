#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ASTER_BACKEND="${ASTER_BACKEND:-c}" BENCH_SET=kernels "$ROOT/tools/bench/run.sh"
