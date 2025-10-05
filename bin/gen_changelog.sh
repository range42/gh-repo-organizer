#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

### ----------------------------------------------------------------
### Helper: detect GNU sed (gsed) if needed, or error if missing
### ----------------------------------------------------------------
detect_sed() {
  # If gsed is present, prefer it
  if command -v gsed >/dev/null 2>&1; then
    echo "gsed"
    return 0
  fi

  # If plain sed exists, test if it's GNU
  if command -v sed >/dev/null 2>&1; then
    if sed --version >/dev/null 2>&1; then
      # It's GNU sed
      echo "sed"
      return 0
    fi
  fi

  # Otherwise, error out
  echo >&2 "ERROR: GNU sed (gsed) not found and default sed is not GNU-compatible."
  echo >&2 "Install GNU sed (e.g. on macOS: brew install gnu-sed) and re-run this script."
  exit 1
}

xSED="$(detect_sed)"

### ----------------------------------------------------------------
### Check repository state & file existence
### ----------------------------------------------------------------

# Ensure we're in a git repository
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "ERROR: Not inside a Git repository."
  exit 1
}

# Ensure working tree is clean
if [[ -n "$(git status --porcelain)" ]]; then
  echo "ERROR: Uncommitted changes present. Please commit or stash before running."
  exit 1
fi

# Ensure CHANGELOG.md exists
if [[ ! -f CHANGELOG.md ]]; then
  echo "ERROR: CHANGELOG.md not found in current directory."
  exit 1
fi

### ----------------------------------------------------------------
### Apply transformations
### ----------------------------------------------------------------

# We’ll do several in-place edits. With GNU sed, `-i` works directly.
# Use xSED for all sed invocations.
# If you ever need portability with BSD sed, you’d need to use the `-i ''` form, but here we assume GNU.

# Fence normalization: “~~~” → “---” when fence
"${xSED}" -i -E 's/^~~~([[:alnum:]_-]*)$/---\1/' CHANGELOG.md

# Escape leading `#` in list items (for bullets)
"${xSED}" -i -E 's/^(\s*[-*+]\s*)#/\1\\#/' CHANGELOG.md

# Replace “(unreleased)” in headings
"${xSED}" -i -E 's/^\s*##[[:space:]]*\(unreleased\)/## current changelog/I' CHANGELOG.md

# Replace version placeholder
"${xSED}" -i 's/%%version%%/LHC documentation/g' CHANGELOG.md

# Emoji / symbolic replacements:

# /!\ → :warning:
"${xSED}" -i 's@/!\\@:warning:@g' CHANGELOG.md

# WIP / WiP variants → :construction:
"${xSED}" -i -E 's/\bWIP\b/:construction:/gI' CHANGELOG.md

# [security] label in list → :lock:
"${xSED}" -i -E 's/^\s*-\s*\[security\]\s*/- :lock: /I' CHANGELOG.md

### ----------------------------------------------------------------
### Commit changes if any
### ----------------------------------------------------------------

git add CHANGELOG.md

# Only commit if there is a change staged
if ! git diff --cached --quiet -- CHANGELOG.md; then
  git commit -m "chg: [log] Updated CHANGELOG.md"
  echo "Committed updated CHANGELOG.md"
else
  echo "No changes to CHANGELOG.md; skipping commit."
fi
