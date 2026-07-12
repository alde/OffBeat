#!/bin/bash
set -euo pipefail

# Symlinks satellite addons into the same AddOns directory as the core
# so WoW can discover them during development.
#
# Usage: run from the OffBeat repo root, or pass the AddOns path:
#   ./dev_install.sh
#   ./dev_install.sh /path/to/Interface/AddOns

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ADDONS_DIR="${1:-$(dirname "$SCRIPT_DIR")}"

for sat in OffBeat_Evoker OffBeat_Mage OffBeat_Monk OffBeat_DeathKnight OffBeat_Paladin; do
    src="$SCRIPT_DIR/$sat"
    dest="$ADDONS_DIR/$sat"

    if [[ ! -d "$src" ]]; then
        echo "Skipping $sat (not found)"
        continue
    fi

    if [[ -L "$dest" ]]; then
        echo "$sat: symlink exists"
    elif [[ -d "$dest" ]]; then
        echo "$sat: directory exists (not a symlink), skipping"
    else
        ln -s "$src" "$dest"
        echo "$sat: linked"
    fi
done
