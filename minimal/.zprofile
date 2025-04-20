# Group completion initializations into a single function
function init_completions() {
  [[ -x "$(command -v fzf)" ]] && eval "$(fzf --zsh)"
  [[ -x "$(command -v gh)" ]] && eval "$(gh copilot alias zsh)"
  [[ -x "$(command -v zoxide)" ]] && eval "$(zoxide init zsh)"
  [[ -x "$(command -v mise)" ]] && { eval "$(mise activate zsh)";}
}
init_completions


