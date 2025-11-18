# Theming and Color Scheme in Caelestia

## Overview
Caelestia uses a comprehensive color system based on Material Design 3 principles, with custom color palettes and extensive theming for all components.

## Color Palette
- **Primary**: #c2c1ff (light purple)
- **Secondary**: #c6c4e0 (muted purple)
- **Tertiary**: #f5b2e0 (pink)
- **Background**: #131317 (dark gray)
- **Surface**: #131317 (matching background)
- **On Background**: #e5e1e7 (light gray)

## Material Tokens
- **Surface variants**: Multiple surface levels for layering
- **On Surface variants**: Text colors for different backgrounds
- **Fixed colors**: Additional accent colors for specific uses
- **Terminal colors**: 16-color palette for terminal applications

## Implementation
- **Hyprland**: Colors used for window borders, gaps, and decorations
- **Shell**: Integrated into Quickshell for consistent theming
- **Applications**: Theme files for VSCode, Firefox, etc.
- **Dynamic**: Support for light/dark mode switching

## Key Colors
- **Active Window Border**: rgba($primarye6) - semi-transparent primary
- **Inactive Window Border**: rgba($onSurfaceVariant11) - subtle gray
- **Shadows**: rgba($surfaced4) - dark surface for depth

## Integration Notes
The color scheme provides a cohesive dark theme with purple accents, used across all Caelestia components for visual consistency.