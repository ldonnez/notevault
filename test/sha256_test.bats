#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  # shellcheck source=nv.sh
  source "nv.sh"
}

@test "returns success when file exists" {
  local file="test.txt"
  touch "$file"

  run _sha256 "$file"
  assert_success

  rm -f "$file"
}

@test "returns failure when file does not exist" {
  run _sha256 "i-do-not-exist"
  assert_failure
}
