# VSCode/VSCodium Integration with Caelestia

## Configuration Overview
VSCode/VSCodium is configured with Caelestia-specific settings including theme, font choices, and language-specific configurations. Includes a custom Caelestia theme extension.

## Key Settings
- **Theme**: Custom "Caelestia" theme (installed via extension)
- **Icon Theme**: Catppuccin Mocha
- **Font**: CaskaydiaCove Nerd Font (matches other apps)
- **Font Size**: 16px (consistent with other tools)
- **Smooth Scrolling**: Enabled for editor, terminal, and lists
- **Cursor**: Smooth caret animation
- **Format on Save**: Enabled with Prettier
- **Organize Imports**: Automatic on save

## Language Configurations
- **QML**: Custom QML language server (qmlls6) with Qt6 QML paths
- **Python**: Ruff formatter, Pylance language server
- **C/C++**: LLVM clangd formatter
- **TypeScript/JavaScript**: Prettier with 120 width, minimal import endings

## Extensions
- **Caelestia VSCode Integration**: Custom theme and settings
- **Codeium**: AI code completion (enabled for most languages)
- **Prettier**: Code formatting
- **Ruff**: Python linting and formatting
- **Qt QML**: QML language support

## Integration Notes
VSCode config aligns with Caelestia's overall aesthetic and workflow. Uses the same Nerd Font and includes QML support relevant for Quickshell development. Theme matches the desktop color scheme.