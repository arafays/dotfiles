# Add local bin to PATH if it exists
if [[ -d "$HOME/.local/bin" ]]; then
	export PATH="$HOME/.local/bin:$PATH"
fi

# Export PATH to ensure it's available to all child processes
export PATH
