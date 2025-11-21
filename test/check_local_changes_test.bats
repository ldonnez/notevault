#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  # shellcheck source=nv.sh
  source "nv.sh"
}

teardown() {
  rm -rf "${ARCHIVEDIR:?}"/*
  rm -rf "${PLAINDIR:?}"/*
}

@test "returns 0 when no local changes in $PLAINDIR" {
  local input_path="$PLAINDIR/test.txt"
  touch "$input_path"

  local dir_signature
  dir_signature="$(_dir_signature "$PLAINDIR")"

  run _check_local_changes "$dir_signature"
  assert_success
}

@test "exits 1 when local changes in $PLAINDIR" {
  local input_path="$PLAINDIR/test2.txt"
  touch "$input_path"

  local dir_signature
  dir_signature="$(_dir_signature "$PLAINDIR")"

  local input_path2="$PLAINDIR/test3.txt"
  touch "$input_path2"

  run _check_local_changes "$dir_signature"
  assert_failure
  assert_output "Local changes detected in $PLAINDIR — decrypt aborted."
}
