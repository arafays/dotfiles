# hypr Integration with Caelestia

## Configuration Overview
Hyprland is the core window manager in Caelestia, with a modular configuration system split across multiple files.

## Configuration Structure
- **Main Config**: `hyprland.conf` - Entry point that sources other configs
- **Modular Files**: env.conf, general.conf, input.conf, misc.conf, animations.conf, decoration.conf, group.conf, execs.conf, rules.conf, gestures.conf, keybinds.conf
- **Scheme System**: Dynamic color scheme loading from `scheme/current.conf`
- **User Variables**: Custom user configuration in `~/.config/caelestia/hypr-vars.conf`

## Key Features
- **Monitor**: Auto-detection with preferred resolution
- **Environment Setup**: Copies default scheme to current on startup
- **User Customization**: Separate user config file for personal settings

## Integration Notes
The configuration assumes a specific directory structure and uses environment variables for paths. It includes both default configurations and user customization points. The scheme system allows for dynamic theming.

## Dependencies
Relies on various Hyprland plugins and utilities like hyprpicker, wl-clipboard, etc.