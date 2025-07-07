# GitHub Copilot Documentation

This file provides an overview of the dotfiles repository, its structure, and key configurations to assist with future interactions.

## Folder Structure

The repository is organized by application, with each top-level directory corresponding to a specific tool or environment. The configuration files are managed using `stow`.

```
/home/arafay/dotfiles/
├───.editorconfig
├───.git/...
├───.vscode/
│   └───settings.json
├───alacritty/
│   └───.config/
│       └───alacritty/
│           └───alacritty.toml
├───dolphin/
│   └───.config/
│       └───dolphinrc
├───hypr/
│   └───.config/
│       ├───hypr/
│       │   ├───hypridle.conf
│       │   ├───hyprland.conf
│       │   ├───keybindings.conf
│       │   └───windowrules.conf
│       └───waybar/
│           ├───config
│           ├───platform_profile.sh
│           └───style.css
├───kitty/
│   └───.config/
│       └───kitty/
│           └───kitty.conf
├───nvim/
│   └───.config/
│       └───nvim/
│           ├───.gitignore
│           ├───.neoconf.json
│           ├───init.lua
│           ├───lazy-lock.json
│           ├───lazyvim.json
│           ├───LICENSE
│           ├───README.md
│           ├───stylua.toml
│           ├───lua/
│           │   ├───config/
│           │   │   ├───autocmds.lua
│           │   │   ├───keymaps.lua
│           │   │   ├───lazy.lua
│           │   │   └───options.lua
│           │   └───plugins/
│           │       ├───example.lua
│           │       ├───git-identity.lua
│           │       ├───nvim-lspconfig.lua
│           │       ├───snacks-explorer.lua
│           │       └───theme.lua
│           ├───plugin/
│           │   ├───set-local-git.lua
│           │   └───after/
│           │       └───transparency.lua
│           └───user/
│               └───git_identities.lua
├───scripts/
│   ├───delete-cloudflare.sh
│   ├───install-cloudflare.sh
│   ├───keybindings.sh
│   ├───reload-hyprpaper.sh
│   ├───reload-waybar.sh
│   └───.local/
│       └───share/
│           └───bin/
│               ├───amdgpu.py
│               ├───animations.sh
│               ├───batterynotify.sh
│               ├───brightnesscontrol.sh
│               ├───cliphist.sh
│               ├───cpuinfo.sh
│               ├───dontkillsteam.sh
│               ├───gamelauncher.sh
│               ├───gamemode.sh
│               ├───globalcontrol.sh
│               ├───gpuinfo.sh
│               ├───keybinds_hint.sh
│               ├───keyboardswitch.sh
│               ├───logoutlaunch.sh
│               ├───mediaplayer.py
│               ├───notifications.py
│               ├───polkitkdeauth.sh
│               ├───quickapps.sh
│               ├───resetxdgportal.sh
│               ├───rofilaunch.sh
│               ├───rofiselect.sh
│               ├───screenshot.sh
│               ├───swwwallbash.sh
│               ├───swwwallcache.sh
│               ├───swwwallkon.sh
│               ├───swwwallpaper.sh
│               ├───swwwallselect.sh
│               ├───sysmonlaunch.sh
│               ├───systemupdate.sh
│               ├───testrunner.sh
│               ├───themeselect.sh
│               ├───themestyle.sh
│               ├───themeswitch.sh
│               ├───volumecontrol.sh
│               ├───wallbash.sh
│               ├───wallbashcava.sh
│               ├───wallbashcode.sh
│               ├───wallbashdiscord.sh
│               ├───wallbashdunst.sh
│               ├───wallbashqt.sh
│               ├───wallbashspotify.sh
│               ├───wallbashtoggle.sh
│               ├───waybar_cava.sh
│               ├───wbarconfgen.sh
│               ├───wbarstylegen.sh
│               └───windowpin.sh
├───starship/
│   └───.config/
│       └───starship/
│           └───starship.toml
├───stow/
│   └───.stowrc
├───tmux/
│   └───.tmux.conf
└───zsh/
    ├───.bash_profile
    ├───.bashrc
    ├───.profile
    ├───.zprofile
    ├───.zshenv
    └───.zshrc
```

## Key Configurations and Tools

### Shell Environment (zsh)

The primary shell is `zsh`, configured through a set of files in the `zsh/` directory.

- **`.zshrc`**: This is the main configuration file for interactive shells. It sets up shell options, aliases, functions, and initializes the plugin manager.
- **`.zshenv`**: This file is sourced on all invocations of the shell, both interactive and non-interactive. It's used to set environment variables that should be available to all programs.
- **`.zprofile`**: This is sourced for login shells. It's used for commands that should be executed only when you log in.
- **`.profile`**: This file is sourced by `.zshenv` and is also compatible with `bash`. It contains environment variable definitions and PATH modifications.

### System Tools and Aliases

The following tools and aliases are configured in the shell environment:

- **`mise`**: A tool for managing environment variables and tool versions. It is configured to be used in the shell.
- **`rg` (ripgrep)**: The `grep` command is aliased to `rg`, a faster and more user-friendly alternative.
- **`fd`**: The `find` command is aliased to `fd`, a simpler and faster alternative.
- **`bat`**: The `cat` command is aliased to `bat`, which provides syntax highlighting and Git integration.
- **`eza`**: The `ls` command is aliased to `eza`, a modern replacement for `ls` with more features.
- **`fzf`**: A command-line fuzzy finder, used for history search and file finding.
- **`zoxide`**: A smarter `cd` command that learns your habits. The `cd` command is aliased to `z`.
- **AUR Helper**: The system uses an AUR helper (`yay` or `paru`) for managing packages from the Arch User Repository. The alias `in` is used to install packages.

### Documentation and Further Information

- **Neovim (`nvim/`)**: The Neovim configuration is located in `nvim/`. It uses LazyVim, and the configuration is split into several files under `nvim/.config/nvim/lua/`. The `init.lua` file is the main entry point.
- **Hyprland (`hypr/`)**: The configuration for the Hyprland window manager is in `hypr/`. This includes settings for `hyprland`, `hypridle`, `waybar`, and keybindings.
- **Scripts (`scripts/`)**: The `scripts/` directory contains various utility scripts. The scripts in `scripts/.local/share/bin/` are added to the `PATH`.

This `copilot-instructions.md` file should serve as a useful reference for understanding the structure and key components of this dotfiles repository.
