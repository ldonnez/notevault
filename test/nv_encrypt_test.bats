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

@test "archives and encrypts $PLAINDIR to $ARCHIVEDIR" {
  local input_path="$PLAINDIR/test.txt"
  touch "$input_path"

  run nv_encrypt
  assert_success
  assert_output --partial "creating tarball...
encrypted ->"

  run _file_exists "$PLAINDIR.tar.gz"
  assert_failure
}

@test "exits when $PLAINDIR does not exist" {
  # run in subshell to avaoid collisions and allow global variables to be overriden.
  (
    local PLAINDIR="i-do-not-exist"

    run nv_encrypt
    assert_failure
    assert_output "$PLAINDIR does not exist."
  )
}
