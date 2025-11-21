#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  # shellcheck source=nv.sh
  source "nv.sh"
}

teardown() {
  rm -rf "${ARCHIVEDIR:?}"/*
}

@test "removes old archives from $ARCHIVEDIR, oldest first" {
  touch "$ARCHIVEDIR/1764135005-$(hostname)-ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad.tar.gz.gpg"
  touch "$ARCHIVEDIR/1764174005-$(hostname)-3608bca1e44ea6c4d268eb6db02260269892c0b42b86bbf1e77a6fa16c3c9282.tar.gz.gpg"
  touch "$ARCHIVEDIR/1764175005-$(hostname)-dff872038755d6c918211dca2edd2a89c1da24d9091b8c1146bd1ae04f0c345c.tar.gz.gpg"
  touch "$ARCHIVEDIR/1764179005-$(hostname)-50b3e9cbdd1e47b7e389cba312bda2f61c9d9e64098fae65cad573f792a385cc.tar.gz.gpg"

  run _rotate_archives_by_host "$ARCHIVEDIR" "$(hostname)" 2
  assert_success
  assert_output "rotating archives for host $(hostname) (removing 2 old archives)...
removing $ARCHIVEDIR/1764135005-$(hostname)-ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad.tar.gz.gpg
removing $ARCHIVEDIR/1764174005-$(hostname)-3608bca1e44ea6c4d268eb6db02260269892c0b42b86bbf1e77a6fa16c3c9282.tar.gz.gpg"
}

@test "do nothing when stored archives are less then given keep" {
  touch "$ARCHIVEDIR/1764135005-$(hostname)-ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad.tar.gz.gpg"
  touch "$ARCHIVEDIR/1764174005-$(hostname)-3608bca1e44ea6c4d268eb6db02260269892c0b42b86bbf1e77a6fa16c3c9282.tar.gz.gpg"
  touch "$ARCHIVEDIR/1764175005-$(hostname)-dff872038755d6c918211dca2edd2a89c1da24d9091b8c1146bd1ae04f0c345c.tar.gz.gpg"
  touch "$ARCHIVEDIR/1764179005-$(hostname)-50b3e9cbdd1e47b7e389cba312bda2f61c9d9e64098fae65cad573f792a385cc.tar.gz.gpg"

  run _rotate_archives_by_host "$ARCHIVEDIR" "$(hostname)" 10
  assert_success
  assert_output ""
}

@test "do nothing when no archives found" {
  run _rotate_archives_by_host "$ARCHIVEDIR" "$(hostname)" 10
  assert_success
  assert_output ""
}
