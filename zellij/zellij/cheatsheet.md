# Zellij Cheatsheet

## Prefix Keys
| Key | Mode |
|-----|------|
| `Ctrl+s` | Tmux mode (main prefix) |
| `Ctrl+t` | Tab mode |
| `Alt+p`  | Pane mode |
| `Alt+n`  | Resize mode |
| `Ctrl+h` | Move mode |
| `Ctrl+o` | Session mode |
| `Alt+c`  | Scroll/Copy mode |
| `Alt+g`  | Locked mode (for nested sessions) |

## Tmux Mode (`Ctrl+s`)
| Key | Action |
|-----|--------|
| `c` | New tab |
| `v` | Split right |
| `s` | Split down |
| `x` | Close tab |
| `,` | Rename tab |
| `h/j/k/l` | Move focus |
| `n/p` | Next/Previous tab |
| `1-9` | Go to tab |
| `z` | Toggle fullscreen (zoom) |
| `e` | Edit scrollback in vim |
| `/` | Search mode |
| `d` | Detach |
| `w` | Session picker (room plugin) |
| `?` | This cheatsheet |

## Pane Mode (`Alt+p`)
| Key | Action |
|-----|--------|
| `n` | New pane |
| `r` | Split right |
| `d` | Split down |
| `x` | Close pane |
| `f` | Toggle fullscreen |
| `w` | Toggle floating |
| `e` | Toggle embed/floating |
| `z` | Toggle pane frames |
| `c` | Rename pane |

## Tab Mode (`Ctrl+t`)
| Key | Action |
|-----|--------|
| `n` | New tab |
| `x` | Close tab |
| `r` | Rename tab |
| `[/]` | Break pane left/right |
| `b` | Break pane to new tab |
| `s` | Sync tab |

## Scroll/Copy Mode (`Alt+c`)
| Key | Action |
|-----|--------|
| `j/k` | Scroll down/up |
| `d/u` | Half page down/up |
| `Ctrl+f/b` | Page down/up |
| `s` | Search |
| `e` | Edit scrollback in vim |
| `Ctrl+c` | Exit to normal |

## Session Mode (`Ctrl+o`)
| Key | Action |
|-----|--------|
| `w` | Session manager |
| `c` | Configuration |
| `p` | Plugin manager |
| `d` | Detach |

## Global Shortcuts (Always available)
| Key | Action |
|-----|--------|
| `Alt+h/j/k/l` | Move focus |
| `Alt+1-9` | Go to tab |
| `Alt+f` | Toggle floating panes |
| `Alt+n` | New pane |
| `Alt+[/]` | Prev/Next layout |
| `Alt+i/o` | Move tab left/right |
| `Ctrl+q` | Quit |

## Nested Sessions (SSH)
When running zellij inside zellij (e.g., over SSH):
1. Press `Alt+g` to enter **locked mode**
2. All keys now pass to inner session
3. Press `Alt+g` again to exit locked mode

## Shell Aliases
```
zj        # Start zellij
zzz       # Start with tmux layout
zls       # List sessions
zat       # Attach with fzf picker
zn NAME   # New named session
zkill     # Kill session (fzf picker)
zclean    # Delete all dead sessions
```

## Sessions Quick Reference
```bash
zellij                       # New session
zellij -s myproject          # Named session
zellij attach myproject      # Attach to session
zellij ls                    # List sessions
zellij kill-session NAME     # Kill session
zellij delete-session NAME   # Delete dead session
zellij delete-all-sessions   # Clean up all dead
```
