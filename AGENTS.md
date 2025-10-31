# Repository Guidelines

## Project Structure & Module Organization
- `gh_repo_cloner.sh` is the entry point for cloning and audits, with built-in option parsing and logging helpers.
- `helpers/` stores the staged analysis scripts (`1_files_extract.sh`, `2_meta_extract.sh`, `3_static_scan.sh`) plus the Python aggregator `make_for_ai_analysis.py`; they write to `analysis/`.
- `bin/gen_changelog.sh` wraps `gitchangelog` for release notes.
- `pub/` and `priv/` collect cloned repositories; avoid editing them manually. Generated directories such as `analysis/` and `venv/` can be cleaned freely.

## Build, Test, and Development Commands
- `make all` → run the main cloner end-to-end using `config.env`.
- `make sanity` or `./gh_repo_cloner.sh --sanity-check [repo]` → run compliance checks; pass a repo name for a focused report.
- `make prep_ai` → execute the full analysis pipeline (clone, extract, scan, and rebuild `analysis/` files).
- `python -m venv venv && source venv/bin/activate && pip install -r requirements.txt` → install `gitchangelog` when needed.
- `gh auth status` → confirm GitHub CLI authentication before touching private repositories.

## Coding Style & Naming Conventions
- Bash scripts use 4-space indentation, `set -e`, and shared logging helpers (`print_status`, etc.); extend those instead of echoing directly.
- Keep flags long-form first (`--sanity-check`), mirror existing `snake_case` function names, and uppercase environment variables loaded from `config.env`.
- Python utilities under `helpers/` lean on standard-library imports, short helpers, and `snake_case`; define new constants near existing ones.

## Testing Guidelines
- Run `make sanity` after shell changes and review `analysis/sanity.asc` for regressions.
- For helper scripts, test against a lightweight organization or fixture to confirm artifacts land in `analysis/`.
- Validate authentication flows with `gh auth login` in a throwaway environment; never commit tokens or generated reports.

## Commit & Pull Request Guidelines
- Follow the `type: [scope] summary` pattern visible in history (`chg: [sh] ...`, `fix: [gi] ...`); keep summaries concise.
- Group logical changes per commit and signal touched areas in the scope tag (e.g., `[sh]`, `[log]`).
- PRs should explain the motivation, list commands exercised, and link related issues; add sanitized `analysis/` excerpts when helpful.

## Security & Configuration Tips
- Keep `config.env` out of version control; base it on `config.env.example` and prefer `gh auth login` over stored tokens.
- Do not check in `pub/`, `priv/`, or `analysis/` artifacts; add new generated paths to `.gitignore` if needed.
- Review helper scripts for secret redaction (`helpers/make_for_ai_analysis.py`) before expanding scopes to avoid leaks.
