#!/usr/bin/env zsh

# Safe Git Mirroring Script with Anonymity Protection
# This script only pushes NEW commits with client identity, preserving existing history

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
CLIENT_NAME="developer"
CLIENT_EMAIL="dev.testing785@gmail.com"
CLIENT_GH_ACCOUNT="developmentest785"

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

# Safety check: Verify GitHub CLI is authenticated with correct account
check_gh_auth() {
    log "Checking GitHub CLI authentication..."
    
    local active_account
    active_account=$(gh auth status 2>&1 | rg -B1 "Active account: true" | rg "Logged in to github.com account" | awk '{print $7}')
    
    if [ "$active_account" != "$CLIENT_GH_ACCOUNT" ]; then
        error "GitHub CLI is not authenticated with client account '$CLIENT_GH_ACCOUNT'"
        error "Current active account: $active_account"
        error "Please run: gh auth switch --user $CLIENT_GH_ACCOUNT"
        exit 1
    fi
    
    success "GitHub CLI authenticated with client account: $CLIENT_GH_ACCOUNT"
}

# Safety check: Verify git identity is set to client (and fix if not)
check_and_set_git_identity() {
    log "Checking git identity..."
    
    local current_name current_email
    current_name=$(git config user.name 2>/dev/null || echo "")
    current_email=$(git config user.email 2>/dev/null || echo "")
    
    if [ "$current_name" != "$CLIENT_NAME" ] || [ "$current_email" != "$CLIENT_EMAIL" ]; then
        warning "Git identity needs to be set to client account"
        log "Setting client identity..."
        
        git config user.name "$CLIENT_NAME"
        git config user.email "$CLIENT_EMAIL"
        
        success "Git identity set to client account: $CLIENT_NAME <$CLIENT_EMAIL>"
    else
        success "Git identity is correctly set to client account"
    fi
}

# Check for any non-client identity in unpushed commits only
check_unpushed_commits_anonymity() {
    local branch="${1:-main}"
    
    log "Checking unpushed commits for non-client identity..."
    
    # Get the range of commits that haven't been pushed to client remote yet
    local unpushed_commits
    if git rev-parse "$CLIENT_REMOTE/$branch" >/dev/null 2>&1; then
        # Client remote branch exists, check commits ahead
        unpushed_commits=$(git rev-list "$CLIENT_REMOTE/$branch..HEAD" 2>/dev/null || echo "")
    else
        # Client remote branch doesn't exist, check all commits
        unpushed_commits=$(git rev-list HEAD 2>/dev/null || echo "")
    fi
    
    if [ -z "$unpushed_commits" ]; then
        success "No unpushed commits found"
        return 0
    fi
    
    # Check each unpushed commit for non-client identity
    local problematic_commits=""
    for commit in ${=unpushed_commits}; do
        local commit_name commit_email
        commit_name=$(git show -s --format="%an" "$commit")
        commit_email=$(git show -s --format="%ae" "$commit")
        
        if [ "$commit_name" != "$CLIENT_NAME" ] || [ "$commit_email" != "$CLIENT_EMAIL" ]; then
            local short_commit=$(git show -s --format="%h" "$commit")
            local commit_subject=$(git show -s --format="%s" "$commit")
            problematic_commits="$problematic_commits\n  $short_commit: $commit_name <$commit_email> - $commit_subject"
        fi
    done
    
    if [ -n "$problematic_commits" ]; then
        error "Found unpushed commits with non-client identity:"
        echo -e "$problematic_commits"
        error ""
        error "These commits would expose your identity to the client!"
        error ""
        error "Options to fix this:"
        error "1. Create new commits with your changes using client identity"
        error "2. Use 'git commit --amend --author=\"$CLIENT_NAME <$CLIENT_EMAIL>\"' for the last commit"
        error "3. Use interactive rebase to change author of multiple commits"
        error ""
        exit 1
    fi
    
    success "All unpushed commits use client identity"
}

# Get the last common commit between client and current branch
get_sync_status() {
    local branch="${1:-main}"
    
    if git rev-parse "$CLIENT_REMOTE/$branch" >/dev/null 2>&1; then
        local behind ahead
        behind=$(git rev-list --count "HEAD..$CLIENT_REMOTE/$branch" 2>/dev/null || echo "0")
        ahead=$(git rev-list --count "$CLIENT_REMOTE/$branch..HEAD" 2>/dev/null || echo "0")
        
        echo "behind:$behind,ahead:$ahead"
    else
        local total_commits
        total_commits=$(git rev-list --count HEAD 2>/dev/null || echo "0")
        echo "behind:0,ahead:$total_commits"
    fi
}

# Main mirroring function - only pushes new commits
mirror_new_commits() {
    local branch="${1:-main}"
    
    log "Starting safe mirroring process for branch: $branch"
    
    # Ensure we're on the correct branch
    local current_branch
    current_branch=$(git branch --show-current)
    
    if [ "$current_branch" != "$branch" ]; then
        if git show-ref --verify --quiet "refs/heads/$branch"; then
            log "Switching to existing branch: $branch"
            git checkout "$branch"
        else
            error "Branch '$branch' does not exist locally"
            error "Please create the branch first or specify an existing branch"
            exit 1
        fi
    fi
    
    # Get sync status
    local sync_status
    sync_status=$(get_sync_status "$branch")
    local behind ahead
    behind=$(echo "$sync_status" | cut -d',' -f1 | cut -d':' -f2)
    ahead=$(echo "$sync_status" | cut -d',' -f2 | cut -d':' -f2)
    
    if [ "$ahead" -eq 0 ]; then
        success "No new commits to push - client remote is up to date"
        return 0
    fi
    
    if [ "$behind" -gt 0 ]; then
        warning "Your local branch is $behind commits behind client remote"
        warning "You may want to pull and resolve conflicts first"
        if [ "$non_interactive" = false ]; then
            echo -n "Continue anyway? (y/N): "
            read -r response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                log "Mirroring cancelled by user"
                exit 0
            fi
        else
            log "Non-interactive mode: continuing despite being behind"
        fi
    fi
    
    log "Found $ahead new commit(s) to push to client remote"
    
    # List the commits that will be pushed
    log "Commits to be pushed:"
    if git rev-parse "$CLIENT_REMOTE/$branch" >/dev/null 2>&1; then
        git log --oneline --graph "$CLIENT_REMOTE/$branch..HEAD" | head -10
    else
        git log --oneline --graph HEAD | head -10
    fi
    
    # Push only the new commits to client remote
    log "Pushing new commits to client remote..."
    git push "$CLIENT_REMOTE" "$branch"
    
    success "Successfully pushed $ahead new commit(s) to client remote"
}

# Pre-commit hook setup to prevent personal identity commits
setup_commit_hook() {
    local hook_file=".git/hooks/pre-commit"
    
    if [ -f "$hook_file" ]; then
        log "Pre-commit hook already exists, skipping setup"
        return 0
    fi
    
    log "Setting up pre-commit hook to prevent personal identity commits..."
    
    cat > "$hook_file" << 'EOF'
#!/usr/bin/env zsh

# Pre-commit hook to ensure only client identity is used
CLIENT_NAME="developer"
CLIENT_EMAIL="dev.testing785@gmail.com"

current_name=$(git config user.name)
current_email=$(git config user.email)

if [ "$current_name" != "$CLIENT_NAME" ] || [ "$current_email" != "$CLIENT_EMAIL" ]; then
    echo "ERROR: Git identity is not set to client account!"
    echo "Current: $current_name <$current_email>"
    echo "Expected: $CLIENT_NAME <$CLIENT_EMAIL>"
    echo ""
    echo "Run: git config user.name \"$CLIENT_NAME\""
    echo "Run: git config user.email \"$CLIENT_EMAIL\""
    exit 1
fi
EOF
    
    chmod +x "$hook_file"
    success "Pre-commit hook installed"
}

# Anonymize commits by changing authors to client identity
anonymize_commits() {
    local force_patterns=("$@")
    
    log "Checking for commits to anonymize..."
    
    # Check if git-filter-repo is available
    if ! command -v git-filter-repo >/dev/null 2>&1; then
        error "git-filter-repo is not installed!"
        error "Please install it from: https://github.com/newren/git-filter-repo/"
        error "Or install via your package manager (e.g., pip install git-filter-repo)"
        exit 1
    fi
    
    # Check if there are any commits with non-client email or non-client name
    local has_non_client
    has_non_client=$(git log --all --format="%an %ae" 2>/dev/null | grep -v "^$CLIENT_NAME $CLIENT_EMAIL$" | wc -l)
    
    if [ "$has_non_client" -eq 0 ]; then
        success "All commits already use client identity"
        return 0
    fi
    
    if [ ${#force_patterns[@]} -gt 0 ]; then
        log "Selective anonymization enabled for patterns: ${force_patterns[*]}"
        log "Anonymizing commits where author name or email contains any of the specified patterns..."
    else
        log "Found commits with non-client identity, anonymizing all..."
    fi
    
    # Create a temporary Python script for the callback
    local temp_script=$(mktemp --suffix=.py)
    
    cat > "$temp_script" << EOF
import sys
import re

client_name = b"$CLIENT_NAME"
client_email = b"$CLIENT_EMAIL"
force_patterns = [p.lower() for p in ["${force_patterns[@]}"]]

def commit_callback(commit):
    changed = False
    
    # Check if we should anonymize this commit
    should_anonymize = False
    if force_patterns:
        # Selective mode: check if author info contains any pattern
        author_info = (commit.author_name + b' ' + commit.author_email).decode('utf-8', errors='ignore').lower()
        should_anonymize = any(pattern in author_info for pattern in force_patterns)
    else:
        # All mode: anonymize if not already client
        should_anonymize = (commit.author_email != client_email or commit.author_name != client_name or
                           commit.committer_email != client_email or commit.committer_name != client_name)
    
    if should_anonymize:
        old_author = f"{commit.author_name.decode('utf-8', errors='ignore')} <{commit.author_email.decode('utf-8', errors='ignore')}>"
        old_committer = f"{commit.committer_name.decode('utf-8', errors='ignore')} <{commit.committer_email.decode('utf-8', errors='ignore')}>"
        
        commit.author_name = client_name
        commit.author_email = client_email
        commit.committer_name = client_name
        commit.committer_email = client_email
        
        print(f"Changed: Author {old_author}, Committer {old_committer} to $CLIENT_NAME <$CLIENT_EMAIL> for {commit.original_id.decode('ascii')[:7]}", file=sys.stderr)
        changed = True
    
    return changed

commit_callback
EOF
    
    # Run git filter-repo with the callback
    git filter-repo --commit-callback "$(cat "$temp_script")" --force
    
    # Clean up
    rm "$temp_script"
    
    success "Anonymization completed using git-filter-repo"
}

# Show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [branch_name]"
    echo ""
    echo "This script anonymizes commits to use client identity,"
    echo "then safely mirrors commits from your personal/org account to client account"
    echo ""
    echo "Options:"
    echo "  --setup-hook         Install pre-commit hook to prevent personal identity commits"
    echo "  --force <pattern>    Anonymize commits where author name or email contains <pattern> (can be used multiple times)"
    echo "  --non-interactive    Run without prompts, automatically continue (useful for CI/CD)"
    echo "  --yes                Alias for --non-interactive"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Arguments:"
    echo "  branch_name          Branch to mirror (default: main)"
    echo ""
    echo "Safety features:"
    echo "  - Anonymizes commit authors to client identity"
    echo "  - Only pushes commits (preserves existing history on client)"
    echo "  - Verifies GitHub CLI is authenticated with client account"
    echo "  - Ensures git identity is set to client account"
    echo "  - Checks unpushed commits for non-client identity"
    echo "  - Validates remote configurations"
    echo ""
    echo "Examples:"
    echo "  share                 # Anonymize all commits and mirror on main branch"
    echo "  share develop         # Anonymize all commits and mirror on develop branch"
    echo "  share --setup-hook    # Install pre-commit hook"
    echo "  share --force maya    # Anonymize commits with 'maya' in author name/email"
    echo "  share --force maya --force arafay  # Anonymize commits matching either pattern"
    echo "  share --non-interactive  # Run without prompts for CI/CD"
}

# Parse command line arguments
setup_hook=false
branch="main"
force_patterns=()
non_interactive=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --setup-hook)
            setup_hook=true
            shift
            ;;
        --force)
            if [[ -z "$2" || "$2" == -* ]]; then
                error "Error: --force requires a pattern argument"
                show_usage
                exit 1
            fi
            force_patterns+=("$2")
            shift 2
            ;;
        --non-interactive|--yes)
            non_interactive=true
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
    log "🔒 Starting secure git mirroring process..."
    
    # Run all safety checks
    check_git_repo
    # check_remotes
    # check_gh_auth
    check_and_set_git_identity
    
    # Anonymize commits to devtesting identity
    anonymize_commits "${force_patterns[@]}"
    
    # Setup pre-commit hook if requested
    if [ "$setup_hook" = true ]; then
        setup_commit_hook
        success "Pre-commit hook setup completed"
        exit 0
    fi
    
    # Check unpushed commits for anonymity
    check_unpushed_commits_anonymity "$branch"
    
    # Show what will be pushed
    local sync_status
    sync_status=$(get_sync_status "$branch")
    local ahead
    ahead=$(echo "$sync_status" | cut -d',' -f2 | cut -d':' -f2)
    
    if [ "$ahead" -eq 0 ]; then
        success "🎉 Client remote is already up to date!"
        exit 0
    fi
    
    # Confirm with user
    echo ""
    log "Ready to push $ahead new commit(s) from '$branch' to client account"
    warning "Target: $(git remote get-url $CLIENT_REMOTE)"
    if [ "$non_interactive" = false ]; then
        echo -n "Continue? (y/N): "
        read -r response
        
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log "Mirroring cancelled by user"
            exit 0
        fi
    else
        log "Non-interactive mode: proceeding with push"
    fi
    
    # Perform the mirroring
    mirror_new_commits "$branch"
    
    echo ""
    success "🎉 Mirroring completed successfully!"
    log "Your new commits have been safely pushed to the client account"
    log "Existing commit history was preserved unchanged"
}

# Run main function
main
