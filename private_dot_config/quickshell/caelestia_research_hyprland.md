# Hyprland Integration with Caelestia

## Configuration Overview
Hyprland is the core window manager for Caelestia, configured with extensive keybindings, animations, and theming support. The configuration is modular, split into multiple files for organization.

## Key Components

### Main Configuration Structure
- **hyprland.conf**: Main config file that sources all other configs
- **variables.conf**: Defines apps, gaps, colors, and keybind variables
- **scheme/**: Color scheme management with default.conf and current.conf
- **scripts/**: Utility scripts like wsaction.fish for workspace management

### Layout and Behavior
- **Layout**: Dwindle layout with smart resizing
- **Gaps**: Configurable workspace and window gaps (20/10/40 default)
- **Borders**: 3px borders with color-coded active/inactive states
- **Rounding**: 10px window corner rounding

### Animations
- Custom bezier curves for different animation types
- Smooth transitions for windows, workspaces, and layers
- Special workspace animations with slide effects

### Key Features
- **Workspaces**: 10 workspaces with group support
- **Window Management**: Floating, tiling, grouping, and special workspaces
- **Media Controls**: Integrated media playback controls
- **Utilities**: Screenshot, recording, color picker, clipboard manager
- **Apps**: Pre-configured keybinds for terminal, browser, editor, file manager

## Integration Notes
Hyprland config integrates deeply with the Caelestia shell for launcher, notifications, and special workspace toggles. Uses variables for easy theming and customization. Supports touchpad gestures and multi-monitor setups.

## Keybinds Summary
- `Super + T/W/C/E`: Terminal/Browser/Editor/File manager
- `Super + 1-0`: Switch workspaces
- `Super + Alt + 1-0`: Move windows to workspaces
- `Super + S`: Toggle special workspace
- `Ctrl + Super + Space`: Media play/pause
- `Super + V`: Clipboard manager
- `Super + .`: Emoji picker