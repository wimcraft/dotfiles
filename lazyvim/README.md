# LazyVim Dotfiles Package

This package manages Neovim config as:

- Repo path: `lazyvim/nvim`
- Target path: `~/.config/nvim`

## Direct Stow Usage

Run from the dotfiles repo root:

```bash
stow --target="$HOME/.config" lazyvim
```

This creates:

- `~/.config/nvim -> <repo>/lazyvim/nvim`

Unstow:

```bash
stow -D --target="$HOME/.config" lazyvim
```

## Just Commands

- `just install lazyvim`
  - Installs LazyVim starter into `~/.config/nvim`
  - Backs up existing non-empty `~/.config/nvim` to `~/.config/nvim.bak.<timestamp>`
- `just sync lazyvim`
  - Stows `lazyvim/nvim` into `~/.config/nvim`
  - Backs up existing non-symlink `~/.config/nvim` to `~/.config/nvim.bak.<timestamp>`
