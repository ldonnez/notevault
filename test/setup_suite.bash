setup_suite() {
  # Use readlink -f to follow symlinks here since macOS symlinks temp from /var/... to /private/var/
  TEST_HOME="$(readlink -f "$(mktemp -d)")"
  export TEST_HOME
  export HOME="$TEST_HOME"
  export REPO_ROOT="$TEST_HOME/test-notes"
  export GPG_RECIPIENTS="mock@example.com"
  export PLAINDIR="$REPO_ROOT/notes"
  export ARCHIVEDIR="$REPO_ROOT/archives"
  export ARCHIVES_TO_KEEP=10

  mkdir -p "$REPO_ROOT"
  mkdir -p "$PLAINDIR"
  mkdir -p "$ARCHIVEDIR"

  gpg --batch --gen-key <<EOF
%no-protection
Key-Type: RSA
Key-Length: 1024
Name-Real: mock user
Name-Email: $GPG_RECIPIENTS
Expire-Date: 0
%commit
EOF

  git init "$REPO_ROOT"
  git config --global user.email "mock@example.com"
  git config --global user.name "mock example"

  cat >"$REPO_ROOT/.note-vault-config" <<EOF
GPG_RECIPIENTS="$GPG_RECIPIENTS"
EOF

  cd "$REPO_ROOT" || exit

  # Source your script with mocked env
  # get the containing directory of this file
  # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
  # as those will point to the bats executable's location or the preprocessed file respectively
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
  # make executables in src/ visible to PATH
  PATH="$DIR/..:$PATH"
}

teardown_suite() {
  rm -rf "$TEST_HOME"
}
