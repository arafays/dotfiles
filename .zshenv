#!/usr/bin/env zsh
[[ -f ~/.profile ]] && source ~/.profile

# History settings (these affect all shells)
export HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
export HISTSIZE=50000
export SAVEHIST=50000
