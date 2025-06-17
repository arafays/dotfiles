## exports
export PATH="$HOME/.local/bin:$PATH"
export ZSH="$HOME/.oh-my-zsh"

export WGPU_BACKEND=gl
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

# completions
autoload -Uz compinit
zstyle ':completion:*' menu yes select
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zmodload zsh/complist
_comp_options+=(globdots)  # Include hidden files.
zle_highlight=('paste:none')
compinit -C

unsetopt BEEP
setopt AUTO_CD
setopt GLOB_DOTS
setopt NOMATCH
setopt MENU_COMPLETE
setopt EXTENDED_GLOB
setopt INTERACTIVE_COMMENTS

# Key bindings
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey -s '^x' 'source $HOME/.zshrc\n'
bindkey -M menuselect '?' history-incremental-search-forward
bindkey -M menuselect '/' history-incremental-search-backward
bindkey '^H' backward-kill-word # Ctrl + Backspace to delete a whole word.
bindkey -v
export KEYTIMEOUT=1


# Colors
autoload -Uz colors && colors

if [[ -o menucomplete ]]; then
  # Use vim keys in tab complete menu:
  bindkey -M menuselect '^h' vi-backward-char
  bindkey -M menuselect '^k' vi-up-line-or-history
  bindkey -M menuselect '^l' vi-forward-char
  bindkey -M menuselect '^j' vi-down-line-or-history
  bindkey -M menuselect '^[[Z' vi-up-line-or-history
fi

# Prompt
PROMPT=$'\uf0a9 ' # Unicode arrow
if [[ ! $(locale charmap) =~ "UTF-8" ]]; then
  PROMPT="> " # Fallback for non-UTF-8 locales
fi
precmd() { print -Pn "\e]0;%~\a" }

if ! command -v starship &> /dev/null; then
  echo "Starship not found. Install it? (y/n)"
  read -r response
  if [[ "$response" == "y" ]]; then
    curl -fsSL https://starship.rs/install.sh | sh -s -- --yes
  fi
fi
eval "$(starship init zsh)"

## Zap installer
if [[ ! -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ]]; then
  echo "Zap not found. Install it? (y/n)"
  read -r response
  if [[ "$response" == "y" ]]; then
    zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh) --keep --branch release-v1
  fi
fi
source "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh"

# # zsh plugins
plug "zdharma-continuum/fast-syntax-highlighting"
plug "zsh-users/zsh-autosuggestions"
plug "zsh-users/zsh-completions"
plug "zap-zsh/completions"
plug "zap-zsh/fzf"
plug "Aloxaf/fzf-tab"

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

# Group completion initializations into a single function
function init_essentials() {
  [[ -x "$(command -v fzf)" ]] && eval "$(fzf --zsh)"
  [[ -x "$(command -v gh)" ]] && eval "$(gh copilot alias zsh)"
  [[ -x "$(command -v zoxide)" ]] && eval "$(zoxide init zsh)"
  [[ -x "$(command -v mise)" ]] && { eval "$(mise activate zsh)";}
}
init_essentials

# Group completion initializations into a single function
function init_completions() {
  [[ -x "$(command -v warp-cli)" ]] && eval "$(warp-cli generate-completions zsh)"
  [[ -x "$(command -v pnpm)" ]] && eval "$(pnpm completion zsh)"
  [[ -x "$(command -v go-blueprint)" ]] && eval "$(go-blueprint completion zsh)"
  [[ -x "$(command -v mise)" ]] && { eval "$(mise completion zsh)"; }
}
init_completions


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

# To update the gist
# gh api --method PATCH -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" /gists/3beb86f3b33e396654b1cf1799c923f9 -f "files[.zshrc][content]=$(cat ~/.zshrc)"
export GPG_TTY=$(tty)

# pnpm
export PNPM_HOME="/home/arafays/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
