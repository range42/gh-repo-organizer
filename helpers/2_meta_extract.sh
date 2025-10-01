# metadata_extract.sh
if [ "$1" == "pub" ]; then
    scope="$1"
elif [ "$1" == "priv" ]; then
    scope="priv"
else
    echo "You need to specify pub or priv"
    exit 2
fi

mkdir -p analysis/metadata
for d in pub/*; do
  if [ -e ${scope}/.github ]; then
    d=${scope}/.github
  fi
  repo=$(basename "$d")
  last_commit=$(git -C "$d" log -1 --format="%ci" 2>/dev/null || echo "no-commits")
  commit_count=$(git -C "$d" rev-list --count HEAD 2>/dev/null || echo "0")
  main_branch=$(git -C "$d" rev-parse --abbrev-ref origin/HEAD 2>/dev/null | sed 's|origin/||' || echo "unknown")
  echo -e "repo: $repo\nlast_commit: $last_commit\ncommits: $commit_count\nmain_branch: $main_branch" > analysis/metadata/"$repo".yaml
  # If you use GitHub and gh CLI:
  if command -v gh >/dev/null 2>&1; then
    # requires repo in form owner/repo
    # you can map owner/repo in a map file if needed
    :
  fi
done
