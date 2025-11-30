#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  # shellcheck source=nv.sh
  source "nv.sh"

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

teardown() {
  rm -rf "/tmp/nv"
}

@test "Upgrades nv when confirming" {
  # Run in subshell to avaoid collision with other tests
  (
    local VERSION="0.1.0"

    # Mock latest version
    # shellcheck disable=SC2329
    _get_latest_version() { printf "v0.2.0"; }

    run nv_upgrade <<<""
    assert_success
    assert_output "Upgrade available: v0.1.0 -> v0.2.0
Proceeding with upgrade...
Downloading https://github.com/ldonnez/notevault/releases/download/v0.2.0/nv.tar.gz
Upgrade nv in $(_resolve_script_path)...
Upgrade success!"
  )
}

@test "Does not upgrade when not confirming" {
  # Run in subshell to avaoid collision with other tests
  (
    local VERSION="0.1.0"

    # Mock latest version
    # shellcheck disable=SC2329
    _get_latest_version() { printf "v0.2.0"; }

    run nv_upgrade <<<"n"
    assert_success
    assert_output "Upgrade available: v0.1.0 -> v0.2.0
Upgrade cancelled."
  )
}

@test "Does not upgrade when latest version = current version" {
  # Run in subshell to avoid collision with other tests
  (
    local VERSION="0.1.0"

    # Mock latest version
    # shellcheck disable=SC2329
    _get_latest_version() { printf "v0.1.0"; }

    run nv_upgrade
    assert_success
    assert_output "Already up to date"
  )
}

@test "Does not upgrade when curl can't resolve host" {
  # Run in subshell to avoid collision with other tests
  (
    local VERSION="0.1.0"

    # Mock curl
    # shellcheck disable=SC2329
    curl() {
      return 6
    }

    run nv_upgrade
    assert_failure
    assert_output "Version not found."
  )
}
