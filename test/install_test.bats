#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  # shellcheck source=install.sh
  source "install.sh"

  # Mock external commands
  # shellcheck disable=SC2329
  curl() {
    return 0
  }
  # shellcheck disable=SC2329
  install() {
    return 0
  }
  # shellcheck disable=SC2329
  rm() {
    return 0
  }
  # shellcheck disable=SC2329
  tar() {
    return 0
  }
}

@test "Installs latest version of nv" {
  # Mock latest version
  # shellcheck disable=SC2329
  _get_version() { printf "v0.2.0"; }

  run main
  assert_success
  assert_output "Downloading https://github.com/ldonnez/notevault/releases/download/v0.2.0/nv.tar.gz
Installing nv to $TEST_HOME/.local/bin...
Installed nv to $TEST_HOME/.local/bin
Make sure $TEST_HOME/.local/bin is in your PATH."
}

@test "Does not install nv curl could not resolve host" {
  # Run in separate subshell to avoid collision with other tests
  (
    # Mock curl
    # shellcheck disable=SC2329
    curl() {
      return 6 # Return cURL error code 6 for "Couldn't resolve host"
    }

    run main
    assert_failure
    assert_output "Version not found."
  )
}
