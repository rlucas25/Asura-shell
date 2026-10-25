#!/usr/bin/env python3
import argparse
import subprocess
import sys
from pathlib import Path

import shutil

__version__ = "0.1.2"


def get_quickshell_bin() -> str | None:
    """Find the Quickshell executable ('qs' or 'quickshell')."""
    return shutil.which("qs") or shutil.which("quickshell")


def get_shell_dir() -> Path:
    """Locate the installed or local Asura Quickshell directory."""
    shell_dir = Path.home() / ".local/share/asura/Shell/quickshell"
    if not (shell_dir / "shell.qml").exists():
        shell_dir = Path.home() / ".local/share/asura/Shell"
    return shell_dir


def ipc_call(target: str, action: str = "toggle", *extra_args) -> bool:
    """Send an IPC command to the active Quickshell instance."""
    qs_bin = get_quickshell_bin()
    if not qs_bin:
        print("Error: Quickshell is not installed! ('qs' or 'quickshell' not found in PATH)", file=sys.stderr)
        return False

    shell_dir = get_shell_dir()
    args = [action] + list(extra_args)

    # 1. Try targeting the specific shell directory
    cmd_path = [qs_bin, "-p", str(shell_dir), "ipc", "call", target] + args
    res = subprocess.run(cmd_path, capture_output=True, text=True)
    if res.returncode == 0:
        return True

    # 2. Fallback to newest running instance
    cmd_newest = [qs_bin, "ipc", "-n", "call", target] + args
    res = subprocess.run(cmd_newest, capture_output=True, text=True)
    if res.returncode == 0:
        return True

    # 3. Fallback to default IPC call
    cmd_default = [qs_bin, "ipc", "call", target] + args
    res = subprocess.run(cmd_default, capture_output=True, text=True)
    if res.returncode != 0 and res.stderr:
        print(f"Error from quickshell ipc: {res.stderr.strip()}", file=sys.stderr)
    return res.returncode == 0


def kill(args):
    print("Stopping Asura Shell...")
    subprocess.run(["pkill", "-x", "qs"], check=False)
    subprocess.run(["pkill", "-x", "quickshell"], check=False)


def run(args):
    qs_bin = get_quickshell_bin()
    if not qs_bin:
        print("Error: Quickshell is not installed! Neither 'qs' nor 'quickshell' was found in PATH.", file=sys.stderr)
        print("Please install Quickshell (via AUR on Arch or COPR on Fedora).", file=sys.stderr)
        return

    shell_dir = get_shell_dir()
    print("Welcome to Asura Shell! :)")
    subprocess.Popen([qs_bin, "-d", "-p", str(shell_dir)])


def reload(args):
    kill(args)
    run(args)


def update(args):
    print("Updating Asura Shell...")
    asura_dir = Path.home() / ".local/share/asura"
    if asura_dir.exists():
        subprocess.run(["git", "-C", str(asura_dir), "pull"])
    else:
        print(f"Error: Directory {asura_dir} does not exist.", file=sys.stderr)


def doctor(args):
    print(f"Checking Asura Shell dependencies (CLI v{__version__})...")
    checks = {
        "Quickshell": get_quickshell_bin(),
        "Hyprland": shutil.which("hyprland"),
        "Awww": shutil.which("awww") or shutil.which("swww"),
        "Screen Recorder": shutil.which("wf-recorder"),
        "Audio Visualizer": shutil.which("cava"),
        "Kitty": shutil.which("kitty"),
        "Fish": shutil.which("fish"),
        "Starship": shutil.which("starship"),
    }
    for name, path in checks.items():
        status = f"OK ({path})" if path else "MISSING"
        print(f"  [{'✓' if path else '✗'}] {name}: {status}")


def main():
    parser = argparse.ArgumentParser(
        prog="asura",
        description=f"Asura Shell CLI v{__version__}"
    )
    parser.add_argument("-v", "--version", action="version", version=f"asura {__version__}")
    subparsers = parser.add_subparsers(dest="command", help="Subcommands")

    # Lifecycle commands
    p_run = subparsers.add_parser("run", help="Start Asura shell")
    p_run.set_defaults(func=run)

    p_kill = subparsers.add_parser("kill", help="Kill Asura shell")
    p_kill.set_defaults(func=kill)

    p_reload = subparsers.add_parser("reload", help="Restart Asura shell")
    p_reload.set_defaults(func=reload)

    p_update = subparsers.add_parser("update", help="Update Asura shell")
    p_update.set_defaults(func=update)

    p_doctor = subparsers.add_parser("doctor", help="Run diagnostic on Asura shell")
    p_doctor.set_defaults(func=doctor)

    # Shell IPC controls
    p_launcher = subparsers.add_parser("launcher", help="Toggle or control App Launcher")
    p_launcher.add_argument("action", nargs="?", default="toggle", help="Action to execute (default: toggle)")
    p_launcher.set_defaults(func=lambda args: ipc_call("launcher", args.action))

    p_wallpaper = subparsers.add_parser("wallpaper", help="Toggle or control Wallpaper Selector")
    p_wallpaper.add_argument("action", nargs="?", default="toggle", help="Action to execute (default: toggle)")
    p_wallpaper.set_defaults(func=lambda args: ipc_call("wallpaper", args.action))

    p_control = subparsers.add_parser("controlpanel", help="Toggle or control Control Panel")
    p_control.add_argument("action", nargs="?", default="toggle", help="Action to execute (default: toggle)")
    p_control.set_defaults(func=lambda args: ipc_call("controlpanel", args.action))

    p_player = subparsers.add_parser("player", help="Toggle or control Media Player widget")
    p_player.add_argument("action", nargs="?", default="toggle", help="Action to execute (default: toggle)")
    p_player.set_defaults(func=lambda args: ipc_call("player", args.action))

    p_settings = subparsers.add_parser("settings", help="Toggle or control Settings window")
    p_settings.add_argument("action", nargs="?", default="toggle", help="Action to execute (default: toggle)")
    p_settings.set_defaults(func=lambda args: ipc_call("settings", args.action))

    p_clip = subparsers.add_parser("clipboard", help="Toggle or control Clipboard panel")
    p_clip.add_argument("action", nargs="?", default="toggle", help="Action to execute (default: toggle)")
    p_clip.set_defaults(func=lambda args: ipc_call("clipboard", args.action))

    p_lock = subparsers.add_parser("lock", help="Lock screen or toggle lock screen")
    p_lock.add_argument("action", nargs="?", default="toggle", help="Action to execute (default: toggle)")
    p_lock.set_defaults(func=lambda args: ipc_call("lock", args.action))

    p_switcher = subparsers.add_parser("switcher", help="Control window switcher (next, prev, toggle)")
    p_switcher.add_argument("action", nargs="?", default="next", help="Action to execute (default: next)")
    p_switcher.set_defaults(func=lambda args: ipc_call("switcher", args.action))

    p_record = subparsers.add_parser("record", help="Toggle or control Screen Recorder")
    p_record.add_argument("action", nargs="?", default="toggle", choices=["toggle", "start", "stop"], help="Action to execute (default: toggle)")
    p_record.set_defaults(func=lambda args: ipc_call("recorder", args.action))

    p_toggle = subparsers.add_parser("toggle", help="Toggle an Asura shell module")
    p_toggle.add_argument("target", help="Module target name (e.g. launcher, controlpanel, wallpaper)")
    p_toggle.set_defaults(func=lambda args: ipc_call(args.target, "toggle"))

    p_ipc = subparsers.add_parser("ipc", help="Call Quickshell IPC directly")
    p_ipc.add_argument("target", help="IPC target name")
    p_ipc.add_argument("action", nargs="?", default="toggle", help="Function/action to call (default: toggle)")
    p_ipc.add_argument("extra_args", nargs="*", help="Additional arguments")
    p_ipc.set_defaults(func=lambda args: ipc_call(args.target, args.action, *args.extra_args))

    args = parser.parse_args()

    if getattr(args, "func", None):
        args.func(args)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
