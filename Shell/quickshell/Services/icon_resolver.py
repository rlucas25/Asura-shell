#!/usr/bin/env python3
import glob
import json
import os
import sys

_CACHE = {}
_DESKTOP_ICONS = None

KNOWN_ALIASES = {
    "spotify": "spotify",
    "spotify-client": "spotify",
    "firefox": "firefox",
    "chrome": "google-chrome",
    "chromium": "chromium",
    "brave": "brave-browser",
    "vivaldi": "vivaldi",
    "discord": "discord",
    "vesktop": "discord",
    "webcord": "discord",
    "telegram": "telegram",
    "telegramdesktop": "telegram",
    "code": "visual-studio-code",
    "vscodium": "vscodium",
    "vscode": "visual-studio-code",
    "kitty": "kitty",
    "alacritty": "Alacritty",
    "foot": "foot",
    "wezterm": "org.wezfurlong.wezterm",
    "vlc": "vlc",
    "mpv": "mpv",
    "thunar": "thunar",
    "nautilus": "org.gnome.Nautilus",
    "dolphin": "system-file-manager",
    "gimp": "gimp",
    "inkscape": "inkscape",
    "obsidian": "obsidian",
    "steam": "steam",
    "obs": "obs",
    "pavucontrol": "org.pulseaudio.pavucontrol",
}

def _scan_desktop_entries():
    global _DESKTOP_ICONS
    if _DESKTOP_ICONS is not None:
        return _DESKTOP_ICONS

    _DESKTOP_ICONS = {}
    search_dirs = [
        os.path.expanduser("~/.local/share/applications"),
        "/usr/share/applications",
        "/usr/local/share/applications",
        "/var/lib/flatpak/exports/share/applications",
    ]

    for d in search_dirs:
        if not os.path.isdir(d):
            continue
        for entry_path in glob.glob(os.path.join(d, "*.desktop")):
            filename = os.path.basename(entry_path)
            base_id = filename[:-8].lower() if filename.endswith(".desktop") else filename.lower()
            try:
                with open(entry_path, "r", encoding="utf-8", errors="ignore") as fp:
                    for line in fp:
                        if line.startswith("Icon="):
                            icon_val = line.strip().split("=", 1)[1].strip()
                            if icon_val and base_id not in _DESKTOP_ICONS:
                                _DESKTOP_ICONS[base_id] = icon_val
                            break
            except Exception:
                continue

    return _DESKTOP_ICONS

def resolve_app_icon(name, binary_hint=None):
    clean_name = (name or "").strip()
    clean_bin = (binary_hint or "").strip()
    cache_key = f"{clean_name.lower()}::{clean_bin.lower()}"

    if cache_key in _CACHE:
        return _CACHE[cache_key]

    lower_name = clean_name.lower()
    lower_bin = clean_bin.lower()

    # Direct match in known aliases
    if lower_name in KNOWN_ALIASES:
        _CACHE[cache_key] = KNOWN_ALIASES[lower_name]
        return _CACHE[cache_key]
    if lower_bin in KNOWN_ALIASES:
        _CACHE[cache_key] = KNOWN_ALIASES[lower_bin]
        return _CACHE[cache_key]

    desktop_icons = _scan_desktop_entries()

    # Direct match in desktop entries
    candidates = [
        lower_name,
        lower_bin,
        lower_name.replace(" ", "-"),
        lower_name.replace(" ", "_"),
        lower_bin.replace(" ", "-"),
        lower_bin.replace(" ", "_"),
    ]

    for cand in candidates:
        if cand and cand in desktop_icons:
            _CACHE[cache_key] = desktop_icons[cand]
            return _CACHE[cache_key]

    # Substring match in known aliases
    for alias_key, icon_val in KNOWN_ALIASES.items():
        if alias_key in lower_name or (lower_bin and alias_key in lower_bin):
            _CACHE[cache_key] = icon_val
            return icon_val

    # Substring match in desktop entries
    if lower_name:
        for d_id, icon_val in desktop_icons.items():
            if lower_name in d_id or d_id in lower_name:
                _CACHE[cache_key] = icon_val
                return icon_val

    # Category fallback based on keywords
    if any(k in lower_name for k in ["player", "music", "audio", "sound", "spotify"]):
        resolved = "audio-player"
    elif any(k in lower_name for k in ["browser", "web", "firefox", "chrome"]):
        resolved = "web-browser"
    elif any(k in lower_name for k in ["term", "console", "kitty", "alacritty"]):
        resolved = "utilities-terminal"
    elif any(k in lower_name for k in ["game", "steam"]):
        resolved = "applications-games"
    else:
        resolved = clean_bin or clean_name or "application-x-executable"

    _CACHE[cache_key] = resolved
    return resolved

def main():
    name = sys.argv[1] if len(sys.argv) > 1 else ""
    hint = sys.argv[2] if len(sys.argv) > 2 else ""
    result = resolve_app_icon(name, hint)
    if "--json" in sys.argv:
        print(json.dumps({"name": name, "hint": hint, "icon": result}))
    else:
        print(result)

if __name__ == "__main__":
    main()
