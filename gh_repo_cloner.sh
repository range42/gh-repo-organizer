#!/bin/bash

# GitHub Organization Repository Cloner
# Clones all accessible repos from an organization into ./pub and ./priv directories

set -e  # Exit on any error

# Global variables
SANITY_CHECK=false

# Configuration
CONFIG_FILE="config.env"

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

# Function to show usage
show_usage() {
    echo "GitHub Organization Repository Cloner"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -s, --sanity-check    Perform sanity checks on repositories for common files"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Sanity checks include:"
    echo "  - LICENSE (with content validation for template placeholders)"
    echo "  - CHANGELOG/CHANGELOG.md"
    echo "  - CONTRIBUTING/CONTRIBUTING.md"
    echo "  - README.md"
    echo "  - .gitignore"
    echo "  - SECURITY.md"
    echo "  - CODE_OF_CONDUCT.md"
    echo "  - .editorconfig"
    echo "  - docs/ directory"
    echo "  - .github/ISSUE_TEMPLATE/ directory"
    echo "  - .github/PULL_REQUEST_TEMPLATE.md"
    echo "  - CI/CD configuration files"
}

# Function to parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--sanity-check)
                SANITY_CHECK=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
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
        print_error "Please create a config file with the required variables."
        print_error "Example config.env content:"
        print_error 'ORG="your-org-name"'
        print_error 'PUB_DIR="./pub"'
        print_error 'PRIV_DIR="./priv"'
        print_error 'RED="\033[0;31m"'
        print_error 'GREEN="\033[0;32m"'
        print_error 'YELLOW="\033[1;33m"'
        print_error 'BLUE="\033[0;34m"'
        print_error 'NC="\033[0m"'
        exit 1
    fi
    
    # Source the config file
    if ! source "$CONFIG_FILE"; then
        print_error "Failed to source config file. Please check syntax."
        exit 1
    fi
    
    # Validate required variables
    if [[ -z "$ORG" ]]; then
        print_error "ORG variable not set in config file."
        print_error "Please add: ORG=\"your-organization-name\""
        exit 1
    fi
    
    # Set default values if not provided
    PUB_DIR=${PUB_DIR:-"./pub"}
    PRIV_DIR=${PRIV_DIR:-"./priv"}
    RED=${RED:-'\033[0;31m'}
    GREEN=${GREEN:-'\033[0;32m'}
    YELLOW=${YELLOW:-'\033[1;33m'}
    BLUE=${BLUE:-'\033[0;34m'}
    NC=${NC:-'\033[0m'}
    
    print_status "Organization: $ORG"
    print_status "Public directory: $PUB_DIR"
    print_status "Private directory: $PRIV_DIR"
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
    print_status "Fetching repository list for $ORG..."
    
    # Try to get repos with visibility info
    if ! REPO_JSON=$(gh repo list "$ORG" --limit 1000 --json name,isPrivate,sshUrl,visibility 2>/dev/null); then
        print_error "Failed to fetch repositories for organization '$ORG'"
        print_error "Please check:"
        print_error "1. Organization name is correct"
        print_error "2. Organization exists and is accessible"
        print_error "3. You have proper permissions (if accessing private repos)"
        exit 1
    fi
    
    # Check if we got any repos
    REPO_COUNT=$(echo "$REPO_JSON" | jq length)
    
    if [[ "$REPO_COUNT" -eq 0 ]]; then
        print_warning "No repositories found for organization '$ORG'"
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
            print_status "Repository $repo_name already exists, updating..."
            
            # Change to repo directory and pull latest changes
            if (cd "$target_dir/$repo_name" && git pull &> /dev/null); then
                print_success "✓ Updated $repo_name in $target_dir/"
                if [[ "$is_private" == "true" ]]; then
                    ((PRIVATE_COUNT++))
                else
                    ((PUBLIC_COUNT++))
                fi
            else
                print_error "✗ Failed to update $repo_name (may have local changes or connection issues)"
                ((FAILED_COUNT++))
            fi
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
            https_url="https://github.com/$ORG/$repo_name.git"
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
    # Parse command line arguments first
    parse_args "$@"
    
    print_status "GitHub Organization Repository Cloner"
    print_status "======================================"
    
    # Check prerequisites
    check_gh_cli
    
    # Read configuration
    read_config
    
    # Check authentication
    check_auth
    
    if [[ "$SANITY_CHECK" == true ]]; then
        # Sanity check mode
        print_status "Running in sanity check mode"
        ensure_repos_cloned
        perform_sanity_checks
    else
        # Normal cloning mode
        # Create directories
        create_directories
        
        # Get repository list
        get_repo_list
        
        # Clone repositories
        clone_repositories_fixed
        
        print_success "All done! Check the $PUB_DIR and $PRIV_DIR directories."
        print_status "Tip: Run with --sanity-check to verify repository standards"
    fi
}

# Function to check if LICENSE file is properly filled out
check_license_content() {
    local repo_path="$1"
    local license_file=""
    
    # Find the LICENSE file (case-insensitive)
    local license_variants=("LICENSE" "LICENSE.txt" "LICENSE.md" "license" "license.txt" "license.md")
    
    for variant in "${license_variants[@]}"; do
        if [[ -e "$repo_path/$variant" ]]; then
            license_file="$repo_path/$variant"
            break
        fi
    done
    
    if [[ -z "$license_file" ]]; then
        echo "MISSING"
        return
    fi
    
    # Read the license file content
    local license_content
    if ! license_content=$(cat "$license_file" 2>/dev/null); then
        echo "PRESENT"  # File exists but can't read it
        return
    fi
    
    # Check for common template placeholders (case-insensitive)
    local placeholders=(
        "<year>"
        "<name of author>"
        "<name of copyright owner>"
        "<copyright holders>"
        "<author>"
        "<owner>"
        "\[year\]"
        "\[name\]"
        "\[author\]"
        "YYYY"
        "COPYRIGHT_HOLDER"
        "AUTHOR_NAME"
        "YOUR_NAME"
        "YOUR NAME"
    )
    
    # Convert to lowercase for case-insensitive matching
    local content_lower=$(echo "$license_content" | tr '[:upper:]' '[:lower:]')
    
    # Check for placeholders
    for placeholder in "${placeholders[@]}"; do
        # Convert placeholder to lowercase for comparison
        local placeholder_lower=$(echo "$placeholder" | tr '[:upper:]' '[:lower:]')
        if echo "$content_lower" | grep -q "$placeholder_lower"; then
            echo "TEMPLATE"
            return
        fi
    done
    
    echo "COMPLETE"
}

# Function to check for common files in a repository
check_repo_files() {
    local repo_path="$1"
    local repo_name="$2"
    local results=""
    
    # Files to check for (case-insensitive) - LICENSE handled separately
    local files_to_check=(
        "CHANGELOG:CHANGELOG,CHANGELOG.md,CHANGELOG.txt,changelog,changelog.md,changelog.txt,HISTORY.md,RELEASES.md"
        "CONTRIBUTING:CONTRIBUTING,CONTRIBUTING.md,CONTRIBUTING.txt,contributing,contributing.md,contributing.txt"
        "README:README.md,README.txt,README,readme.md,readme.txt,readme"
        "GITIGNORE:.gitignore"
        "SECURITY:SECURITY.md,SECURITY.txt,SECURITY,security.md,security.txt,security"
        "CODE_OF_CONDUCT:CODE_OF_CONDUCT.md,CODE_OF_CONDUCT.txt,CODE_OF_CONDUCT,code_of_conduct.md,code_of_conduct.txt,code_of_conduct"
        "EDITORCONFIG:.editorconfig"
    )
    
    # Directory-based checks
    local dir_checks=(
        "DOCS:docs,Docs,DOCS,documentation,Documentation"
        "ISSUE_TEMPLATES:.github/ISSUE_TEMPLATE,.github/issue_template"
    )
    
    # File-based GitHub checks
    local github_files=(
        "PR_TEMPLATE:.github/PULL_REQUEST_TEMPLATE.md,.github/pull_request_template.md,.github/PULL_REQUEST_TEMPLATE,.github/pull_request_template"
    )
    
    # CI/CD files to check for
    local cicd_files=(
        ".github/workflows"
        ".gitlab-ci.yml"
        ".travis.yml"
        "Jenkinsfile"
        ".circleci"
        "azure-pipelines.yml"
        ".buildkite"
        "bitbucket-pipelines.yml"
    )
    
    print_status "Checking $repo_name..."
    
    # Check LICENSE file specifically (with content validation)
    license_status=$(check_license_content "$repo_path")
    case "$license_status" in
        "MISSING")
            results+="✗ LICENSE "
            ;;
        "TEMPLATE") 
            results+="⚠ LICENSE "
            ;;
        "PRESENT"|"COMPLETE")
            results+="✓ LICENSE "
            ;;
    esac
    
    # Check for standard files
    for file_check in "${files_to_check[@]}"; do
        IFS=':' read -r file_type file_variants <<< "$file_check"
        IFS=',' read -ra variants <<< "$file_variants"
        
        found=false
        for variant in "${variants[@]}"; do
            if [[ -e "$repo_path/$variant" ]]; then
                results+="✓ $file_type "
                found=true
                break
            fi
        done
        
        if [[ "$found" == false ]]; then
            results+="✗ $file_type "
        fi
    done
    
    # Check for directories
    for dir_check in "${dir_checks[@]}"; do
        IFS=':' read -r dir_type dir_variants <<< "$dir_check"
        IFS=',' read -ra variants <<< "$dir_variants"
        
        found=false
        for variant in "${variants[@]}"; do
            if [[ -d "$repo_path/$variant" ]]; then
                results+="✓ $dir_type "
                found=true
                break
            fi
        done
        
        if [[ "$found" == false ]]; then
            results+="✗ $dir_type "
        fi
    done
    
    # Check for GitHub-specific files
    for github_check in "${github_files[@]}"; do
        IFS=':' read -r github_type github_variants <<< "$github_check"
        IFS=',' read -ra variants <<< "$github_variants"
        
        found=false
        for variant in "${variants[@]}"; do
            if [[ -e "$repo_path/$variant" ]]; then
                results+="✓ $github_type "
                found=true
                break
            fi
        done
        
        if [[ "$found" == false ]]; then
            results+="✗ $github_type "
        fi
    done
    
    # Check for CI/CD files
    cicd_found=false
    for cicd_file in "${cicd_files[@]}"; do
        if [[ -e "$repo_path/$cicd_file" ]]; then
            cicd_found=true
            break
        fi
    done
    
    if [[ "$cicd_found" == true ]]; then
        results+="✓ CI/CD "
    else
        results+="✗ CI/CD "
    fi
    
    echo "$results"
}

# Function to perform sanity checks on all repositories
perform_sanity_checks() {
    print_status "Performing sanity checks on repositories..."
    print_status "========================================"
    
    # Track results
    local total_repos=0
    local perfect_repos=0
    
    # Check public repositories
    if [[ -d "$PUB_DIR" ]]; then
        print_status "Checking public repositories in $PUB_DIR:"
        for repo_dir in "$PUB_DIR"/*; do
            if [[ -d "$repo_dir" ]]; then
                repo_name=$(basename "$repo_dir")
                result=$(check_repo_files "$repo_dir" "$repo_name")
                echo "  $repo_name: $result"
                ((total_repos++))
                
                # Check if all checks passed (no ✗ or ⚠ symbols)
                if [[ "$result" != *"✗"* ]] && [[ "$result" != *"⚠"* ]]; then
                    ((perfect_repos++))
                fi
            fi
        done
    fi
    
    # Check private repositories
    if [[ -d "$PRIV_DIR" ]]; then
        print_status "Checking private repositories in $PRIV_DIR:"
        for repo_dir in "$PRIV_DIR"/*; do
            if [[ -d "$repo_dir" ]]; then
                repo_name=$(basename "$repo_dir")
                result=$(check_repo_files "$repo_dir" "$repo_name")
                echo "  $repo_name: $result"
                ((total_repos++))
                
                # Check if all checks passed (no ✗ or ⚠ symbols)
                if [[ "$result" != *"✗"* ]] && [[ "$result" != *"⚠"* ]]; then
                    ((perfect_repos++))
                fi
            fi
        done
    fi
    
    # Print summary
    print_status "Sanity Check Summary:"
    print_status "====================="
    print_status "Total repositories checked: $total_repos"
    print_success "Repositories with all files: $perfect_repos"
    
    if [[ $perfect_repos -lt $total_repos ]]; then
        missing_count=$((total_repos - perfect_repos))
        print_warning "Repositories missing files: $missing_count"
        
        print_status "Legend:"
        print_status "  ✓ = File/directory present and complete"
        print_status "  ✗ = File/directory missing"
        print_status "  ⚠ = LICENSE present but contains template placeholders"
        print_status ""
        print_status "Checks performed:"
        print_status "  LICENSE (with content validation), CHANGELOG, CONTRIBUTING, README, .gitignore"
        print_status "  SECURITY, CODE_OF_CONDUCT, .editorconfig"
        print_status "  docs/, .github/ISSUE_TEMPLATE/, .github/PULL_REQUEST_TEMPLATE.md"
        print_status "  CI/CD configuration files"
    fi
}

# Function to ensure repositories are cloned before sanity check
ensure_repos_cloned() {
    local need_cloning=false
    
    # Check if we have any repositories cloned
    if [[ ! -d "$PUB_DIR" ]] && [[ ! -d "$PRIV_DIR" ]]; then
        need_cloning=true
    else
        # Check if directories exist but are empty
        if [[ -d "$PUB_DIR" ]] && [[ -z "$(ls -A "$PUB_DIR" 2>/dev/null)" ]]; then
            if [[ -d "$PRIV_DIR" ]] && [[ -z "$(ls -A "$PRIV_DIR" 2>/dev/null)" ]]; then
                need_cloning=true
            fi
        fi
    fi
    
    if [[ "$need_cloning" == true ]]; then
        print_status "No repositories found locally. Cloning first..."
        get_repo_list
        clone_repositories_fixed
    else
        print_status "Using existing repository clones for sanity check"
    fi
}

# Run the script
main "$@"