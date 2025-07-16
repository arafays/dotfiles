#!/bin/bash

# Backup System for Script Cleanup
# Creates timestamped backups and provides rollback capabilities

set -eo pipefail

# Configuration
SCRIPTS_DIR="${1:-$(dirname "$(dirname "$(realpath "$0")")")}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/.script-cleanup-backups}"
OPERATION="${2:-full}"  # full, individual, rollback, list
TARGET_FILE="${3:-}"    # For individual backup or rollback
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

# Function to create timestamped backup directory
create_backup_dir() {
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_path="$BACKUP_DIR/scripts_backup_$timestamp"

    mkdir -p "$backup_path"
    echo "$backup_path"
}

# Function to create full backup of scripts directory
create_full_backup() {
    log "INFO" "Creating full backup of scripts directory..."

    if [[ ! -d "$SCRIPTS_DIR" ]]; then
        log "ERROR" "Scripts directory does not exist: $SCRIPTS_DIR"
        return 1
    fi

    local backup_path
    backup_path=$(create_backup_dir)

    # Copy entire scripts directory
    log "DEBUG" "Copying $SCRIPTS_DIR to $backup_path"
    cp -r "$SCRIPTS_DIR" "$backup_path/scripts"

    # Create backup metadata
    local metadata_file="$backup_path/backup_metadata.json"
    cat > "$metadata_file" << EOF
{
    "backup_type": "full",
    "backup_timestamp": $(date +%s),
    "backup_date": "$(date -Iseconds)",
    "source_directory": "$SCRIPTS_DIR",
    "backup_directory": "$backup_path",
    "file_count": $(find "$SCRIPTS_DIR" -type f | wc -l),
    "total_size": $(du -sb "$SCRIPTS_DIR" | cut -f1)
}
EOF

    # Create restore script
    local restore_script="$backup_path/restore.sh"
    cat > "$restore_script" << 'EOF'
#!/bin/bash
# Auto-generated restore script

set -eo pipefail

BACKUP_DIR="$(dirname "$(realpath "$0")")"
METADATA_FILE="$BACKUP_DIR/backup_metadata.json"

if [[ ! -f "$METADATA_FILE" ]]; then
    echo "ERROR: Backup metadata not found"
    exit 1
fi

SOURCE_DIR=$(jq -r '.source_directory' "$METADATA_FILE")
BACKUP_DATE=$(jq -r '.backup_date' "$METADATA_FILE")

echo "This will restore scripts from backup created on: $BACKUP_DATE"
echo "Target directory: $SOURCE_DIR"
echo ""
read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Restore cancelled"
    exit 0
fi

echo "Creating backup of current state before restore..."
CURRENT_BACKUP_DIR="$HOME/.script-cleanup-backups/pre_restore_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$CURRENT_BACKUP_DIR"
if [[ -d "$SOURCE_DIR" ]]; then
    cp -r "$SOURCE_DIR" "$CURRENT_BACKUP_DIR/scripts"
fi

echo "Restoring scripts from backup..."
rm -rf "$SOURCE_DIR"
cp -r "$BACKUP_DIR/scripts" "$SOURCE_DIR"

echo "Restore completed successfully"
echo "Pre-restore backup saved to: $CURRENT_BACKUP_DIR"
EOF

    chmod +x "$restore_script"

    log "INFO" "Full backup created: $backup_path"
    log "INFO" "Backup size: $(du -sh "$backup_path" | cut -f1)"
    log "INFO" "To restore: $restore_script"

    echo "$backup_path"
}

# Function to create individual file backup
create_individual_backup() {
    local file_path="$1"

    if [[ -z "$file_path" ]]; then
        log "ERROR" "File path required for individual backup"
        return 1
    fi

    if [[ ! -f "$file_path" ]]; then
        log "ERROR" "File does not exist: $file_path"
        return 1
    fi

    log "DEBUG" "Creating individual backup for: $file_path"

    # Create individual backup directory structure
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    local relative_path="${file_path#$SCRIPTS_DIR/}"
    local backup_path="$BACKUP_DIR/individual_backups/$relative_path"
    local backup_file="$backup_path.backup_$timestamp"

    # Create directory structure
    mkdir -p "$(dirname "$backup_file")"

    # Copy file with timestamp
    cp "$file_path" "$backup_file"

    # Create metadata for individual backup
    local metadata_file="$backup_file.metadata.json"
    cat > "$metadata_file" << EOF
{
    "backup_type": "individual",
    "backup_timestamp": $(date +%s),
    "backup_date": "$(date -Iseconds)",
    "original_file": "$file_path",
    "backup_file": "$backup_file",
    "file_size": $(stat -c%s "$file_path"),
    "file_permissions": "$(stat -c%a "$file_path")",
    "file_modified": $(stat -c%Y "$file_path")
}
EOF

    log "INFO" "Individual backup created: $backup_file"
    echo "$backup_file"
}

# Function to list available backups
list_backups() {
    log "INFO" "Available backups in: $BACKUP_DIR"

    if [[ ! -d "$BACKUP_DIR" ]]; then
        log "WARN" "No backup directory found: $BACKUP_DIR"
        return 0
    fi

    echo ""
    echo "Full Backups:"
    echo "============="

    local full_backups=()
    mapfile -t full_backups < <(find "$BACKUP_DIR" -name "scripts_backup_*" -type d 2>/dev/null | sort -r)

    if [[ ${#full_backups[@]} -eq 0 ]]; then
        echo "  No full backups found"
    else
        for backup in "${full_backups[@]}"; do
            local backup_name
            backup_name=$(basename "$backup")
            local metadata_file="$backup/backup_metadata.json"

            if [[ -f "$metadata_file" ]]; then
                local backup_date file_count total_size
                backup_date=$(jq -r '.backup_date' "$metadata_file" 2>/dev/null || echo "unknown")
                file_count=$(jq -r '.file_count' "$metadata_file" 2>/dev/null || echo "unknown")
                total_size=$(jq -r '.total_size' "$metadata_file" 2>/dev/null || echo "unknown")

                if [[ "$total_size" != "unknown" ]] && [[ "$total_size" =~ ^[0-9]+$ ]]; then
                    total_size=$(numfmt --to=iec "$total_size" 2>/dev/null || echo "$total_size bytes")
                fi

                echo "  $backup_name"
                echo "    Date: $backup_date"
                echo "    Files: $file_count"
                echo "    Size: $total_size"
                echo "    Restore: $backup/restore.sh"
                echo ""
            else
                echo "  $backup_name (metadata missing)"
                echo ""
            fi
        done
    fi

    echo "Individual File Backups:"
    echo "======================="

    local individual_dir="$BACKUP_DIR/individual_backups"
    if [[ -d "$individual_dir" ]]; then
        local individual_backups=()
        mapfile -t individual_backups < <(find "$individual_dir" -name "*.backup_*" -type f 2>/dev/null | sort -r)

        if [[ ${#individual_backups[@]} -eq 0 ]]; then
            echo "  No individual backups found"
        else
            local current_file=""
            for backup in "${individual_backups[@]}"; do
                local backup_name
                backup_name=$(basename "$backup")
                local file_path="${backup%%.backup_*}"
                local relative_file="${file_path#$individual_dir/}"

                if [[ "$relative_file" != "$current_file" ]]; then
                    if [[ -n "$current_file" ]]; then
                        echo ""
                    fi
                    echo "  File: $relative_file"
                    current_file="$relative_file"
                fi

                local metadata_file="$backup.metadata.json"
                if [[ -f "$metadata_file" ]]; then
                    local backup_date
                    backup_date=$(jq -r '.backup_date' "$metadata_file" 2>/dev/null || echo "unknown")
                    echo "    Backup: $backup_name ($backup_date)"
                else
                    echo "    Backup: $backup_name (metadata missing)"
                fi
            done
        fi
    else
        echo "  No individual backup directory found"
    fi

    echo ""
}

# Function to rollback from backup
rollback_from_backup() {
    local backup_path="$1"

    if [[ -z "$backup_path" ]]; then
        log "ERROR" "Backup path required for rollback"
        return 1
    fi

    if [[ ! -d "$backup_path" ]]; then
        log "ERROR" "Backup directory does not exist: $backup_path"
        return 1
    fi

    local metadata_file="$backup_path/backup_metadata.json"
    if [[ ! -f "$metadata_file" ]]; then
        log "ERROR" "Backup metadata not found: $metadata_file"
        return 1
    fi

    local source_dir backup_date
    source_dir=$(jq -r '.source_directory' "$metadata_file")
    backup_date=$(jq -r '.backup_date' "$metadata_file")

    log "INFO" "Rolling back to backup from: $backup_date"
    log "INFO" "Target directory: $source_dir"

    # Create backup of current state before rollback
    log "INFO" "Creating backup of current state before rollback..."
    local pre_rollback_backup
    pre_rollback_backup=$(create_full_backup)

    # Perform rollback
    log "INFO" "Performing rollback..."
    rm -rf "$source_dir"
    cp -r "$backup_path/scripts" "$source_dir"

    log "INFO" "Rollback completed successfully"
    log "INFO" "Pre-rollback backup saved to: $pre_rollback_backup"
}

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [SCRIPTS_DIR] [OPERATION] [TARGET_FILE]

Backup System for Script Cleanup - Creates and manages backups

Arguments:
    SCRIPTS_DIR   Scripts directory (default: parent of this script's directory)
    OPERATION     Backup operation: full, individual, rollback, list
    TARGET_FILE   Target file for individual backup or backup path for rollback

Operations:
    full          Create full backup of scripts directory
    individual    Create backup of individual file (requires TARGET_FILE)
    rollback      Rollback from specified backup (requires TARGET_FILE as backup path)
    list          List all available backups

Environment Variables:
    BACKUP_DIR    Backup storage directory (default: ~/.script-cleanup-backups)
    VERBOSE=1     Enable verbose debug output

Examples:
    $0                                    # Create full backup
    $0 /path/to/scripts full              # Create full backup of specific directory
    $0 /path/to/scripts individual file.sh # Create individual file backup
    $0 /path/to/scripts list              # List available backups
    $0 /path/to/scripts rollback /path/to/backup # Rollback from backup

EOF
}

# Main execution
main() {
    # Check for help flag
    if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
        usage
        exit 0
    fi

    # Validate scripts directory for operations that need it
    if [[ "$OPERATION" != "list" ]] && [[ ! -d "$SCRIPTS_DIR" ]]; then
        log "ERROR" "Scripts directory does not exist: $SCRIPTS_DIR"
        exit 1
    fi

    log "INFO" "Backup system starting..."
    log "INFO" "Scripts directory: $SCRIPTS_DIR"
    log "INFO" "Backup directory: $BACKUP_DIR"
    log "INFO" "Operation: $OPERATION"

    # Create backup directory if needed
    mkdir -p "$BACKUP_DIR"

    case "$OPERATION" in
        "full")
            create_full_backup
            ;;
        "individual")
            if [[ -z "$TARGET_FILE" ]]; then
                log "ERROR" "Target file required for individual backup"
                exit 1
            fi
            create_individual_backup "$TARGET_FILE"
            ;;
        "rollback")
            if [[ -z "$TARGET_FILE" ]]; then
                log "ERROR" "Backup path required for rollback"
                exit 1
            fi
            rollback_from_backup "$TARGET_FILE"
            ;;
        "list")
            list_backups
            ;;
        *)
            log "ERROR" "Unknown operation: $OPERATION"
            log "ERROR" "Valid operations: full, individual, rollback, list"
            exit 1
            ;;
    esac

    log "INFO" "Backup operation completed"
}

# Run main function
main "$@"