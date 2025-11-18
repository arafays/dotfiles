# btop Integration with Caelestia

## Configuration Overview
btop is configured in Caelestia with a custom theme called "caelestia" and specific settings optimized for the rice.

## Key Settings
- **Theme**: `color_theme = "caelestia"` - Uses a custom Caelestia theme
- **Background**: `theme_background = False` - Transparent background for terminal integration
- **Truecolor**: `truecolor = True` - Enables 24-bit color support
- **Graph Symbols**: `graph_symbol = "braille"` - High-resolution braille graphs
- **Rounded Corners**: `rounded_corners = True` - Modern UI with rounded corners
- **Update Interval**: `update_ms = 2000` - 2-second refresh rate

## Display Boxes
- **Shown Boxes**: CPU, Memory, Network, and Processes
- **CPU Graphs**: Upper shows auto-detected stat, lower shows total with inversion
- **Memory**: Shows graphs with ZFS ARC caching enabled
- **Processes**: Sorted by CPU lazy, shows memory in bytes, includes CPU graphs per process

## Features Enabled
- CPU temperature monitoring
- CPU frequency display
- Battery stats (if present)
- Disk I/O statistics
- Network auto-scaling
- Vim keybindings disabled

## Integration Notes
The configuration assumes the "caelestia" theme file exists in the btop themes directory. The theme likely uses colors that match the overall Caelestia color scheme.