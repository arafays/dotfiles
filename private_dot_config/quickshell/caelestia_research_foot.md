# foot Integration with Caelestia

## Configuration Overview
Foot terminal is configured as the default terminal in Caelestia with custom theming, font settings, and keybindings.

## Key Settings
- **Shell**: fish (default shell)
- **Font**: JetBrains Mono Nerd Font, size 12
- **Padding**: 25x25 pixels
- **Transparency**: 0.78 alpha
- **Cursor**: Beam style with 1.5 thickness

## Features
- **Scrollback**: 10,000 lines
- **DPI Awareness**: Disabled
- **Gamma Correction**: Disabled for blending
- **Bold Text**: Not forced to bright colors

## Key Bindings
- **Page Up/Down**: Standard scrollback navigation
- **Search**: Control+Shift+f to start search
- **Search Navigation**: F3/Shift+F3 for next/previous, Control+G for next
- **Cancel Search**: Escape

## Integration Notes
Foot is set as the default terminal ($TERMINAL) in the Hyprland configuration. The configuration uses JetBrains Mono Nerd Font to match other applications in the rice.