# Configuration for Zsh history control

# Enable appending to the history file, rather than overwriting it
# when the shell exits.
setopt APPEND_HISTORY

# Ignore duplicate commands and commands that start with a space
# when saving to the history.
HISTCONTROL=ignoreboth

# Set the maximum number of history entries to save in memory.
HISTSIZE=32768

# Set the maximum number of history entries to save in the history file.
HISTFILESIZE="${HISTSIZE}"

# if command --v fzf &> /dev/null; then
#     export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
#     export FZF_CTRL_T_COMMAND="$HOME/.fzf/bin/fzf-tmux --height 40% --layout=reverse --border"
#     export FZF_CTRL_T_OPTS="--height 40% --layout=reverse --border"
#     eval "$(fzf --zsh)"
# fi

if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi

bindkey "\e[3~" delete-char # delete key

bindkey -v
export KEYTIMEOUT=1
# Technicolor dreams
force_color_prompt=yes
color_prompt=yes

PROMPT=$'\uf0a9 '
precmd() { print -Pn "\e]0;%~\a" }

# if starship is not installed, install it
if !command -v starship &> /dev/null; then
    echo "Starship not found. Installing..."
    curl -fsSL https://starship.rs/install.sh | bash -s -- --yes
fi

## Created by Zap installer
[[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ]] ||
    zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh) --keep --branch release-v1
source "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh"

# # # zsh plugins
plug "zdharma-continuum/fast-syntax-highlighting"
plug "MichaelAquilina/zsh-you-should-use"

plug "zap-zsh/supercharge"

plug "zsh-users/zsh-autosuggestions"

plug "zap-zsh/completions"

plug "zap-zsh/fzf"
plug "Aloxaf/fzf-tab"

# auto start zellij
# if command -v zellij &> /dev/null; then
#     eval "$(zellij setup --generate-auto-start zsh)"
# fi

autoload -U +X compinit && compinit
. <( zellij setup --generate-completion zsh | sed -Ee 's/^(_(zellij) ).*/compdef \1\2/' )

# Use vim keys in tab complete menu:
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -v '^?' backward-delete-char

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


if command -v go-blueprint &> /dev/null; then
  eval "$(go-blueprint completion zsh)"
fi
# To update the gist
# gh api --method PATCH -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" /gists/3beb86f3b33e396654b1cf1799c923f9 -f "files[.zshrc][content]=$(cat ~/.zshrc)"


#compdef pnpm
###-begin-pnpm-completion-###
if type compdef &>/dev/null; then
  _pnpm_completion () {
    local reply
    local si=$IFS

    IFS=$'\n' reply=($(COMP_CWORD="$((CURRENT-1))" COMP_LINE="$BUFFER" COMP_POINT="$CURSOR" SHELL=zsh pnpm completion-server -- "${words[@]}"))
    IFS=$si

    if [ "$reply" = "__tabtab_complete_files__" ]; then
      _files
    else
      _describe 'values' reply
    fi
  }
  # When called by the Zsh completion system, this will end with
  # "loadautofunc" when initially autoloaded and "shfunc" later on, otherwise,
  # the script was "eval"-ed so use "compdef" to register it with the
  # completion system
  if [[ $zsh_eval_context == *func ]]; then
    _pnpm_completion "$@"
  else
    compdef _pnpm_completion pnpm
  fi
fi
###-end-pnpm-completion-###

# bun completions
[ -s "/home/arafay/.bun/_bun" ] && source "/home/arafay/.bun/_bun"

eval "$(mise activate zsh)"
eval "$(starship init zsh)"
