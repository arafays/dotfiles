# Dotfiles - Chezmoi Branch

This branch contains dotfiles managed by [chezmoi](https://chezmoi.io/).

## Migration from Stow

This branch replaces the previous stow-based dotfiles management system. The `main` branch still contains the original stow structure for reference.

## Current Configurations

- **Zsh**: Shell configuration (.zshrc, .zshenv, .zprofile, .profile)
- **Starship**: Custom prompt configuration
- **Neovim**: Full LazyVim configuration with custom plugins and keymaps
- **Hyprland**: Window manager configuration (bindings, monitors, hypridle)
- **Waybar**: Status bar configuration and styling
- **VS Code Insiders**: Settings, prompts, and MCP configuration
- **Environment**: mise configuration for development tools

## Usage

### First-time setup on a new machine:
```bash
chezmoi init --apply https://github.com/arafays/dotfiles.git --branch chezmoi
```

### Daily usage:
```bash
# Check status
chezmoi status

# Apply changes
chezmoi apply

# Edit a managed file
chezmoi edit ~/.zshrc

# Add a new file to management
chezmoi add ~/.config/new-app/config.toml
```

### Pushing Changes to Remote

When you've made changes to your dotfiles and want to sync them to your remote repository:

#### Quick Method (Push all changes):
```bash
# 1. Check what files have changes
chezmoi status

# 2. Add all modified files to chezmoi tracking
chezmoi re-add

# 3. Navigate to chezmoi directory and commit
cd ~/.local/share/chezmoi
git add .
git commit -m "Your commit message here"
git push origin chezmoi
```

#### Individual File Method:
```bash
# 1. Add specific file to chezmoi
chezmoi add ~/.config/specific/file

# 2. Navigate to chezmoi directory
cd ~/.local/share/chezmoi

# 3. Commit and push
git add .
git commit -m "Update specific configuration"
git push origin chezmoi
```

#### Alternative using chezmoi git commands:
```bash
# Note: These commands work from any directory
chezmoi git add .
chezmoi git commit -m "Update configs"
chezmoi git push
```

## Structure

Files are stored in chezmoi's special format:
- `dot_zshrc` → `~/.zshrc`
- `dot_config/starship/starship.toml` → `~/.config/starship/starship.toml`

## Adding More Configurations

To add configurations from the original stow setup:
1. Copy the files to the appropriate location in your home directory
2. Use `chezmoi add <file>` to start managing them
3. Commit and push the changes

## Branches

- `main`: Original stow-based dotfiles (archived)
- `chezmoi`: Current branch with chezmoi-managed dotfiles
