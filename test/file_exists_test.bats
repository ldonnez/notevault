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

  run _file_exists "$file"
  assert_success
}

@test "returns failure when file does not exist" {
  run _file_exists "does-not-exist.txt"
  assert_failure
}
