# fastfetch Integration with Caelestia

## Configuration Overview
fastfetch is configured with a custom ASCII art layout showing system information in a bordered box format.

## Layout Structure
- **Border**: Unicode box drawing characters for clean borders
- **Modules**: Custom arrangement with icons and formatted output
- **Color Coding**: Uses ANSI color codes for visual hierarchy

## Displayed Information
- **Kernel**: Release version with icon
- **Uptime**: System uptime in human-readable format
- **Shell**: Current shell name
- **Memory**: Used/total memory in GiB
- **Packages**: Total package count
- **User**: Current username
- **Hostname**: System hostname
- **Distro**: Distribution name with icon

## Styling
- **Separator**: Double spaces between elements
- **Colors**: White text with colored accents (37m, 16m, 17m, 18m ANSI codes)
- **Width**: Fixed 35-character content width with borders
- **Icons**: Nerd Font icons for visual elements

## Integration Notes
The configuration creates a compact, bordered system information display that fits well with the overall Caelestia aesthetic. Uses custom command modules for formatted output and consistent spacing.