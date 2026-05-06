#!/usr/bin/env bash

set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
TARGET_DIR=${HOME}
PACKAGES=(shell git x11 nvim i3 terminals desktop yazi bat)
ASSUME_YES=0
SKIP_INSTALL=0

usage() {
  cat <<'EOF'
Usage: ./bootstrap.sh [--yes] [--skip-install]

Options:
  -y, --yes         Install GNU Stow without prompting when supported.
      --skip-install  Do not try to install GNU Stow automatically.
  -h, --help        Show this help text.

What it does:
1. Checks for GNU Stow.
2. Installs GNU Stow when possible.
3. Runs a dry-run to catch conflicts safely.
4. Restows all managed packages into $HOME.
EOF
}

log() {
  printf '==> %s\n' "$*"
}

warn() {
  printf 'warning: %s\n' "$*" >&2
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

prompt_yes_no() {
  local prompt=$1
  local reply

  if [ "$ASSUME_YES" -eq 1 ]; then
    return 0
  fi

  if [ ! -t 0 ]; then
    return 1
  fi

  printf '%s [Y/n] ' "$prompt"
  read -r reply

  case "$reply" in
    ''|y|Y|yes|YES)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

install_stow() {
  if command -v stow >/dev/null 2>&1; then
    return 0
  fi

  if [ "$SKIP_INSTALL" -eq 1 ]; then
    die "GNU Stow is required. Install it first, then rerun ./bootstrap.sh."
  fi

  if command -v pacman >/dev/null 2>&1; then
    prompt_yes_no "GNU Stow is missing. Install it with pacman?" || die "Install GNU Stow first, then rerun ./bootstrap.sh."
    if [ "$ASSUME_YES" -eq 1 ]; then
      sudo pacman -S --needed --noconfirm stow
    else
      sudo pacman -S --needed stow
    fi
    return 0
  fi

  if command -v apt-get >/dev/null 2>&1; then
    prompt_yes_no "GNU Stow is missing. Install it with apt-get?" || die "Install GNU Stow first, then rerun ./bootstrap.sh."
    sudo apt-get update
    sudo apt-get install -y stow
    return 0
  fi

  if command -v dnf >/dev/null 2>&1; then
    prompt_yes_no "GNU Stow is missing. Install it with dnf?" || die "Install GNU Stow first, then rerun ./bootstrap.sh."
    sudo dnf install -y stow
    return 0
  fi

  if command -v brew >/dev/null 2>&1; then
    prompt_yes_no "GNU Stow is missing. Install it with Homebrew?" || die "Install GNU Stow first, then rerun ./bootstrap.sh."
    brew install stow
    return 0
  fi

  die "GNU Stow is not installed and no supported package manager was detected."
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -y|--yes)
        ASSUME_YES=1
        ;;
      --skip-install)
        SKIP_INSTALL=1
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "Unknown option: $1"
        ;;
    esac
    shift
  done
}

check_packages() {
  local package

  for package in "${PACKAGES[@]}"; do
    [ -d "$REPO_DIR/$package" ] || die "Missing package directory: $package"
  done
}

run_stow() {
  log "Dry-running stow to detect conflicts"
  if ! stow -d "$REPO_DIR" -nv -t "$TARGET_DIR" "${PACKAGES[@]}"; then
    warn "Dry-run reported conflicts. Resolve them first, then rerun ./bootstrap.sh."
    exit 1
  fi

  log "Applying stow packages into $TARGET_DIR"
  stow -d "$REPO_DIR" -Rv -t "$TARGET_DIR" "${PACKAGES[@]}"
}

main() {
  parse_args "$@"
  check_packages
  install_stow
  command -v stow >/dev/null 2>&1 || die "GNU Stow is still unavailable after installation attempt."
  run_stow
  log "Bootstrap complete"
}

main "$@"
