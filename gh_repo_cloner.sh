#!/bin/bash

# GitHub Organization Repository Cloner
# Clones all accessible repos from an organization into ./pub and ./priv directories

set -e  # Exit on any error

# Configuration
CONFIG_FILE="config.txt"
PUB_DIR="./pub"
PRIV_DIR="./priv"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if gh CLI is installed
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI (gh) is not installed. Please install it first."
        print_error "Visit: https://cli.github.com/"
        exit 1
    fi
}

# Function to read config file
read_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_error "Config file '$CONFIG_FILE' not found."
        print_error "Please create a config file with the organization name."
        print_error "Example: echo 'microsoft' > $CONFIG_FILE"
        exit 1
    fi
    
    ORG_NAME=$(cat "$CONFIG_FILE" | tr -d '[:space:]')
    
    if [[ -z "$ORG_NAME" ]]; then
        print_error "Config file is empty. Please add the organization name."
        exit 1
    fi
    
    print_status "Organization: $ORG_NAME"
}

# Function to check authentication status
check_auth() {
    print_status "Checking GitHub authentication status..."
    
    if gh auth status &> /dev/null; then
        print_success "Authenticated with GitHub"
        AUTHENTICATED=true
        # Get the authenticated user
        AUTH_USER=$(gh api user --jq .login 2>/dev/null || echo "unknown")
        print_status "Authenticated as: $AUTH_USER"
    else
        print_warning "Not authenticated with GitHub"
        print_warning "You will only see public repositories"
        print_warning "Run 'gh auth login' to access private repositories"
        AUTHENTICATED=false
    fi
}

# Function to create directories
create_directories() {
    print_status "Creating directories..."
    mkdir -p "$PUB_DIR" "$PRIV_DIR"
    print_success "Directories created: $PUB_DIR, $PRIV_DIR"
}

# Function to get repository list
get_repo_list() {
    print_status "Fetching repository list for $ORG_NAME..."
    
    # Try to get repos with visibility info
    if ! REPO_JSON=$(gh repo list "$ORG_NAME" --limit 1000 --json name,isPrivate,sshUrl,visibility 2>/dev/null); then
        print_error "Failed to fetch repositories for organization '$ORG_NAME'"
        print_error "Please check:"
        print_error "1. Organization name is correct"
        print_error "2. Organization exists and is accessible"
        print_error "3. You have proper permissions (if accessing private repos)"
        exit 1
    fi
    
    # Check if we got any repos
    REPO_COUNT=$(echo "$REPO_JSON" | jq length)
    
    if [[ "$REPO_COUNT" -eq 0 ]]; then
        print_warning "No repositories found for organization '$ORG_NAME'"
        print_warning "This could mean:"
        print_warning "1. Organization has no repositories"
        print_warning "2. All repositories are private and you lack access"
        print_warning "3. Organization name is incorrect"
        exit 0
    fi
    
    print_success "Found $REPO_COUNT repositories"
}

# Function to clone repositories
clone_repositories() {
    print_status "Starting repository cloning..."
    
    PUBLIC_COUNT=0
    PRIVATE_COUNT=0
    FAILED_COUNT=0
    
    # Process each repository
    echo "$REPO_JSON" | jq -r '.[] | @base64' | while IFS= read -r repo_data; do
        # Decode the base64 data
        repo_info=$(echo "$repo_data" | base64 --decode)
        
        # Extract repository details
        repo_name=$(echo "$repo_info" | jq -r .name)
        is_private=$(echo "$repo_info" | jq -r .isPrivate)
        ssh_url=$(echo "$repo_info" | jq -r .sshUrl)
        visibility=$(echo "$repo_info" | jq -r .visibility)
        
        # Determine target directory
        if [[ "$is_private" == "true" ]]; then
            target_dir="$PRIV_DIR"
            repo_type="private"
        else
            target_dir="$PUB_DIR"
            repo_type="public"
        fi
        
        print_status "Cloning $repo_type repository: $repo_name"
        
        # Check if directory already exists
        if [[ -d "$target_dir/$repo_name" ]]; then
            print_warning "Directory $target_dir/$repo_name already exists, skipping..."
            continue
        fi
        
        # Clone the repository
        if git clone "$ssh_url" "$target_dir/$repo_name" &> /dev/null; then
            print_success "✓ Cloned $repo_name to $target_dir/"
            if [[ "$is_private" == "true" ]]; then
                ((PRIVATE_COUNT++))
            else
                ((PUBLIC_COUNT++))
            fi
        else
            print_error "✗ Failed to clone $repo_name"
            ((FAILED_COUNT++))
        fi
    done
    
    # Print summary (this won't work in the subshell, so we'll do it differently)
}

# Function to clone repositories (fixed version without subshell)
clone_repositories_fixed() {
    print_status "Starting repository cloning..."
    
    PUBLIC_COUNT=0
    PRIVATE_COUNT=0
    FAILED_COUNT=0
    
    # Create temporary file for repo processing
    temp_file=$(mktemp)
    echo "$REPO_JSON" | jq -r '.[] | "\(.name)|\(.isPrivate)|\(.sshUrl)|\(.visibility)"' > "$temp_file"
    
    while IFS='|' read -r repo_name is_private ssh_url visibility; do
        # Determine target directory
        if [[ "$is_private" == "true" ]]; then
            target_dir="$PRIV_DIR"
            repo_type="private"
        else
            target_dir="$PUB_DIR"
            repo_type="public"
        fi
        
        print_status "Cloning $repo_type repository: $repo_name"
        
        # Check if directory already exists
        if [[ -d "$target_dir/$repo_name" ]]; then
            print_warning "Directory $target_dir/$repo_name already exists, skipping..."
            continue
        fi
        
        # Clone the repository
        if git clone "$ssh_url" "$target_dir/$repo_name" &> /dev/null; then
            print_success "✓ Cloned $repo_name to $target_dir/"
            if [[ "$is_private" == "true" ]]; then
                ((PRIVATE_COUNT++))
            else
                ((PUBLIC_COUNT++))
            fi
        else
            print_error "✗ Failed to clone $repo_name"
            ((FAILED_COUNT++))
            
            # Try HTTPS if SSH fails
            https_url="https://github.com/$ORG_NAME/$repo_name.git"
            print_status "Retrying with HTTPS: $repo_name"
            if git clone "$https_url" "$target_dir/$repo_name" &> /dev/null; then
                print_success "✓ Cloned $repo_name to $target_dir/ (via HTTPS)"
                if [[ "$is_private" == "true" ]]; then
                    ((PRIVATE_COUNT++))
                else
                    ((PUBLIC_COUNT++))
                fi
                ((FAILED_COUNT--))
            fi
        fi
    done < "$temp_file"
    
    # Clean up
    rm "$temp_file"
    
    # Print summary
    print_success "Cloning completed!"
    print_status "Summary:"
    print_status "  Public repositories cloned: $PUBLIC_COUNT"
    print_status "  Private repositories cloned: $PRIVATE_COUNT"
    if [[ $FAILED_COUNT -gt 0 ]]; then
        print_warning "  Failed to clone: $FAILED_COUNT"
    fi
}

# Main execution
main() {
    print_status "GitHub Organization Repository Cloner"
    print_status "======================================"
    
    # Check prerequisites
    check_gh_cli
    
    # Read configuration
    read_config
    
    # Check authentication
    check_auth
    
    # Create directories
    create_directories
    
    # Get repository list
    get_repo_list
    
    # Clone repositories
    clone_repositories_fixed
    
    print_success "All done! Check the $PUB_DIR and $PRIV_DIR directories."
}

# Run the script
main "$@"