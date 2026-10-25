#!/usr/bin/env python3
"""
Clipboard Manager for Quickshell
Watches Wayland clipboard for text and images, maintains the last 30 items,
and provides CLI commands for listing, copying, pasting, and deleting items.
"""

import sys
import os
import json
import time
import hashlib
import subprocess
from datetime import datetime
import io
import signal

CACHE_DIR = os.path.expanduser("~/.cache/quickshell/clipboard")
IMAGES_DIR = os.path.join(CACHE_DIR, "images")
HISTORY_FILE = os.path.join(CACHE_DIR, "history.json")
MAX_ITEMS = 30

def ensure_dirs():
    os.makedirs(IMAGES_DIR, exist_ok=True)

def load_history():
    ensure_dirs()
    if not os.path.exists(HISTORY_FILE):
        return []
    try:
        with open(HISTORY_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
            if isinstance(data, list):
                return data
    except Exception:
        pass
    return []

def save_history(history):
    ensure_dirs()
    # Limit to MAX_ITEMS
    history = history[:MAX_ITEMS]
    
    # Save JSON atomically
    tmp_file = HISTORY_FILE + ".tmp"
    with open(tmp_file, "w", encoding="utf-8") as f:
        json.dump(history, f, ensure_ascii=False, indent=2)
    os.replace(tmp_file, HISTORY_FILE)
    
    # Clean up orphaned images
    try:
        active_images = {os.path.basename(item["content"]) for item in history if item.get("type") == "image"}
        for f in os.listdir(IMAGES_DIR):
            if f not in active_images:
                try:
                    os.remove(os.path.join(IMAGES_DIR, f))
                except Exception:
                    pass
    except Exception:
        pass

def record_text():
    try:
        raw = sys.stdin.read()
    except Exception:
        return
    
    if not raw or raw.strip() == "":
        return
    
    text = raw
    history = load_history()
    
    # Check if duplicate of most recent item
    if history and history[0].get("type") == "text" and history[0].get("content") == text:
        return
    
    # Remove existing identical item if present elsewhere in history
    history = [item for item in history if not (item.get("type") == "text" and item.get("content") == text)]
    
    length = len(text)
    size_str = f"{length} chars" if length < 1000 else f"{round(length/1024, 1)} KB"
    
    entry = {
        "id": int(time.time() * 1000),
        "type": "text",
        "content": text,
        "preview": text[:300].strip(),
        "time": datetime.now().strftime("%H:%M"),
        "timestamp": time.time(),
        "size": size_str
    }
    
    history.insert(0, entry)
    save_history(history)

def record_image():
    try:
        data = sys.stdin.buffer.read()
    except Exception:
        return
    
    if not data or len(data) < 32:
        return
    
    ensure_dirs()
    img_hash = hashlib.sha256(data).hexdigest()[:16]
    ext = "png"
    
    dim_str = ""
    try:
        from PIL import Image
        img = Image.open(io.BytesIO(data))
        w, h = img.size
        ext = (img.format or "png").lower()
        dim_str = f"{w}x{h} • "
    except Exception:
        pass
    
    filename = f"{img_hash}.{ext}"
    filepath = os.path.join(IMAGES_DIR, filename)
    
    # Save image file if not already existing
    if not os.path.exists(filepath):
        with open(filepath, "wb") as f:
            f.write(data)
    
    history = load_history()
    
    # Check duplicate with most recent item
    if history and history[0].get("type") == "image" and history[0].get("content") == filepath:
        return
    
    # Remove older identical entry
    history = [item for item in history if not (item.get("type") == "image" and item.get("content") == filepath)]
    
    size_kb = round(len(data) / 1024, 1)
    entry = {
        "id": int(time.time() * 1000),
        "type": "image",
        "content": filepath,
        "preview": filepath,
        "time": datetime.now().strftime("%H:%M"),
        "timestamp": time.time(),
        "size": f"{dim_str}{size_kb} KB"
    }
    
    history.insert(0, entry)
    save_history(history)

def list_items():
    history = load_history()
    print(json.dumps(history, ensure_ascii=False))

def copy_item(item_id):
    history = load_history()
    target = None
    for item in history:
        if str(item.get("id")) == str(item_id):
            target = item
            break
    
    if not target:
        return False
    
    if target["type"] == "text":
        p = subprocess.Popen(["wl-copy"], stdin=subprocess.PIPE)
        p.communicate(input=target["content"].encode("utf-8"))
        return p.returncode == 0
    elif target["type"] == "image":
        filepath = target["content"]
        if os.path.exists(filepath):
            with open(filepath, "rb") as f:
                img_data = f.read()
            p = subprocess.Popen(["wl-copy", "-t", "image/png"], stdin=subprocess.PIPE)
            p.communicate(input=img_data)
            return p.returncode == 0
    return False

def paste_item(item_id):
    if copy_item(item_id):
        time.sleep(0.15)
        try:
            subprocess.run(["wtype", "-M", "ctrl", "-k", "v", "-m", "ctrl"], check=True)
            return True
        except (subprocess.SubprocessError, FileNotFoundError):
            pass
    return False

def delete_item(item_id):
    history = load_history()
    history = [item for item in history if str(item.get("id")) != str(item_id)]
    save_history(history)

def clear_all():
    save_history([])
    try:
        for f in os.listdir(IMAGES_DIR):
            os.remove(os.path.join(IMAGES_DIR, f))
    except Exception:
        pass

def run_daemon():
    ensure_dirs()
    # Clean up any leftover watcher processes from previous runs
    try:
        subprocess.run(["pkill", "-f", "wl-paste.*clipboard_manager.py"], capture_output=True)
    except Exception:
        pass

    # Populate initial clipboard content
    try:
        p_text = subprocess.run(["wl-paste", "--type", "text"], capture_output=True, text=True, timeout=1)
        if p_text.returncode == 0 and p_text.stdout and p_text.stdout.strip():
            sys.stdin = io.StringIO(p_text.stdout)
            record_text()
    except Exception:
        pass
    
    script_path = os.path.abspath(__file__)
    
    # Spawn text watcher
    p1 = subprocess.Popen(["wl-paste", "--type", "text", "--watch", sys.executable, script_path, "record_text"])
    # Spawn image watcher
    p2 = subprocess.Popen(["wl-paste", "--type", "image", "--watch", sys.executable, script_path, "record_image"])
    
    def cleanup_children(signum=None, frame=None):
        for proc in (p1, p2):
            try:
                proc.terminate()
                proc.wait(timeout=0.5)
            except Exception:
                try:
                    proc.kill()
                except Exception:
                    pass
        sys.exit(0)

    signal.signal(signal.SIGTERM, cleanup_children)
    signal.signal(signal.SIGINT, cleanup_children)

    try:
        while True:
            time.sleep(2)
            if p1.poll() is not None:
                p1 = subprocess.Popen(["wl-paste", "--type", "text", "--watch", sys.executable, script_path, "record_text"])
            if p2.poll() is not None:
                p2 = subprocess.Popen(["wl-paste", "--type", "image", "--watch", sys.executable, script_path, "record_image"])
    except (KeyboardInterrupt, SystemExit):
        cleanup_children()

def main():
    if len(sys.argv) < 2:
        list_items()
        return
    
    cmd = sys.argv[1]
    if cmd == "daemon":
        run_daemon()
    elif cmd == "record_text":
        record_text()
    elif cmd == "record_image":
        record_image()
    elif cmd == "list":
        list_items()
    elif cmd == "copy" and len(sys.argv) > 2:
        copy_item(sys.argv[2])
    elif cmd == "paste" and len(sys.argv) > 2:
        paste_item(sys.argv[2])
    elif cmd == "delete" and len(sys.argv) > 2:
        delete_item(sys.argv[2])
    elif cmd == "clear":
        clear_all()
    else:
        list_items()

if __name__ == "__main__":
    main()