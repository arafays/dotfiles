# zmodload zsh/zprof

export BAT_THEME="ansi"
export BAT_PAGER="less -RF"
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="
  --height 80%
  --layout=reverse
  --border
  --preview 'bat --color=always --style=numbers --line-range=:500 {}'
  --preview-window=right:60%
  --bind 'ctrl-/:change-preview-window(down|hidden|)'
  --color=bg+:#161616,bg:#000000,spinner:#08bdba,hl:#3ddbd9,fg:#f2f4f8,header:#3ddbd9,info:#08bdba,pointer:#08bdba,marker:#08bdba,fg+:#f2f4f8,prompt:#08bdba,hl+:#3ddbd9"

# Performance tracking
_start_time=$SECONDS

typeset -A _cmd_cache
_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
_cache_file="$_cache_dir/cmd_cache"
[[ ! -d "$_cache_dir" ]] && mkdir -p "$_cache_dir"

# Fast command existence check with persistent caching
_cmd_exists() {
  local cmd="$1"
  if [[ -z "${_cmd_cache[$cmd]}" ]]; then
    if command -v "$cmd" &>/dev/null; then
      _cmd_cache[$cmd]=1
    else
      _cmd_cache[$cmd]=0
    fi
    # Save cache after update
    echo "_cmd_cache[$cmd]=${_cmd_cache[$cmd]}" >>"$_cache_file"
  fi
  return $((1 - _cmd_cache[$cmd]))
}

# Load cached command results
[[ -f "$_cache_file" ]] && source "$_cache_file"

# Terminal title
_set_terminal_title() {
  local git_branch=""
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    git_branch=" ($(git branch --show-current 2>/dev/null))"
  fi
  print -Pn "\e]0;%~$git_branch\a"
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

# AUR helper detection (cached)
_detect_aur_helper() {
  [[ -n "$aurhelper" ]] && return
  for helper in yay paru; do
    if _cmd_exists "$helper"; then
      export aurhelper="$helper"
      break
    fi
  done
}

# Install tool from AUR
_install_tool() {
  local tool="$1"
  local aur_package="$2"

  if [[ -z "$aurhelper" ]]; then
    echo "No AUR helper found. Please install $tool manually."
    return 1
  fi

  echo "Installing $tool using $aurhelper..."
  if $aurhelper -S "$aur_package"; then
    # Clear cache for this tool
    unset "_cmd_cache[$tool]"
    return 0
  else
    echo "Failed to install $tool"
    return 1
  fi
}

_setup_vi_mode() {
  bindkey -v
  export KEYTIMEOUT=1

  # Better vi mode cursor
  zle-keymap-select() {
    case $KEYMAP in
    vicmd) echo -ne '\e[1 q' ;;        # Block cursor
    viins | main) echo -ne '\e[5 q' ;; # Beam cursor
    esac
  }
  zle -N zle-keymap-select

  zle-line-init() {
    zle -K viins
    echo -ne "\e[5 q"
  }
  zle -N zle-line-init

  # Better vi mode bindings
  # Ensure fzf-history-widget is defined
  if [[ -n "$(command -v fzf)" ]]; then
    fzf-history-widget() {
      local selected=$(fc -rl 1 | fzf --height 40% --layout=reverse --border --preview 'echo {}' --preview-window=up:3:wrap)
      if [[ -n "$selected" ]]; then
        BUFFER="$selected"
        CURSOR=${#BUFFER}
      fi
    }
    zle -N fzf-history-widget
    bindkey '^R' fzf-history-widget
  fi
  bindkey '^P' up-history
  bindkey '^N' down-history
  bindkey '^A' beginning-of-line
  bindkey '^E' end-of-line
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
  # Show system info only in interactive shells
  if [[ $- == *i* ]] && [[ -z "$TMUX" ]]; then
    for cmd in pokego pokemon-colorscripts fastfetch; do
      if _cmd_exists "$cmd"; then
        case "$cmd" in
        pokego | pokemon-colorscripts)
          "$cmd" --no-title -r 2>/dev/null
          ;;
        fastfetch)
          "$cmd" --logo-type small 2>/dev/null
          ;;
        esac
        break
      fi
    done
  fi

  if _cmd_exists starship; then
    eval "$(starship init zsh)"
    export STARSHIP_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/starship"
    export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship/starship.toml"
  else
    echo "Starship not found. Install it? (y/n)"
    read -r response
    if [[ "$response" == "y" ]]; then
      curl -fsSL https://starship.rs/install.sh | sh -s -- --yes
      eval "$(starship init zsh)"
      export STARSHIP_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/starship"
      export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship/starship.toml"
    fi
  fi
}

_setup_essential_tools() {
  local tools=("git" "nvim" "mise" "gh" "docker" "zoxide" "fd" "bat" "rg" "fzf" "eza")
  local packages=("git" "neovim" "mise-bin" "github-cli" "docker" "zoxide" "fd-find" "bat" "ripgrep" "fzf" "eza")
  local completions=(
    "git"
    "skip"
    "mise activate zsh"
    "gh completion -s zsh && gh copilot alias zsh"
    "docker completion zsh"
    "zoxide init zsh"
    "fd --gen-completions zsh"
    "bat --completion zsh"
    "rg --generate=complete-zsh"
    "fzf --zsh"
    "skip"
  )

  for i in {1..${#tools[@]}}; do
    local tool="${tools[$i]}"
    local package="${packages[$i]}"
    local completion_cmd="${completions[$i]}"

    if _cmd_exists "$tool"; then
      _load_completion "$tool" "$completion_cmd" "0"
    else
      echo "$tool not found. Install it? (y/n)"
      read -r response
      if [[ "$response" == "y" ]]; then
        if _install_tool "$tool" "$package"; then
          _load_completion "$tool" "$completion_cmd" "2"
        fi
      fi
    fi
  done
}

_setup_optional_tools() {
  local tools=("warp-cli")
  local packages=("warp-cli")
  local completions=(
    "warp-cli generate-completions zsh"
  )

  for i in {1..${#tools[@]}}; do
    local tool="${tools[$i]}"
    local package="${packages[$i]}"
    local completion_cmd="${completions[$i]}"

    if _cmd_exists "$tool"; then
      _load_completion "$tool" "$completion_cmd" "1"
    fi
  done
}

_init_plugins() {
  # Core plugins loaded immediately
  zinit wait lucid light-mode for \
    atinit"zicompinit; zicdreplay" \
    zdharma-continuum/fast-syntax-highlighting \
    atload"_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions \
    blockf atpull'zinit creinstall -q .' \
    zsh-users/zsh-completions

  # Load after 1 second for non-essential plugins
  zinit wait'1' lucid for \
    MichaelAquilina/zsh-you-should-use \
    Aloxaf/fzf-tab

  # Setup tool completions
  _setup_essential_tools
  _setup_optional_tools
}

_load_aliases() {
  # if zoxide exists replace cd

  _cmd_exists fzf && alias fzf='fzf --height 40% --layout=reverse --border'
  _cmd_exists fzf && alias ff='fzf --preview "bat --style=numbers --color=always {}"'
  _cmd_exists fd && alias find='fd'
  _cmd_exists fd && alias f='fd --type f --hidden --follow --exclude .git'

  _cmd_exists rg && alias grep='rg --color=auto --line-number --smart-case  --hidden --glob "!.git"'

  _cmd_exists bat && alias cat='bat --paging=never'
  _cmd_exists bat && alias less='bat --paging=always --style=plain --color=always'

  _cmd_exists zoxide && alias cd='z'

  # Eza aliases (enhanced ls)
  if _cmd_exists eza; then
    alias ls='eza -lh --icons=auto --group-directories-first'
    alias ll='eza -lha --icons=auto --sort=name --group-directories-first'
    alias l='eza -lh --icons=auto'
    alias la='eza -lha --icons=auto'
    alias ld='eza -lhD --icons=auto'
    alias lt='eza --icons=auto --tree --level=2'
    alias lta='eza --icons=auto --tree --level=3 --all'
    export EZA_COLORS="da=36:di=34:ex=32:fi=0:ln=35:pi=33:so=31"
  fi

  # Package management
  if [[ -n "$aurhelper" ]]; then
    alias in="$aurhelper -S"
    alias un="$aurhelper -Rns"
    alias up="$aurhelper -Syu"
    alias pl="$aurhelper -Qs"
    alias pa="$aurhelper -Ss"
    alias pc="$aurhelper -Sc"
    alias po="$aurhelper -Qtdq | $aurhelper -Rns -"
    alias pi="$aurhelper -Si" # Package info
    alias orphans="$aurhelper -Qtdq"
  fi

  # Navigation
  alias ..='cd ..'
  alias ...='cd ../..'
  alias .3='cd ../../..'
  alias .4='cd ../../../..'
  alias .5='cd ../../../../..'
  alias -- -='cd -'

  # Utils
  alias mkdir='mkdir -p'
  alias cp='cp -i'
  alias mv='mv -i'
  alias rm='rm -i'
  alias df='df -h'
  alias du='du -h'
  alias free='free -h'
  alias vim='nvim'
  alias vi='nvim'
  alias n='nvim'
  alias dev='code .'
}

# Lazy function definitions
_define_functions() {
  # Fuzzy directory navigation
  fcd() {
    local dir
    dir=$(find . -maxdepth 5 \( -name .git -o -name node_modules -o -name .next -o -name dist \) -prune -o -type d -print 2>/dev/null |
      fzf --height=40% --layout=reverse --preview='eza -la --icons=auto {}' --preview-window=right:60%) &&
      cd "$dir"
  }

  # Fuzzy file edit
  fe() {
    local file
    file=$(fzf --preview='bat --color=always --style=numbers --line-range=:500 {}' --preview-window=right:60%) &&
      ${EDITOR:-nvim} "$file"
  }

  # Enhanced package install
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

  # Quick compression
  compress() {
    case "$1" in
    *.tar.gz | *.tgz) tar -czf "$1" "${@:2}" ;;
    *.tar.bz2 | *.tbz2) tar -cjf "$1" "${@:2}" ;;
    *.zip) zip -r "$1" "${@:2}" ;;
    *) echo "Unsupported format. Use .tar.gz, .tar.bz2, or .zip" ;;
    esac
  }

  # Extract function
  extract() {
    if [[ -f "$1" ]]; then
      case "$1" in
      *.tar.bz2) tar xjf "$1" ;;
      *.tar.gz) tar xzf "$1" ;;
      *.bz2) bunzip2 "$1" ;;
      *.rar) unrar x "$1" ;;
      *.gz) gunzip "$1" ;;
      *.tar) tar xf "$1" ;;
      *.tbz2) tar xjf "$1" ;;
      *.tgz) tar xzf "$1" ;;
      *.zip) unzip "$1" ;;
      *.Z) uncompress "$1" ;;
      *.7z) 7z x "$1" ;;
      *) echo "'$1' cannot be extracted" ;;
      esac
    else
      echo "'$1' is not a valid file"
    fi
  }

  # Video conversion
  webm2mp4() {
    local input="$1" output="${1%.webm}.mp4"
    ffmpeg -i "$input" -c:v libx264 -preset medium -crf 23 -c:a aac -b:a 192k "$output"
  }

  # Create and enter directory
  mkcd() {
    mkdir -p "$1" && cd "$1"
  }

  # Process management
  ps_grep() {
    ps aux | grep -v grep | grep -i "$1"
  }

  # Enhanced tmux session management
  tn() {
    local session_name="${1:-$(basename "$PWD")}"
    # Clean session name (replace dots and special chars with underscores)
    session_name="${session_name//[^a-zA-Z0-9_-]/_}"
    tmux new-session -A -s "$session_name" -c "$PWD"
  }

  # Tmux session switcher with fzf (if available)
  ts() {
    if _cmd_exists fzf; then
      local session
      session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --height=60% --layout=reverse --prompt="Switch to session: ") &&
        tmux switch-client -t "$session" 2>/dev/null || tmux attach-session -t "$session"
    else
      tmux list-sessions
    fi
  }

  # Kill tmux session
  tk() {
    if [[ -n "$1" ]]; then
      tmux kill-session -t "$1"
    elif _cmd_exists fzf; then
      local session
      session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --height=60% --layout=reverse --prompt="Kill session: ") &&
        tmux kill-session -t "$session"
    else
      echo "Usage: tk <session_name>"
    fi
  }

  # List tmux sessions
  tl() {
    tmux list-sessions
  }
}

# Optimized version that checks if plugins are already loaded
_mise_chpwd_hook_optimized() {
  # Check if mise is available and we have mise config files
  if _cmd_exists mise && [[ -f .mise.toml || -f .tool-versions || -f mise.toml ]]; then

    # Track loaded completions to avoid duplicates
    local -A loaded_completions

    # # Parse the output of `zinit completions` and build completion status
    # while IFS= read -r line; do
    #   # Skip progress and empty lines
    #   [[ $line =~ ^[0-9]+\.[0-9]+%\ *$ || -z $line ]] && continue

    #   # Split into tools and source
    #   local source tools_str
    #   tools_str=$(echo "$line" | awk -F'[[:space:]]+[^[:space:]]+$' '{print $1}')
    #   source=$(echo "$line" | awk '{print $NF}')

    #   # Process comma-separated tools
    #   echo "$tools_str" | tr ',' '\n' | while read -r tool; do
    #     # Clean up tool name
    #     tool=${tool## }    # Remove leading spaces
    #     tool=${tool%% }    # Remove trailing spaces
    #     [[ -z $tool ]] && continue

    #     # Store both the completion status and its source
    #     loaded_completions[$tool]=$source
    #   done
    # done < <(zinit completions)

    # # Debug: Print loaded completions
    # echo "Loaded completions:"
    # for tool in ${(k)loaded_completions}; do
    #   echo "$tool -> ${loaded_completions[$tool]}"
    # done

    # Load pnpm completion and plugin if not already loaded
    if _cmd_exists pnpm; then
      if [[ -z ${loaded_completions['pnpm']} ]]; then
        zinit id-as"pnpm-completion" wait lucid for \
          atload"pnpm completion zsh" \
          zdharma-continuum/null
      fi

      if [[ -z ${loaded_completions['ntnyq/omz-plugin-pnpm']} ]]; then
        zinit wait lucid for ntnyq/omz-plugin-pnpm
      fi
    fi

    # Load bun completion if not already loaded
    if _cmd_exists bun; then
      if [[ -z ${loaded_completions['bun']} ]]; then
        zinit id-as"bun-completion" wait lucid for \
          atload"bun completions" \
          zdharma-continuum/null
      fi
    fi

  fi
}

_load_completion() {
  local tool="$1"
  local completion_cmd="$2"
  local delay="${3:-2}"

  # Skip if tool doesn't exist
  if ! _cmd_exists "$tool"; then
    return
  fi
  if [[ -z "$completion_cmd" || "$completion_cmd" == "skip" ]]; then
    return
  fi

  # Use Zinit's built-in completion management
  case "$tool" in
  git)
    zinit ice blockf
    zinit light zsh-users/zsh-completions
    ;;
  docker)
    zinit ice blockf
    zinit light zsh-users/zsh-completions
    ;;
  bat)
    # TODO: implement a more robust way to handle bat completions
    ;;
  rg)
    # TODO: implement a more robust way to handle ripgrep completions
    ;;
  *)
    # For other tools, use their native completion if available
    if [[ -n "$completion_cmd" ]]; then
      zinit wait"$delay" lucid for \
        atload"eval \"\$($completion_cmd)\"" \
        zdharma-continuum/null
    fi
    ;;
  esac
}

# Initialize components
_detect_terminal
_detect_aur_helper
_setup_vi_mode
_init_zinit
_init_starship
autoload -Uz add-zsh-hook
add-zsh-hook precmd _set_terminal_title
add-zsh-hook chpwd _mise_chpwd_hook_optimized
autoload -Uz compinit && compinit

# Load functions and aliases
_define_functions
_load_aliases
_init_plugins

_mise_chpwd_hook_optimized

# Performance warning
_end_time=$SECONDS
_load_time=$((_end_time - _start_time))
if ((_load_time > 3)); then
  echo "⚠️  Shell startup took ${_load_time}s. Consider optimizing further."
fi

# Cleanup
unset _start_time _end_time _load_time

# zprof
export PATH
