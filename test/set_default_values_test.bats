#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  # shellcheck source=nv.sh
  source "nv.sh"
}

teardown() {
  rm -rf "${REPO_ROOT:?}"/.*
  rm -rf "${REPO_ROOT:?}"/*
}

@test "sets default values" {
  # Run in subshell to prevent collision in other tests
  (
    local GPG_RECIPIENTS
    local _CONFIG_FILE
    local PLAINDIR
    local ARCHIVEDIR
    local ARCHIVES_TO_KEEP

    _set_default_values
    assert_equal "$REPO_ROOT" "$HOME/test-notes"
    assert_equal "$GPG_RECIPIENTS" ""
    assert_equal "$_CONFIG_FILE" "$REPO_ROOT/.note-vault-config"
    assert_equal "$PLAINDIR" "$REPO_ROOT/notes"
    assert_equal "$ARCHIVEDIR" "$REPO_ROOT/archives"
    assert_equal "$ARCHIVES_TO_KEEP" 10
  )
}
