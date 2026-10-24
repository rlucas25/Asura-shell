#!/usr/bin/env bash
SOURCE="$1"
DEST="$HOME/.config/vivaldi/Default/VivaldiThumbnails/AsuraWallpaper.jpg"
[[ -z "$SOURCE" || ! -f "$SOURCE" ]] && exit 0
mkdir -p "$(dirname "$DEST")"
cp -f -- "$SOURCE" "$DEST"
