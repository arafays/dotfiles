---
goal: Implement Quickshell-based UI components replicating Caelestia's shell functionality
version: 1.0
date_created: 2025-11-16
last_updated: 2025-11-16
owner: Arafays
status: Planned
tags: feature, ui, shell, quickshell, qml
---

# Introduction

![Status: Planned](https://img.shields.io/badge/status-Planned-blue)

This implementation plan outlines the creation of Quickshell-based UI components that replicate the core functionality of Caelestia's shell, adapted to the user's Arch Linux system with Hyprland window manager. The focus is on implementing bar, launcher, dashboard, notifications, and services components using QML and JavaScript, following the established code style and integration patterns.

## 1. Requirements & Constraints

- **REQ-001**: Implement bar component with workspaces, active window, tray, clock, status icons, and power controls
- **REQ-002**: Create launcher with fuzzy app search, built-in actions, and wallpaper picker
- **REQ-003**: Build dashboard with profile picture, media controls, quick settings, and system info
- **REQ-004**: Develop notifications system with toast and notification center
- **REQ-005**: Integrate services for audio, brightness, network, battery, idle, VPN, and weather
- **CON-001**: Use QML with JavaScript, no C++ plugins unless necessary
- **CON-002**: Follow 4-space indentation, camelCase naming, PascalCase components
- **CON-003**: Integrate with existing MPRIS for media controls
- **CON-004**: Use qs ipc commands for runtime control
- **CON-005**: Support Hyprland key bindings (Ctrl+Alt+Q reload, etc.)
- **GUD-001**: Group QtQuick imports first, then custom modules alphabetically
- **GUD-002**: Separate UI logic from business logic using QML modules
- **PAT-001**: Use modular structure with separate QML files for components

## 2. Implementation Steps

### Phase 1: Project Setup and Core Structure
1. Create directory structure: components/, services/, config/
2. Set up main shell.qml configuration file
3. Implement basic IPC integration with qs ipc commands
4. Create base QML modules for common functionality

### Phase 2: Bar Component Implementation
1. Create Bar.qml with workspace indicators
2. Add active window title display
3. Implement system tray icons
4. Add clock component with optional icon
5. Integrate status icons (battery, network, Bluetooth, lock)
6. Add power/session controls
7. Implement scroll actions for brightness/volume/workspaces
8. Add popouts and hover show functionality

### Phase 3: Launcher Component Implementation
1. Create Launcher.qml with fuzzy search input
2. Implement app search through installed applications
3. Add built-in actions (calculator, scheme change, wallpaper)
4. Create special commands with > and @ prefixes
5. Build wallpaper picker with visual selection
6. Add configuration options for search toggles and max items

### Phase 4: Dashboard Component Implementation
1. Create Dashboard.qml with profile picture from ~/.face
2. Implement MPRIS media controls with player selection
3. Add quick settings toggles (audio, brightness, network)
4. Create system info displays (CPU, memory, disk)
5. Integrate weather display with location-based data

### Phase 5: Notifications System Implementation
1. Create Toast.qml for temporary status messages
2. Build NotificationCenter.qml for persistent notifications
3. Implement DND mode toggle
4. Add notification grouping and expiration logic
5. Create action handling for notifications

### Phase 6: Services Integration
1. Implement audio service using Pipewire/PulseAudio
2. Create brightness control service (DDC/CI and software)
3. Add NetworkManager integration
4. Build battery monitoring with warnings
5. Implement idle management (lock/screen off/suspend)
6. Add VPN status and control
7. Integrate OpenWeatherMap for weather data

### Phase 7: Background and Lock Screen
1. Create wallpaper display with blur options
2. Add audio visualiser with CAVA integration
3. Implement optional desktop clock overlay
4. Build lock screen with PAM authentication
5. Add media display on lock screen

### Phase 8: Configuration and IPC
1. Create JSON-based config system in ~/.config/quickshell/shell.json
2. Implement IPC interface for runtime control
3. Add Hyprland DBus shortcuts integration
4. Create caelestia shell subcommands

## 3. Alternatives

- **ALT-001**: Use C++ plugins for performance-critical services instead of pure QML - rejected due to complexity and maintenance overhead
- **ALT-002**: Implement custom notification daemon instead of integrating with system - rejected to maintain compatibility with existing tools
- **ALT-003**: Use YAML instead of JSON for configuration - rejected due to Qt's native JSON support

## 4. Dependencies

- **DEP-001**: Quickshell framework (already installed via yay)
- **DEP-002**: Qt6 libraries
- **DEP-003**: MPRIS service for media integration
- **DEP-004**: NetworkManager for network controls
- **DEP-005**: Pipewire/PulseAudio for audio
- **DEP-006**: OpenWeatherMap API for weather data

## 5. Files

- **FILE-001**: shell.qml - Main configuration file
- **FILE-002**: components/Bar.qml - Bar component
- **FILE-003**: components/Launcher.qml - Launcher component
- **FILE-004**: components/Dashboard.qml - Dashboard component
- **FILE-005**: components/NotificationCenter.qml - Notifications component
- **FILE-006**: services/AudioService.qml - Audio service
- **FILE-007**: services/BrightnessService.qml - Brightness service
- **FILE-008**: services/NetworkService.qml - Network service
- **FILE-009**: services/BatteryService.qml - Battery service
- **FILE-010**: config/shell.json - Configuration file

## 6. Testing

- **TEST-001**: Manual testing of bar interactions (workspaces, tray, clock)
- **TEST-002**: Launcher search functionality with installed apps
- **TEST-003**: Media controls integration with MPRIS
- **TEST-004**: Notification display and actions
- **TEST-005**: IPC commands via qs ipc
- **TEST-006**: Hyprland key binding integration
- **TEST-007**: Configuration loading and persistence

## 7. Risks & Assumptions

- **RISK-001**: MPRIS integration may require additional configuration for Spotify
- **RISK-002**: NetworkManager integration assumes standard Arch setup
- **ASSUMPTION-001**: User has ~/.face file for profile picture
- **ASSUMPTION-002**: OpenWeatherMap API key is available for weather
- **ASSUMPTION-003**: Hyprland is properly configured with key bindings

## 8. Related Specifications / Further Reading

- [Quickshell Documentation](https://github.com/quickshell/quickshell)
- [Qt QML Documentation](https://doc.qt.io/qt-6/qmlapplications.html)
- [MPRIS Specification](https://specifications.freedesktop.org/mpris-spec/latest/)
- [Hyprland IPC](https://hyprland.org/docs/)
