#!/usr/bin/env python3
import argparse
import subprocess
import sys
from pathlib import Path

def kill(args):
    print("Goodbye! :(")
    subprocess.run(["pkill", "qs"])
def run(args):
    print("Welcome to Asura Shell! :)")
    subprocess.run(["qs", "-d", "-p", Path.home() / ".local/share/asura/Shell"])

def reload(args):
    subprocess.run(["pkill","qs"])
    run(args)

def update(args):
    print("WIP")
    subprocess.run(["git", "-C", Path.home() / ".local/share/asura", "pull" ])

def doctor(args):
    print("WIP")

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
