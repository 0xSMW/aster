#!/usr/bin/env bash
set -euo pipefail

# Shared "module preprocessor" for Aster1.
#
# Aster1 compiler currently compiles a single .as file. Until `asterc` grows a
# real module system, we treat:
#   use foo.bar
# as a build-time include of:
#   <package_root>/src/foo/bar.as
#
# This script is sourced by other bash tools (e.g. `tools/aster/aster`,
# `tools/build/asterc.sh`) to keep semantics identical.

aster_find_root() {
  # Walk upward looking for aster.toml; fall back to current dir.
  local start="${1:-$PWD}"
  local d="$start"
  while true; do
    if [[ -f "$d/aster.toml" ]]; then
      printf '%s\n' "$d"
      return 0
    fi
    if [[ "$d" == "/" ]]; then
      printf '%s\n' "$PWD"
      return 0
    fi
    d="$(cd "$d/.." && pwd)"
  done
}

aster_mod_path_to_file() {
  local root="$1"
  local mod="$2"
  # `use foo.bar` -> <root>/src/foo/bar.as
  local rel="${mod//.//}.as"
  printf '%s\n' "$root/src/$rel"
}

aster_file_has_use_preamble() {
  local file="$1"
  local in_preamble=1
  while IFS= read -r line || [[ -n "$line" ]]; do
    local t="${line#"${line%%[!$' \t']*}"}"
    if [[ "$in_preamble" -eq 1 ]]; then
      if [[ -z "$t" || "${t:0:1}" == "#" ]]; then
        continue
      fi
      if [[ "$t" =~ ^use[[:space:]]+([A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*)[[:space:]]*$ ]]; then
        return 0
      fi
      return 1
    fi
  done < "$file"
  return 1
}

aster_preprocess_modules() {
  local root="$1"
  local entry="$2"
  local out_as="$3"

  # Supports `use foo.bar` in the leading preamble.
  # Emits a concatenated output with all `use` lines removed.
  local root_abs
  root_abs="$(cd "$root" && pwd)"

  local visited="|"
  local order_list=()

  parse_uses() {
    local file="$1"
    local in_preamble=1
    while IFS= read -r line || [[ -n "$line" ]]; do
      local t="${line#"${line%%[!$' \t']*}"}"
      if [[ "$in_preamble" -eq 1 ]]; then
        if [[ -z "$t" || "${t:0:1}" == "#" ]]; then
          continue
        fi
        if [[ "$t" =~ ^use[[:space:]]+([A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*)[[:space:]]*$ ]]; then
          printf '%s\n' "${BASH_REMATCH[1]}"
          continue
        fi
        break
      fi
    done < "$file"
  }

  strip_use_block() {
    local file="$1"
    local in_preamble=1
    while IFS= read -r line || [[ -n "$line" ]]; do
      local t="${line#"${line%%[!$' \t']*}"}"
      if [[ "$in_preamble" -eq 1 ]]; then
        if [[ "$t" =~ ^use[[:space:]]+([A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*)[[:space:]]*$ ]]; then
          continue
        fi
        if [[ -z "$t" || "${t:0:1}" == "#" ]]; then
          echo "$line"
          continue
        fi
        in_preamble=0
      fi
      echo "$line"
    done < "$file"
  }

  is_visited() {
    local key="|$1|"
    case "$visited" in
      *"$key"*) return 0 ;;
      *) return 1 ;;
    esac
  }

  mark_visited() {
    visited="${visited}$1|"
  }

  abs_path() {
    local f="$1"
    local d
    d="$(cd "$(dirname "$f")" && pwd)"
    printf '%s/%s\n' "$d" "$(basename "$f")"
  }

  dfs_file() {
    local file="$1"
    local abs
    abs="$(abs_path "$file")"
    if is_visited "$abs"; then
      return 0
    fi
    mark_visited "$abs"
    while IFS= read -r mod; do
      [[ -n "$mod" ]] || continue
      local dep
      dep="$(aster_mod_path_to_file "$root_abs" "$mod")"
      if [[ ! -f "$dep" ]]; then
        echo "aster: module not found: use $mod -> $dep" >&2
        exit 2
      fi
      dfs_file "$dep"
    done < <(parse_uses "$abs")
    order_list+=("$abs")
  }

  dfs_file "$entry"

  mkdir -p "$(dirname "$out_as")"
  : > "$out_as"
  for file in "${order_list[@]}"; do
    local rel="$file"
    case "$file" in
      "$root_abs"/*) rel="${file#$root_abs/}" ;;
    esac
    printf '# --- module: %s ---\n' "$rel" >>"$out_as"
    strip_use_block "$file" >>"$out_as"
    printf '\n\n' >>"$out_as"
  done
}
