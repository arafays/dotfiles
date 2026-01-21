# .zprofile - Login shell configuration
# This runs for login shells only

# SSH agent and keychain setup (only for login shells)
if [[ -z "$SSH_AUTH_SOCK" ]] && command -v keychain &>/dev/null; then
    eval "$(keychain --eval --quiet --agents ssh id_ed25519 2>/dev/null)"
elif [[ -z "$SSH_AUTH_SOCK" ]]; then
    # Fallback SSH agent setup
    ssh_env="$XDG_RUNTIME_DIR/ssh-agent.env"
    if ! pgrep -u "$USER" ssh-agent >/dev/null; then
        ssh-agent >"$ssh_env"
    fi
    [[ -f "$ssh_env" ]] && source "$ssh_env" >/dev/null
fi

# Clean up old SSH sockets
find /tmp -name 'ssh-*' -user "$USER" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
