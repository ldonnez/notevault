#!/usr/bin/env bash
set -euo pipefail

VERSION=0.0.1 # x-release-please-version

# Prints current version of nv
#
# Usage:
#   nv --version
nv_version() {
  printf "%s\n" "v$VERSION"
}

nv_help() {
  cat <<EOF
Usage: nv [COMMAND]

Commands:
  version                           Print current version
  help                              Show this help message
  encrypt                           Encrypts $PLAINDIR -> $ARCHIVEDIR
  decrypt                           Decrypt $ARCHIVEDIR -> $PLAINDIR
EOF
}

###############################################################################
# Setup
###############################################################################

# Set default global variables
# Variables prefixed with _ should not be overriden.
_set_default_values() {
  : "${REPO_ROOT:=$(git rev-parse --show-toplevel)}"
  : "${GPG_RECIPIENTS:=}"
  : "${_CONFIG_FILE:=$REPO_ROOT/.note-vault-config}"
  : "${PLAINDIR:=$REPO_ROOT/notes}"
  : "${ARCHIVEDIR:=$REPO_ROOT/archives}"
  : "${ARCHIVES_TO_KEEP:=10}"
}

# Initializes $ARCHIVEDIR
_setup_directories() {
  # Create directories if not exist
  mkdir -p "$ARCHIVEDIR"
}

_load_config() {
  # Ensure we're inside a git repo
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf "not inside a git repository.\n"
    exit 1
  fi

  _set_default_values

  # Load repo-specific config
  if [ -f "$_CONFIG_FILE" ]; then
    # shellcheck source=/dev/null
    source "$_CONFIG_FILE"
  fi

  _setup_directories
}

_parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
    help)
      nv_help
      exit 0
      ;;
    version)
      nv_version
      return
      ;;
    --encrypt)
      nv_encrypt
      return
      ;;
    --decrypt)
      nv_decrypt
      return
      ;;
    *)
      nv_help
      exit 1
      ;;
    esac
  done

  printf "Usage: nv [version | help]\n"
  exit 1
}

# Entrypoint
main() {
  _load_config
  _parse_args "$@"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Script is being executed directly, NOT sourced
  main "$@"
fi
