#!/bin/bash

# Script Classification System
# Analyzes script data and generates action plans for each script

set -eo pipefail

# Configuration
SCRIPTS_DIR="${1:-$(dirname "$(dirname "$(realpath "$0")")")}"
SCAN_DATA="${2:-/tmp/script-scan-results.json}"
HYDE_DATA="${3:-/tmp/hyde-references.json}"
USAGE_DATA="${4:-/tmp/usage-analysis.json}"
OUTPUT_FILE="${5:-/tmp/script-classification.json}"
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
    local files=("$SCAN_DATA" "$HYDE_DATA" "$USAGE_DATA")
    local file_names=("scan data" "Hyde references" "usage analysis")

    for i in "${!files[@]}"; do
        local file="${files[i]}"
        local name="${file_names[i]}"

        if [[ ! -f "$file" ]]; then
            log "ERROR" "Missing $name file: $file"
            log "ERROR" "Please run the analysis tools first"
            exit 1
        fi

        if ! jq empty "$file" 2>/dev/null; then
            log "ERROR" "Invalid JSON in $name file: $file"
            exit 1
        fi
    done
}

# Function to get Hyde reference data for a script
get_hyde_references() {
    local script_path="$1"
    local relative_path="${script_path#$SCRIPTS_DIR/}"

    # Get Hyde reference data for this script
    jq -r --arg path "$relative_path" '
        .files[] | select(.relative_path == $path) |
        {
            reference_count: .reference_count,
            has_critical: ([.references[] | select(.criticality == "critical")] | length > 0),
            has_high: ([.references[] | select(.criticality == "high")] | length > 0),
            critical_count: ([.references[] | select(.criticality == "critical")] | length),
            high_count: ([.references[] | select(.criticality == "high")] | length),
            low_count: ([.references[] | select(.criticality == "low")] | length)
        }
    ' "$HYDE_DATA" 2>/dev/null || echo '{
        "reference_count": 0,
        "has_critical": false,
        "has_high": false,
        "critical_count": 0,
        "high_count": 0,
        "low_count": 0
    }'
}

# Function to get usage data for a script
get_usage_data() {
    local script_path="$1"
    local relative_path="${script_path#$SCRIPTS_DIR/}"

    # Get usage data for this script
    jq -r --arg path "$relative_path" '
        .scripts[] | select(.relative_path == $path) |
        {
            usage_frequency: .usage_frequency,
            reference_count: .reference_count,
            in_path: .path_info.in_path,
            is_executable: .path_info.is_executable,
            in_local_bin: .path_info.in_local_bin
        }
    ' "$USAGE_DATA" 2>/dev/null || echo '{
        "usage_frequency": "unused",
        "reference_count": 0,
        "in_path": false,
        "is_executable": false,
        "in_local_bin": false
    }'
}

# Function to check for dependencies in other scripts
check_script_dependencies() {
    local script_name="$1"
    local dependencies=()

    # Search for references to this script in other scripts
    local script_basename
    script_basename=$(basename "$script_name" .sh)

    # Use grep to find references in other scripts
    local grep_results
    grep_results=$(grep -r -l "$script_basename" "$SCRIPTS_DIR" 2>/dev/null | grep -v "$script_name" || true)

    if [[ -n "$grep_results" ]]; then
        while IFS= read -r dep_file; do
            [[ -n "$dep_file" ]] && dependencies+=("${dep_file#$SCRIPTS_DIR/}")
        done <<< "$grep_results"
    fi

    # Convert to JSON array
    printf '%s\n' "${dependencies[@]}" | jq -R . | jq -s .
}

# Function to classify a single script
classify_script() {
    local script_path="$1"
    local script_name
    script_name=$(basename "$script_path")
    local relative_path="${script_path#$SCRIPTS_DIR/}"

    log "DEBUG" "Classifying script: $relative_path"

    # Get analysis data
    local hyde_data usage_data dependencies
    hyde_data=$(get_hyde_references "$script_path")
    usage_data=$(get_usage_data "$script_path")
    dependencies=$(check_script_dependencies "$script_path")

    # Extract key values for decision making
    local has_critical_hyde has_high_hyde usage_frequency reference_count is_executable
    has_critical_hyde=$(echo "$hyde_data" | jq -r '.has_critical')
    has_high_hyde=$(echo "$hyde_data" | jq -r '.has_high')
    usage_frequency=$(echo "$usage_data" | jq -r '.usage_frequency')
    reference_count=$(echo "$usage_data" | jq -r '.reference_count')
    is_executable=$(echo "$usage_data" | jq -r '.is_executable')

    # Classification decision tree
    local action reason priority update_instructions

    # Decision logic based on requirements 4.1, 4.2
    if [[ "$has_critical_hyde" == "true" ]] && [[ "$usage_frequency" == "unused" ]] && [[ "$reference_count" -eq 0 ]]; then
        action="remove"
        reason="Script has critical Hyde dependencies and is not used in any configurations"
        priority="high"
        update_instructions=""

    elif [[ "$has_critical_hyde" == "true" ]] && [[ "$usage_frequency" == "active" ]]; then
        action="update"
        reason="Script is actively used but has critical Hyde dependencies that need removal"
        priority="high"
        update_instructions="Remove critical Hyde references while preserving core functionality. Replace Hyde paths with generic alternatives."

    elif [[ "$has_high_hyde" == "true" ]] && [[ "$usage_frequency" == "unused" ]]; then
        action="remove"
        reason="Script has high-priority Hyde references and is not actively used"
        priority="medium"
        update_instructions=""

    elif [[ "$has_high_hyde" == "true" ]] && [[ "$usage_frequency" != "unused" ]]; then
        action="update"
        reason="Script has high-priority Hyde references but is used or available"
        priority="medium"
        update_instructions="Update Hyde variable references and theme-related paths. Preserve functionality where possible."

    elif [[ "$usage_frequency" == "active" ]] && [[ "$is_executable" == "true" ]]; then
        action="preserve"
        reason="Script is actively used in configurations and functional"
        priority="low"
        update_instructions=""

    elif [[ "$usage_frequency" == "available" ]] && [[ "$is_executable" == "true" ]]; then
        action="organize"
        reason="Script is available in PATH but not actively referenced - may need better organization"
        priority="low"
        update_instructions=""

    elif [[ "$is_executable" == "false" ]]; then
        action="remove"
        reason="Script is not executable and appears to be broken"
        priority="medium"
        update_instructions=""

    else
        action="organize"
        reason="Script needs review for proper categorization"
        priority="low"
        update_instructions=""
    fi

    # Create classification result
    cat << EOF
{
    "script_path": "$script_path",
    "script_name": "$script_name",
    "relative_path": "$relative_path",
    "action": "$action",
    "reason": "$reason",
    "priority": "$priority",
    "update_instructions": "$update_instructions",
    "analysis_data": {
        "hyde_references": $hyde_data,
        "usage_info": $usage_data,
        "dependencies": $dependencies
    },
    "classification_timestamp": $(date +%s)
}
EOF
}

# Function to classify all scripts
classify_all_scripts() {
    log "INFO" "Starting script classification..."

    # Start JSON structure
    echo "{"
    echo "  \"classification_timestamp\": $(date +%s),"
    echo "  \"classification_date\": \"$(date -Iseconds)\","
    echo "  \"scripts_directory\": \"$SCRIPTS_DIR\","
    echo "  \"input_files\": {"
    echo "    \"scan_data\": \"$SCAN_DATA\","
    echo "    \"hyde_data\": \"$HYDE_DATA\","
    echo "    \"usage_data\": \"$USAGE_DATA\""
    echo "  },"
    echo "  \"classifications\": ["

    local first_script=true
    local total_scripts=0
    local remove_count=0
    local update_count=0
    local preserve_count=0
    local organize_count=0

    # Get list of scripts from scan data
    local script_paths
    script_paths=$(jq -r '.files[].path' "$SCAN_DATA")

    # Classify each script
    while IFS= read -r script_path; do
        [[ -z "$script_path" ]] && continue

        ((total_scripts++))

        # Add comma separator for JSON array
        if [[ "$first_script" == "false" ]]; then
            echo ","
        fi
        first_script=false

        # Classify script and add to JSON
        local classification
        classification=$(classify_script "$script_path")
        echo "$classification" | sed 's/^/    /'

        # Count by action
        local action
        action=$(echo "$classification" | jq -r '.action')
        case "$action" in
            "remove") ((remove_count++)) ;;
            "update") ((update_count++)) ;;
            "preserve") ((preserve_count++)) ;;
            "organize") ((organize_count++)) ;;
        esac

        log "DEBUG" "Classified: $(basename "$script_path") -> $action"
    done <<< "$script_paths"

    # Close classifications array and add summary
    echo ""
    echo "  ],"
    echo "  \"summary\": {"
    echo "    \"total_scripts\": $total_scripts,"
    echo "    \"remove_count\": $remove_count,"
    echo "    \"update_count\": $update_count,"
    echo "    \"preserve_count\": $preserve_count,"
    echo "    \"organize_count\": $organize_count,"
    echo "    \"classification_completed\": true"
    echo "  }"
    echo "}"

    log "INFO" "Classification completed: $total_scripts scripts processed"
    log "INFO" "  - $remove_count to remove"
    log "INFO" "  - $update_count to update"
    log "INFO" "  - $preserve_count to preserve"
    log "INFO" "  - $organize_count to organize"
}

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [SCRIPTS_DIR] [SCAN_DATA] [HYDE_DATA] [USAGE_DATA] [OUTPUT_FILE]

Script Classification System - Generates action plans for script cleanup

Arguments:
    SCRIPTS_DIR   Scripts directory (default: parent of this script's directory)
    SCAN_DATA     Script scan JSON file (default: /tmp/script-scan-results.json)
    HYDE_DATA     Hyde references JSON file (default: /tmp/hyde-references.json)
    USAGE_DATA    Usage analysis JSON file (default: /tmp/usage-analysis.json)
    OUTPUT_FILE   Output classification JSON file (default: /tmp/script-classification.json)

Environment Variables:
    VERBOSE=1     Enable verbose debug output

Examples:
    $0                                    # Classify using default files
    $0 /path/to/scripts                   # Classify specific directory
    VERBOSE=1 $0                          # Classify with verbose output

Prerequisites:
    - Run script-scanner.sh to generate scan data
    - Run hyde-detector.sh to generate Hyde reference data
    - Run usage-analyzer.sh to generate usage data

EOF
}

# Main execution
main() {
    # Check for help flag
    if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
        usage
        exit 0
    fi

    # Check dependencies
    check_dependencies

    # Validate scripts directory
    if [[ ! -d "$SCRIPTS_DIR" ]]; then
        log "ERROR" "Scripts directory does not exist: $SCRIPTS_DIR"
        exit 1
    fi

    # Validate input files
    validate_input_files

    log "INFO" "Starting script classification..."
    log "INFO" "Scripts directory: $SCRIPTS_DIR"
    log "INFO" "Input files:"
    log "INFO" "  - Scan data: $SCAN_DATA"
    log "INFO" "  - Hyde data: $HYDE_DATA"
    log "INFO" "  - Usage data: $USAGE_DATA"
    log "INFO" "Output file: $OUTPUT_FILE"

    # Create output directory if needed
    mkdir -p "$(dirname "$OUTPUT_FILE")"

    # Perform classification and save results
    classify_all_scripts > "$OUTPUT_FILE"

    log "INFO" "Classification results saved to: $OUTPUT_FILE"

    # Display summary
    if command -v jq >/dev/null 2>&1; then
        local total remove update preserve organize
        total=$(jq -r '.summary.total_scripts' "$OUTPUT_FILE")
        remove=$(jq -r '.summary.remove_count' "$OUTPUT_FILE")
        update=$(jq -r '.summary.update_count' "$OUTPUT_FILE")
        preserve=$(jq -r '.summary.preserve_count' "$OUTPUT_FILE")
        organize=$(jq -r '.summary.organize_count' "$OUTPUT_FILE")

        log "INFO" "Classification Summary:"
        log "INFO" "  Total scripts: $total"
        log "INFO" "  Remove: $remove scripts"
        log "INFO" "  Update: $update scripts"
        log "INFO" "  Preserve: $preserve scripts"
        log "INFO" "  Organize: $organize scripts"

        # Show high priority actions
        local high_priority_count
        high_priority_count=$(jq -r '[.classifications[] | select(.priority == "high")] | length' "$OUTPUT_FILE")
        if [[ $high_priority_count -gt 0 ]]; then
            log "INFO" "High priority actions needed for $high_priority_count scripts"
        fi
    else
        log "WARN" "Install 'jq' for better JSON processing and summary display"
    fi
}

# Run main function
main "$@"