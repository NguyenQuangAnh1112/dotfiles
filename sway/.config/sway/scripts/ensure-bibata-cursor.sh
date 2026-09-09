#!/bin/sh
# Ensure Bibata-Modern-Amber cursor theme is installed.
# Usage: called from sway config via exec.

set -eu

THEME_NAME="Bibata-Modern-Ice"
ICON_DIR="$HOME/.local/share/icons"
THEME_DIR="$ICON_DIR/$THEME_NAME"
DOWNLOAD_URL="https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Ice.tar.xz"

# Already installed → skip
if [ -d "$THEME_DIR/cursors" ]; then
    exit 0
fi

echo "[bibata] Installing $THEME_NAME..."
mkdir -p "$ICON_DIR"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

curl -fsSL "$DOWNLOAD_URL" -o "$TMP/bibata.tar.xz"
tar -xJf "$TMP/bibata.tar.xz" -C "$TMP"
mv "$TMP/$THEME_NAME" "$THEME_DIR"

echo "[bibata] Installed to $THEME_DIR"
