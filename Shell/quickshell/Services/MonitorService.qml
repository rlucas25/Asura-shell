pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var monitors: []
    property string selectedName: ""
    property bool loading: false

    readonly property var selectedMonitor: {
        if (!monitors || monitors.length === 0) return null;
        if (selectedName) {
            for (var i = 0; i < monitors.length; i++) {
                if (monitors[i].name === selectedName) return monitors[i];
            }
        }
        var focused = monitors.find(function(m) { return m.focused; });
        return focused ? focused : monitors[0];
    }

    readonly property string scriptPath: {
        var p = (typeof Quickshell.shellPath === "function")
            ? Quickshell.shellPath("Services/monitor_manager.py").toString()
            : (Quickshell.env("HOME") + "/.config/quickshell/Services/monitor_manager.py");
        return p.replace(/^file:\/\//, "").replace(/^file:/, "");
    }

    signal monitorsUpdated()

    Process {
        id: getMonitorsProc
        command: ["python3", root.scriptPath, "get"]
        running: false

        stdout: SplitParser {
            splitMarker: ""
            onRead: (data) => {
                try {
                    var parsed = JSON.parse(data.trim());
                    if (Array.isArray(parsed) && parsed.length > 0) {
                        root.monitors = parsed;
                        if (!root.selectedName) {
                            var focused = parsed.find(function(m) { return m.focused; });
                            root.selectedName = focused ? focused.name : parsed[0].name;
                        }
                        root.monitorsUpdated();
                    }
                } catch (e) {
                    console.log("Failed to parse monitors JSON:", e);
                }
                root.loading = false;
            }
        }

        onExited: {
            root.loading = false;
        }
    }

    function refresh() {
        if (getMonitorsProc.running) return;
        root.loading = true;
        getMonitorsProc.command = ["python3", root.scriptPath, "get"];
        getMonitorsProc.running = true;
    }

    function selectByName(name) {
        root.selectedName = name;
    }

    function applyMonitor(name, mode, position, scale, transform, vrr) {
        var cmd = [
            "python3",
            root.scriptPath,
            "apply",
            String(name),
            String(mode || "preferred"),
            String(position || "auto"),
            String((scale !== undefined && scale !== null) ? scale : 1.0),
            String(transform || 0),
            vrr ? "true" : "false"
        ];

        if (typeof Quickshell.execDetached === "function") {
            Quickshell.execDetached(cmd);
        }

        if (root.monitors) {
            for (var i = 0; i < root.monitors.length; i++) {
                if (root.monitors[i].name === name) {
                    root.monitors[i].scale = scale;
                    root.monitors[i].transform = transform;
                    root.monitors[i].vrr = vrr;
                    if (mode && mode !== "preferred") {
                        var parts = mode.split("@");
                        if (parts.length > 0) {
                            var wh = parts[0].split("x");
                            if (wh.length === 2) {
                                root.monitors[i].width = parseInt(wh[0]);
                                root.monitors[i].height = parseInt(wh[1]);
                            }
                        }
                        if (parts.length > 1) {
                            var parsedHz = parseFloat(parts[1].replace(/Hz/i, ""));
                            if (!isNaN(parsedHz) && parsedHz > 0) {
                                root.monitors[i].refreshRate = parsedHz;
                            }
                        }
                    }
                    if (position && position !== "auto") {
                        var p = position.split("x");
                        if (p.length === 2) {
                            root.monitors[i].x = parseInt(p[0]);
                            root.monitors[i].y = parseInt(p[1]);
                        }
                    }
                    break;
                }
            }
            root.monitorsUpdated();
        }

        refreshTimer.restart();
    }

    function applyAll(monitorsList) {
        var cmd = [
            "python3",
            root.scriptPath,
            "apply_all",
            JSON.stringify(monitorsList)
        ];

        if (typeof Quickshell.execDetached === "function") {
            Quickshell.execDetached(cmd);
        }

        if (root.monitors && Array.isArray(monitorsList)) {
            for (var m = 0; m < monitorsList.length; m++) {
                var updateItem = monitorsList[m];
                for (var i = 0; i < root.monitors.length; i++) {
                    if (root.monitors[i].name === updateItem.name) {
                        if (updateItem.position && updateItem.position !== "auto") {
                            var p = updateItem.position.split("x");
                            if (p.length === 2) {
                                root.monitors[i].x = parseInt(p[0]);
                                root.monitors[i].y = parseInt(p[1]);
                            }
                        }
                        if (updateItem.scale !== undefined) root.monitors[i].scale = updateItem.scale;
                        if (updateItem.transform !== undefined) root.monitors[i].transform = updateItem.transform;
                        if (updateItem.vrr !== undefined) root.monitors[i].vrr = updateItem.vrr;
                        if (updateItem.mode && updateItem.mode !== "preferred") {
                            var mparts = updateItem.mode.split("@");
                            if (mparts.length > 0) {
                                var mwh = mparts[0].split("x");
                                if (mwh.length === 2) {
                                    root.monitors[i].width = parseInt(mwh[0]);
                                    root.monitors[i].height = parseInt(mwh[1]);
                                }
                            }
                            if (mparts.length > 1) {
                                var mhz = parseFloat(mparts[1].replace(/Hz/i, ""));
                                if (!isNaN(mhz) && mhz > 0) {
                                    root.monitors[i].refreshRate = mhz;
                                }
                            }
                        }
                        break;
                    }
                }
            }
            root.monitorsUpdated();
        }

        refreshTimer.restart();
    }

    function setDpms(name, state) {
        var cmd = ["python3", root.scriptPath, "dpms", String(name), state ? "on" : "off"];
        if (typeof Quickshell.execDetached === "function") {
            Quickshell.execDetached(cmd);
        }
        refreshTimer.restart();
    }

    Timer {
        id: refreshTimer
        interval: 1000
        repeat: false
        onTriggered: root.refresh()
    }

    Component.onCompleted: {
        root.refresh();
    }
}
