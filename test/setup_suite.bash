setup_suite() {
  # Use readlink -f to follow symlinks here since macOS symlinks temp from /var/... to /private/var/
  TEST_HOME="$(readlink -f "$(mktemp -d)")"
  export TEST_HOME
  export HOME="$TEST_HOME"
  export NOTES_DIR="$TEST_HOME/notes"
  export GPG_RECIPIENTS="mock@example.com"
  export PLAINDIR="notes"
  export ENCRYPTEDDIR="encrypted"

  mkdir -p "$NOTES_DIR"
  mkdir -p "$NOTES_DIR/$PLAINDIR"
  mkdir -p "$NOTES_DIR/$ENCRYPTEDDIR"

  gpg --batch --gen-key <<EOF
%no-protection
Key-Type: RSA
Key-Length: 1024
Name-Real: mock user
Name-Email: $GPG_RECIPIENTS
Expire-Date: 0
%commit
EOF

  git init "$NOTES_DIR"

  cat >"$NOTES_DIR/.note-vault-config" <<EOF
GPG_RECIPIENTS="$GPG_RECIPIENTS"
EOF

  export ARCHIVE="encrypted/notes.tar.gz.gpg"

  cd "$NOTES_DIR" || exit

  # Source your script with mocked env
  # get the containing directory of this file
  # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
  # as those will point to the bats executable's location or the preprocessed file respectively
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
  # make executables in src/ visible to PATH
  PATH="$DIR/..:$PATH"
}
