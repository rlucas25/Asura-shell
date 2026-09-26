pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool active: false

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

    property var cpuHistory: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    property var ramHistory: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    property var gpuHistory: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    property var topProcs: []

    signal dataUpdated()

    readonly property string scriptPath: (typeof Quickshell.shellPath === "function")
        ? Quickshell.shellPath("Services/system_monitor.py")
        : (Quickshell.env("HOME") + "/.config/quickshell/Services/system_monitor.py")

    Timer {
        id: pollTimer
        interval: 1500
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: {
            if (!monitorProc.running) {
                monitorProc.running = true;
            }
        }
    }

    onActiveChanged: {
        if (active) {
            if (!monitorProc.running) monitorProc.running = true;
        } else {
            if (monitorProc.running) {
                monitorProc.kill();
            }
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
                    if (data.top_procs) {
                        root.topProcs = data.top_procs;
                    }
                    root.dataUpdated();
                } catch (e) {
                    console.warn("SystemMonitorService parse error:", e);
                }
            }
        }
    }

    Component.onDestruction: {
        if (monitorProc.running) {
            monitorProc.kill();
        }
    }
}
