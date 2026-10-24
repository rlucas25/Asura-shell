#!/usr/bin/env python3
import sys
import os
import re
import shutil
import subprocess
import json
import time
from datetime import datetime

ASURA_DIR = os.path.expanduser("~/.config/asura")
DATA_DIR = os.path.join(ASURA_DIR, "data")
PRESETS_DIR = os.path.join(DATA_DIR, "presets")
PRESETS_INDEX_FILE = os.path.join(PRESETS_DIR, "presets.json")

CONFIG_FILE = os.path.join(ASURA_DIR, "config.json")
COLORS_FILE = os.path.join(ASURA_DIR, "colors.json")
BAR_WIDGETS_FILE = os.path.join(ASURA_DIR, "bar_widgets.json")
HYPR_VARS_FILE = os.path.join(ASURA_DIR, "hypr-vars.lua")
WINDOW_MGR_SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "window_manager.py")
DEFAULT_APPS_MGR_SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "default_apps_manager.py")
MONITOR_MGR_SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "monitor_manager.py")
KEYBOARD_MGR_SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "keyboard_manager.py")
SHORTCUTS_MGR_SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "shortcuts_manager.py")

# Configuration keys grouped by settings tab
TAB_CONFIG_KEYS = {
    "theme": [
        "theme", "scheme", "isDarkMode", "colorsAutoGenerate", "primarySlot"
    ],
    "general": [
        "opacity", "generalOpacity", "generalRadius", "blurEnabled", "blurStrength",
        "clockFormat", "clock24h", "wallpaperAnimation", "wallpaperAnimationDuration",
        "wallpaperFolder", "recordingsFolder"
    ],
    "bar": [
        "barPosition", "barThickness", "barIconScale",
        "barMode", "widthS", "exclusiveMode", "autoHide", "barCapsuleRadius",
        "barFollowsGeneralOpacity", "barFollowsGeneralRadius",
        "barMeltEnabled", "barMeltRadius", "barMeltStyle",
        "barVisualizerEnabled", "barVisualizerType", "barVisualizerHeight",
        "barVisualizerOpacity", "barVisualizerBarsOrigin", "barVisualizerDensity",
        "barVisualizerGap", "barVisualizerSmoothing",
        "barEdgeSpacing", "barCapsulePadding", "barWidgetSpacing", "barCapsuleWidgetSpacing",
        "barWidgetHoverTextEnabled", "barHoverMenusEnabled",
        "hardwareHidePercent", "hardwareShowAbsolute",
        "workspacesCount", "workspacesNumberStyle", "workspacesShowNumbers"
    ],
    "windows": [],
    "launcher": [
        "launcherPosition", "launcherCommandsNoPrefix", "launcherCalculatorNoPrefix", "launcherWebSearchNoPrefix"
    ],
    "apptheming": [
        "appThemingEnabled", "disabledTemplates"
    ],
    "notifications": [
        "notificationSound", "notificationTimeout", "alertsPopups", "soundEffects"
    ],
    "defaultapps": [
        "defaultApps", "launcherHiddenApps"
    ],
    "monitors": [],
    "keyboard": [
        "keyboardLayouts", "keyboardSwitchOption", "keyboardNumlockByDefault",
        "keyboardRepeatRate", "keyboardRepeatDelay", "mouseSensitivity",
        "mouseAccelProfile", "mouseNaturalScroll", "mouseLeftHanded",
        "mouseScrollFactor", "mouseFollowFocus", "touchpadNaturalScroll",
        "touchpadDisableWhileTyping", "touchpadTapToClick", "touchpadScrollFactor",
        "cursorNoWarps"
    ],
    "shortcuts": [
        "customKeybinds"
    ]
}

TAB_LABELS = {
    "theme": "Theme",
    "general": "General",
    "windows": "Windows",
    "bar": "Bar",
    "launcher": "Launcher",
    "apptheming": "App Theming",
    "notifications": "Notifications",
    "defaultapps": "Apps",
    "monitors": "Monitors",
    "keyboard": "Mouse & Keyboard",
    "shortcuts": "Shortcuts"
}

# The default tabs selected when creating presets remain unchanged
DEFAULT_TABS = ["theme", "general", "windows", "bar", "launcher", "apptheming"]

def ensure_dirs():
    os.makedirs(PRESETS_DIR, exist_ok=True)

def read_json_file(path, default=None):
    if default is None:
        default = {}
    if not os.path.exists(path):
        return default
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return default

def write_json_file(path, data):
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4, ensure_ascii=False)
    os.replace(tmp, path)

def check_zone_active(zone_list):
    if not zone_list or not isinstance(zone_list, list):
        return False
    return any(w.get("visible", True) for w in zone_list)

def get_window_settings():
    try:
        res = subprocess.run(["python3", WINDOW_MGR_SCRIPT, "get"], capture_output=True, text=True, timeout=3)
        if res.returncode == 0 and res.stdout.strip():
            return json.loads(res.stdout)
    except Exception:
        pass
    return {}

def get_monitor_settings():
    try:
        if os.path.exists(MONITOR_MGR_SCRIPT):
            res = subprocess.run(["python3", MONITOR_MGR_SCRIPT, "get"], capture_output=True, text=True, timeout=3)
            if res.returncode == 0 and res.stdout.strip():
                return json.loads(res.stdout)
    except Exception as e:
        sys.stderr.write(f"Failed to get monitor settings: {e}\n")
    return []

def get_keyboard_settings():
    try:
        if os.path.exists(KEYBOARD_MGR_SCRIPT):
            res = subprocess.run(["python3", KEYBOARD_MGR_SCRIPT, "get"], capture_output=True, text=True, timeout=3)
            if res.returncode == 0 and res.stdout.strip():
                data = json.loads(res.stdout)
                if isinstance(data, dict):
                    # Omit large layout catalog from preset snapshot
                    data.pop("allAvailableLayouts", None)
                return data
    except Exception as e:
        sys.stderr.write(f"Failed to get keyboard settings: {e}\n")
    return {}

def get_shortcuts_settings():
    try:
        if os.path.exists(SHORTCUTS_MGR_SCRIPT):
            res = subprocess.run(["python3", SHORTCUTS_MGR_SCRIPT, "get_preset"], capture_output=True, text=True, timeout=3)
            if res.returncode == 0 and res.stdout.strip():
                return json.loads(res.stdout)
    except Exception as e:
        sys.stderr.write(f"Failed to get shortcuts settings: {e}\n")
    return {}

def list_presets():
    ensure_dirs()
    index_data = read_json_file(PRESETS_INDEX_FILE, default=[])
    if not isinstance(index_data, list):
        index_data = []

    # Verify that stored presets still exist on disk
    valid_presets = []
    for p in index_data:
        p_id = p.get("id")
        p_dir = os.path.join(PRESETS_DIR, p_id)
        if p_id and os.path.exists(p_dir):
            # Ensure wallpaper path is valid if preset has one
            wp_path = p.get("wallpaperCopyPath")
            if wp_path and not os.path.exists(wp_path):
                # Look for wallpaper.* in preset directory
                for f in os.listdir(p_dir):
                    if f.startswith("wallpaper."):
                        p["wallpaperCopyPath"] = os.path.join(p_dir, f)
                        break

            # Calculate whether this preset alters extra settings beyond the default rice scope
            tabs = p.get("tabs", [])
            if not tabs:
                tabs = list(DEFAULT_TABS)
                p["tabs"] = tabs
            extra = [t for t in tabs if t not in DEFAULT_TABS]
            p["hasExtraSettings"] = len(extra) > 0
            p["extraTabs"] = extra

            # Ensure primarySlot and bar preview metadata are tracked in manifest
            needs_manifest_sync = ("primarySlot" not in p or "barPosition" not in p or "barMode" not in p or "activeCapsules" not in p)
            if needs_manifest_sync:
                preset_json_file = os.path.join(p_dir, "preset.json")
                if os.path.exists(preset_json_file):
                    p_full = read_json_file(preset_json_file, default={})
                    cfg = p_full.get("config", {})
                    bw = p_full.get("barWidgets", {})

                    if "primarySlot" not in p:
                        p["primarySlot"] = (
                            p_full.get("manifest", {}).get("primarySlot")
                            or p_full.get("colors", {}).get("primarySlot")
                            or cfg.get("primarySlot")
                            or "base0D"
                        )
                    if "barPosition" not in p:
                        p["barPosition"] = cfg.get("barPosition") or "top"
                    if "barMode" not in p:
                        p["barMode"] = cfg.get("barMode", 1) if "barMode" in cfg else 1
                    if "activeCapsules" not in p:
                        p["activeCapsules"] = {
                            "left": check_zone_active(bw.get("left")) if "left" in bw else True,
                            "center": check_zone_active(bw.get("center")) if "center" in bw else True,
                            "right": check_zone_active(bw.get("right")) if "right" in bw else True
                        }
                else:
                    if "primarySlot" not in p:
                        p["primarySlot"] = "base0D"
                    if "barPosition" not in p:
                        p["barPosition"] = "top"
                    if "barMode" not in p:
                        p["barMode"] = 1
                    if "activeCapsules" not in p:
                        p["activeCapsules"] = {"left": True, "center": True, "right": True}

            valid_presets.append(p)

    needs_save = (len(valid_presets) != len(index_data) or any(
        "primarySlot" not in item or "barPosition" not in item or "barMode" not in item or "activeCapsules" not in item
        for item in index_data
    ))
    if needs_save:
        write_json_file(PRESETS_INDEX_FILE, valid_presets)

    print(json.dumps(valid_presets), flush=True)

def save_preset(name, preset_id=None, selected_tabs=None):
    ensure_dirs()
    if not name or not name.strip():
        name = "Preset " + datetime.now().strftime("%Y-%m-%d %H:%M")
    name = name.strip()

    is_update = bool(preset_id)
    if not preset_id:
        slug = re.sub(r'[^a-zA-Z0-9_\-]+', '_', name.lower()).strip('_')
        if not slug:
            slug = "preset"
        preset_id = f"{slug}_{int(time.time())}"

    preset_folder = os.path.join(PRESETS_DIR, preset_id)
    os.makedirs(preset_folder, exist_ok=True)

    # Normalize selected tabs
    if selected_tabs is None or not isinstance(selected_tabs, list) or len(selected_tabs) == 0:
        selected_tabs = list(DEFAULT_TABS)
    else:
        selected_tabs = [str(t).lower().strip() for t in selected_tabs]

    # 1. Read Current Configuration Snapshots
    config_data = read_json_file(CONFIG_FILE, default={})
    colors_data = read_json_file(COLORS_FILE, default={})
    bar_widgets_data = read_json_file(BAR_WIDGETS_FILE, default={})
    window_data = get_window_settings() if "windows" in selected_tabs else {}
    monitors_data = get_monitor_settings() if "monitors" in selected_tabs else []
    keyboard_data = get_keyboard_settings() if "keyboard" in selected_tabs else {}
    shortcuts_data = get_shortcuts_settings() if "shortcuts" in selected_tabs else {}

    # Primary accent color slot (e.g. base08 - base0F)
    primary_slot = colors_data.get("primarySlot") or config_data.get("primarySlot", "base0D")
    colors_data["primarySlot"] = primary_slot
    config_data["primarySlot"] = primary_slot

    # 2. Capture and Copy Wallpaper if general or theme is included
    raw_wp = config_data.get("wallpaper", "")
    expanded_wp = os.path.expanduser(raw_wp) if raw_wp else ""
    dest_wp_path = ""
    has_wp_tab = ("general" in selected_tabs) or ("theme" in selected_tabs)

    if has_wp_tab and expanded_wp and os.path.exists(expanded_wp):
        wallpaper_ext = ".jpg"
        _, ext = os.path.splitext(expanded_wp)
        if ext:
            wallpaper_ext = ext.lower()

        dest_wp_filename = f"wallpaper{wallpaper_ext}"
        dest_wp_path = os.path.join(preset_folder, dest_wp_filename)

        try:
            shutil.copy2(expanded_wp, dest_wp_path)
        except Exception as e:
            sys.stderr.write(f"Failed to copy wallpaper: {e}\n")
    elif has_wp_tab:
        dest_wp_filename = "wallpaper.jpg"
        dest_wp_path = os.path.join(preset_folder, dest_wp_filename)
        if not os.path.exists(dest_wp_path):
            with open(dest_wp_path, "wb") as f:
                f.write(b"")

    # 3. Colors summary for preview cards
    if primary_slot in colors_data and colors_data[primary_slot]:
        primary_col = colors_data[primary_slot]
        colors_data["primary"] = primary_col
    else:
        primary_col = colors_data.get("primary", "#e0b0ff")
    secondary_col = colors_data.get("secondary", "#b0c4de")
    surface_col = colors_data.get("surface", "#1e1e2e")
    bg_col = colors_data.get("base00", colors_data.get("background", "#181825"))

    now_iso = datetime.now().isoformat()
    existing_created_at = now_iso
    index_list = read_json_file(PRESETS_INDEX_FILE, default=[])
    if not isinstance(index_list, list):
        index_list = []

    for item in index_list:
        if item.get("id") == preset_id and item.get("createdAt"):
            existing_created_at = item.get("createdAt")
            break

    # 4. Filter config keys for selected tabs
    filtered_config = {}
    for tab in selected_tabs:
        if tab in TAB_CONFIG_KEYS:
            for k in TAB_CONFIG_KEYS[tab]:
                if k in config_data:
                    filtered_config[k] = config_data[k]
    if "theme" in selected_tabs:
        filtered_config["primarySlot"] = primary_slot

    # Map selected tabs to display component labels
    components = [TAB_LABELS.get(t, t.capitalize()) for t in selected_tabs]

    # Detect if preset alters extra settings beyond default rice scope
    extra_tabs = [t for t in selected_tabs if t not in DEFAULT_TABS]
    has_extra_settings = len(extra_tabs) > 0

    # Bar preview metadata
    has_bar_tab = "bar" in selected_tabs
    bar_pos = config_data.get("barPosition") or "top"
    bar_mode = config_data.get("barMode", 1) if "barMode" in config_data else 1
    has_left_cap = check_zone_active(bar_widgets_data.get("left")) if "left" in bar_widgets_data else True
    has_center_cap = check_zone_active(bar_widgets_data.get("center")) if "center" in bar_widgets_data else True
    has_right_cap = check_zone_active(bar_widgets_data.get("right")) if "right" in bar_widgets_data else True

    # 5. Construct Preset Manifest & Payload
    preset_manifest = {
        "id": preset_id,
        "name": name,
        "createdAt": existing_created_at,
        "updatedAt": now_iso,
        "wallpaperCopyPath": dest_wp_path,
        "originalWallpaper": raw_wp if has_wp_tab else "",
        "theme": config_data.get("theme", "dracula"),
        "colorsAutoGenerate": config_data.get("colorsAutoGenerate", False),
        "scheme": config_data.get("scheme", "tonal-spot"),
        "isDarkMode": config_data.get("isDarkMode", True),
        "primarySlot": primary_slot,
        "primaryColor": primary_col,
        "secondaryColor": secondary_col,
        "surfaceColor": surface_col,
        "backgroundColor": bg_col,
        "barPosition": bar_pos,
        "barMode": bar_mode,
        "activeCapsules": {
            "left": has_left_cap,
            "center": has_center_cap,
            "right": has_right_cap
        },
        "tabs": selected_tabs,
        "components": components,
        "hasExtraSettings": has_extra_settings,
        "extraTabs": extra_tabs
    }

    preset_full_data = {
        "manifest": preset_manifest,
        "tabs": selected_tabs,
        "config": filtered_config,
        "colors": colors_data if "theme" in selected_tabs else {},
        "barWidgets": bar_widgets_data if "bar" in selected_tabs else {},
        "windows": window_data if "windows" in selected_tabs else {},
        "monitors": monitors_data if "monitors" in selected_tabs else [],
        "keyboard": keyboard_data if "keyboard" in selected_tabs else {},
        "shortcuts": shortcuts_data if "shortcuts" in selected_tabs else {}
    }

    # Save full preset snapshot
    write_json_file(os.path.join(preset_folder, "preset.json"), preset_full_data)

    # Update index file
    updated_index = [p for p in index_list if p.get("id") != preset_id]
    updated_index.insert(0, preset_manifest)
    write_json_file(PRESETS_INDEX_FILE, updated_index)

    print(json.dumps({"status": "ok", "preset": preset_manifest}), flush=True)

def apply_preset(preset_id):
    ensure_dirs()
    preset_folder = os.path.join(PRESETS_DIR, preset_id)
    preset_json_path = os.path.join(preset_folder, "preset.json")

    if not os.path.exists(preset_json_path):
        print(json.dumps({"status": "error", "message": f"Preset {preset_id} not found"}))
        return

    full_data = read_json_file(preset_json_path)
    manifest = full_data.get("manifest", {})
    saved_cfg = full_data.get("config", {})
    saved_colors = full_data.get("colors", {})
    saved_widgets = full_data.get("barWidgets", {})
    saved_windows = full_data.get("windows", {})
    saved_monitors = full_data.get("monitors", [])
    saved_keyboard = full_data.get("keyboard", {})
    saved_shortcuts = full_data.get("shortcuts", {})

    saved_tabs = full_data.get("tabs")
    if saved_tabs is None:
        saved_tabs = manifest.get("tabs")
    if saved_tabs is None:
        # Legacy presets without tabs restore all default categories
        saved_tabs = list(DEFAULT_TABS)
    else:
        saved_tabs = [str(t).lower().strip() for t in saved_tabs]

    wp_copy = manifest.get("wallpaperCopyPath")
    if not wp_copy or not os.path.exists(wp_copy):
        for f in os.listdir(preset_folder):
            if f.startswith("wallpaper."):
                wp_copy = os.path.join(preset_folder, f)
                break

    # 1. Restore colors.json if theme tab was saved
    primary_slot = None
    if "theme" in saved_tabs:
        primary_slot = (
            saved_colors.get("primarySlot")
            or manifest.get("primarySlot")
            or saved_cfg.get("primarySlot")
            or "base0D"
        )
        if saved_colors:
            saved_colors["primarySlot"] = primary_slot
            if primary_slot in saved_colors and saved_colors[primary_slot]:
                saved_colors["primary"] = saved_colors[primary_slot]
            write_json_file(COLORS_FILE, saved_colors)

    # 2. Restore bar_widgets.json if bar tab was saved
    if "bar" in saved_tabs and saved_widgets:
        write_json_file(BAR_WIDGETS_FILE, saved_widgets)

    # 3. Restore config.json keys for saved tabs
    current_cfg = read_json_file(CONFIG_FILE, default={})
    for tab in saved_tabs:
        if tab in TAB_CONFIG_KEYS:
            for k in TAB_CONFIG_KEYS[tab]:
                if k in saved_cfg:
                    current_cfg[k] = saved_cfg[k]

    if "theme" in saved_tabs:
        if primary_slot:
            current_cfg["primarySlot"] = primary_slot
        for k in ["theme", "scheme", "isDarkMode", "colorsAutoGenerate"]:
            if k in saved_cfg:
                current_cfg[k] = saved_cfg[k]
            elif k in manifest:
                current_cfg[k] = manifest[k]

    if ("general" in saved_tabs or "theme" in saved_tabs) and wp_copy and os.path.exists(wp_copy):
        current_cfg["wallpaper"] = wp_copy

    write_json_file(CONFIG_FILE, current_cfg)

    # 4. Apply Window settings to Hyprland if windows tab was saved
    if "windows" in saved_tabs and saved_windows:
        try:
            subprocess.run(["python3", WINDOW_MGR_SCRIPT, "apply", json.dumps(saved_windows)], capture_output=True, timeout=3)
        except Exception as e:
            sys.stderr.write(f"Failed to apply window settings: {e}\n")

    # 5. Apply Wallpaper via awww if general or theme tab was saved
    if ("general" in saved_tabs or "theme" in saved_tabs) and wp_copy and os.path.exists(wp_copy):
        anim = current_cfg.get("wallpaperAnimation", "wave")
        duration = current_cfg.get("wallpaperAnimationDuration", 1.5)
        try:
            subprocess.run(["awww", "img", wp_copy, "--transition-type", str(anim), "--transition-duration", str(duration)], capture_output=True, timeout=4)
        except Exception:
            try:
                subprocess.run(["hyprctl", "hyprpaper", "wallpaper", f",{wp_copy}"], capture_output=True, timeout=2)
            except Exception:
                pass

    # 6. Apply Default Apps if defaultapps tab was saved
    if "defaultapps" in saved_tabs and "defaultApps" in saved_cfg:
        if os.path.exists(DEFAULT_APPS_MGR_SCRIPT):
            try:
                subprocess.run(["python3", DEFAULT_APPS_MGR_SCRIPT, "apply", json.dumps(saved_cfg["defaultApps"])], capture_output=True, timeout=3)
            except Exception as e:
                sys.stderr.write(f"Failed to apply default apps: {e}\n")

    # 7. Apply Monitor settings if monitors tab was saved
    if "monitors" in saved_tabs and saved_monitors:
        if os.path.exists(MONITOR_MGR_SCRIPT):
            try:
                subprocess.run(["python3", MONITOR_MGR_SCRIPT, "apply_all", json.dumps(saved_monitors)], capture_output=True, timeout=4)
            except Exception as e:
                sys.stderr.write(f"Failed to apply monitor settings: {e}\n")

    # 8. Apply Keyboard & Mouse settings if keyboard tab was saved
    if "keyboard" in saved_tabs and saved_keyboard:
        if os.path.exists(KEYBOARD_MGR_SCRIPT):
            try:
                subprocess.run(["python3", KEYBOARD_MGR_SCRIPT, "apply", json.dumps(saved_keyboard)], capture_output=True, timeout=3)
            except Exception as e:
                sys.stderr.write(f"Failed to apply keyboard settings: {e}\n")

    # 9. Apply Shortcuts settings if shortcuts tab was saved
    if "shortcuts" in saved_tabs:
        if os.path.exists(SHORTCUTS_MGR_SCRIPT):
            try:
                payload = saved_shortcuts if isinstance(saved_shortcuts, dict) and saved_shortcuts else {
                    "vars": {},
                    "custom": saved_cfg.get("customKeybinds", [])
                }
                subprocess.run(["python3", SHORTCUTS_MGR_SCRIPT, "apply_preset", json.dumps(payload)], capture_output=True, timeout=4)
            except Exception as e:
                sys.stderr.write(f"Failed to apply shortcuts settings: {e}\n")

    print(json.dumps({
        "status": "ok",
        "appliedId": preset_id,
        "name": manifest.get("name", ""),
        "primarySlot": primary_slot if "theme" in saved_tabs else None
    }), flush=True)

def delete_preset(preset_id):
    ensure_dirs()
    preset_folder = os.path.join(PRESETS_DIR, preset_id)
    if os.path.exists(preset_folder):
        try:
            shutil.rmtree(preset_folder)
        except Exception as e:
            sys.stderr.write(f"Failed to remove preset folder: {e}\n")

    index_list = read_json_file(PRESETS_INDEX_FILE, default=[])
    if isinstance(index_list, list):
        updated = [p for p in index_list if p.get("id") != preset_id]
        write_json_file(PRESETS_INDEX_FILE, updated)

    print(json.dumps({"status": "ok", "deletedId": preset_id}), flush=True)

def main():
    if len(sys.argv) < 2:
        list_presets()
        return

    cmd = sys.argv[1]
    if cmd == "list":
        list_presets()
    elif cmd == "save":
        payload_str = sys.argv[2] if len(sys.argv) > 2 else "{}"
        try:
            data = json.loads(payload_str)
        except Exception:
            data = {"name": payload_str}
        name = data.get("name", "")
        p_id = data.get("id", None)
        selected_tabs = data.get("tabs", None)
        save_preset(name, p_id, selected_tabs)
    elif cmd == "apply":
        p_id = sys.argv[2] if len(sys.argv) > 2 else ""
        apply_preset(p_id)
    elif cmd == "delete":
        p_id = sys.argv[2] if len(sys.argv) > 2 else ""
        delete_preset(p_id)
    elif cmd == "overwrite":
        payload_str = sys.argv[2] if len(sys.argv) > 2 else ""
        try:
            data = json.loads(payload_str)
            p_id = data.get("id", "")
            p_name = data.get("name", "")
            p_tabs = data.get("tabs", None)
        except Exception:
            p_id = payload_str
            p_name = ""
            p_tabs = None

        if not p_name:
            index_list = read_json_file(PRESETS_INDEX_FILE, default=[])
            for p in index_list:
                if p.get("id") == p_id:
                    p_name = p.get("name", "")
                    if p_tabs is None:
                        p_tabs = p.get("tabs", None)
                    break
        save_preset(p_name or p_id, p_id, p_tabs)
    else:
        sys.stderr.write(f"Unknown command {cmd}\n")
        sys.exit(1)

if __name__ == "__main__":
    main()
