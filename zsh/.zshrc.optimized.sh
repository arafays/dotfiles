# .zshrc - Interactive shell configuration with lazy loading
# This file is only loaded for interactive shells

# Cache directory for command existence checks
typeset -A _cmd_cache
_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
_cache_file="$_cache_dir/cmd_cache"
[[ ! -d "$_cache_dir" ]] && mkdir -p "$_cache_dir"

# Fast command existence check with caching
_cmd_exists() {
    local cmd="$1"
    if [[ -z "${_cmd_cache[$cmd]}" ]]; then
        if command -v "$cmd" &>/dev/null; then
            _cmd_cache[$cmd]=1
        else
            _cmd_cache[$cmd]=0
        fi
    fi
    return $(( 1 - _cmd_cache[$cmd] ))
}

# Load cached command results if available
[[ -f "$_cache_file" ]] && source "$_cache_file"

# Terminal detection (only run once)
_detect_terminal() {
    if [[ -n "$COLORTERM" ]]; then
        return  # Already set
    fi

    if [[ "$TERM_PROGRAM" == "alacritty" || "$TERMINAL" == *"alacritty"* ]]; then
        export COLORTERM=truecolor
    elif [[ "$TERM_PROGRAM" == "kitty" || "$TERMINAL" == *"kitty"* ]]; then
        export COLORTERM=truecolor
    fi
}
_detect_terminal

# AUR helper detection with caching
_detect_aur_helper() {
    if [[ -n "$aurhelper" ]]; then
        return  # Already detected
    fi

    if _cmd_exists yay; then
        export aurhelper="yay"
    elif _cmd_exists paru; then
        export aurhelper="paru"
    fi
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

# Load plugins with turbo mode for better performance
_load_plugins() {
    _init_zinit

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
        MichaelAquilina/zsh-you-should-use \
        Aloxaf/fzf-tab

    # Tools that can be loaded later
    zinit wait'2' lucid as"command" from"gh-r" for \
        junegunn/fzf
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

        (( ${#arch[@]} )) && sudo pacman -S "${arch[@]}"
        (( ${#aur[@]} )) && [[ -n "$aurhelper" ]] && "$aurhelper" -S "${aur[@]}"
    }

    # File compression
    compress() { tar -czf "${1%/}.tar.gz" "${1%/}"; }

    # Video conversion
    webm2mp4() {
        local input="$1" output="${1%.webm}.mp4"
        ffmpeg -i "$input" -c:v libx264 -preset slow -crf 22 -c:a aac -b:a 192k "$output"
    }
}

# Completion configuration
_setup_completions() {
    autoload -Uz compinit

    # Speed up compinit by checking only once per day
    local dump_file="$XDG_CACHE_HOME/zsh/zcompdump"
    if [[ "$dump_file"(#qNmh+24) ]]; then
        compinit -C -d "$dump_file"
    else
        compinit -d "$dump_file"
    fi

    # Completion styling
    zstyle ':completion:*' menu select
    zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
    zstyle ':completion:*:descriptions' format '[%d]'

    # FZF-tab configuration
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath 2>/dev/null || ls -1 $realpath'
    zstyle ':fzf-tab:*' switch-group '<' '>'
}

# Lazy load external tool integrations
_init_external_tools() {
    # Load these only when first accessed
    _cmd_exists gh && eval "$(gh copilot alias zsh)" &
    _cmd_exists zoxide && eval "$(zoxide init zsh)" &
    _cmd_exists mise && eval "$(mise activate zsh)" &
    _cmd_exists starship && eval "$(starship init zsh)" &
    wait  # Wait for all background jobs
}

# Deferred completions (load after shell is ready)
_init_completions() {
    _cmd_exists fzf && eval "$(fzf --zsh)" &
    _cmd_exists gh && eval "$(gh completion -s zsh)" &
    _cmd_exists mise && eval "$(mise completion zsh)" &
    wait
}

# Set up aliases
_setup_aliases() {
    # Core aliases
    alias c='clear'
    alias ..='cd ..'
    alias n='nvim'

    # Enhanced ls if eza is available
    if _cmd_exists eza; then
        alias ls='eza -lh --icons=auto --group-directories-first'
        alias lt='eza --icons=auto --tree'
    fi

    # Enhanced cat if bat is available
    _cmd_exists bat && alias cat='bat'

    # FZF file finder
    _cmd_exists fzf && alias ff='fzf --preview "bat --color=always {}" 2>/dev/null || cat {}'
}

# Vi mode configuration
_setup_vi_mode() {
    bindkey -v
    export KEYTIMEOUT=1

    # Cursor shape for vi modes
    zle-keymap-select() {
        case $KEYMAP in
            vicmd) echo -ne '\e[1 q' ;;
            viins|main) echo -ne '\e[5 q' ;;
        esac
    }
    zle -N zle-keymap-select

    zle-line-init() {
        zle -K viins
        echo -ne "\e[5 q"
    }
    zle -N zle-line-init
}

# Shell options
_setup_shell_options() {
    # Navigation
    setopt AUTO_CD
    setopt EXTENDED_GLOB
    setopt GLOB_DOTS

    # Interaction
    setopt INTERACTIVE_COMMENTS
    setopt MENU_COMPLETE

    # History (additional options)
    setopt BANG_HIST
    setopt HIST_EXPIRE_DUPS_FIRST
    setopt HIST_FIND_NO_DUPS
    setopt HIST_VERIFY

    # Misc
    unsetopt BEEP
    setopt NOMATCH
}

# Terminal title
_set_terminal_title() {
    print -Pn "\e]0;%~\a"
}

# Performance monitoring
_perf_monitor() {
    local start_time=$SECONDS
    if (( start_time > 2 )); then
        echo "⚠️  Shell startup took ${start_time}s. Consider optimizing further."
    fi
}

# Main initialization (run everything in order of importance)
() {
    # Essential setup (blocking)
    _setup_shell_options
    _setup_aliases
    _define_functions
    _detect_aur_helper

    # Completions (can be slightly deferred)
    zsh-defer _setup_completions

    # Plugin loading (deferred)
    zsh-defer _load_plugins

    # External tools (background loading)
    zsh-defer _init_external_tools
    zsh-defer _init_completions

    # UI setup
    zsh-defer _setup_vi_mode

    # Hooks
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd _set_terminal_title
    add-zsh-hook precmd _perf_monitor

    # Save command cache
    {
        echo "# Auto-generated command cache"
        for cmd val in ${(kv)_cmd_cache}; do
            echo "_cmd_cache[$cmd]=$val"
        done
    } > "$_cache_file"
}

# Zsh-defer function for lazy loading (if not available via plugin)
if ! typeset -f zsh-defer > /dev/null; then
    zsh-defer() {
        zle -N zle-line-init "${(j:; :)@} ${functions[zle-line-init]#*$'\n'}"
    }
fi
