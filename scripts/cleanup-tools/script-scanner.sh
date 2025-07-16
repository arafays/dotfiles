#!/bin/bash

# Script Scanner Utility
# Recursively scans scripts directory and catalogs all executable files with metadata

# Configuration
SCRIPTS_DIR="${1:-$(dirname "$(dirname "$(realpath "$0")")")}"
OUTPUT_FILE="${2:-/tmp/script-scan-results.json}"
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

# Function to detect file type
detect_file_type() {
    local file="$1"

    # Check if file is executable
    if [[ ! -x "$file" ]]; then
        echo "non-executable"
        return
    fi

    # Check shebang for script types
    if [[ -f "$file" ]]; then
        local first_line
        first_line=$(head -n1 "$file" 2>/dev/null || echo "")

        case "$first_line" in
            "#!/bin/bash"* | "#!/usr/bin/bash"* | "#!/bin/sh"* | "#!/usr/bin/sh"*)
                echo "shell-script"
                return
                ;;
            "#!/usr/bin/python"* | "#!/bin/python"* | "#!/usr/bin/env python"*)
                echo "python-script"
                return
                ;;
            "#!/usr/bin/env"*)
                echo "env-script"
                return
                ;;
            "#!"*)
                echo "script"
                return
                ;;
        esac
    fi

    # Check file extension
    case "$file" in
        *.sh) echo "shell-script" ;;
        *.py) echo "python-script" ;;
        *) echo "executable" ;;
    esac
}

# Function to get file metadata
get_file_metadata() {
    local file="$1"
    local name permissions size last_modified file_type

    name=$(basename "$file")
    permissions=$(stat -c "%a" "$file" 2>/dev/null || echo "unknown")
    size=$(stat -c "%s" "$file" 2>/dev/null || echo "0")
    last_modified=$(stat -c "%Y" "$file" 2>/dev/null || echo "0")
    file_type=$(detect_file_type "$file")

    # Create JSON object for this file
    cat << EOF
{
    "path": "$file",
    "name": "$name",
    "type": "$file_type",
    "permissions": "$permissions",
    "size": $size,
    "last_modified": $last_modified,
    "is_executable": $([ -x "$file" ] && echo "true" || echo "false"),
    "relative_path": "${file#$SCRIPTS_DIR/}"
}
EOF
}

# Function to scan directory recursively
scan_directory() {
    local dir="$1"
    local file_count=0
    local script_count=0

    log "INFO" "Scanning directory: $dir"

    # Start JSON array
    echo "{"
    echo "  \"scan_timestamp\": $(date +%s),"
    echo "  \"scan_date\": \"$(date -Iseconds)\","
    echo "  \"scanned_directory\": \"$dir\","
    echo "  \"files\": ["

    local first_file=true
    local files_array=()

    # Collect all files first
    mapfile -t files_array < <(find "$dir" -type f \( -name "*.sh" -o -name "*.py" -o -executable \) 2>/dev/null | sort)

    # Process each file
    for file in "${files_array[@]}"; do
        # Skip directories
        [[ -d "$file" ]] && continue

        # Skip hidden files and common non-script files
        local basename_file
        basename_file=$(basename "$file")
        case "$basename_file" in
            .* | *.md | *.txt | *.json | *.conf | *.toml | *.yml | *.yaml)
                log "DEBUG" "Skipping non-script file: $file"
                continue
                ;;
        esac

        ((file_count++))

        # Add comma separator for JSON array
        if [[ "$first_file" == "false" ]]; then
            echo ","
        fi
        first_file=false

        # Get metadata and add to JSON
        get_file_metadata "$file" | sed 's/^/    /'

        # Count scripts
        if [[ -x "$file" ]] || [[ "$file" == *.sh ]] || [[ "$file" == *.py ]]; then
            ((script_count++))
        fi

        log "DEBUG" "Processed: $file"
    done

    # Close JSON array and object
    echo ""
    echo "  ],"
    echo "  \"summary\": {"
    echo "    \"total_files\": $file_count,"
    echo "    \"script_files\": $script_count,"
    echo "    \"scan_completed\": true"
    echo "  }"
    echo "}"

    log "INFO" "Scan completed: $file_count files processed, $script_count scripts found"
}

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [SCRIPTS_DIR] [OUTPUT_FILE]

Script Scanner Utility - Catalogs all scripts with metadata

Arguments:
    SCRIPTS_DIR   Directory to scan (default: parent of this script's directory)
    OUTPUT_FILE   Output JSON file (default: /tmp/script-scan-results.json)

Environment Variables:
    VERBOSE=1     Enable verbose debug output

Examples:
    $0                                    # Scan default scripts directory
    $0 /path/to/scripts                   # Scan specific directory
    $0 /path/to/scripts results.json      # Scan and save to specific file
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

    log "INFO" "Starting script scan..."
    log "INFO" "Scripts directory: $SCRIPTS_DIR"
    log "INFO" "Output file: $OUTPUT_FILE"

    # Create output directory if needed
    mkdir -p "$(dirname "$OUTPUT_FILE")"

    # Perform scan and save results
    scan_directory "$SCRIPTS_DIR" > "$OUTPUT_FILE"

    log "INFO" "Scan results saved to: $OUTPUT_FILE"

    # Display summary
    if command -v jq >/dev/null 2>&1; then
        local total_files script_files
        total_files=$(jq -r '.summary.total_files' "$OUTPUT_FILE")
        script_files=$(jq -r '.summary.script_files' "$OUTPUT_FILE")
        log "INFO" "Summary: $total_files total files, $script_files script files"
    else
        log "WARN" "Install 'jq' for better JSON processing and summary display"
    fi
}

# Run main function
main "$@"