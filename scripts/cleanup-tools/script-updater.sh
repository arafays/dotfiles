#!/bin/bash

# Script Updater Utility
# Updates scripts to remove Hyde references while preserving functionality

set -eo pipefail

# Configuration
SCRIPTS_DIR="${1:-$(dirname "$(dirname "$(realpath "$0")")")}"
CLASSIFICATION_FILE="${2:-/tmp/script-classification.json}"
HYDE_DATA="${3:-/tmp/hyde-references.json}"
OUTPUT_LOG="${4:-/tmp/script-updates.log}"
DRY_RUN="${DRY_RUN:-0}"
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

    if ! command -v sed >/dev/null 2>&1; then
        missing_tools+=("sed")
    fi

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log "ERROR" "Missing required tools: ${missing_tools[*]}"
        log "ERROR" "Please install missing tools and try again"
        exit 1
    fi
}

# Function to validate input files
validate_input_files() {
    local files=("$CLASSIFICATION_FILE" "$HYDE_DATA")
    local file_names=("classification file" "Hyde references file")

    for i in "${!files[@]}"; do
        local file="${files[i]}"
        local name="${file_names[i]}"

        if [[ ! -f "$file" ]]; then
            log "ERROR" "Missing $name: $file"
            log "ERROR" "Please run the analysis tools first"
            exit 1
        fi

        if ! jq empty "$file" 2>/dev/null; then
            log "ERROR" "Invalid JSON in $name: $file"
            exit 1
        fi
    done
}

# Function to create backup before updating
create_backup() {
    local script_path="$1"
    local backup_dir="/tmp/script-update-backup-$(date +%Y%m%d-%H%M%S)"

    # Create backup directory if it doesn't exist
    mkdir -p "$backup_dir"

    # Copy script to backup
    local backup_path="$backup_dir/$(basename "$script_path")"
    cp "$script_path" "$backup_path"

    log "INFO" "Created backup: $backup_path"
    echo "$backup_path"
}

# Function to get Hyde references for a specific script
get_script_hyde_references() {
    local script_path="$1"
    local relative_path="${script_path#$SCRIPTS_DIR/}"

    jq -r --arg path "$relative_path" '
        .files[] | select(.relative_path == $path) | .references[]
    ' "$HYDE_DATA" 2>/dev/null || echo ""
}

# Function to generate replacement patterns for Hyde references
generate_replacement_patterns() {
    local pattern_type="$1"
    local match="$2"
    local criticality="$3"

    case "$pattern_type" in
        "directory")
            case "$match" in
                "hydeThemeDir")
                    echo "s/\$hydeThemeDir/\$HOME\/.config\/themes/g"
                    echo "s/\${hydeThemeDir}/\${HOME}\/.config\/themes/g"
                    ;;
                "hydeConfDir")
                    echo "s/\$hydeConfDir/\$HOME\/.config/g"
                    echo "s/\${hydeConfDir}/\${HOME}\/.config/g"
                    ;;
            esac
            ;;
        "variable")
            case "$match" in
                "hydeTheme")
                    echo "s/\$hydeTheme/default/g"
                    echo "s/\${hydeTheme}/default/g"
                    ;;
            esac
            ;;
        "path")
            case "$match" in
                "/hyde/")
                    echo "s|/hyde/|/themes/|g"
                    ;;
                "/.hyde/")
                    echo "s|/\.hyde/|/.config/themes/|g"
                    ;;
            esac
            ;;
        "config")
            case "$match" in
                "hyde.conf")
                    echo "s/hyde\.conf/theme.conf/g"
                    ;;
                "hypr.theme")
                    echo "s/hypr\.theme/theme.conf/g"
                    ;;
            esac
            ;;
        "reference")
            # For general Hyde references, comment them out or replace with generic terms
            echo "s/Hyde/Theme/g"
            echo "s/HYDE/THEME/g"
            ;;
    esac
}

# Function to apply updates to a script file
apply_script_updates() {
    local script_path="$1"
    local temp_file
    temp_file=$(mktemp)
    local changes_made=0

    # Copy original to temp file
    cp "$script_path" "$temp_file"

    # Get Hyde references for this script
    local hyde_refs
    hyde_refs=$(get_script_hyde_references "$script_path")

    if [[ -z "$hyde_refs" ]]; then
        log "DEBUG" "No Hyde references found for: $(basename "$script_path")"
        rm "$temp_file"
        return 0
    fi

    # Process each Hyde reference
    while IFS= read -r ref_line; do
        [[ -z "$ref_line" ]] && continue

        local pattern_type match criticality line_number
        pattern_type=$(echo "$ref_line" | jq -r '.pattern_type')
        match=$(echo "$ref_line" | jq -r '.match')
        criticality=$(echo "$ref_line" | jq -r '.criticality')
        line_number=$(echo "$ref_line" | jq -r '.line_number')

        log "DEBUG" "Processing $criticality $pattern_type reference: $match at line $line_number"

        # Generate replacement patterns
        local replacements
        replacements=$(generate_replacement_patterns "$pattern_type" "$match" "$criticality")

        # Apply each replacement pattern
        while IFS= read -r sed_pattern; do
            [[ -z "$sed_pattern" ]] && continue

            # Apply sed pattern to temp file
            if sed -i "$sed_pattern" "$temp_file" 2>/dev/null; then
                log "DEBUG" "Applied pattern: $sed_pattern"
                ((changes_made++))
            else
                log "WARN" "Failed to apply pattern: $sed_pattern"
            fi
        done <<< "$replacements"

    done <<< "$hyde_refs"

    # Add documentation comment at the top if changes were made
    if [[ $changes_made -gt 0 ]]; then
        local header_comment
        header_comment="# UPDATED: $(date '+%Y-%m-%d %H:%M:%S') - Removed $changes_made Hyde references"

        # Add comment after shebang line
        if head -1 "$temp_file" | grep -q "^#!"; then
            # Insert after shebang
            sed -i "1a\\$header_comment" "$temp_file"
        else
            # Insert at beginning
            sed -i "1i\\$header_comment" "$temp_file"
        fi

        log "INFO" "Applied $changes_made updates to: $(basename "$script_path")"

        # Replace original file with updated version (unless dry run)
        if [[ "$DRY_RUN" -eq 1 ]]; then
            log "INFO" "[DRY RUN] Would update: $script_path"
            log "DEBUG" "[DRY RUN] Changes preview:"
            diff -u "$script_path" "$temp_file" | head -20 >&2 || true
        else
            cp "$temp_file" "$script_path"
            log "INFO" "Successfully updated: $script_path"
        fi
    else
        log "DEBUG" "No changes applied to: $(basename "$script_path")"
    fi

    # Clean up temp file
    rm "$temp_file"

    return $changes_made
}

# Function to validate updated script syntax
validate_script_syntax() {
    local script_path="$1"
    local script_name
    script_name=$(basename "$script_path")

    # Check if it's a shell script
    if [[ "$script_name" == *.sh ]] || head -1 "$script_path" | grep -q "bash\|sh"; then
        if bash -n "$script_path" 2>/dev/null; then
            log "DEBUG" "Syntax validation passed: $script_name"
            return 0
        else
            log "ERROR" "Syntax validation failed: $script_name"
            return 1
        fi
    fi

    # Check if it's a Python script
    if [[ "$script_name" == *.py ]] || head -1 "$script_path" | grep -q "python"; then
        if command -v python3 >/dev/null 2>&1; then
            if python3 -m py_compile "$script_path" 2>/dev/null; then
                log "DEBUG" "Python syntax validation passed: $script_name"
                return 0
            else
                log "ERROR" "Python syntax validation failed: $script_name"
                return 1
            fi
        else
            log "WARN" "Python not available for syntax validation: $script_name"
            return 0
        fi
    fi

    # For other file types, just check if it's readable
    if [[ -r "$script_path" ]]; then
        log "DEBUG" "Basic validation passed: $script_name"
        return 0
    else
        log "ERROR" "File not readable: $script_name"
        return 1
    fi
}

# Function to update a single script
update_script() {
    local script_path="$1"
    local relative_path="${script_path#$SCRIPTS_DIR/}"

    log "INFO" "Processing update for: $relative_path"

    # Check if script exists
    if [[ ! -f "$script_path" ]]; then
        log "WARN" "Script not found, skipping: $script_path"
        return 1
    fi

    # Create backup before updating
    local backup_path
    backup_path=$(create_backup "$script_path")

    # Apply updates
    local changes_count
    if changes_count=$(apply_script_updates "$script_path"); then
        if [[ $changes_count -gt 0 ]]; then
            # Validate syntax after updates
            if validate_script_syntax "$script_path"; then
                log "INFO" "Successfully updated and validated: $relative_path"
                log "INFO" "  Changes applied: $changes_count"
                log "INFO" "  Backup created: $backup_path"
                return 0
            else
                log "ERROR" "Syntax validation failed after update: $relative_path"
                log "INFO" "Restoring from backup: $backup_path"

                # Restore from backup if not dry run
                if [[ "$DRY_RUN" -eq 0 ]]; then
                    cp "$backup_path" "$script_path"
                fi
                return 1
            fi
        else
            log "INFO" "No changes needed for: $relative_path"
            return 0
        fi
    else
        log "ERROR" "Failed to apply updates to: $relative_path"
        return 1
    fi
}

# Function to process all scripts marked for update
process_updates() {
    log "INFO" "Starting script update process..."

    # Get scripts marked for update from classification
    local update_scripts
    update_scripts=$(jq -r '.classifications[] | select(.action == "update") | .script_path' "$CLASSIFICATION_FILE")

    if [[ -z "$update_scripts" ]]; then
        log "INFO" "No scripts marked for update"
        return 0
    fi

    local total_count=0
    local success_count=0
    local error_count=0

    # Process each script
    while IFS= read -r script_path; do
        [[ -z "$script_path" ]] && continue

        ((total_count++))

        if update_script "$script_path"; then
            ((success_count++))
        else
            ((error_count++))
        fi

    done <<< "$update_scripts"

    # Log summary
    log "INFO" "Update process completed:"
    log "INFO" "  Total scripts processed: $total_count"
    log "INFO" "  Successfully updated: $success_count"
    log "INFO" "  Errors encountered: $error_count"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log "INFO" "This was a dry run - no files were actually modified"
    fi
}

# Function to display update preview
show_update_preview() {
    log "INFO" "Scripts marked for update:"

    local update_scripts
    update_scripts=$(jq -r '.classifications[] | select(.action == "update")' "$CLASSIFICATION_FILE")

    if [[ -z "$update_scripts" ]]; then
        log "INFO" "No scripts marked for update"
        return 0
    fi

    echo "$update_scripts" | jq -r '"  - \(.relative_path) (\(.reason))"' | while read -r line; do
        log "INFO" "$line"
    done
}

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [SCRIPTS_DIR] [CLASSIFICATION_FILE] [HYDE_DATA] [OUTPUT_LOG]

Script Updater Utility - Updates scripts to remove Hyde references

Arguments:
    SCRIPTS_DIR         Scripts directory (default: parent of this script's directory)
    CLASSIFICATION_FILE Classification JSON file (default: /tmp/script-classification.json)
    HYDE_DATA           Hyde references JSON file (default: /tmp/hyde-references.json)
    OUTPUT_LOG          Update log file (default: /tmp/script-updates.log)

Environment Variables:
    DRY_RUN=1          Preview updates without actually modifying files
    VERBOSE=1          Enable verbose debug output

Examples:
    $0                                    # Update scripts using default files
    DRY_RUN=1 $0                         # Preview what would be updated
    $0 /path/to/scripts classification.json hyde-refs.json updates.log
    VERBOSE=1 $0                         # Update with verbose output

Prerequisites:
    - Run script-classifier.sh to generate classification data
    - Run hyde-detector.sh to generate Hyde reference data

Safety Features:
    - Automatic backup creation before updates
    - Syntax validation after updates
    - Rollback on validation failure
    - Comprehensive audit logging
    - Dry run mode for preview

Update Patterns:
    - hydeThemeDir -> \$HOME/.config/themes
    - hydeConfDir -> \$HOME/.config
    - hydeTheme -> default
    - /hyde/ -> /themes/
    - /.hyde/ -> /.config/themes/
    - hyde.conf -> theme.conf
    - Hyde -> Theme

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
    echo "Script Update Log - Started at $(date)" > "$OUTPUT_LOG"

    # Check dependencies
    check_dependencies

    # Validate scripts directory
    if [[ ! -d "$SCRIPTS_DIR" ]]; then
        log "ERROR" "Scripts directory does not exist: $SCRIPTS_DIR"
        exit 1
    fi

    # Validate input files
    validate_input_files

    log "INFO" "Starting script updater utility..."
    log "INFO" "Scripts directory: $SCRIPTS_DIR"
    log "INFO" "Classification file: $CLASSIFICATION_FILE"
    log "INFO" "Hyde data file: $HYDE_DATA"
    log "INFO" "Output log: $OUTPUT_LOG"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log "INFO" "DRY RUN MODE - No files will be actually modified"
    fi

    # Show preview of what will be updated
    show_update_preview

    # Process updates
    process_updates

    log "INFO" "Script updater utility completed"
    log "INFO" "Full log available at: $OUTPUT_LOG"
}

# Run main function
main "$@"