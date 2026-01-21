#!/usr/bin/env zsh

# Reverse Sync Script - Pull from Client, Push to Personal
# This script syncs code from client account back to personal/org account

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PERSONAL_REMOTE="personal"
CLIENT_REMOTE="client"
PERSONAL_NAME="Abdul Rafay Shaikh"
PERSONAL_EMAIL="abdul.rafay@mayabytes.com"
CLIENT_GH_ACCOUNT="developmentest785"
PERSONAL_GH_ACCOUNT="arafays"

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Safety check: Ensure we're in a git repository
check_git_repo() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        error "Not in a git repository!"
        exit 1
    fi
}

# Safety check: Verify remotes exist
check_remotes() {
    if ! git remote get-url "$PERSONAL_REMOTE" >/dev/null 2>&1; then
        error "Personal remote '$PERSONAL_REMOTE' not found!"
        exit 1
    fi
    
    if ! git remote get-url "$CLIENT_REMOTE" >/dev/null 2>&1; then
        error "Client remote '$CLIENT_REMOTE' not found!"
        exit 1
    fi
}

# Switch GitHub CLI to client account to fetch
switch_to_client_gh() {
    log "Switching GitHub CLI to client account for fetching..."
    if ! gh auth switch --user "$CLIENT_GH_ACCOUNT" >/dev/null 2>&1; then
        error "Failed to switch to client account '$CLIENT_GH_ACCOUNT'"
        exit 1
    fi
    success "Switched to client GitHub account"
}

# Switch GitHub CLI to personal account to push
switch_to_personal_gh() {
    log "Switching GitHub CLI to personal account for pushing..."
    if ! gh auth switch --user "$PERSONAL_GH_ACCOUNT" >/dev/null 2>&1; then
        error "Failed to switch to personal account '$PERSONAL_GH_ACCOUNT'"
        exit 1
    fi
    success "Switched to personal GitHub account"
}

# Set git identity to personal account
set_personal_identity() {
    log "Setting git identity to personal account..."
    git config user.name "$PERSONAL_NAME"
    git config user.email "$PERSONAL_EMAIL"
    success "Git identity set to personal account: $PERSONAL_NAME <$PERSONAL_EMAIL>"
}

# Main sync function
sync_from_client() {
    local branch="${1:-main}"
    local force_push="${2:-false}"
    
    log "Starting reverse sync from client to personal account..."
    log "Branch: $branch"
    
    # Switch to client account and fetch latest
    switch_to_client_gh
    log "Fetching latest from client remote..."
    git fetch "$CLIENT_REMOTE" "$branch"
    
    # Reset local branch to match client remote
    log "Resetting local branch to match client remote..."
    git checkout "$branch" 2>/dev/null || git checkout -b "$branch" "$CLIENT_REMOTE/$branch"
    git reset --hard "$CLIENT_REMOTE/$branch"
    
    success "Local branch now matches client remote"
    
    # Switch to personal account and set identity
    switch_to_personal_gh
    set_personal_identity
    
    # Show what will be pushed
    log "Checking sync status with personal remote..."
    git fetch "$PERSONAL_REMOTE" "$branch" 2>/dev/null || true
    
    if git rev-parse "$PERSONAL_REMOTE/$branch" >/dev/null 2>&1; then
        local ahead behind
        ahead=$(git rev-list --count "$PERSONAL_REMOTE/$branch..HEAD" 2>/dev/null || echo "0")
        behind=$(git rev-list --count "HEAD..$PERSONAL_REMOTE/$branch" 2>/dev/null || echo "0")
        
        log "Sync status:"
        log "  Commits ahead of personal remote: $ahead"
        log "  Commits behind personal remote: $behind"
        
        if [ "$ahead" -eq 0 ] && [ "$behind" -eq 0 ]; then
            success "Personal remote is already up to date!"
            return 0
        fi
        
        if [ "$behind" -gt 0 ] && [ "$force_push" != "true" ]; then
            warning "Personal remote has $behind commits that will be lost!"
            warning "This will OVERWRITE the personal remote history."
            echo -n "Are you sure you want to force push? (y/N): "
            read -r response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                log "Sync cancelled by user"
                exit 0
            fi
            force_push="true"
        fi
    else
        log "Personal remote branch doesn't exist, will create it"
    fi
    
    # Push to personal remote
    log "Pushing to personal remote..."
    if [ "$force_push" = "true" ]; then
        warning "Force pushing to personal remote..."
        git push --force "$PERSONAL_REMOTE" "$branch"
    else
        git push "$PERSONAL_REMOTE" "$branch"
    fi
    
    success "Successfully synced from client to personal remote!"
}

# Show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [branch_name]"
    echo ""
    echo "This script syncs code from client account back to personal/org account"
    echo "WARNING: This can overwrite your personal remote history!"
    echo ""
    echo "Options:"
    echo "  --force        Force push without confirmation (dangerous)"
    echo "  -h, --help     Show this help message"
    echo ""
    echo "Arguments:"
    echo "  branch_name    Branch to sync (default: main)"
    echo ""
    echo "Examples:"
    echo "  sync                  # Sync main branch (with confirmation)"
    echo "  sync develop          # Sync develop branch"
    echo "  sync --force          # Force sync main branch (no confirmation)"
}

# Parse command line arguments
force_push=false
branch="main"

while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            force_push=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -*)
            error "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            branch="$1"
            shift
            ;;
    esac
done

# Main execution
main() {
    log "🔄 Starting reverse sync process..."
    
    # Run safety checks
    check_git_repo
    check_remotes
    
    # Perform the sync
    sync_from_client "$branch" "$force_push"
    
    echo ""
    success "🎉 Reverse sync completed successfully!"
    log "Your personal remote now has the latest code from client account"
    log "You can now continue working with your personal identity"
}

# Run main function
main
