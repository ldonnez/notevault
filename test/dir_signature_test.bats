#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  # shellcheck source=nv.sh
  source "nv.sh"
}

@test "returns success when directory exists" {
  local file="$PLAINDIR/test.txt"
  touch "$file"

  run _dir_signature "$file"
  assert_success
}

@test "returns failure when directory does not exist" {
  run _dir_signature "i-do-not-exist"
  assert_failure
}
