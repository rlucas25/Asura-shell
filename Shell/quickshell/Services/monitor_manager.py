#!/usr/bin/env python3
import sys
import os
import re
import subprocess
import json

def get_monitors():
    try:
        res = subprocess.run(["hyprctl", "monitors", "-j"], capture_output=True, text=True, timeout=3)
        if res.returncode == 0:
            return json.loads(res.stdout)
    except Exception as e:
        sys.stderr.write(f"get_monitors error: {e}\n")
    return []

def apply_monitor(name: str, mode: str = "preferred", position: str = "auto", scale: float = 1.0, transform: int = 0, vrr: bool = False):
    name = str(name).strip()
    mode = str(mode).strip() if mode else "preferred"
    position = str(position).strip() if position else "auto"
    try:
        scale = float(scale)
    except (ValueError, TypeError):
        scale = 1.0
    try:
        transform = int(transform)
    except (ValueError, TypeError):
        transform = 0
    vrr_str = "true" if vrr else "false"

    lua_code = f"""
hl.monitor({{
    output = "{name}",
    mode = "{mode}",
    position = "{position}",
    scale = {scale},
    transform = {transform},
    vrr = {vrr_str}
}})
return "ok"
"""
    try:
        res = subprocess.run(["hyprctl", "eval", lua_code], capture_output=True, text=True, timeout=3)
        ok = (res.returncode == 0)
    except Exception as e:
        sys.stderr.write(f"apply_monitor hyprctl error: {e}\n")
        ok = False

    persist_ok = persist_monitor(name, mode, position, scale, transform, vrr)
    try:
        subprocess.run(["hyprctl", "reload"], capture_output=True, text=True, timeout=3)
    except Exception as e:
        sys.stderr.write(f"apply_monitor hyprctl reload error: {e}\n")
    return ok or persist_ok

def persist_monitor(name: str, mode: str, position: str, scale: float, transform: int, vrr: bool):
    config_path = os.path.expanduser("~/.config/hypr/hyprland.lua")
    if not os.path.exists(config_path):
        return False
    try:
        with open(config_path, "r", encoding="utf-8") as f:
            content = f.read()

        if not content.strip():
            return False

        vrr_str = "true" if vrr else "false"
        rule_block = f"""hl.monitor({{
    output = "{name}",
    mode = "{mode}",
    position = "{position}",
    scale = {scale},
    transform = {transform},
    vrr = {vrr_str}
}})"""

        pattern = rf'hl\.monitor\(\s*\{{[\s\S]*?output\s*=\s*"{re.escape(name)}"[\s\S]*?\}}\s*\)'
        matches = list(re.finditer(pattern, content))
        if matches:
            # Remove subsequent duplicates first from end to start
            for m in reversed(matches[1:]):
                content = content[:m.start()] + content[m.end():]
            m_first = re.search(pattern, content)
            if m_first:
                new_content = content[:m_first.start()] + rule_block + content[m_first.end():]
            else:
                new_content = content + "\n\n" + rule_block
            new_content = re.sub(r'\n{3,}', '\n\n', new_content)
        else:
            marker = "-- Default monitor conf"
            if marker in content:
                new_content = content.replace(marker, marker + "\n" + rule_block)
            else:
                new_content = content + "\n\n" + rule_block

        tmp_path = config_path + ".tmp"
        with open(tmp_path, "w", encoding="utf-8") as f:
            f.write(new_content)
        os.replace(tmp_path, config_path)
        return True
    except Exception as e:
        sys.stderr.write(f"persist_monitor error: {e}\n")
        return False

def set_dpms(name: str, state: str):
    st = "on" if str(state).lower() in ("true", "1", "on") else "off"
    name = str(name).strip()
    lua_code = f'return hl.dsp.dpms("{st}", "{name}")'
    try:
        res = subprocess.run(["hyprctl", "eval", lua_code], capture_output=True, text=True, timeout=3)
        return res.returncode == 0
    except Exception as e:
        sys.stderr.write(f"set_dpms error: {e}\n")
        return False

def apply_all_monitors(monitors_list: list):
    lua_lines = []
    for m in monitors_list:
        name = str(m.get("name", "")).strip()
        if not name:
            continue
        mode = str(m.get("mode", "preferred")).strip()
        pos = str(m.get("position", "auto")).strip()
        try:
            sc = float(m.get("scale", 1.0))
        except (ValueError, TypeError):
            sc = 1.0
        try:
            tr = int(m.get("transform", 0))
        except (ValueError, TypeError):
            tr = 0
        vrr = "true" if m.get("vrr", False) else "false"

        lua_lines.append(f"""hl.monitor({{
    output = "{name}",
    mode = "{mode}",
    position = "{pos}",
    scale = {sc},
    transform = {tr},
    vrr = {vrr}
}})""")

    if not lua_lines:
        return False

    lua_code = "\n".join(lua_lines) + '\nreturn "ok"\n'
    try:
        res = subprocess.run(["hyprctl", "eval", lua_code], capture_output=True, text=True, timeout=3)
        ok = (res.returncode == 0)
    except Exception as e:
        sys.stderr.write(f"apply_all hyprctl error: {e}\n")
        ok = False

    for m in monitors_list:
        name = str(m.get("name", "")).strip()
        if name:
            persist_monitor(
                name,
                str(m.get("mode", "preferred")),
                str(m.get("position", "auto")),
                float(m.get("scale", 1.0)),
                int(m.get("transform", 0)),
                bool(m.get("vrr", False))
            )
    try:
        subprocess.run(["hyprctl", "reload"], capture_output=True, text=True, timeout=3)
    except Exception as e:
        sys.stderr.write(f"apply_all hyprctl reload error: {e}\n")
    return ok

def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Missing command"}))
        sys.exit(1)

    cmd = sys.argv[1]
    if cmd == "get":
        mons = get_monitors()
        print(json.dumps(mons))
    elif cmd == "apply":
        if len(sys.argv) < 3:
            print(json.dumps({"error": "Missing monitor name"}))
            sys.exit(1)
        name = sys.argv[2]
        mode = sys.argv[3] if len(sys.argv) > 3 else "preferred"
        pos = sys.argv[4] if len(sys.argv) > 4 else "auto"
        scale = float(sys.argv[5]) if len(sys.argv) > 5 else 1.0
        transform = int(sys.argv[6]) if len(sys.argv) > 6 else 0
        vrr = str(sys.argv[7]).lower() in ("true", "1", "yes") if len(sys.argv) > 7 else False

        ok = apply_monitor(name, mode, pos, scale, transform, vrr)
        print(json.dumps({"success": ok, "name": name, "mode": mode, "scale": scale}))
    elif cmd == "apply_all":
        if len(sys.argv) < 3:
            print(json.dumps({"error": "Missing monitors json"}))
            sys.exit(1)
        try:
            mlist = json.loads(sys.argv[2])
            ok = apply_all_monitors(mlist)
            print(json.dumps({"success": ok, "count": len(mlist)}))
        except Exception as e:
            print(json.dumps({"error": str(e)}))
            sys.exit(1)
    elif cmd == "dpms":
        if len(sys.argv) < 4:
            print(json.dumps({"error": "Missing dpms args"}))
            sys.exit(1)
        name = sys.argv[2]
        st = sys.argv[3]
        ok = set_dpms(name, st)
        print(json.dumps({"success": ok, "name": name, "state": st}))
    else:
        print(json.dumps({"error": f"Unknown command {cmd}"}))
        sys.exit(1)

if __name__ == "__main__":
    main()
