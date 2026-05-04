# Agent Guidelines

## This is a chezmoi dotfiles repository

Edit source files here (`~/.local/share/chezmoi`), not the live configs in `$HOME`.

## Applying changes

- **Never use global apply** (`chezmoi apply` without args)
- **Never apply automatically** — only when explicitly requested
- Apply only the specific file changed: `chezmoi apply "<relative/path>"`
- Example: `chezmoi apply "dot_gitconfig.tmpl"`

## Template data & variables

Defined in `chezmoi data`:
- `{{ .name }}`, `{{ .email }}`, `{{ .github_username }}`
- `{{ .chezmoi.hostname }}` (cocoar), `{{ .chezmoi.os }}`, `{{ .chezmoi.arch }}`
- `{{ .chezmoi.osRelease.id }}` (cachyos)

chezmoi is configured with `template.options = ["missingkey=error"]` — undefined template vars will **error**.

## Secrets management

Bitwarden CLI (`bw`) is used for API keys and secrets. Template files call it directly:
```
{{ (bitwarden "item" "Context7 API Key").notes | trim }}
```
API keys are also exported at runtime via `~/.config/environment.d/10-misc.conf.tmpl`.

## Config structure

- `dot_*` files → `$HOME/.<filename>` (e.g., `dot_gitconfig.tmpl` → `~/.gitconfig`)
- `private_dot_*` files → private config (not shared)
- `executable_*` files → `$HOME/.local/bin/<filename>` (e.g., `executable_hello` → `~/.local/bin/hello`)
- `*.tmpl` suffix → chezmoi templates; 
- niri config: `private_dot_config/niri/config.kdl` includes `cfg/*.kdl` + `noctalia.kdl`
- OpenCode config lives in dotfiles at `private_dot_config/opencode/opencode.jsonc`
- Environment variables loaded from `~/.config/environment.d/*.conf` (sourced by fish)
- `dot_tmux.conf` uses TPM plugins: tmux-resurrect, tmux-continuum, tmux-dotbar, tmux-menus

## Conventions

- Shell: fish + tmux (vi mode, base-index 1)
- Plugins: zoxide, fzf, starship, tmux-resurrect, tmux-continuum
- Tool version manager: mise
- Package managers: pacman/paru (AUR helper auto-detected), mise for global tools
- Python: uv (not pip)
- Search: rg (not grep)
- Code style: camelCase (vars/func), PascalCase (types), UPPER_SNAKE_CASE (const); kebab-case files
- AGENTS.md is excluded from chezmoi via `.chezmoiignore`
