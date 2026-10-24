pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Asura

Item {
    id: root

    property var categories: []
    property var currentApps: ({})
    property bool loading: false
    property string lastStatus: ""

    signal settingsLoaded()
    signal settingsApplied()

    readonly property string scriptPath: {
        var p = (typeof Quickshell.shellPath === "function")
            ? Quickshell.shellPath("Services/default_apps_manager.py").toString()
            : (Quickshell.env("HOME") + "/.config/quickshell/Services/default_apps_manager.py");
        return p.replace(/^file:\/\//, "").replace(/^file:/, "");
    }

    Timer {
        id: debounceTimer
        interval: 120
        repeat: false
        onTriggered: root.dispatchApply()
    }

    Process {
        id: getProc
        command: ["python3", root.scriptPath, "get"]
        running: false

        stdout: SplitParser {
            splitMarker: ""
            onRead: (data) => {
                try {
                    var parsed = JSON.parse(data.trim());
                    if (parsed && typeof parsed === "object") {
                        if (parsed.current && typeof parsed.current === "object") {
                            root.currentApps = Object.assign({}, parsed.current);
                        }
                        if (parsed.categories && Array.isArray(parsed.categories)) {
                            root.categories = parsed.categories;
                        }
                        root.settingsLoaded();
                    }
                } catch (e) {
                    console.log("Failed to parse default apps get output:", e);
                }
                root.loading = false;
            }
        }

        onExited: {
            root.loading = false;
        }
    }

    Process {
        id: applyProc
        running: false

        stdout: SplitParser {
            splitMarker: ""
            onRead: (data) => {
                try {
                    var parsed = JSON.parse(data.trim());
                    if (parsed && parsed.status === "ok") {
                        root.lastStatus = qsTr("Hyprland variables and default apps updated");
                        root.settingsApplied();
                    }
                } catch (e) {
                    console.log("Failed to parse apply apps output:", e);
                }
                root.loading = false;
            }
        }

        onExited: {
            root.loading = false;
        }
    }

    Process {
        id: launchProc
        running: false
    }

    function loadSettings() {
        if (root.loading) return;
        root.loading = true;
        getProc.command = ["python3", root.scriptPath, "get"];
        getProc.running = false;
        getProc.running = true;
    }

    function setApp(categoryKey, command) {
        if (!categoryKey || command === undefined) return;
        var updated = Object.assign({}, root.currentApps);
        updated[categoryKey] = command.trim();
        root.currentApps = updated;
        debounceTimer.restart();
    }

    function dispatchApply() {
        root.loading = true;
        var payload = JSON.stringify(root.currentApps);
        applyProc.command = [
            "python3",
            root.scriptPath,
            "apply",
            payload
        ];
        applyProc.running = false;
        applyProc.running = true;
    }

    function testLaunch(command) {
        if (!command || !command.trim()) return;
        launchProc.command = [
            "python3",
            root.scriptPath,
            "launch",
            command.trim()
        ];
        launchProc.running = false;
        launchProc.running = true;
    }

    Component.onCompleted: {
        loadSettings();
    }
}
