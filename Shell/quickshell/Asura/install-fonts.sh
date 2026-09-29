#!/usr/bin/env bash

set -euo pipefail

# Get the directory where this script is located.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source directory containing the fonts shipped with Asura.
FONT_SOURCE="$SCRIPT_DIR/fonts"

# User-local font directory.
FONT_DEST="$HOME/.local/share/fonts/Asura"

# Check if the source directory exists.
if [[ ! -d "$FONT_SOURCE" ]]; then
    echo "Error: font directory not found:"
    echo "  $FONT_SOURCE"
    exit 1
fi

# Create the destination directory.
mkdir -p "$FONT_DEST"

# Install every supported font file found in the fonts directory.
find "$FONT_SOURCE" -maxdepth 1 -type f \
    \( -iname "*.ttf" -o -iname "*.otf" -o -iname "*.woff" -o -iname "*.woff2" \) \
    -exec cp -f {} "$FONT_DEST/" \;

# Rebuild the user font cache.
fc-cache -f "$FONT_DEST"

echo "Fonts installed successfully."
echo
echo "Installed fonts:"
find "$FONT_DEST" -maxdepth 1 -type f \
    \( -iname "*.ttf" -o -iname "*.otf" -o -iname "*.woff" -o -iname "*.woff2" \) \
    -printf '  %f\n'
