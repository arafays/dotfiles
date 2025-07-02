#!/bin/bash

set -euo pipefail # Exit on any error, on unset variables, and on pipe failures

alias in="yay -S --needed --noconfirm"

# --- DRY RUN IS DEFAULT ---
INSTALL=false
if [[ "${1:-}" == "--install" ]]; then
  INSTALL=true
  echo "[INSTALL] Will actually install packages."
else
  echo "[DRY RUN] Checking package availability only, no installation will be performed."
fi

# Check if running on an Arch-based distribution
if [ ! -f /etc/arch-release ]; then
  echo "This script is intended for Arch-based Linux distributions."
  echo "Please check the script and adapt it for your distribution."
  exit 1
fi

# Check if yay is installed
if ! command -v yay &>/dev/null; then
  echo "yay is not installed. Please install it first."
  echo "You can install it by running:"
  echo "git clone https://aur.archlinux.org/yay.git"
  echo "cd yay"
  echo "makepkg -si"
  exit 1
fi

if $INSTALL; then
  echo "🔄 First Updating system..."
  # Update the system and clean up
  yay -Syu --noconfirm
  yay -Rns $(yay -Qdtq) --noconfirm # Remove orphaned packages
fi

echo "🚀 Installing essential development tools..."

# Essential CLI tools and utilities
CORE_PACKAGES=(
  git github-cli stow fzf ripgrep bat zsh zellij starship neovim kitty lazygit eza zoxide fd docker docker-compose wget curl less man-db parallel screen tmux ffmpeg
)

# --- Color output helper ---
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to check package availability
check_packages() {
  local arr=("${@}")
  for pkg in "${arr[@]}"; do
    if yay -Si "$pkg" &>/dev/null; then
      echo -e "${GREEN}[OK] $pkg found${NC}"
    else
      echo -e "${RED}[MISSING] $pkg NOT found in repos/AUR${NC}"
    fi
  done
}

echo "📦 Installing core packages..."
if $INSTALL; then
  in "${CORE_PACKAGES[@]}"
else
  check_packages "${CORE_PACKAGES[@]}"
fi

DEV_PACKAGES=(visual-studio-code-bin base-devel)
echo "🔧 Installing development tools and runtime managers..."
if $INSTALL; then
  in "${DEV_PACKAGES[@]}"
else
  check_packages "${DEV_PACKAGES[@]}"
fi

BROWSER_PACKAGES=(zen-browser-bin firefox chromium)
echo "� Installing optional browsers and applications..."
if $INSTALL; then
  in "${BROWSER_PACKAGES[@]}"
else
  check_packages "${BROWSER_PACKAGES[@]}"
fi

FONT_PACKAGES=(ttf-fira-code ttf-jetbrains-mono noto-fonts noto-fonts-emoji ttf-font-awesome)
echo "🎨 Installing fonts and themes..."
if $INSTALL; then
  in "${FONT_PACKAGES[@]}"
else
  check_packages "${FONT_PACKAGES[@]}"
fi

SECURITY_PACKAGES=(gnupg openssh ufw)
echo "� Installing security tools..."
if $INSTALL; then
  in "${SECURITY_PACKAGES[@]}"
else
  check_packages "${SECURITY_PACKAGES[@]}"
fi

EXTRA_PACKAGES=(tree htop btop ncdu jq yq unzip tar gzip)
echo "📚 Installing additional development tools..."
if $INSTALL; then
  in "${EXTRA_PACKAGES[@]}"
else
  check_packages "${EXTRA_PACKAGES[@]}"
fi

# install mise if not already installed
if ! command -v mise &>/dev/null; then
  echo "Installing mise for runtime management..."
  curl https://mise.run | sh
fi

if $INSTALL; then
  echo "⚙️ Setting up runtime environments with mise..."
  # Setup programming language runtimes
  mise use -g node@latest lua@latest go@latest python@latest
fi

if $INSTALL; then
  echo "🐚 Configuring shell..."
  # Change default shell to zsh if not already
  if [[ "$SHELL" != */zsh ]]; then
    echo "Changing default shell to zsh..."
    chsh -s $(which zsh)
  fi
fi

if $INSTALL; then
  echo "🔌 Installing useful cargo packages..."
  # Install some useful Rust tools via cargo (after rust is installed)
  if command -v cargo &>/dev/null; then
    cargo install \
      tokei \
      hyperfine \
      du-dust \
      procs \
      bandwhich || echo "Some cargo packages failed to install, continuing..."
  fi
fi

if $INSTALL; then
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
else
  echo "[DRY RUN] Package check complete. No changes made."
fi
