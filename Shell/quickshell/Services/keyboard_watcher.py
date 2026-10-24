#!/usr/bin/env python3
import os
import sys
import socket
import json
import time
import signal
import subprocess

def sig_handler(signum, frame):
    sys.exit(0)

signal.signal(signal.SIGINT, sig_handler)
signal.signal(signal.SIGTERM, sig_handler)

LAYOUT_MAP = {
    "portuguese (brazil)": "BR",
    "portuguese": "PT",
    "english (us)": "US",
    "english (uk)": "UK",
    "spanish": "ES",
    "french": "FR",
    "german": "DE",
    "italian": "IT",
    "russian": "RU",
    "japanese": "JA",
    "korean": "KO",
    "chinese": "ZH",
    "turkish": "TR",
    "swedish": "SE",
    "norwegian": "NO",
    "danish": "DK",
    "finnish": "FI",
    "polish": "PL",
    "ukrainian": "UA",
    "czech": "CZ",
    "greek": "GR",
    "hebrew": "IL",
    "arabic": "AR",
}

def derive_short(active_keymap, layout_str, active_index):
    # 1. From layout string list if active_index is valid
    if layout_str:
        parts = [p.strip() for p in layout_str.split(",") if p.strip()]
        if 0 <= active_index < len(parts):
            code = parts[active_index]
            clean_code = code.split("(")[0].strip().upper()
            if 1 <= len(clean_code) <= 3:
                return clean_code

    # 2. From known full keymap dictionary
    km_lower = (active_keymap or "").lower().strip()
    if km_lower in LAYOUT_MAP:
        return LAYOUT_MAP[km_lower]

    for k, v in LAYOUT_MAP.items():
        if k in km_lower:
            return v

    # 3. Extract inside parentheses if present (e.g. "English (US)" -> "US")
    if "(" in active_keymap and ")" in active_keymap:
        inside = active_keymap[active_keymap.find("(") + 1 : active_keymap.find(")")].strip().upper()
        if 2 <= len(inside) <= 3:
            return inside

    # 4. Fallback to first 2 letters
    if active_keymap and len(active_keymap.strip()) >= 2:
        return active_keymap.strip()[:2].upper()

    return "EN"

def get_keyboard_state():
    try:
        res = subprocess.run(["hyprctl", "devices", "-j"], capture_output=True, text=True, timeout=2)
        if res.returncode != 0 or not res.stdout.strip():
            return None
        data = json.loads(res.stdout)
        keyboards = data.get("keyboards", [])
        if not keyboards:
            return None

        # Prefer main keyboard, or first one with layout
        main_kb = next((k for k in keyboards if k.get("main")), None)
        if not main_kb:
            main_kb = next((k for k in keyboards if k.get("layout")), keyboards[0])

        active_keymap = main_kb.get("active_keymap", "")
        # Transient sentinel "ERROR" during transitions
        if active_keymap.lower() == "error":
            return None

        layout_str = main_kb.get("layout", "")
        active_index = main_kb.get("active_layout_index", 0)
        short = derive_short(active_keymap, layout_str, active_index)
        layouts = [p.strip() for p in layout_str.split(",") if p.strip()]

        return {
            "name": main_kb.get("name", ""),
            "layout": active_keymap,
            "short": short,
            "layouts": layouts,
            "index": active_index
        }
    except Exception:
        return None

def main():
    his = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
    xdg = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
    sock_path = f"{xdg}/hypr/{his}/.socket2.sock"

    last_state = None

    # Emit initial state immediately
    init_state = get_keyboard_state()
    if init_state:
        last_state = init_state
        sys.stdout.write(json.dumps(init_state) + "\n")
        sys.stdout.flush()

    while True:
        if not os.path.exists(sock_path):
            time.sleep(1)
            continue
        try:
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.connect(sock_path)
            buf = ""
            while True:
                chunk = s.recv(4096).decode("utf-8", errors="ignore")
                if not chunk:
                    break
                buf += chunk
                had_layout_event = False
                while "\n" in buf:
                    line, buf = buf.split("\n", 1)
                    line = line.strip()
                    if line.startswith("activelayout>>") or line.startswith("configreloaded>>"):
                        had_layout_event = True
                if had_layout_event:
                    st = get_keyboard_state()
                    if st and st != last_state:
                        last_state = st
                        sys.stdout.write(json.dumps(st) + "\n")
                        sys.stdout.flush()
            s.close()
        except Exception:
            time.sleep(1)

if __name__ == "__main__":
    main()
