#!/usr/bin/env python3
import sys
import os
import re
import glob
import subprocess
import json
import shutil

ASURA_DIR = os.path.expanduser("~/.config/asura")
HYPR_VARS_FILE = os.path.join(ASURA_DIR, "hypr-vars.lua")
HYPR_DEFAULT_VARS_FILE = os.path.expanduser("~/.config/hypr/variables.lua")
CONFIG_FILE = os.path.join(ASURA_DIR, "config.json")

# Metadata mapping categories to Hyprland variables and defaults
APP_CATEGORIES = {
    "fileExplorer": {
        "title": "File Manager",
        "desc": "System file browser and directory navigator",
        "icon": "folder",
        "hyprVar": "fileExplorer",
        "keybind": "SUPER + E",
        "default": "nautilus",
        "mime": ["inode/directory"],
        "known": [
            {"id": "nautilus", "name": "Nautilus (GNOME Files)", "cmd": "nautilus", "desktop": "org.gnome.Nautilus.desktop", "icon": "system-file-manager"},
            {"id": "nemo", "name": "Nemo (Cinnamon Files)", "cmd": "nemo", "desktop": "nemo.desktop", "icon": "system-file-manager"},
            {"id": "dolphin", "name": "Dolphin (KDE)", "cmd": "dolphin", "desktop": "org.kde.dolphin.desktop", "icon": "system-file-manager"},
            {"id": "thunar", "name": "Thunar (XFCE)", "cmd": "thunar", "desktop": "thunar.desktop", "icon": "system-file-manager"},
            {"id": "pcmanfm", "name": "PCManFM", "cmd": "pcmanfm", "desktop": "pcmanfm.desktop", "icon": "system-file-manager"},
            {"id": "yazi", "name": "Yazi (Terminal FM)", "cmd": "kitty -e yazi", "desktop": "yazi.desktop", "icon": "terminal"},
            {"id": "ranger", "name": "Ranger (Terminal FM)", "cmd": "kitty -e ranger", "desktop": "ranger.desktop", "icon": "terminal"}
        ]
    },
    "terminal": {
        "title": "Terminal Emulator",
        "desc": "Primary command line and shell environment",
        "icon": "terminal",
        "hyprVar": "terminal",
        "keybind": "SUPER + T / SUPER + Enter",
        "default": "kitty",
        "mime": [],
        "known": [
            {"id": "kitty", "name": "Kitty", "cmd": "kitty", "desktop": "kitty.desktop", "icon": "kitty"},
            {"id": "alacritty", "name": "Alacritty", "cmd": "alacritty", "desktop": "Alacritty.desktop", "icon": "Alacritty"},
            {"id": "ghostty", "name": "Ghostty", "cmd": "ghostty", "desktop": "ghostty.desktop", "icon": "ghostty"},
            {"id": "foot", "name": "Foot", "cmd": "foot", "desktop": "foot.desktop", "icon": "foot"},
            {"id": "wezterm", "name": "WezTerm", "cmd": "wezterm", "desktop": "org.wezfurlong.wezterm.desktop", "icon": "wezterm"},
            {"id": "konsole", "name": "Konsole", "cmd": "konsole", "desktop": "org.kde.konsole.desktop", "icon": "konsole"},
            {"id": "gnome-terminal", "name": "GNOME Terminal", "cmd": "gnome-terminal", "desktop": "org.gnome.Terminal.desktop", "icon": "gnome-terminal"}
        ]
    },
    "browser": {
        "title": "Web Browser",
        "desc": "Internet browser for web pages and HTTP URLs",
        "icon": "language",
        "hyprVar": "browser",
        "keybind": "SUPER + B",
        "default": "vivaldi",
        "mime": ["x-scheme-handler/http", "x-scheme-handler/https", "text/html"],
        "known": [
            {"id": "vivaldi", "name": "Vivaldi", "cmd": "vivaldi", "desktop": "vivaldi-stable.desktop", "icon": "vivaldi"},
            {"id": "firefox", "name": "Firefox", "cmd": "firefox", "desktop": "firefox.desktop", "icon": "firefox"},
            {"id": "brave", "name": "Brave", "cmd": "brave", "desktop": "brave-browser.desktop", "icon": "brave-desktop"},
            {"id": "chromium", "name": "Chromium", "cmd": "chromium", "desktop": "chromium.desktop", "icon": "chromium"},
            {"id": "google-chrome", "name": "Google Chrome", "cmd": "google-chrome-stable", "desktop": "google-chrome.desktop", "icon": "google-chrome"},
            {"id": "zen-browser", "name": "Zen Browser", "cmd": "zen-browser", "desktop": "zen.desktop", "icon": "zen-browser"},
            {"id": "microsoft-edge", "name": "Microsoft Edge", "cmd": "microsoft-edge-stable", "desktop": "microsoft-edge.desktop", "icon": "microsoft-edge"}
        ]
    },
    "editor": {
        "title": "Text Editor / IDE",
        "desc": "Source code editor and plain text tool",
        "icon": "edit_note",
        "hyprVar": "editor",
        "keybind": "SUPER + C",
        "default": "code",
        "mime": ["text/plain"],
        "known": [
            {"id": "code", "name": "Visual Studio Code", "cmd": "code", "desktop": "code.desktop", "icon": "vscode"},
            {"id": "codium", "name": "VSCodium", "cmd": "codium", "desktop": "vscodium.desktop", "icon": "vscodium"},
            {"id": "nvim", "name": "Neovim", "cmd": "kitty -e nvim", "desktop": "nvim.desktop", "icon": "nvim"},
            {"id": "vim", "name": "Vim", "cmd": "vim", "desktop": "vim.desktop", "icon": "gvim"},
            {"id": "micro", "name": "Micro", "cmd": "micro", "desktop": "micro.desktop", "icon": "micro"},
            {"id": "nano", "name": "Nano", "cmd": "kitty -e nano", "desktop": "nano.desktop", "icon": "nano"},
            {"id": "kate", "name": "Kate", "cmd": "kate", "desktop": "org.kde.kate.desktop", "icon": "kate"},
            {"id": "subl", "name": "Sublime Text", "cmd": "subl", "desktop": "sublime_text.desktop", "icon": "sublime-text"},
            {"id": "zed", "name": "Zed", "cmd": "zed", "desktop": "dev.zed.Zed.desktop", "icon": "zed"}
        ]
    },
    "audioSettings": {
        "title": "Audio Control",
        "desc": "Volume mixer and sound device management",
        "icon": "volume_up",
        "hyprVar": "audioSettings",
        "keybind": "CTRL + ALT + V",
        "default": "pavucontrol",
        "mime": [],
        "known": [
            {"id": "pavucontrol", "name": "Volume Control (Pavucontrol)", "cmd": "pavucontrol", "desktop": "org.pulseaudio.pavucontrol.desktop", "icon": "org.pulseaudio.pavucontrol"},
            {"id": "qpwgraph", "name": "PipeWire Graph (qpwgraph)", "cmd": "qpwgraph", "desktop": "org.rncbc.qpwgraph.desktop", "icon": "org.rncbc.qpwgraph"},
            {"id": "helvum", "name": "Helvum (Patchbay)", "cmd": "helvum", "desktop": "org.pipewire.Helvum.desktop", "icon": "helvum"},
            {"id": "alsamixer", "name": "Alsamixer", "cmd": "kitty -e alsamixer", "desktop": "alsamixer.desktop", "icon": "audio-volume-high"}
        ]
    },
    "mediaPlayer": {
        "title": "Media Player",
        "desc": "Video and audio player for multimedia files",
        "icon": "movie",
        "hyprVar": "mediaPlayer",
        "keybind": "Media / Files",
        "default": "vlc",
        "mime": ["video/mp4", "video/mkv", "video/webm", "audio/mpeg"],
        "known": [
            {"id": "vlc", "name": "VLC Media Player", "cmd": "vlc", "desktop": "vlc.desktop", "icon": "vlc"},
            {"id": "mpv", "name": "MPV Player", "cmd": "mpv", "desktop": "mpv.desktop", "icon": "mpv"},
            {"id": "clapper", "name": "Clapper", "cmd": "clapper", "desktop": "com.github.rafostar.Clapper.desktop", "icon": "clapper"},
            {"id": "celluloid", "name": "Celluloid", "cmd": "celluloid", "desktop": "io.github.celluloid_player.Celluloid.desktop", "icon": "celluloid"},
            {"id": "totem", "name": "Videos (Totem)", "cmd": "totem", "desktop": "org.gnome.Totem.desktop", "icon": "totem"}
        ]
    },
    "imageViewer": {
        "title": "Image Viewer",
        "desc": "Picture viewer for wallpapers and graphics",
        "icon": "image",
        "hyprVar": "imageViewer",
        "keybind": "Images",
        "default": "loupe",
        "mime": ["image/png", "image/jpeg", "image/webp"],
        "known": [
            {"id": "loupe", "name": "Loupe (GNOME Image Viewer)", "cmd": "loupe", "desktop": "org.gnome.Loupe.desktop", "icon": "org.gnome.Loupe"},
            {"id": "eog", "name": "Eye of GNOME (eog)", "cmd": "eog", "desktop": "eog.desktop", "icon": "eog"},
            {"id": "imv", "name": "imv (Wayland Image Viewer)", "cmd": "imv", "desktop": "imv.desktop", "icon": "imv"},
            {"id": "viewnior", "name": "Viewnior", "cmd": "viewnior", "desktop": "viewnior.desktop", "icon": "viewnior"},
            {"id": "feh", "name": "feh", "cmd": "feh", "desktop": "feh.desktop", "icon": "feh"},
            {"id": "gwenview", "name": "Gwenview", "cmd": "gwenview", "desktop": "org.kde.gwenview.desktop", "icon": "gwenview"}
        ]
    }
}

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
                if v == "true":
                    data[k] = True
                elif v == "false":
                    data[k] = False
                elif re.match(r'^-?\d+$', v):
                    data[k] = int(v)
                elif re.match(r'^-?\d+\.\d+$', v):
                    data[k] = float(v)
                elif (v.startswith('"') and v.endswith('"')) or (v.startswith("'") and v.endswith("'")):
                    data[k] = v[1:-1]
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
            v_str = "true" if v else "false"
        elif isinstance(v, (int, float)):
            v_str = str(v)
        elif isinstance(v, str):
            v_str = f'"{v}"'
        else:
            v_str = f'"{v}"'
        lines.append(f"    {k} = {v_str},")
    lines.append("}\n")
    content = "\n".join(lines)
    tmp_path = HYPR_VARS_FILE + ".tmp"
    with open(tmp_path, "w", encoding="utf-8") as f:
        f.write(content)
    os.replace(tmp_path, HYPR_VARS_FILE)

def read_hypr_default_vars() -> dict:
    if not os.path.exists(HYPR_DEFAULT_VARS_FILE):
        return {}
    data = {}
    try:
        with open(HYPR_DEFAULT_VARS_FILE, "r", encoding="utf-8") as f:
            for line in f.read().splitlines():
                m = re.match(r'^\s*([a-zA-Z0-9_]+)\s*=\s*["\']([^"\']+)["\']', line)
                if m:
                    data[m.group(1)] = m.group(2)
    except Exception:
        pass
    return data

def is_cmd_available(cmd_name: str) -> bool:
    if not cmd_name:
        return False
    first = cmd_name.strip().split()[0]
    return shutil.which(first) is not None

def get_installed_desktop_apps():
    """Scan standard desktop entry directories for installed apps."""
    dirs = [
        os.path.expanduser("~/.local/share/applications"),
        "/usr/local/share/applications",
        "/usr/share/applications"
    ]
    seen_execs = set()
    apps = []

    for d in dirs:
        if not os.path.isdir(d):
            continue
        for f in sorted(glob.glob(os.path.join(d, "*.desktop"))):
            desktop_id = os.path.basename(f)
            try:
                with open(f, "r", encoding="utf-8", errors="ignore") as fh:
                    content = fh.read()
                name, exec_cmd, icon, nodisplay = "", "", "", False
                for line in content.splitlines():
                    if line.startswith("Name=") and not name:
                        name = line[5:].strip()
                    elif line.startswith("Exec=") and not exec_cmd:
                        raw_exec = line[5:].strip()
                        # Strip field codes like %U, %F, %f, etc.
                        exec_cmd = re.sub(r'%[a-zA-Z]', '', raw_exec).strip()
                    elif line.startswith("Icon=") and not icon:
                        icon = line[5:].strip()
                    elif line.startswith("NoDisplay=true"):
                        nodisplay = True

                if exec_cmd and not nodisplay:
                    base_binary = exec_cmd.split()[0]
                    if base_binary not in seen_execs and is_cmd_available(base_binary):
                        seen_execs.add(base_binary)
                        apps.append({
                            "desktop": desktop_id,
                            "name": name or base_binary,
                            "cmd": base_binary,
                            "icon": icon or "application-x-executable"
                        })
            except Exception:
                pass
    return apps

def get_all_settings():
    hypr_vars = read_hypr_vars_file()
    hypr_defaults = read_hypr_default_vars()
    desktop_apps = get_installed_desktop_apps()

    # Determine active value for each category
    current_apps = {}
    categories_result = []

    for cat_key, meta in APP_CATEGORIES.items():
        var_name = meta["hyprVar"]
        active_val = hypr_vars.get(var_name) or hypr_defaults.get(var_name) or meta["default"]
        current_apps[cat_key] = active_val

        # Collect installed options for this category
        detected_options = []
        added_cmds = set()
        added_names = set()

        # 1. Check known candidates
        for k in meta["known"]:
            cmd_root = k["cmd"].split()[0]
            if is_cmd_available(cmd_root):
                base_bin = os.path.basename(cmd_root)
                if base_bin not in added_cmds:
                    detected_options.append({
                        "id": k["id"],
                        "name": k["name"],
                        "cmd": k["cmd"],
                        "desktop": k.get("desktop", ""),
                        "icon": k.get("icon", "application-x-executable"),
                        "isKnown": True
                    })
                    added_cmds.add(k["cmd"])
                    added_cmds.add(cmd_root)
                    added_cmds.add(base_bin)
                    added_cmds.add(k["id"].lower())
                    added_names.add(k["name"].lower())

        # 2. Match desktop apps if active command or related
        EXCLUDED_KEYWORDS = [
            "avahi", "zeroconf", "ssh server", "vnc server", "jconsole", "openjdk",
            "dbus", "kernel", "schedext", "scx-manager", "virt-manager", "qdbusviewer",
            "qv4l2", "qvidcap", "remote viewer", "autorun", "prompt"
        ]

        for da in desktop_apps:
            cmd_root = da["cmd"].split()[0]
            base_bin = os.path.basename(cmd_root)
            name_lower = da["name"].lower()
            if base_bin not in added_cmds and name_lower not in added_names:
                c_lower = da["cmd"].lower()
                d_lower = da.get("desktop", "").lower()

                if any(ex in c_lower or ex in name_lower or ex in d_lower for ex in EXCLUDED_KEYWORDS):
                    continue

                matched = False
                if cat_key == "browser" and any(x in c_lower or x in name_lower for x in ["browser", "chrome", "firefox", "vivaldi", "brave", "chromium"]):
                    matched = True
                elif cat_key == "terminal" and any(x in c_lower or x in name_lower for x in ["term", "kitty", "alacritty", "ghostty", "foot"]):
                    matched = True
                elif cat_key == "fileExplorer" and any(x in c_lower or x in name_lower for x in ["nautilus", "nemo", "thunar", "dolphin", "pcmanfm", "yazi", "ranger"]):
                    matched = True
                elif cat_key == "editor" and any(x in c_lower or x in name_lower for x in ["code", "codium", "editor", "nvim", "vim", "micro", "nano", "zed"]):
                    matched = True
                elif cat_key == "audioSettings" and any(x in c_lower or x in name_lower for x in ["volume", "audio", "mixer", "pulse", "pavucontrol", "qpwgraph", "helvum"]):
                    matched = True
                elif cat_key == "mediaPlayer" and any(x in c_lower or x in name_lower for x in ["vlc", "mpv", "celluloid", "clapper", "totem"]):
                    matched = True
                elif cat_key == "imageViewer" and any(x in c_lower or x in name_lower for x in ["loupe", "eog", "imv", "viewnior", "feh", "gwenview", "gthumb"]):
                    matched = True

                if matched:
                    detected_options.append({
                        "id": da["cmd"],
                        "name": da["name"],
                        "cmd": da["cmd"],
                        "desktop": da["desktop"],
                        "icon": da["icon"],
                        "isKnown": False
                    })
                    added_cmds.add(da["cmd"])
                    added_cmds.add(cmd_root)
                    added_cmds.add(base_bin)
                    added_names.add(name_lower)

        categories_result.append({
            "key": cat_key,
            "hyprVar": meta["hyprVar"],
            "title": meta["title"],
            "desc": meta["desc"],
            "icon": meta["icon"],
            "keybind": meta["keybind"],
            "current": active_val,
            "options": detected_options
        })

    return {
        "current": current_apps,
        "categories": categories_result
    }

def apply_settings(payload: dict):
    if not isinstance(payload, dict):
        return {"status": "error", "message": "Invalid payload format"}

    ensure_asura_dir()
    hypr_vars = read_hypr_vars_file()

    # Update app variables in hypr-vars.lua
    applied_count = 0
    for cat_key, meta in APP_CATEGORIES.items():
        var_name = meta["hyprVar"]
        if cat_key in payload:
            val = str(payload[cat_key]).strip()
            if val:
                hypr_vars[var_name] = val
                applied_count += 1
        elif var_name in payload:
            val = str(payload[var_name]).strip()
            if val:
                hypr_vars[var_name] = val
                applied_count += 1

    write_hypr_vars_file(hypr_vars)

    # Also update config.json with defaultApps
    try:
        cfg_data = {}
        if os.path.exists(CONFIG_FILE):
            with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                cfg_data = json.load(f)
        if "defaultApps" not in cfg_data or not isinstance(cfg_data["defaultApps"], dict):
            cfg_data["defaultApps"] = {}
        for cat_key in APP_CATEGORIES:
            var_name = APP_CATEGORIES[cat_key]["hyprVar"]
            if var_name in hypr_vars:
                cfg_data["defaultApps"][cat_key] = hypr_vars[var_name]
        with open(CONFIG_FILE + ".tmp", "w", encoding="utf-8") as f:
            json.dump(cfg_data, f, indent=4, ensure_ascii=False)
        os.replace(CONFIG_FILE + ".tmp", CONFIG_FILE)
    except Exception as e:
        sys.stderr.write(f"config.json write error: {e}\n")

    # Reload Hyprland to instantly refresh keybindings
    hypr_reloaded = False
    try:
        res = subprocess.run(["hyprctl", "reload"], capture_output=True, text=True, timeout=3)
        hypr_reloaded = (res.returncode == 0)
    except Exception as e:
        sys.stderr.write(f"hyprctl reload error: {e}\n")

    # Update XDG MIME associations where relevant
    desktop_apps = get_installed_desktop_apps()
    for cat_key, meta in APP_CATEGORIES.items():
        chosen_cmd = payload.get(cat_key) or payload.get(meta["hyprVar"])
        if not chosen_cmd or not meta.get("mime"):
            continue

        base_bin = chosen_cmd.split()[0]
        matched_desktop = ""
        # Find desktop file
        for k in meta["known"]:
            if k["cmd"].split()[0] == base_bin and k.get("desktop"):
                matched_desktop = k["desktop"]
                break
        if not matched_desktop:
            for da in desktop_apps:
                if da["cmd"] == base_bin and da.get("desktop"):
                    matched_desktop = da["desktop"]
                    break

        if matched_desktop:
            for m in meta["mime"]:
                try:
                    subprocess.run(["xdg-mime", "default", matched_desktop, m], capture_output=True, timeout=2)
                except Exception:
                    pass
            if cat_key == "browser":
                try:
                    subprocess.run(["xdg-settings", "set", "default-web-browser", matched_desktop], capture_output=True, timeout=2)
                except Exception:
                    pass

    return {
        "status": "ok",
        "appliedCount": applied_count,
        "hyprReloaded": hypr_reloaded,
        "current": hypr_vars
    }

def launch_command(cmd: str):
    if not cmd or not cmd.strip():
        return {"status": "error", "message": "Empty command"}
    try:
        # Launch detached process
        subprocess.Popen(cmd.strip(), shell=True, start_new_session=True)
        return {"status": "ok", "launched": cmd.strip()}
    except Exception as e:
        return {"status": "error", "message": str(e)}

def main():
    if len(sys.argv) < 2:
        print(json.dumps(get_all_settings(), indent=2))
        return

    cmd = sys.argv[1]
    if cmd == "get":
        print(json.dumps(get_all_settings()))
    elif cmd == "apply":
        payload_str = sys.argv[2] if len(sys.argv) > 2 else "{}"
        try:
            payload = json.loads(payload_str)
        except Exception:
            payload = {}
        print(json.dumps(apply_settings(payload)))
    elif cmd == "launch":
        to_run = sys.argv[2] if len(sys.argv) > 2 else ""
        print(json.dumps(launch_command(to_run)))
    else:
        sys.stderr.write(f"Unknown command {cmd}\n")
        sys.exit(1)

if __name__ == "__main__":
    main()
