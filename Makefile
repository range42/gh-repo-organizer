.PHONY: all prep_ai sanity clean

# Default target
all:
	./gh_repo_cloner.sh

# Prepare data for AI analysis
prep_ai:
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
	./helpers/3_static_scan.sh pub
	@echo "==> Running static scans on private repos..."
	./helpers/3_static_scan.sh priv
	@echo "==> Generating sanity check report..."
	./gh_repo_cloner.sh -s > analysis/sanity.asc
	@echo "==> Generating AI analysis contexts..."
	python helpers/make_for_ai_analysis.py
	@echo "==> Done! Analysis files ready in analysis/"

# Run sanity check only
sanity:
	./gh_repo_cloner.sh -s

# Optional: clean analysis directory
clean:
	@echo "Cleaning analysis directory..."
	rm -rf analysis/*
	@echo "Done!"
