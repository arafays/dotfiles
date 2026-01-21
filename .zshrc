# zmodload zsh/zprof

# gh api --method PATCH -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" /gists/3beb86f3b33e396654b1cf1799c923f9 -f "files[.zshrc][content]=$(cat ~/.zshrc)"

# Performance tracking
_start_time=$SECONDS

# Basic shell options
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

# GPG configuration
export GPG_TTY=$(tty)

# Android SDK configuration
export ANDROID_HOME=$HOME/Android/Sdk
export ANDROID_AVD_HOME=$HOME/.config/.android/avd
export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/build-tools/35.0.0
export ANDROID_EMULATOR_USE_SYSTEM_LIBS=1  

typeset -A _cmd_cache
_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
_cache_file="$_cache_dir/cmd_cache"
[[ ! -d "$_cache_dir" ]] && mkdir -p "$_cache_dir"

# Load cached command results
[[ -f "$_cache_file" ]] && source "$_cache_file"

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

# Terminal title
_set_terminal_title() {
  local git_branch=""
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    git_branch=" ($(git branch --show-current 2>/dev/null))"
  fi

  # Use printf for cross-shell compatibility
  if [[ -n "$ZSH_VERSION" ]]; then
    # zsh: use prompt expansion with trailing slash for home
    local zsh_path="%~"
    if [[ "$PWD" == "$HOME" ]]; then
      zsh_path="~/"
    fi
    print -Pn "\e]0;${zsh_path}$git_branch\a"
  else
    # bash: use $PWD and manual tilde expansion with trailing slash for home
    local pwd_display="${PWD/#$HOME/~}"
    if [[ "$pwd_display" == "~" ]]; then
      pwd_display="~/"
    fi
    printf '\e]0;%s%s\a' "$pwd_display" "$git_branch"
  fi
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
  # ---------------------------------------------------------
  # CORE CONFIGURATION
  # ---------------------------------------------------------
  
  # Enable Vi mode in the shell
  bindkey -v

  # Reduce delay when hitting 'Esc' to 0.1s (makes mode switching feel instant)
  export KEYTIMEOUT=1

  # Load widgets for searching history based on what you've already typed
  autoload -U up-line-or-beginning-search
  autoload -U down-line-or-beginning-search
  zle -N up-line-or-beginning-search
  zle -N down-line-or-beginning-search

  # ---------------------------------------------------------
  # CURSOR & VISUALS (Alacritty/Xterm)
  # ---------------------------------------------------------

  # Changes cursor shape when switching between Insert and Normal mode
  zle-keymap-select() {
    case $KEYMAP in
      vicmd) echo -ne '\e[1 q' ;;      # Block cursor for NORMAL mode
      viins | main) echo -ne '\e[5 q' ;; # Beam cursor for INSERT mode
    esac
  }
  zle -N zle-keymap-select

  # Ensure the cursor resets to a Beam whenever a new prompt line starts
  zle-line-init() {
    zle -K viins
    echo -ne "\e[5 q"
  }
  zle -N zle-line-init

  # ---------------------------------------------------------
  # FZF INTEGRATION
  # ---------------------------------------------------------

  # Fuzzy search history using fzf (if installed)
  if [[ -n "$(command -v fzf)" ]]; then
    fzf-history-widget() {
      # history -n 1 removes the line numbers so they don't get pasted in
      local selected=$(history -n 1 | fzf --height 40% --layout=reverse --border)
      if [[ -n "$selected" ]]; then
        BUFFER="$selected"    # Put selected command in the buffer
        CURSOR=${#BUFFER}     # Move cursor to the end of the line
      fi
      zle reset-prompt        # Fix potential display glitches after fzf closes
    }
    zle -N fzf-history-widget
    # Bind Ctrl+R to trigger the fzf history search
    bindkey '^R' fzf-history-widget
  fi

  # ---------------------------------------------------------
  # KEYBINDINGS (Insert & Normal Modes)
  # ---------------------------------------------------------

  # --- INSERT MODE (Emacs-style shortcuts for convenience) ---
  
  # Standard terminal navigation in Insert Mode
  bindkey '^P' up-history             # Ctrl+P: Previous command
  bindkey '^N' down-history           # Ctrl+N: Next command
  bindkey '^A' beginning-of-line      # Ctrl+A: Jump to start of line
  bindkey '^E' end-of-line            # Ctrl+E: Jump to end of line
  
  # Text deletion
  bindkey '^H' backward-kill-word     # Ctrl+Backspace: Delete word behind cursor
  bindkey '^?' backward-delete-char   # Backspace: Delete character (fixes Vi-mode backspace lock)
  
  # Utilities
  # Ctrl+X: Immediately reloads your .zshrc (useful for testing changes)
  bindkey -s '^x' 'source $HOME/.zshrc\n'

  # --- NORMAL MODE (Vi Command Mode) ---

  # Make j/k search history based on current input (e.g., type 'git' then hit 'k')
  bindkey -M vicmd 'k' up-line-or-beginning-search
  bindkey -M vicmd 'j' down-line-or-beginning-search
  
  # Ensure 'v' in Normal mode opens your current command in your $EDITOR (Vim/Nano)
  autoload -z edit-command-line
  zle -N edit-command-line
  bindkey -M vicmd 'v' edit-command-line
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
  # if [[ $- == *i* ]] && [[ -z "$TMUX" ]]; then
  #   if _cmd_exists fastfetch; then
  #     fastfetch --logo-type small 2>/dev/null
  #   fi
  # fi
  #
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
  local tools=("git" "nvim" "mise" "gh" "docker" "bat" "rg" "fzf" "eza")
  local packages=("git" "neovim" "mise-bin" "github-cli" "docker" "bat" "ripgrep" "fzf" "eza")
  local completions=(
    "skip"
    "skip"
    "mise completion zsh"
    "gh completion -s zsh && gh copilot alias zsh"
    "skip"
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
      # Load completion with longer delay to ensure system is ready
      _load_completion "$tool" "$completion_cmd" "2"
    else
      echo "$tool not found. Install it? (y/n)"
      read -r response
      if [[ "$response" == "y" ]]; then
        if _install_tool "$tool" "$package"; then
          _load_completion "$tool" "$completion_cmd" "3"
        fi
      fi
    fi
  done
}

_setup_optional_tools() {
  local tools=("warp-cli" "chezmoi")
  local packages=("warp-cli" "chezmoi")
  local completions=(
    "warp-cli generate-completions zsh"
    "chezmoi completion zsh"
  )

  for i in {1..${#tools[@]}}; do
    local tool="${tools[$i]}"
    local package="${packages[$i]}"
    local completion_cmd="${completions[$i]}"

    if _cmd_exists "$tool"; then
      _load_completion "$tool" "$completion_cmd" "3"
    fi
  done
}

_setup_menuselect_bindings() {
  # Menu navigation bindings (requires compinit to be loaded first)
  bindkey -M menuselect '?' history-incremental-search-forward
  bindkey -M menuselect '/' history-incremental-search-backward

  # Use vim keys in tab complete menu
  if [[ -o menucomplete ]]; then
    bindkey -M menuselect '^h' vi-backward-char
    bindkey -M menuselect '^k' vi-up-line-or-history
    bindkey -M menuselect '^l' vi-forward-char
    bindkey -M menuselect '^j' vi-down-line-or-history
    bindkey -M menuselect '^[[Z' vi-up-line-or-history
  fi
}

_init_plugins() {
  # Enhanced completion configuration
  zstyle ':completion:*' menu yes select
  zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
  zmodload zsh/complist
  _comp_options+=(globdots) # Include hidden files
  zle_highlight=('paste:none')

  # FZF-tab configuration
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
  zstyle ':fzf-tab:*' use-fzf-default-opts yes
  zstyle ':fzf-tab:*' fzf-preview 'bat --color=always --style=numbers --line-range :500 {}'

  fpath+=(~/.config/hcloud/completion/zsh)
  # Initialize completion system properly
  autoload -Uz compinit
  compinit

  # Core plugins with proper loading order and deferred completions
  zinit wait lucid for \
    atinit"zicompinit; zicdreplay" \
    zdharma-continuum/fast-syntax-highlighting \
    atload"_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions

  # Load completions plugin with blockf to avoid conflicts
  zinit wait'1' lucid blockf atpull'zinit creinstall -q .' for \
    zsh-users/zsh-completions

  # Load fzf-tab after completions are set up
  zinit wait'1' lucid atload"_setup_menuselect_bindings" for \
    Aloxaf/fzf-tab

  # Load you-should-use last to avoid conflicts
  zinit wait'2' lucid for \
    MichaelAquilina/zsh-you-should-use

  # Setup tool completions after core system is ready
  _setup_essential_tools
  _setup_optional_tools
}

_load_aliases() {
  # If zoxide exists replace cd
  _cmd_exists zoxide && alias cd='z'

  if _cmd_exists fzf; then
    alias fzf='fzf --height 40% --layout=reverse --border'
    alias ff='fzf --preview "bat --style=numbers --color=always {}"'
  fi

  if _cmd_exists fd; then
    alias find='fd'
    alias f='fd --type f --hidden --follow --exclude .git'
  fi

  _cmd_exists rg && alias grep='rg --color=auto --line-number --smart-case  --hidden --glob "!.git"'

  if _cmd_exists bat; then
    alias cat='bat --style=plain --color=always --paging=never'
    alias less='bat --style=plain --color=always --paging=always'
  else
    alias cat='cat --show-all --show-control-chars --show-tabs --show-nonprinting'
    alias less='less -R'
  fi

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
    alias un="$aurhelper -Rns"
    alias up="$aurhelper -Syu --noconfirm"
    alias look="$aurhelper -Qs"
    alias search="$aurhelper -Ss"
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
  
  # Git mirroring aliases for client anonymity
  alias share='$HOME/scripts/mirror-to-client.sh'   # Share code with client (anonymized)
  alias sync='$HOME/scripts/sync-from-client.sh'    # Sync latest code from client
}

# Lazy function definitions
_define_functions() {
  # Fuzzy directory navigation
  fcd() {
    local dir
    dir=$(find . -maxdepth 5 \( -name .git -o -name node_modules -o -name .next -o -name dist \) -prune -o -type d -print 2>/dev/null |
      fzf --height=60% --layout=reverse --preview='eza -la --icons=auto {}' --preview-window=right:60%) &&
      cd "$dir"
  }

  # Fuzzy file edit
  fe() {
    local file
    file=$(fzf --preview='bat --color=always --style=numbers --line-range=:500 {}' --preview-window=right:60%) &&
      ${EDITOR:-nvim} "$file"
  }

  in() {
    # If no arguments provided, show usage
    if [[ $# -eq 0 ]]; then
      echo "Usage: in <package1> [package2] ..."
      return 1
    fi

    if _cmd_exists "$aurhelper"; then
      "$aurhelper" -S "$@"
    else
      echo "No AUR helper found. Installing official packages only..."
      local -a official=()

      for pkg in "$@"; do
        if pacman -Si "$pkg" &>/dev/null; then
          official+=("$pkg")
        else
          echo "⚠️  Skipping AUR package: $pkg (no AUR helper available)"
        fi
      done

      if ((${#official[@]})); then
        sudo pacman -S "${official[@]}"
      fi
    fi
  }

  # Enhanced compression function
  compress() {
    if [[ $# -lt 2 ]]; then
      echo "Usage: compress <archive_name> <files_or_directories...>"
      echo "Supported formats: .tar.gz, .tar.bz2, .tar.xz, .zip, .7z"
      echo "Examples:"
      echo "  compress backup.tar.gz ~/Documents ~/Pictures"
      echo "  compress project.zip src/ README.md"
      return 1
    fi

    local archive="$1"
    shift

    # Validate that source files/directories exist
    for item in "$@"; do
      if [[ ! -e "$item" ]]; then
        echo "Error: '$item' does not exist"
        return 1
      fi
    done

    # Check if archive already exists
    if [[ -f "$archive" ]]; then
      echo "Warning: '$archive' already exists. Overwrite? (y/n)"
      read -r response
      if [[ "$response" != "y" && "$response" != "Y" ]]; then
        echo "Compression cancelled"
        return 1
      fi
    fi

    echo "Compressing $# item(s) into '$archive'..."

    case "$archive" in
    *.tar.gz | *.tgz)
      tar -czf "$archive" "$@" && echo "✓ Created: $archive"
      ;;
    *.tar.bz2 | *.tbz2)
      tar -cjf "$archive" "$@" && echo "✓ Created: $archive"
      ;;
    *.tar.xz | *.txz)
      tar -cJf "$archive" "$@" && echo "✓ Created: $archive"
      ;;
    *.zip)
      zip -r "$archive" "$@" && echo "✓ Created: $archive"
      ;;
    *.7z)
      if _cmd_exists 7z; then
        7z a "$archive" "$@" && echo "✓ Created: $archive"
      else
        echo "Error: 7z not found. Install p7zip package."
        return 1
      fi
      ;;
    *)
      echo "Error: Unsupported format. Supported: .tar.gz, .tar.bz2, .tar.xz, .zip, .7z"
      echo "Archive name should include the extension (e.g., archive.tar.gz)"
      return 1
      ;;
    esac
  }

  # Enhanced extraction function
  extract() {
    if [[ $# -eq 0 ]]; then
      echo "Usage: extract <archive_file> [destination_directory]"
      echo "Supported formats: .tar.gz, .tar.bz2, .tar.xz, .zip, .7z, .rar, .gz, .bz2, .Z"
      return 1
    fi

    local archive="$1"
    local dest_dir="${2:-.}"

    if [[ ! -f "$archive" ]]; then
      echo "Error: '$archive' is not a valid file or does not exist"
      return 1
    fi

    # Create destination directory if it doesn't exist
    if [[ "$dest_dir" != "." && ! -d "$dest_dir" ]]; then
      echo "Creating destination directory: $dest_dir"
      mkdir -p "$dest_dir" || {
        echo "Error: Could not create directory '$dest_dir'"
        return 1
      }
    fi

    # Change to destination directory for extraction
    local original_dir="$PWD"
    if [[ "$dest_dir" != "." ]]; then
      cd "$dest_dir" || {
        echo "Error: Could not change to directory '$dest_dir'"
        return 1
      }
      # Update archive path to be relative to new location
      archive="$original_dir/$archive"
    fi

    echo "Extracting '$archive'..."

    case "$archive" in
    *.tar.bz2 | *.tbz2)
      tar -xjf "$archive" && echo "✓ Extracted successfully"
      ;;
    *.tar.gz | *.tgz)
      tar -xzf "$archive" && echo "✓ Extracted successfully"
      ;;
    *.tar.xz | *.txz)
      tar -xJf "$archive" && echo "✓ Extracted successfully"
      ;;
    *.tar)
      tar -xf "$archive" && echo "✓ Extracted successfully"
      ;;
    *.bz2)
      bunzip2 -k "$archive" && echo "✓ Extracted successfully"
      ;;
    *.gz)
      gunzip -k "$archive" && echo "✓ Extracted successfully"
      ;;
    *.zip)
      unzip -q "$archive" && echo "✓ Extracted successfully"
      ;;
    *.rar)
      if _cmd_exists unrar; then
        unrar x "$archive" && echo "✓ Extracted successfully"
      else
        echo "Error: unrar not found. Install unrar package."
        cd "$original_dir"
        return 1
      fi
      ;;
    *.7z)
      if _cmd_exists 7z; then
        7z x "$archive" && echo "✓ Extracted successfully"
      else
        echo "Error: 7z not found. Install p7zip package."
        cd "$original_dir"
        return 1
      fi
      ;;
    *.Z)
      uncompress "$archive" && echo "✓ Extracted successfully"
      ;;
    *)
      echo "Error: Unsupported archive format for '$archive'"
      echo "Supported: .tar.gz, .tar.bz2, .tar.xz, .zip, .7z, .rar, .gz, .bz2, .Z"
      cd "$original_dir"
      return 1
      ;;
    esac

    # Return to original directory
    cd "$original_dir"
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

  # Tmux layout management helper functions
  _tn_get_layout_path() {
    local dir="$1"
    # Replace $HOME with "home-username"
    local relative_path="${dir#$HOME}"
    local username=$(basename "$HOME")
    local safe_path="home-${username}${relative_path}"
    # Replace all special characters with hyphens
    safe_path="${safe_path//[^a-zA-Z0-9_-]/-}"
    # Collapse multiple hyphens
    safe_path="${safe_path//--/-}"
    # Remove leading/trailing hyphens
    safe_path="${safe_path#-}"
    safe_path="${safe_path%-}"
    
    local layout_dir="${XDG_STATE_HOME:-$HOME/.local/state}/tmux-layouts"
    echo "$layout_dir/$safe_path"
  }

  _tn_save_layout() {
    local session_name="$1"
    local session_path="$2"
    
    if [[ -z "$session_name" ]]; then
      echo "Error: No tmux session found"
      return 1
    fi

    local layout_file="$(_tn_get_layout_path "$session_path")"
    local layout_dir="${layout_file%/*}"
    
    mkdir -p "$layout_dir"
    
    {
      echo "# Tmux layout for session: $session_name"
      echo "# Path: $session_path"
      echo "# Saved: $(date)"
      echo "SESSION_NAME=$session_name"
      echo "SESSION_PATH=$session_path"
      echo ""
      echo "# Windows"
      tmux list-windows -t "$session_name" -F "#{window_index}:#{window_name}:#{window_layout}"
      echo ""
      echo "# Panes with commands"
      tmux list-windows -t "$session_name" -F "#{window_index}" | while read -r win_idx; do
        tmux list-panes -t "$session_name:$win_idx" -F "#{pane_index}:#{pane_current_command}:#{pane_current_path}" | while IFS=: read -r pane_idx cmd pane_path; do
          echo "WINDOW=$win_idx PANE=$pane_idx CMD='$cmd' PATH='$pane_path'"
        done
      done
    } > "$layout_file"
    
    echo "Layout saved to: $layout_file"
  }

  _tn_restore_layout() {
    local layout_file="$1"
    local session_name="$2"
    
    if [[ ! -f "$layout_file" ]]; then
      echo "No saved layout found"
      return 1
    fi
    
    # Parse session info from layout file
    local session_path=$(command grep "^SESSION_PATH=" "$layout_file" | cut -d= -f2)
    
    # Create session if it doesn't exist
    tmux has-session -t "$session_name" 2>/dev/null || {
      tmux new-session -d -s "$session_name" -c "$session_path"
    }
    
    # Restore windows and panes (simplified restoration)
    # This is a basic implementation - full restoration would need more complex logic
    echo "Restoring layout from $layout_file..."
    
    # Kill existing windows except the first one
    local current_windows=$(tmux list-windows -t "$session_name" -F "#{window_index}" | sort -rn)
    for win in $current_windows; do
      if [[ "$win" != "1" ]]; then
        tmux kill-window -t "$session_name:$win"
      fi
    done
    
    # Parse and create windows
    command grep "^# Windows" -A 100 "$layout_file" | command grep -E "^[0-9]+:" | while IFS=: read -r win_idx win_name win_layout; do
      if [[ "$win_idx" == "1" ]]; then
        tmux rename-window -t "$session_name:1" "$win_name"
      else
        tmux new-window -t "$session_name" -n "$win_name" -c "$session_path"
      fi
    done
    
    # Start commands in panes
    command grep "^WINDOW=" "$layout_file" | while read -r line; do
      eval "$line"
      if [[ "$CMD" != "'zsh'" && "$CMD" != "'bash'" && "$CMD" != "''" ]]; then
        tmux send-keys -t "$session_name:$WINDOW.$PANE" "$CMD" C-m
      fi
    done
  }

  # Enhanced tmux session management
  tn() {
    local session_name="${1:-$(basename "$PWD")}"
    session_name="${session_name//[^a-zA-Z0-9_-]/_}"
    
    local layout_file="$(_tn_get_layout_path "$PWD")"
    
    if [[ "$1" == "--save" ]]; then
      if [[ -n "$TMUX" ]]; then
        local current_session=$(tmux display-message -p "#{session_name}")
        _tn_save_layout "$current_session" "$PWD"
      else
        echo "Error: Not in a tmux session"
        return 1
      fi
      return
    fi
    
    # Check if session exists
    if tmux has-session -t "$session_name" 2>/dev/null; then
      # Check for saved layout
      if [[ -f "$layout_file" ]]; then
        _tn_restore_layout "$layout_file" "$session_name"
      fi
      tmux attach-session -t "$session_name"
    else
      # Check for saved layout for new session
      if [[ -f "$layout_file" ]]; then
        _tn_restore_layout "$layout_file" "$session_name"
        tmux attach-session -t "$session_name"
      else
        # Create new session
        tmux new-session -A -s "$session_name" -c "$PWD"
      fi
    fi
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

# Optimized mise hook that avoids completion conflicts
_mise_chpwd_hook_optimized() {
  # Check if mise is available and we have mise config files
  if _cmd_exists mise && [[ -f .mise.toml || -f .tool-versions || -f mise.toml || -f .env || -f .nvmrc || -f .node-version || -f .yarnrc || -f .pnpm-lock.yaml || -f .go.mod || -f .ruby-version || -f .python-version ]]; then

    # Load pnpm completion if available and not already loaded
    if _cmd_exists pnpm; then
      # Use a more conservative approach to avoid completion conflicts
      if _cmd_exists pnpm; then
        zinit wait'2' lucid nocd as"completion" for \
          atload"eval \"$(pnpm completion zsh)\"" \
          zdharma-continuum/null
      fi

      # Load pnpm plugin separately
      zinit wait'2' lucid for ntnyq/omz-plugin-pnpm
    fi

    if _cmd_exists bun; then
      zinit wait'2' lucid nocd as"completion" for \
        atload"eval \"$(bun completions)\"" \
        zdharma-continuum/null
    fi
  fi
}

_load_completion() {
  local tool="$1"
  local completion_cmd="$2"
  local delay="${3:-3}"

  # Skip if tool doesn't exist or no completion command
  if ! _cmd_exists "$tool" || [[ -z "$completion_cmd" || "$completion_cmd" == "skip" ]]; then
    return
  fi

  # Defer all completions to avoid conflicts with initialization
  case "$tool" in
  git | docker)
    # These are handled by zsh-completions plugin
    ;;
  *)
    # For other tools, load completion in a deferred, safe way
    if [[ -n "$completion_cmd" ]]; then
      zinit wait"$delay" lucid nocd as"completion" for \
        atload"eval \"\$($completion_cmd)\" 2>/dev/null" \
        zdharma-continuum/null
    fi
    ;;
  esac
}

# Initialize mise if available
_init_mise() {
  if _cmd_exists mise; then
    eval "$(mise activate zsh)"
  fi
}


# Initialize components
_detect_terminal
_detect_aur_helper
_setup_vi_mode
_init_zinit
_init_starship
_init_mise

if _cmd_exists zoxide; then
  _load_completion zoxide "zoxide init zsh" "0"
fi

if _cmd_exists fd; then
  _load_completion fd "fd --gen-completions zsh" "1"
fi

autoload -Uz add-zsh-hook
add-zsh-hook precmd _set_terminal_title
add-zsh-hook chpwd _mise_chpwd_hook_optimized

# Load functions and aliases
_define_functions
_load_aliases

_init_plugins

_mise_chpwd_hook_optimized

_save_cmd_cache() {
  if ((${#_cmd_cache_new_entries[@]} > 0)); then
    for cmd in "${!_cmd_cache_new_entries[@]}"; do
      echo "_cmd_cache[$cmd]=${_cmd_cache_new_entries[$cmd]}"
    done >>"$_cache_file"
  fi
}
add-zsh-hook zshexit _save_cmd_cache

# Performance warning
_end_time=$SECONDS
_load_time=$((_end_time - _start_time))
if ((_load_time > 3)); then
  echo "⚠️  Shell startup took ${_load_time}s. Consider optimizing further."
fi

# Cleanup
# unset _start_time _end_time _load_time

# zprof

alias ua-drop-caches="sudo paccache -rk3; $aurhelper -Sc --aur --noconfirm"
alias ua-update-all="export TMPFILE='$(mktemp)'; \
    sudo true; \
    rate-mirrors --save=$TMPFILE arch --max-delay=21600 \
      && sudo mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist-backup \
      && sudo mv $TMPFILE /etc/pacman.d/mirrorlist \
      && ua-drop-caches \
      && $aurhelper -Syyu --noconfirm"
alias ua-update-chaotic="export TMPFILE='$(mktemp)'; \
    sudo true; \
    rate-mirrors --save=$TMPFILE chaotic-aur \
      && sudo cp /etc/pacman.d/chaotic-mirrorlist /etc/pacman.d/chaotic-mirrorlist-backup \
      && sudo mv $TMPFILE /etc/pacman.d/chaotic-mirrorlist \
      && $aurhelper -Syyu --noconfirm"


[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"
[[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code-insiders --locate-shell-integration-path zsh)"
