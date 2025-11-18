# Caelestia Shell (Quickshell-based UI)

## Overview
The Caelestia shell is a comprehensive desktop shell built on Quickshell, providing all interactive UI components including the bar, launcher, dashboard, notifications, and system controls.

## Architecture
- **Framework**: Quickshell (Qt/QML-based)
- **Language**: QML with JavaScript
- **Structure**: Modular components in separate QML files
- **Configuration**: JSON-based config in `~/.config/caelestia/shell.json`

## Core Components

### Bar
- **Workspaces**: Visual workspace indicators with icons
- **Active Window**: Current window title display
- **Tray**: System tray icons
- **Clock**: Time display with optional icon
- **Status Icons**: Battery, network, Bluetooth, lock status
- **Power**: Session controls
- **Features**: Scroll actions for brightness/volume/workspaces, popouts, hover show

### Launcher
- **App Search**: Fuzzy search through installed applications
- **Actions**: Built-in actions (calculator, scheme change, wallpaper, etc.)
- **Special Commands**: Prefixed with > for actions, @ for special
- **Wallpaper Picker**: Visual wallpaper selection
- **Configuration**: Fuzzy search toggles, dangerous actions, max shown items

### Dashboard
- **Profile Picture**: User avatar from `~/.face`
- **Media Controls**: MPRIS integration with player selection
- **Quick Settings**: Audio, brightness, network toggles
- **System Info**: CPU, memory, disk usage
- **Weather**: Location-based weather display

### Notifications
- **Toast System**: Temporary status messages
- **Notification Center**: Persistent notifications with actions
- **DND Mode**: Do not disturb toggle
- **Grouping**: Notification grouping and expiration

### Background
- **Wallpaper Display**: Dynamic wallpaper with blur options
- **Visualiser**: Audio visualiser with CAVA integration
- **Desktop Clock**: Optional clock overlay

### Lock Screen
- **Authentication**: PAM-based login
- **Media Display**: Current playing media
- **Session Info**: User/session details

## Services
- **Audio**: Pipewire/PulseAudio volume control
- **Brightness**: DDC/CI and software brightness control
- **Network**: NetworkManager integration
- **Battery**: Battery monitoring with warnings
- **Idle**: Automatic lock/screen off/suspend
- **VPN**: VPN status and control
- **Weather**: OpenWeatherMap integration

## IPC Interface
- **DBus Shortcuts**: Global keybinds via Hyprland
- **Commands**: `caelestia shell` subcommands for runtime control
- **Targets**: drawers, notifs, lock, mpris, picker, wallpaper

## Configuration Sections
- **appearance**: Fonts, animations, padding, transparency
- **general**: Apps, battery warnings, idle timeouts
- **bar**: Layout, entries, status display
- **launcher**: Search settings, actions, wallpapers
- **dashboard**: Media update interval, components
- **notifs**: Expiration, click actions
- **services**: Player aliases, weather location

## Integration Notes
The shell provides the complete interactive layer on top of Hyprland, handling all user interactions that the dots config delegates to "caelestia:" IPC calls. It's highly configurable and extensible through QML modules.