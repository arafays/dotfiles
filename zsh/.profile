# Define an array to manage PATH entries
path_array=(
	"$HOME/.local/bin"
	"$HOME/.pub-cache/bin"
	"$HOME/Android/Sdk/platform-tools"
	"$HOME/Android/Sdk/emulator"
	"$HOME/Android/Sdk/cmdline-tools/latest/bin"
	"$HOME/Android/Sdk/build-tools/35.0.1"
)

# Function to update PATH from path_array
update_path() {
	local new_path=""
	for dir in "${path_array[@]}"; do
		if [[ -d "$dir" ]]; then
			if [[ -z "$new_path" ]]; then
				new_path="$dir"
			else
				new_path="$new_path:$dir"
			fi
		fi
	done
	export PATH="$new_path:$PATH"
}

# Function to add a new path
add_path() {
	local new_path="$1"
	if [[ -d $new_path && ! ${path_array[*]} =~ $new_path ]]; then
		path_array+=("$new_path")
		update_path
	fi
}

# Function to remove a path
remove_path() {
	local remove_path="$1"
	local new_array=()
	for item in "${path_array[@]}"; do
		[[ "$item" != "$remove_path" ]] && new_array+=("$item")
	done
	path_array=("${new_array[@]}")
	update_path
}

# Function to list all paths
list_paths() {
	printf "%s\n" "${path_array[@]}"
}

# Initialize PATH
update_path

# Ensure DISPLAY is properly set for X11 applications
# Only set if not already properly configured
if [ -z "$DISPLAY" ] || { [ "$DISPLAY" != ":0" ] && [ "$DISPLAY" != ":0.0" ]; }; then
	# Check if X11 is running
	if [ "$XDG_SESSION_TYPE" = "x11" ] || pgrep -x "Xorg" >/dev/null 2>&1; then
		export DISPLAY=":0"
	fi
fi

# Environment variables that should be available to all applications
# STOW_DIR: Path to the directory containing dotfiles
export STOW_DIR="$HOME/dotfiles"

# Detect AUR wrapper
if command -v yay &>/dev/null; then
	export aurhelper="yay"
elif command -v paru &>/dev/null; then
	export aurhelper="paru"
fi

# Export PATH for systemd and other non-shell processes
# This ensures the PATH is available to applications launched from GUI
systemctl --user import-environment PATH 2>/dev/null || true

# Essential environment variables
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
export VISUAL="nvim"

# XDG Base Directory Specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CONFIG_DIR="${XDG_CONFIG_DIR:-$HOME/.config}" # Non-standard, but used by some apps
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# XDG Base Directory Specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CONFIG_DIR="${XDG_CONFIG_DIR:-$HOME/.config}" # Non-standard, but used by some apps
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# XDG User Directories
export XDG_DESKTOP_DIR="${XDG_DESKTOP_DIR:-$HOME/Desktop}"
export XDG_DOWNLOAD_DIR="${XDG_DOWNLOAD_DIR:-$HOME/Downloads}"
export XDG_TEMPLATES_DIR="${XDG_TEMPLATES_DIR:-$HOME/Templates}"
export XDG_PUBLICSHARE_DIR="${XDG_PUBLICSHARE_DIR:-$HOME/Public}"
export XDG_DOCUMENTS_DIR="${XDG_DOCUMENTS_DIR:-$HOME/Documents}"
export XDG_MUSIC_DIR="${XDG_MUSIC_DIR:-$HOME/Music}"
export XDG_PICTURES_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}"
export XDG_VIDEOS_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}"

# Application-specific settings
export MANPAGER="sh -c 'col -bx | bat -l man -p --color always'"
export MANROFFOPT="-c"
export WGETRC="${XDG_CONFIG_HOME}/wgetrc"
export PARALLEL_HOME="$XDG_CONFIG_HOME"/parallel
export SCREENRC="$XDG_CONFIG_HOME"/screen/screenrc
export WGPU_BACKEND=gl
export BAT_THEME="ansi"
export BAT_PAGER="less -RF"

firewall=$(command -v ufw || command -v firewalld || command -v iptables || command -v nftables || command -v pfctl || echo "none")
export OS_FIREWALL="$firewall"

# FZF configuration
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="--height 80% \
  --layout=reverse \
  --border \
  --preview 'bat --color=always --style=numbers --line-range=:500 {}' \
  --preview-window=right:60% \
  --bind 'ctrl-/:change-preview-window(down|hidden|)' "
chrome_path=$(which chromium || which chrome)
export CHROME_EXECUTABLE="$chrome_path"

# Android development environment
export ANDROID_HOME="$HOME/Android/Sdk/"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
