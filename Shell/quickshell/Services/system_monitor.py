#!/usr/bin/env python3
import json
import os
import platform
import shutil
import subprocess
import sys
import time

def get_cpu_info():
    model = "CPU"
    cores = 1
    try:
        with open("/proc/cpuinfo") as f:
            lines = f.readlines()
            models = [l.split(":")[1].strip() for l in lines if "model name" in l]
            if models:
                model = models[0]
                cores = len(models)
    except Exception:
        pass

    # CPU usage calculation via /proc/stat with delta caching
    cpu_percent = 0.0
    cache_file = "/dev/shm/qs_stat_cpu"
    now = time.time()
    try:
        with open("/proc/stat") as f:
            fields = [float(column) for column in f.readline().strip().split()[1:]]
        idle_curr, total_curr = fields[3], sum(fields)
        calculated = False

        if os.path.exists(cache_file):
            try:
                with open(cache_file, "r") as cf:
                    prev_time, idle_prev, total_prev = [float(x) for x in cf.read().split()]
                delta_t = now - prev_time
                if 0.3 < delta_t < 10.0:
                    idle_delta = idle_curr - idle_prev
                    total_delta = total_curr - total_prev
                    if total_delta > 0:
                        cpu_percent = 100.0 * (1.0 - idle_delta / total_delta)
                        calculated = True
            except Exception:
                pass

        if not calculated:
            time.sleep(0.05)
            with open("/proc/stat") as f:
                fields2 = [float(column) for column in f.readline().strip().split()[1:]]
            idle2, total2 = fields2[3], sum(fields2)
            idle_delta = idle2 - idle_curr
            total_delta = total2 - total_curr
            if total_delta > 0:
                cpu_percent = 100.0 * (1.0 - idle_delta / total_delta)

        try:
            with open(cache_file, "w") as cf:
                cf.write(f"{now} {idle_curr} {total_curr}")
        except Exception:
            pass
    except Exception:
        pass

    # CPU Temperature
    temp = 45
    try:
        for tpath in ["/sys/class/thermal/thermal_zone0/temp", "/sys/class/hwmon/hwmon0/temp1_input", "/sys/class/hwmon/hwmon1/temp1_input", "/sys/class/hwmon/hwmon2/temp1_input"]:
            if os.path.exists(tpath):
                with open(tpath) as f:
                    raw = int(f.read().strip())
                    temp = round(raw / 1000) if raw > 1000 else raw
                    break
    except Exception:
        pass

    return {
        "model": model,
        "cores": cores,
        "percent": max(0.0, min(100.0, cpu_percent)),
        "temp": temp
    }

def get_mem_info():
    total_gb = 0.0
    used_gb = 0.0
    percent = 0.0
    swap_percent = 0.0
    try:
        with open("/proc/meminfo") as f:
            mem = {}
            for l in f:
                parts = l.split(":")
                if len(parts) == 2:
                    mem[parts[0].strip()] = int(parts[1].split()[0])
        total_kb = mem.get("MemTotal", 1)
        avail_kb = mem.get("MemAvailable", 0)
        used_kb = total_kb - avail_kb
        total_gb = total_kb / (1024 * 1024)
        used_gb = used_kb / (1024 * 1024)
        percent = (used_kb / total_kb) * 100.0

        swap_total = mem.get("SwapTotal", 0)
        swap_free = mem.get("SwapFree", 0)
        if swap_total > 0:
            swap_percent = ((swap_total - swap_free) / swap_total) * 100.0
    except Exception:
        pass

    return {
        "total_gb": round(total_gb, 2),
        "used_gb": round(used_gb, 2),
        "percent": round(max(0.0, min(100.0, percent)), 1),
        "swap_percent": round(max(0.0, min(100.0, swap_percent)), 1)
    }

def get_gpu_info():
    info = {
        "available": False,
        "name": "GPU",
        "percent": 0.0,
        "temp": 0,
        "used_gb": 0.0,
        "total_gb": 0.0
    }
    # Check NVIDIA
    try:
        out = subprocess.check_output(
            ["nvidia-smi", "--query-gpu=name,temperature.gpu,utilization.gpu,memory.used,memory.total", "--format=csv,noheader,nounits"],
            stderr=subprocess.DEVNULL
        ).decode().strip()
        parts = [p.strip() for p in out.split(",")]
        if len(parts) >= 5:
            info["available"] = True
            info["name"] = parts[0]
            info["temp"] = int(parts[1]) if parts[1].isdigit() else 0
            info["percent"] = float(parts[2]) if parts[2].replace(".", "", 1).isdigit() else 0.0
            info["used_gb"] = round(float(parts[3]) / 1024.0, 2)
            info["total_gb"] = round(float(parts[4]) / 1024.0, 2)
            return info
    except Exception:
        pass

    # Check Intel / AMD DRM sysfs
    try:
        for drm in ["/sys/class/drm/card0/device", "/sys/class/drm/card1/device"]:
            busy_path = os.path.join(drm, "gpu_busy_percent")
            if os.path.exists(busy_path):
                with open(busy_path) as f:
                    info["available"] = True
                    info["name"] = "Integrated Graphics"
                    info["percent"] = float(f.read().strip())
                    break
    except Exception:
        pass

    return info

def get_top_procs():
    procs = []
    my_pid = os.getpid()
    parent_pid = os.getppid()
    try:
        out = subprocess.check_output(
            ["ps", "-eo", "pid,comm,%cpu,rss,%mem", "--sort=-%cpu"],
            stderr=subprocess.DEVNULL
        ).decode()
        for l in out.strip().splitlines()[1:]:
            parts = l.split()
            if len(parts) >= 5:
                pid = int(parts[0])
                if pid in (my_pid, parent_pid):
                    continue
                name = " ".join(parts[1:-3])
                if name in ("ps", "system_monitor.py"):
                    continue

                cpu = float(parts[-3])
                rss_kb = int(parts[-2])
                mem_pct = float(parts[-1])
                mem_mb = rss_kb / 1024.0
                if mem_mb >= 1024:
                    mem_str = f"{mem_mb / 1024.0:.1f} GB"
                else:
                    mem_str = f"{int(round(mem_mb))} MB"
                procs.append({
                    "pid": pid,
                    "name": name,
                    "cpu": cpu,
                    "rss_kb": rss_kb,
                    "mem_mb": round(mem_mb, 1),
                    "mem_str": mem_str,
                    "mem": mem_pct
                })
                if len(procs) >= 5:
                    break
    except Exception:
        pass
    return procs

def get_disk_info():
    info = {
        "total_gb": 0.0,
        "used_gb": 0.0,
        "free_gb": 0.0,
        "percent": 0.0
    }
    try:
        st = os.statvfs("/")
        total_b = st.f_blocks * st.f_frsize
        free_b = st.f_bavail * st.f_frsize
        used_b = total_b - free_b
        if total_b > 0:
            total_gb = total_b / (1024**3)
            used_gb = used_b / (1024**3)
            free_gb = free_b / (1024**3)
            percent = (used_b / total_b) * 100.0
            info = {
                "total_gb": round(total_gb, 1),
                "used_gb": round(used_gb, 1),
                "free_gb": round(free_gb, 1),
                "percent": round(max(0.0, min(100.0, percent)), 1)
            }
    except Exception:
        pass
    return info

def get_sys_info():
    cache_file = "/dev/shm/qs_sys_info.json"
    info = {}
    if os.path.exists(cache_file) and (time.time() - os.path.getmtime(cache_file) < 60):
        try:
            with open(cache_file, "r") as f:
                info = json.load(f)
        except Exception:
            pass

    if not info:
        distro = "Linux"
        logo = "linux"
        try:
            with open("/etc/os-release", "r") as f:
                lines = dict(line.strip().split("=", 1) for line in f if "=" in line)
                distro = lines.get("PRETTY_NAME", lines.get("NAME", "Linux")).strip('"')
                logo = lines.get("ID", "linux").strip('"')
        except Exception:
            pass

        kernel = platform.release()
        arch = platform.machine()
        hostname = platform.node()

        wm_version = "Hyprland"
        try:
            res = subprocess.check_output(["hyprctl", "version"], stderr=subprocess.DEVNULL).decode()
            for line in res.splitlines():
                if "Tag:" in line:
                    wm_version = f"Hyprland {line.split(':')[1].strip()}"
                    break
        except Exception:
            pass

        pkg_count = "N/A"
        for pm, cmd in [("pacman", ["pacman", "-Qq"]), ("dpkg", ["dpkg-query", "-f", ".\n", "-W"]), ("rpm", ["rpm", "-qa"])]:
            if shutil.which(pm):
                try:
                    cnt = len(subprocess.check_output(cmd, stderr=subprocess.DEVNULL).splitlines())
                    pkg_count = f"{cnt} ({pm})"
                    break
                except Exception:
                    pass

        user_shell = os.environ.get("SHELL", "/bin/bash").split("/")[-1]

        info = {
            "distro": distro,
            "logo": logo,
            "kernel": kernel,
            "arch": arch,
            "hostname": hostname,
            "wm": wm_version,
            "packages": pkg_count,
            "shell": user_shell
        }
        try:
            with open(cache_file, "w") as f:
                json.dump(info, f)
        except Exception:
            pass

    try:
        with open("/proc/uptime", "r") as f:
            total_seconds = float(f.readline().split()[0])
            hours = int(total_seconds // 3600)
            mins = int((total_seconds % 3600) // 60)
            days = hours // 24
            hours = hours % 24
            if days > 0:
                info["uptime"] = f"{days}d {hours}h {mins}m"
            elif hours > 0:
                info["uptime"] = f"{hours}h {mins}m"
            else:
                info["uptime"] = f"{mins}m"
    except Exception:
        info["uptime"] = "Unknown"

    return info

def main():
    cpu = get_cpu_info()
    mem = get_mem_info()
    gpu = get_gpu_info()
    disk = get_disk_info()
    top_p = get_top_procs()
    sys_i = get_sys_info()

    data = {
        "cpu": cpu,
        "mem": mem,
        "gpu": gpu,
        "disk": disk,
        "top_procs": top_p,
        "sys_info": sys_i
    }
    print(json.dumps(data))

if __name__ == "__main__":
    main()

