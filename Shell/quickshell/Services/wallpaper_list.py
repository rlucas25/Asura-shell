#!/usr/bin/env python3
import sys
import os
import glob
import json
import shutil

def get_wallpapers(folder):
    home = os.path.expanduser('~')
    folder = (folder or 'Pictures/Wallpapers').strip()
    if folder.startswith('~'):
        target = os.path.expanduser(folder)
    elif folder.startswith('/'):
        if os.path.isabs(folder) and os.path.exists(folder):
            target = folder
        else:
            target = os.path.join(home, folder.lstrip('/'))
    else:
        target = os.path.join(home, folder)
    
    if not os.path.exists(target):
        try:
            os.makedirs(target, exist_ok=True)
        except Exception:
            target = os.path.join(home, 'Pictures/Wallpapers')
            try:
                os.makedirs(target, exist_ok=True)
            except Exception:
                pass

    files = []
    patterns = [
        '*.jpg', '*.jpeg', '*.png', '*.webp', '*.bmp', '*.svg',
        '*.JPG', '*.JPEG', '*.PNG', '*.WEBP', '*.BMP', '*.SVG'
    ]
    if os.path.exists(target):
        for ext in patterns:
            files.extend(glob.glob(os.path.join(target, ext)))

    # Fallback to default wallpaper if target folder is currently empty
    assets_default = os.path.join(home, '.local/share/asura/Shell/quickshell/Assets/default_wallpaper.jpg')
    if not files and os.path.exists(assets_default):
        dest = os.path.join(target, 'default_wallpaper.jpg')
        try:
            shutil.copy2(assets_default, dest)
            files.append(dest)
        except Exception:
            files.append(assets_default)

    # Deduplicate while preserving order
    seen = set()
    unique_files = []
    for f in sorted(files, key=lambda x: os.path.basename(x).lower()):
        abs_p = os.path.abspath(f)
        if abs_p not in seen:
            seen.add(abs_p)
            unique_files.append({
                'name': os.path.basename(abs_p),
                'path': abs_p
            })

    return {'folder': target, 'wallpapers': unique_files}

def main():
    folder = sys.argv[1] if len(sys.argv) > 1 else 'Pictures/Wallpapers'
    print(json.dumps(get_wallpapers(folder)))

if __name__ == '__main__':
    main()
