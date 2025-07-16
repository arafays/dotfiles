#!/bin/bash

# Script Removal Tool
# Safely removes scripts with dependency checking and audit logging

set -eo pipefail

# Configuration
SCRIPTS_DIR="${1:-$(dirname "$(dirname "$(realpath "$0")")")}"
CLASSIFICATION_FILE="${2:-/tmp/script-classification.json}"
OUTPUT_LOG="${3:-/tmp/script-removal.log}"
DRY_RUN="${DRY_RUN:-0}"
FORCE="${FORCE:-0}"
VERBOSE="${VERBOSE:-0}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

    if ! command -v jq >/dev/null 2>&1; then
        missing_tools+=("jq")
    fi

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log "ERROR" "Missing required tools: ${missing_tools[*]}"
        log "ERROR" "Please install missing tools and try again"
        exit 1
    fi
}

# Function to validate input files
validate_input_files() {
    if [[ ! -f "$CLASSIFICATION_FILE" ]]; then
        log "ERROR" "Classification file not found: $CLASSIFICATION_FILE"
        log "ERROR" "Please run script-classifier.sh first"
        exit 1
    fi

    if ! jq empty "$CLASSIFICATION_FILE" 2>/dev/null; then
        log "ERROR" "Invalid JSON in classification file: $CLASSIFICATION_FILE"
        exit 1
    fi
}

# Function to check configuration file dependencies
check_config_dependencies() {
    local script_name="$1"
    local script_basename
    script_basename=$(basename "$script_name" .sh)

    local config_dirs=(
        "hypr/.config/hypr"
        "hypr/.config/waybar"
        "hypr/.config/dunst"
        "zsh"
        "tmux"
    )

    local dependencies=()

    # Search for references in configuration files
    for config_dir in "${config_dirs[@]}"; do
        [[ ! -d "$config_dir" ]] && continue

        local refs
        refs=$(grep -r -l "$script_basename" "$config_dir" 2>/dev/null || true)

        if [[ -n "$refs" ]]; then
            while IFS= read -r ref_file; do
                [[ -n "$ref_file" ]] && dependencies+=("$ref_file")
            done <<< "$refs"
        fi
    done

    # Return dependencies as JSON array
    printf '%s\n' "${dependencies[@]}" | jq -R . | jq -s .
}

# Function to check script-to-script dependencies
check_script_dependencies() {
    local script_path="$1"
    local script_name
    script_name=$(basename "$script_path")
    local script_basename="${script_name%.*}"

    local dependencies=()

    # Search for references to this script in other scripts
    local refs
    refs=$(grep -r -l "$script_basename" "$SCRIPTS_DIR" 2>/dev/null | grep -v "$script_path" || true)

    if [[ -n "$refs" ]]; then
        while IFS= read -r ref_file; do
            [[ -n "$ref_file" ]] && dependencies+=("${ref_file#$SCRIPTS_DIR/}")
        done <<< "$refs"
    fi

    # Return dependencies as JSON array
    printf '%s\n' "${dependencies[@]}" | jq -R . | jq -s .
}

# Function to create backup before removal
create_backup() {
    local script_path="$1"
    local backup_dir="/tmp/script-removal-backup-$(date +%Y%m%d-%H%M%S)"

    # Create backup directory if it doesn't exist
    mkdir -p "$backup_dir"

    # Copy script to backup
    local backup_path="$backup_dir/$(basename "$script_path")"
    cp "$script_path" "$backup_path"

    log "INFO" "Created backup: $backup_path"
    echo "$backup_path"
}

# Function to safely remove a single script
remove_script() {
    local script_path="$1"
    local script_name
    script_name=$(basename "$script_path")
    local relative_path="${script_path#$SCRIPTS_DIR/}"

    log "INFO" "Processing removal of: $relative_path"

    # Check if script exists
    if [[ ! -f "$script_path" ]]; then
        log "WARN" "Script not found, skipping: $script_path"
        return 0
    fi

    # Check configuration dependencies
    local config_deps script_deps
    config_deps=$(check_config_dependencies "$script_name")
    script_deps=$(check_script_dependencies "$script_path")

    local config_count script_count
    config_count=$(echo "$config_deps" | jq 'length')
    script_count=$(echo "$script_deps" | jq 'length')

    # Verify it's safe to remove
    if [[ $config_count -gt 0 ]] && [[ "$FORCE" -eq 0 ]]; then
        log "ERROR" "Cannot remove $relative_path - referenced in $config_count configuration files:"
        echo "$config_deps" | jq -r '.[]' | while read -r dep; do
            log "ERROR" "  - $dep"
        done
        return 1
    fi

    if [[ $script_count -gt 0 ]] && [[ "$FORCE" -eq 0 ]]; then
        log "ERROR" "Cannot remove $relative_path - referenced by $script_count other scripts:"
        echo "$script_deps" | jq -r '.[]' | while read -r dep; do
            log "ERROR" "  - $dep"
        done
        return 1
    fi

    # Create backup before removal
    local backup_path
    backup_path=$(create_backup "$script_path")

    # Log removal details
    log "INFO" "Removing script: $relative_path"
    log "INFO" "  Reason: Safe to remove (no active dependencies)"
    log "INFO" "  Config dependencies: $config_count"
    log "INFO" "  Script dependencies: $script_count"
    log "INFO" "  Backup created: $backup_path"

    # Perform removal (unless dry run)
    if [[ "$DRY_RUN" -eq 1 ]]; then
        log "INFO" "[DRY RUN] Would remove: $script_path"
    else
        rm "$script_path"
        log "INFO" "Successfully removed: $script_path"
    fi

    return 0
}

# Function to process all scripts marked for removal
process_removals() {
    log "INFO" "Starting script removal process..."

    # Get scripts marked for removal from classification
    local removal_scripts
    removal_scripts=$(jq -r '.classifications[] | select(.action == "remove") | .script_path' "$CLASSIFICATION_FILE")

    if [[ -z "$removal_scripts" ]]; then
        log "INFO" "No scripts marked for removal"
        return 0
    fi

    local total_count=0
    local success_count=0
    local error_count=0

    # Process each script
    while IFS= read -r script_path; do
        [[ -z "$script_path" ]] && continue

        ((total_count++))

        if remove_script "$script_path"; then
            ((success_count++))
        else
            ((error_count++))
        fi

    done <<< "$removal_scripts"

    # Log summary
    log "INFO" "Removal process completed:"
    log "INFO" "  Total scripts processed: $total_count"
    log "INFO" "  Successfully removed: $success_count"
    log "INFO" "  Errors encountered: $error_count"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log "INFO" "This was a dry run - no files were actually removed"
    fi
}

# Function to display removal preview
show_removal_preview() {
    log "INFO" "Scripts marked for removal:"

    local removal_scripts
    removal_scripts=$(jq -r '.classifications[] | select(.action == "remove")' "$CLASSIFICATION_FILE")

    if [[ -z "$removal_scripts" ]]; then
        log "INFO" "No scripts marked for removal"
        return 0
    fi

    echo "$removal_scripts" | jq -r '"  - \(.relative_path) (\(.reason))"' | while read -r line; do
        log "INFO" "$line"
    done
}

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [SCRIPTS_DIR] [CLASSIFICATION_FILE] [OUTPUT_LOG]

Script Removal Tool - Safely removes scripts with dependency checking

Arguments:
    SCRIPTS_DIR         Scripts directory (default: parent of this script's directory)
    CLASSIFICATION_FILE Classification JSON file (default: /tmp/script-classification.json)
    OUTPUT_LOG          Removal log file (default: /tmp/script-removal.log)

Environment Variables:
    DRY_RUN=1          Preview removals without actually deleting files
    FORCE=1            Force removal even if dependencies exist (dangerous!)
    VERBOSE=1          Enable verbose debug output

Examples:
    $0                                    # Remove scripts using default files
    DRY_RUN=1 $0                         # Preview what would be removed
    $0 /path/to/scripts classification.json removal.log
    FORCE=1 $0                           # Force removal (use with caution!)

Prerequisites:
    - Run script-classifier.sh to generate classification data

Safety Features:
    - Dependency checking before removal
    - Automatic backup creation
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
    echo "Script Removal Log - Started at $(date)" > "$OUTPUT_LOG"

    # Check dependencies
    check_dependencies

    # Validate scripts directory
    if [[ ! -d "$SCRIPTS_DIR" ]]; then
        log "ERROR" "Scripts directory does not exist: $SCRIPTS_DIR"
        exit 1
    fi

    # Validate input files
    validate_input_files

    log "INFO" "Starting script removal tool..."
    log "INFO" "Scripts directory: $SCRIPTS_DIR"
    log "INFO" "Classification file: $CLASSIFICATION_FILE"
    log "INFO" "Output log: $OUTPUT_LOG"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log "INFO" "DRY RUN MODE - No files will be actually removed"
    fi

    if [[ "$FORCE" -eq 1 ]]; then
        log "WARN" "FORCE MODE - Dependencies will be ignored (use with caution!)"
    fi

    # Show preview of what will be removed
    show_removal_preview

    # Process removals
    process_removals

    log "INFO" "Script removal tool completed"
    log "INFO" "Full log available at: $OUTPUT_LOG"
}

# Run main function
main "$@"