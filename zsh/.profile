# Define an array to manage PATH entries
path_array=(
	"$HOME/.local/bin"
	"$HOME/Android/Sdk/tools"
	"$HOME/Android/Sdk/platform-tools"
	"$HOME/Android/Sdk/emulator"
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
	if [[ -d "$new_path" && ! " ${path_array[*]} " =~ " $new_path " ]]; then
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

# Essential environment variables
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
export VISUAL="nvim"
export BROWSER="zen-browser"
export STOW_DIR="$HOME/dotfiles"

# Android development environment
export ANDROID_HOME="$HOME/Android/Sdk/"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
