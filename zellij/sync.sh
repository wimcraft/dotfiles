#!/usr/bin/env bash

# sync.sh — stow zellij config from zellij/zellij -> ~/.config/zellij

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE_NAME="zellij"
TARGET_DIR="${HOME}/.config"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: required command '$1' is not installed." >&2
    exit 1
  fi
}

backup_zellij_if_needed() {
  local zellij_path="${HOME}/.config/zellij"

  if [ -L "$zellij_path" ]; then
    echo "• Removing existing symlink $zellij_path"
    rm "$zellij_path"
    return
  fi

  if [ -e "$zellij_path" ]; then
    local backup_path="${zellij_path}.bak.$(date +%Y%m%d%H%M%S)"
    mv "$zellij_path" "$backup_path"
    echo "✓ Backed up $zellij_path -> $backup_path"
  else
    echo "• No existing $zellij_path found, skipping backup"
  fi
}

main() {
  require_cmd stow

  backup_zellij_if_needed

  echo "Syncing $PACKAGE_NAME with stow..."
  (
    cd "$REPO_ROOT"
    stow --target "$TARGET_DIR" "$PACKAGE_NAME"
  )

  echo "✓ Sync complete"
}

main "$@"
