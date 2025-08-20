#!/bin/bash

# Configure mise environment for systemd user session
# This script runs once when chezmoi applies dotfiles to ensure
# GUI applications can find mise-managed tools

set -e

echo "🔧 Configuring mise environment for systemd user session..."

# Check if mise is installed
if ! command -v mise &> /dev/null; then
    echo "⚠️  mise not found. Please install mise first."
    echo "   You can install it with: curl https://mise.run | sh"
    exit 1
fi

# Ensure mise shims directory exists
MISE_SHIMS_DIR="$HOME/.local/share/mise/shims"
if [ ! -d "$MISE_SHIMS_DIR" ]; then
    echo "📁 Creating mise shims directory..."
    mkdir -p "$MISE_SHIMS_DIR"
fi

# Configure systemd user environment with mise shims
echo "🔄 Setting up systemd user environment..."

# Set PATH to include mise shims for current session
systemctl --user set-environment PATH="$HOME/.local/share/mise/shims:$PATH"

# Import PATH environment variable
systemctl --user import-environment PATH

echo "✅ Mise environment configured successfully!"
echo "   GUI applications will now be able to find mise-managed tools."
echo ""
echo "💡 Note: If you install new tools with mise, they will be automatically"
echo "   available system-wide through shims without additional configuration."
