#!/usr/bin/env python3
import os
import sys
import socket
import json
import time
import signal

def sig_handler(signum, frame):
    sys.exit(0)

signal.signal(signal.SIGINT, sig_handler)
signal.signal(signal.SIGTERM, sig_handler)

def main():
    his = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
    xdg = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
    sock_path = f"{xdg}/hypr/{his}/.socket2.sock"

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
                while "\n" in buf:
                    line, buf = buf.split("\n", 1)
                    line = line.strip()
                    if line.startswith("activewindow>>"):
                        payload = line[len("activewindow>>"):]
                        parts = payload.split(",", 1)
                        klass = parts[0].strip() if len(parts) > 0 else ""
                        title = parts[1].strip() if len(parts) > 1 else ""
                        msg = json.dumps({"class": klass, "title": title})
                        sys.stdout.write(msg + "\n")
                        sys.stdout.flush()
            s.close()
        except Exception:
            time.sleep(1)

if __name__ == "__main__":
    main()
