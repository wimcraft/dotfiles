set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

default:
  @just --list

# List supported package names.
packages:
  @echo "lazyvim"

# Install a managed package.
install package:
  case "{{package}}" in \
    lazyvim) ./lazyvim/install.sh ;; \
    *) echo "Unknown package: {{package}}" >&2; echo "Try: just packages" >&2; exit 1 ;; \
  esac

# Sync a managed package into $HOME using GNU Stow.
sync package:
  case "{{package}}" in \
    lazyvim) ./lazyvim/sync.sh ;; \
    *) echo "Unknown package: {{package}}" >&2; echo "Try: just packages" >&2; exit 1 ;; \
  esac
