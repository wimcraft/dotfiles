#!/usr/bin/env bash

# install.sh — install LazyVim starter into ~/.config/nvim

set -euo pipefail

TARGET_DIR="${HOME}/.config/nvim"
STARTER_REPO="${LAZYVIM_STARTER_REPO:-https://github.com/LazyVim/starter}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: required command '$1' is not installed." >&2
    exit 1
  fi
}

is_non_empty_dir() {
  local dir="$1"
  [ -d "$dir" ] && [ -n "$(find "$dir" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]
}

main() {
  require_cmd git
  require_cmd mktemp

  mkdir -p "${HOME}/.config"

  if [ -L "$TARGET_DIR" ]; then
    echo "Error: $TARGET_DIR is a symlink."
    echo "Run 'just sync lazyvim' for stow-based config, or remove the symlink first."
    exit 1
  fi

  if is_non_empty_dir "$TARGET_DIR"; then
    local backup_path="${TARGET_DIR}.bak.$(date +%Y%m%d%H%M%S)"
    mv "$TARGET_DIR" "$backup_path"
    echo "✓ Backed up existing config -> $backup_path"
  fi

  local tmpdir
  tmpdir="$(mktemp -d)"
  trap 'if [ -n "${tmpdir:-}" ]; then rm -rf "$tmpdir"; fi' EXIT

  echo "Cloning LazyVim starter..."
  git clone "$STARTER_REPO" "$tmpdir/starter"
  rm -rf "$tmpdir/starter/.git"

  mkdir -p "$TARGET_DIR"
  cp -a "$tmpdir/starter/." "$TARGET_DIR/"
  echo "✓ Installed starter into $TARGET_DIR"

  echo "✓ LazyVim installation complete"
}

main "$@"
