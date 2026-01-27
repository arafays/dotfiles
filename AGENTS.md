# AGENTS.md - Chezmoi Dotfiles Repository Guide

## Repository Overview

This is a chezmoi-managed dotfiles repository for an Arch Linux system using:

- **WM/DE**: Niri (Wayland compositor)
- **Shell**: Zsh with tmux
- **Package Manager**: paru/pacman + mise for tool management
- **Primary Editors**: nvim, vscode-insiders
- **Secret Management**: gnome-keyring

## Build/Lint/Test Commands

### Chezmoi Management

```bash
# Apply all dotfiles
chezmoi apply

# Apply specific file/directory
chezmoi apply ~/.config/nvim

# Check what would be applied (dry run)
chezmoi diff

# Add new file to chezmoi
chezmoi add ~/.config/new-config

# Edit source file directly
chezmoi edit ~/.config/some-config

# Update from remote
chezmoi update

# Trust all files in repository
chezmoi trust
```

### Git Operations

```bash
# Standard git commands work in chezmoi source directory
git status
git add .
git commit -m "message"
git push
```

### Development Tools

```bash
# Search (preferred tool)
rg "pattern" --type-add 'config:*.{conf,config,kdl,toml,yaml,yml}'

# File operations
eza -la --icons=auto
bat --style=numbers --color=always file

# Navigation
cd ~  # Works in normal shell
chezmoi cd  # Change to chezmoi source directory
```

## Code Style Guidelines

### Naming Conventions

- **Code**:
  - Variables/Functions: `camelCase`
  - Types: `PascalCase`  
  - Constants: `UPPER_SNAKE_CASE`
- **Files**:
  - TypeScript/JavaScript: `kebab-case`
  - Python: `snake_case`
  - Shell scripts: `kebab-case`
  - Config files: descriptive names with appropriate extensions

### Formatting

- **Lua**: 2-space indentation, 120 column width
- **Shell**: Follow existing patterns in `.zshrc`
- **TOML/YAML**: 2-space indentation
- **JSON**: Use JSONC format with comments when supported

### Import/Include Patterns

- **Lua**: Use `require()` for modules, keep imports at file top
- **Shell**: Source files with `source` or `.`
- **Config files**: Use standard inclusion syntax for each format

## File Organization

### Chezmoi Conventions

- **Private files**: Prefix with `private_` (contains sensitive data)
- **Template files**: End with `.tmpl` (chezmoi templates)
- **Dotfiles**: Prefix with `dot_` for files that become `.hidden`
- **Config directories**: Follow XDG Base Directory specification

## Working with This Repository

### Making Changes

1. **Always edit chezmoi source files**, not live configs
2. Use `chezmoi edit <target>` to edit source files directly
3. Test changes with `chezmoi diff` before applying
4. Apply with `chezmoi apply` when ready

### Adding New Configs

1. Place new config in appropriate location: `~/.config/some-app/`
2. Run: `chezmoi add ~/.config/some-app/config-file`
3. Commit the source file changes
4. Test with `chezmoi apply`

### Templates

- Use `.tmpl` extension for files with chezmoi templating
- Access template data with `{{ .variable }}` syntax
- Common template variables: hostname, username, etc.

## Tool-Specific Guidelines

### Neovim Configuration

- Uses LazyVim as base configuration
- Lua files in `lua/config/` and `lua/plugins/`
- 2-space indentation, 120-char line limit
- Follow LazyVim plugin structure

### Shell Configuration

- Modular functions in `.zshrc` with descriptive names
- Use `_` prefix for private/internal functions
- Error handling with proper return codes
- Use `_cmd_exists()` helper for command availability

### Environment Configuration

- Split environment variables into logical files in `environment.d/`
- Use `01-` to `99-` prefix for loading order
- Follow XDG Base Directory specification

## Security Considerations

### Sensitive Data

- Files with secrets should have `private_` prefix
- Never commit actual secrets, only templates
- Use chezmoi's secret management features
- Store API keys in appropriate system keyrings

### Permissions

- Ensure sensitive configs have appropriate file permissions
- Use chezmoi's permission attributes when needed
- Validate changes before applying to production system

## Testing Your Changes

### Verification Steps

1. `chezmoi diff` - Review changes before applying
2. `chezmoi apply --dry-run` - Test application without changes
3. `chezmoi apply` - Apply changes to test environment
4. Verify application/service functionality
5. Check logs for errors if applicable

### Common Pitfalls

- Editing live configs instead of chezmoi source files
- Forgetting to commit `private_` prefixed files
- Breaking environment variable loading order
- Missing template variable definitions

## Preferred Tools and Aliases

From the shell configuration:

- `rg` for searching (not `grep`)
- `eza` for file listing (not `ls`)
- `bat` for file viewing (not `cat`)
- `nvim` as primary editor (alias `n`, `vim`, `vi`)
- `mise` for development tool management
- `paru` as AUR helper

## Environment Context

- **OS**: Arch Linux
- **Display**: Wayland (Niri compositor)
- **Terminal**: Usually within tmux
- **Shell**: Zsh with extensive customizations
- **Year**: 2026 (for context in generated files)

Remember: This repository manages personal system configuration. Always test changes in a safe manner and maintain backup of working configurations.
