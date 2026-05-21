#!/usr/bin/env bash

# sync.sh — stow tmux config from tmux/.config/tmux -> ~/.config/tmux

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE_NAME="tmux"
TARGET_DIR="${HOME}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: required command '$1' is not installed." >&2
    exit 1
  fi
}

backup_if_needed() {
  local path="${HOME}/.config/tmux"

  if [ -L "$path" ]; then
    echo "• Removing existing symlink $path"
    rm "$path"
    return
  fi

  if [ -e "$path" ]; then
    local backup="${path}.bak.$(date +%Y%m%d%H%M%S)"
    mv "$path" "$backup"
    echo "✓ Backed up $path -> $backup"
  else
    echo "• No existing $path found, skipping backup"
  fi
}

main() {
  require_cmd stow

  backup_if_needed

  echo "Syncing $PACKAGE_NAME with stow..."
  (
    cd "$REPO_ROOT"
    stow --target "$TARGET_DIR" "$PACKAGE_NAME"
  )

  echo "✓ Sync complete"

  if [ ! -d "${HOME}/.tmux/plugins/tpm" ]; then
    echo ""
    echo "Note: tpm not found. Install it with:"
    echo "  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm"
    echo "Then start tmux and press prefix + I to install plugins."
  fi
}

main "$@"
