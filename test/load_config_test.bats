#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  # shellcheck source=nv.sh
  source "nv.sh"
}

@test "loads config from config file" {
  # config file is set in ./setup_suite.bash

  # Run in subshell to prevent collision in other tests
  (
    local GPG_RECIPIENTS
    local _CONFIG_FILE
    local PLAINDIR
    local ARCHIVEDIR

    cat >"$REPO_ROOT/.note-vault-config" <<EOF
GPG_RECIPIENTS="test@example.com,test2@example.com"
PLAINDIR="test"
ARCHIVEDIR="encrypted_archives"
ARCHIVES_TO_KEEP=5
EOF
    cd "$REPO_ROOT"

    _load_config
    assert_equal "$REPO_ROOT" "$HOME/test-notes"
    assert_equal "$GPG_RECIPIENTS" "test@example.com,test2@example.com"
    assert_equal "$_CONFIG_FILE" "$REPO_ROOT/.note-vault-config"
    assert_equal "$PLAINDIR" "test"
    assert_equal "$ARCHIVEDIR" "encrypted_archives"
    assert_equal "$ARCHIVES_TO_KEEP" 5

    rm -rf "$ARCHIVEDIR"
  )
}

@test "exits when not in git repo" {
  # Run in subshell to prevent collision in other tests
  (
    cd "/"
    run _load_config
    assert_failure
    assert_output "not inside a git repository."
  )
}
