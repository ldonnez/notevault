#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  # shellcheck source=nv.sh
  source "nv.sh"
}

@test "decrypts $ARCHIVE to $PLAINDIR" {
  local input_path="$PLAINDIR/test.txt"
  touch "$input_path"

  nv_encrypt

  run nv_decrypt
  assert_success

  run _file_exists "$PLAINDIR/test.txt"
  assert_success

  run _file_exists "$PLAINDIR.tar.gz"
  assert_failure

  rm "$ARCHIVE"
}

@test "exits if $ARCHIVE is not found" {
  run nv_decrypt
  assert_failure
  assert_output "encrypted archive not found: $ARCHIVE"
}
