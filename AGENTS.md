# Chezmoi Dotfiles (CachyOS / Niri)

## Rules

- **Edit source files** in `~/.local/share/chezmoi/`, **never** live configs in `$HOME`.
- **Never run global apply** (`chezmoi apply` without args).
- Apply only the changed file: `chezmoi apply --source-path "<source-path>"`.
  - The path is **source-relative** and must include chezmoi prefixes/suffixes (`private_`, `dot_`, `.tmpl`, etc.).
  - Without `--source-path`, chezmoi treats it as a target path and fails with "not managed".
  - Examples:
    - `chezmoi apply --source-path "dot_gitconfig.tmpl"`
    - `chezmoi apply --source-path "private_dot_config/niri/config.kdl"`
    - `chezmoi apply --source-path "executable_dot_local_bin_hello"`
- Find the source path for a target: `chezmoi source-path ~/.config/some/file`
- List tracked files: `chezmoi managed`

## Source Naming

chezmoi encodes behavior in source filenames. Prefix order matters.

- Regular: `encrypted_` → `private_` → `readonly_` → `empty_` → `executable_` → `dot_` + `.tmpl`
- Scripts: `run_` → `once_|onchange_` → `before_|after_` + `.tmpl`
- Symlinks: `symlink_` → `dot_` + `.tmpl` (content = link target)
- Dirs: `remove_|external_|exact_|private_|readonly_|dot_` (no `.tmpl`)

Examples:
`dot_gitconfig` → `~/.gitconfig` · `dot_gitconfig.tmpl` → templated `~/.gitconfig` · `private_dot_config/niri/config.kdl` → `~/.config/niri/config.kdl` (0600) · `executable_dot_local_bin_hello` → `~/.local/bin/hello` (+x)

## Templates & Secrets

Template vars from `.chezmoi.toml.tmpl`: `{{ .name }}`, `{{ .email }}`, `{{ .github_username }}`.
`template.options = ["missingkey=error"]` — undefined template vars fail.

Secrets via Bitwarden CLI: `{{ (bitwarden "item" "Name").notes | trim }}`.
API keys are exported at runtime via `private_dot_config/environment.d/*.conf.tmpl`.

## Environment

- OS: CachyOS (Arch-based) · WM: Niri (Wayland)
- Shell: fish + tmux (vi mode, base-index 1)
- Terminals: alacritty, kitty
- Editors: nvim, vscode-insiders, zed
- Package managers: pacman/paru (AUR helper auto-detected), mise for global tools
- Python: uv (not pip)
- Search: rg (not grep)
- `environment.d/*.conf` is sourced by fish via `fenv`

## Config Layout

- `dot_gitconfig.tmpl` · `dot_tmux.conf` · `dot_profile`
- `private_dot_config/`
  - `niri/config.kdl` — only includes `cfg/*.kdl` + `noctalia.kdl`; edit files under `niri/cfg/`
  - `noctalia/plugins/symlink_*` — plugin dirs are symlinks (content = target path)
  - `opencode/opencode.jsonc` — OpenCode config
  - `environment.d/` · `fish/` · `nvim/` · `alacritty/` · `kitty/` · `mise/` · `starship/` · `yazi/` · `zed/`
- `private_dot_local/bin/` — executable scripts
- `run_onchange_*` scripts under `.chezmoiscripts/`

## Workflow

1. Edit source.
2. Preview: `chezmoi diff` or `chezmoi apply --source-path "file" --dry-run`.
3. Apply: `chezmoi apply --source-path "file"`.
4. After any Niri change: `niri validate` before restarting.

## Notes

- `AGENTS.md`, `.skills/`, `.opencode/`, `**/niri/noctalia.kdl`, and Python artifacts are excluded via `.chezmoiignore`.
- Code style: camelCase (vars/funcs), PascalCase (types), UPPER_SNAKE_CASE (const); kebab-case files.
