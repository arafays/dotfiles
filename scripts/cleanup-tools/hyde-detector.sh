#!/bin/bash

# Hyde Reference Detection Script
# Identifies and analyzes Hyde-related references in scripts

set -eo pipefail

# Configuration
SCRIPTS_DIR="${1:-$(dirname "$(dirname "$(realpath "$0")")")}"
OUTPUT_FILE="${2:-/tmp/hyde-references.json}"
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

# Function to analyze a single file for Hyde references
analyze_file() {
    local file="$1"
    local references=()

    # Skip binary files
    if ! file "$file" | grep -q "text"; then
        log "DEBUG" "Skipping binary file: $file"
        return
    fi

    log "DEBUG" "Analyzing file: $file"

    # Search for Hyde patterns and collect results
    local hyde_lines
    hyde_lines=$(grep -nE "hyde|Hyde|HYDE" "$file" 2>/dev/null || true)

    if [[ -n "$hyde_lines" ]]; then
        while IFS=: read -r line_num line_content; do
            [[ -z "$line_num" ]] && continue

            # Determine pattern type and criticality
            local pattern_type="variable"
            local criticality="non-critical"
            local match=""

            # Extract specific matches
            if echo "$line_content" | grep -qE "hydeThemeDir|hydeConfDir"; then
                match=$(echo "$line_content" | grep -oE "hydeThemeDir|hydeConfDir" | head -1)
                pattern_type="directory"
                criticality="critical"
            elif echo "$line_content" | grep -qE "hydeTheme"; then
                match=$(echo "$line_content" | grep -oE "hydeTheme" | head -1)
                pattern_type="variable"
                criticality="high"
            elif echo "$line_content" | grep -qE "/hyde/|/.hyde/"; then
                match=$(echo "$line_content" | grep -oE "/\.?hyde/" | head -1)
                pattern_type="path"
                criticality="critical"
            elif echo "$line_content" | grep -qE "hyde\.conf|hypr\.theme"; then
                match=$(echo "$line_content" | grep -oE "hyde\.conf|hypr\.theme" | head -1)
                pattern_type="config"
                criticality="high"
            else
                match=$(echo "$line_content" | grep -oE "[Hh]yde" | head -1)
                pattern_type="reference"
                criticality="low"
            fi

            # Create reference object
            local ref_obj
            ref_obj=$(cat << EOF
{
    "line_number": $line_num,
    "pattern_type": "$pattern_type",
    "match": "$match",
    "criticality": "$criticality",
    "line_content": $(echo "$line_content" | jq -R .)
}
EOF
)
            references+=("$ref_obj")
            log "DEBUG" "Found $criticality $pattern_type reference: $match at line $line_num"
        done <<< "$hyde_lines"
    fi

    # Output file analysis result
    local ref_count=${#references[@]}
    if [[ $ref_count -gt 0 ]]; then
        echo "{"
        echo "  \"file\": \"$file\","
        echo "  \"relative_path\": \"${file#$SCRIPTS_DIR/}\","
        echo "  \"reference_count\": $ref_count,"
        echo "  \"references\": ["

        for i in "${!references[@]}"; do
            echo "    ${references[i]}"
            if [[ $i -lt $((ref_count - 1)) ]]; then
                echo ","
            fi
        done

        echo "  ]"
        echo "}"
    fi
}

# Function to scan all scripts for Hyde references
scan_hyde_references() {
    local dir="$1"

    log "INFO" "Scanning for Hyde references in: $dir"

    # Start JSON structure
    echo "{"
    echo "  \"scan_timestamp\": $(date +%s),"
    echo "  \"scan_date\": \"$(date -Iseconds)\","
    echo "  \"scanned_directory\": \"$dir\","
    echo "  \"files\": ["

    local first_file=true
    local total_files=0
    local files_with_refs=0

    # Get list of script files
    local script_files=()
    mapfile -t script_files < <(/usr/bin/find "$dir" -type f \( -name "*.sh" -o -name "*.py" \) 2>/dev/null | sort)

    # Analyze each script file
    for file in "${script_files[@]}"; do
        ((total_files++))

        # Skip directories
        [[ -d "$file" ]] && continue

        local result
        result=$(analyze_file "$file")

        if [[ -n "$result" ]]; then
            ((files_with_refs++))

            # Add comma separator for JSON array
            if [[ "$first_file" == "false" ]]; then
                echo ","
            fi
            first_file=false

            # Add file result to JSON
            echo "$result" | sed 's/^/    /'
        fi

        log "DEBUG" "Processed: $file"
    done

    # Close files array
    echo ""
    echo "  ],"

    # Add summary
    echo "  \"summary\": {"
    echo "    \"total_files_scanned\": $total_files,"
    echo "    \"files_with_hyde_refs\": $files_with_refs,"
    echo "    \"scan_completed\": true"
    echo "  }"
    echo "}"

    log "INFO" "Hyde reference scan completed: $files_with_refs/$total_files files contain Hyde references"
}

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [SCRIPTS_DIR] [OUTPUT_FILE]

Hyde Reference Detection Script - Identifies Hyde-related references in scripts

Arguments:
    SCRIPTS_DIR   Directory to scan (default: parent of this script's directory)
    OUTPUT_FILE   Output JSON file (default: /tmp/hyde-references.json)

Environment Variables:
    VERBOSE=1     Enable verbose debug output

Examples:
    $0                                    # Scan default scripts directory
    $0 /path/to/scripts                   # Scan specific directory
    $0 /path/to/scripts hyde-refs.json    # Scan and save to specific file
    VERBOSE=1 $0                          # Scan with verbose output

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

    log "INFO" "Starting Hyde reference detection..."
    log "INFO" "Scripts directory: $SCRIPTS_DIR"
    log "INFO" "Output file: $OUTPUT_FILE"

    # Create output directory if needed
    mkdir -p "$(dirname "$OUTPUT_FILE")"

    # Perform scan and save results
    scan_hyde_references "$SCRIPTS_DIR" > "$OUTPUT_FILE"

    log "INFO" "Hyde reference analysis saved to: $OUTPUT_FILE"

    # Display summary if jq is available
    if command -v jq >/dev/null 2>&1; then
        local total_scanned files_with_refs
        total_scanned=$(jq -r '.summary.total_files_scanned' "$OUTPUT_FILE")
        files_with_refs=$(jq -r '.summary.files_with_hyde_refs' "$OUTPUT_FILE")
        log "INFO" "Summary: $files_with_refs/$total_scanned files contain Hyde references"

        # Show top problematic files
        if [[ $files_with_refs -gt 0 ]]; then
            log "INFO" "Files with most Hyde references:"
            jq -r '.files[] | "\(.reference_count) refs: \(.relative_path)"' "$OUTPUT_FILE" | sort -nr | head -5 >&2
        fi
    else
        log "WARN" "Install 'jq' for better JSON processing and summary display"
    fi
}

# Run main function
main "$@"