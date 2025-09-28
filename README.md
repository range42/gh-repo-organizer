# GitHub Organization Repository Cloner

**GitHub Organization Repository Cloner - Automatically clone and audit all repositories from a GitHub organization with comprehensive standards compliance checking.**

A powerful bash script for cloning and auditing all repositories from a GitHub organization. Automatically organizes repositories into public and private directories, with comprehensive sanity checks for repository standards compliance.

## Features

- **Mass Repository Cloning**: Clone all accessible repositories from any GitHub organization
- **Smart Organization**: Automatically separates public and private repositories into dedicated directories
- **Automatic Updates**: Existing repositories are automatically updated with `git pull`
- **Authentication Aware**: Works with or without GitHub authentication (limited to public repos when unauthenticated)
- **Comprehensive Sanity Checks**: Audit repositories for standard files and best practices with line-by-line output
- **Repository Filtering**: Run sanity checks on specific repositories for focused analysis
- **Flexible Configuration**: Environment-based configuration for easy customization
- **Robust Error Handling**: Graceful handling of failed clones with HTTPS fallback
- **Colored Output**: Clear, colored terminal output for better visibility

## Quick Start

1. **Install Prerequisites**:
   ```bash
   # Install GitHub CLI
   brew install gh  # macOS
   # or
   sudo apt install gh  # Ubuntu/Debian
   
   # Install jq for JSON parsing
   brew install jq  # macOS
   # or  
   sudo apt install jq  # Ubuntu/Debian
   ```

2. **Configure the Script**:
   ```bash
   # Create configuration file
   cp config.env.example config.env
   # Edit with your organization name
   vim config.env
   ```

3. **Run the Script**:
   ```bash
   # Clone all repositories
   ./gh_repo_cloner.sh
   
   # Perform sanity checks on all repositories
   ./gh_repo_cloner.sh --sanity-check
   
   # Check a specific repository
   ./gh_repo_cloner.sh --sanity-check my-repo-name
   ```

## Prerequisites

- **GitHub CLI (`gh`)** - For repository listing and authentication
- **Git** - For cloning repositories  
- **jq** - For JSON parsing
- **Bash 4.0+** - For script execution

## Configuration

Create a `config.env` file with the following variables:

```bash
# Required: Organization name
ORG="your-organization-name"

# Optional: Directory paths (defaults shown)
PUB_DIR="./pub"
PRIV_DIR="./priv"

# Optional: Colors for output (defaults shown)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color
```

### Configuration Options

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `ORG` | GitHub organization name | - | Yes |
| `PUB_DIR` | Directory for public repositories | `./pub` | No |
| `PRIV_DIR` | Directory for private repositories | `./priv` | No |
| `RED`, `GREEN`, etc. | Terminal colors | ANSI codes | No |

## Usage

### Basic Commands

```bash
# Show help
./gh_repo_cloner.sh --help

# Clone all repositories  
./gh_repo_cloner.sh

# Perform sanity checks on all repositories
./gh_repo_cloner.sh --sanity-check

# Perform sanity check on a specific repository
./gh_repo_cloner.sh --sanity-check my-repository-name

# Alternative syntax (short form)
./gh_repo_cloner.sh -s my-repository-name
```

### Command Line Options

| Option | Description |
|--------|-------------|
| `-s, --sanity-check [REPO]` | Perform sanity checks on repositories for common files. Optionally specify a specific repository name to check |
| `-h, --help` | Show help message and exit |

### Usage Examples

```bash
# Clone all repositories from the organization
./gh_repo_cloner.sh

# Run comprehensive sanity checks on all repositories
./gh_repo_cloner.sh --sanity-check

# Check only the "range42-inventory" repository
./gh_repo_cloner.sh --sanity-check range42-inventory

# Check only the "my-backend-api" repository (short form)
./gh_repo_cloner.sh -s my-backend-api
```

## Repository Filtering

The script supports filtering sanity checks to specific repositories, which is useful for:

- **Focused Analysis**: Check a single repository without noise from others
- **Quick Validation**: Verify fixes on specific repositories
- **Onboarding**: Show new developers the standards for a particular project
- **CI Integration**: Validate specific repositories in automated workflows

### Filter Behavior

- **Automatic Discovery**: The script searches for the specified repository in both `./pub` and `./priv` directories
- **Error Handling**: If the repository isn't found, it lists all available repositories
- **Focused Output**: Shows results only for the specified repository with a streamlined summary

### Filter Examples

```bash
# Check the "awesome-project" repository
./gh_repo_cloner.sh -s awesome-project

# Output shows only results for that repository:
# [INFO] Checking repository: awesome-project
# [INFO] awesome-project:
#   ✓ LICENSE
#   ✗ CHANGELOG
#   ...
# [INFO] Repository checked: awesome-project
# [SUCCESS] Repository has all required files!
```

## Sanity Checks

The script can audit repositories for compliance with common standards and best practices:

### Files Checked

| Category | Files/Directories |
|----------|-------------------|
| **License** | `LICENSE`, `LICENSE.txt`, `LICENSE.md`, `COPYING`, `COPYRIGHT` (with content validation) |
| **Documentation** | `README.md`, `README.txt`, `README` |
| **Changelog** | `CHANGELOG.md`, `HISTORY.md`, `RELEASES.md` |
| **Contributing** | `CONTRIBUTING.md`, `CONTRIBUTING.txt` |
| **Security** | `SECURITY.md`, `SECURITY.txt` |
| **Code of Conduct** | `CODE_OF_CONDUCT.md` |
| **Git Configuration** | `.gitignore` |
| **Editor Configuration** | `.editorconfig` |
| **Documentation Directory** | `docs/`, `documentation/` |
| **GitHub Templates** | `.github/ISSUE_TEMPLATE/`, `.github/PULL_REQUEST_TEMPLATE.md` |

### CI/CD Detection

The script automatically detects various CI/CD configurations:

- **GitHub Actions** - `.github/workflows/`
- **GitLab CI** - `.gitlab-ci.yml`
- **Travis CI** - `.travis.yml`
- **Jenkins** - `Jenkinsfile`
- **CircleCI** - `.circleci/`
- **Azure Pipelines** - `azure-pipelines.yml`
- **Buildkite** - `.buildkite/`
- **Bitbucket Pipelines** - `bitbucket-pipelines.yml`

### LICENSE Content Validation

The script goes beyond just checking for the presence of a LICENSE file - it also validates that the license has been properly filled out. It detects common template placeholders that indicate an incomplete license:

**Template Placeholders Detected:**
- `<year>`, `[year]`, `YYYY` - Year placeholders
- `<name of author>`, `<author>`, `<owner>` - Author placeholders
- `<name of copyright owner>`, `<copyright holders>` - Copyright placeholders
- `COPYRIGHT_HOLDER`, `AUTHOR_NAME`, `YOUR_NAME`, `YOUR NAME` - Common template variables

**LICENSE File Variants Detected:**
- Standard names: `LICENSE`, `LICENSE.txt`, `LICENSE.md`, `LICENSE.rst`
- Case variations: `license`, `License`
- Alternative names: `COPYING`, `COPYRIGHT` (common in some projects)
- All checked with proper file type validation (not directories or symlinks)

**LICENSE Status Indicators:**
- **✓ LICENSE** - File present and properly filled out
- **⚠ LICENSE (contains template placeholders)** - File present but needs customization
- **✗ LICENSE** - File missing entirely

## Example Output

### Repository Cloning
```
[INFO] GitHub Organization Repository Cloner
[INFO] ======================================
[SUCCESS] Authenticated with GitHub
[INFO] Authenticated as: username
[INFO] Organization: awesome-org
[INFO] Found 25 repositories
[INFO] Repository awesome-project already exists, updating...
[SUCCESS] ✓ Updated awesome-project in ./pub/
[SUCCESS] ✓ Cloned new-secret-sauce to ./priv/
[ERROR] ✗ Failed to update modified-repo (may have local changes or connection issues)
[SUCCESS] Cloning completed!
[INFO] Summary:
[INFO]   Public repositories cloned: 12
[INFO]   Private repositories cloned: 8
[WARNING]   Failed to clone: 5
```

### Sanity Check Results (All Repositories)
```
[INFO] Checking public repositories in ./pub:

awesome-project:
  ✓ LICENSE
  ✓ CHANGELOG
  ✓ CONTRIBUTING
  ✓ README
  ✓ GITIGNORE
  ✓ SECURITY
  ✓ CODE_OF_CONDUCT
  ✓ EDITORCONFIG
  ✓ DOCS
  ✓ ISSUE_TEMPLATES
  ✓ PR_TEMPLATE
  ✓ CI/CD

legacy-tool:
  ⚠ LICENSE (contains template placeholders)
  ✗ CHANGELOG
  ✗ CONTRIBUTING
  ✓ README
  ✓ GITIGNORE
  ✗ SECURITY
  ✗ CODE_OF_CONDUCT
  ✗ EDITORCONFIG
  ✗ DOCS
  ✗ ISSUE_TEMPLATES
  ✗ PR_TEMPLATE
  ✓ CI/CD

[INFO] Sanity Check Summary:
[INFO] =====================
[INFO] Total repositories checked: 25
[SUCCESS] Repositories with all files: 8
[WARNING] Repositories missing files: 17

[INFO] Legend:
[INFO]   ✓ = File/directory present and complete
[INFO]   ✗ = File/directory missing  
[INFO]   ⚠ = LICENSE present but contains template placeholders
```

### Sanity Check Results (Single Repository)
```
[INFO] Running sanity check on repository: range42-inventory
[INFO] Checking repository: range42-inventory

[INFO] range42-inventory:
  ⚠ LICENSE (contains template placeholders)
  ✗ CHANGELOG
  ✗ CONTRIBUTING
  ✓ README
  ✓ GITIGNORE
  ✗ SECURITY
  ✗ CODE_OF_CONDUCT
  ✗ EDITORCONFIG
  ✗ DOCS
  ✗ ISSUE_TEMPLATES
  ✗ PR_TEMPLATE
  ✗ CI/CD

[INFO] Sanity Check Summary:
[INFO] =====================
[INFO] Repository checked: range42-inventory
[WARNING] Repository is missing some files.

[INFO] Legend:
[INFO]   ✓ = File/directory present and complete
[INFO]   ✗ = File/directory missing
[INFO]   ⚠ = LICENSE present but contains template placeholders
```

## Authentication

### GitHub CLI Authentication
```bash
# Login with GitHub CLI
gh auth login

# Check authentication status
gh auth status
```

### Behavior by Authentication Status

| Authentication | Public Repos | Private Repos | Rate Limits |
|----------------|--------------|---------------|-------------|
| Authenticated | Full access | Access based on permissions | 5,000/hour |
| Not authenticated | Read-only access | No access | 60/hour |

## Error Handling

The script includes robust error handling:

- **SSH to HTTPS Fallback**: Automatically retries failed SSH clones using HTTPS
- **Existing Repository Updates**: Automatically pulls latest changes for existing repositories
- **Permission Validation**: Clear error messages for access issues
- **Rate Limit Awareness**: Warns about API rate limits for unauthenticated users
- **Repository Not Found**: When filtering, provides helpful error messages with available repository lists

## Directory Structure

After running the script, your directory structure will look like:

```
project-root/
├── gh_repo_cloner.sh
├── config.env
├── pub/
│   ├── public-repo-1/
│   ├── public-repo-2/
│   └── ...
└── priv/
    ├── private-repo-1/
    ├── private-repo-2/
    └── ...
```

## Development

### Running Tests
```bash
# Test configuration loading
./gh_repo_cloner.sh --help

# Test authentication check
gh auth status

# Dry run sanity checks
./gh_repo_cloner.sh --sanity-check

# Test repository filtering
./gh_repo_cloner.sh --sanity-check non-existent-repo  # Should show available repos
```

### Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Best Practices

### For Organizations
- **Regular Audits**: Run sanity checks monthly to ensure repository standards
- **Standardize Templates**: Use the script to identify repos missing issue/PR templates
- **Security Compliance**: Ensure all repositories have `SECURITY.md` files
- **Documentation**: Verify all projects have proper `README.md` and `docs/` directories
- **Focused Reviews**: Use repository filtering to validate specific projects during code reviews

### For Repository Management
- **Batch Updates**: Use the script to identify repositories needing standardization
- **Regular Sync**: Run the script regularly to keep local copies up to date
- **Clean Working Directory**: Ensure local repositories have no uncommitted changes before running updates
- **Onboarding**: Include sanity check results in new developer onboarding
- **Compliance**: Track organization-wide compliance with repository standards
- **Targeted Fixes**: Use filtering to verify fixes on specific repositories

## Limitations

- **Large Organizations**: For organizations with 1000+ repositories, consider running in smaller batches
- **Private Repository Access**: Requires appropriate GitHub permissions
- **Storage Space**: Cloning many repositories requires significant disk space
- **Network Usage**: Initial cloning can consume significant bandwidth

## Troubleshooting

### Common Issues

**"Organization not found"**
- Verify the organization name in `config.env`
- Check if the organization exists and is accessible

**"No repositories found"**  
- Organization may have only private repositories (authenticate with `gh auth login`)
- Organization name may be incorrect

**"Repository 'repo-name' not found"** (when filtering)
- Check spelling of the repository name
- Ensure repositories are cloned first (run without `-s` flag)
- Repository may be in a different case (names are case-sensitive)
- Use the error output to see available repositories

**"Permission denied"**
- SSH key not configured properly
- Use `gh auth login` for authentication
- Check repository access permissions

**"Rate limit exceeded"**
- Authenticate with GitHub CLI: `gh auth login`
- Wait for rate limit reset (shown in error message)

**"Failed to update repository"**
- Repository may have uncommitted local changes
- Check for merge conflicts: `cd repo_directory && git status`
- Reset local changes if safe: `git reset --hard origin/main`
- May indicate network connectivity issues

**"LICENSE shows warning (⚠) symbol"**
- LICENSE file contains template placeholders like `<year>` or `<name of author>`
- Edit the LICENSE file to replace placeholders with actual values
- Common placeholders: `<year>` → actual year, `<name of author>` → your name/organization

**"LICENSE shows missing (✗) but file exists"**
- LICENSE file may have an unexpected name or extension
- Supported names: `LICENSE`, `LICENSE.txt`, `LICENSE.md`, `license`, `License`, `COPYING`, `COPYRIGHT`
- Check file permissions (must be readable)
- Verify file is not a directory or symlink

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues**: Report bugs and request features via [GitHub Issues](../../issues)
- **Discussions**: Join conversations in [GitHub Discussions](../../discussions)
- **Documentation**: Check this README and inline script comments

---

**Made with care for better repository management**
