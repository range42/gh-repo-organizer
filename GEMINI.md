# GEMINI CLI Mandates - GitHub Organization Repository Organizer

These instructions are foundational mandates and take absolute precedence over general workflows.

## Project Structure & Module Organization
- `gh_repo_cloner.sh` is the primary entry point for cloning and audits.
- `helpers/` contains staged analysis scripts for file extraction, metadata extraction, and static scanning.
- `pub/` and `priv/` directories are where repositories are cloned; avoid manual edits to these directories unless specifically instructed.
- The `analysis/` directory contains generated artifacts and is cleared by `make clean`.

## Engineering Standards
- **Scripting Style:** `gh_repo_cloner.sh` and helper scripts use **4-space indentation** and `set -e`. Maintain this style rigorously.
- **Logging:** Use the established logging helpers (`print_status`, `print_success`, `print_warning`, `print_error`) in `gh_repo_cloner.sh` rather than `echo`.
- **Command Flags:** Prefer long-form flags first (e.g., `--sanity-check` over `-s`).
- **Naming Conventions:** Use `snake_case` for function names and uppercase for environment variables from `config.env`.

## Operational Workflows
- **Configuration:** Always reference `config.env` for settings; use `config.env.example` as a template if `config.env` is missing.
- **Authentication:** Use `gh auth status` to verify GitHub CLI authentication before operations involving private repositories.
- **Data Preparation:** Use `make prep_ai` to regenerate the analysis context before tasks requiring a global project state overview.
- **Sanity Checks:** Use `make sanity` or `./gh_repo_cloner.sh --sanity-check [repo]` to validate repository compliance.

## Security & Verification
- **Secrets:** Never commit `config.env` or generated analysis files.
- **Validation:** After any logic changes to `gh_repo_cloner.sh`, run `make sanity` and verify the output. If modifying `helpers/3_static_scan.sh`, test its behavior when scanners are missing or when `package.json` lacks a lock file.
- **Commit Messages:** Follow the `type: [scope] summary` pattern (e.g., `chg: [sh] ...`, `fix: [gi] ...`).
