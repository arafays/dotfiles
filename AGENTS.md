# Agent Guidelines

## This is a chezmoi dotfiles repository

Edit source files here (`~/.local/share/chezmoi`), not the live configs in `$HOME`. Use `chezmoi apply <path>` to apply a specific changed file to the home directory.

## Applying changes

- **Never use global apply** (`chezmoi apply` without args)
- **Never apply automatically** - only apply when explicitly requested
- **Ask user before applying** any file
- Apply only the specific file that was changed, using: `chezmoi apply "<relative/path>"`
- Ask the user to apply the file to change. give command to apply only of the changed file, not all files. For example: `chezmoi apply "dot_gitconfig.tmpl"`

## Conventions

- Shell: fish + tmux
- plugins: zoxide, fzf, starship, tmux-resurrect, tmux-continuum
- mise
- Package manager: pacman/paru, mise for global tool versions
- Search: ripgrep (rg), not grep
- Be concise and technical; no preamble or explanations unless asked

## Config structure

- `dot_*` files → apply to `$HOME/.<filename>` (e.g., `dot_gitconfig.tmpl` → `~/.gitconfig`)
- `private_dot_*` files → private config (not shared), apply to `$HOME/.<filename>`
- `*.tmpl` suffix → chezmoi templates with `.chezmoitemplate` variables
- niri config uses kdl format with includes in `private_dot_config/niri/cfg/`
