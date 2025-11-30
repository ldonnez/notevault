#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  # Mock only git pull
  git() {
    if [[ "$1" == "pull" ]]; then
      return 0
    fi

    if [[ "$1" == "push" ]]; then
      printf "git push called"
      return 0
    fi
    # Delegate to the real git
    command git "$@"
  }
  # shellcheck source=nv.sh
  source "nv.sh"

}

teardown() {
  rm -rf "${ARCHIVEDIR:?}"/*
}

@test "commits latest changes with $DEFAULT_GIT_COMMIT and pushes to HEAD" {
  touch "$ARCHIVEDIR/1764135005-$(hostname)-ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad.tar.gz.gpg"
  run nv_sync
  assert_success
  assert_output --partial "git push called"
}
