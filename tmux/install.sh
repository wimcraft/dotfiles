#!/usr/bin/env bash

# install.sh — install tmux and tpm (Tmux Plugin Manager)

set -euo pipefail

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: required command '$1' is not installed." >&2
    exit 1
  fi
}

install_tmux() {
  if command -v tmux >/dev/null 2>&1; then
    echo "• tmux already installed ($(tmux -V))"
    return
  fi

  echo "Installing tmux..."
  case "$(uname -s)" in
    Darwin)
      require_cmd brew
      brew install tmux
      ;;
    Linux)
      if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -q && sudo apt-get install -y tmux
      elif command -v yay >/dev/null 2>&1; then
        yay -S --noconfirm tmux
      elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm tmux
      elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y tmux
      else
        echo "Error: no supported package manager found. Install tmux manually." >&2
        exit 1
      fi
      ;;
    *)
      echo "Error: unsupported OS. Install tmux manually." >&2
      exit 1
      ;;
  esac
}

install_tpm() {
  local tpm_dir="${HOME}/.tmux/plugins/tpm"
  if [ -d "$tpm_dir" ]; then
    echo "• tpm already installed"
    return
  fi
  echo "Installing Tmux Plugin Manager..."
  git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
  echo "✓ tpm installed -> $tpm_dir"
}

main() {
  install_tmux
  echo "✓ tmux installed ($(tmux -V))"

  install_tpm

  echo ""
  echo "Run 'just sync tmux' to link the config, then start tmux and press prefix + I to install plugins."
}

main "$@"
