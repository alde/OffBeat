#!/bin/bash
set -euo pipefail

mkdir -p Libs

current_path=""
current_url=""
in_externals=false

checkout() {
  if [[ -n "$current_path" && -n "$current_url" ]]; then
    echo "Fetching ${current_path}..."
    if [[ "$current_url" == *github.com* ]]; then
      rm -rf "$current_path"
      git clone --depth 1 "$current_url" "$current_path"
    else
      svn checkout "$current_url" "$current_path"
    fi
    echo "Done."
  fi
}

while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"

  if [[ "$line" =~ ^externals: ]]; then
    in_externals=true
    continue
  fi

  if ! $in_externals; then
    continue
  fi

  if [[ -n "$line" && ! "$line" =~ ^[[:space:]] ]]; then
    break
  fi

  if [[ "$line" =~ ^[[:space:]]{2}[^[:space:]] && "$line" =~ : ]]; then
    checkout
    current_path="$(echo "$line" | sed 's/^[[:space:]]*//' | sed 's/:$//')"
    current_url=""
  fi

  if [[ "$line" =~ ^[[:space:]]+url: ]]; then
    current_url="$(echo "$line" | sed 's/^[[:space:]]*url:[[:space:]]*//')"
  fi
done < .pkgmeta

checkout
