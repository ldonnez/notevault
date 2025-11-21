#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  # shellcheck source=nv.sh
  source "nv.sh"
}

@test "returns archive filename" {
  run _get_archive_filename "$(hostname)" "123"
  assert_success
  assert_output --partial "$(hostname)-123"
}
