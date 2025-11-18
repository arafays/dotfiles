# AGENTS

- Distro: Arch (use `yay`); Shell: `zsh`; Editors: VS Code Insiders, `nvim`; `tmux`.
- Global profile: `~/.config/opencode/profile.yaml` (agents should read this on start).
- Search: use `rg` only; do not call `grep` (alias points to `rg`).
- **IMPORTANT**: Always check latest documentation - information here may be outdated

## Build/Lint/Test

- **Build**: `cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release && cmake --build build`
- **Install**: `sudo cmake --install build` (or custom prefix for local changes)
- **Run**: `qs` (default config) or `qs -c <config>` or `qs -p <path>` always try to run for 30 seconds after build
- **Debug**: `qs -vv` (verbose), `qs --debug <port>` (QML debugger), `qs log` (view logs)
- **Dependencies**: Install quickshell-git, Qt6 via `yay` (minimize additional packages)
- **Single test**: No unit tests currently; manual testing via running the shell
- **IPC commands**: `qs ipc` subcommands for runtime control

## Code Style

- **Language**: QML (Qt Modeling Language) with C++ plugins
- **Imports**: Group QtQuick imports first, then custom modules; sort alphabetically
- **Formatting**: Follow Qt/QML conventions; 4-space indentation; consistent spacing
- **Naming**: camelCase for properties/functions; PascalCase for component names
- **Types**: Use proper QML types; avoid `var` when possible; use typed properties
- **Structure**: Separate UI logic from business logic; use QML modules for organization
- **Comments**: JSDoc style for functions; inline comments for complex logic

## Conventions

- **Configuration**: QML file at `~/.config/quickshell/shell.qml` (create if missing)
- **Media support**: Full Spotify/MPRIS integration via MPRIS service
- **IPC**: Use `qs ipc call <command>` for runtime control
- **Themes**: Support for dynamic color schemes based on wallpapers
- **Extensions**: Add custom QML components in `components/` directory
- **Build customization**: Modify `CMakeLists.txt` for additional features
- **Debugging**: Use `qs -vv` for verbose debug output, `qs --debug <port>` for QML debugger
- **Hot reload**: Live reload on file save; use `qs ipc call reload` for manual reload
- **Fonts**: Use Caskaydia Cove Nerd Font or Noto Nerd Font for icons

## Media/Spotify Integration

- **MPRIS support**: Automatic detection of media players (Spotify, etc.)
- **Controls**: Play/pause, next/prev, seek via IPC or UI
- **Metadata**: Track info, album art, progress display
- **Playlists**: Full playlist navigation and control
- **Multiple players**: Switch between active media sources
- **DBus integration**: Standard MPRIS2 protocol compliance

## Key Bindings (Hyprland)

- `Ctrl + Alt + Q`: Reload shell config
- `Super + Space`: Open launcher
- `Super + T`: Open terminal
- `Super + W`: Open browser
- Dashboard and bar interactions for media controls

## Caelestia Research & Implementation

- **Research Repository**: https://github.com/caelestia-dots/caelestia (dots), shell, cli
- **Documentation**: caelestia_research_*.md files in this directory
- **Implementation Plans**: plan/feature-*.md files for each component
- **Key Components**: Hyprland config, Quickshell UI, Python CLI, theming system
- **Inspiration**: Modular design, smooth animations, comprehensive IPC integration

## Key Bindings (Hyprland) - Caelestia Inspired

- `Super`: Open launcher
- `Super + 1-0`: Switch to workspace 1-10
- `Super + Alt + 1-0`: Move window to workspace 1-10
- `Super + T`: Open terminal (kitty)
- `Super + W`: Open browser (Firefox)
- `Super + C`: Open IDE (VS Code Insiders)
- `Super + S`: Toggle special workspace
- `Ctrl + Alt + Delete`: Open session menu
- `Ctrl + Super + Space`: Toggle media play/pause
- `Ctrl + Super + Alt + R`: Restart shell
- `Ctrl + Alt + Q`: Reload shell config (existing)

## Troubleshooting

- **Flickering**: Disable VRR in hyprland config: `misc { vrr = 0 }`
- **No media controls**: Check MPRIS service is running: `playerctl status`
- **Config not loading**: Validate QML syntax in `shell.qml`; use `qs -vv` for errors
- **Debugging**: Use `qs log` to view logs; `qs --debug <port>` for QML debugger

