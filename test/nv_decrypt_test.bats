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

@test "decrypts to $PLAINDIR" {
  local input_path="$PLAINDIR/test.txt"
  touch "$input_path"

  nv_encrypt

  run nv_decrypt
  assert_success

  if [[ "$OSTYPE" == "darwin"* ]]; then
    assert_output "x ./
x ./test.txt
decrypted into $PLAINDIR"
  else
    assert_output "./
./test.txt
decrypted into $PLAINDIR"
  fi

  run _file_exists "$PLAINDIR/test.txt"
  assert_success

  rm -rf "${ARCHIVEDIR:?}"/*
}

@test "prints message if no archives found" {
  run nv_decrypt

  assert_success
  assert_output "no archives found."
}

@test "prints message if local changes in $PLAINDIR" {
  mkdir -p "$PLAINDIR"
  local file="$PLAINDIR/test.txt"
  touch "$file"

  nv_encrypt

  printf "Hello World" >"$file"

  run nv_decrypt
  assert_failure
  assert_output "Local changes detected in $PLAINDIR — decrypt aborted."
}

@test "decrypts multiple archives to $PLAINDIR" {
  mkdir -p "$PLAINDIR"

  local input_path="$PLAINDIR/test.txt"
  touch "$input_path"

  run nv_encrypt

  sleep 1

  local input_path="$PLAINDIR/test2.txt"
  touch "$input_path"
  run nv_encrypt

  run nv_decrypt
  assert_success

  assert_output --partial "decrypted into $PLAINDIR"

  run _file_exists "$PLAINDIR/test.txt"
  assert_success

  run _file_exists "$PLAINDIR/test2.txt"
  assert_success
}
