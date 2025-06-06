# STOW_DIR: Path to the directory containing dotfiles
STOW_DIR="$HOME/dotfiles"

# Detect AUR wrapper
if pacman -Qi yay &>/dev/null; then
   aurhelper="yay"
elif pacman -Qi paru &>/dev/null; then
   aurhelper="paru"
fi

if [[ -z "$aurhelper" ]]; then
  echo "No AUR helper detected. Some aliases may not work."
fi

function search {
  local -a searchPkg=("$@")
  local -a arch=()
  local -a aur=()

  for pkg in "${searchPkg[@]}"; do
      if pacman -Si "${pkg}" &>/dev/null; then
          arch+=("${pkg}")
      else
          aur+=("${pkg}")
      fi
    done

    if [[ ${#arch[@]} -gt 0 ]]; then
        sudo pacman -Ss "${arch[@]}"
    fi

    if [[ ${#aur[@]} -gt 0 ]]; then
        ${aurhelper} -Ss "${aur[@]}"
    fi
}

# Editor settings
EDITOR="nvim"
SUDO_EDITOR="$EDITOR"
DIFFPROG="$EDITOR"

# System settings
OS_FIREWALL="firewalld"

# XDG Base Directory Specification
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CONFIG_DIR="${XDG_CONFIG_DIR:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_DESKTOP_DIR="${XDG_DESKTOP_DIR:-$HOME/Desktop}"
XDG_DOWNLOAD_DIR="${XDG_DOWNLOAD_DIR:-$HOME/Downloads}"
XDG_TEMPLATES_DIR="${XDG_TEMPLATES_DIR:-$HOME/Templates}"
XDG_PUBLICSHARE_DIR="${XDG_PUBLICSHARE_DIR:-$HOME/Public}"
XDG_DOCUMENTS_DIR="${XDG_DOCUMENTS_DIR:-$HOME/Documents}"
XDG_MUSIC_DIR="${XDG_MUSIC_DIR:-$HOME/Music}"
XDG_PICTURES_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}"
XDG_VIDEOS_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}"

# Application-specific settings
LESSHISTFILE=${LESSHISTFILE:-/tmp/less-hist}
PARALLEL_HOME="$XDG_CONFIG_HOME"/parallel
MANPAGER="sh -c 'col -bx | bat -l man -p --color always'"
MANROFFOPT="-c"
WGETRC="${XDG_CONFIG_HOME}/wgetrc"
SCREENRC="$XDG_CONFIG_HOME"/screen/screenrc

# Export all variables
export XDG_CONFIG_HOME XDG_CONFIG_DIR XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME \
       XDG_DESKTOP_DIR XDG_DOWNLOAD_DIR XDG_TEMPLATES_DIR XDG_PUBLICSHARE_DIR \
       XDG_DOCUMENTS_DIR XDG_MUSIC_DIR XDG_PICTURES_DIR XDG_VIDEOS_DIR \
       STOW_DIR EDITOR SUDO_EDITOR OS_FIREWALL PARALLEL_HOME WGETRC SCREENRC \
       aurhelper MANPAGER MANROFFOPT LESSHISTFILE DIFFPROG

# Export PATH only once after all modifications
export PATH
