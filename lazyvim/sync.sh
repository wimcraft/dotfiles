#!/usr/bin/env bash

# sync.sh — stow LazyVim config from lazyvim/nvim -> ~/.config/nvim

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE_NAME="lazyvim"
TARGET_DIR="${HOME}/.config"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: required command '$1' is not installed." >&2
    exit 1
  fi
}

backup_nvim_if_needed() {
  local nvim_path="${HOME}/.config/nvim"

  if [ -L "$nvim_path" ]; then
    echo "• $nvim_path is already a symlink, skipping backup"
    return
  fi

  if [ -e "$nvim_path" ]; then
    local backup_path="${nvim_path}.bak.$(date +%Y%m%d%H%M%S)"
    mv "$nvim_path" "$backup_path"
    echo "✓ Backed up $nvim_path -> $backup_path"
  else
    echo "• No existing $nvim_path found, skipping backup"
  fi
}

main() {
  require_cmd stow

  backup_nvim_if_needed

  echo "Syncing $PACKAGE_NAME with stow..."
  (
    cd "$REPO_ROOT"
    stow --target "$TARGET_DIR" "$PACKAGE_NAME"
  )

  echo "✓ Sync complete"
}

main "$@"
