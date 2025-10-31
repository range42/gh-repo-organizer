# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GitHub Organization Repository Cloner - A bash-based tool for mass-cloning GitHub organization repositories with comprehensive compliance auditing and AI-powered analysis preparation.

The tool organizes cloned repos into `pub/` and `priv/` directories, performs standards compliance checks, and generates analysis artifacts for AI consumption.

## Core Commands

### Essential Operations
```bash
# Clone all accessible repositories from configured org
./gh_repo_cloner.sh

# Run compliance sanity checks on all repos
./gh_repo_cloner.sh --sanity-check
# or shorthand
make sanity

# Check specific repository
./gh_repo_cloner.sh --sanity-check <repo-name>

# Full analysis pipeline (clone → extract → scan → AI contexts)
make prep_ai

# Clean generated analysis artifacts
make clean
```

### Development Setup
```bash
# Verify GitHub authentication (required for private repos)
gh auth status
gh auth login  # if not authenticated

# Setup Python environment for gitchangelog
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Create config from template
cp config.env.example config.env
# Edit config.env to set ORG variable
```

### Testing
```bash
# Test sanity checks and review output
make sanity > test_output.txt

# Test helper scripts on small dataset
./helpers/1_files_extract.sh pub
./helpers/2_meta_extract.sh pub
./helpers/3_static_scan.sh pub

# Verify analysis artifacts
ls -la analysis/files/
ls -la analysis/metadata/
ls -la analysis/for_ai/
```

## Architecture

### Entry Point & Core Logic
**`gh_repo_cloner.sh`** (main script, ~850 lines)
- Argument parsing with `--sanity-check` and `--help` flags
- Configuration loading from `config.env`
- Repository cloning via `gh` CLI with SSH/HTTPS fallback
- Comprehensive sanity checks validating 12+ compliance categories
- LICENSE content validation detecting template placeholders
- Colored terminal output via shared print functions

### Analysis Pipeline (`make prep_ai`)
The analysis pipeline is a multi-stage process that prepares repository data for AI consumption:

1. **Clone Stage**: `gh_repo_cloner.sh` clones all org repos into `pub/` and `priv/`

2. **File Extraction** (`helpers/1_files_extract.sh`):
   - Extracts key files: README, docs, architecture docs, Dockerfiles, workflows, manifests
   - Captures git file tree (top 200 files) via `git ls-tree`
   - Outputs to `analysis/files/<repo>/`

3. **Metadata Extraction** (`helpers/2_meta_extract.sh`):
   - Extracts git metadata: last commit, commit count, main branch
   - Outputs YAML to `analysis/metadata/<repo>.yaml`
   - Placeholder for optional gh CLI API calls

4. **Static Scanning** (`helpers/3_static_scan.sh`):
   - **Python**: `pip-audit` + `safety` for requirements.txt, `bandit` for security
   - **Node.js**: `npm audit` (validates lock file presence)
   - **Container**: Trivy scanning (local binary or Docker/Podman fallback)
   - Outputs JSON reports to `analysis/files/<repo>/`

5. **AI Context Generation** (`helpers/make_for_ai_analysis.py`):
   - Aggregates files, metadata, and scan results per repo
   - Redacts secrets via regex patterns (API keys, tokens, passwords)
   - Generates truncated, sanitized contexts in `analysis/for_ai/<repo>_context.txt`
   - Limits: 16k chars total, 3.5k for README, 200 lines for file lists, top 5 Bandit findings

### Directory Structure
```
.
├── gh_repo_cloner.sh          # Main script (clone + sanity checks)
├── config.env                 # Configuration (ORG, paths, colors)
├── Makefile                   # Task automation
├── helpers/
│   ├── 1_files_extract.sh     # Extract key files from repos
│   ├── 2_meta_extract.sh      # Extract git metadata
│   ├── 3_static_scan.sh       # Run security/dependency scans
│   └── make_for_ai_analysis.py# Aggregate analysis for AI
├── bin/
│   └── gen_changelog.sh       # Wrapper for gitchangelog
├── pub/                       # Public repositories (auto-created)
├── priv/                      # Private repositories (auto-created)
└── analysis/                  # Generated artifacts (auto-created)
    ├── files/                 # Extracted files + scan reports
    ├── metadata/              # Git metadata YAMLs
    ├── for_ai/                # AI-ready context files
    └── sanity.asc             # Sanity check output
```

**Generated directories** (`pub/`, `priv/`, `analysis/`, `venv/`) are gitignored and can be deleted safely.

## Coding Conventions

### Bash Scripts
- **Indentation**: 4 spaces (no tabs)
- **Error handling**: `set -e` at top of all scripts
- **Functions**: `snake_case` naming matching existing patterns
- **Output**: Use shared helpers (`print_status`, `print_success`, `print_warning`, `print_error`) - never raw `echo`
- **Environment**: Uppercase variables from `config.env` (e.g., `ORG`, `PUB_DIR`, `PRIV_DIR`)
- **Arguments**: Long-form flags first (`--sanity-check` before `-s`)

### Python Scripts
- **Style**: Standard library preferred, `snake_case` for all identifiers
- **Constants**: Uppercase at module top (e.g., `MAX_CHARS`, `README_SNIPPET`)
- **Error handling**: Wrapped in try/except, fail gracefully with empty strings/defaults
- **Security**: Extend `SECRET_RE` regex for new secret patterns

### Commit Style
Follow existing pattern: `type: [scope] summary`
- **Types**: `chg`, `fix`, `add`, `doc`
- **Scopes**: `[sh]` (shell), `[py]` (Python), `[log]` (changelog), `[gi]` (git/gitignore), `[doc]` (docs)
- **Examples**:
  - `chg: [sh] More checks and refactor`
  - `fix: [sh] Fixed venv`
  - `add: [py] Secret redaction in analysis`

## Configuration

### `config.env` Variables
```bash
ORG="your-organization"        # Required: GitHub org name
PUB_DIR="./pub"               # Optional: public repos directory
PRIV_DIR="./priv"             # Optional: private repos directory
RED='\033[0;31m'              # Optional: terminal colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
```

**Security**: Never commit `config.env` - use `config.env.example` as template.

## Sanity Check Categories

The script validates 12 compliance areas with file/directory variants:

1. **LICENSE**: LICENSE, LICENSE.txt, LICENSE.md, COPYING, COPYRIGHT
   - Content validation detects unfilled templates: `<year>`, `<author>`, `COPYRIGHT_HOLDER`, etc.
   - Status indicators: `✓` (complete), `⚠` (template placeholders), `✗` (missing)

2. **CHANGELOG**: CHANGELOG.md, HISTORY.md, RELEASES.md

3. **CONTRIBUTING**: CONTRIBUTING.md, CONTRIBUTING.txt

4. **README**: README.md, README.txt, README

5. **GITIGNORE**: .gitignore

6. **SECURITY**: SECURITY.md, SECURITY.txt

7. **CODE_OF_CONDUCT**: CODE_OF_CONDUCT.md

8. **EDITORCONFIG**: .editorconfig

9. **DOCS**: docs/, documentation/

10. **ISSUE_TEMPLATES**: .github/ISSUE_TEMPLATE/

11. **PR_TEMPLATE**: .github/PULL_REQUEST_TEMPLATE.md

12. **CI/CD**: .github/workflows/, .gitlab-ci.yml, .travis.yml, Jenkinsfile, .circleci/, azure-pipelines.yml, .buildkite/, bitbucket-pipelines.yml

## Key Implementation Details

### Clone Logic
- Uses `gh repo list` for discovery
- Attempts SSH clone first, falls back to HTTPS on failure
- Updates existing repos with `git pull`
- Tracks success/failure counts per visibility level

### Sanity Check Behavior
- Recursive search via `find` with file type validation (not directories/symlinks)
- Repository filtering searches both `pub/` and `priv/` directories
- Lists available repos if filter target not found
- Outputs summary stats: total checked, all files present, missing files

### Analysis Pipeline Inputs
- **Files**: README variants, docs/, architecture*, Dockerfiles, workflow YAMLs, manifests (requirements.txt, package.json, go.mod, pyproject.toml)
- **Scans**: Requires tool availability (pip-audit, safety, bandit, npm, trivy)
- **Metadata**: Git commands for history analysis

### Secret Redaction
`make_for_ai_analysis.py` redacts via case-insensitive regex:
```python
SECRET_RE = re.compile(r'(?i)(aws[_-]?secret[_-]?access[_-]?key|aws[_-]?secret|api[_-]?key|token|password|secret|private_key)\s*[:=]\s*("?)[^\s"]+("? )?')
```
Extend this pattern to catch new secret formats.

## Dependencies

### Required
- **bash 4.0+**: Core scripting
- **gh**: GitHub CLI for API access and auth
- **git**: Repository operations
- **jq**: JSON parsing in scripts
- **python3**: Analysis aggregation

### Optional (for `make prep_ai`)
- **pip-audit**, **safety**: Python dependency scanning
- **bandit**: Python security analysis
- **npm**: Node.js dependency scanning
- **trivy**: Container/filesystem scanning (local or Docker/Podman)
- **gitchangelog**: Changelog generation

## Common Workflows

### Adding New Sanity Check
1. Extend the sanity check function in `gh_repo_cloner.sh` around line 400-600
2. Add to the legend/help text
3. Update README.md sanity checks table
4. Test with `make sanity`

### Adding New Static Scanner
1. Add tool check and execution in `helpers/3_static_scan.sh`
2. Extend output path: `analysis/files/"$repo"/<tool>_report.json`
3. Add summarizer function in `make_for_ai_analysis.py`
4. Test with `make prep_ai`

### Filtering to Specific Repos
```bash
# Single repo analysis
./gh_repo_cloner.sh -s my-backend-api

# Multi-repo: modify helpers to accept repo list
# Currently pipeline processes all repos in pub/priv
```

## Troubleshooting

### "Organization not found"
- Verify `ORG` in `config.env`
- Check `gh auth status` for valid authentication

### "Repository 'X' not found" (filtering)
- Case-sensitive matching required
- Run without `-s` first to ensure cloned
- Check error output for available repo list

### "Failed to update repository"
- Local uncommitted changes or merge conflicts
- Use `git status` in repo directory to diagnose

### Analysis Pipeline Failures
- Check tool availability: `which pip-audit bandit npm trivy`
- Review `analysis/files/<repo>/*.json` for error fields
- Python venv may need activation for gitchangelog
