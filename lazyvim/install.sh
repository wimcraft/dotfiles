#!/usr/bin/env bash

# install.sh — install LazyVim starter into ~/.config/nvim

set -euo pipefail

TARGET_DIR="${HOME}/.config/nvim"
STARTER_REPO="${LAZYVIM_STARTER_REPO:-https://github.com/LazyVim/starter}"
INSTALL_FONT="${LAZYVIM_INSTALL_FONT:-1}"
NERD_FONT_NAME="${LAZYVIM_NERD_FONT_NAME:-JetBrainsMono}"
NERD_FONT_URL_BASE="${LAZYVIM_NERD_FONT_URL_BASE:-https://github.com/ryanoasis/nerd-fonts/releases/latest/download}"

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

get_font_dir() {
  case "$(uname -s)" in
    Darwin) echo "${HOME}/Library/Fonts" ;;
    Linux) echo "${HOME}/.local/share/fonts" ;;
    *) echo "" ;;
  esac
}

has_nerd_font() {
  local font_dir="$1"
  find "$font_dir" -maxdepth 1 -type f -iname "*${NERD_FONT_NAME}*Nerd*.*tf" -print -quit 2>/dev/null | grep -q .
}

install_nerd_font() {
  if [ "$INSTALL_FONT" != "1" ]; then
    echo "• Skipping font install (LAZYVIM_INSTALL_FONT=$INSTALL_FONT)"
    return
  fi

  local font_dir
  font_dir="$(get_font_dir)"
  if [ -z "$font_dir" ]; then
    echo "• Unsupported OS for automatic font install; install a Nerd Font manually."
    return
  fi

  mkdir -p "$font_dir"
  if has_nerd_font "$font_dir"; then
    echo "• Nerd Font already present in $font_dir, skipping"
    return
  fi

  if ! command -v curl >/dev/null 2>&1 || ! command -v unzip >/dev/null 2>&1; then
    echo "• curl/unzip not found; install ${NERD_FONT_NAME} Nerd Font manually."
    return
  fi

  local zip_path="${tmpdir}/${NERD_FONT_NAME}.zip"
  local url="${NERD_FONT_URL_BASE}/${NERD_FONT_NAME}.zip"

  echo "Installing ${NERD_FONT_NAME} Nerd Font..."
  if ! curl -fsSL "$url" -o "$zip_path"; then
    echo "• Failed to download font from $url"
    return
  fi

  if ! unzip -o -q "$zip_path" -d "$font_dir"; then
    echo "• Failed to unpack Nerd Font archive"
    return
  fi

  if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$font_dir" >/dev/null 2>&1 || true
  fi

  echo "✓ Installed ${NERD_FONT_NAME} Nerd Font to $font_dir"
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
  install_nerd_font

  echo "✓ LazyVim installation complete"
}

main "$@"
