#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
FMT="$ROOT/tools/asterfmt/asterfmt"

tmp="$(mktemp -d "${TMPDIR:-/tmp}/asterfmt-tests.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

write_file() {
  local path="$1"
  local content="$2"
  mkdir -p "$(dirname "$path")"
  # `printf %s` to allow embedded \r\n etc via $'..' at call sites.
  printf "%s" "$content" >"$path"
}

expect_eq() {
  local got="$1"
  local want="$2"
  if ! cmp -s "$got" "$want"; then
    echo "FAIL: mismatch: $got" >&2
    diff -u "$want" "$got" >&2 || true
    exit 1
  fi
}

# 1) In-place formatting (CRLF -> LF, tabs -> 4 spaces, trailing ws stripped, newline at EOF).
in1="$tmp/in1.as"
want1="$tmp/want1.as"
write_file "$in1" $'def main() returns i32\t \r\n    return 0   \r\n'
write_file "$want1" $'def main() returns i32\n    return 0\n'
"$FMT" "$in1" >/dev/null
expect_eq "$in1" "$want1"

# 2) --check should fail when changes are needed, succeed when clean.
in2="$tmp/in2.as"
write_file "$in2" $'def main() returns i32\t\r\n    return 0\r\n'
set +e
"$FMT" --check "$in2" >/dev/null 2>&1
rc=$?
set -e
if [[ "$rc" -ne 1 ]]; then
  echo "FAIL: expected --check to exit 1, got $rc" >&2
  exit 1
fi

"$FMT" "$in2" >/dev/null
"$FMT" --check "$in2" >/dev/null

echo "ok asterfmt"

