set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

default:
  @just --list

# List supported package names.
packages:
  @echo "lazyvim"
  @echo "jetbrains"
  @echo "shell"
  @echo "hammerspoon"
  @echo "zellij"
  @echo "tmux"

# Install a managed package.
install package:
  case "{{package}}" in \
    lazyvim) ./lazyvim/install.sh ;; \
    jetbrains) just jetbrains-vimrc ;; \
    tmux) ./tmux/install.sh ;; \
    *) echo "Unknown package: {{package}}" >&2; echo "Try: just packages" >&2; exit 1 ;; \
  esac

# Sync a managed package into $HOME using GNU Stow.
sync package:
  case "{{package}}" in \
    lazyvim) ./lazyvim/sync.sh ;; \
    jetbrains) just jetbrains-vimrc ;; \
    shell) ./shell/sync.sh ;; \
    hammerspoon) just hammerspoon-sync ;; \
    zellij) ./zellij/sync.sh ;; \
    tmux) ./tmux/sync.sh ;; \
    *) echo "Unknown package: {{package}}" >&2; echo "Try: just packages" >&2; exit 1 ;; \
  esac

# Link Hammerspoon config to ~/.hammerspoon/.
hammerspoon-sync:
  mkdir -p "$HOME/.hammerspoon"
  ln -sfn "$PWD/hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"
  ln -sfn "$PWD/hammerspoon/hyper.lua" "$HOME/.hammerspoon/hyper.lua"
  @echo "Linked Hammerspoon config files to $HOME/.hammerspoon/"

# Link IdeaVim config for JetBrains IDEs to ~/.ideavimrc.
jetbrains-vimrc:
  ln -sfn "$PWD/jetbrains/ideavimrc" "$HOME/.ideavimrc"
  @echo "Linked $HOME/.ideavimrc -> $PWD/jetbrains/ideavimrc"
