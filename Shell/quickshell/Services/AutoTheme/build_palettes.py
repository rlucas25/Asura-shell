#!/usr/bin/env python3
"""
Base16 Palettes Preprocessor & Categorizer
Generates Asura/palettes/palettes.json with:
- palettes: { [id]: { base00..base0F, name, type, category } } (O(1) lookup)
- categories: { all: [...], blue: [...], ... } (O(1) tab binding in QML)
- dark_list: [...] (pre-split dark palettes for fast image matching)
- light_list: [...] (pre-split light palettes for fast image matching)
"""

import os
import json
import colorsys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
SOURCE_PALETTES = os.path.join(PROJECT_ROOT, "Asura", "palettes", "palettes.json")
OUTPUT_PALETTES = os.path.join(PROJECT_ROOT, "Asura", "palettes", "palettes.json")
SCRIPTS_PALETTES = os.path.join(SCRIPT_DIR, "palettes.json")

def hex_to_rgb(hex_str):
    hex_str = str(hex_str).lstrip('#')
    if len(hex_str) == 3:
        hex_str = ''.join([c*2 for c in hex_str])
    return [int(hex_str[i:i+2], 16) for i in (0, 2, 4)]

def get_luminance(rgb):
    # Standard relative luminance (sRGB / Rec. 709)
    return 0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2]

def get_hue_category(rgb):
    r, g, b = [x / 255.0 for x in rgb]
    h, s, v = colorsys.rgb_to_hsv(r, g, b)
    h_deg = h * 360.0
    if s < 0.15 or v < 0.15:
        return 'monochrome'
    if h_deg < 20 or h_deg >= 340:
        return 'red'
    elif h_deg < 45:
        return 'orange'
    elif h_deg < 70:
        return 'yellow'
    elif h_deg < 165:
        return 'green'
    elif h_deg < 200:
        return 'cyan'
    elif h_deg < 265:
        return 'blue'
    else:
        return 'purple'

def format_title(name):
    clean = name.replace('-', ' ').replace('_', ' ')
    return ' '.join([w.capitalize() for w in clean.split()])

def build():
    # Read existing raw palettes
    with open(SOURCE_PALETTES, 'r', encoding='utf-8') as f:
        raw_data = json.load(f)

    # If already nested, extract raw dict
    if "palettes" in raw_data and isinstance(raw_data["palettes"], dict):
        raw_palettes = raw_data["palettes"]
    else:
        raw_palettes = raw_data

    palettes_dict = {}
    categories_dict = {
        "all": [],
        "blue": [],
        "cyan": [],
        "purple": [],
        "green": [],
        "red": [],
        "yellow": [],
        "orange": [],
        "monochrome": []
    }
    dark_list = []
    light_list = []

    # Simplified reference palettes for fast distance matching in Scripts/palettes.json
    reference_palettes = {}

    for pal_id, p in sorted(raw_palettes.items()):
        if not isinstance(p, dict) or "base00" not in p:
            continue
        
        base00 = p.get("base00", "#1e1e2e")
        base05 = p.get("base05", "#cdd6f4")
        base0D = p.get("base0D", p.get("base08", "#89b4fa"))
        
        bg_rgb = hex_to_rgb(base00)
        fg_rgb = hex_to_rgb(base05)
        accent_rgb = hex_to_rgb(base0D)
        
        lum = get_luminance(bg_rgb)
        pal_type = "dark" if lum < 128 else "light"
        cat = get_hue_category(accent_rgb)
        title = p.get("name") or format_title(pal_id)

        item_colors = {
            "base00": p.get("base00", "#1e1e2e"),
            "base01": p.get("base01", "#181825"),
            "base02": p.get("base02", "#313244"),
            "base03": p.get("base03", "#45475a"),
            "base04": p.get("base04", "#a6adc8"),
            "base05": p.get("base05", "#cdd6f4"),
            "base06": p.get("base06", "#f5e0dc"),
            "base07": p.get("base07", "#ffffff"),
            "base08": p.get("base08", "#f38ba8"),
            "base09": p.get("base09", "#fab387"),
            "base0A": p.get("base0A", "#f9e2af"),
            "base0B": p.get("base0B", "#a6e3a1"),
            "base0C": p.get("base0C", "#94e2d5"),
            "base0D": p.get("base0D", "#89b4fa"),
            "base0E": p.get("base0E", "#cba6f7"),
            "base0F": p.get("base0F", "#f2cdcd"),
        }

        pal_obj = {
            "id": pal_id,
            "name": title,
            "type": pal_type,
            "category": cat,
            **item_colors
        }

        palettes_dict[pal_id] = pal_obj

        summary_card = {
            "id": pal_id,
            "name": title,
            "type": pal_type,
            "category": cat,
            "color": base0D,
            "bg": base00,
            "fg": base05,
            "colors": item_colors
        }

        categories_dict["all"].append(summary_card)
        if cat in categories_dict:
            categories_dict[cat].append(summary_card)
        else:
            categories_dict[cat] = [summary_card]

        match_entry = {
            "id": pal_id,
            "name": title,
            "type": pal_type,
            "bg": bg_rgb,
            "fg": fg_rgb,
            "accent": accent_rgb,
            "color": base0D,
            "colors": item_colors
        }

        if pal_type == "dark":
            dark_list.append(match_entry)
        else:
            light_list.append(match_entry)

        reference_palettes[pal_id] = {
            "bg": bg_rgb,
            "fg": fg_rgb,
            "accent1": hex_to_rgb(p.get("base0D", "#89b4fa")),
            "accent2": hex_to_rgb(p.get("base0E", "#cba6f7"))
        }

    output_data = {
        "palettes": palettes_dict,
        "categories": categories_dict,
        "dark_list": dark_list,
        "light_list": light_list
    }

    with open(OUTPUT_PALETTES, 'w', encoding='utf-8') as f:
        json.dump(output_data, f, indent=2, ensure_ascii=False)

    with open(SCRIPTS_PALETTES, 'w', encoding='utf-8') as f:
        json.dump(reference_palettes, f, indent=2, ensure_ascii=False)

    print(f"Successfully generated structured palettes.json:")
    print(f"  Total palettes: {len(palettes_dict)}")
    print(f"  Dark list: {len(dark_list)}")
    print(f"  Light list: {len(light_list)}")
    print(f"  Categories: { {k: len(v) for k, v in categories_dict.items()} }")

if __name__ == "__main__":
    build()
