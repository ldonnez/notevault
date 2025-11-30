#!/usr/bin/env bash
set -euo pipefail

VERSION=0.3.0 # x-release-please-version
REPO="ldonnez/notevault"

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

_get_unix_timestamp() {
  date +%s
}

# Generate sha256 from given file
_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    # GNU coreutils
    if [ "$1" = "-" ]; then
      sha256sum | awk '{print $1}'
    else
      sha256sum "$1" | awk '{print $1}'
    fi
  else
    # macOS/BSD shasum
    if [ "$1" = "-" ]; then
      shasum -a 256 | awk '{print $1}'
    else
      shasum -a 256 "$1" | awk '{print $1}'
    fi
  fi
}

# Generate sha256 signature from given directory
_dir_signature() {
  local root="$1"

  (
    cd "$root" || exit 1

    find . -type f \
      ! -name '.DS_Store' \
      ! -name '._*' \
      -print0 |
      sort -z |
      while IFS= read -r -d '' f; do
        printf "%s:%s\n" "$f" "$(_sha256 "$f")"
      done
  ) | _sha256 -
}

# Resolves the absolute path of where this script is run (it will follow symlinks)
_resolve_script_path() {
  local source="${BASH_SOURCE[0]}"
  while [ -h "$source" ]; do
    local dir
    dir="$(cd -P "$(dirname "$source")" && pwd)"

    source="$(readlink "$source")"
    [[ $source != /* ]] && source="$dir/$source"
  done
  cd -P "$(dirname "$source")" && pwd
}

###############################################################################
# Common (private)
###############################################################################

# Returns latest release version of notevault by using the Github API.
_get_latest_version() {
  curl -s https://api.github.com/repos/$REPO/releases/latest | grep tag_name | cut -d '"' -f4
}

# Determines if current installed version is older then given version. Returns exit code 1 when no upgrade is necessary, otherwise will return 0.
# Caution! Does not work with version strings like v0.1.0-alpha. Wil only work with strings like v0.1.0, v0.1.2 etc.
# See test/check_upgrade_test.bats
_check_upgrade() {
  local version="$1"
  local current_version="v$VERSION"

  local newer
  newer=$(printf '%s\n' "$version" "$current_version" | sort -V | tail -n1)

  if [ "$version" = "$current_version" ]; then
    printf "Already up to date\n"
    return 1
  elif [ "$newer" = "$version" ]; then
    printf "Upgrade available: %s -> %s\n" "$current_version" "$version"
    return 0
  else
    printf "Current version (%s) is newer than latest %s?\n" "$current_version" "$version"
    return 1
  fi
}

# Returns filename to be used as archive filename
# Format of: <timestamp>-<hostname>-<signature>
_get_archive_filename() {
  local hostname="$1"
  local dir_signature="$2"

  printf "%s" "$(_get_unix_timestamp)-$hostname-$dir_signature"
}

# Extracts sha256 from given archive filename.
# Format of filename should be <timestamp>-<hostname>-<sha256>.tar.gz.gpg
_extract_sha256_from_archive() {
  local file="$1"
  local base
  base=$(basename "$file")

  # remove .tar.gz.gpg suffix
  base="${base%.tar.gz.gpg}"

  # drop timestamp + hostname (everything up to last '-')
  sha="${base##*-}"

  # Validate that it's exactly 64 hex characters
  if printf "%s" "$sha" | grep -Eq '^[0-9a-fA-F]{64}$'; then
    printf "%s\n" "$sha"
    return 0
  fi

  printf "error: archive filename does not contain a valid SHA256: %s\n" "$file" >&2
  return 1
}

# Rotates archives in a directory for a specific host by removing the oldest archives.
# It will keep the total number of archives below given ($keep) limit.
_rotate_archives_by_host() {
  local archivedir="$1"
  local hostname="$2"
  local keep="$3"

  local archives
  archives=$(_get_archives_sorted "$ARCHIVEDIR")

  local count
  count=$(printf "%s\n" "$archives" | grep -c .)

  if ((count <= keep)); then
    return 0
  fi

  local remove_count=$((count - keep))

  printf "rotating archives for host %s (removing %d old archives)...\n" \
    "$hostname" "$remove_count"

  # Remove the oldest archives
  printf "%s\n" "$archives" |
    head -n "$remove_count" |
    while IFS= read -r old; do
      printf "removing %s\n" "$archivedir/$old"
      rm -f "$archivedir/$old"
    done
}

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

# _gpg_pinentry: Ensure GPG agent has the passphrase cached
#
# Behavior:
#   - If passphrase is cached: does nothing.
#   - If not cached and $GPG_PASSPHRASE is set: use loopback mode with that passphrase. (Used for environments without TTY like tests, CI, etc...)
#   - If not cached and $GPG_PASSPHRASE is unset: pinentry will prompt.
#
# Usage:
#   _gpg_pinentry <keyid>
_gpg_pinentry() {
  local keyid="${1:-}"

  # Step 1: test if cached (no pinentry triggered)
  if ! printf 'test' | gpg --sign \
    --batch --no-tty --pinentry-mode=error \
    ${keyid:+--local-user "$keyid"} \
    -o /dev/null 2>/dev/null; then

    printf 'Passphrase not cached — prompting...\n' >&2

    # Step 2: cache passphrase either via loopback or pinentry
    if [[ -n "${GPG_PASSPHRASE:-}" ]]; then
      printf 'test' | gpg --sign \
        --batch --yes --pinentry-mode=loopback \
        --passphrase "$GPG_PASSPHRASE" \
        ${keyid:+--local-user "$keyid"} \
        -o /dev/null
    else
      export GPG_TTY
      GPG_TTY=$(tty 2>/dev/null || true)

      printf 'test' | gpg --sign \
        --batch --no-tty \
        ${keyid:+--local-user "$keyid"} \
        -o /dev/null
    fi
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
    exit 1
  }
}

# Returns all archives in given $archivedir sorted oldest first.
_get_archives_sorted() {
  local archivedir="$1"

  # sort lexicographically (timestamp prefix ensures chronological order)
  find "$archivedir" -type f -name '*.tar.gz.gpg' -print0 2>/dev/null |
    while IFS= read -r -d '' f; do basename "$f"; done |
    sort
}

# Returns all archives in given $archivedir sorted latest first.
_check_local_changes() {
  local latest_sig="$1"

  if _dir_exists "$PLAINDIR"; then
    local current_sig
    current_sig=$(_dir_signature "$PLAINDIR")

    if [ "$current_sig" != "$latest_sig" ]; then
      printf "Local changes detected in %s — decrypt aborted.\n" "$PLAINDIR"
      exit 1
    fi
  fi
}

###############################################################################
# Core API
###############################################################################

# Upgrades nv in-place when a new version is found.
#
# Will replace notevault by resolving the path where the script is located, even if it is a symlink.
#
# Usage:
#   nv upgrade
nv_upgrade() {
  local latest_version

  if ! latest_version=$(_get_latest_version); then
    printf "Version not found."
    return 1
  fi

  if _check_upgrade "$latest_version"; then
    # Ask to confirm upgrade
    read -r -p "Do you want to upgrade now? [Y/n] " reply
    if [ -z "$reply" ] || [ "$reply" = "y" ] || [ "$reply" = "Y" ]; then
      printf "Proceeding with upgrade...\n"
    else
      printf "Upgrade cancelled.\n"
      return 0
    fi

    local url="https://github.com/$REPO/releases/download/$latest_version/nv.tar.gz"

    local script_path
    script_path=$(_resolve_script_path)

    printf "Downloading %s\n" "$url"
    curl -sSL "$url" -o /tmp/nv.tar.gz

    mkdir -p /tmp/nv && tar -xzf /tmp/nv.tar.gz -C /tmp/nv

    printf "Upgrade nv in %s...\n" "$script_path"
    install -m 0700 /tmp/nv/nv.sh "$script_path"/nv

    rm -rf /tmp/nv
    rm -f /tmp/nv.tar.gz

    printf "Upgrade success!"
    return 0
  fi
}

# Commits first then pushes to origin
#
# Usage:
#   nv_sync
nv_sync() {
  nv_commit
  git push origin HEAD
}

# Pulls latest changes of HEAD from origin.
# Stages latest changes in $ARCHIVEDIR and commits them when changes found.
#
# Usage:
#   nv_commit
nv_commit() {
  git pull origin HEAD --rebase

  git add "$ARCHIVEDIR"

  if ! git diff --cached --quiet; then
    git commit -m "$DEFAULT_GIT_COMMIT"
  fi
}

# Decrypts all and unarchives all tar.gz.gpg files to $PLAINDIR
# Starts with oldest archive first.
#
# It will exit when local changes are found to ensure not overwriting work.
#
# Usage:
#   nv_decrypt
nv_decrypt() {
  _gpg_pinentry

  local archives
  archives="$(_get_archives_sorted "$ARCHIVEDIR")"

  if [ -z "$archives" ]; then
    printf "no archives found.\n"
    return 0
  fi

  local latest_archive
  latest_archive="$(tail -n 1 <<<"$archives")"

  local latest_sha
  latest_sha=$(_extract_sha256_from_archive "$latest_archive")

  _check_local_changes "$latest_sha"

  mkdir -p "$PLAINDIR"

  # iterate and apply
  while IFS= read -r archive; do
    local archive_path="$ARCHIVEDIR/$archive"

    if ! _file_exists "$archive_path"; then
      printf "skipping missing archive %s\n" "$archive"
      continue
    fi

    local tmp="tmp-file"

    _gpg_decrypt "$archive_path" "$tmp"
    tar -xvf "$tmp" -C "$PLAINDIR"
    rm -f "$tmp"

  done <<<"$archives"

  printf "decrypted into %s\n" "$PLAINDIR"
}

# Archives, encrypts and signs the $PLAINDIR to $ARCHIVEDIR
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
  tar -C "$PLAINDIR" -czf "$tmp_archive" .

  local hostname
  hostname="$(hostname)"

  local dir_signature
  dir_signature=$(_dir_signature "$PLAINDIR")

  local archive
  archive="$ARCHIVEDIR/$(_get_archive_filename "$hostname" "$dir_signature").tar.gz.gpg"

  _gpg_encrypt "$tmp_archive" "$archive"

  rm -f "$tmp_archive"
  _rotate_archives_by_host "$ARCHIVEDIR" "$hostname" "$ARCHIVES_TO_KEEP"

  printf "encrypted -> %s\n" "$archive"
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
  version                           Print current version
  help                              Show this help message
  encrypt                           Encrypts $PLAINDIR -> $ARCHIVEDIR
  decrypt                           Decrypt $ARCHIVEDIR -> $PLAINDIR
  commit                            Creates local git commit: $DEFAULT_GIT_COMMIT with latest archive changes
  sync                              Same as commit but includes pushing to origin
  upgrade                           Upgrades nv in-place
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
  : "${DEFAULT_GIT_COMMIT:=$(hostname): add archive}"
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
    encrypt)
      nv_encrypt
      return
      ;;
    decrypt)
      nv_decrypt
      return
      ;;
    commit)
      nv_commit
      return
      ;;
    sync)
      nv_sync
      return
      ;;
    upgrade)
      nv_upgrade
      return
      ;;
    *)
      nv_help
      exit 1
      ;;
    esac
  done

  printf "Usage: nv [version | help | encrypt | decrypt | commit | sync | upgrade]\n"
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
