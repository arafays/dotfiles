# Agent Guidelines for Dotfiles Repository

Chezmoi-managed dotfiles for Arch Linux with Hyprland. Edit source files in repo, not deployed configs.

## Build/Test Commands

- **Apply changes**: `chezmoi apply` (after editing source files)
- **Check status**: `chezmoi status`
- **Diff changes**: `chezmoi diff`
- **Test config**: Edit source, then `chezmoi apply <target_path>`
- **No traditional tests**: Manual testing by restarting services/reloading configs

## Code Style Guidelines

### File Naming & Structure

- Chezmoi conventions: `private_` prefix for private files, `dot_` for dotfiles
- Config files: native formats (TOML, YAML, shell, etc.)
- Modular configs: split large files into logical sections

### Shell Scripts (Zsh)

- Search: `rg` only (never `grep`)
- Functions: `_` prefix for internal functions
- Command checks: `_cmd_exists()` before execution
- Performance: lazy loading and caching

### Configuration Files

- TOML: 2-space indent, quote strings when needed
- Shell: `[[ ]]` for tests, follow existing patterns
- XDG Base Directory compliance where possible

### Import/Dependency Management

- Tools: `mise` instead of language-specific managers
- Python: `uv` from mise instead of `pip`
- Prefer: system packages (pacman/yay) over manual installs

### Naming Conventions

- Variables/functions: camelCase (shell), snake_case (configs)
- Files: kebab-case (scripts), native conventions (configs)
- Constants: UPPER_SNAKE_CASE

### Error Handling

- Proper exit codes in shell scripts
- Command existence checks before execution
- Graceful fallbacks for optional dependencies

## Key Tools & Aliases

- Search: `rg` (ripgrep)
- File listing: `eza` with aliases
- Editors: VS Code Insiders (`code`), Neovim (`nvim`)
- Terminal: Kitty primary, Alacritty secondary
- Multiplexer: tmux with session management

## Testing Changes

Always test config changes by applying with chezmoi and restarting relevant services or reloading configs.

ASK USER TO INSTALL ANY NEW DEPENDENCIES IF NEEDED. NEVER USE pacman or yay to install find the package first then ask user to install it.

use hyprctl command to first look for errors in hyprland config changes.

before using chezmoi apply ask user to unlock the password manager if any private files are changed.
