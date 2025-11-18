# Scripts and Utilities in Caelestia

## Overview
Caelestia includes various scripts and utilities to enhance functionality, particularly for Hyprland window management and system integration.

## Key Scripts

### wsaction.fish
- **Purpose**: Handles workspace switching and moving with group support
- **Features**: 
  - Supports workspace groups (10 workspaces per group)
  - Calculates target workspace based on current active workspace
  - Used extensively in Hyprland keybindings
- **Usage**: `wsaction.fish [-g] <dispatcher> <workspace>`

### Other Utilities
- **Shell Scripts**: Custom commands for media control, screenshots, notifications
- **IPC Integration**: Runtime control via `qs ipc` commands
- **App Launchers**: `app2unit` for launching applications with proper environment

## Integration Notes
Scripts provide the glue between Hyprland, the shell, and user interactions. They handle complex workspace management and system controls that aren't directly available in Hyprland config.