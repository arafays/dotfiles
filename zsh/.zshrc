# Cache directory for command existence checks
typeset -A _cmd_cache
_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
_cache_file="$_cache_dir/cmd_cache"
[[ ! -d "$_cache_dir" ]] && mkdir -p "$_cache_dir"

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

# Performance monitoring
_perf_monitor() {
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

# AUR helper detection with caching
_detect_aur_helper() {
  if [[ -n "$aurhelper" ]]; then
    return # Already detected
  fi

  if _cmd_exists yay; then
    export aurhelper="yay"
  elif _cmd_exists paru; then
    export aurhelper="paru"
  fi
}

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

# Function to display a slow load warning for shell startup
function _slow_load_warning {
  local lock_file="/tmp/.arafay_slow_load_warning.lock"
  local load_time=$SECONDS

  # Check if the lock file exists
  if [[ ! -f $lock_file ]]; then
    # Create the lock file
    touch $lock_file

    # Display the warning if load time exceeds the limit
    time_limit=3
    if ((load_time > time_limit)); then
      cat <<EOF
    ⚠️ Warning: Shell startup took more than ${time_limit} seconds. Consider optimizing your configuration.
        1. This might be due to slow plugins or initialization scripts.
        2. Duplicate plugin initializations or conflicting configurations.
        3. Check for large files being sourced during startup.

    Possible solutions:
        - Review zinit plugin loading in your dotfiles
        - Check for redundant completions or aliases
        - Consider using zinit's turbo mode for non-critical plugins

    For more information or to contribute improvements:
        🌐 https://github.com/arafays/dotfiles

EOF
    fi
  fi
}

_init_plugins() {
  # Essential plugins (load immediately)
  zinit light zdharma-continuum/fast-syntax-highlighting

  # Deferred plugins (load after prompt is ready)
  zinit wait lucid for \
    atinit"zicompinit; zicdreplay" \
    zdharma-continuum/fast-syntax-highlighting \
    atload"_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions \
    blockf atpull'zinit creinstall -q .' \
    zsh-users/zsh-completions

  # Load after 1 second for non-essential plugins
  zinit wait'1' lucid for \
    MichaelAquilina/zsh-you-should-use

  completions=(
    [gh]='gh completion -s zsh'
    [zoxide]='zoxide init zsh'
    [mise]='mise activate zsh && mise completion zsh'
    [fzf]='fzf --zsh'
    ['warp-cli']='warp-cli generate-completions zsh'
    ['go-blueprint']='go-blueprint completion zsh'
    [pnpm]='pnpm completion zsh'
  )

  # for key value in ${(kv)completions}; do
  #     echo "$key -> $value"
  # done

  # FZF integration
  if _cmd_exists fzf; then
    zinit wait'1' lucid for Aloxaf/fzf-tab
  else
    echo "fzf not found. Install it? (y/n)"
    read -r response
    if [[ "$response" == "y" ]]; then
      if _cmd_exists aurhelper; then
        $aurhelper -S fzf
      else
        echo "No AUR helper found. Please install fzf-tab manually."
        exit 1
      fi
    fi
  fi

  # Directory jumping
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
    eval "$(mise activate zsh)"
  else
    echo "mise not found. Install it? (y/n)"
    read -r response
    if [[ "$response" == "y" ]]; then
      if _cmd_exists aurhelper; then
        $aurhelper -S mise
      else
        echo "No AUR helper found. Please install mise manually."
        exit 1
      fi
    fi
  fi

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
_detect_aur_helper
_setup_vi_mode
_define_functions

# Load zsh hooks module once
autoload -Uz add-zsh-hook

# Warn if the shell is slow to load
add-zsh-hook -Uz precmd _set_terminal_title
add-zsh-hook -Uz precmd _slow_load_warning
_init_zinit
_init_starship

# Initialize completions early to avoid compdef errors
autoload -Uz compinit
compinit

# echo starttime
echo

_init_plugins
_load_aliases
