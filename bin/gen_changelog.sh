#!/usr/bin/env bash

# Function to check for uncommitted changes in the Git repository
check_git_changes() {
    if [ -d ".git" ]; then
        # Check for uncommitted changes
        if [ -n "$(git status --porcelain)" ]; then
            echo "Warning: There are uncommitted changes in the current repository."
            echo "Please commit or stash your changes before proceeding."
            exit 1
        fi
    fi
}

# Check for uncommitted changes in the Git repository
check_git_changes

[[ -e "$(which gsed)" ]] && xSED="gsed" || xSED="sed"

# Check if the directory 'venv' exists
if [ ! -d "venv" ]; then
    echo "Directory 'venv' does not exist. Creating virtual environment..."
    python3 -m venv venv
    venv/bin/pip install -U setuptools pip
    venv/bin/pip install -r requirements.txt
    source ./venv/bin/activate
    echo "Virtual environment created successfully."
else
    echo "Directory 'venv' already exists. No action needed."
fi

# Check if gitchangelog is installed
if ! command -v gitchangelog &> /dev/null
then
    pip install gitchangelog
fi

gitchangelog > CHANGELOG.md

# This search and replace is sub-optimal. It replaces 3 "~"s beginning of the line
# and then just replaces the remaining 2 following tildes in the document.
# This might change the sense of some commit messages...
${xSED} -i "s/^\~\~\~/---/" CHANGELOG.md
${xSED} -i "s/^- \#/- \\\#/" CHANGELOG.md
${xSED} -i "s/\~\~/--/g" CHANGELOG.md
${xSED} -i "s/\(unreleased\)/current changelog/g" CHANGELOG.md
${xSED} -i "s/%%version%%/LHC documentation/g" CHANGELOG.md

# Emojifying things
${xSED} -i "s/\/\!\\\/:warning:/g" CHANGELOG.md
${xSED} -i "s/WiP/:construction:/g" CHANGELOG.md
${xSED} -i "s/WIP/:construction:/g" CHANGELOG.md
${xSED} -i "s/Wip:/:construction:/g" CHANGELOG.md
${xSED} -i "s/\[security\]/:lock:/g" CHANGELOG.md

git add CHANGELOG.md
git commit -m "chg: [log] Updated CHANGELOG.md"
