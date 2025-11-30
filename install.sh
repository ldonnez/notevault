#!/usr/bin/env bash
set -euo pipefail

REPO="ldonnez/notevault"
VERSION="${VERSION:-latest}"
NV_INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"

_get_version() {
  # Resolve latest version if not specified
  if [ "$VERSION" = "latest" ]; then
    curl -s https://api.github.com/repos/$REPO/releases/latest |
      grep tag_name | cut -d '"' -f4
  else
    curl -s https://api.github.com/repos/$REPO/releases/"$VERSION" |
      grep tag_name | cut -d '"' -f4
  fi
}

main() {
  local version

  if ! version=$(_get_version); then
    printf "Version not found."
    return 1
  fi

  local url="https://github.com/$REPO/releases/download/$version/nv.tar.gz"

  printf "Downloading %s\n" "$url"
  curl -sSL "$url" -o /tmp/nv.tar.gz

  mkdir -p /tmp/nv && tar -xzf /tmp/nv.tar.gz -C /tmp/nv

  printf "Installing nv to %s...\n" "$NV_INSTALL_DIR"
  mkdir -p "$NV_INSTALL_DIR"
  install -m 0700 /tmp/nv/nv.sh "$NV_INSTALL_DIR"/nv

  rm -rf /tmp/nv
  rm -rf /tmp/nv.tar.gz

  printf "Installed nv to %s\n" "$NV_INSTALL_DIR"
  printf "Make sure %s is in your PATH.\n" "$NV_INSTALL_DIR"

  return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Script is being executed directly, NOT sourced
  main "$@"
fi
