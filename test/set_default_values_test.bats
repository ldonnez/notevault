#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  # shellcheck source=nv.sh
  source "nv.sh"
}

teardown() {
  rm -rf "${NOTES_DIR:?}"/.*
  rm -rf "${NOTES_DIR:?}"/*
}

@test "sets default values" {
  # Run in subshell to prevent collision in other tests
  (
    local REPO_ROOT
    local GPG_RECIPIENTS
    local _CONFIG_FILE
    local PLAINDIR
    local ENCRYPTEDDIR

    cd "$NOTES_DIR"

    _set_default_values
    assert_equal "$REPO_ROOT" "$HOME/notes"
    assert_equal "$GPG_RECIPIENTS" ""
    assert_equal "$_CONFIG_FILE" "$REPO_ROOT/.note-vault-config"
    assert_equal "$PLAINDIR" "notes"
    assert_equal "$ENCRYPTEDDIR" "encrypted"
  )
}
