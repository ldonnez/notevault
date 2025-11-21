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

@test "sorts $ARCHIVEDIR files oldest first" {
  # create files in non-sorted order
  touch "$ARCHIVEDIR/1764175005-$(hostname)-ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad.tar.gz.gpg"
  touch "$ARCHIVEDIR/1764135005-$(hostname)-3608bca1e44ea6c4d268eb6db02260269892c0b42b86bbf1e77a6fa16c3c9282.tar.gz.gpg"
  touch "$ARCHIVEDIR/1764174005-$(hostname)-dff872038755d6c918211dca2edd2a89c1da24d9091b8c1146bd1ae04f0c345c.tar.gz.gpg"
  touch "$ARCHIVEDIR/1764179005-$(hostname)-50b3e9cbdd1e47b7e389cba312bda2f61c9d9e64098fae65cad573f792a385cc.tar.gz.gpg"

  run _get_archives_sorted "$ARCHIVEDIR"
  assert_success
  assert_output "1764135005-$(hostname)-3608bca1e44ea6c4d268eb6db02260269892c0b42b86bbf1e77a6fa16c3c9282.tar.gz.gpg
1764174005-$(hostname)-dff872038755d6c918211dca2edd2a89c1da24d9091b8c1146bd1ae04f0c345c.tar.gz.gpg
1764175005-$(hostname)-ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad.tar.gz.gpg
1764179005-$(hostname)-50b3e9cbdd1e47b7e389cba312bda2f61c9d9e64098fae65cad573f792a385cc.tar.gz.gpg"
}

@test "returns empty when no files in $ARCHIVEDIR" {
  run _get_archives_sorted "$ARCHIVEDIR"
  assert_success
  assert_output ""
}
