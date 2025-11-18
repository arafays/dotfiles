---
goal: Adapt Caelestia's Hyprland Configuration to Arch Linux System
version: 1.0
date_created: 2025-11-16
last_updated: 2025-11-16
owner: Arafays
status: Planned
tags: feature, configuration, hyprland, window-manager
---

# Introduction

![Status: Planned](https://img.shields.io/badge/status-Planned-blue)

This implementation plan outlines the steps to adapt Caelestia's Hyprland configuration to the user's Arch Linux system, incorporating preferences for zsh shell, VS Code Insiders editor, kitty terminal, and other system-specific settings. The plan focuses on key components including window management, keybinds, animations, and theming while adapting app preferences and system-specific configurations.

## 1. Requirements & Constraints

- **REQ-001**: Install Hyprland window manager on Arch Linux using yay package manager
- **REQ-002**: Configure keybinds for user's preferred applications (VS Code Insiders, kitty terminal, firefox browser, thunar file manager)
- **REQ-003**: Adapt shell integration for zsh instead of fish
- **REQ-004**: Implement modular configuration structure with variables, schemes, and scripts
- **REQ-005**: Set up animations with custom bezier curves and smooth transitions
- **REQ-006**: Configure theming support with color schemes and borders
- **REQ-007**: Integrate media controls for Spotify/MPRIS
- **REQ-008**: Set up workspace management with 10 workspaces and special workspace
- **CON-001**: Must maintain compatibility with existing quickshell configuration
- **CON-002**: Keybinds must not conflict with Hyprland defaults or user's existing shortcuts
- **CON-003**: Configuration must work with Arch Linux package ecosystem
- **GUD-001**: Follow Hyprland best practices for configuration organization
- **GUD-002**: Use absolute paths where necessary for system-specific locations
- **PAT-001**: Modular config pattern with separate files for variables, keybinds, and rules

## 2. Implementation Steps

### Phase 1: Installation and Base Setup
1. Install Hyprland and required dependencies using yay
2. Create Hyprland configuration directory structure
3. Set up basic hyprland.conf with source directives

### Phase 2: Core Configuration
1. Create variables.conf with app definitions, gaps, and colors
2. Configure layout settings (dwindle, gaps, borders, rounding)
3. Set up monitor and workspace configurations
4. Implement window rules and layer rules

### Phase 3: Keybinds Adaptation
1. Adapt keybinds for user's applications (Super+T for kitty, Super+W for firefox, etc.)
2. Implement workspace switching (Super+1-0)
3. Set up window management keybinds (move, resize, toggle floating)
4. Configure media controls integration
5. Add utility keybinds (screenshot, clipboard, emoji picker)

### Phase 4: Animations and Theming
1. Implement custom bezier curves for animations
2. Configure window, workspace, and layer animations
3. Set up color scheme management with scheme/ directory
4. Configure borders and active/inactive window styling

### Phase 5: Scripts and Integration
1. Adapt shell scripts for zsh compatibility (wsaction.sh instead of .fish)
2. Integrate with quickshell for launcher and notifications
3. Set up special workspace toggles
4. Configure touchpad gestures if applicable

### Phase 6: Testing and Validation
1. Test Hyprland startup and basic functionality
2. Verify all keybinds work with user's applications
3. Test animations and theming
4. Validate media controls and workspace management

## 3. Alternatives

- **ALT-001**: Use default Hyprland config as base instead of Caelestia's - rejected due to requirement for advanced features like animations and theming
- **ALT-002**: Maintain fish shell compatibility - rejected due to user's zsh preference
- **ALT-003**: Use different terminal emulator - rejected as kitty is user's primary terminal
- **ALT-004**: Skip modular config structure - rejected for maintainability and theming flexibility

## 4. Dependencies

- **DEP-001**: Hyprland window manager (yay -S hyprland)
- **DEP-002**: kitty terminal emulator (yay -S kitty)
- **DEP-003**: VS Code Insiders (yay -S visual-studio-code-insiders)
- **DEP-004**: Firefox browser (yay -S firefox)
- **DEP-005**: Thunar file manager (yay -S thunar)
- **DEP-006**: MPRIS media controls (playerctl or similar)
- **DEP-007**: Screenshot utilities (grim, slurp)
- **DEP-008**: Clipboard manager (wl-clipboard, cliphist)
- **DEP-009**: Emoji picker (wofi-emoji or similar)

## 5. Files

- **FILE-001**: ~/.config/hypr/hyprland.conf - Main configuration file
- **FILE-002**: ~/.config/hypr/variables.conf - App definitions and variables
- **FILE-003**: ~/.config/hypr/keybinds.conf - Keybind definitions
- **FILE-004**: ~/.config/hypr/rules.conf - Window and layer rules
- **FILE-005**: ~/.config/hypr/scheme/default.conf - Default color scheme
- **FILE-006**: ~/.config/hypr/scheme/current.conf - Current color scheme
- **FILE-007**: ~/.config/hypr/scripts/wsaction.sh - Workspace action script (zsh)
- **FILE-008**: ~/.config/hypr/scripts/screenshot.sh - Screenshot script
- **FILE-009**: ~/.config/hypr/scripts/clipboard.sh - Clipboard manager script

## 6. Testing

- **TEST-001**: Verify Hyprland starts without errors: `Hyprland` command
- **TEST-002**: Test keybinds: Super+T opens kitty, Super+W opens firefox, Super+1-0 switches workspaces
- **TEST-003**: Validate window management: floating toggle, move to workspace, resize
- **TEST-004**: Check animations: window open/close, workspace switch transitions
- **TEST-005**: Test media controls: play/pause with Ctrl+Super+Space
- **TEST-006**: Verify theming: borders, active/inactive colors, color scheme switching
- **TEST-007**: Test utilities: screenshot (Super+Shift+S), clipboard (Super+V), emoji picker (Super+.)
- **TEST-008**: Check integration: quickshell launcher with Super+Space, notifications

## 7. Risks & Assumptions

- **RISK-001**: Potential conflicts with existing X11/Wayland configurations
- **RISK-002**: Keybind conflicts with other applications or system shortcuts
- **RISK-003**: Performance issues with animations on lower-end hardware
- **RISK-004**: Compatibility issues with specific GPU drivers
- **ASSUMPTION-001**: User has basic Arch Linux system with yay package manager
- **ASSUMPTION-002**: All required applications (kitty, vscode-insiders, firefox) are installed
- **ASSUMPTION-003**: User prefers zsh shell and has it configured
- **ASSUMPTION-004**: System supports Wayland and has compatible graphics drivers

## 8. Related Specifications / Further Reading

- [Hyprland Configuration Documentation](https://hyprland.org/Configuring/)
- [Caelestia Research Summary](/home/arafays/.config/quickshell/caelestia_research_summary.md)
- [Arch Linux Hyprland Wiki](https://wiki.archlinux.org/title/Hyprland)
- [User Profile Configuration](/home/arafays/.config/opencode/profile.yaml)