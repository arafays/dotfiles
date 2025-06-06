# Initialize keychain if available
if command -v keychain &> /dev/null; then
    eval "$(keychain --eval --quiet id_ed25519)"
fi

# Start ssh-agent if not running
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    ssh-agent > "$XDG_RUNTIME_DIR/ssh-agent.env"
fi
if [[ ! "$SSH_AUTH_SOCK" ]]; then
    eval "$(<"$XDG_RUNTIME_DIR/ssh-agent.env")"
fi
