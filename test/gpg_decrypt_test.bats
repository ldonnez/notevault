#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  # shellcheck source=nv.sh
  source "nv.sh"
}

@test "decrypts file to given output path" {
  local input_path="test.txt"
  touch "$input_path"

  _gpg_encrypt "$input_path" "$input_path.gpg"

  run _gpg_decrypt "$input_path.gpg" "$input_path"
  assert_success

  rm -f "$input_path"
  rm -f "$input_path.gpg"
}
