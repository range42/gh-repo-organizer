if [ "$1" == "pub" ]; then
    scope="$1"
elif [ "$1" == "priv" ]; then
    scope="priv"
else
    echo "You need to specify pub or priv"
    exit 2
fi

for d in pub/*; do
  if [ -e ${scope}/.github ]; then
    d=${scope}/.github
  fi
  repo=$(basename "$d")
  if [ -f "$d/requirements.txt" ]; then
    pip-audit -r "$d/requirements.txt" --format json > analysis/files/"$repo"/pip_audit.json || true
    safety check --file="$d/requirements.txt" --json > analysis/files/"$repo"/safety.json || true
  fi
  if [ -f "$d/package.json" ]; then
    (cd "$d" && npm audit --json) > analysis/files/"$repo"/npm_audit.json || true
  fi
  if find "$d" -name "*.py" | grep -q .; then
    echo "Running Bandit on $repo"
    # -r: recursive, -f json output, -o file
    bandit -r "$d" -f json -o analysis/files/"$repo"/bandit_report.json || true
  fi
done

for d in repos/*; do
  repo=$(basename "$d")
done
