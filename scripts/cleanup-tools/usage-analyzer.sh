#!/bin/bash

# Usage Analysis Tool
# Determines which scripts are actively used by current configurations

set -eo pipefail

# Configuration
SCRIPTS_DIR="${1:-$(dirname "$(dirname "$(realpath "$0")")")}"
OUTPUT_FILE="${2:-/tmp/usage-analysis.json}"
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
    case "$level" in
        "INFO")  echo -e "${GREEN}[INFO]${NC} $*" >&2 ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $*" >&2 ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $*" >&2 ;;
        "DEBUG") [[ "$VERBOSE" -eq 1 ]] && echo -e "${BLUE}[DEBUG]${NC} $*" >&2 ;;
    esac
}

# Configuration directories to check for script references
declare -a CONFIG_DIRS=(
    "hypr/.config/hypr"
    "hypr/.config/waybar"
    "hypr/.config/dunst"
    "zsh"
    "tmux"
)

# Function to find script references in configuration files
find_config_references() {
    local script_name="$1"
    local references=()

    # Search in configuration directories
    for config_dir in "${CONFIG_DIRS[@]}"; do
        # Skip if config directory doesn't exist
        [[ ! -d "$config_dir" ]] && continue

        log "DEBUG" "Searching for '$script_name' in $config_dir"

        # Find references using grep
        local grep_results
        grep_results=$(grep -r -n "$script_name" "$config_dir" 2>/dev/null || true)

        if [[ -n "$grep_results" ]]; then
            while IFS=: read -r config_file line_num line_content; do
                [[ -z "$config_file" ]] && continue

                local ref_obj
                ref_obj=$(cat << EOF
{
    "config_file": "$config_file",
    "line_number": $line_num,
    "line_content": $(echo "$line_content" | jq -R .),
    "reference_type": "config"
}
EOF
)
                references+=("$ref_obj")
                log "DEBUG" "Found reference in $config_file:$line_num"
            done <<< "$grep_results"
        fi
    done

    # Output references array
    printf '%s\n' "${references[@]}"
}

# Function to check if script is in PATH and executable
check_path_accessibility() {
    local script_name="$1"
    local script_path="$2"

    # Check if script is in PATH
    local in_path=false
    if command -v "$script_name" >/dev/null 2>&1; then
        in_path=true
    fi

    # Check if script is executable
    local is_executable=false
    if [[ -x "$script_path" ]]; then
        is_executable=true
    fi

    # Check if script is in .local/share/bin (commonly in PATH)
    local in_local_bin=false
    if [[ "$script_path" == *".local/share/bin/"* ]]; then
        in_local_bin=true
    fi

    cat << EOF
{
    "in_path": $in_path,
    "is_executable": $is_executable,
    "in_local_bin": $in_local_bin
}
EOF
}

# Function to determine usage frequency based on various factors
determine_usage_frequency() {
    local ref_count="$1"
    local in_path="$2"
    local in_local_bin="$3"
    local is_executable="$4"

    # Determine frequency
    if [[ $ref_count -gt 0 ]]; then
        echo "active"
    elif [[ "$in_path" == "true" ]] || [[ "$in_local_bin" == "true" ]]; then
        echo "available"
    elif [[ "$is_executable" == "true" ]]; then
        echo "executable"
    else
        echo "unused"
    fi
}

# Function to analyze a single script's usage
analyze_script_usage() {
    local script_path="$1"
    local script_name
    script_name=$(basename "$script_path")

    log "DEBUG" "Analyzing usage for: $script_path"

    # Find configuration references
    local config_refs_array=()
    while IFS= read -r ref; do
        [[ -n "$ref" ]] && config_refs_array+=("$ref")
    done < <(find_config_references "$script_name")

    # Convert to JSON array
    local config_refs="[]"
    if [[ ${#config_refs_array[@]} -gt 0 ]]; then
        config_refs="[$(IFS=,; echo "${config_refs_array[*]}")]"
    fi

    # Check PATH accessibility
    local path_info
    path_info=$(check_path_accessibility "$script_name" "$script_path")

    # Extract path info values
    local in_path in_local_bin is_executable
    in_path=$(echo "$path_info" | jq -r '.in_path')
    in_local_bin=$(echo "$path_info" | jq -r '.in_local_bin')
    is_executable=$(echo "$path_info" | jq -r '.is_executable')

    # Determine usage frequency
    local ref_count=${#config_refs_array[@]}
    local usage_frequency
    usage_frequency=$(determine_usage_frequency "$ref_count" "$in_path" "$in_local_bin" "$is_executable")

    # Create usage analysis object
    cat << EOF
{
    "script_path": "$script_path",
    "script_name": "$script_name",
    "relative_path": "${script_path#$SCRIPTS_DIR/}",
    "usage_frequency": "$usage_frequency",
    "config_references": $config_refs,
    "path_info": $path_info,
    "reference_count": $ref_count
}
EOF
}

# Function to scan all scripts for usage analysis
scan_script_usage() {
    local dir="$1"

    log "INFO" "Analyzing script usage in: $dir"

    # Start JSON structure
    echo "{"
    echo "  \"scan_timestamp\": $(date +%s),"
    echo "  \"scan_date\": \"$(date -Iseconds)\","
    echo "  \"scanned_directory\": \"$dir\","
    echo "  \"scripts\": ["

    local first_script=true
    local total_scripts=0
    local active_scripts=0
    local available_scripts=0
    local unused_scripts=0

    # Get list of script files
    local script_files=()
    mapfile -t script_files < <(/usr/bin/find "$dir" -type f \( -name "*.sh" -o -name "*.py" \) 2>/dev/null | sort)

    # Analyze each script
    for script_file in "${script_files[@]}"; do
        # Skip directories
        [[ -d "$script_file" ]] && continue

        ((total_scripts++))

        # Add comma separator for JSON array
        if [[ "$first_script" == "false" ]]; then
            echo ","
        fi
        first_script=false

        # Analyze script usage
        local usage_result
        usage_result=$(analyze_script_usage "$script_file")
        echo "$usage_result" | sed 's/^/    /'

        # Count by usage frequency
        local frequency
        frequency=$(echo "$usage_result" | jq -r '.usage_frequency')
        case "$frequency" in
            "active") ((active_scripts++)) ;;
            "available") ((available_scripts++)) ;;
            *) ((unused_scripts++)) ;;
        esac

        log "DEBUG" "Processed: $script_file ($frequency)"
    done

    # Close scripts array and add summary
    echo ""
    echo "  ],"
    echo "  \"summary\": {"
    echo "    \"total_scripts\": $total_scripts,"
    echo "    \"active_scripts\": $active_scripts,"
    echo "    \"available_scripts\": $available_scripts,"
    echo "    \"unused_scripts\": $unused_scripts,"
    echo "    \"scan_completed\": true"
    echo "  }"
    echo "}"

    log "INFO" "Usage analysis completed: $active_scripts active, $available_scripts available, $unused_scripts unused"
}

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [SCRIPTS_DIR] [OUTPUT_FILE]

Usage Analysis Tool - Determines which scripts are actively used

Arguments:
    SCRIPTS_DIR   Directory to scan (default: parent of this script's directory)
    OUTPUT_FILE   Output JSON file (default: /tmp/usage-analysis.json)

Environment Variables:
    VERBOSE=1     Enable verbose debug output

Examples:
    $0                                    # Analyze default scripts directory
    $0 /path/to/scripts                   # Analyze specific directory
    $0 /path/to/scripts usage.json        # Analyze and save to specific file
    VERBOSE=1 $0                          # Analyze with verbose output

EOF
}

# Main execution
main() {
    # Check for help flag
    if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
        usage
        exit 0
    fi

    # Validate scripts directory
    if [[ ! -d "$SCRIPTS_DIR" ]]; then
        log "ERROR" "Scripts directory does not exist: $SCRIPTS_DIR"
        exit 1
    fi

    log "INFO" "Starting usage analysis..."
    log "INFO" "Scripts directory: $SCRIPTS_DIR"
    log "INFO" "Output file: $OUTPUT_FILE"

    # Create output directory if needed
    mkdir -p "$(dirname "$OUTPUT_FILE")"

    # Perform analysis and save results
    scan_script_usage "$SCRIPTS_DIR" > "$OUTPUT_FILE"

    log "INFO" "Usage analysis saved to: $OUTPUT_FILE"

    # Display summary if jq is available
    if command -v jq >/dev/null 2>&1; then
        local total active available unused
        total=$(jq -r '.summary.total_scripts' "$OUTPUT_FILE")
        active=$(jq -r '.summary.active_scripts' "$OUTPUT_FILE")
        available=$(jq -r '.summary.available_scripts' "$OUTPUT_FILE")
        unused=$(jq -r '.summary.unused_scripts' "$OUTPUT_FILE")

        log "INFO" "Summary: $total scripts analyzed"
        log "INFO" "  - $active actively used in configurations"
        log "INFO" "  - $available available in PATH"
        log "INFO" "  - $unused potentially unused"

        # Show actively used scripts
        if [[ $active -gt 0 ]]; then
            log "INFO" "Actively used scripts:"
            jq -r '.scripts[] | select(.usage_frequency == "active") | "  - \(.relative_path) (\(.reference_count) refs)"' "$OUTPUT_FILE" >&2
        fi
    else
        log "WARN" "Install 'jq' for better JSON processing and summary display"
    fi
}

# Run main function
main "$@"