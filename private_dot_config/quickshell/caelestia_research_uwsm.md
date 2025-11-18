# uwsm Integration with Caelestia

## Configuration Overview
uwsm (Universal Wayland Session Manager) is configured in Caelestia with environment variables and app categorization for systemd integration.

## Environment Variables
- **QT_QPA_PLATFORMTHEME**: Set to 'qt6ct' for consistent Qt theming
- **QT_WAYLAND_DISABLE_WINDOWDECORATION**: '1' to disable window decorations in Wayland
- **QT_AUTO_SCREEN_SCALE_FACTOR**: '1' for automatic screen scaling

## App Categorization
Uses app2unit for systemd slice management:
- `a=app-graphical.slice` - Graphical applications
- `b=background-graphical.slice` - Background graphical processes  
- `s=session-graphical.slice` - Session graphical processes

## Integration Notes
The uwsm configuration ensures proper Qt application theming and resource management through systemd slices. This allows for better process organization and resource control in the Wayland session.

## Purpose
- Ensures Qt applications use the correct theme (qt6ct)
- Disables redundant window decorations in Wayland
- Enables automatic scaling for HiDPI displays
- Categorizes applications for systemd resource management