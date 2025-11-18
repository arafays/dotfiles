---
goal: Implement Python CLI Tools Replicating Caelestia's Control Functionality for Quickshell
version: 1
date_created: 2025-11-16
last_updated: 2025-11-16
owner: Arafays
status: 'Planned'
tags: ['feature', 'cli', 'quickshell', 'python', 'system-control']
---

# Introduction

![Status: Planned](https://img.shields.io/badge/status-Planned-blue)

This implementation plan outlines the creation of Python-based CLI tools that replicate the control functionality of Caelestia's CLI, adapted for the Quickshell environment on Arch Linux. The tools will provide command-line interfaces for managing shell operations, wallpapers, color schemes, screenshots, recordings, clipboard, emoji picker, and special workspace toggles, integrated with Quickshell's IPC system and the user's preferred tools and workflows.

## 1. Requirements & Constraints

- **REQ-001**: Implement CLI in Python 3 with modular subcommands structure
- **REQ-002**: Integrate with Quickshell IPC using `qs ipc` commands for shell control
- **REQ-003**: Support wallpaper management with post-hooks and directory watching
- **REQ-004**: Implement color scheme management with dynamic generation from wallpapers
- **REQ-005**: Provide screenshot functionality using grim, slurp, and swappy
- **REQ-006**: Add screen recording with gpu-screen-recorder backend
- **REQ-007**: Include clipboard history with fuzzel integration
- **REQ-008**: Implement emoji/glyph picker with search and clipboard copy
- **REQ-009**: Create special workspace toggles for sysmon, music, communication, todo
- **REQ-010**: Use JSON configuration file at `~/.config/quickshell/cli.json`
- **SEC-001**: Ensure secure handling of system commands and IPC communication
- **CON-001**: Adapt to Arch Linux with yay/pacman package management
- **CON-002**: Integrate with Hyprland window manager for workspace and window operations
- **CON-003**: Use zsh as the primary shell environment
- **GUD-001**: Follow user's preferences: use rg for search operations, biome for code formatting
- **GUD-002**: Use camelCase for variables/functions, PascalCase for classes, kebab-case for files
- **PAT-001**: Implement CLI using Click framework for command-line parsing
- **PAT-002**: Structure code with separate modules for each subcommand

## 2. Implementation Steps

### Phase 1: Project Setup and Core Structure
- **TASK-001**: Create main CLI entry point script `caelestia-cli.py` with Click group setup
- **TASK-002**: Set up modular directory structure: `commands/` for subcommands, `utils/` for utilities
- **TASK-003**: Initialize JSON configuration file handling with default values
- **TASK-004**: Implement configuration loading from `~/.config/quickshell/cli.json`

### Phase 2: Core IPC Integration
- **TASK-005**: Create Quickshell IPC wrapper module for `qs ipc` command execution
- **TASK-006**: Implement shell control subcommand (start, message, lock, unlock)
- **TASK-007**: Add MPRIS controls integration for media playback
- **TASK-008**: Implement notification management through IPC

### Phase 3: System Control Features
- **TASK-009**: Implement wallpaper subcommand with set, list, random, and directory operations
- **TASK-010**: Add post-hook execution for wallpaper changes
- **TASK-011**: Create scheme subcommand for color scheme management and generation
- **TASK-012**: Implement toggle subcommand for special workspaces with app launching

### Phase 4: Media and Capture Tools
- **TASK-013**: Build screenshot subcommand using grim/slurp/swappy integration
- **TASK-014**: Implement record subcommand with gpu-screen-recorder backend
- **TASK-015**: Add clipboard history subcommand with fuzzel interface
- **TASK-016**: Create emoji picker subcommand with search functionality

### Phase 5: Advanced Features
- **TASK-017**: Implement resizer daemon for window resizing operations
- **TASK-018**: Add configuration validation and error handling
- **TASK-019**: Integrate with user's preferred tools (rg for search, etc.)

### Phase 6: Testing and Documentation
- **TASK-020**: Write unit tests for all modules using pytest
- **TASK-021**: Create integration tests with Quickshell IPC
- **TASK-022**: Document all subcommands and configuration options
- **TASK-023**: Add installation and setup instructions for Arch Linux

## 3. Alternatives

- **ALT-001**: Use bash scripts instead of Python for simpler commands - rejected due to need for complex logic and modularity
- **ALT-002**: Integrate directly with Quickshell QML instead of IPC - rejected due to IPC being the designed interface
- **ALT-003**: Use argparse instead of Click - rejected for better subcommand handling and documentation features

## 4. Dependencies

- **DEP-001**: Python 3.8+ (system dependency)
- **DEP-002**: Click library for CLI framework (`pip install click`)
- **DEP-003**: PyYAML for configuration handling (`pip install pyyaml`)
- **DEP-004**: System tools: grim, slurp, swappy, gpu-screen-recorder, fuzzel, playerctl
- **DEP-005**: Quickshell with IPC support (already installed)

## 5. Files

- **FILE-001**: `caelestia-cli.py` - Main CLI entry point
- **FILE-002**: `commands/shell.py` - Shell control subcommand
- **FILE-003**: `commands/toggle.py` - Workspace toggle subcommand
- **FILE-004**: `commands/scheme.py` - Color scheme management
- **FILE-005**: `commands/screenshot.py` - Screenshot functionality
- **FILE-006**: `commands/record.py` - Screen recording
- **FILE-007**: `commands/clipboard.py` - Clipboard history
- **FILE-008**: `commands/emoji.py` - Emoji picker
- **FILE-009**: `commands/wallpaper.py` - Wallpaper management
- **FILE-010**: `commands/resizer.py` - Window resizer daemon
- **FILE-011**: `utils/ipc.py` - Quickshell IPC wrapper
- **FILE-012**: `utils/config.py` - Configuration handling
- **FILE-013**: `utils/system.py` - System command utilities
- **FILE-014**: `setup.py` - Package setup for pip installation
- **FILE-015**: `cli.json` - Default configuration template

## 6. Testing

- **TEST-001**: Unit tests for configuration loading and validation
- **TEST-002**: Unit tests for IPC command execution
- **TEST-003**: Integration tests for each subcommand with mock Quickshell
- **TEST-004**: Manual testing of screenshot and recording functionality
- **TEST-005**: End-to-end testing of workspace toggles with Hyprland
- **TEST-006**: Performance tests for wallpaper directory watching

## 7. Risks & Assumptions

- **RISK-001**: Quickshell IPC API may change, requiring updates to integration code
- **RISK-002**: System tool dependencies may not be available or compatible on all Arch systems
- **RISK-003**: Performance impact of Python CLI vs native tools for frequent operations
- **ASSUMPTION-001**: Quickshell is properly installed and configured with IPC enabled
- **ASSUMPTION-002**: All required system tools are installed via yay/pacman
- **ASSUMPTION-003**: User has proper permissions for system operations

## 8. Related Specifications / Further Reading

- [Quickshell IPC Documentation](https://github.com/quickshell/quickshell)
- [Caelestia Research CLI Spec](/home/arafays/.config/quickshell/caelestia_research_cli.md)
- [Hyprland Documentation](https://hyprland.org/)
- [Arch Wiki - Sway Tools](https://wiki.archlinux.org/title/Sway#Screenshot)
</content>
<parameter name="filePath">plan/feature-caelestia-cli-1.md