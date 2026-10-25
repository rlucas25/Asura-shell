#!/bin/bash
# Start wallpaper daemon (awww-daemon or swww-daemon)
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

if command -v awww-daemon >/dev/null 2>&1; then
    exec awww-daemon
elif command -v swww-daemon >/dev/null 2>&1; then
    exec swww-daemon
elif command -v swww >/dev/null 2>&1; then
    exec swww init
fi
