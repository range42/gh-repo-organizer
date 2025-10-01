if [ "$1" == "pub" ]; then
    scope="$1"
elif [ "$1" == "priv" ]; then
    scope="priv"
else
    echo "You need to specify pub or priv"
    exit 2
fi

for d in ${scope}/*; do
  if [ -e ${scope}/.github ]; then
    d=${scope}/.github
  fi
  repo=$(basename "$d")

  # Create output directory structure
  mkdir -p analysis/files/"$repo"

  if [ -f "$d/requirements.txt" ]; then
    pip-audit -r "$d/requirements.txt" --format json > analysis/files/"$repo"/pip_audit.json || true
    safety check --file="$d/requirements.txt" --json > analysis/files/"$repo"/safety.json || true
  fi
  
  if [ -f "$d/package.json" ]; then
    if [ -f "$d/package-lock.json" ] || [ -f "$d/yarn.lock" ] || [ -f "$d/pnpm-lock.yaml" ]; then
      (cd "$d" && npm audit --json) > analysis/files/"$repo"/npm_audit.json 2>&1 || true
    else
      echo "WARNING: $repo has package.json but no lock file" >&2
      echo '{"error": "no_lock_file", "message": "Repository has package.json but no lock file (package-lock.json, yarn.lock, or pnpm-lock.yaml)"}' > analysis/files/"$repo"/npm_audit.json
    fi
  fi

  if find "$d" -name "*.py" | grep -q .; then
    echo "Running Bandit on $repo"
    bandit -r "$d" -f json -o analysis/files/"$repo"/bandit_report.json || true
  fi
done
