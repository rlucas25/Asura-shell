#!/usr/bin/env python3
import sys
import os
import re
import subprocess
import json

ASURA_DIR = os.path.expanduser("~/.config/asura")
HYPR_USER_FILE = os.path.join(ASURA_DIR, "hypr-user.lua")
CONFIG_JSON_FILE = os.path.join(ASURA_DIR, "config.json")
LAYOUTS_JSON_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "keyboard_layouts.json")

def ensure_asura_dir():
    if not os.path.exists(ASURA_DIR):
        os.makedirs(ASURA_DIR, exist_ok=True)

def get_hypr_option(name: str):
    try:
        res = subprocess.run(["hyprctl", "getoption", name, "-j"], capture_output=True, text=True, timeout=2)
        if res.returncode == 0:
            return json.loads(res.stdout)
    except Exception:
        pass
    return None

def load_layouts_catalog():
    if os.path.exists(LAYOUTS_JSON_FILE):
        try:
            with open(LAYOUTS_JSON_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return []

def read_config_json():
    if os.path.exists(CONFIG_JSON_FILE):
        try:
            with open(CONFIG_JSON_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return {}

def write_config_json(updates: dict):
    data = read_config_json()
    data.update(updates)
    tmp_path = CONFIG_JSON_FILE + ".tmp"
    with open(tmp_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4, ensure_ascii=False)
    os.replace(tmp_path, CONFIG_JSON_FILE)

def parse_hypr_user_blocks() -> dict:
    blocks = {}
    if not os.path.exists(HYPR_USER_FILE):
        return blocks
    try:
        with open(HYPR_USER_FILE, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception:
        return blocks

    m = re.search(r"hl\.config\s*\(\s*\{", content)
    if not m:
        return blocks
    start = m.end()
    i = start
    n = len(content)
    in_str = None
    escape = False

    while i < n:
        c = content[i]
        if escape:
            escape = False
            i += 1
            continue
        if in_str:
            if c == "\\":
                escape = True
            elif c == in_str:
                in_str = None
            i += 1
            continue
        if c in ("\"", "'"):
            in_str = c
            i += 1
            continue
        if c == "-" and i + 1 < n and content[i + 1] == "-":
            eol = content.find("\n", i)
            if eol == -1:
                break
            i = eol + 1
            continue
        if c == "}" and i + 1 < n and content[i + 1] == ")":
            break

        key_match = re.match(r"([a-zA-Z0-9_]+)\s*=\s*\{", content[i:])
        if key_match:
            key_name = key_match.group(1)
            block_start = i
            line_start = content.rfind("\n", 0, block_start) + 1
            base_indent = block_start - line_start
            brace_pos = i + key_match.end() - 1
            depth = 0
            j = brace_pos
            inner_str = None
            inner_escape = False
            found_end = False

            while j < n:
                jc = content[j]
                if inner_escape:
                    inner_escape = False
                    j += 1
                    continue
                if inner_str:
                    if jc == "\\":
                        inner_escape = True
                    elif jc == inner_str:
                        inner_str = None
                    j += 1
                    continue
                if jc in ("\"", "'"):
                    inner_str = jc
                    j += 1
                    continue
                if jc == "-" and j + 1 < n and content[j + 1] == "-":
                    eol = content.find("\n", j)
                    if eol == -1:
                        break
                    j = eol + 1
                    continue
                if jc == "}" and j + 1 < n and content[j + 1] == ")":
                    break
                if jc == "{":
                    depth += 1
                elif jc == "}":
                    depth -= 1
                    if depth == 0:
                        raw_block = content[block_start:j + 1].strip()
                        lines = raw_block.splitlines()
                        norm_lines = []
                        for l in lines:
                            if l.startswith(" " * base_indent):
                                norm_lines.append(l[base_indent:])
                            else:
                                norm_lines.append(l.lstrip())
                        blocks[key_name] = "\n".join(norm_lines)
                        found_end = True
                        i = j + 1
                        break
                j += 1

            if not found_end:
                raw_block = content[block_start:j].strip()
                lines = raw_block.splitlines()
                norm_lines = []
                for l in lines:
                    if l.startswith(" " * base_indent):
                        norm_lines.append(l[base_indent:])
                    else:
                        norm_lines.append(l.lstrip())
                for _ in range(depth):
                    norm_lines.append("}")
                blocks[key_name] = "\n".join(norm_lines)
                i = j
                continue

        i += 1

    return blocks

def write_hypr_user_blocks(blocks: dict):
    ensure_asura_dir()
    preferred = ["general", "dwindle", "input", "cursor"]
    keys = [k for k in preferred if k in blocks]
    for k in blocks:
        if k not in keys:
            keys.append(k)

    chunks = []
    for k in keys:
        lines = blocks[k].strip().splitlines()
        indented = ["    " + l if l.strip() else "" for l in lines]
        chunks.append("\n".join(indented))

    content = "hl.config({\n" + ",\n".join(chunks) + "\n})\n"
    tmp_path = HYPR_USER_FILE + ".tmp"
    with open(tmp_path, "w", encoding="utf-8") as f:
        f.write(content)
    os.replace(tmp_path, HYPR_USER_FILE)

def write_hypr_user_file_input(
    layouts_str: str,
    kb_options: str,
    numlock: bool = False,
    repeat_rate: int = 35,
    repeat_delay: int = 250,
    sensitivity: float = 0.0,
    accel_profile: str = "",
    natural_scroll: bool = False,
    left_handed: bool = False,
    scroll_factor: float = 1.0,
    follow_mouse: int = 1,
    tp_natural_scroll: bool = True,
    tp_disable_typing: bool = True,
    tp_tap_to_click: bool = True,
    tp_scroll_factor: float = 0.5,
    no_warps: bool = False
):
    blocks = parse_hypr_user_blocks()
    if "general" not in blocks:
        blocks["general"] = """general = {
    layout = "dwindle"
}"""
    if "dwindle" not in blocks:
        blocks["dwindle"] = """dwindle = {
    smart_split = true
}"""

    numlock_str = "true" if numlock else "false"
    nat_scroll_str = "true" if natural_scroll else "false"
    left_handed_str = "true" if left_handed else "false"
    tp_nat_scroll_str = "true" if tp_natural_scroll else "false"
    tp_dwt_str = "true" if tp_disable_typing else "false"
    tp_ttc_str = "true" if tp_tap_to_click else "false"
    no_warps_str = "true" if no_warps else "false"

    accel_line = f'\n    accel_profile = "{accel_profile}",' if accel_profile in ("adaptive", "flat", "custom") else ""

    blocks["input"] = f"""input = {{
    kb_layout = "{layouts_str}",
    kb_options = "{kb_options}",
    numlock_by_default = {numlock_str},
    repeat_rate = {repeat_rate},
    repeat_delay = {repeat_delay},
    sensitivity = {sensitivity},{accel_line}
    natural_scroll = {nat_scroll_str},
    left_handed = {left_handed_str},
    scroll_factor = {scroll_factor},
    follow_mouse = {follow_mouse},
    touchpad = {{
        natural_scroll = {tp_nat_scroll_str},
        disable_while_typing = {tp_dwt_str},
        tap_to_click = {tp_ttc_str},
        scroll_factor = {tp_scroll_factor}
    }}
}}"""
    blocks["cursor"] = f"""cursor = {{
    no_warps = {no_warps_str}
}}"""
    write_hypr_user_blocks(blocks)

def get_settings():
    catalog = load_layouts_catalog()
    cfg = read_config_json()

    # Query hyprctl options
    kb_layout_opt = get_hypr_option("input:kb_layout")
    kb_options_opt = get_hypr_option("input:kb_options")
    numlock_opt = get_hypr_option("input:numlock_by_default")
    rate_opt = get_hypr_option("input:repeat_rate")
    delay_opt = get_hypr_option("input:repeat_delay")

    sens_opt = get_hypr_option("input:sensitivity")
    accel_opt = get_hypr_option("input:accel_profile")
    nat_scroll_opt = get_hypr_option("input:natural_scroll")
    left_hand_opt = get_hypr_option("input:left_handed")
    scroll_factor_opt = get_hypr_option("input:scroll_factor")
    follow_mouse_opt = get_hypr_option("input:follow_mouse")

    tp_nat_scroll_opt = get_hypr_option("input:touchpad:natural_scroll")
    tp_dwt_opt = get_hypr_option("input:touchpad:disable_while_typing")
    tp_ttc_opt = get_hypr_option("input:touchpad:tap-to-click")
    tp_scroll_factor_opt = get_hypr_option("input:touchpad:scroll_factor")
    no_warps_opt = get_hypr_option("cursor:no_warps")

    raw_layout_str = (kb_layout_opt.get("str") if kb_layout_opt else "") or ""
    if not raw_layout_str and "keyboardLayouts" in cfg and isinstance(cfg["keyboardLayouts"], list):
        layouts = cfg["keyboardLayouts"]
    else:
        layouts = [p.strip() for p in raw_layout_str.split(",") if p.strip()]

    if not layouts:
        layouts = ["br", "us"]

    kb_options = (kb_options_opt.get("str") if kb_options_opt else "") or cfg.get("keyboardSwitchOption", "grp:win_space_toggle")
    numlock = (numlock_opt.get("bool") if numlock_opt else False) if numlock_opt else cfg.get("keyboardNumlockByDefault", False)
    repeat_rate = (rate_opt.get("int") if rate_opt else 35) or 35
    repeat_delay = (delay_opt.get("int") if delay_opt else 250) or 250

    # Mouse & Touchpad properties
    sensitivity = float(cfg.get("mouseSensitivity", sens_opt.get("float", 0.0) if sens_opt else 0.0))
    raw_accel = accel_opt.get("str", "") if accel_opt else ""
    if raw_accel == "[[EMPTY]]":
        raw_accel = ""
    accel_profile = str(cfg.get("mouseAccelProfile", raw_accel))
    natural_scroll = bool(cfg.get("mouseNaturalScroll", nat_scroll_opt.get("bool", False) if nat_scroll_opt else False))
    left_handed = bool(cfg.get("mouseLeftHanded", left_hand_opt.get("bool", False) if left_hand_opt else False))
    scroll_factor = float(cfg.get("mouseScrollFactor", scroll_factor_opt.get("float", 1.0) if scroll_factor_opt else 1.0))
    follow_mouse = int(cfg.get("mouseFollowFocus", follow_mouse_opt.get("int", 1) if follow_mouse_opt else 1))

    tp_natural_scroll = bool(cfg.get("touchpadNaturalScroll", tp_nat_scroll_opt.get("bool", True) if tp_nat_scroll_opt else True))
    tp_disable_typing = bool(cfg.get("touchpadDisableWhileTyping", tp_dwt_opt.get("bool", True) if tp_dwt_opt else True))
    tp_tap_to_click = bool(cfg.get("touchpadTapToClick", tp_ttc_opt.get("bool", True) if tp_ttc_opt else True))
    tp_scroll_factor = float(cfg.get("touchpadScrollFactor", tp_scroll_factor_opt.get("float", 0.5) if tp_scroll_factor_opt else 0.5))
    no_warps = bool(cfg.get("cursorNoWarps", no_warps_opt.get("bool", False) if no_warps_opt else False))

    out = {
        "layouts": layouts,
        "primaryLayout": layouts[0] if layouts else "br",
        "kbOptions": kb_options,
        "numlockByDefault": bool(numlock),
        "repeatRate": repeat_rate,
        "repeatDelay": repeat_delay,
        "mouseSensitivity": round(sensitivity, 2),
        "mouseAccelProfile": accel_profile,
        "mouseNaturalScroll": natural_scroll,
        "mouseLeftHanded": left_handed,
        "mouseScrollFactor": round(scroll_factor, 1),
        "mouseFollowFocus": follow_mouse,
        "touchpadNaturalScroll": tp_natural_scroll,
        "touchpadDisableWhileTyping": tp_disable_typing,
        "touchpadTapToClick": tp_tap_to_click,
        "touchpadScrollFactor": round(tp_scroll_factor, 1),
        "cursorNoWarps": no_warps,
        "allAvailableLayouts": catalog
    }
    print(json.dumps(out))

def apply_settings(payload_str: str):
    try:
        data = json.loads(payload_str)
    except Exception as e:
        sys.stderr.write(f"Failed to parse JSON payload: {e}\n")
        print(json.dumps({"status": "error", "message": str(e)}))
        return

    layouts = data.get("layouts", ["br", "us"])
    if not layouts:
        layouts = ["us"]

    layouts_str = ",".join(layouts)
    kb_options = data.get("kbOptions", "grp:win_space_toggle")
    numlock = bool(data.get("numlockByDefault", False))
    repeat_rate = int(data.get("repeatRate", 35))
    repeat_delay = int(data.get("repeatDelay", 250))
    numlock_str = "true" if numlock else "false"

    # Mouse & Touchpad properties
    sensitivity = round(float(data.get("mouseSensitivity", 0.0)), 2)
    accel_profile = str(data.get("mouseAccelProfile", ""))
    natural_scroll = bool(data.get("mouseNaturalScroll", False))
    left_handed = bool(data.get("mouseLeftHanded", False))
    scroll_factor = round(float(data.get("mouseScrollFactor", 1.0)), 1)
    follow_mouse = int(data.get("mouseFollowFocus", 1))

    tp_natural_scroll = bool(data.get("touchpadNaturalScroll", True))
    tp_disable_typing = bool(data.get("touchpadDisableWhileTyping", True))
    tp_tap_to_click = bool(data.get("touchpadTapToClick", True))
    tp_scroll_factor = round(float(data.get("touchpadScrollFactor", 0.5)), 1)
    no_warps = bool(data.get("cursorNoWarps", False))

    nat_scroll_str = "true" if natural_scroll else "false"
    left_handed_str = "true" if left_handed else "false"
    tp_nat_scroll_str = "true" if tp_natural_scroll else "false"
    tp_dwt_str = "true" if tp_disable_typing else "false"
    tp_ttc_str = "true" if tp_tap_to_click else "false"
    no_warps_str = "true" if no_warps else "false"

    accel_lua = f'\n        accel_profile = "{accel_profile}",' if accel_profile in ("adaptive", "flat", "custom") else ""

    # Real-time evaluation in Hyprland
    lua_code = f"""
hl.config({{
    input = {{
        kb_layout = "{layouts_str}",
        kb_options = "{kb_options}",
        numlock_by_default = {numlock_str},
        repeat_rate = {repeat_rate},
        repeat_delay = {repeat_delay},
        sensitivity = {sensitivity},{accel_lua}
        natural_scroll = {nat_scroll_str},
        left_handed = {left_handed_str},
        scroll_factor = {scroll_factor},
        follow_mouse = {follow_mouse},
        touchpad = {{
            natural_scroll = {tp_nat_scroll_str},
            disable_while_typing = {tp_dwt_str},
            tap_to_click = {tp_ttc_str},
            scroll_factor = {tp_scroll_factor}
        }}
    }},
    cursor = {{
        no_warps = {no_warps_str}
    }}
}})
return "ok"
"""
    try:
        subprocess.run(["hyprctl", "eval", lua_code], capture_output=True, text=True, timeout=3)
    except Exception as e:
        sys.stderr.write(f"hyprctl eval error: {e}\n")

    # Switch all keyboards to index 0 (primary layout)
    try:
        subprocess.run(["hyprctl", "switchxkblayout", "all", "0"], capture_output=True, text=True, timeout=2)
    except Exception:
        pass

    # Persist in hypr-user.lua
    try:
        write_hypr_user_file_input(
            layouts_str, kb_options, numlock, repeat_rate, repeat_delay,
            sensitivity, accel_profile, natural_scroll, left_handed,
            scroll_factor, follow_mouse, tp_natural_scroll,
            tp_disable_typing, tp_tap_to_click, tp_scroll_factor, no_warps
        )
    except Exception as e:
        sys.stderr.write(f"write_hypr_user_file_input error: {e}\n")

    # Persist in config.json
    try:
        write_config_json({
            "keyboardLayouts": layouts,
            "keyboardSwitchOption": kb_options,
            "keyboardNumlockByDefault": numlock,
            "keyboardRepeatRate": repeat_rate,
            "keyboardRepeatDelay": repeat_delay,
            "mouseSensitivity": sensitivity,
            "mouseAccelProfile": accel_profile,
            "mouseNaturalScroll": natural_scroll,
            "mouseLeftHanded": left_handed,
            "mouseScrollFactor": scroll_factor,
            "mouseFollowFocus": follow_mouse,
            "touchpadNaturalScroll": tp_natural_scroll,
            "touchpadDisableWhileTyping": tp_disable_typing,
            "touchpadTapToClick": tp_tap_to_click,
            "touchpadScrollFactor": tp_scroll_factor,
            "cursorNoWarps": no_warps
        })
    except Exception as e:
        sys.stderr.write(f"write_config_json error: {e}\n")

    print(json.dumps({
        "status": "ok",
        "layouts": layouts,
        "primaryLayout": layouts[0],
        "kbOptions": kb_options,
        "numlockByDefault": numlock,
        "mouseSensitivity": sensitivity,
        "mouseAccelProfile": accel_profile,
        "mouseNaturalScroll": natural_scroll,
        "mouseLeftHanded": left_handed,
        "mouseScrollFactor": scroll_factor,
        "mouseFollowFocus": follow_mouse,
        "touchpadNaturalScroll": tp_natural_scroll,
        "touchpadDisableWhileTyping": tp_disable_typing,
        "touchpadTapToClick": tp_tap_to_click,
        "touchpadScrollFactor": tp_scroll_factor,
        "cursorNoWarps": no_warps
    }))

def main():
    if len(sys.argv) < 2:
        get_settings()
        return

    cmd = sys.argv[1]
    if cmd == "get":
        get_settings()
    elif cmd == "apply":
        payload = sys.argv[2] if len(sys.argv) > 2 else "{}"
        apply_settings(payload)
    else:
        sys.stderr.write(f"Unknown command {cmd}\n")
        sys.exit(1)

if __name__ == "__main__":
    main()
