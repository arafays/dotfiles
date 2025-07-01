# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.

# Add ~/.local/bin and mise shims to PATH for all applications
export PATH="$HOME/.local/bin:$PATH"

# Ensure DISPLAY is properly set for X11 applications
# Only set if not already properly configured
if [ -z "$DISPLAY" ] || { [ "$DISPLAY" != ":0" ] && [ "$DISPLAY" != ":0.0" ]; }; then
  # Check if X11 is running
  if [ "$XDG_SESSION_TYPE" = "x11" ] || pgrep -x "Xorg" >/dev/null 2>&1; then
    export DISPLAY=":0"
  fi
fi

# Environment variables that should be available to all applications
# STOW_DIR: Path to the directory containing dotfiles
export STOW_DIR="$HOME/dotfiles"

# Detect AUR wrapper
if command -v yay &>/dev/null; then
   export aurhelper="yay"
elif command -v paru &>/dev/null; then
   export aurhelper="paru"
fi

# Set editor
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
export DIFFPROG="$EDITOR"

# XDG Base Directory Specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CONFIG_DIR="${XDG_CONFIG_DIR:-$HOME/.config}" # Non-standard, but used by some apps
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# XDG User Directories
export XDG_DESKTOP_DIR="${XDG_DESKTOP_DIR:-$HOME/Desktop}"
export XDG_DOWNLOAD_DIR="${XDG_DOWNLOAD_DIR:-$HOME/Downloads}"
export XDG_TEMPLATES_DIR="${XDG_TEMPLATES_DIR:-$HOME/Templates}"
export XDG_PUBLICSHARE_DIR="${XDG_PUBLICSHARE_DIR:-$HOME/Public}"
export XDG_DOCUMENTS_DIR="${XDG_DOCUMENTS_DIR:-$HOME/Documents}"
export XDG_MUSIC_DIR="${XDG_MUSIC_DIR:-$HOME/Music}"
export XDG_PICTURES_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}"
export XDG_VIDEOS_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}"

# Application-specific settings
export MANPAGER="sh -c 'col -bx | bat -l man -p --color always'"
export MANROFFOPT="-c"
export WGETRC="${XDG_CONFIG_HOME}/wgetrc"
export PARALLEL_HOME="$XDG_CONFIG_HOME"/parallel
export SCREENRC="$XDG_CONFIG_HOME"/screen/screenrc
export WGPU_BACKEND=gl
export BAT_THEME="ansi"
export BAT_PAGER="less -RF"
export OS_FIREWALL="$(command -v ufw || command -v firewalld || command -v iptables || command -v nftables || command -v pfctl || echo "none")"

# FZF configuration
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="--height 80% \
  --layout=reverse \
  --border \
  --preview 'bat --color=always --style=numbers --line-range=:500 {}' \
  --preview-window=right:60% \
  --bind 'ctrl-/:change-preview-window(down|hidden|)' "