#!/bin/bash

set -euo pipefail # Exit on any error, on unset variables, and on pipe failures

# Check if running on an Arch-based distribution
if [ ! -f /etc/arch-release ]; then
    echo "This script is intended for Arch-based Linux distributions."
    echo "Please check the script and adapt it for your distribution."
    exit 1
fi

# Check if yay is installed
if ! command -v yay &> /dev/null; then
    echo "yay is not installed. Please install it first."
    echo "You can install it by running:"
    echo "git clone https://aur.archlinux.org/yay.git"
    echo "cd yay"
    echo "makepkg -si"
    exit 1
fi

echo "🚀 Installing essential development tools..."

# Essential CLI tools and utilities
echo "📦 Installing core packages..."
yay -S --needed \
  git \
  github-cli \
  stow \
  fzf \
  ripgrep \
  bat \
  zsh \
  zellij \
  starship \
  neovim \
  kitty \
  lazygit \
  eza \
  zoxide \
  fd \
  docker \
  docker-compose \
  wget \
  curl \
  less \
  man-db \
  parallel \
  screen \
  tmux \
  ffmpeg

echo "🔧 Installing development tools and runtime managers..."
# Development tools
yay -S --needed \
  mise-bin \
  visual-studio-code-bin \
  base-devel

echo "🌐 Installing optional browsers and applications..."
# Optional applications (comment out if not needed)
yay -S --needed \
  zen-browser-bin \
  firefox \
  chromium

echo "🎨 Installing fonts and themes..."
# Fonts for better terminal experience
yay -S --needed \
  ttf-fira-code \
  ttf-jetbrains-mono \
  noto-fonts \
  noto-fonts-emoji \
  ttf-font-awesome

echo "🔐 Installing security tools..."
# Security and system tools
yay -S --needed \
  gnupg \
  openssh \
  ufw

echo "📚 Installing additional development tools..."
# Additional useful tools
yay -S --needed \
  tree \
  htop \
  btop \
  ncdu \
  jq \
  yq \
  unzip \
  tar \
  gzip

echo "⚙️ Setting up runtime environments with mise..."
# Setup programming language runtimes
mise use -g node@latest
mise use -g lua@latest
mise use -g go@latest
mise use -g python@latest

echo "🐚 Configuring shell..."
# Change default shell to zsh if not already
if [[ "$SHELL" != */zsh ]]; then
  echo "Changing default shell to zsh..."
  chsh -s $(which zsh)
fi

echo "🔌 Installing useful cargo packages..."
# Install some useful Rust tools via cargo (after rust is installed)
if command -v cargo &> /dev/null; then
  cargo install \
    tokei \
    hyperfine \
    du-dust \
    procs \
    bandwhich || echo "Some cargo packages failed to install, continuing..."
fi

echo "🎉 Installation complete!"
echo ""
echo "📝 Next steps:"
echo "1. Restart your terminal or run: source ~/.zshrc"
echo "2. Run 'stow minimal' from your dotfiles directory to symlink configs"
echo "3. Configure Git: git config --global user.name 'Your Name'"
echo "4. Configure Git: git config --global user.email 'your.email@example.com'"
echo "5. Setup GitHub CLI: gh auth login"
echo "6. Configure Docker: sudo systemctl enable --now docker && sudo usermod -aG docker $USER"
echo ""
echo "🛡️ Security recommendations:"
echo "- Enable firewall: sudo ufw enable"
echo "- Setup SSH keys: ssh-keygen -t ed25519 -C 'your.email@example.com'"
