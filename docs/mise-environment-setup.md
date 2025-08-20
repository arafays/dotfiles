# Mise Environment Integration

This setup ensures that mise-managed tools (like Node.js, Python, etc.) are available to GUI applications launched from the desktop environment, not just terminal applications.

## How it works

### 1. Shell Integration (`.zshrc`)
- Calls `mise activate zsh` to set up mise hooks in the shell
- Provides access to mise-managed tools in terminal sessions

### 2. System-wide Integration (`.profile` + `environment.d`)
- `.profile`: Exports mise shims directory for shell profiles
- `environment.d/10-mise.conf`: Configures systemd user session with mise shims path
- This ensures GUI applications launched from desktop can find mise tools

### 3. Automated Setup (`run_once_before_configure-mise-environment.sh`)
- Automatically runs when applying dotfiles with chezmoi
- Sets up systemd user environment with mise shims
- Ensures the setup works immediately without requiring logout/login

## Why use shims?

Mise shims are **static symlinks** in `~/.local/share/mise/shims/` that:
- ✅ Automatically update when you install new tools
- ✅ Work system-wide for all applications
- ✅ Don't require hardcoded version paths
- ✅ Persist across mise version changes

## Installation on new machine

1. Install mise: `curl https://mise.run | sh`
2. Apply dotfiles: `chezmoi apply`
3. Install your tools: `mise install`

The environment setup will be automatically configured!

## Verification

Check if it's working:
```bash
# Check shims are created
ls ~/.local/share/mise/shims/

# Check systemd user environment
systemctl --user show-environment | grep PATH

# Test shim directly
~/.local/share/mise/shims/node --version
```

## Troubleshooting

If GUI apps still can't find tools:
1. Restart your desktop session (logout/login)
2. Or manually update systemd environment:
   ```bash
   systemctl --user set-environment PATH="$HOME/.local/share/mise/shims:$PATH"
   systemctl --user import-environment PATH
   ```

## Benefits

- 🚀 **Zero configuration** on new machines
- 🔄 **Automatically updates** when installing new tools
- 🖥️ **Works with GUI apps** launched from desktop
- 📦 **No hardcoded versions** - everything is dynamic
- 🔧 **Proper Linux integration** using systemd user environment
