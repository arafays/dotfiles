[[ -f ~/.profile ]] && source ~/.profile

# STOW_DIR: Path to the directory containing dotfiles
export STOW_DIR="$HOME/dotfiles"

# Detect AUR wrapper
if pacman -Qi yay &>/dev/null; then
   aurhelper="yay"
elif pacman -Qi paru &>/dev/null; then
   aurhelper="paru"
fi

EDITOR="nvim"
SUDO_EDITOR="$EDITOR"
DIFFPROG="$EDITOR"

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CONFIG_DIR="${XDG_CONFIG_DIR:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DESKTOP_DIR="${XDG_DESKTOP_DIR:-$HOME/Desktop}"
export XDG_DOWNLOAD_DIR="${XDG_DOWNLOAD_DIR:-$HOME/Downloads}"
export XDG_TEMPLATES_DIR="${XDG_TEMPLATES_DIR:-$HOME/Templates}"
export XDG_PUBLICSHARE_DIR="${XDG_PUBLICSHARE_DIR:-$HOME/Public}"
export XDG_DOCUMENTS_DIR="${XDG_DOCUMENTS_DIR:-$HOME/Documents}"
export XDG_MUSIC_DIR="${XDG_MUSIC_DIR:-$HOME/Music}"
export XDG_PICTURES_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}"
export XDG_VIDEOS_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}"

# wget
WGETRC="${XDG_CONFIG_HOME}/wgetrc"
SCREENRC="$XDG_CONFIG_HOME"/screen/screenrc

# Application-specific settings that need to be available everywhere
export MANPAGER="sh -c 'col -bx | bat -l man -p --color always'"
export MANROFFOPT="-c"
export WGETRC="${XDG_CONFIG_HOME}/wgetrc"

export PARALLEL_HOME="$XDG_CONFIG_HOME"/parallel
export SCREENRC="$XDG_CONFIG_HOME"/screen/screenrc

export KEYTIMEOUT=1

export OS_FIREWALL="$(command -v ufw || command -v firewalld || command -v iptables || command -v nftables || command -v pfctl || echo "none")"

export WGPU_BACKEND=gl

export BAT_THEME="ansi"
export BAT_PAGER="less -RF"
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="--height 80%
  --layout=reverse
  --border
  --preview 'bat --color=always --style=numbers --line-range=:500 {}'
  --preview-window=right:60%
  --bind 'ctrl-/:change-preview-window(down|hidden|)'
  --color=bg+:#161616,bg:#000000,spinner:#08bdba,hl:#3ddbd9,fg:#f2f4f8,header:#3ddbd9,info:#08bdba,pointer:#08bdba,marker:#08bdba,fg+:#f2f4f8,prompt:#08bdba,hl+:#3ddbd9"

# History settings (these affect all shells)
export HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
export HISTSIZE=50000
export SAVEHIST=50000
export LESSHISTFILE=${LESSHISTFILE:-/tmp/less-hist}

# Basic shell options that should be set early
unsetopt BEEP
setopt AUTO_CD
setopt GLOB_DOTS
setopt NOMATCH
setopt MENU_COMPLETE
setopt EXTENDED_GLOB
setopt INTERACTIVE_COMMENTS
setopt APPEND_HISTORY
setopt BANG_HIST              # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY       # Write the history file in the ":start:elapsed;command" format.
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS       # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS   # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS      # Do not display a line previously found.
setopt HIST_IGNORE_SPACE      # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS      # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS     # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY            # Don't execute immediately upon history expansion.

