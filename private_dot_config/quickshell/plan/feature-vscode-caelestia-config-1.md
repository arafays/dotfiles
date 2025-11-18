---
goal: Configure VS Code Insiders to replicate Caelestia's VSCode setup adapted for user preferences
version: 1
date_created: 2025-11-16
last_updated: 2025-11-16
owner: Arafays
status: Planned
tags: feature, configuration, vscode, biome, theming
---

# Introduction

![Status: Planned](https://img.shields.io/badge/status-Planned-blue)

This implementation plan outlines the steps to configure VS Code Insiders to match the Caelestia research setup, while adapting settings, extensions, and theming to align with the user's preferences as defined in the opencode profile (e.g., preferring Biome over Prettier, specific formatting rules, and tool choices).

## 1. Requirements & Constraints

- **REQ-001**: Replicate Caelestia's VSCode configuration including theme, font, icon theme, and language-specific settings
- **REQ-002**: Adapt formatting and linting to use Biome instead of Prettier for JavaScript/TypeScript
- **REQ-003**: Adjust code formatting width to 100 characters as per user preferences (instead of Caelestia's 120)
- **REQ-004**: Maintain QML support for Quickshell development
- **REQ-005**: Ensure smooth scrolling, cursor animations, and other UI enhancements are enabled
- **REQ-006**: Install necessary extensions for AI completion, Python (Ruff), and C/C++ (clangd)
- **CON-001**: Use VS Code Insiders as the primary editor
- **CON-002**: Respect user's preference for Biome over ESLint/Prettier
- **CON-003**: Use Caskaydia Cove Nerd Font (matching user's font preference)
- **GUD-001**: Follow user's naming and formatting conventions (e.g., single quotes, trailing commas)
- **PAT-001**: Use absolute paths for configuration files as specified in profile

## 2. Implementation Steps

| Task ID | Description | Dependencies | Files Affected | Validation Criteria |
|---------|-------------|--------------|----------------|---------------------|
| TASK-001 | Install required VS Code extensions | None | None (extensions installed via CLI) | Extensions appear in VS Code Extensions panel |
| TASK-002 | Update VS Code settings.json with adapted configuration | TASK-001 | ~/.config/Code - Insiders/User/settings.json | Settings applied without errors; Biome formats correctly |
| TASK-003 | Update VS Code keybindings.json if custom bindings are needed | TASK-002 | ~/.config/Code - Insiders/User/keybindings.json | Keybindings functional |
| TASK-004 | Install custom Caelestia theme extension (if available) or select alternative theme | TASK-001 | None | Theme applied and matches aesthetic |
| TASK-005 | Verify QML language server configuration | TASK-002 | None | QML files have proper syntax highlighting and IntelliSense |
| TASK-006 | Test formatting and linting on sample files | TASK-002 | Test files in workspace | Code formatted to Biome standards (width 100, single quotes, etc.) |

## 3. Alternatives

- **ALT-001**: Use Prettier instead of Biome - Rejected due to user's explicit preference for Biome over Prettier/ESLint
- **ALT-002**: Use default VS Code theme instead of Caelestia custom theme - Rejected to maintain aesthetic consistency with Caelestia setup
- **ALT-003**: Use different icon theme - Considered Catppuccin variants but Mocha kept for consistency
- **ALT-004**: Use different font - Considered Noto Nerd Font but Caskaydia Cove preferred for consistency

## 4. Dependencies

- **DEP-001**: VS Code Insiders installed and functional
- **DEP-002**: Caskaydia Cove Nerd Font installed on system
- **DEP-003**: Qt6 and qmlls6 for QML support (if QML development needed)
- **DEP-004**: Node.js and Biome installed globally or via mise
- **DEP-005**: Python and Ruff installed for Python development

## 5. Files

- **FILE-001**: ~/.config/Code - Insiders/User/settings.json - Main configuration file with adapted settings
- **FILE-002**: ~/.config/Code - Insiders/User/keybindings.json - Keybindings configuration (if modifications needed)
- **FILE-003**: Test QML/JS/TS/Python files - For validation of formatting and language support

## 6. Testing

- **TEST-001**: Open VS Code Insiders and verify theme, icon theme, and font are applied
- **TEST-002**: Create a sample TypeScript file and verify Biome formatting (width 100, single quotes, trailing commas)
- **TEST-003**: Create a sample QML file and verify syntax highlighting and IntelliSense
- **TEST-004**: Create a sample Python file and verify Ruff formatting and linting
- **TEST-005**: Test smooth scrolling and cursor animations in editor
- **TEST-006**: Verify Codeium AI completion works in supported languages

## 7. Risks & Assumptions

- **RISK-001**: Custom Caelestia theme extension may not be publicly available - Mitigated by selecting similar alternative theme
- **RISK-002**: Conflicts with existing VS Code settings - Mitigated by backing up current settings before changes
- **RISK-003**: Biome configuration may not perfectly match all Caelestia formatting rules - Mitigated by manual testing and adjustments
- **ASSUMPTION-001**: User has necessary dependencies (Qt6, Node.js, Python) installed
- **ASSUMPTION-002**: VS Code Insiders is the primary editor and settings path is correct

## 8. Related Specifications / Further Reading

- [Caelestia Research VSCode Configuration](/home/arafays/.config/quickshell/caelestia_research_vscode.md)
- [OpenCode User Profile](~/.config/opencode/profile.yaml)
- [Biome Configuration Documentation](https://biomejs.dev/reference/configuration/)
- [VS Code Settings Reference](https://code.visualstudio.com/docs/getstarted/settings)</content>
<parameter name="filePath">plan/feature-vscode-caelestia-config-1.md