#!/usr/bin/env bash
set -euo pipefail

echo "Toolchains:"
echo "- host: $(uname -a)"

if command -v clang >/dev/null 2>&1; then
  echo "- clang: $(clang --version | head -n 1)"
else
  echo "- clang: (missing)"
fi

if command -v clang++ >/dev/null 2>&1; then
  echo "- clang++: $(clang++ --version | head -n 1)"
else
  echo "- clang++: (missing)"
fi

if command -v rustc >/dev/null 2>&1; then
  echo "- rustc: $(rustc --version)"
else
  echo "- rustc: (missing)"
fi

if command -v python3 >/dev/null 2>&1; then
  echo "- python3: $(python3 --version 2>&1)"
else
  echo "- python3: (missing)"
fi

