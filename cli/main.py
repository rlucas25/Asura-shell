#!/usr/bin/env python3
import argparse
import subprocess
import sys
from pathlib import Path

import shutil

def get_quickshell_bin() -> str | None:
    """Find the Quickshell executable ('qs' or 'quickshell')."""
    return shutil.which("qs") or shutil.which("quickshell")


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

    shell_dir = Path.home() / ".local/share/asura/Shell/quickshell"
    if not (shell_dir / "shell.qml").exists():
        shell_dir = Path.home() / ".local/share/asura/Shell"

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
    print("Checking Asura Shell dependencies...")
    checks = {
        "Quickshell": get_quickshell_bin(),
        "Hyprland": shutil.which("hyprland"),
        "Awww": shutil.which("awww"),
        "Kitty": shutil.which("kitty"),
        "Fish": shutil.which("fish"),
        "Starship": shutil.which("starship"),
    }
    for name, path in checks.items():
        status = f"OK ({path})" if path else "MISSING"
        print(f"  [{'✓' if path else '✗'}] {name}: {status}")

def main():
    parser = argparse.ArgumentParser(
        prog = "asura",
        description ="Asura shell cli"
    )
    subparsers = parser.add_subparsers(dest="command", help="Subcommands")    

    # Kill command
    p_kill = subparsers.add_parser("kill", help="Kill Asura shell")
    p_kill.set_defaults(func=kill)

    # Run command
    p_run = subparsers.add_parser("run", help="Start Asura shell")
    p_run.set_defaults(func=run)
    
    # Restart command
    p_reload = subparsers.add_parser("reload", help="Restart Asura shell")
    p_reload.set_defaults(func=reload)
    
    
    # Update command
    p_update = subparsers.add_parser("update", help="Update Asura shell")
    p_update.set_defaults(func=update)


    # Doctor command
    p_doctor = subparsers.add_parser("doctor", help="[WIP] Run diagnostic on Asura shell")
    p_doctor.set_defaults(func=doctor)

    args = parser.parse_args()

    if args.command:
        args.func(args)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
