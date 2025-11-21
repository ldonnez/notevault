#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  # shellcheck source=nv.sh
  source "nv.sh"
}

@test "encrypts file to same path when no output_path (second arg) is given" {
  local input_path="$NOTES_DIR/test.txt"
  touch "$input_path"

  run _gpg_encrypt "$input_path" "$input_path.gpg"
  assert_success

  run _file_exists "$input_path.gpg"
  assert_success
}

@test "encrypts file to given output_path" {
  local input_path="$NOTES_DIR/test.txt"
  touch "$input_path"

  local output_path="$NOTES_DIR/test.txt"

  run _gpg_encrypt "$input_path" "$output_path.gpg"
  assert_success

  run _file_exists "$output_path.gpg"
  assert_success
}

@test "encrypts file with multiple recipients" {
  gpg --batch --gen-key <<EOF
%no-protection
Key-Type: RSA
Key-Length: 1024
Name-Real: mock user2
Name-Email: test2@example.com
Expire-Date: 0
%commit
EOF
  # shellcheck disable=SC2030,SC2031
  export GPG_RECIPIENTS="mock@example.com,test2@example.com"

  local input_path="$NOTES_DIR/test_multi.txt"
  touch "$input_path"

  run _gpg_encrypt "$input_path" "$input_path.gpg"
  assert_success

  run _file_exists "$input_path.gpg"
  assert_success
}

@test "does not leave unencrypted file when encryption fails" {
  # shellcheck disable=SC2030,SC2031
  export GPG_RECIPIENTS="missing@example.com"

  local input_path="$NOTES_DIR/test_secure.md"
  touch "$input_path"

  run _gpg_encrypt "$input_path" "$input_path.gpg"
  assert_failure

  run _file_exists "$input_path.gpg"
  assert_failure
}
