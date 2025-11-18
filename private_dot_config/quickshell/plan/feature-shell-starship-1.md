---
goal: Set up Starship prompt in Zsh with Caelestia-inspired features
version: 1
date_created: 2025-11-16
status: Planned
tags: feature, shell, prompt
---

# Introduction

![Status: Planned](https://img.shields.io/badge/status-Planned-blue)

This implementation plan outlines the setup of Starship prompt in Zsh shell, adapting useful productivity features from Caelestia's Fish shell configuration while respecting the user's Zsh preference. The plan incorporates directory navigation tools, enhanced file listing, git shortcuts, and custom theming.

## 1. Requirements & Constraints

- **REQ-001**: Zsh must be installed and set as default shell
- **REQ-002**: Starship prompt must be installed and initialized in Zsh
- **REQ-003**: Integrate direnv for directory-specific environments
- **REQ-004**: Integrate zoxide for smart directory jumping
- **REQ-005**: Set up eza for enhanced file listing with icons
- **REQ-006**: Implement git aliases/abbreviations equivalent to Fish setup
- **REQ-007**: Configure custom greeting with fastfetch system info
- **REQ-008**: Apply Caelestia-inspired color scheme and symbols in Starship
- **CON-001**: Adapt Fish-specific abbreviations to Zsh aliases
- **CON-002**: Ensure compatibility with existing Zsh configuration
- **GUD-001**: Follow user's profile preferences (use yay for packages, rg for search)
- **GUD-002**: Maintain lightweight setup without heavy frameworks like Oh My Zsh

## 2. Implementation Steps

### Phase 1: Install Dependencies
| Task ID | Description | File/Command | Validation |
|---------|-------------|--------------|------------|
| TASK-001 | Install starship via yay | `yay -S starship` | `starship --version` returns version |
| TASK-002 | Install direnv via yay | `yay -S direnv` | `direnv --version` returns version |
| TASK-003 | Install zoxide via yay | `yay -S zoxide` | `zoxide --version` returns version |
| TASK-004 | Install eza via yay | `yay -S eza` | `eza --version` returns version |
| TASK-005 | Install fastfetch via yay | `yay -S fastfetch` | `fastfetch --version` returns version |

### Phase 2: Configure Starship
| Task ID | Description | File/Command | Validation |
|---------|-------------|--------------|------------|
| TASK-006 | Create starship config directory | `mkdir -p ~/.config` | Directory exists |
| TASK-007 | Create starship.toml with Caelestia-inspired config | Create ~/.config/starship.toml with custom symbols, colors, and modules | File exists and is valid TOML |
| TASK-008 | Configure left-aligned prompt with username, hostname, directory | Add to starship.toml: format, add_newline, etc. | Prompt displays correctly |
| TASK-009 | Configure right-aligned git and directory info | Add right_format to starship.toml | Right side shows git status |
| TASK-010 | Add custom symbols (◎ for success, △ for git, etc.) | Set character, git symbols in starship.toml | Symbols display in prompt |
| TASK-011 | Enable development modules (nodejs, python, rust, lua, deno) | Add module configurations | Modules show when applicable |
| TASK-012 | Enable system modules (battery, time, memory, local_ip) | Add module configurations | System info displays |
| TASK-013 | Enable tool modules (docker, nix_shell, conda, aws) | Add module configurations | Tool indicators show |
| TASK-014 | Configure continuation prompt with dimmed chevrons | Set continuation_prompt in starship.toml | Multi-line commands show chevrons |

### Phase 3: Configure Zsh Integrations
| Task ID | Description | File/Command | Validation |
|---------|-------------|--------------|------------|
| TASK-015 | Initialize starship in ~/.zshrc | Add `eval "$(starship init zsh)"` to ~/.zshrc | Starship prompt loads on shell start |
| TASK-016 | Initialize direnv in ~/.zshrc | Add `eval "$(direnv hook zsh)"` to ~/.zshrc | direnv works in directories with .envrc |
| TASK-017 | Initialize zoxide in ~/.zshrc | Add `eval "$(zoxide init zsh)"` to ~/.zshrc | zoxide commands available |
| TASK-018 | Create git aliases equivalent to Fish abbreviations | Add aliases: lg='lazygit', gd='git diff', etc. to ~/.zshrc | Aliases work in shell |
| TASK-019 | Create file operation aliases | Add l='eza', ll='eza -l', la='eza -a', lla='eza -la' to ~/.zshrc | Aliases use eza with icons |
| TASK-020 | Configure eza with icons and directory-first sorting | Set EZA_CONFIG or alias options | eza shows icons and sorts directories first |

### Phase 4: Set Up Custom Greeting
| Task ID | Description | File/Command | Validation |
|---------|-------------|--------------|------------|
| TASK-021 | Add fastfetch greeting to ~/.zshrc | Add fastfetch command to ~/.zshrc | System info displays on shell start |
| TASK-022 | Configure fastfetch with ASCII art logo | Create/modify fastfetch config | Logo displays with system info |

### Phase 5: Testing and Validation
| Task ID | Description | File/Command | Validation |
|---------|-------------|--------------|------------|
| TASK-023 | Test starship prompt display | Open new zsh session | Prompt shows with all modules |
| TASK-024 | Test git aliases functionality | Run lg, gd, ga, etc. | Commands execute correctly |
| TASK-025 | Test directory tools integration | Use zoxide cd commands, direnv in project dirs | Navigation and env loading work |
| TASK-026 | Test enhanced file listing | Run l, ll, la, lla | eza output with icons displays |
| TASK-027 | Verify custom greeting | Open new shell | fastfetch output appears |

## 3. Alternatives

- **ALT-001**: Use Fish shell instead of Zsh - rejected due to user's explicit Zsh preference in profile
- **ALT-002**: Use Oh My Zsh framework - rejected to maintain lightweight, custom configuration
- **ALT-003**: Use Powerlevel10k instead of Starship - rejected to incorporate Caelestia's Starship-specific customizations
- **ALT-004**: Use exa instead of eza - rejected as eza is the maintained fork with better features

## 4. Dependencies

- **DEP-001**: starship - Cross-shell prompt
- **DEP-002**: direnv - Directory-specific environment variables
- **DEP-003**: zoxide - Smarter cd command
- **DEP-004**: eza - Modern ls replacement
- **DEP-005**: fastfetch - System information tool
- **DEP-006**: zsh - User's preferred shell
- **DEP-007**: git - Version control (for aliases)

## 5. Files

- **FILE-001**: ~/.zshrc - Main Zsh configuration file (modified)
- **FILE-002**: ~/.config/starship.toml - Starship prompt configuration (created)
- **FILE-003**: ~/.config/fastfetch/config.jsonc - Fastfetch configuration (optional, created if needed)

## 6. Testing

- **TEST-001**: Starship prompt renders correctly with custom symbols and colors
- **TEST-002**: All git aliases (lg, gd, ga, gc, gl, gs, gp, gpl, gsw, gsm, gb, gbd, gco, gsh, gst, gsp) function properly
- **TEST-003**: Directory navigation tools (zoxide, direnv) integrate seamlessly
- **TEST-004**: File listing aliases (l, ll, la, lla) use eza with icons and proper sorting
- **TEST-005**: Custom greeting with fastfetch displays system information on shell startup
- **TEST-006**: Prompt continuation works for multi-line commands
- **TEST-007**: Development and system modules appear when relevant tools are active

## 7. Risks & Assumptions

- **RISK-001**: Existing ~/.zshrc may conflict with new configurations - backup required
- **RISK-002**: Package installations may require sudo or specific permissions
- **RISK-003**: Custom symbols may not display correctly in all terminal fonts
- **ASSUMPTION-001**: User has yay package manager available as per profile
- **ASSUMPTION-002**: Terminal supports Unicode and custom fonts (Caskaydia Cove Nerd Font preferred)
- **ASSUMPTION-003**: No existing Starship configuration conflicts

## 8. Related Specifications / Further Reading

- [Caelestia Research: Fish Shell](caelestia_research_fish.md)
- [Caelestia Research: Starship Prompt](caelestia_research_starship.md)
- [User Profile](~/.config/opencode/profile.yaml)
- [Starship Configuration Documentation](https://starship.rs/config/)
- [Zsh Documentation](https://zsh.sourceforge.io/Doc/)
