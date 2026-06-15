# Chezmoi Dotfiles (Arch/Niri)

## Rules

- **Edit source** in `~/.local/share/chezmoi/`, NEVER live configs in `$HOME`
- **Never global apply** — always `chezmoi apply --source-path "file"`
- Find source path: `chezmoi source-path ~/.config/some/file`
- List managed: `chezmoi managed`

## Source Naming (prefix order matters)

Regular: `encrypted_` → `private_` → `readonly_` → `empty_` → `executable_` → `dot_` + `.tmpl`
Scripts: `run_` + `once_|onchange_` + `before_|after_` + `.tmpl`
Symlinks: `symlink_` + `dot_` + `.tmpl` (content = link target)
Dirs: `remove_|external_|exact_|private_|readonly_|dot_` (no .tmpl)

Examples: `dot_gitconfig` → `~/.gitconfig` · `private_dot_config/niri/config.kdl` → `~/.config/niri/config.kdl` (0600) · `executable_dot_local_bin_hello` → `~/.local/bin/hello` (+x) · `dot_gitconfig.tmpl` → `~/.gitconfig` (templated)

## Template & Secrets

Vars: `{{ .name }}`, `{{ .email }}`, `{{ .github_username }}` (from `.chezmoi.toml.tmpl`)
Secrets: Bitwarden CLI — `{{ (bitwarden "item" "Name").notes | trim }}` in `environment.d/*.conf.tmpl`

## Environment

Arch/Niri (Wayland) · fish + tmux · alacritty · nvim/vscode-insiders · pacman/paru + mise · uv (not pip) · rg (not grep)

## Config Layout

`dot_gitconfig.tmpl` · `dot_tmux.conf` · `private_dot_zshrc.tmpl` · `dot_ssh/authorized_keys.tmpl`
`private_dot_config/` → environment.d/ · niri/ (cfg/\*.kdl) · nvim/ · fish/ · opencode/ · alacritty/ · waybar/ · starship/ · zed/ · mise/
`private_dot_local/bin/`

## Workflow

1. Edit source → 2. `chezmoi diff` or `--dry-run` → 3. `chezmoi apply --source-path "file"` → 4. Validate niri: `niri validate`
   Add new: `chezmoi add ~/.config/new-app/config`. This file excluded via `.chezmoiignore`.

