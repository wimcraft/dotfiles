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

zellij_cache_dir() {
  if [[ "$(uname)" == "Darwin" ]]; then
    echo "${HOME}/Library/Caches/org.Zellij-Contributors.Zellij"
  else
    echo "${XDG_CACHE_HOME:-${HOME}/.cache}/zellij"
  fi
}

ZJSTATUS_VERSION="v0.21.1"
ZJSTATUS_URL="https://github.com/dj95/zjstatus/releases/download/${ZJSTATUS_VERSION}/zjstatus.wasm"
ZJSTATUS_DEST="${HOME}/.config/zellij/plugins/zjstatus.wasm"

ROOM_VERSION="v1.2.1"
ROOM_URL="https://github.com/rvcas/room/releases/download/${ROOM_VERSION}/room.wasm"
ROOM_DEST="${HOME}/.config/zellij/plugins/room.wasm"

download_plugins() {
  mkdir -p "$(dirname "$ZJSTATUS_DEST")"

  if [[ -f "$ZJSTATUS_DEST" ]]; then
    echo "• zjstatus already present, skipping download"
  else
    echo "Downloading zjstatus ${ZJSTATUS_VERSION}..."
    curl -fsSL "$ZJSTATUS_URL" -o "$ZJSTATUS_DEST"
    echo "✓ Downloaded zjstatus -> $ZJSTATUS_DEST"
  fi

  if [[ -f "$ROOM_DEST" ]]; then
    echo "• room already present, skipping download"
  else
    echo "Downloading room ${ROOM_VERSION}..."
    curl -fsSL "$ROOM_URL" -o "$ROOM_DEST"
    echo "✓ Downloaded room -> $ROOM_DEST"
  fi
}

install_permissions() {
  local cache_dir
  cache_dir="$(zellij_cache_dir)"
  local dest="${cache_dir}/permissions.kdl"
  local template="${SCRIPT_DIR}/permissions.kdl.template"

  mkdir -p "$cache_dir"
  sed "s|{HOME}|${HOME}|g" "$template" > "$dest"
  echo "✓ Installed plugin permissions -> $dest"
}

main() {
  require_cmd stow

  backup_zellij_if_needed

  echo "Syncing $PACKAGE_NAME with stow..."
  (
    cd "$REPO_ROOT"
    stow --target "$TARGET_DIR" "$PACKAGE_NAME"
  )

  download_plugins
  install_permissions

  echo "✓ Sync complete"
}

main "$@"
