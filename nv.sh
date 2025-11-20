#!/usr/bin/env bash
set -euo pipefail

VERSION=0.0.1 # x-release-please-version

# Prints current version of memo
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
  --version                           Print current version
  --help                              Show this help message
EOF
}

_parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
    --help)
      nv_help
      exit 0
      ;;
    --version)
      nv_version
      return
      ;;
    --)
      shift
      break
      ;;
    -*)
      nv_help
      exit 1
      ;;
    esac
  done

  printf "Usage: nv [--version | --help]\n"
  exit 1
}

# Entrypoint
main() {
  _parse_args "$@"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Script is being executed directly, NOT sourced
  main "$@"
fi
