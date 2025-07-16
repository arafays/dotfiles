#!/bin/bash

# Configuration File Updater
# Updates configuration files that reference removed or updated scripts

set -eo pipefail

# Configuration
SCRIPTS_DIR="${1:-$(dirname "$(dirname "$(realpath "$0")")")}"
REMOVAL_LOG="${2:-/tmp/script-removal.log}"
UPDATE_LOG="${3:-/tmp/script-updates.log}"
OUTPUT_LOG="${4:-/tmp/config-updates.log}"
DRY_RUN="${DRY_RUN:-0}"
VERBOSE="${VERBOSE:-0}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration directories and files to check
declare -A CONFIG_FILES=(
    ["hypr/.config/hypr/hyprland.conf"]="hyprland_main"
    ["hypr/.config/hypr/keybindings.conf"]="hyprland_keybindings"
    ["hypr/.config/hypr/autostart.conf"]="hyprland_autostart"
    ["hypr/.config/waybar/config.jsonc"]="waybar_config"
    ["hypr/.config/waybar/config"]="waybar_config_alt"
    ["zsh/.zshrc"]="zsh_config"
    ["tmux/.tmux.conf"]="tmux_config"
)

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case "$level" in
        "INFO")  echo -e "${GREEN}[INFO]${NC} $message" >&2 ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $message" >&2 ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" >&2 ;;
        "DEBUG") [[ "$VERBOSE" -eq 1 ]] && echo -e "${BLUE}[DEBUG]${NC} $message" >&2 ;;
    esac

    # Also log to file with timestamp
    echo "[$timestamp] [$level] $message" >> "$OUTPUT_LOG"
}

# Function to check if required tools are available
check_dependencies() {
    local missing_tools=()

    if ! command -v sed >/dev/null 2>&1; then
        missing_tools+=("sed")
    fi

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log "ERROR" "Missing required tools: ${missing_tools[*]}"
        log "ERROR" "Please install missing tools and try again"
        exit 1
    fi
}

# Function to extract removed scripts from removal log
get_removed_scripts() {
    local removed_scripts=()

    if [[ -f "$REMOVAL_LOG" ]]; then
        # Extract script names from removal log
        while IFS= read -r line; do
            if [[ "$line" =~ "Successfully removed:" ]]; then
                local script_path
                script_path=$(echo "$line" | sed 's/.*Successfully removed: //')
                local script_name
                script_name=$(basename "$script_path")
                removed_scripts+=("$script_name")
            fi
        done < "$REMOVAL_LOG"
    fi

    printf '%s\n' "${removed_scripts[@]}"
}

# Function to extract updated scripts from update log
get_updated_scripts() {
    local updated_scripts=()

    if [[ -f "$UPDATE_LOG" ]]; then
        # Extract script names from update log
        while IFS= read -r line; do
            if [[ "$line" =~ "Successfully updated:" ]]; then
                local script_path
                script_path=$(echo "$line" | sed 's/.*Successfully updated: //')
                local script_name
                script_name=$(basename "$script_path")
                updated_scripts+=("$script_name")
            fi
        done < "$UPDATE_LOG"
    fi

    printf '%s\n' "${updated_scripts[@]}"
}

# Function to create backup of configuration file
create_config_backup() {
    local config_file="$1"
    local backup_dir="/tmp/config-update-backup-$(date +%Y%m%d-%H%M%S)"

    # Create backup directory if it doesn't exist
    mkdir -p "$backup_dir"

    # Copy config file to backup
    local backup_path="$backup_dir/$(basename "$config_file")"
    cp "$config_file" "$backup_path"

    log "INFO" "Created config backup: $backup_path"
    echo "$backup_path"
}

# Function to update Hyprland configuration files
update_hyprland_config() {
    local config_file="$1"
    local config_type="$2"
    local removed_scripts=("${@:3}")

    local changes_made=0
    local temp_file
    temp_file=$(mktemp)

    # Copy original to temp file
    cp "$config_file" "$temp_file"

    log "DEBUG" "Updating Hyprland config: $config_file"

    # Process each removed script
    for script_name in "${removed_scripts[@]}"; do
        local script_basename="${script_name%.*}"

        # Look for references to this script
        if grep -q "$script_basename" "$temp_file"; then
            log "INFO" "Found reference to removed script '$script_basename' in $config_file"

            case "$config_type" in
                "hyprland_keybindings")
                    # Comment out keybinding lines that reference removed scripts
                    if sed -i "s/^bind.*$script_basename.*$/# REMOVED: &/" "$temp_file"; then
                        ((changes_made++))
                        log "INFO" "Commented out keybinding for: $script_basename"
                    fi
                    ;;
                "hyprland_autostart")
                    # Comment out autostart lines that reference removed scripts
                    if sed -i "s/^exec.*$script_basename.*$/# REMOVED: &/" "$temp_file"; then
                        ((changes_made++))
                        log "INFO" "Commented out autostart for: $script_basename"
                    fi
                    ;;
                "hyprland_main")
                    # Update script path variables if they reference removed scripts
                    if sed -i "s|\$scrPath/$script_basename|# REMOVED: &|g" "$temp_file"; then
                        ((changes_made++))
                        log "INFO" "Updated script path reference for: $script_basename"
                    fi
                    ;;
            esac
        fi
    done

    # Apply changes if any were made
    if [[ $changes_made -gt 0 ]]; then
        # Add update comment
        local update_comment="# CONFIG UPDATED: $(date '+%Y-%m-%d %H:%M:%S') - Removed $changes_made script references"
        echo "$update_comment" >> "$temp_file"

        if [[ "$DRY_RUN" -eq 1 ]]; then
            log "INFO" "[DRY RUN] Would update: $config_file ($changes_made changes)"
        else
            cp "$temp_file" "$config_file"
            log "INFO" "Updated: $config_file ($changes_made changes)"
        fi
    else
        log "DEBUG" "No changes needed for: $config_file"
    fi

    # Clean up temp file
    rm "$temp_file"

    return $changes_made
}

# Function to update Waybar configuration files
update_waybar_config() {
    local config_file="$1"
    local removed_scripts=("${@:2}")

    local changes_made=0
    local temp_file
    temp_file=$(mktemp)

    # Copy original to temp file
    cp "$config_file" "$temp_file"

    log "DEBUG" "Updating Waybar config: $config_file"

    # Process each removed script
    for script_name in "${removed_scripts[@]}"; do
        local script_basename="${script_name%.*}"

        # Look for references to this script in JSON/JSONC format
        if grep -q "$script_basename" "$temp_file"; then
            log "INFO" "Found reference to removed script '$script_basename' in $config_file"

            # Comment out or remove JSON entries that reference removed scripts
            # This is more complex for JSON, so we'll use a conservative approach
            if sed -i "s/\".*$script_basename.*\"/\"# REMOVED: &\"/g" "$temp_file"; then
                ((changes_made++))
                log "INFO" "Updated Waybar reference for: $script_basename"
            fi
        fi
    done

    # Apply changes if any were made
    if [[ $changes_made -gt 0 ]]; then
        # Add update comment (JSON comment style)
        local update_comment="// CONFIG UPDATED: $(date '+%Y-%m-%d %H:%M:%S') - Removed $changes_made script references"
        echo "$update_comment" >> "$temp_file"

        if [[ "$DRY_RUN" -eq 1 ]]; then
            log "INFO" "[DRY RUN] Would update: $config_file ($changes_made changes)"
        else
            cp "$temp_file" "$config_file"
            log "INFO" "Updated: $config_file ($changes_made changes)"
        fi
    else
        log "DEBUG" "No changes needed for: $config_file"
    fi

    # Clean up temp file
    rm "$temp_file"

    return $changes_made
}

# Function to update shell configuration files
update_shell_config() {
    local config_file="$1"
    local removed_scripts=("${@:2}")

    local changes_made=0
    local temp_file
    temp_file=$(mktemp)

    # Copy original to temp file
    cp "$config_file" "$temp_file"

    log "DEBUG" "Updating shell config: $config_file"

    # Process each removed script
    for script_name in "${removed_scripts[@]}"; do
        local script_basename="${script_name%.*}"

        # Look for references to this script
        if grep -q "$script_basename" "$temp_file"; then
            log "INFO" "Found reference to removed script '$script_basename' in $config_file"

            # Comment out lines that reference removed scripts
            if sed -i "s/^.*$script_basename.*$/# REMOVED: &/" "$temp_file"; then
                ((changes_made++))
                log "INFO" "Commented out shell reference for: $script_basename"
            fi
        fi
    done

    # Apply changes if any were made
    if [[ $changes_made -gt 0 ]]; then
        # Add update comment
        local update_comment="# CONFIG UPDATED: $(date '+%Y-%m-%d %H:%M:%S') - Removed $changes_made script references"
        echo "$update_comment" >> "$temp_file"

        if [[ "$DRY_RUN" -eq 1 ]]; then
            log "INFO" "[DRY RUN] Would update: $config_file ($changes_made changes)"
        else
            cp "$temp_file" "$config_file"
            log "INFO" "Updated: $config_file ($changes_made changes)"
        fi
    else
        log "DEBUG" "No changes needed for: $config_file"
    fi

    # Clean up temp file
    rm "$temp_file"

    return $changes_made
}

# Function to update a single configuration file
update_config_file() {
    local config_file="$1"
    local config_type="$2"
    local removed_scripts=("${@:3}")

    # Check if config file exists
    if [[ ! -f "$config_file" ]]; then
        log "DEBUG" "Config file not found, skipping: $config_file"
        return 0
    fi

    log "INFO" "Processing config file: $config_file"

    # Create backup before updating
    local backup_path
    backup_path=$(create_config_backup "$config_file")

    # Update based on config type
    local changes_count=0
    case "$config_type" in
        hyprland_*)
            changes_count=$(update_hyprland_config "$config_file" "$config_type" "${removed_scripts[@]}")
            ;;
        waybar_*)
            changes_count=$(update_waybar_config "$config_file" "${removed_scripts[@]}")
            ;;
        *_config)
            changes_count=$(update_shell_config "$config_file" "${removed_scripts[@]}")
            ;;
        *)
            log "WARN" "Unknown config type: $config_type"
            return 0
            ;;
    esac

    if [[ $changes_count -gt 0 ]]; then
        log "INFO" "Successfully updated: $config_file ($changes_count changes)"
        log "INFO" "  Backup created: $backup_path"
    else
        log "DEBUG" "No changes needed for: $config_file"
    fi

    return $changes_count
}

# Function to process all configuration files
process_config_updates() {
    log "INFO" "Starting configuration file update process..."

    # Get list of removed scripts
    local removed_scripts=()
    mapfile -t removed_scripts < <(get_removed_scripts)

    if [[ ${#removed_scripts[@]} -eq 0 ]]; then
        log "INFO" "No removed scripts found - checking for updated scripts"

        # If no removed scripts, check for updated scripts that might need config updates
        mapfile -t removed_scripts < <(get_updated_scripts)

        if [[ ${#removed_scripts[@]} -eq 0 ]]; then
            log "INFO" "No scripts to process for configuration updates"
            return 0
        fi
    fi

    log "INFO" "Processing configuration updates for ${#removed_scripts[@]} scripts:"
    printf '  - %s\n' "${removed_scripts[@]}" >&2

    local total_configs=0
    local updated_configs=0
    local total_changes=0

    # Process each configuration file
    for config_file in "${!CONFIG_FILES[@]}"; do
        local config_type="${CONFIG_FILES[$config_file]}"

        ((total_configs++))

        local changes
        if changes=$(update_config_file "$config_file" "$config_type" "${removed_scripts[@]}"); then
            if [[ $changes -gt 0 ]]; then
                ((updated_configs++))
                ((total_changes += changes))
            fi
        else
            log "WARN" "Failed to update config file: $config_file"
        fi
    done

    # Log summary
    log "INFO" "Configuration update process completed:"
    log "INFO" "  Total config files processed: $total_configs"
    log "INFO" "  Config files updated: $updated_configs"
    log "INFO" "  Total changes made: $total_changes"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log "INFO" "This was a dry run - no files were actually modified"
    fi
}

# Function to display update preview
show_config_preview() {
    log "INFO" "Configuration files to be checked:"

    for config_file in "${!CONFIG_FILES[@]}"; do
        local config_type="${CONFIG_FILES[$config_file]}"
        if [[ -f "$config_file" ]]; then
            log "INFO" "  - $config_file ($config_type)"
        else
            log "DEBUG" "  - $config_file ($config_type) [NOT FOUND]"
        fi
    done
}

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [SCRIPTS_DIR] [REMOVAL_LOG] [UPDATE_LOG] [OUTPUT_LOG]

Configuration File Updater - Updates config files that reference removed scripts

Arguments:
    SCRIPTS_DIR   Scripts directory (default: parent of this script's directory)
    REMOVAL_LOG   Script removal log file (default: /tmp/script-removal.log)
    UPDATE_LOG    Script update log file (default: /tmp/script-updates.log)
    OUTPUT_LOG    Config update log file (default: /tmp/config-updates.log)

Environment Variables:
    DRY_RUN=1     Preview updates without actually modifying files
    VERBOSE=1     Enable verbose debug output

Examples:
    $0                                    # Update configs using default files
    DRY_RUN=1 $0                         # Preview what would be updated
    $0 /path/to/scripts removal.log update.log config.log
    VERBOSE=1 $0                         # Update with verbose output

Prerequisites:
    - Run script-remover.sh or script-updater.sh to generate logs

Configuration Files Processed:
    - Hyprland: hyprland.conf, keybindings.conf, autostart.conf
    - Waybar: config.jsonc, config
    - Shell: .zshrc
    - Tmux: .tmux.conf

Safety Features:
    - Automatic backup creation before updates
    - Conservative update approach (commenting out rather than deleting)
    - Comprehensive audit logging
    - Dry run mode for preview

EOF
}

# Main execution
main() {
    # Check for help flag
    if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
        usage
        exit 0
    fi

    # Initialize log file
    mkdir -p "$(dirname "$OUTPUT_LOG")"
    echo "Configuration Update Log - Started at $(date)" > "$OUTPUT_LOG"

    # Check dependencies
    check_dependencies

    # Validate scripts directory
    if [[ ! -d "$SCRIPTS_DIR" ]]; then
        log "ERROR" "Scripts directory does not exist: $SCRIPTS_DIR"
        exit 1
    fi

    log "INFO" "Starting configuration file updater..."
    log "INFO" "Scripts directory: $SCRIPTS_DIR"
    log "INFO" "Removal log: $REMOVAL_LOG"
    log "INFO" "Update log: $UPDATE_LOG"
    log "INFO" "Output log: $OUTPUT_LOG"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log "INFO" "DRY RUN MODE - No files will be actually modified"
    fi

    # Show preview of what will be processed
    show_config_preview

    # Process configuration updates
    process_config_updates

    log "INFO" "Configuration file updater completed"
    log "INFO" "Full log available at: $OUTPUT_LOG"
}

# Run main function
main "$@"