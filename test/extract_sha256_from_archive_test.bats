#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  # shellcheck source=nv.sh
  source "nv.sh"
}

teardown() {
  rm -rf "${ARCHIVEDIR:?}"/*
  rm -rf "${PLAINDIR:?}"/*
}

@test "returns sha from given archive name" {
  local archive
  archive="$ARCHIVEDIR/1764135005-$(hostname)-ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad.tar.gz.gpg"

  run _extract_sha256_from_archive "$archive"
  assert_success
  assert_output "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
}

@test "returns error when given filename does not include sha" {
  local archive
  archive="$ARCHIVEDIR/1764135005-$(hostname).tar.gz.gpg"

  run _extract_sha256_from_archive "$archive"
  assert_failure
  assert_output "error: archive filename does not contain a valid SHA256: $archive"
}
