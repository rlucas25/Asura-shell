pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool active: false
    property int subscriberCount: 0
    readonly property bool shouldRun: active || subscriberCount > 0

    function subscribe() {
        subscriberCount++;
    }

    function unsubscribe() {
        if (subscriberCount > 0) {
            subscriberCount--;
        }
    }

    property real cpuPercent: 0.0
    property int cpuTemp: 0
    property string cpuModel: "CPU"
    property int cpuCores: 1

    property real memPercent: 0.0
    property real memUsedGb: 0.0
    property real memTotalGb: 0.0
    property real swapPercent: 0.0

    property bool gpuAvailable: false
    property string gpuName: "GPU"
    property real gpuPercent: 0.0
    property int gpuTemp: 0
    property real gpuUsedGb: 0.0
    property real gpuTotalGb: 0.0

    property real diskPercent: 0.0
    property real diskUsedGb: 0.0
    property real diskTotalGb: 0.0
    property real diskFreeGb: 0.0

    property var cpuHistory: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    property var ramHistory: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    property var gpuHistory: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    property var topProcs: []

    property string distroName: "Linux"
    property string distroLogo: "linux"
    property string kernelVersion: ""
    property string arch: ""
    property string hostName: ""
    property string wmVersion: ""
    property string packageCount: ""
    property string userShell: ""
    property string uptimeStr: ""

    signal dataUpdated()

    function refresh() {
        if (!monitorProc.running) {
            monitorProc.running = true;
        }
    }

    readonly property string scriptPath: (typeof Quickshell.shellPath === "function")
        ? Quickshell.shellPath("Services/system_monitor.py")
        : (Quickshell.env("HOME") + "/.config/quickshell/Services/system_monitor.py")

    Timer {
        id: pollTimer
        interval: root.active ? 1500 : 2000
        repeat: true
        running: root.shouldRun
        triggeredOnStart: true
        onTriggered: {
            if (!monitorProc.running) {
                monitorProc.running = true;
            }
        }
    }

    onShouldRunChanged: {
        if (shouldRun) {
            if (!monitorProc.running) monitorProc.running = true;
        } else {
            monitorProc.running = false;
        }
    }

    Process {
        id: monitorProc
        command: ["python3", root.scriptPath]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "") return;
                try {
                    var data = JSON.parse(text.trim());
                    if (data.cpu) {
                        root.cpuPercent = data.cpu.percent || 0.0;
                        root.cpuTemp = data.cpu.temp || 0;
                        root.cpuModel = data.cpu.model || "CPU";
                        root.cpuCores = data.cpu.cores || 1;

                        var ch = root.cpuHistory.slice(1);
                        ch.push(root.cpuPercent);
                        root.cpuHistory = ch;
                    }
                    if (data.mem) {
                        root.memPercent = data.mem.percent || 0.0;
                        root.memUsedGb = data.mem.used_gb || 0.0;
                        root.memTotalGb = data.mem.total_gb || 0.0;
                        root.swapPercent = data.mem.swap_percent || 0.0;

                        var rh = root.ramHistory.slice(1);
                        rh.push(root.memPercent);
                        root.ramHistory = rh;
                    }
                    if (data.gpu) {
                        root.gpuAvailable = data.gpu.available || false;
                        root.gpuName = data.gpu.name || "GPU";
                        root.gpuPercent = data.gpu.percent || 0.0;
                        root.gpuTemp = data.gpu.temp || 0;
                        root.gpuUsedGb = data.gpu.used_gb || 0.0;
                        root.gpuTotalGb = data.gpu.total_gb || 0.0;

                        var gh = root.gpuHistory.slice(1);
                        gh.push(root.gpuPercent);
                        root.gpuHistory = gh;
                    }
                    if (data.disk) {
                        root.diskPercent = data.disk.percent || 0.0;
                        root.diskUsedGb = data.disk.used_gb || 0.0;
                        root.diskTotalGb = data.disk.total_gb || 0.0;
                        root.diskFreeGb = data.disk.free_gb || 0.0;
                    }
                    if (data.top_procs) {
                        root.topProcs = data.top_procs;
                    }
                    if (data.sys_info) {
                        root.distroName = data.sys_info.distro || "Linux";
                        root.distroLogo = data.sys_info.logo || "linux";
                        root.kernelVersion = data.sys_info.kernel || "";
                        root.arch = data.sys_info.arch || "";
                        root.hostName = data.sys_info.hostname || "";
                        root.wmVersion = data.sys_info.wm || "";
                        root.packageCount = data.sys_info.packages || "";
                        root.userShell = data.sys_info.shell || "";
                        root.uptimeStr = data.sys_info.uptime || "";
                    }
                    root.dataUpdated();
                } catch (e) {
                    console.warn("SystemMonitorService parse error:", e);
                }
            }
        }
    }

    Component.onDestruction: {
        monitorProc.running = false;
    }
}
