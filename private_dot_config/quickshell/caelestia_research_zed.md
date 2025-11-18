# zed Integration with Caelestia

## Configuration Overview
Zed editor is configured with Caelestia-specific settings including font choices, themes, and language-specific configurations.

## Key Settings
- **UI Font Size**: 16px
- **Buffer Font Size**: 16px
- **Font Family**: "CaskaydiaCove Nerd Font" - Matches Caelestia's font choice
- **Theme**: System-based with One Light/Dark variants
- **Multi-cursor Modifier**: cmd_or_ctrl

## Language Configurations
- **Nix**: Uses nixd language server with alejandra formatter
- **QML**: Custom formatter using qmlformat with temporary file handling

## LSP Settings
- **nixd**: Configured with nixpkgs import and alejandra formatting
- **qml**: Uses qmlls with -E flag

## Integration Notes
Zed configuration aligns with Caelestia's overall aesthetic:
- Uses the same Nerd Font as other applications
- Includes QML support (relevant for Quickshell development)
- Nix support for system configuration
- Consistent font sizing with other tools