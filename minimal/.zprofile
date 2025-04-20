# Group completion initializations into a single function
function init_completions() {
  [[ -x "$(command -v fzf)" ]] && eval "$(fzf --zsh)"
  [[ -x "$(command -v warp-cli)" ]] && eval "$(warp-cli generate-completions zsh)"
  [[ -x "$(command -v pnpm)" ]] && eval "$(pnpm completion zsh)"
  [[ -x "$(command -v gh)" ]] && eval "$(gh copilot alias zsh)"
  [[ -x "$(command -v zoxide)" ]] && eval "$(zoxide init zsh)"
  [[ -x "$(command -v go-blueprint)" ]] && eval "$(go-blueprint completion zsh)"
  [[ -x "$(command -v mise)" ]] && { eval "$(mise activate zsh)"; eval "$(mise completion zsh)"; }
}
init_completions


