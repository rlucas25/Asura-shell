#!/usr/bin/env python3
"""
Screen and audio recorder manager for Asura / Quickshell.
Handles monitor detection, desktop + microphone audio mixing via PulseAudio/PipeWire,
graceful wf-recorder lifecycle, and cleanup.
"""

import sys
import os
import signal
import subprocess
import json
import time

STATE_FILE = "/tmp/asura_recorder_state.json"
LOG_FILE = "/tmp/asura_recorder.log"


def log(msg: str):
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{timestamp}] {msg}\n"
    try:
        with open(LOG_FILE, "a") as f:
            f.write(line)
    except Exception:
        pass
    sys.stderr.write(line)


def get_focused_monitor() -> str:
    # 1. Try hyprctl
    try:
        out = subprocess.check_output(["hyprctl", "monitors", "-j"], stderr=subprocess.DEVNULL)
        monitors = json.loads(out.decode("utf-8"))
        if isinstance(monitors, list) and len(monitors) > 0:
            for m in monitors:
                if m.get("focused"):
                    return m.get("name", "")
            return monitors[0].get("name", "")
    except Exception as e:
        log(f"hyprctl monitors failed: {e}")

    # 2. Fallback to wf-recorder -L
    try:
        out = subprocess.check_output(["wf-recorder", "-L"], stderr=subprocess.DEVNULL).decode("utf-8")
        import re
        match = re.search(r"Name:\s*(\S+)", out)
        if match:
            return match.group(1)
    except Exception as e:
        log(f"wf-recorder -L failed: {e}")

    return ""


def cleanup_audio_modules():
    try:
        out = subprocess.check_output(["pactl", "list", "short", "modules"], stderr=subprocess.DEVNULL).decode("utf-8")
        for line in out.splitlines():
            if "recording_combined" in line:
                parts = line.split()
                if parts:
                    mod_id = parts[0]
                    subprocess.run(["pactl", "unload-module", mod_id], stderr=subprocess.DEVNULL)
        time.sleep(0.15)
    except Exception as e:
        log(f"cleanup_audio_modules error: {e}")


def setup_audio_sink():
    """
    Sets up a null sink and loopbacks for desktop audio + mic.
    Returns the audio monitor device name or a fallback device name.
    """
    cleanup_audio_modules()

    target_device = "recording_combined.monitor"
    try:
        # Create null sink
        subprocess.check_call([
            "pactl", "load-module", "module-null-sink",
            "sink_name=recording_combined",
            "sink_properties=device.description=RecordingCombined",
            "rate=48000", "channels=2"
        ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(0.15)

        # Connect default sink monitor (desktop sound)
        try:
            default_sink = subprocess.check_output(["pactl", "get-default-sink"], stderr=subprocess.DEVNULL).decode().strip()
            if default_sink:
                subprocess.run([
                    "pactl", "load-module", "module-loopback",
                    f"source={default_sink}.monitor",
                    "sink=recording_combined"
                ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                time.sleep(0.15)
        except Exception as e:
            log(f"Error attaching desktop audio loopback: {e}")

        # Connect default source (microphone)
        try:
            default_source = subprocess.check_output(["pactl", "get-default-source"], stderr=subprocess.DEVNULL).decode().strip()
            if default_source:
                subprocess.run([
                    "pactl", "load-module", "module-loopback",
                    f"source={default_source}",
                    "sink=recording_combined"
                ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                time.sleep(0.2)
        except Exception as e:
            log(f"Error attaching microphone loopback: {e}")

        # Verify sink monitor is visible
        for _ in range(20):
            out = subprocess.check_output(["pactl", "list", "sources", "short"], stderr=subprocess.DEVNULL).decode()
            if target_device in out:
                return target_device
            time.sleep(0.05)

        return target_device
    except Exception as e:
        log(f"setup_audio_sink failed: {e}")

    # Fallback to direct default sink monitor
    try:
        default_sink = subprocess.check_output(["pactl", "get-default-sink"], stderr=subprocess.DEVNULL).decode().strip()
        if default_sink:
            return f"{default_sink}.monitor"
    except Exception:
        pass

    return None


def cmd_record(filepath: str):
    filepath = os.path.expanduser(filepath)
    os.makedirs(os.path.dirname(filepath), exist_ok=True)

    log(f"Preparing to record to: {filepath}")

    monitor = get_focused_monitor()
    log(f"Target monitor: {monitor or 'default'}")

    audio_device = setup_audio_sink()
    log(f"Target audio device: {audio_device or 'default'}")

    cmd = ["wf-recorder", "-y"]
    if monitor:
        cmd.extend(["-o", monitor])

    # Audio configuration: use standard PulseAudio backend (reliable AAC capture)
    if audio_device:
        cmd.append(f"--audio={audio_device}")
    else:
        cmd.append("-a")

    cmd.extend(["-f", filepath])

    log(f"Launching: {' '.join(cmd)}")

    wf_proc = subprocess.Popen(
        cmd,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )

    state = {
        "pid": wf_proc.pid,
        "manager_pid": os.getpid(),
        "file": filepath
    }
    with open(STATE_FILE, "w") as f:
        json.dump(state, f)

    is_stopping = False

    def handle_signal(sig, frame):
        nonlocal is_stopping
        if is_stopping:
            return
        is_stopping = True
        log(f"Caught signal {sig}, stopping wf-recorder (PID {wf_proc.pid})...")
        try:
            wf_proc.send_signal(signal.SIGINT)
        except Exception as e:
            log(f"Error signaling wf-recorder: {e}")

    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)
    signal.signal(signal.SIGHUP, handle_signal)

    # Wait for wf-recorder to finish
    stdout, stderr = wf_proc.communicate()
    exit_code = wf_proc.returncode
    log(f"wf-recorder finished with exit code {exit_code}")
    if stdout:
        log(f"wf-recorder stdout: {stdout.strip()[:500]}")
    if stderr:
        log(f"wf-recorder stderr: {stderr.strip()[:500]}")

    # Cleanup state and audio
    try:
        if os.path.exists(STATE_FILE):
            os.remove(STATE_FILE)
    except Exception:
        pass

    cleanup_audio_modules()

    # Validate file
    if os.path.exists(filepath) and os.path.getsize(filepath) > 1024:
        log(f"Recording successful! Saved: {filepath} ({os.path.getsize(filepath)} bytes)")
        print(json.dumps({"success": True, "path": filepath, "size": os.path.getsize(filepath)}))
        sys.exit(0)
    else:
        size = os.path.getsize(filepath) if os.path.exists(filepath) else 0
        log(f"Recording failed! File size: {size} bytes")
        print(json.dumps({"success": False, "path": filepath, "size": size, "exitCode": exit_code}))
        sys.exit(1)


def cmd_stop():
    log("Stop requested")
    # Send SIGINT to wf-recorder directly so it writes container metadata and closes cleanly
    subprocess.run(["pkill", "-INT", "-x", "wf-recorder"], stderr=subprocess.DEVNULL)

    if os.path.exists(STATE_FILE):
        try:
            with open(STATE_FILE, "r") as f:
                state = json.load(f)
            manager_pid = state.get("manager_pid")
            if manager_pid and manager_pid != os.getpid():
                try:
                    os.kill(manager_pid, signal.SIGINT)
                except ProcessLookupError:
                    pass
        except Exception as e:
            log(f"Error reading state file on stop: {e}")

    print(json.dumps({"status": "stopping"}))


def main():
    if len(sys.argv) < 2:
        print("Usage: recorder_manager.py [record <path> | stop | cleanup-audio]")
        sys.exit(1)

    cmd = sys.argv[1]
    if cmd == "record":
        if len(sys.argv) < 3:
            print("Missing file path")
            sys.exit(1)
        cmd_record(sys.argv[2])
    elif cmd == "stop":
        cmd_stop()
    elif cmd == "cleanup-audio":
        cleanup_audio_modules()
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)


if __name__ == "__main__":
    main()
