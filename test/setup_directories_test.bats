#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  TEMP="$(mktemp -d)"

  # shellcheck source=nv.sh
  source "nv.sh"
}

teardown() {
  rm -rf "$TEMP"
}

@test "Creates missing directories" {
  # Run in subshell to prevent collision in other tests
  (
    local PLAINDIR="$TEMP/test_plain"

    _setup_directories

    assert_equal "" "$([[ -d "$PLAINDIR" ]])"
  )
}
