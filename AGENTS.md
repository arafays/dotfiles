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

## Chezmoi source file naming conventions (CRITICAL — read before editing any file)

chezmoi encodes ALL behavior (permissions, encryption, templating, script execution) in source filenames via **prefixes** and **suffixes**. These are called "attributes." The source filename IS the encoding — never rename files without understanding the attribute system below.

### Source → Target path mapping

The target path is derived by stripping all recognized attribute prefixes/suffixes from the source filename. For example:

| Source filename | Target path | What it does |
|---|---|---|
| `dot_gitconfig` | `~/.gitconfig` | `dot_` → leading `.` |
| `private_dot_config/niri/config.kdl` | `~/.config/niri/config.kdl` | `private_` → 0600 perms |
| `executable_dot_local_bin_hello` | `~/.local/bin/hello` | `executable_` → chmod +x |
| `dot_gitconfig.tmpl` | `~/.gitconfig` | `.tmpl` → template processing |
| `run_onchange_install-packages.sh` | *(script, no target)* | Runs on change |

**Critical rule:** Directory separators in target paths are encoded as `_` in filenames. The only way to create a target `~/.config/niri/config.kdl` is via directory structure: `private_dot_config/niri/config.kdl` in the source directory.

### Full attribute prefix table (order matters!)

The exact order of prefixes is **mandatory**. Each target type has a specific allowed prefix sequence:

#### Regular files

`encrypted_` → `private_` → `readonly_` → `empty_` → `executable_` → `dot_` + `.tmpl` suffix

Example: `encrypted_private_executable_dot_secret.sh.tmpl`

#### Create files (create if missing)

`create_` → `encrypted_` → `private_` → `readonly_` → `empty_` → `executable_` → `dot_` + `.tmpl` suffix

#### Modify files (script that modifies existing target)

`modify_` → `encrypted_` → `private_` → `readonly_` → `executable_` → `dot_` + `.tmpl` suffix

#### Scripts (run as commands)

`run_` → `once_` or `onchange_` → `before_` or `after_` + `.tmpl` suffix

- `run_before_*` — execute BEFORE dotfile updates (alphabetically)
- `run_after_*` — execute AFTER dotfile updates (alphabetically)
- `run_once_*` — execute only if contents never run successfully before
- `run_onchange_*` — execute only if contents changed since last run

#### Symbolic links

`symlink_` → `dot_` + `.tmpl` suffix

The file content is the link target (literal path or template that evaluates to a path).

#### Directories

`remove_` → `external_` → `exact_` → `private_` → `readonly_` → `dot_`

Directories CANNOT have the `.tmpl` suffix.

#### Remove files

`remove_` → `dot_`

### Attribute definitions

| Attribute | Effect |
|---|---|
| `after_` | Run script after updating destination |
| `before_` | Run script before updating destination |
| `create_` | Ensure file exists; create with contents if absent |
| `dot_` | Rename to use a leading dot (`dot_foo` → `.foo`) |
| `empty_` | Keep file even if empty (by default, empty files are removed) |
| `encrypted_` | File is encrypted at rest in source state |
| `exact_` | Remove anything in the target directory NOT managed by chezmoi |
| `executable_` | Add executable permissions to target |
| `external_` | Ignore attributes in child entries (directory only) |
| `literal_` | Stop parsing prefix attributes (escape hatch) |
| `modify_` | Treat contents as a script that modifies an existing file |
| `once_` | Only run script if contents haven't been run successfully before |
| `onchange_` | Only run script if contents changed (per filename) |
| `private_` | Remove all group/world permissions (target → 0600/0700) |
| `readonly_` | Remove all write permissions from target |
| `remove_` | Remove the file/dir if it exists |
| `run_` | Treat contents as a script to execute |
| `symlink_` | Create a symlink instead of a regular file |
| `.literal` (suffix) | Stop parsing suffix attributes |
| `.tmpl` (suffix) | Process source file as a Go template |
| `.age` / `.asc` (suffix) | Encryption suffix (stripped at apply) — age vs gpg |

### Escaping: `literal_` and `.literal`

If a filename would accidentally match a chezmoi attribute, escape it:

- `literal_dot_example` → target is `.example` (the `dot_` is literal text)
- `literal_encrypted_stuff` → target is `encrypted_stuff` (NOT encrypted)

### NEVER do these things

- **NEVER** edit files in `$HOME` directly — edit source files in `~/.local/share/chezmoi`
- **NEVER** run `chezmoi apply` without specifying the exact file path
- **NEVER** rename source files without preserving the correct attribute prefix order
- **NEVER** add a `.tmpl` suffix to a directory (directories can't be templates)
- **NEVER** use `chezmoi add` and `chezmoi apply` in the same operation without asking
- **NEVER** assume a file without `dot_` prefix maps to the same path — it maps to `$HOME/` without a leading dot
- **ALWAYS** use `chezmoi source-path` to find where a source file should go when creating new ones
- **ALWAYS** check `chezmoi managed` to see what's currently managed

### File naming examples (common patterns in this repo)

```
private_dot_config/niri/config.kdl     → ~/.config/niri/config.kdl (0600)
executable_dot_local_bin_hello         → ~/.local/bin/hello (+x)
dot_gitconfig.tmpl                     → ~/.gitconfig (templated)
private_dot_config/opencode/opencode.jsonc → ~/.config/opencode/opencode.jsonc (0600)
```

## Config structure

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
