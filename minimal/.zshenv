[[ -f ~/.profile ]] && source ~/.profile

# Zsh-specific environment settings that need to be available in all zsh shells.

# History settings (these affect all shells)
export HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
export HISTSIZE=50000
export SAVEHIST=50000
export LESSHISTFILE=${LESSHISTFILE:-/tmp/less-hist}
