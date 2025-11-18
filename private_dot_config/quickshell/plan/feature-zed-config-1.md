---
goal: Configure Zed editor with Caelestia-inspired settings adapted to user preferences
version: 1
date_created: 2025-11-16
last_updated: 2025-11-16
owner: Arafays
status: 'Planned'
tags: ['feature', 'configuration', 'editor']
---

# Introduction

![Status: Planned](https://img.shields.io/badge/status-Planned-blue)

This implementation plan outlines the steps to configure the Zed editor with settings derived from the Caelestia research document, adapted to align with the user's preferences from their profile. The configuration will include font settings, theming, and language-specific configurations for optimal development experience.

## 1. Requirements & Constraints

- **REQ-001**: Set UI and buffer font size to 16px for consistency with user environment
- **REQ-002**: Use "CaskaydiaCove Nerd Font" as the font family, matching user's preferred fonts
- **REQ-003**: Configure system-based theme with One Light/Dark variants
- **REQ-004**: Set multi-cursor modifier to cmd_or_ctrl for standard behavior
- **REQ-005**: Configure Nix language server with nixd and alejandra formatter
- **REQ-006**: Set up QML language support with qmlls and qmlformat
- **REQ-007**: Adapt JavaScript/TypeScript configuration to use Biome for formatting and linting, per user preferences
- **CON-001**: Configuration must be written to Zed's standard settings file at ~/.config/zed/settings.json
- **CON-002**: All language servers and formatters must be installed and available in PATH
- **GUD-001**: Follow Zed's JSON configuration format
- **PAT-001**: Use absolute paths where necessary for executables

## 2. Implementation Steps

1. **Create Zed settings directory**: Ensure ~/.config/zed/ directory exists
2. **Generate settings.json**: Create the configuration file with all specified settings
3. **Install required language servers**: Ensure nixd, qmlls, alejandra, qmlformat, and biome are installed
4. **Test configuration**: Launch Zed and verify all settings are applied correctly
5. **Validate language features**: Test Nix and QML file editing with LSP features

## 3. Alternatives

- **ALT-001**: Use VS Code Insiders as primary editor instead of Zed, leveraging existing user familiarity
- **ALT-002**: Configure Zed with default settings and manually adjust, rather than using Caelestia-derived configs
- **ALT-003**: Use Neovim instead, as it's the user's secondary editor with potentially better customization

## 4. Dependencies

- **DEP-001**: Zed editor installed via yay -S zed
- **DEP-002**: nixd language server for Nix support
- **DEP-003**: alejandra Nix formatter
- **DEP-004**: qmlls Qt Modeling Language server
- **DEP-005**: qmlformat for QML formatting
- **DEP-006**: biome for JavaScript/TypeScript formatting and linting

## 5. Files

- **FILE-001**: ~/.config/zed/settings.json - Main configuration file containing all editor settings

## 6. Testing

- **TEST-001**: Launch Zed and verify font family and size are applied in UI and editor
- **TEST-002**: Open a Nix file and confirm LSP features (completion, diagnostics) work with nixd
- **TEST-003**: Open a QML file and test formatting with qmlformat
- **TEST-004**: Open a TypeScript file and ensure Biome is used for formatting
- **TEST-005**: Test multi-cursor functionality with cmd_or_ctrl modifier

## 7. Risks & Assumptions

- **RISK-001**: Zed may not support all specified configuration options, requiring adjustments
- **ASSUMPTION-001**: All required language servers and tools are available in the system PATH
- **ASSUMPTION-002**: User's system has sufficient resources for running LSP servers

## 8. Related Specifications / Further Reading

- [Caelestia Zed Research Document](./caelestia_research_zed.md)
- [User Profile Configuration](../opencode/profile.yaml)
- [Zed Documentation](https://zed.dev/docs)</content>
<parameter name="filePath">plan/feature-zed-config-1.md