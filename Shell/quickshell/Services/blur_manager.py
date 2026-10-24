#!/usr/bin/env python3
import sys
import os
import re
import subprocess
import json

PRESETS = {
    "light": {
        "size": 4,
        "passes": 2,
        "noise": 0.01,
        "vibrancy": 0.12,
        "label": "Light (Subtle)"
    },
    "balanced": {
        "size": 10,
        "passes": 3,
        "noise": 0.015,
        "vibrancy": 0.16,
        "label": "Balanced (Glass)"
    },
    "strong": {
        "size": 16,
        "passes": 4,
        "noise": 0.02,
        "vibrancy": 0.22,
        "label": "Strong (Frost)"
    },
    "maximum": {
        "size": 22,
        "passes": 5,
        "noise": 0.03,
        "vibrancy": 0.28,
        "label": "Maximum (Acrylic)"
    }
}

def resolve_params(strength, custom_size=None, custom_passes=None):
    st = str(strength).lower().strip()
    if st in PRESETS:
        p = PRESETS[st].copy()
    else:
        # Check if numeric
        try:
            sz = int(st)
            p = {
                "size": max(1, min(40, sz)),
                "passes": max(1, min(6, round(sz / 4))),
                "noise": 0.02,
                "vibrancy": 0.20,
                "label": f"Custom ({sz}px)"
            }
        except ValueError:
            p = PRESETS["balanced"].copy()

    if custom_size is not None:
        try:
            p["size"] = max(1, min(40, int(custom_size)))
        except ValueError:
            pass

    if custom_passes is not None:
        try:
            p["passes"] = max(1, min(6, int(custom_passes)))
        except ValueError:
            pass

    return p

def apply_hyprctl(enabled: bool, p: dict):
    b_str = "true" if enabled else "false"
    size = p["size"]
    passes = p["passes"]
    noise = p.get("noise", 0.015)
    vibrancy = p.get("vibrancy", 0.16)

    lua_code = f"""
hl.config({{
    decoration = {{
        blur = {{
            enabled = {b_str},
            size = {size},
            passes = {passes},
            ignore_opacity = true,
            new_optimizations = true,
            noise = {noise},
            vibrancy = {vibrancy}
        }}
    }}
}})
hl.layer_rule({{ name = "asura-bar", match = {{ namespace = "^(asura-bar.*)$" }}, animation = "slide top", blur = {b_str}, ignore_alpha = 0.05 }})
hl.layer_rule({{ name = "CenterLauncher", match = {{ namespace = "^(CenterLauncher.*)$" }}, no_anim = true, blur = {b_str}, ignore_alpha = 0.05 }})
hl.layer_rule({{ name = "ZenLauncher", match = {{ namespace = "^(ZenLauncher.*)$" }}, no_anim = true, blur = {b_str}, ignore_alpha = 0.05 }})
hl.layer_rule({{ name = "ClipboardPanel", match = {{ namespace = "^(ClipboardPanel.*)$" }}, no_anim = true, blur = {b_str}, ignore_alpha = 0.05 }})
hl.layer_rule({{ name = "window-switcher", match = {{ namespace = "^window-switcher$" }}, no_anim = true, blur = {b_str}, ignore_alpha = 0.05 }})
hl.layer_rule({{ name = "volumeOSD", match = {{ namespace = "^volumeOSD$" }}, no_anim = true, blur = {b_str}, ignore_alpha = 0.05 }})
hl.layer_rule({{ name = "NotificationToast", match = {{ namespace = "^NotificationToast$" }}, no_anim = true, blur = {b_str}, ignore_alpha = 0.05 }})
hl.layer_rule({{ name = "TimerTransitionPopup", match = {{ namespace = "^TimerTransitionPopup$" }}, no_anim = true, blur = {b_str}, ignore_alpha = 0.05 }})
hl.layer_rule({{ name = "lockscreen", match = {{ namespace = "^lockscreen$" }}, no_anim = true, blur = true, ignore_alpha = 0.05 }})
return "ok"
"""
    try:
        res = subprocess.run(["hyprctl", "eval", lua_code], capture_output=True, text=True, timeout=3)
        return res.returncode == 0
    except Exception as e:
        sys.stderr.write(f"hyprctl eval error: {e}\n")
        return False

def persist_variables(enabled: bool, p: dict):
    var_path = os.path.expanduser("~/.config/hypr/variables.lua")
    if not os.path.exists(var_path):
        return False
    try:
        with open(var_path, "r", encoding="utf-8") as f:
            content = f.read()

        if not content.strip():
            return False

        b_str = "true" if enabled else "false"
        content = re.sub(r'(blurEnabled\s*=\s*)(true|false),', rf'\g<1>{b_str},', content)
        content = re.sub(r'(blurSize\s*=\s*)\d+,', rf'\g<1>{p["size"]},', content)
        content = re.sub(r'(blurPasses\s*=\s*)\d+,', rf'\g<1>{p["passes"]},', content)

        tmp_path = var_path + ".tmp"
        with open(tmp_path, "w", encoding="utf-8") as f:
            f.write(content)
        os.replace(tmp_path, var_path)
        return True
    except Exception as e:
        sys.stderr.write(f"persist_variables error: {e}\n")
        return False

def persist_rules(enabled: bool):
    rules_path = os.path.expanduser("~/.config/hypr/hyprland/rules.lua")
    if not os.path.exists(rules_path):
        return False
    try:
        with open(rules_path, "r", encoding="utf-8") as f:
            content = f.read()

        if not content.strip():
            return False

        b_str = "true" if enabled else "false"
        targets = [
            "asura-bar",
            "CenterLauncher",
            "ZenLauncher",
            "ClipboardPanel",
            "window-switcher",
            "volumeOSD",
            "NotificationToast",
            "TimerTransitionPopup"
        ]
        for name in targets:
            pattern = rf'(name\s*=\s*"{name}"[\s\S]*?blur\s*=\s*)(true|false)'
            if re.search(pattern, content):
                content = re.sub(pattern, rf'\g<1>{b_str}', content)

        tmp_path = rules_path + ".tmp"
        with open(tmp_path, "w", encoding="utf-8") as f:
            f.write(content)
        os.replace(tmp_path, rules_path)
        return True
    except Exception as e:
        sys.stderr.write(f"persist_rules error: {e}\n")
        return False

def main():
    if len(sys.argv) < 2:
        print("Usage: blur_manager.py apply <enabled:true|false> <preset:light|balanced|strong|maximum|size> [size] [passes]")
        sys.exit(1)

    cmd = sys.argv[1]
    if cmd == "apply":
        enabled_arg = sys.argv[2] if len(sys.argv) > 2 else "true"
        enabled = str(enabled_arg).lower() in ("true", "1", "yes", "on")
        strength = sys.argv[3] if len(sys.argv) > 3 else "balanced"
        custom_size = sys.argv[4] if len(sys.argv) > 4 else None
        custom_passes = sys.argv[5] if len(sys.argv) > 5 else None

        params = resolve_params(strength, custom_size, custom_passes)
        ok_hypr = apply_hyprctl(enabled, params)
        persist_variables(enabled, params)
        persist_rules(enabled)
        try:
            subprocess.run(["hyprctl", "reload", "config-only"], capture_output=True, text=True, timeout=3)
        except Exception:
            pass

        out = {
            "success": ok_hypr,
            "enabled": enabled,
            "preset": strength,
            "size": params["size"],
            "passes": params["passes"]
        }
        print(json.dumps(out))
    elif cmd == "get":
        try:
            sz_proc = subprocess.run(["hyprctl", "getoption", "decoration:blur:size"], capture_output=True, text=True)
            pa_proc = subprocess.run(["hyprctl", "getoption", "decoration:blur:passes"], capture_output=True, text=True)
            en_proc = subprocess.run(["hyprctl", "getoption", "decoration:blur:enabled"], capture_output=True, text=True)
            sz_match = re.search(r'int:\s*(\d+)', sz_proc.stdout)
            pa_match = re.search(r'int:\s*(\d+)', pa_proc.stdout)
            en_match = re.search(r'int:\s*(\d+)', en_proc.stdout)
            out = {
                "size": int(sz_match.group(1)) if sz_match else 10,
                "passes": int(pa_match.group(1)) if pa_match else 3,
                "enabled": (int(en_match.group(1)) == 1) if en_match else True
            }
            print(json.dumps(out))
        except Exception as e:
            print(json.dumps({"error": str(e)}))
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)

if __name__ == "__main__":
    main()
