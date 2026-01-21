# Dotfiles - Chezmoi Branch

This branch contains dotfiles managed by [chezmoi](https://chezmoi.io/).

## Migration from Stow

This branch replaces the previous stow-based dotfiles management system. The `main` branch still contains the original stow structure for reference.

## Current Configurations

- **Zsh**: Shell configuration (.zshrc, .zshenv, .zprofile, .profile)
- **Starship**: Custom prompt configuration

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

# Update remote repository
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
