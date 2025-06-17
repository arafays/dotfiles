zmodload zsh/zprof

# Cache directory for command existence checks
typeset -A _cmd_cache
_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
_cache_file="$_cache_dir/cmd_cache"
[[ ! -d "$_cache_dir" ]] && mkdir -p "$_cache_dir"
if [[ -f "$_cache_file" ]]; then
  source "$_cache_file"
else
  mkdir -p "$_cache_dir"
fi
# Define config directory
local zsh_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

# Fast command existence check with caching
_cmd_exists() {
  local cmd="$1"
  if [[ -z "${_cmd_cache[$cmd]}" ]]; then
    if command -v "$cmd" &>/dev/null; then
      _cmd_cache[$cmd]=1
    else
      _cmd_cache[$cmd]=0
    fi
    # Save the cache after each update
  fi
  return $((1 - _cmd_cache[$cmd]))
}

# Load cached command results if available
[[ -f "$_cache_file" ]] && source "$_cache_file"

# Terminal title
_set_terminal_title() {
  print -Pn "\e]0;%~\a"
}

# Performance monitoring using zinit
_perf_monitor() {

  # Load zinit for performance monitoring
  zinit light zsh-users/zsh-zprof
  zprof
  local start_time=$SECONDS
  if ((start_time > 2)); then
    echo "⚠️  Shell startup took ${start_time}s. Consider optimizing further."
  fi
}

# Terminal detection (only run once)
_detect_terminal() {
  if [[ -n "$COLORTERM" ]]; then
    return # Already set
  fi

  if [[ "$TERM_PROGRAM" == "alacritty" || "$TERMINAL" == *"alacritty"* || "$TERMINAL_EMULATOR" == *"alacritty"* ]]; then
    export TERM=alacritty
    # Alacritty supports true color
    export COLORTERM=truecolor
  elif [[ "$TERM_PROGRAM" == "kitty" || "$TERMINAL" == *"kitty"* || "$TERMINAL_EMULATOR" == *"kitty"* ]]; then
    export TERM=xterm-kitty
    # Kitty supports true color
    export COLORTERM=truecolor
  fi
}
_detect_terminal

_detect_aur_helper() {
  [[ -n "$aurhelper" ]] && return
  for helper in yay paru; do
    if _cmd_exists "$helper"; then
      export aurhelper="$helper"
      break
    fi
  done
}
_detect_aur_helper

# Vi mode configuration
_setup_vi_mode() {
  bindkey -v
  export KEYTIMEOUT=1

  # Cursor shape for vi modes
  zle-keymap-select() {
    case $KEYMAP in
    vicmd) echo -ne '\e[1 q' ;;
    viins | main) echo -ne '\e[5 q' ;;
    esac
  }
  zle -N zle-keymap-select

  zle-line-init() {
    zle -K viins
    echo -ne "\e[5 q"
  }
  zle -N zle-line-init
}

# Initialize Zinit (lazy loading)
_init_zinit() {
  local zinit_dir="$HOME/.local/share/zinit/zinit.git"

  if [[ ! -f "$zinit_dir/zinit.zsh" ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" &&
      print -P "%F{33} %F{34}Installation successful.%f%b" ||
      print -P "%F{160} The clone has failed.%f%b"
  fi

  source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
  autoload -Uz _zinit
  ((${#_comps[@]} > 0)) && _comps[zinit]=_zinit
}

_init_starship() {
  if [[ $- == *i* ]]; then
    # This is a good place to load graphic/ascii art, display system information, etc.
    if command -v pokego >/dev/null; then
      pokego --no-title -r 1,3,6
    elif command -v pokemon-colorscripts >/dev/null; then
      pokemon-colorscripts --no-title -r 1,3,6
    elif command -v fastfetch >/dev/null; then
      if do_render "image"; then
        fastfetch --logo-type kitty
      fi
    fi
  fi

  if ! _cmd_exists starship; then
    echo "Starship not found. Install it? (y/n)"
    read -r response
    if [[ "$response" == "y" ]]; then
      curl -fsSL https://starship.rs/install.sh | sh -s -- --yes
    fi
  else
    # ===== START Initialize Starship prompt =====
    eval "$(starship init zsh)"
    export STARSHIP_CACHE=$XDG_CACHE_HOME/starship
    export STARSHIP_CONFIG=$XDG_CONFIG_HOME/starship/starship.toml
  fi
}

_slow_load_warning() {
  local lock_file="/tmp/.arafay_slow_load_warning.lock"
  if [[ ! -f $lock_file ]]; then
    touch $lock_file
    if ((SECONDS > 3)); then
      echo "⚠️ Shell startup took more than 3 seconds. Consider optimizing your configuration."
    fi
  fi
}

_init_plugins() {

  # Deferred plugins (load after prompt is ready)
  zinit wait lucid light-mode for \
    atinit"zicompinit; zicdreplay" \
    zdharma-continuum/fast-syntax-highlighting \
    atload"_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions \
    blockf atpull'zinit creinstall -q .' \
    zsh-users/zsh-completions

  # Load after 1 second for non-essential plugins
  zinit wait'1' lucid for \
    MichaelAquilina/zsh-you-should-use
}

_load_aliases() {
  # if zoxide exists replace cd
  _cmd_exists zoxide && alias cd='z'

  _cmd_exists fzf && alias fzf='fzf --height 40% --layout=reverse --border'

  _cmd_exists fzf && alias ff='fzf --preview "bat --style=numbers --color=always {}"'

  _cmd_exists rg && alias grep='rg --color=auto --line-number --smart-case'

  # Tool-specific exports
  if _cmd_exists eza; then
    alias ls='eza -lh --icons=auto --group-directories-first' \
      ll='eza -lha --icons=auto --sort=name --group-directories-first' \
      l='eza -lh --icons=auto' \
      la='eza -lha --icons=auto' \
      ld='eza -lhD --icons=auto' \
      lt='eza --icons=auto --tree'
    export EZA_COLORS="da=36:di=34:ex=32:fi=0:ln=35:pi=33:so=31"
  fi

  if [[ -n "$aurhelper" ]]; then
    alias in='$aurhelper -S' \
      un='$aurhelper -Rns' \
      up='$aurhelper -Syu' \
      pl='$aurhelper -Qs' \
      pa='$aurhelper -Ss' \
      pc='$aurhelper -Sc' \
      po='$aurhelper -Qtdq | $aurhelper -Rns -'
  fi

  # Navigation shortcuts
  alias ..='cd ..' \
    ...='cd ../..' \
    .3='cd ../../..' \
    .4='cd ../../../..' \
    .5='cd ../../../../..'

  alias cat='bat' \
    cd='z' \
    mkdir='mkdir -p' \
    rg='rg --hidden --glob "!.git"' \
    fd='fdfind'

}

# Lazy function definitions
_define_functions() {
  # Fuzzy directory change
  fcd() {
    local dir
    dir=$(find . -maxdepth 5 \( -name .git -o -name node_modules \) -prune -o -type d -print 2>/dev/null |
      fzf --height=40% --layout=reverse --preview='ls -la {}' --preview-window=right:60%) &&
      cd "$dir"
  }

  # Fuzzy file search and edit
  fe() {
    local file
    file=$(fzf --preview='bat --color=always {}' --preview-window=right:60%) &&
      ${EDITOR:-vim} "$file"
  }

  # Enhanced package management
  in() {
    _detect_aur_helper
    local -a arch=() aur=()

    for pkg in "$@"; do
      if pacman -Si "$pkg" &>/dev/null; then
        arch+=("$pkg")
      else
        aur+=("$pkg")
      fi
    done

    ((${#arch[@]})) && sudo pacman -S "${arch[@]}"
    ((${#aur[@]})) && [[ -n "$aurhelper" ]] && "$aurhelper" -S "${aur[@]}"
  }

  # File compression
  compress() { tar -czf "${1%/}.tar.gz" "${1%/}"; }

  # Video conversion
  webm2mp4() {
    local input="$1" output="${1%.webm}.mp4"
    ffmpeg -i "$input" -c:v libx264 -preset slow -crf 22 -c:a aac -b:a 192k "$output"
  }
}

export BAT_THEME="ansi"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"

# Initialize everything
_setup_vi_mode

# Load zsh hooks module once
autoload -Uz add-zsh-hook

# Warn if the shell is slow to load
add-zsh-hook -Uz precmd _set_terminal_title
add-zsh-hook -Uz precmd _slow_load_warning
_init_zinit
_init_starship
autoload -Uz compinit && compinit

_define_functions

if _cmd_exists zoxide; then
  eval "$(zoxide init zsh)"
else
  echo "zsh zoxide not found. Install it? (y/n)"
  read -r response
  if [[ "$response" == "y" ]]; then
    if _cmd_exists aurhelper; then
      $aurhelper -S zoxide
    else
      echo "No AUR helper found. Please install zoxide manually."
      exit 1
    fi
  fi
fi

if _cmd_exists mise; then
  eval "$(mise activate zsh && mise completion zsh)"
else
  echo "mise not found. Install it? (y/n)"
  read -r response
  if [[ "$response" == "y" ]]; then
    if _cmd_exists aurhelper; then
      $aurhelper -S mise-bin
      eval "$(mise activate zsh && mise completion zsh)"
    else
      echo "No AUR helper found. Please install mise manually."
      exit 1
    fi
  fi
fi
if _cmd_exists fzf; then
  eval "$(fzf --zsh)"
  zinit wait'1' lucid for Aloxaf/fzf-tab
else
  echo "fzf not found. Install it? (y/n)"
  read -r response
  if [[ "$response" == "y" ]]; then
    if _cmd_exists aurhelper; then
      $aurhelper -S fzf
      autoload -Uz fzf-tab
      zinit wait'1' lucid for Aloxaf/fzf-tab
    else
      echo "No AUR helper found. Please install fzf-tab manually."
      exit 1
    fi
  fi
fi
_load_aliases

_init_plugins

if _cmd_exists gh; then
  eval "$(gh completion -s zsh)"
fi

if _cmd_exists warp-cli; then
  eval "$(warp-cli generate-completions zsh)"
fi

if _cmd_exists go-blueprint; then
  eval "$(go-blueprint completion zsh)"
fi

if _cmd_exists pnpm; then
  eval "$(pnpm completion zsh)"
fi
zprof
