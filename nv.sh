#!/usr/bin/env bash
set -euo pipefail

VERSION=0.1.0 # x-release-please-version

###############################################################################
# Helpers (private)
###############################################################################

_dir_exists() {
  [[ -d "$1" ]]
}

_file_exists() {
  local filepath="$1"
  [[ -f "$filepath" ]]
}

# Trim leading or trailing spaces of a string
_trim() {
  local string="$1"

  # trim leading spaces
  string="${string#"${string%%[! ]*}"}"

  # trim trailing spaces
  string="${string%"${string##*[! ]}"}"
  printf "%s" "$string"
}

###############################################################################
# Common (private)
###############################################################################

# Validates if all the given recipients exist in GPG keyring.
_gpg_recipients_exists() {
  local recipients="$1"
  local missing_keys=()

  IFS=',' read -ra keys <<<"$recipients"

  if ((${#keys[@]} > 0)); then
    for key in "${keys[@]}"; do
      key="$(_trim "$key")"

      if ! gpg --list-keys "$key" &>/dev/null; then
        missing_keys+=("$key")
      fi
    done
  fi

  if ((${#missing_keys[@]} > 0)); then
    printf "GPG recipient(s) not found: %s\n" "${missing_keys[*]}" >&2
    exit 1
  fi
}

# Builds the gpg recipients (-r param in gpg) based on given key_ids
# When given key_ids is empty, --default-recipient-self is given, which means the first key found in the keyring is used as a recipient.
# returns array of "-r <key_id> -r <key_id2>"
#
# Usage:
#
# ```
# local -a recipients=()
#
# if ! _build_gpg_recipients "$GPG_RECIPIENTS" recipients; then
#   return 1
# fi
#
# gpg --quiet --yes --armor --encrypt "${recipients[@]}"...
# ```
_build_gpg_recipients() {
  local gpg_recipients="$1"
  local output_array="$2"

  if [[ -z "$gpg_recipients" ]]; then
    eval "$output_array+=(\"--default-recipient-self\")"
    return 0
  fi

  local IFS=',' items
  read -r -a items <<<"$gpg_recipients"

  if [[ ${#items[@]} -eq 0 ]]; then
    eval "$output_array+=(\"--default-recipient-self\")"
    return 0
  fi

  local id
  for id in "${items[@]}"; do
    id=$(_trim "$id")
    [[ -z "$id" ]] && continue

    if ! _gpg_recipients_exists "$id"; then
      printf "GPG recipient(s) not found: %s\n" "$id" >&2
      return 1
    fi

    eval "$output_array+=(\"-r\" \"$id\")"
  done
}

# Encrypts the content of given input file (path) to given output file (path)
# This will encrypt the file itself.
_gpg_encrypt() {
  # Sets output_path to input_path when output_path is not given
  local input_path="$1" output_path="${2-$1}"

  if ! _file_exists "$input_path"; then
    printf "file not found: %s" "$input_path"
    exit 1
  fi

  local -a recipients=()

  if ! _build_gpg_recipients "$GPG_RECIPIENTS" recipients; then
    return 1
  fi

  gpg --quiet --yes --encrypt "${recipients[@]}" -o "$output_path" "$input_path"
}

# Decrypts given input file (path) to given output file (path)
_gpg_decrypt() {
  local input_path="$1" output_path="${2-""}"

  if ! _file_exists "$input_path"; then
    printf "File not found: %s" "$input_path"
    exit 1
  fi

  gpg --quiet --yes --decrypt "$input_path" >"$output_path" || {
    printf "Failed to decrypt %s\n" "$input_path" >&2
    return 1
  }
}

###############################################################################
# Core API
###############################################################################

# Decrypts encrypted archive to $PLAINDIR with gpg
#
# It will exit if $ARCHIVE does not exist
#
# Usage:
#   nv_decrypt
nv_decrypt() {
  if ! _file_exists "$ARCHIVE"; then
    printf "encrypted archive not found: %s\n" "$ARCHIVE"
    exit 1
  fi

  local tmp_archive="$PLAINDIR.tar.gz"

  gpg -o "$tmp_archive" --decrypt "$ARCHIVE"

  tar -xzf "$tmp_archive"
  rm -f "$tmp_archive"

  printf "decrypted into %s\n" "$PLAINDIR"
}

# Archives (with tar) and encrypts te archived file to $ARCHIVE
#
# It will exit if $PLAINDIR does not exist
#
# Usage:
#   nv_encrypt
nv_encrypt() {
  if ! _dir_exists "$PLAINDIR"; then
    printf "%s does not exist." "$PLAINDIR"
    exit 1
  fi

  local tmp_archive="$PLAINDIR.tar.gz"

  printf "creating tarball...\n"
  tar -czf "$tmp_archive" "$PLAINDIR"

  _gpg_encrypt "$tmp_archive" "$ARCHIVE"

  rm -f "$tmp_archive"

  printf "encrypted -> %s\n" "$ARCHIVE"
}

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
  --version                           Print current version
  --help                              Show this help message
  --encrypt                           Encrypts $PLAINDIR -> $ARCHIVE
  --decrypt                           Decrypt $ARCHIVE -> $PLAINDIR
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
  : "${PLAINDIR:=notes}"
  : "${ENCRYPTEDDIR:=encrypted}"
}

# Initializes $PLAINDIR, $ENCRYPTEDDIR
_setup_directories() {
  # Create directories if not exist
  mkdir -p "$PLAINDIR"
  mkdir -p "$ENCRYPTEDDIR"
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

  : "${ARCHIVE:=$ENCRYPTEDDIR/$PLAINDIR.tar.gz.gpg}"
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
    --encrypt)
      nv_encrypt
      return
      ;;
    --decrypt)
      nv_decrypt
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

  printf "Usage: nv [--version | --help | --encrypt]\n"
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
