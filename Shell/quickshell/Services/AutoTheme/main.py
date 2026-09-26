#!/usr/bin/env python3
"""
Dynamic Wallpaper & Base16 Theme Mapper
Conforms to Instrucoes_cores.md and Wallpaper_Theme_Architecture.md:
- Extracts dominant colors via K-Means / fast color quantization.
- Performs dual-matching against pre-split dark_list and light_list from palettes.json.
- Generates/updates static wallpaper_map.json with { "dark": "...", "light": "..." }.
- Supports CLI commands: scan (default), single, get.
"""

import os
import sys
import json
import argparse
import numpy as np
from PIL import Image

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "../.."))

PALETTES_FILE = os.path.join(PROJECT_ROOT, "Asura", "palettes", "palettes.json")
OUTPUT_MAP_FILE = os.path.join(PROJECT_ROOT, "Asura", "wallpaper_map.json")
SCRIPTS_MAP_FILE = os.path.join(SCRIPT_DIR, "wallpaper_map.json")

DEFAULT_WALLPAPER_DIR = os.path.expanduser("~/Pictures/Wallpapers")

def load_palette_lists(filepath=PALETTES_FILE):
    """Loads pre-split dark_list and light_list from structured palettes.json."""
    if not os.path.exists(filepath):
        print(f"Error: Palettes file '{filepath}' not found.", file=sys.stderr)
        return [], []
    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    dark_list = data.get("dark_list", [])
    light_list = data.get("light_list", [])
    return dark_list, light_list

def extract_dominant_colors(image_path, k=5):
    """
    Extracts k dominant RGB colors using fast bilinear downscaling and median-cut / k-means quantization.
    Returns float32 numpy array of shape (k, 3).
    """
    with Image.open(image_path) as img:
        img = img.convert("RGB")
        small = img.resize((100, 100), Image.Resampling.BILINEAR)
        quantized = small.quantize(colors=k, method=Image.Quantize.MEDIANCUT)
        palette = quantized.getpalette()[:k * 3]
        return np.array(palette, dtype=np.float32).reshape(-1, 3)

def find_best_match(dominant_colors, candidate_list):
    """
    Finds the closest palette in candidate_list using vectorized Euclidean distance
    between dominant wallpaper colors and the palette's background, accent, and foreground.
    """
    if not candidate_list:
        return "catppuccin-mocha"
        
    best_id = None
    min_cost = float("inf")

    for item in candidate_list:
        bg = item.get("bg", [30, 30, 46])
        accent = item.get("accent", [137, 180, 250])
        fg = item.get("fg", [205, 214, 244])
        
        pal_colors = np.array([bg, accent, fg], dtype=np.float32)
        diff = dominant_colors[:, np.newaxis, :] - pal_colors[np.newaxis, :, :]
        dists = np.linalg.norm(diff, axis=2)
        cost = np.mean(np.min(dists, axis=1))

        if cost < min_cost:
            min_cost = cost
            best_id = item["id"]

    return best_id or candidate_list[0]["id"]

def load_existing_map():
    """Loads existing wallpaper_map.json if present."""
    if os.path.exists(OUTPUT_MAP_FILE):
        try:
            with open(OUTPUT_MAP_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return {}

def save_wallpaper_map(mapping):
    """Saves the static mapping dictionary to Asura and Scripts."""
    os.makedirs(os.path.dirname(OUTPUT_MAP_FILE), exist_ok=True)
    with open(OUTPUT_MAP_FILE, "w", encoding="utf-8") as f:
        json.dump(mapping, f, indent=2, ensure_ascii=False)
    
    with open(SCRIPTS_MAP_FILE, "w", encoding="utf-8") as f:
        json.dump(mapping, f, indent=2, ensure_ascii=False)

def scan_directory(directory, force=False):
    """Scans all wallpapers in directory and generates dual dark/light mapping."""
    if not os.path.isdir(directory):
        print(f"Error: Directory '{directory}' does not exist.", file=sys.stderr)
        return {}

    dark_list, light_list = load_palette_lists()
    if not dark_list or not light_list:
        return {}

    existing_map = load_existing_map()
    valid_exts = (".png", ".jpg", ".jpeg", ".webp", ".svg", ".bmp", ".gif")
    files = [f for f in os.listdir(directory) if f.lower().endswith(valid_exts)]

    if not files:
        print(f"No wallpaper images found in '{directory}'.")
        return existing_map

    print(f"Analyzing {len(files)} wallpapers with K-Means dual matching...")
    processed = 0
    for filename in sorted(files):
        if not force and filename in existing_map:
            entry = existing_map[filename]
            if isinstance(entry, dict) and "dark" in entry and "light" in entry:
                continue

        path = os.path.join(directory, filename)
        try:
            dom_colors = extract_dominant_colors(path, k=5)
            dark_theme = find_best_match(dom_colors, dark_list)
            light_theme = find_best_match(dom_colors, light_list)

            existing_map[filename] = {
                "dark": dark_theme,
                "light": light_theme
            }
            processed += 1
            print(f"  [+] {filename} -> dark: {dark_theme} | light: {light_theme}")
        except Exception as e:
            print(f"  [!] Error processing '{filename}': {e}", file=sys.stderr)

    save_wallpaper_map(existing_map)
    print(f"Successfully updated wallpaper_map.json ({len(existing_map)} entries, {processed} newly processed).")
    return existing_map

def process_single(image_path, update_map=True):
    """Processes a single image, returns dict with dark and light themes, and updates map."""
    if not os.path.exists(image_path):
        print(json.dumps({"error": f"File '{image_path}' not found"}), file=sys.stderr)
        return None

    dark_list, light_list = load_palette_lists()
    if not dark_list or not light_list:
        return None

    try:
        dom_colors = extract_dominant_colors(image_path, k=5)
        dark_theme = find_best_match(dom_colors, dark_list)
        light_theme = find_best_match(dom_colors, light_list)

        result = {
            "dark": dark_theme,
            "light": light_theme
        }
        filename = os.path.basename(image_path)

        if update_map:
            existing_map = load_existing_map()
            existing_map[filename] = result
            save_wallpaper_map(existing_map)

        return result
    except Exception as e:
        print(f"Error processing single image: {e}", file=sys.stderr)
        return None

def set_wallpaper_palette(image_target, palette_id, mode="dark"):
    filename = os.path.basename(image_target)
    existing_map = load_existing_map()
    entry = existing_map.get(filename, {})
    if isinstance(entry, str):
        entry = {"dark": entry, "light": entry}
    elif not isinstance(entry, dict):
        entry = {}
    entry[mode] = palette_id
    if "dark" not in entry:
        entry["dark"] = palette_id
    if "light" not in entry:
        entry["light"] = palette_id
    existing_map[filename] = entry
    save_wallpaper_map(existing_map)
    return entry

def main():
    parser = argparse.ArgumentParser(description="Extract dominant colors & map wallpapers to Base16 themes.")
    parser.add_argument("command", nargs="?", default="scan", choices=["scan", "single", "get", "set"],
                        help="Operation: scan (default), single, get, or set")
    parser.add_argument("target", nargs="?", default=None,
                        help="Target image file or directory path")
    parser.add_argument("palette", nargs="?", default=None,
                        help="Palette ID for set command")
    parser.add_argument("--mode", choices=["dark", "light"], default="dark",
                        help="Theme mode (dark or light)")
    parser.add_argument("--dir", default=DEFAULT_WALLPAPER_DIR,
                        help="Wallpapers directory to scan (default: ~/Pictures/Wallpapers)")
    parser.add_argument("--force", action="store_true",
                        help="Re-analyze all images even if already present in wallpaper_map.json")

    args = parser.parse_args()

    if args.command == "scan":
        target_dir = args.target if args.target and os.path.isdir(args.target) else args.dir
        scan_directory(target_dir, force=args.force)
    elif args.command in ("single", "get"):
        if not args.target:
            print("Error: Specify image path for 'single' or 'get' command.", file=sys.stderr)
            sys.exit(1)
        res = process_single(args.target, update_map=(args.command == "single"))
        if res:
            print(json.dumps(res))
        else:
            sys.exit(1)
    elif args.command == "set":
        if not args.target or not args.palette:
            print("Error: Specify image target and palette id for 'set' command.", file=sys.stderr)
            sys.exit(1)
        res = set_wallpaper_palette(args.target, args.palette, mode=args.mode)
        if res:
            print(json.dumps(res))
        else:
            sys.exit(1)

if __name__ == "__main__":
    main()
