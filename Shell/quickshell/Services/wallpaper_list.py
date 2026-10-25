#!/usr/bin/env python3
import sys
import os
import glob
import json

def get_wallpapers(folder):
    home = os.path.expanduser('~')
    if folder.startswith('/'):
        target = os.path.join(home, folder.lstrip('/'))
    else:
        target = os.path.join(home, folder)
    
    if not os.path.exists(target):
        target = os.path.join(home, 'Pictures/Wallpapers')

    files = []
    if os.path.exists(target):
        for ext in ['*.jpg', '*.jpeg', '*.png', '*.webp']:
            files.extend(glob.glob(os.path.join(target, ext)))

    files.sort()
    res = []
    for f in files:
        res.append({
            'name': os.path.basename(f),
            'path': f
        })

    return {'folder': target, 'wallpapers': res}

def main():
    folder = sys.argv[1] if len(sys.argv) > 1 else 'Pictures/Wallpapers'
    print(json.dumps(get_wallpapers(folder)))

if __name__ == '__main__':
    main()
