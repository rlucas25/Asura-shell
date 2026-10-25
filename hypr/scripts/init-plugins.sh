#!/bin/bash
# Initialize and ensure hyprpm plugins are loaded cleanly

if ! command -v hyprpm >/dev/null 2>&1; then
    exit 0
fi

user_name="$(id -un)"
so_path="/var/cache/hyprpm/${user_name}/hyprland-scroll-overview/scrolloverview.so"

# If scrolloverview binary is missing or not registered, attempt auto-setup
if [ ! -f "$so_path" ] || ! hyprpm list 2>/dev/null | grep -q "scrolloverview"; then
    hyprpm update -f >/dev/null 2>&1
    echo "y" | hyprpm add https://github.com/yayuuu/hyprland-scroll-overview >/dev/null 2>&1
    hyprpm enable scrolloverview >/dev/null 2>&1
fi

# Reload plugins into running Hyprland session
hyprpm reload -n >/dev/null 2>&1 || hyprpm reload >/dev/null 2>&1
