# extract_files.sh
if [ "$1" == "pub" ]; then
    scope="$1"
elif [ "$1" == "priv" ]; then
    scope="priv"
else
    echo "You need to specify pub or priv"
    exit 2
fi

mkdir -p analysis/files
for d in ${scope}/*; do
  if [ -e ${scope}/.github ]; then
    d=${scope}/.github
  fi
  repo=$(basename "$d")
  mkdir -p analysis/files/"$repo"
  for f in README.md README.rst docs/* architecture* docker* Dockerfile .github/workflows/* requirements*.txt pyproject.toml package.json go.mod; do
    if compgen -G "$d/$f" >/dev/null; then
      cp -r $d/$f analysis/files/"$repo"/ 2>/dev/null || true
    fi
  done
  # capture top-level tree
  git -C "$d" ls-tree -r --name-only HEAD | head -n 200 > analysis/files/"$repo"/file_list.txt 2>/dev/null || true
done
