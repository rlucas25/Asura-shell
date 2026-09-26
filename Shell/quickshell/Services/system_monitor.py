#!/usr/bin/env python3
import json
import os
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

    # CPU usage calculation via /proc/stat
    cpu_percent = 0.0
    try:
        with open("/proc/stat") as f:
            fields = [float(column) for column in f.readline().strip().split()[1:]]
        idle1, total1 = fields[3], sum(fields)
        time.sleep(0.08)
        with open("/proc/stat") as f:
            fields = [float(column) for column in f.readline().strip().split()[1:]]
        idle2, total2 = fields[3], sum(fields)
        idle_delta = idle2 - idle1
        total_delta = total2 - total1
        if total_delta > 0:
            cpu_percent = 100.0 * (1.0 - idle_delta / total_delta)
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
    try:
        out = subprocess.check_output(["ps", "-eo", "comm,%cpu,%mem", "--sort=-%cpu"], stderr=subprocess.DEVNULL).decode()
        lines = out.strip().splitlines()[1:6]
        for l in lines:
            parts = l.split()
            if len(parts) >= 3:
                name = parts[0]
                cpu = float(parts[1])
                mem = float(parts[2])
                procs.append({"name": name, "cpu": cpu, "mem": mem})
    except Exception:
        pass
    return procs

def main():
    cpu = get_cpu_info()
    mem = get_mem_info()
    gpu = get_gpu_info()
    top_p = get_top_procs()

    data = {
        "cpu": cpu,
        "mem": mem,
        "gpu": gpu,
        "top_procs": top_p
    }
    print(json.dumps(data))

if __name__ == "__main__":
    main()
