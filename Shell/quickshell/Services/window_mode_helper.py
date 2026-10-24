#!/usr/bin/env python3
import sys
import subprocess
import json

LAYOUTS = ["scrolling", "dwindle", "master", "monocle"]

def get_active_workspace():
    try:
        res = subprocess.run(["hyprctl", "activeworkspace", "-j"], capture_output=True, text=True, timeout=2)
        if res.returncode == 0 and res.stdout.strip():
            return json.loads(res.stdout)
    except Exception as e:
        sys.stderr.write(f"get_active_workspace error: {e}\n")
    return {}

def apply_workspace_layout(ws, layout_name):
    ws_name = str(ws.get("name", ""))
    ws_id = str(ws.get("id", 1))
    is_special = ws_name.startswith("special:")

    if is_special:
        rule_target = ws_name
    else:
        rule_target = ws_id

    lua = f'''
local ws = hl.get_active_workspace()
if hl.get_active_special_workspace() then ws = hl.get_active_special_workspace() end
if not ws then return end
hl.workspace_rule({{ workspace = "{rule_target}", layout = "{layout_name}" }})
'''
    try:
        subprocess.run(["hyprctl", "eval", lua], capture_output=True, text=True, timeout=2)
    except Exception as e:
        sys.stderr.write(f"apply_workspace_layout error: {e}\n")

def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "get"
    ws = get_active_workspace()
    cur = ws.get("tiledLayout") or "dwindle"
    ws_id = ws.get("id", 1)

    if cmd == "cycle":
        idx = LAYOUTS.index(cur) if cur in LAYOUTS else 0
        nxt = LAYOUTS[(idx + 1) % len(LAYOUTS)]
        apply_workspace_layout(ws, nxt)
        print(json.dumps({"layout": nxt, "workspace": ws_id}))
    elif cmd == "set":
        target = sys.argv[2] if len(sys.argv) > 2 else "dwindle"
        if target in LAYOUTS:
            apply_workspace_layout(ws, target)
            print(json.dumps({"layout": target, "workspace": ws_id}))
        else:
            print(json.dumps({"layout": cur, "workspace": ws_id, "error": "unknown layout"}))
    else: # "get"
        print(json.dumps({"layout": cur, "workspace": ws_id}))

if __name__ == "__main__":
    main()
