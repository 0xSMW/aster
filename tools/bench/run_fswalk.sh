#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [[ -n "${1:-}" ]]; then
    export FS_BENCH_ROOT="$1"
fi

if [[ -z "${FS_BENCH_ROOT:-}" ]]; then
    echo "usage: run_fswalk.sh <root> (or set FS_BENCH_ROOT)" >&2
    exit 2
fi

BENCH_SET=fswalk "$ROOT/tools/bench/run.sh"
