# GitHub Organization Repository Cloner

**GitHub Organization Repository Cloner - Automatically clone and audit all repositories from a GitHub organization with comprehensive standards compliance checking.**

A powerful bash script for cloning and auditing all repositories from a GitHub organization. Automatically organizes repositories into public and private directories, with comprehensive sanity checks for repository standards compliance.

## Features

- **Mass Repository Cloning**: Clone all accessible repositories from any GitHub organization
- **Smart Organization**: Automatically separates public and private repositories into dedicated directories
- **Authentication Aware**: Works with or without GitHub authentication (limited to public repos when unauthenticated)
- **Comprehensive Sanity Checks**: Audit repositories for standard files and best practices
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
   ./clone-repos.sh
   
   # Or perform sanity checks
   ./clone-repos.sh --sanity-check
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
./clone-repos.sh --help

# Clone all repositories  
./clone-repos.sh

# Perform sanity checks on repositories
./clone-repos.sh --sanity-check
```

### Command Line Options

| Option | Description |
|--------|-------------|
| `-s, --sanity-check` | Perform sanity checks on repositories for common files |
| `-h, --help` | Show help message and exit |

## Sanity Checks

The script can audit repositories for compliance with common standards and best practices:

### Files Checked

| Category | Files/Directories |
|----------|-------------------|
| **License** | `LICENSE`, `LICENSE.txt`, `LICENSE.md` (with content validation) |
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
- `<year>`, `[year]`, `YYYY`
- `<name of author>`, `<author>`, `<owner>`
- `<name of copyright owner>`, `<copyright holders>`
- `COPYRIGHT_HOLDER`, `AUTHOR_NAME`, `YOUR_NAME`

**LICENSE Status Indicators:**
- **✓ LICENSE** - File present and properly filled out
- **⚠ LICENSE** - File present but contains template placeholders
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
[SUCCESS] Cloned awesome-project to ./pub/
[SUCCESS] Cloned secret-sauce to ./priv/
[SUCCESS] Cloning completed!
[INFO] Summary:
[INFO]   Public repositories cloned: 15
[INFO]   Private repositories cloned: 10
```

### Sanity Check Results
```
[INFO] Checking public repositories in ./pub:
  awesome-project: ✓ LICENSE ✓ CHANGELOG ✓ CONTRIBUTING ✓ README ✓ GITIGNORE ✓ SECURITY ✓ CODE_OF_CONDUCT ✓ EDITORCONFIG ✓ DOCS ✓ ISSUE_TEMPLATES ✓ PR_TEMPLATE ✓ CI/CD
  legacy-tool: ⚠ LICENSE ✓ README ✓ GITIGNORE ✓ CI/CD
  old-project: ✗ LICENSE ✗ CHANGELOG ✗ CONTRIBUTING ✓ README ✓ GITIGNORE ✗ SECURITY

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
- **Existing Directory Detection**: Skips repositories that are already cloned
- **Permission Validation**: Clear error messages for access issues
- **Rate Limit Awareness**: Warns about API rate limits for unauthenticated users

## Directory Structure

After running the script, your directory structure will look like:

```
project-root/
├── clone-repos.sh
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
./clone-repos.sh --help

# Test authentication check
gh auth status

# Dry run sanity checks
./clone-repos.sh --sanity-check
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

### For Repository Management
- **Batch Updates**: Use the script to identify repositories needing standardization
- **Onboarding**: Include sanity check results in new developer onboarding
- **Compliance**: Track organization-wide compliance with repository standards

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

**"Permission denied"**
- SSH key not configured properly
- Use `gh auth login` for authentication
- Check repository access permissions

**"Rate limit exceeded"**
- Authenticate with GitHub CLI: `gh auth login`
- Wait for rate limit reset (shown in error message)

**"LICENSE shows warning (⚠) symbol"**
- LICENSE file contains template placeholders like `<year>` or `<name of author>`
- Edit the LICENSE file to replace placeholders with actual values
- Common placeholders: `<year>` → actual year, `<name of author>` → your name/organization

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues**: Report bugs and request features via [GitHub Issues](../../issues)
- **Discussions**: Join conversations in [GitHub Discussions](../../discussions)
- **Documentation**: Check this README and inline script comments

---

**Made with care for better repository management**