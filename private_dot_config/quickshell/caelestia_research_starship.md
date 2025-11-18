# Starship Prompt in Caelestia

## Configuration Overview
Starship is configured with custom symbols, colors, and layout to match Caelestia's aesthetic. Features extensive module support and custom formatting.

## Key Features
- **Custom Symbols**: Unique symbols for different modules (◎ for success, △ for git, etc.)
- **Color Scheme**: Matches Caelestia's color palette
- **Layout**: Left-aligned prompt with right-aligned directory/git info
- **Continuation Prompt**: Dimmed white chevrons for multi-line commands

## Modules Enabled
- **Core**: username, hostname, directory, git status/metrics
- **System**: battery, time, memory usage, local IP
- **Development**: nodejs, python, rust, lua, deno, and many others
- **Tools**: docker, nix_shell, conda, aws, etc.

## Custom Formatting
- **Character**: Success/error symbols with colors
- **Directory**: Home symbol (⌂), truncation, read-only indicator
- **Git**: Branch with remote tracking, status indicators, metrics
- **Battery**: Multiple thresholds with color coding
- **Time**: 24-hour format in dimmed white

## Integration Notes
Starship config complements the Fish shell setup, providing rich contextual information in the prompt. Symbols and colors align with the overall Caelestia theme.