---
goal: Implement Caelestia Color Scheme and Theming System
version: 1.0
date_created: 2025-11-16
owner: Arafays
status: Planned
tags: feature, theming, material-design, hyprland, quickshell, vscode
---

# Introduction

![Status: Planned](https://img.shields.io/badge/status-Planned-blue)

This implementation plan outlines the steps to integrate Caelestia's comprehensive color scheme and theming system based on Material Design 3 principles into the user's Arch Linux environment. The plan adapts the specified color palette and theming approach to work seamlessly with Quickshell, Hyprland, VS Code Insiders, and other applications while maintaining visual consistency and supporting dynamic theming.

## 1. Requirements & Constraints

- **REQ-001**: Implement the defined color palette (#c2c1ff primary, #c6c4e0 secondary, #f5b2e0 tertiary, #131317 background) across all components
- **REQ-002**: Support Material Design 3 token system including surface variants, on-surface variants, and fixed colors
- **REQ-003**: Integrate theming into Hyprland for window borders, gaps, and decorations
- **REQ-004**: Update Quickshell configuration to use Caelestia colors for shell theming
- **REQ-005**: Create theme files for VS Code Insiders and other applications (Firefox, terminal)
- **REQ-006**: Implement dynamic light/dark mode switching capability
- **REQ-007**: Ensure 16-color terminal palette compatibility
- **CON-001**: Must work with existing Arch Linux setup using yay/pacman package managers
- **CON-002**: Respect user's preference for QML-based configurations and VS Code Insiders
- **GUD-001**: Follow Material Design 3 principles for color usage and accessibility
- **PAT-001**: Use centralized color definitions to avoid duplication across configurations

## 2. Implementation Steps

### Phase 1: Color System Foundation
1. Create a centralized color configuration file at `~/.config/caelestia/colors.yaml` containing all Material Design tokens
2. Define primary, secondary, tertiary, and neutral color palettes with all variants (50-900)
3. Implement surface and on-surface color calculations for proper contrast ratios
4. Generate terminal color palette (16 colors) based on the main palette

### Phase 2: Hyprland Integration
1. Update `~/.config/hypr/hyprland.conf` to use Caelestia colors for:
   - Active window border: rgba($primary, 0.9)
   - Inactive window border: rgba($onSurfaceVariant, 0.3)
   - Window shadows: rgba($surface, 0.8)
2. Configure window rules for consistent theming across applications
3. Set up dynamic color variables for runtime theme switching

### Phase 3: Quickshell Theming
1. Modify `~/.config/quickshell/shell.qml` to import Caelestia color scheme
2. Update QML components to use Material tokens for backgrounds, text, and accents
3. Implement theme switching logic in Quickshell for light/dark modes
4. Ensure media controls and dashboard use consistent theming

### Phase 4: Application Themes
1. Create VS Code Insiders theme extension or settings at `~/.config/Code - Insiders/User/settings.json`
2. Develop Firefox userChrome.css for consistent browser theming
3. Configure terminal (kitty) colors using the 16-color palette
4. Update tmux configuration for consistent terminal theming

### Phase 5: Dynamic Theming Infrastructure
1. Implement a theme daemon or script for runtime color switching
2. Create IPC commands for theme changes (integrate with `qs ipc`)
3. Add wallpaper-based dynamic theming if supported
4. Test theme persistence across system restarts

## 3. Alternatives

- **ALT-001**: Use existing Material Design theme frameworks instead of custom implementation - rejected due to need for Caelestia-specific colors
- **ALT-002**: Implement theming at OS level only - rejected as it wouldn't cover application-specific theming needs
- **ALT-003**: Use CSS variables for web applications only - rejected due to need for native application support

## 4. Dependencies

- **DEP-001**: Quickshell (already installed via yay)
- **DEP-002**: Hyprland window manager (already configured)
- **DEP-003**: VS Code Insiders (already set as primary editor)
- **DEP-004**: Firefox browser (for web theming)
- **DEP-005**: Kitty terminal (for terminal colors)

## 5. Files

- **FILE-001**: `~/.config/caelestia/colors.yaml` - Centralized color definitions
- **FILE-002**: `~/.config/hypr/hyprland.conf` - Hyprland configuration updates
- **FILE-003**: `~/.config/quickshell/shell.qml` - Quickshell theme integration
- **FILE-004**: `~/.config/Code - Insiders/User/settings.json` - VS Code theme settings
- **FILE-005**: `~/.mozilla/firefox/[profile]/chrome/userChrome.css` - Firefox custom CSS
- **FILE-006**: `~/.config/kitty/kitty.conf` - Terminal color configuration
- **FILE-007**: `~/.tmux.conf` - Tmux theme configuration

## 6. Testing

- **TEST-001**: Verify color contrast ratios meet WCAG accessibility standards
- **TEST-002**: Test Hyprland window borders and decorations display correctly
- **TEST-003**: Confirm Quickshell loads with new theme and media controls work
- **TEST-004**: Validate VS Code syntax highlighting and UI elements use theme colors
- **TEST-005**: Check Firefox custom CSS applies without breaking functionality
- **TEST-006**: Test terminal colors in various applications (vim, tmux, etc.)
- **TEST-007**: Verify dynamic theme switching works via IPC commands

## 7. Risks & Assumptions

- **RISK-001**: Some applications may not support custom theming, requiring workarounds
- **ASSUMPTION-001**: User has administrative access to modify configuration files
- **ASSUMPTION-002**: Material Design color calculations will provide sufficient contrast
- **RISK-002**: Dynamic theming may impact performance if not implemented efficiently

## 8. Related Specifications / Further Reading

- [Material Design 3 Color System](https://m3.material.io/styles/color/overview)
- [Hyprland Configuration Documentation](https://hyprland.org/)
- [Quickshell Documentation](https://github.com/quickshell/quickshell)
- [VS Code Theme Creation Guide](https://code.visualstudio.com/api/extension-guides/color-theme)