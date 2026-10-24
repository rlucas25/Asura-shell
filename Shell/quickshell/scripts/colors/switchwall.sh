#!/usr/bin/env bash
# Based on iNiR by snowarch (https://github.com/snowarch/inir) and illogical-impulse by end-4
# Licensed under GNU General Public License v3.0 (GPL-3.0)
# Adapted for Asura Shell

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

STATE_DIR="$XDG_STATE_HOME/quickshell"
CACHE_DIR="$XDG_CACHE_HOME/quickshell"
TEMPLATE_DIR="$SHELL_ROOT/templates"
ASURA_COLORS="$XDG_CONFIG_HOME/asura/colors.json"
TERMINAL_SCHEME="$SCRIPT_DIR/terminal/scheme-base.json"
SEQUENCES_TEMPLATE="$SCRIPT_DIR/terminal/sequences.txt"

mkdir -p "$STATE_DIR/user/generated" "$CACHE_DIR/user/generated"

# Virtual environment resolution
VENV_DIR="${ASURA_VENV:-${INIR_VENV:-$STATE_DIR/.venv}}"

if [[ ! -d "$VENV_DIR" ]]; then
    if command -v uv &>/dev/null; then
        echo "[switchwall.sh] Setting up Python virtual environment with uv..."
        uv venv "$VENV_DIR" >/dev/null 2>&1 || true
        uv pip install --python "$VENV_DIR/bin/python" materialyoucolor pillow numpy >/dev/null 2>&1 || true
    fi
fi

if [[ -x "$VENV_DIR/bin/python3" ]]; then
    PYTHON_BIN="$VENV_DIR/bin/python3"
elif [[ -x "$VENV_DIR/bin/python" ]]; then
    PYTHON_BIN="$VENV_DIR/bin/python"
else
    PYTHON_BIN="python3"
fi

# Parse arguments
IMAGE_PATH=""
MODE="dark"
SCHEME="tonal-spot"
SEED_COLOR=""
PALETTE=""
PRIMARY_SLOT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --path)
            IMAGE_PATH="$2"
            shift 2
            ;;
        --palette|-p)
            PALETTE="$2"
            shift 2
            ;;
        --primary-slot)
            PRIMARY_SLOT="$2"
            shift 2
            ;;
        --mode|-m)
            MODE="$2"
            shift 2
            ;;
        --scheme|-s|-t)
            SCHEME="$2"
            shift 2
            ;;
        --color|-c)
            SEED_COLOR="$2"
            shift 2
            ;;
        -*)
            shift
            ;;
        *)
            if [[ -z "$IMAGE_PATH" ]]; then
                IMAGE_PATH="$1"
            fi
            shift
            ;;
    esac
done

# If no scheme given, default to tonal-spot
if [[ -z "$SCHEME" ]]; then
    SCHEME="tonal-spot"
fi

if [[ -z "$PRIMARY_SLOT" ]] && command -v jq &>/dev/null; then
    if [[ -f "$XDG_CONFIG_HOME/asura/config.json" ]]; then
        PRIMARY_SLOT=$(jq -r '.primarySlot // empty' "$XDG_CONFIG_HOME/asura/config.json" 2>/dev/null || true)
    elif [[ -f "$XDG_CONFIG_HOME/quickshell/Asura/config/config.json" ]]; then
        PRIMARY_SLOT=$(jq -r '.primarySlot // empty' "$XDG_CONFIG_HOME/quickshell/Asura/config/config.json" 2>/dev/null || true)
    fi
fi

if [[ -z "$IMAGE_PATH" ]] && command -v jq &>/dev/null; then
    if [[ -f "$XDG_CONFIG_HOME/asura/config.json" ]]; then
        IMAGE_PATH=$(jq -r '.wallpaper // empty' "$XDG_CONFIG_HOME/asura/config.json" 2>/dev/null || true)
    elif [[ -f "$XDG_CONFIG_HOME/quickshell/Asura/config/config.json" ]]; then
        IMAGE_PATH=$(jq -r '.wallpaper // empty' "$XDG_CONFIG_HOME/quickshell/Asura/config/config.json" 2>/dev/null || true)
    fi
fi

if [[ -n "$IMAGE_PATH" ]]; then
    IMAGE_PATH="${IMAGE_PATH#file://}"
fi

# Handle video wallpaper frame extraction if needed
EXTRACTED_FRAME=""
if [[ -n "$IMAGE_PATH" && -f "$IMAGE_PATH" ]]; then
    if [[ "$IMAGE_PATH" =~ \.(mp4|mkv|webm|avi|mov)$ ]]; then
        EXTRACTED_FRAME="/tmp/asura_wall_frame.jpg"
        if command -v ffmpeg &>/dev/null; then
            ffmpeg -y -i "$IMAGE_PATH" -vframes 1 -f image2 "$EXTRACTED_FRAME" >/dev/null 2>&1 || true
            IMAGE_PATH="$EXTRACTED_FRAME"
        fi
    fi
fi

# Sync desktop interface color-scheme if gsettings is present
if command -v gsettings &>/dev/null; then
    if [[ "$MODE" == "dark" ]]; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    elif [[ "$MODE" == "light" ]]; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' 2>/dev/null || true
    fi
fi

# Prepare generate_colors_material.py arguments
GEN_ARGS=()

if [[ -n "$PALETTE" ]]; then
    GEN_ARGS+=(--palette "$PALETTE")
fi

if [[ -n "$PRIMARY_SLOT" ]]; then
    GEN_ARGS+=(--primary-slot "$PRIMARY_SLOT")
fi

if [[ -n "$IMAGE_PATH" && -f "$IMAGE_PATH" ]]; then
    GEN_ARGS+=(--path "$IMAGE_PATH")
elif [[ -n "$SEED_COLOR" ]]; then
    GEN_ARGS+=(--color "$SEED_COLOR")
fi

GEN_ARGS+=(--mode "$MODE")
GEN_ARGS+=(--scheme "$SCHEME")

if [[ -f "$TERMINAL_SCHEME" ]]; then
    GEN_ARGS+=(--termscheme "$TERMINAL_SCHEME")
fi

_JSON_OUT="$STATE_DIR/user/generated/colors.json"
_PALETTE_OUT="$STATE_DIR/user/generated/palette.json"
_APP_PALETTE_OUT="$STATE_DIR/user/generated/app-palette.json"
_TERMINAL_OUT="$STATE_DIR/user/generated/terminal.json"
_META_OUT="$STATE_DIR/user/generated/theme-meta.json"
_SCSS_OUT="$STATE_DIR/user/generated/material_colors.scss"

GEN_ARGS+=(
    --json-output "$_JSON_OUT"
    --asura-output "$ASURA_COLORS"
    --palette-output "$_PALETTE_OUT"
    --app-palette-output "$_APP_PALETTE_OUT"
    --terminal-output "$_TERMINAL_OUT"
    --meta-output "$_META_OUT"
    --scss-output "$_SCSS_OUT"
)

# Check app theming and disabled templates from configuration
APP_THEMING_ENABLED=true
CONFIG_JSON_FILE="$XDG_CONFIG_HOME/asura/config.json"
if [[ ! -f "$CONFIG_JSON_FILE" && -f "$XDG_CONFIG_HOME/quickshell/Asura/config/config.json" ]]; then
    CONFIG_JSON_FILE="$XDG_CONFIG_HOME/quickshell/Asura/config/config.json"
fi
if [[ -f "$CONFIG_JSON_FILE" ]] && command -v jq &>/dev/null; then
    if [[ $(jq -r '.appThemingEnabled // true' "$CONFIG_JSON_FILE" 2>/dev/null) == "false" ]]; then
        APP_THEMING_ENABLED=false
    fi
fi

is_template_disabled() {
    local tname="$1"
    if [[ "$APP_THEMING_ENABLED" == "false" ]]; then
        return 0
    fi
    if [[ -f "$CONFIG_JSON_FILE" ]] && command -v jq &>/dev/null; then
        local found
        found=$(jq -r --arg n "$tname" '(.disabledTemplates // [])[] | select(. == $n)' "$CONFIG_JSON_FILE" 2>/dev/null || true)
        if [[ -n "$found" ]]; then
            return 0
        fi
    fi
    return 1
}

if [[ "$APP_THEMING_ENABLED" == "true" && -d "$TEMPLATE_DIR" ]]; then
    GEN_ARGS+=(--render-templates "$TEMPLATE_DIR")
fi

# Execute Material You generation
echo "[switchwall.sh] Generating Material You colors (mode: $MODE, scheme: $SCHEME)..."
"$PYTHON_BIN" "$SCRIPT_DIR/generate_colors_material.py" "${GEN_ARGS[@]}" >/dev/null 2>&1 || true
if [[ "$APP_THEMING_ENABLED" == "true" ]] && ! is_template_disabled "vivaldi" && ! is_template_disabled "vivaldi-compat"; then
if [[ -n "$IMAGE_PATH" && -f "$IMAGE_PATH" ]]; then
    VIVALDI_THUMB_DIR="$HOME/.config/vivaldi/Default/VivaldiThumbnails"
    if [[ -d "$HOME/.config/vivaldi" ]]; then
        mkdir -p "$VIVALDI_THUMB_DIR"
        "$PYTHON_BIN" -c '
import json, os, sys
from PIL import Image

wall = sys.argv[1]
pref_path = os.path.expanduser("~/.config/vivaldi/Default/Preferences")
pal_path = sys.argv[2]
thumb_dir = os.path.expanduser("~/.config/vivaldi/Default/VivaldiThumbnails")

try:
    with open(pal_path) as f:
        pal = json.load(f)
    bg_hex = pal.get("background", "#191b1f")
    fg_hex = pal.get("on_surface", "#c2bdbd")
    accent_hex = pal.get("primary", "#b16873")
    surface_hex = pal.get("surface", "#2e2f37")

    im = Image.open(wall).convert("RGB")
    im.save(os.path.join(thumb_dir, "AsuraWallpaper.jpg"), "JPEG", quality=95)
    im.save(os.path.join(thumb_dir, "APFHCOH3KOCXQAA5MKVZZVNBTQSZAT6E.jpg"), "JPEG", quality=95)

    if os.path.exists(pref_path):
        with open(pref_path, "r") as f:
            data = json.load(f)
        viv = data.setdefault("vivaldi", {})
        themes = viv.setdefault("themes", {})
        user_themes = themes.setdefault("user", [])
        for t in user_themes:
            if t.get("name") in ("Asura Dragonfall", "Dragonfall"):
                t["colorBg"] = bg_hex
                t["colorFg"] = fg_hex
                t["colorAccentBg"] = accent_hex
                t["colorHighlightBg"] = accent_hex
                t["colorWindowBg"] = surface_hex
                t["backgroundImage"] = "chrome://vivaldi-data/thumbnail/APFHCOH3KOCXQAA5MKVZZVNBTQSZAT6E.jpg"
        themes["current"] = "ffde18ac-2952-4fc6-843e-e1b9447c2d41"
        sched = viv.setdefault("theme", {}).setdefault("schedule", {})
        os_dict = sched.setdefault("o_s", {})
        os_dict["dark"] = "ffde18ac-2952-4fc6-843e-e1b9447c2d41"
        os_dict["light"] = "ffde18ac-2952-4fc6-843e-e1b9447c2d41"
        app = viv.setdefault("appearance", {})
        asura_viv_dir = os.path.expanduser("~/.config/asura/vivaldi")
        os.makedirs(asura_viv_dir, exist_ok=True)
        app["css_ui_mods_directory"] = asura_viv_dir
        tmp_path = pref_path + ".tmp"
        with open(tmp_path, "w") as f:
            json.dump(data, f, indent=2)
        os.replace(tmp_path, pref_path)
except Exception:
    pass
' "$IMAGE_PATH" "$_PALETTE_OUT" 2>/dev/null || true
    fi
fi
fi

if [[ "$APP_THEMING_ENABLED" == "true" ]] && ! is_template_disabled "vscode-raw" && ! is_template_disabled "vscode-json"; then
    if [[ -f "$SCRIPT_DIR/vscode/theme_generator.py" && -f "$_PALETTE_OUT" ]]; then
        "$PYTHON_BIN" "$SCRIPT_DIR/vscode/theme_generator.py" \
            --colors "$_PALETTE_OUT" \
            --scss "$_SCSS_OUT" >/dev/null 2>&1 || true
    fi
fi

if [[ -f "$SEQUENCES_TEMPLATE" && -f "$_TERMINAL_OUT" ]] && command -v jq &>/dev/null; then
    SEQUENCES_FILE="$STATE_DIR/user/generated/terminal/sequences.txt"
    mkdir -p "$(dirname "$SEQUENCES_FILE")"
    cp "$SEQUENCES_TEMPLATE" "$SEQUENCES_FILE"
    for idx in $(seq 0 15); do
        val=$(jq -r ".term${idx} // empty" "$_TERMINAL_OUT" 2>/dev/null || true)
        if [[ -n "$val" ]]; then
            sed -i "s/\$term${idx} #/${val#\#}/g" "$SEQUENCES_FILE"
        fi
    done
    sed -i 's/\$alpha/100/g' "$SEQUENCES_FILE"

    for pts in /dev/pts/[0-9]*; do
        if [[ -w "$pts" ]]; then
            is_kitty=false
            for p in /proc/[0-9]*/fd/0; do
                if [[ "$(readlink "$p" 2>/dev/null || true)" == "$pts" ]]; then
                    pid="${p#/proc/}"
                    pid="${pid%/fd/0}"
                    cur="$pid"
                    while [[ "$cur" -gt 1 ]]; do
                        comm=$(cat "/proc/$cur/comm" 2>/dev/null || true)
                        if [[ "$comm" == "kitty" || "$comm" == *"antigravity"* ]]; then
                            is_kitty=true
                            break 2
                        fi
                        ppid=$(awk '/^PPid:/{print $2}' "/proc/$cur/status" 2>/dev/null || true)
                        [[ "$ppid" == "$cur" || -z "$ppid" ]] && break
                        cur="$ppid"
                    done
                fi
            done
            if [[ "$is_kitty" == false ]]; then
                cat "$SEQUENCES_FILE" > "$pts" 2>/dev/null || true
            fi
        fi
    done
fi

if [[ "$APP_THEMING_ENABLED" == "true" ]] && ! is_template_disabled "kitty"; then
    if pgrep -x kitty &>/dev/null; then
        kitty +kitten themes --reload-in=all Asura 2>/dev/null || pkill -SIGUSR1 -x kitty 2>/dev/null || true
    fi
fi

if [[ -n "$EXTRACTED_FRAME" && -f "$EXTRACTED_FRAME" ]]; then
    rm -f "$EXTRACTED_FRAME"
fi

echo "[switchwall.sh] Colors generated successfully."
