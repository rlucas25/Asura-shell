#!/usr/bin/env python3
import json
import os
import re
import subprocess
import sys

ASURA_DIR = os.path.expanduser("~/.config/asura")
HYPR_DIR = os.path.expanduser("~/.config/hypr")
HYPR_VARS_FILE = os.path.join(ASURA_DIR, "hypr-vars.lua")
HYPR_USER_FILE = os.path.join(ASURA_DIR, "hypr-user.lua")
CONFIG_JSON_FILE = os.path.join(ASURA_DIR, "config.json")
DEFAULT_VARS_FILE = os.path.join(HYPR_DIR, "variables.lua")

# Known built-in keybind catalog with human-readable labels, hints and categories
SYSTEM_CATALOG = [
    # Windows & Layout
    {
        "id": "kbCloseWindow",
        "category": "windows",
        "label": "Close Active Window",
        "hint": "Closes the currently focused window gracefully",
        "default": "SUPER + Q",
        "var": "kbCloseWindow"
    },
    {
        "id": "kbToggleWindowFloating",
        "category": "windows",
        "label": "Toggle Floating Window",
        "hint": "Switches active window between tiled and floating mode",
        "default": "SUPER + W",
        "var": "kbToggleWindowFloating"
    },
    {
        "id": "kbWindowFullscreen",
        "category": "windows",
        "label": "Toggle Fullscreen",
        "hint": "Expands the active window across the entire screen",
        "default": "SUPER + SHIFT + F",
        "var": "kbWindowFullscreen"
    },
    {
        "id": "kbWindowBorderedFullscreen",
        "category": "windows",
        "label": "Toggle Maximized Window",
        "hint": "Maximizes the window keeping margins and borders visible",
        "default": "SUPER + F",
        "var": "kbWindowBorderedFullscreen"
    },
    {
        "id": "kbPinWindow",
        "category": "windows",
        "label": "Pin Window (Sticky)",
        "hint": "Keeps active window visible across all workspaces",
        "default": "SUPER + P",
        "var": "kbPinWindow"
    },
    {
        "id": "kbMoveWindow",
        "category": "windows",
        "label": "Move Window (Drag)",
        "hint": "Hold modifier and drag window with left mouse button",
        "default": "SUPER + Z",
        "var": "kbMoveWindow"
    },
    {
        "id": "kbResizeWindow",
        "category": "windows",
        "label": "Resize Window (Drag)",
        "hint": "Hold modifier and drag window border with right mouse button",
        "default": "SUPER + X",
        "var": "kbResizeWindow"
    },
    {
        "id": "kbWindowPip",
        "category": "windows",
        "label": "Picture-in-Picture Mode",
        "hint": "Pins window and floats it in a compact corner preview",
        "default": "SUPER + ALT + backslash",
        "var": "kbWindowPip"
    },
    {
        "id": "kbToggleGroup",
        "category": "windows",
        "label": "Toggle Window Group / Tab",
        "hint": "Groups adjacent windows into tabbed container",
        "default": "SUPER + Comma",
        "var": "kbToggleGroup"
    },
    {
        "id": "kbUngroup",
        "category": "windows",
        "label": "Ungroup Window",
        "hint": "Detaches window from the current tabbed group",
        "default": "SUPER + U",
        "var": "kbUngroup"
    },
    {
        "id": "kbWindowGroupCycleNext",
        "category": "windows",
        "label": "Next Window in Group",
        "hint": "Cycles to next tab in current window group",
        "default": "CTRL + ALT + TAB",
        "var": "kbWindowGroupCycleNext"
    },
    {
        "id": "kbWindowGroupCyclePrev",
        "category": "windows",
        "label": "Previous Window in Group",
        "hint": "Cycles to previous tab in current window group",
        "default": "CTRL + SHIFT + ALT + TAB",
        "var": "kbWindowGroupCyclePrev"
    },

    # Workspaces
    {
        "id": "kbGoToWs",
        "category": "workspaces",
        "label": "Switch to Workspace [1-10]",
        "hint": "Direct jump to target workspace number",
        "default": "SUPER",
        "var": "kbGoToWs",
        "suffix": "0-9"
    },
    {
        "id": "kbMoveWinToWs",
        "category": "workspaces",
        "label": "Move Window to Workspace [1-10]",
        "hint": "Sends active window to target workspace",
        "default": "ALT",
        "var": "kbMoveWinToWs",
        "suffix": "0-9"
    },
    {
        "id": "kbNextWs",
        "category": "workspaces",
        "label": "Next Workspace",
        "hint": "Navigates to the next sequential workspace",
        "default": "CTRL + SUPER + Right",
        "var": "kbNextWs"
    },
    {
        "id": "kbPrevWs",
        "category": "workspaces",
        "label": "Previous Workspace",
        "hint": "Navigates to previous sequential workspace",
        "default": "CTRL + SUPER + Left",
        "var": "kbPrevWs"
    },
    {
        "id": "kbSpecialWs",
        "category": "workspaces",
        "label": "Toggle Scratchpad Workspace",
        "hint": "Toggles floating scratchpad overlay workspace",
        "default": "SUPER + S",
        "var": "kbSpecialWs"
    },
    {
        "id": "kbMusicWs",
        "category": "workspaces",
        "label": "Toggle Music Workspace",
        "hint": "Dedicated special workspace for media players",
        "default": "SUPER + M",
        "var": "kbMusicWs"
    },
    {
        "id": "kbCommunicationWs",
        "category": "workspaces",
        "label": "Toggle Chat & Messaging Workspace",
        "hint": "Dedicated workspace for communication apps",
        "default": "SUPER + D",
        "var": "kbCommunicationWs"
    },
    {
        "id": "kbTodoWs",
        "category": "workspaces",
        "label": "Toggle Tasks & Notes Workspace",
        "hint": "Dedicated workspace for tasks and notes",
        "default": "SUPER + R",
        "var": "kbTodoWs"
    },
    {
        "id": "kbSystemMonitorWs",
        "category": "workspaces",
        "label": "Toggle System Monitor Workspace",
        "hint": "Quickly opens btop or system task manager",
        "default": "CTRL + SHIFT + Escape",
        "var": "kbSystemMonitorWs"
    },

    # Menus & Asura Shell
    {
        "id": "kbLauncher",
        "category": "menus",
        "label": "Application Launcher",
        "hint": "Opens Asura application search menu",
        "default": "SUPER + SUPER_L",
        "var": "kbLauncher"
    },
    {
        "id": "kbWallpaperSelector",
        "category": "menus",
        "label": "Wallpaper Gallery Selector",
        "hint": "Opens visual wallpaper gallery and palette preview",
        "default": "SUPER + SHIFT + W",
        "var": "kbWallpaperSelector"
    },
    {
        "id": "kbControlPanel",
        "category": "menus",
        "label": "Control Panel (Dashboard)",
        "hint": "Opens quick settings, audio sliders, and system controls",
        "default": "SUPER + A",
        "var": None
    },
    {
        "id": "kbClipboard",
        "category": "menus",
        "label": "Clipboard History Menu",
        "hint": "Opens Asura clipboard history manager",
        "default": "SUPER + V",
        "var": None
    },
    {
        "id": "kbSettings",
        "category": "menus",
        "label": "Asura Shell Settings",
        "hint": "Opens Asura configuration center",
        "default": "SUPER + SHIFT + C",
        "var": None
    },
    {
        "id": "kbPlayer",
        "category": "menus",
        "label": "Media Player Flyout",
        "hint": "Toggles multimedia controls popup",
        "default": "SUPER + P",
        "var": None
    },
    {
        "id": "kbLock",
        "category": "menus",
        "label": "Lock Screen",
        "hint": "Secures session with Asura lockscreen",
        "default": "SUPER + L",
        "var": "kbLock"
    },
    {
        "id": "kbWindowSwitcher",
        "category": "menus",
        "label": "Window Switcher (Alt-Tab)",
        "hint": "Cycles through open windows with visual preview",
        "default": "ALT + Tab",
        "var": None
    },

    # Applications
    {
        "id": "kbTerminal",
        "category": "apps",
        "label": "Default Terminal",
        "hint": "Launches preferred terminal emulator",
        "default": "SUPER + T",
        "var": "kbTerminal"
    },
    {
        "id": "kbTerminal2",
        "category": "apps",
        "label": "Secondary Terminal Shortcut",
        "hint": "Alternative hotkey to launch terminal emulator",
        "default": "SUPER + Return",
        "var": "kbTerminal2"
    },
    {
        "id": "kbBrowser",
        "category": "apps",
        "label": "Default Web Browser",
        "hint": "Launches preferred web browser",
        "default": "SUPER + B",
        "var": "kbBrowser"
    },
    {
        "id": "kbFileExplorer",
        "category": "apps",
        "label": "Default File Manager",
        "hint": "Launches preferred file explorer",
        "default": "SUPER + E",
        "var": "kbFileExplorer"
    },
    {
        "id": "kbEditor",
        "category": "apps",
        "label": "Default Code Editor",
        "hint": "Launches preferred text or code editor",
        "default": "SUPER + C",
        "var": "kbEditor"
    },

    # Hardware & Media
    {
        "id": "kbBrightnessUp",
        "category": "media",
        "label": "Increase Display Brightness",
        "hint": "Raises screen backlight by 5%",
        "default": "XF86MonBrightnessUp",
        "var": None
    },
    {
        "id": "kbBrightnessDown",
        "category": "media",
        "label": "Decrease Display Brightness",
        "hint": "Lowers screen backlight by 5%",
        "default": "XF86MonBrightnessDown",
        "var": None
    },
    {
        "id": "kbMediaPlayPause",
        "category": "media",
        "label": "Play / Pause Media",
        "hint": "Toggles playback of active audio or video",
        "default": "XF86AudioPlay",
        "var": None
    },
    {
        "id": "kbMediaNext",
        "category": "media",
        "label": "Next Track",
        "hint": "Skips to the next media track",
        "default": "XF86AudioNext",
        "var": None
    },
    {
        "id": "kbMediaPrev",
        "category": "media",
        "label": "Previous Track",
        "hint": "Rewinds or returns to previous media track",
        "default": "XF86AudioPrev",
        "var": None
    },

    # System & Session
    {
        "id": "kbSession",
        "category": "system",
        "label": "Session Power Menu",
        "hint": "Opens shutdown, reboot and logout options",
        "default": "CTRL + ALT + Delete",
        "var": "kbSession"
    },
    {
        "id": "kbClearNotifs",
        "category": "system",
        "label": "Clear All Notifications",
        "hint": "Dismisses all active toast notifications",
        "default": "CTRL + ALT + C",
        "var": "kbClearNotifs"
    }
]

def ensure_asura_dir():
    os.makedirs(ASURA_DIR, exist_ok=True)

def read_hypr_vars_file() -> dict:
    ensure_asura_dir()
    if not os.path.exists(HYPR_VARS_FILE):
        return {}
    data = {}
    try:
        with open(HYPR_VARS_FILE, "r", encoding="utf-8") as f:
            content = f.read()
        for line in content.splitlines():
            line = line.strip()
            if not line or line.startswith("--") or line.startswith("return") or line.startswith("{") or line.startswith("}"):
                continue
            m = re.match(r'([a-zA-Z0-9_]+)\s*=\s*(.+?)[,;]?$', line)
            if m:
                k = m.group(1).strip()
                v = m.group(2).strip()
                if (v.startswith('"') and v.endswith('"')) or (v.startswith("'") and v.endswith("'")):
                    data[k] = v[1:-1]
                elif v == "true":
                    data[k] = True
                elif v == "false":
                    data[k] = False
                elif re.match(r'^-?\d+$', v):
                    data[k] = int(v)
                elif re.match(r'^-?\d+\.\d+$', v):
                    data[k] = float(v)
                else:
                    data[k] = v
    except Exception as e:
        sys.stderr.write(f"read_hypr_vars_file error: {e}\n")
    return data

def write_hypr_vars_file(data: dict):
    ensure_asura_dir()
    lines = ["-- Generated by Asura Settings", "return {"]
    for k, v in sorted(data.items()):
        if isinstance(v, bool):
            lines.append(f"    {k} = {'true' if v else 'false'},")
        elif isinstance(v, (int, float)):
            lines.append(f"    {k} = {v},")
        else:
            lines.append(f'    {k} = "{v}",')
    lines.append("}\n")
    tmp = HYPR_VARS_FILE + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    os.replace(tmp, HYPR_VARS_FILE)

def read_default_vars_file() -> dict:
    if not os.path.exists(DEFAULT_VARS_FILE):
        return {}
    data = {}
    try:
        with open(DEFAULT_VARS_FILE, "r", encoding="utf-8") as f:
            content = f.read()
        for line in content.splitlines():
            line = line.strip()
            if not line or line.startswith("--") or line.startswith("return") or line.startswith("{") or line.startswith("}"):
                continue
            m = re.match(r'([a-zA-Z0-9_]+)\s*=\s*(.+?)[,;]?$', line)
            if m:
                k = m.group(1).strip()
                v = m.group(2).strip()
                if (v.startswith('"') and v.endswith('"')) or (v.startswith("'") and v.endswith("'")):
                    data[k] = v[1:-1]
    except Exception as e:
        sys.stderr.write(f"read_default_vars_file error: {e}\n")
    return data

def read_config_json() -> dict:
    if os.path.exists(CONFIG_JSON_FILE):
        try:
            with open(CONFIG_JSON_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return {}

def write_config_json(updates: dict):
    ensure_asura_dir()
    data = read_config_json()
    data.update(updates)
    tmp = CONFIG_JSON_FILE + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4, ensure_ascii=False)
    os.replace(tmp, CONFIG_JSON_FILE)

def reload_hyprland():
    try:
        subprocess.run(["hyprctl", "reload"], capture_output=True, timeout=3)
    except Exception as e:
        sys.stderr.write(f"reload_hyprland error: {e}\n")

def normalize_chord(chord: str) -> str:
    if not chord:
        return ""
    parts = [p.strip().upper() for p in chord.replace("+", " ").split() if p.strip()]
    mods = []
    keys = []
    for p in parts:
        if p in ("SUPER", "SUPER_L", "SUPER_R", "WIN", "LOGO", "MOD4"):
            if "SUPER" not in mods:
                mods.append("SUPER")
        elif p in ("CTRL", "CONTROL", "LCTRL", "RCTRL"):
            if "CTRL" not in mods:
                mods.append("CTRL")
        elif p in ("ALT", "MOD1", "LALT", "RALT"):
            if "ALT" not in mods:
                mods.append("ALT")
        elif p in ("SHIFT", "LSHIFT", "RSHIFT"):
            if "SHIFT" not in mods:
                mods.append("SHIFT")
        else:
            keys.append(p)
    return " + ".join(mods + keys)

def update_hypr_user_custom_binds(custom_list: list):
    ensure_asura_dir()
    content = ""
    if os.path.exists(HYPR_USER_FILE):
        try:
            with open(HYPR_USER_FILE, "r", encoding="utf-8") as f:
                content = f.read()
        except Exception:
            content = ""

    tag_start = "-- [[ ASURA CUSTOM BINDS START ]]"
    tag_end = "-- [[ ASURA CUSTOM BINDS END ]]"

    lines = [tag_start]
    for b in custom_list:
        if not b.get("enabled", True):
            continue
        chord = b.get("chord", "").strip()
        action = b.get("action", "exec")
        val = b.get("value", "").strip()
        if not chord:
            continue
        if action == "exec":
            lines.append(f'hl.bind("{chord}", hl.dsp.exec_cmd("{val}"))')
        elif action == "close":
            lines.append(f'hl.bind("{chord}", hl.dsp.window.close())')
        elif action == "float":
            lines.append(f'hl.bind("{chord}", hl.dsp.window.float())')
        elif action == "fullscreen":
            lines.append(f'hl.bind("{chord}", hl.dsp.window.fullscreen({{ mode = "fullscreen" }}))')
    lines.append(tag_end)
    custom_block = "\n".join(lines)

    if tag_start in content and tag_end in content:
        pattern = re.compile(rf"{re.escape(tag_start)}.*?{re.escape(tag_end)}", re.DOTALL)
        content = pattern.sub(custom_block, content)
    else:
        if content.strip():
            content = content.rstrip() + "\n\n" + custom_block + "\n"
        else:
            content = custom_block + "\n"

    tmp = HYPR_USER_FILE + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(content)
    os.replace(tmp, HYPR_USER_FILE)

def cmd_get():
    overrides = read_hypr_vars_file()
    defaults = read_default_vars_file()
    cfg = read_config_json()
    custom_binds = cfg.get("customKeybinds", [])

    items_out = []
    used_chords = {}

    for item in SYSTEM_CATALOG:
        var_name = item.get("var")
        effective_chord = item["default"]
        is_overridden = False

        if var_name:
            if var_name in overrides:
                effective_chord = str(overrides[var_name])
                is_overridden = True
            elif var_name in defaults:
                effective_chord = str(defaults[var_name])

        suffix = item.get("suffix")
        if suffix:
            display_chord = f"{effective_chord} + {suffix}"
            default_chord = f"{item['default']} + {suffix}"
        elif var_name == "kbLauncher" and effective_chord in ("SUPER + SUPER_L", "SUPER"):
            display_chord = "SUPER"
            default_chord = "SUPER"
        else:
            display_chord = effective_chord
            default_chord = item["default"]

        norm = normalize_chord(display_chord)
        items_out.append({
            "id": item["id"],
            "category": item["category"],
            "label": item["label"],
            "hint": item["hint"],
            "default": default_chord,
            "chord": display_chord,
            "normalized": norm,
            "var": var_name,
            "suffix": suffix,
            "isOverridden": is_overridden,
            "isCustom": False
        })
        if norm:
            used_chords[norm] = used_chords.get(norm, 0) + 1

    custom_out = []
    for cb in custom_binds:
        norm = normalize_chord(cb.get("chord", ""))
        custom_out.append({
            "id": cb.get("id"),
            "category": "custom",
            "label": cb.get("label", "Custom Shortcut"),
            "hint": f"{cb.get('action', 'exec')}: {cb.get('value', '')}",
            "chord": cb.get("chord", ""),
            "normalized": norm,
            "action": cb.get("action", "exec"),
            "value": cb.get("value", ""),
            "enabled": cb.get("enabled", True),
            "isCustom": True
        })
        if norm and cb.get("enabled", True):
            used_chords[norm] = used_chords.get(norm, 0) + 1

    conflicts = [chord for chord, count in used_chords.items() if count > 1]

    payload = {
        "items": items_out,
        "custom": custom_out,
        "conflicts": conflicts,
        "totalCount": len(items_out) + len(custom_out),
        "conflictCount": len(conflicts)
    }
    print(json.dumps(payload, ensure_ascii=False))

def cmd_set_var(var_name: str, chord: str):
    overrides = read_hypr_vars_file()
    clean_chord = re.sub(r'\s*\+\s*(?:0-9|\[[0-9,\-]+\]|[0-9])$', '', chord, flags=re.IGNORECASE).strip()
    if var_name == "kbLauncher" and clean_chord.upper() == "SUPER":
        clean_chord = "SUPER + SUPER_L"
    overrides[var_name] = clean_chord if clean_chord else chord
    write_hypr_vars_file(overrides)
    reload_hyprland()
    print(json.dumps({"status": "ok", "var": var_name, "chord": overrides[var_name]}))

def cmd_reset_var(var_name: str):
    overrides = read_hypr_vars_file()
    if var_name in overrides:
        del overrides[var_name]
        write_hypr_vars_file(overrides)
        reload_hyprland()
    print(json.dumps({"status": "ok", "reset": var_name}))

def cmd_reset_all():
    overrides = read_hypr_vars_file()
    keys_to_remove = [k for k in overrides.keys() if k.startswith("kb")]
    for k in keys_to_remove:
        del overrides[k]
    write_hypr_vars_file(overrides)
    update_hypr_user_custom_binds([])
    write_config_json({"customKeybinds": []})
    reload_hyprland()
    print(json.dumps({"status": "ok", "resetCount": len(keys_to_remove)}))

def cmd_save_custom(json_str: str):
    try:
        custom_list = json.loads(json_str)
        write_config_json({"customKeybinds": custom_list})
        update_hypr_user_custom_binds(custom_list)
        reload_hyprland()
        print(json.dumps({"status": "ok", "count": len(custom_list)}))
    except Exception as e:
        print(json.dumps({"status": "error", "message": str(e)}))

def cmd_get_preset():
    overrides = read_hypr_vars_file()
    cfg = read_config_json()
    kb_vars = {k: v for k, v in overrides.items() if k.startswith("kb")}
    custom_binds = cfg.get("customKeybinds", [])
    if not isinstance(custom_binds, list):
        custom_binds = []
    print(json.dumps({
        "vars": kb_vars,
        "custom": custom_binds
    }, ensure_ascii=False))

def cmd_apply_preset(json_str: str):
    try:
        data = json.loads(json_str) if isinstance(json_str, str) else json_str
        if not isinstance(data, dict):
            data = {}
    except Exception as e:
        sys.stderr.write(f"cmd_apply_preset parse error: {e}\n")
        data = {}

    vars_data = data.get("vars", {})
    custom_data = data.get("custom", [])
    if not isinstance(vars_data, dict):
        vars_data = {}
    if not isinstance(custom_data, list):
        custom_data = []

    # Update hypr-vars.lua (strip stale kb* overrides, apply preset ones)
    overrides = read_hypr_vars_file()
    for k in list(overrides.keys()):
        if k.startswith("kb"):
            del overrides[k]
    for k, v in vars_data.items():
        if k.startswith("kb"):
            clean_chord = re.sub(r'\s*\+\s*(?:0-9|\[[0-9,\-]+\]|[0-9])$', '', str(v), flags=re.IGNORECASE).strip()
            if k == "kbLauncher" and clean_chord.upper() == "SUPER":
                clean_chord = "SUPER + SUPER_L"
            overrides[k] = clean_chord if clean_chord else v
    write_hypr_vars_file(overrides)

    # Update config.json and hypr-user.lua
    write_config_json({"customKeybinds": custom_data})
    update_hypr_user_custom_binds(custom_data)

    # Reload Hyprland
    reload_hyprland()
    print(json.dumps({"status": "ok", "applied": "shortcuts"}))

def main():
    if len(sys.argv) < 2:
        cmd_get()
        return

    action = sys.argv[1]
    if action == "get":
        cmd_get()
    elif action == "get_preset":
        cmd_get_preset()
    elif action == "apply_preset" and len(sys.argv) >= 3:
        cmd_apply_preset(sys.argv[2])
    elif action == "set_var" and len(sys.argv) >= 4:
        cmd_set_var(sys.argv[2], sys.argv[3])
    elif action == "reset_var" and len(sys.argv) >= 3:
        cmd_reset_var(sys.argv[2])
    elif action == "reset_all":
        cmd_reset_all()
    elif action == "save_custom" and len(sys.argv) >= 3:
        cmd_save_custom(sys.argv[2])
    else:
        print(json.dumps({"status": "error", "message": f"Unknown or invalid command: {action}"}))

if __name__ == "__main__":
    main()
