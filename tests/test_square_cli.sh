#!/bin/bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT

binary="$temp_dir/squaredraw"
g++ -std=c++17 -Wall -Wextra -Werror "$repo_root/main.cpp" -o "$binary"

assert_success_output() {
  local name="$1"
  local expected_file="$2"
  shift 2

  if ! "$@" >"$temp_dir/actual" 2>"$temp_dir/stderr"; then
    echo "$name: expected success" >&2
    exit 1
  fi

  if ! cmp -s "$expected_file" "$temp_dir/actual"; then
    echo "$name: stdout did not match expected output" >&2
    diff -u "$expected_file" "$temp_dir/actual" >&2 || true
    exit 1
  fi

  if [[ -s "$temp_dir/stderr" ]]; then
    echo "$name: expected empty stderr" >&2
    exit 1
  fi
}

assert_failure() {
  local name="$1"
  shift

  if "$@" >"$temp_dir/actual" 2>"$temp_dir/stderr"; then
    echo "$name: expected failure" >&2
    exit 1
  fi

  if [[ -s "$temp_dir/actual" ]]; then
    echo "$name: expected empty stdout" >&2
    exit 1
  fi

  if ! grep -q '^Usage: squaredraw \[--size N\]$' "$temp_dir/stderr"; then
    echo "$name: expected usage hint on stderr" >&2
    exit 1
  fi
}

cat >"$temp_dir/default.expected" <<'EOF'
+-------+
|#      |
| #     |
|  #    |
|   @   |
|    #  |
|     # |
|      #|
+-------+
EOF
assert_success_output "default rendering" "$temp_dir/default.expected" "$binary"

cat >"$temp_dir/size-three.expected" <<'EOF'
+---+
|#  |
| @ |
|  #|
+---+
EOF
assert_success_output "size-three rendering" "$temp_dir/size-three.expected" "$binary" --size 3

"$binary" --size 40 >"$temp_dir/size-forty.actual" 2>"$temp_dir/stderr"
if [[ -s "$temp_dir/stderr" ]] || ! awk 'length != 42 { exit 1 } END { exit NR != 42 }' "$temp_dir/size-forty.actual"; then
  echo "maximum size: expected a 42 by 42 character square" >&2
  exit 1
fi

"$binary" --help >"$temp_dir/help.actual" 2>"$temp_dir/stderr"
if [[ -s "$temp_dir/stderr" ]] || ! grep -q '^Usage: squaredraw \[--size N\]$' "$temp_dir/help.actual"; then
  echo "help: expected usage on stdout only" >&2
  exit 1
fi

assert_failure "missing size" "$binary" --size
assert_failure "size below range" "$binary" --size 2
assert_failure "size above range" "$binary" --size 41
assert_failure "non-numeric size" "$binary" --size seven
assert_failure "signed size" "$binary" --size +3
assert_failure "leading whitespace in size" "$binary" --size " 3"
assert_failure "trailing whitespace in size" "$binary" --size "3 "
assert_failure "unknown option" "$binary" --unknown
assert_failure "positional argument" "$binary" 3
assert_failure "repeated size" "$binary" --size 3 --size 4
assert_failure "help combined with size" "$binary" --help --size 3

echo "All square CLI tests passed."
