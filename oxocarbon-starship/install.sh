#!/bin/bash

# Install Starship prompt

# Check if Starship is already installed
if command -v starship &> /dev/null
then
    echo "Starship is already installed."
    exit 0
fi

# Download and install Starship
echo "Installing Starship..."
curl -sS https://starship.rs/install.sh | sh

# Add initialization to shell configuration
SHELL_CONFIG=""
if [ -n "$BASH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
elif [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -n "$FISH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.config/fish/config.fish"
elif [ -n "$POWERSHELL_VERSION" ]; then
    SHELL_CONFIG="$HOME/Documents/PowerShell/Microsoft.PowerShell_profile.ps1"
else
    echo "Unsupported shell. Please add the following line to your shell configuration manually:"
    echo "eval \"\$(starship init <your_shell>)\""
    exit 1
fi

# Add Starship initialization to the shell configuration
echo "Adding Starship initialization to $SHELL_CONFIG..."
echo 'eval "$(starship init bash)"' >> "$SHELL_CONFIG"

echo "Starship installation complete! Please restart your terminal or run 'source $SHELL_CONFIG' to apply the changes."