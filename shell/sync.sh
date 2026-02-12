#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMMON_SRC="${REPO_ROOT}/shell/commonrc"
COMMON_FILE="${HOME}/.commonrc"

append_common_bridge_if_missing() {
  local file="$1"

  ensure_physical_file "$file"

  if ! grep -Eq '(^|[[:space:]])(source|\.)[[:space:]]+~/.commonrc([[:space:]]|$)' "$file"; then
    cat >> "$file" <<'BLOCK'

# --- Load Common Config (Managed by Dotfiles) ---
# This loads the tracked config from the repo while keeping this file local
if [ -f ~/.commonrc ]; then
    source ~/.commonrc
fi
BLOCK
  fi
}

append_line_if_missing() {
  local file="$1"
  local line="$2"

  ensure_physical_file "$file"
  grep -Fqx "$line" "$file" || printf '\n%s\n' "$line" >> "$file"
}

ensure_physical_file() {
  local file="$1"

  if [ -L "$file" ]; then
    local tmp
    tmp="$(mktemp)"
    cat "$file" > "$tmp" 2>/dev/null || true
    rm -f "$file"
    cat "$tmp" > "$file"
    rm -f "$tmp"
  fi

  touch "$file"
}

link_commonrc() {
  if [ ! -f "$COMMON_SRC" ]; then
    echo "Error: missing source file: $COMMON_SRC" >&2
    exit 1
  fi

  if [ -e "$COMMON_FILE" ] && [ ! -L "$COMMON_FILE" ]; then
    local backup="${COMMON_FILE}.bak.$(date +%Y%m%d%H%M%S)"
    mv "$COMMON_FILE" "$backup"
    echo "✓ Backed up existing $COMMON_FILE -> $backup"
  fi

  ln -sfn "$COMMON_SRC" "$COMMON_FILE"
  echo "✓ Linked $COMMON_FILE -> $COMMON_SRC"
}

main() {
  link_commonrc

  append_common_bridge_if_missing "$HOME/.bashrc"
  append_common_bridge_if_missing "$HOME/.zshrc"

  # Add manual reload aliases in profiles.
  append_line_if_missing "$HOME/.bash_profile" "alias sourcerc='[ -f ~/.bashrc ] && source ~/.bashrc'"
  append_line_if_missing "$HOME/.zprofile" "alias sourcerc='[ -f ~/.zshrc ] && source ~/.zshrc'"

  echo "✓ Shell sync complete"
}

main "$@"
