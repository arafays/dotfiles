#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

eval "$(mise activate bash)"

alias ls='ls --color=auto'
alias grep='rg --color=auto'
PS1='[\u@\h \W]\$ '

export GPG_TTY=$(tty)
