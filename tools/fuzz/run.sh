#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${FUZZ_OUT_DIR:-$ROOT/.context/fuzz/out}"
mkdir -p "$OUT"

ITERS="${FUZZ_ITERS:-200}"
MAX_BYTES="${FUZZ_MAX_BYTES:-256}"
SEED="${FUZZ_SEED:-1}"
DETERMINISTIC="${FUZZ_DETERMINISTIC:-1}" # 1 = deterministic bytes from FUZZ_SEED; 0 = /dev/urandom

CORPUS_DIR="${FUZZ_CORPUS_DIR:-$ROOT/tools/fuzz/corpus}"
SEED_DIR="${FUZZ_SEED_DIR:-$CORPUS_DIR/seeds}"

ASTER_COMPILER="${ASTER_COMPILER:-$ROOT/tools/build/out/asterc}"
if [[ ! -x "$ASTER_COMPILER" ]]; then
  bash "$ROOT/tools/build/build.sh" "$ROOT/asm/driver/asterc.S" >/dev/null
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "fuzz: python3 is required" >&2
  exit 2
fi

echo "fuzz:"
echo "- deterministic: $DETERMINISTIC"
echo "- seed: $SEED"
echo "- iters: $ITERS"
echo "- max_bytes: $MAX_BYTES"
if [[ -d "$SEED_DIR" ]]; then
  echo "- seed_dir: $SEED_DIR"
else
  echo "- seed_dir: (missing) $SEED_DIR"
fi

gen_case_bytes() {
  local seed="$1"
  local idx="$2"
  local max_bytes="$3"
  local out="$4"
  python3 - "$seed" "$idx" "$max_bytes" "$out" <<'PY'
import hashlib
import sys

seed = sys.argv[1].encode("utf-8", errors="replace")
idx = int(sys.argv[2])
max_bytes = int(sys.argv[3])
out = sys.argv[4]

data = bytearray()
ctr = 0
while len(data) < max_bytes:
    h = hashlib.sha256(seed + b":" + str(idx).encode() + b":" + ctr.to_bytes(4, "little")).digest()
    data.extend(h)
    ctr += 1

data = data[:max_bytes]

# Ensure the lexer/parser hits indentation/newline paths.
data.extend(b"\n")

with open(out, "wb") as f:
    f.write(data)
PY
}

compile_one() {
  local src="$1"
  local bin="$2"
  local stderr_path="$3"

  set +e
  "$ASTER_COMPILER" "$src" "$bin" >/dev/null 2>"$stderr_path"
  rc=$?
  set -e

  # Treat signals/crashes as failure (bash convention: 128+signal).
  if [[ "$rc" -ge 128 ]]; then
    echo "FAIL: compiler crashed (rc=$rc) on $src" >&2
    return 1
  fi
  return 0
}

status=0

# 1) Compile the seed corpus first (ensures we exercise deep code paths
# deterministically, even when random bytes fail early).
seed_count=0
if [[ -d "$SEED_DIR" ]]; then
  while IFS= read -r seed; do
    [[ -n "$seed" ]] || continue
    seed_count=$((seed_count + 1))
    base="$(basename "$seed" .as)"
    src="$seed"
    bin="$OUT/seed_${base}.bin"
    if ! compile_one "$src" "$bin" "$OUT/seed_${base}.stderr"; then
      status=1
      break
    fi
  done < <(find "$SEED_DIR" -type f -name '*.as' 2>/dev/null | LC_ALL=C sort)
fi

if [[ "$status" -eq 0 && "$seed_count" -gt 0 ]]; then
  echo "ok fuzz seeds ($seed_count files)"
fi

# 2) Deterministic "random bytes" fuzzing: crash-only signal.
for i in $(seq 1 "$ITERS"); do
  src="$OUT/case_${i}.as"
  bin="$OUT/case_${i}.bin"
  if [[ "$DETERMINISTIC" != "0" ]]; then
    gen_case_bytes "$SEED" "$i" "$MAX_BYTES" "$src"
  else
    # Random bytes, but ensure there's at least one newline so the lexer/parser hits indentation paths.
    head -c "$MAX_BYTES" /dev/urandom >"$src" || true
    printf '\n' >>"$src"
  fi

  if ! compile_one "$src" "$bin" "$OUT/case_${i}.stderr"; then
    status=1
    break
  fi
done

if [[ "$status" -eq 0 ]]; then
  echo "ok fuzz ($ITERS cases)"
fi
exit "$status"
