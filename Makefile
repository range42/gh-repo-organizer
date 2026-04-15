SHELL := /bin/bash

.PHONY: all prep_ai sanity clean venv changelog

# Default target
all:
	./gh_repo_cloner.sh

# Create and populate virtual environment
venv: venv/bin/activate

venv/bin/activate: requirements.txt helpers/requirements.txt
	python3 -m venv venv
	source venv/bin/activate && pip install -q -r requirements.txt -r helpers/requirements.txt
	touch venv/bin/activate

# Prepare data for AI analysis
prep_ai: venv
	@echo "==> Running repository cloner..."
	./gh_repo_cloner.sh
	@echo "==> Extracting files from public repos..."
	./helpers/1_files_extract.sh pub
	@echo "==> Extracting files from private repos..."
	./helpers/1_files_extract.sh priv
	@echo "==> Extracting metadata from public repos..."
	./helpers/2_meta_extract.sh pub
	@echo "==> Extracting metadata from private repos..."
	./helpers/2_meta_extract.sh priv
	@echo "==> Running static scans on public repos..."
	source venv/bin/activate && ./helpers/3_static_scan.sh pub
	@echo "==> Running static scans on private repos..."
	source venv/bin/activate && ./helpers/3_static_scan.sh priv
	@echo "==> Generating sanity check report..."
	./gh_repo_cloner.sh -s > analysis/sanity.asc
	@echo "==> Generating AI analysis contexts..."
	source venv/bin/activate && python helpers/make_for_ai_analysis.py
	@echo "==> Done! Analysis files ready in analysis/"

# Generate CHANGELOG.md from git history
changelog: venv
	source venv/bin/activate && gitchangelog > CHANGELOG.md
	bash bin/gen_changelog.sh

# Run sanity check only
sanity:
	./gh_repo_cloner.sh -s

# Optional: clean analysis directory
clean:
	@echo "Cleaning analysis directory..."
	rm -rf analysis/*
	@echo "Done!"
