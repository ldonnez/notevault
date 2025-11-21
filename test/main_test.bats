#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  # shellcheck source=nv.sh
  source "nv.sh"
}

@test "prints Usage pattern" {

  run main
  assert_output "Usage: nv [--version | --help | --encrypt]"
}
