# Configuration for Zsh history control

# Enable appending to the history file, rather than overwriting it
# when the shell exits.
setopt APPEND_HISTORY

# Ignore duplicate commands and commands that start with a space
# when saving to the history.
HISTCONTROL=ignoreboth
HISTFILESIZE="${HISTSIZE}"
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000


# if command --v fzf &> /dev/null; then
#     export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
#     export FZF_CTRL_T_COMMAND="$HOME/.fzf/bin/fzf-tmux --height 40% --layout=reverse --border"
#     export FZF_CTRL_T_OPTS="--height 40% --layout=reverse --border"
#     eval "$(fzf --zsh)"
# fi

# completions
autoload -Uz compinit
zstyle ':completion:*' menu yes select
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zmodload zsh/complist
_comp_options+=(globdots)		# Include hidden files.
zle_highlight=('paste:none')
for dump in "${ZDOTDIR:-$HOME}/.zcompdump"(N.mh+24); do
  compinit
done
compinit -C

unsetopt BEEP
setopt AUTO_CD
setopt GLOB_DOTS
setopt NOMATCH
setopt MENU_COMPLETE
setopt EXTENDED_GLOB
setopt INTERACTIVE_COMMENTS
setopt APPEND_HISTORY

setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
# setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
# setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY               # Don't execute immediately upon history expansion.

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# Colors
autoload -Uz colors && colors

# exports
export PATH="$HOME/.local/bin:$PATH"

# bindings
bindkey -s '^x' '^usource $ZSHRC\n'
bindkey -M menuselect '?' history-incremental-search-forward
bindkey -M menuselect '/' history-incremental-search-backward
bindkey '^H' backward-kill-word # Ctrl + Backspace to delete a whole word.
bindkey -v
export KEYTIMEOUT=1

if [[ -o menucomplete ]]; then 
  # Use vim keys in tab complete menu:
  bindkey -M menuselect '^h' vi-backward-char
  bindkey -M menuselect '^k' vi-up-line-or-history
  bindkey -M menuselect '^l' vi-forward-char
  bindkey -M menuselect '^j' vi-down-line-or-history
  bindkey -M menuselect '^[[Z' vi-up-line-or-history
fi

bindkey -v '^?' backward-delete-char

PROMPT=$'\uf0a9 '
precmd() { print -Pn "\e]0;%~\a" }

## Created by Zap installer
[[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ]] ||
    zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh) --keep --branch release-v1
source "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh"

# # zsh plugins
plug "zdharma-continuum/fast-syntax-highlighting"

plug "zsh-users/zsh-autosuggestions"
plug "zsh-users/zsh-completions"

plug "MichaelAquilina/zsh-you-should-use"

plug "zap-zsh/completions"
plug "zap-zsh/fzf"

plug "Aloxaf/fzf-tab"

# auto start zellij
# if command -v zellij &> /dev/null; then
#     eval "$(zellij setup --generate-auto-start zsh)"
# fi

autoload -U +X compinit && compinit
. <( zellij setup --generate-completion zsh | sed -Ee 's/^(_(zellij) ).*/compdef \1\2/' )

# Change cursor shape for different vi modes.
function zle-keymap-select () {
  case $KEYMAP in
    vicmd) echo -ne '\e[1 q';;      # block
    viins|main) echo -ne '\e[5 q';; # beam
  esac
}
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne "\e[5 q"
}
zle -N zle-line-init
# Set up fzf key bindings and fuzzy completion

# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
# NOTE: don't use escape sequences (like '%F{red}%d%f') here, fzf-tab will ignore them
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no
# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
# custom fzf flags
# NOTE: fzf-tab does not follow FZF_DEFAULT_OPTS by default
zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept
# To make fzf-tab follow FZF_DEFAULT_OPTS.
# NOTE: This may lead to unexpected behavior since some flags break this plugin. See Aloxaf/fzf-tab#455.
zstyle ':fzf-tab:*' use-fzf-default-opts yes
# switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'


# To update the gist
# gh api --method PATCH -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" /gists/3beb86f3b33e396654b1cf1799c923f9 -f "files[.zshrc][content]=$(cat ~/.zshrc)"

if command -v pnpm &> /dev/null; then
  eval "$(pnpm completion zsh)"
fi

if commmand -v bun &> /dev/null; then
  # bun completions
  [ -s "/home/arafay/.bun/_bun" ] && source "/home/arafay/.bun/_bun"
fi

if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi

if command -v go-blueprint &> /dev/null; then
  eval "$(go-blueprint completion zsh)"
fi

if command -v mise &> /dev/null; then
  eval "$(mise activate zsh)"
fi

# if starship is not installed, install it
if !command -v starship &> /dev/null; then
    echo "Starship not found. Installing..."
    curl -fsSL https://starship.rs/install.sh | bash -s -- --yes
fi

if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
fi
