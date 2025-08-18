# Dotfiles Repository Context

This file provides comprehensive information about this dotfiles repository for LLM assistance. Use this as the primary reference for understanding the setup, structure, and context.

## System Overview

- **Operating System**: Arch Linux-based system
- **Package Manager**: `yay` (AUR helper)
- **Desktop Environments**: KDE Plasma and Hyprland (mood-dependent switching)
- **Dotfiles Management**: Currently using `stow` (considering migration to `chezmoi`)
- **Shell**: `zsh` with Starship prompt
- **Terminal Multiplexer**: `tmux`
- **Terminal Emulators**: Alacritty (primary), Kitty (secondary)

## Repository Structure

The repository is organized by application, with each top-level directory corresponding to a specific tool or environment. Configuration files are managed using `stow`.

```
/home/arafay/dotfiles/
├── .editorconfig
├── .env
├── .git/
├── .github/
├── .gitignore
├── .vscode/
├── alacritty/
│   └── .config/
│       └── alacritty/
│           └── alacritty.toml
├── dolphin/
│   └── .config/
│       └── dolphinrc
├── hypr/
│   └── .config/
│       ├── dunst/
│       │   └── dunstrc
│       ├── hypr/
│       │   ├── appearance.conf
│       │   ├── autostart.conf
│       │   ├── environment.conf
│       │   ├── hypridle.conf
│       │   ├── hyprland.conf
│       │   ├── input.conf
│       │   ├── keybindings.conf
│       │   ├── layouts.conf
│       │   ├── misc.conf
│       │   ├── monitors.conf
│       │   └── windowrules.conf
│       ├── waybar/
│       │   ├── config
│       │   ├── config.jsonc
│       │   ├── platform_profile.sh
│       │   └── style.css
│       └── wlogout/
├── kitty/
│   └── .config/
│       └── kitty/
│           └── kitty.conf
├── nvim/
│   └── .config/
│       └── nvim/
│           ├── .gitignore
│           ├── .neoconf.json
│           ├── init.lua
│           ├── lazy-lock.json
│           ├── lazyvim.json
│           ├── LICENSE
│           ├── README.md
│           ├── stylua.toml
│           ├── lua/
│           │   ├── config/
│           │   │   ├── autocmds.lua
│           │   │   ├── keymaps.lua
│           │   │   ├── lazy.lua
│           │   │   └── options.lua
│           │   └── plugins/
│           │       ├── example.lua
│           │       ├── git-identity.lua
│           │       ├── nvim-lspconfig.lua
│           │       ├── snacks-explorer.lua
│           │       └── theme.lua
│           ├── plugin/
│           │   ├── set-local-git.lua
│           │   └── after/
│           │       └── transparency.lua
│           └── user/
│               └── git_identities.lua
├── scripts/
│   ├── delete-cloudflare.sh
│   ├── install-cloudflare.sh
│   ├── keybindings.sh
│   ├── reload-hyprpaper.sh
│   ├── reload-waybar.sh
│   └── .local/
│       └── share/
│           └── bin/
│               ├── amdgpu.py
│               ├── animations.sh
│               ├── batterynotify.sh
│               ├── brightnesscontrol.sh
│               ├── cliphist.sh
│               ├── cpuinfo.sh
│               ├── dontkillsteam.sh
│               ├── gamelauncher.sh
│               ├── gamemode.sh
│               ├── globalcontrol.sh
│               ├── gpuinfo.sh
│               ├── keybinds_hint.sh
│               ├── keyboardswitch.sh
│               ├── logoutlaunch.sh
│               ├── mediaplayer.py
│               ├── notifications.py
│               ├── polkitkdeauth.sh
│               ├── quickapps.sh
│               ├── rofilaunch.sh
│               ├── rofiselect.sh
│               ├── screenshot.sh
│               ├── swwwallbash.sh
│               ├── swwwallcache.sh
│               ├── swwwallkon.sh
│               ├── swwwallpaper.sh
│               ├── swwwallselect.sh
│               ├── sysmonlaunch.sh
│               ├── systemupdate.sh
│               ├── testrunner.sh
│               ├── themeselect.sh
│               ├── themestyle.sh
│               ├── themeswitch.sh
│               ├── volumecontrol.sh
│               ├── wallbash.sh
│               ├── wallbashcava.sh
│               ├── wallbashcode.sh
│               ├── wallbashdiscord.sh
│               ├── wallbashdunst.sh
│               ├── wallbashqt.sh
│               ├── wallbashspotify.sh
│               ├── wallbashtoggle.sh
│               ├── waybar_cava.sh
│               ├── wbarconfgen.sh
│               ├── wbarstylegen.sh
│               └── windowpin.sh
├── starship/
│   └── .config/
│       └── starship/
│           └── starship.toml
├── stow/
│   └── .stowrc
├── tmux/
│   └── .tmux.conf
└── zsh/
    ├── .bash_profile
    ├── .bashrc
    ├── .profile
    ├── .zprofile
    ├── .zshenv
    └── .zshrc
```

## Key Configurations and Tools

### Shell Environment (zsh)

The primary shell is `zsh`, configured through multiple files in the `zsh/` directory:

- **`.zshrc`**: Main configuration for interactive shells (aliases, functions, plugin manager)
- **`.zshenv`**: Environment variables for all shell invocations
- **`.zprofile`**: Login shell configuration
- **`.profile`**: Cross-compatible environment variables and PATH modifications

### System Tools and Aliases

Modern CLI tools with aliases configured:

- **`mise`**: Environment and tool version management
- **`rg` (ripgrep)**: Replaces `grep` - faster file searching
- **`fd`**: Replaces `find` - simpler file finding
- **`bat`**: Replaces `cat` - syntax highlighting and Git integration
- **`eza`**: Replaces `ls` - modern file listing
- **`fzf`**: Fuzzy finder for history and file search
- **`zoxide`**: Smart `cd` replacement (aliased to `z`)
- **`yay`**: AUR helper (alias `in` for package installation)

### Desktop Environments

#### Hyprland Configuration
- **Location**: `hypr/.config/hypr/`
- **Structure**: Modular configuration split across multiple files
- **Main file**: `hyprland.conf` sources other configuration files
- **Components**:
  - `appearance.conf` - Visual styling
  - `autostart.conf` - Startup applications
  - `keybindings.conf` - Key mappings
  - `input.conf` - Input device settings
  - `monitors.conf` - Display configuration
  - `windowrules.conf` - Window management rules
- **Additional tools**:
  - `waybar/` - Status bar configuration
  - `dunst/` - Notification daemon
  - `hypridle.conf` - Idle management

#### KDE Plasma
- **Usage**: Alternative desktop environment (mood-dependent)
- **Configuration**: `dolphin/.config/dolphinrc` for file manager

### Development Tools

#### Neovim
- **Framework**: LazyVim
- **Location**: `nvim/.config/nvim/`
- **Entry point**: `init.lua`
- **Structure**:
  - `lua/config/` - Core configuration
  - `lua/plugins/` - Plugin configurations
  - `plugin/` - Custom plugins and scripts
  - `user/` - User-specific configurations (git identities)

#### Terminal Emulators
- **Primary**: Alacritty (`alacritty/.config/alacritty/alacritty.toml`)
- **Secondary**: Kitty (`kitty/.config/kitty/kitty.conf`)

#### Other Tools
- **Tmux**: Terminal multiplexer (`tmux/.tmux.conf`)
- **Starship**: Cross-shell prompt (`starship/.config/starship/starship.toml`)

### Scripts and Utilities

The `scripts/` directory contains various utility scripts:
- **Root level**: Basic utility scripts (Cloudflare management, reloading configs)
- **`.local/share/bin/`**: Extensive collection of system utilities (added to PATH)
- **Categories**: System monitoring, wallpaper management, media control, gaming utilities
- **Note**: Some scripts may be redundant and need cleanup

## Repository Status and Plans

### Current State
- **Management**: Using `stow` for symlink management
- **Branch structure**: `clean` branch has improved directory structure
- **Issues**: Some redundant scripts, considering reorganization

### Future Plans
1. **Dotfiles manager migration**: Considering move from `stow` to `chezmoi`
2. **Repository restructure**: Merge cleaner structure from `clean` branch
3. **Script cleanup**: Remove redundant scripts and improve organization

## Guidelines for LLM Assistance

### General Principles
- Follow existing structure and naming conventions
- Use terminal commands for file discovery and navigation
- Consider impact on both KDE and Hyprland configurations
- Maintain compatibility with Arch Linux and `yay` package manager

### File Management
- Use `stow` for current dotfiles management
- Check common configuration locations before suggesting new paths
- Maintain modular configuration approach (especially for Hyprland)
- Document changes in configuration files with comments

### Development Workflow
- Test changes in both desktop environments when applicable
- Consider script dependencies and PATH modifications
- Maintain backward compatibility with existing aliases and functions
- Update this documentation when making structural changes

### Troubleshooting
- Reference relevant configuration files for context
- Use modern CLI tools (`rg`, `fd`, `bat`, etc.) for investigation
- Consider both KDE and Hyprland-specific issues
- Check script permissions and PATH inclusion for utilities

This file serves as the comprehensive reference for understanding and working with this dotfiles repository.