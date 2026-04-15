# Repository Guidelines

## Project Structure & Module Organization
- `gh_repo_cloner.sh` is the entry point for cloning and audits, with built-in option parsing and logging helpers.
- `helpers/` stores the staged analysis scripts (`1_files_extract.sh`, `2_meta_extract.sh`, `3_static_scan.sh`) plus the Python aggregator `make_for_ai_analysis.py`; they populate `analysis/files/`, `analysis/metadata/`, and `analysis/for_ai/`.
- `bin/gen_changelog.sh` wraps `gitchangelog` for release notes.
- `pub/` and `priv/` collect cloned repositories; avoid editing them manually unless the task explicitly targets a cloned repo rather than the organizer itself.
- Generated directories such as `analysis/` and `venv/` are disposable; `make clean` clears `analysis/`.

## Build, Test, and Development Commands
- `make all` → run the main cloner end-to-end using `config.env`.
- `make sanity` or `./gh_repo_cloner.sh --sanity-check [repo]` → run compliance checks; pass a repo name for a focused report.
- `make prep_ai` → execute the full analysis pipeline (clone, extract, scan, and rebuild `analysis/` files).
- `make clean` → remove generated contents under `analysis/`.
- `python -m venv venv && source venv/bin/activate && pip install -r requirements.txt` → install top-level Python tooling such as `gitchangelog`.
- `pip install -r helpers/requirements.txt` → install Python dependency needed by `helpers/make_for_ai_analysis.py`.
- `gh auth status` → confirm GitHub CLI authentication before touching private repositories.
- `pip-audit`, `safety`, `bandit`, and `npm` are optional external scanner dependencies used by `helpers/3_static_scan.sh` during `make prep_ai`.

## Coding Style & Naming Conventions
- `gh_repo_cloner.sh` uses 4-space indentation, `set -e`, and shared logging helpers (`print_status`, etc.); extend those instead of ad hoc output in the main script.
- The helper shell scripts are simpler and currently rely on direct shell commands and `echo`; keep changes consistent with the surrounding script instead of forcing a different style mid-file.
- Keep flags long-form first (`--sanity-check`), mirror existing `snake_case` function names, and uppercase environment variables loaded from `config.env`.
- Python utilities under `helpers/` use short helpers, module-level constants, and `snake_case`; `make_for_ai_analysis.py` also depends on `yaml`.

## Testing Guidelines
- Run `make sanity` after changing `gh_repo_cloner.sh`; review console output or `analysis/sanity.asc` when generated via `make prep_ai`.
- For helper scripts, run the relevant helper against `pub` and/or `priv` fixtures and confirm artifacts land in the expected `analysis/` subdirectories.
- Validate authentication flows with `gh auth login` in a throwaway environment; never commit tokens or generated reports.
- If you touch `helpers/3_static_scan.sh`, verify behavior when scanner tools are missing or when `package.json` exists without a lock file.

## Commit & Pull Request Guidelines
- Follow the `type: [scope] summary` pattern visible in history (`chg: [sh] ...`, `fix: [gi] ...`); keep summaries concise.
- Group logical changes per commit and signal touched areas in the scope tag (e.g., `[sh]`, `[log]`).
- PRs should explain the motivation, list commands exercised, and link related issues; add sanitized `analysis/` excerpts when helpful.

## Security & Configuration Tips
- Keep `config.env` out of version control; base it on `config.env.example` and prefer `gh auth login` over stored tokens.
- Do not check in `pub/`, `priv/`, or `analysis/` artifacts; add new generated paths to `.gitignore` if needed.
- Review helper scripts for secret redaction (`helpers/make_for_ai_analysis.py`) before expanding scopes to avoid leaks.
- Be careful with `make prep_ai`: it copies repository files into `analysis/files/` and writes derived AI context files under `analysis/for_ai/`, so treat those outputs as generated and potentially sensitive.
