[[ -f ~/.profile ]] && source ~/.profile

# Enable appending to the history file, rather than overwriting it
# when the shell exits.
setopt APPEND_HISTORY

# History settings
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY

# Basic shell options
unsetopt BEEP
setopt AUTO_CD
setopt GLOB_DOTS
setopt NOMATCH
setopt MENU_COMPLETE
setopt EXTENDED_GLOB
setopt INTERACTIVE_COMMENTS

# Colors
autoload -Uz colors && colors

# Key bindings
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
zmodload zsh/complist
bindkey -s '^x' 'source $HOME/.zshrc\n'
bindkey -M menuselect '?' history-incremental-search-forward
bindkey -M menuselect '/' history-incremental-search-backward
bindkey '^H' backward-kill-word # Ctrl + Backspace to delete a whole word.
bindkey -v
export KEYTIMEOUT=1

function in() {
    local -a inPkg=("$@")
    local -a arch=()
    local -a aur=()

    for pkg in "${inPkg[@]}"; do
        if pacman -Si "${pkg}" &>/dev/null; then
            arch+=("${pkg}")
        else
            aur+=("${pkg}")
        fi
    done

    if [[ ${#arch[@]} -gt 0 ]]; then
        sudo pacman -S "${arch[@]}"
    fi

    if [[ ${#aur[@]} -gt 0 ]]; then
        ${aurhelper} -S "${aur[@]}"
    fi
}

function init_activations() {
  # Activations
  [[ -x "$(command -v gh)" ]] && eval "$(gh copilot alias zsh)"
  [[ -x "$(command -v zoxide)" ]] && eval "$(zoxide init zsh)"
  # Only run mise activate, PATH is already set in .zshenv
  [[ -x "$(command -v mise)" ]] && eval "$(mise activate zsh)"
}
init_activations

# Initialize Starship prompt
if ! command -v starship &> /dev/null; then
  echo "Starship not found. Install it? (y/n)"
  read -r response
  if [[ "$response" == "y" ]]; then
    curl -fsSL https://starship.rs/install.sh | sh -s -- --yes
  fi
fi
eval "$(starship init zsh)"

# Initialize Zap
if [[ ! -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ]]; then
  echo "Zap not found. Install it? (y/n)"
  read -r response
  if [[ "$response" == "y" ]]; then
    zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh) --keep --branch release-v1
  fi
fi
source "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh"

# Load plugins
plug "zdharma-continuum/fast-syntax-highlighting"
plug "zsh-users/zsh-autosuggestions"
plug "zsh-users/zsh-completions"
plug "MichaelAquilina/zsh-you-should-use"
plug "zap-zsh/completions"
plug "zap-zsh/fzf"
plug "Aloxaf/fzf-tab"

# Completion settings
autoload -Uz compinit
zstyle ':completion:*' menu yes select
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
_comp_options+=(globdots)  # Include hidden files.
zle_highlight=('paste:none')
compinit -C

# FZF-tab configuration
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept
zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:*' fzf-preview 'bat --color=always --style=numbers --line-range :500 {}'

# Cursor shape for vi modes
function zle-keymap-select () {
  case $KEYMAP in
    vicmd) echo -ne '\e[1 q';;      # block
    viins|main) echo -ne '\e[5 q';; # beam
  esac
  zle reset-prompt
}
zle -N zle-keymap-select

zle-line-init() {
  zle -K viins
  echo -ne "\e[5 q"
}
zle -N zle-line-init

# Initialize completions
function init_completions() {
  # Completions
  [[ -x "$(command -v fzf)" ]] && eval "$(fzf --zsh)"
  [[ -x "$(command -v warp-cli)" ]] && eval "$(warp-cli generate-completions zsh)"
  [[ -x "$(command -v pnpm)" ]] && eval "$(pnpm completion zsh)"
  [[ -x "$(command -v gh)" ]] && eval "$(gh completion -s zsh)"
  [[ -x "$(command -v go-blueprint)" ]] && eval "$(go-blueprint completion zsh)"
  [[ -x "$(command -v mise)" ]] && eval "$(mise completion zsh)"
}
init_completions

# Aliases
alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
alias c='clear'
alias l='eza -lh --icons=auto'
alias la='eza -lha --icons=auto'
alias ls='eza -lh --icons=auto --group-directories-first'
alias ll='eza -lha --icons=auto --sort=name --group-directories-first'
alias ld='eza -lhD --icons=auto'
alias lt='eza --icons=auto --tree'
alias rg="rg --hidden --glob '!.git'"
alias cat="bat"
alias scripts="jq '.scripts' package.json | bat --color auto"
alias fd='fdfind'
alias cd='z'
alias n='nvim'
alias g='git'
alias d='docker'
alias lzg='lazygit'
alias lzd='lazydocker'
alias dev='code .'
alias decompress="tar -xzf"
alias un='$aurhelper -Rns'
alias up='$aurhelper -Syu'
alias pl='$aurhelper -Qs'
alias pa='$aurhelper -Ss'
alias pc='$aurhelper -Sc'
alias po='$aurhelper -Qtdq | $aurhelper -Rns -'
alias vc='code'
alias fastfetch='fastfetch --logo-type kitty'
alias mkd='mkdir -p'
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'

# pnpm
export PNPM_HOME="/home/arafay/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH:$HOME/.pub-cache/bin" ;;
esac
# pnpm end

# Functions
tn() {
  local session_name="${1:-$(basename "$PWD")}"
  tmux new-session -A -s "$session_name" -c "$PWD"
}

tt() {
  tn "$@"
}

function compress() { tar -czf "${1%/}.tar.gz" "${1%/}"; }

function webm2mp4() {
  input_file="$1"
  output_file="${input_file%.webm}.mp4"
  ffmpeg -i "$input_file" -c:v libx264 -preset slow -crf 22 -c:a aac -b:a 192k "$output_file"
}
