#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  # Mock only git pull
  git() {
    if [[ "$1" == "pull" ]]; then
      return 0
    fi

    # Delegate everything else to the real git
    command git "$@"
  }
  # shellcheck source=nv.sh
  source "nv.sh"

}

@test "commits latest changes with $DEFAULT_GIT_COMMIT" {
  # run in subshell to avoid collisions
  (
    touch "$ARCHIVEDIR/1764135005-$(hostname)-ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad.tar.gz.gpg"
    cd "$REPO_ROOT"
    run nv_commit
    assert_success
    assert_output --partial "$DEFAULT_GIT_COMMIT"
  )
}

@test "do nothing when no changes" {
  # run in subshell to avoid collisions
  (
    cd "$REPO_ROOT"
    run nv_commit
    assert_success
    assert_output ""

    rm -rf "${ARCHIVEDIR:?}"/*
  )
}
