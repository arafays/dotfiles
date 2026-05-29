# AGENTS.md — Chezmoi Dotfiles (Arch/Niri)

## Critical: chezmoi apply rules

- **Never run global apply** (`chezmoi apply` without args)
- **Always use `--source-path`** with the source-relative path:
  - `chezmoi apply --source-path "dot_gitconfig.tmpl"` ✅
  - `chezmoi apply "dot_gitconfig.tmpl"` ❌ (will fail with "not managed")
- To find the source path from a target path: `chezmoi source-path ~/.config/niri/config.kdl`
- List all managed files: `chezmoi managed`

## Source file naming (attribute encoding)

chezmoi encodes all behavior in filenames. Order is **mandatory**.

| Source | Target | Effect |
|---|---|---|
| `dot_gitconfig` | `~/.gitconfig` | `dot_` → leading `.` |
| `private_dot_config/niri/config.kdl` | `~/.config/niri/config.kdl` | `private_` → 0600 |
| `executable_dot_local_bin_hello` | `~/.local/bin/hello` | `executable_` → +x |
| `dot_gitconfig.tmpl` | `~/.gitconfig` | `.tmpl` → Go template |

**Prefix order (regular files):** `encrypted_` → `private_` → `readonly_` → `empty_` → `executable_` → `dot_` + `.tmpl`

**Scripts:** `run_` + `once_|onchange_` + `before_|after_` + `.tmpl`
**Symlinks:** `symlink_` + `dot_` + `.tmpl`
**Directories:** `remove_|external_|exact_|private_|readonly_|dot_` (no `.tmpl`)

Full attribute reference: https://chezmoi.io/reference/target-attributes/

## Template data & variables

Defined via `promptStringOnce` in `.chezmoi.toml.tmpl`:
- `{{ .name }}`, `{{ .email }}`, `{{ .github_username }}`

No `missingkey=error` set (but add if needed — current config doesn't set template.options).

## Secrets

Bitwarden CLI (`bw`) in `private_dot_config/environment.d/04-misc.conf.tmpl`:
```
CONTEXT7_API_KEY={{ (bitwarden "item" "Context7 API Key").notes | trim }}
EXA_API_KEY={{ (bitwarden "item" "EXA API Key").notes | trim }}
```

## Environment info

- **OS**: Arch Linux, **WM**: Niri (Wayland), **Shell**: fish + tmux
- **Terminal**: alacritty, **Editors**: nvim, vscode-insiders
- **Package mgmt**: pacman/paru (AUR), mise for tools/global npm
- **Python**: uv (not pip), **Search**: rg (not grep)
- **tmux plugins**: tpm, tmux-sensible, tmux-resurrect, tmux-continuum, tmux-menus, tmux-dotbar

## Config structure

```
.
├── dot_gitconfig.tmpl          # ~/.gitconfig (templated)
├── dot_tmux.conf               # ~/.tmux.conf
├── dot_ssh/authorized_keys.tmpl
├── private_dot_zshrc.tmpl      # ~/.zshrc (templated)
├── private_dot_config/
│   ├── environment.d/          # 01-07 numeric order
│   ├── niri/config.kdl         # + cfg/*.kdl
│   ├── nvim/                   # LazyVim-based
│   ├── fish/
│   ├── opencode/opencode.jsonc
│   ├── alacritty/, waybar/, starship/, zed/, mise/
│   ├── chromium-flags.conf, code-flags.conf, electron-flags.conf
│   └── private_Code - Insiders/
└── private_dot_local/bin/
```

## OpenCode config

`private_dot_config/opencode/opencode.jsonc` loads `profile.yaml` as instructions and uses MCP servers:
- **context7**: docs/code examples (Context7 API)
- **gh_grep**: GitHub code search (remote)
- **exa**: web search (remote, EXA API)
- **devtools** & **markitdown**: disabled

## Workflow

1. Edit source files in this repo (`~/.local/share/chezmoi`), never live configs
2. Check changes: `chezmoi diff` or `chezmoi apply --dry-run --source-path "file"`
3. Apply: `chezmoi apply --source-path "file"` (specific file only)
4. Add new file: `chezmoi add ~/.config/new-app/config` → commit source files
5. Validate: `chezmoi verify`, `zsh -n $(chezmoi source-path ~/.zshrc)`
6. AGENTS.md lives in the repo but is **not** applied by chezmoi — edit directly here
