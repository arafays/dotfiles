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

## WORKFLOW

1. EDIT SOURCE → 2. `CHEZMOI DIFF` OR `--DRY-RUN` → 3. `CHEZMOI APPLY --SOURCE-PATH "FILE"` → 4. VALIDATE NIRI: `NIRI VALIDATE`
   ADD NEW: `CHEZMOI ADD ~/.CONFIG/NEW-APP/CONFIG`. THIS FILE EXCLUDED VIA `.CHEZMOIIGNORE`.
