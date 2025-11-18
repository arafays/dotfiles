# Caelestia CLI (Python-based Control Script)

## Overview
The Caelestia CLI is a Python application providing command-line control over the shell and system functions, including wallpaper management, color schemes, screenshots, and special workspace toggles.

## Architecture
- **Language**: Python 3
- **Structure**: Modular subcommands in separate files
- **Configuration**: JSON config in `~/.config/caelestia/cli.json`
- **Dependencies**: Various system tools (grim, slurp, swappy, etc.)

## Subcommands

### shell
- **Purpose**: Start or message the shell
- **Usage**: `caelestia shell [command]`
- **IPC**: Direct communication with running shell instance
- **Functions**: lock, unlock, mpris controls, notifications, wallpaper

### toggle
- **Purpose**: Toggle special workspaces
- **Usage**: `caelestia toggle <workspace>`
- **Workspaces**: sysmon, music, communication, todo
- **Features**: Automatic app launching and window moving

### scheme
- **Purpose**: Manage color schemes
- **Usage**: `caelestia scheme <command>`
- **Commands**: set, list, generate from wallpaper
- **Features**: Dynamic schemes, multiple variants (light/dark)

### screenshot
- **Purpose**: Take screenshots
- **Usage**: `caelestia screenshot [options]`
- **Features**: Full screen, region, freeze mode
- **Integration**: Opens in swappy for editing

### record
- **Purpose**: Screen recording
- **Usage**: `caelestia record [options]`
- **Features**: Full screen, region, audio toggle
- **Backend**: gpu-screen-recorder

### clipboard
- **Purpose**: Clipboard history
- **Usage**: `caelestia clipboard [options]`
- **Features**: History browsing, deletion
- **Integration**: fuzzel for selection

### emoji
- **Purpose**: Emoji/glyph picker
- **Usage**: `caelestia emoji [options]`
- **Features**: Search, copy to clipboard
- **Integration**: fuzzel interface

### wallpaper
- **Purpose**: Wallpaper management
- **Usage**: `caelestia wallpaper <command>`
- **Commands**: set, list, random, from directory
- **Features**: Post-hooks, directory watching

### resizer
- **Purpose**: Window resizer daemon
- **Usage**: `caelestia resizer`
- **Features**: Picture-in-picture mode, custom sizing

## Configuration Sections
- **record**: Extra arguments for recording
- **wallpaper**: Post-hook scripts
- **theme**: Enable/disable theming for various apps
- **toggles**: App definitions for special workspaces

## Integration Notes
The CLI serves as the control interface for the shell, handling all system-level operations that require command-line access. It integrates deeply with the shell via IPC and provides theming capabilities for external applications.