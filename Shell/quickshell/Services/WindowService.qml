pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property int gapsIn: 4
    property int gapsOut: 8
    property int singleWindowGapsOut: 8
    property int borderSize: 2
    property int rounding: 15
    property int roundingPower: 2
    property bool shadowEnabled: true
    property int shadowRange: 15
    property int shadowRenderPower: 4
    property real activeOpacity: 1.0
    property real inactiveOpacity: 1.0
    property string layoutMode: "dwindle"
    property bool smartSplit: false

    property bool loading: false
    signal settingsUpdated()

    readonly property string scriptPath: {
        var p = (typeof Quickshell.shellPath === "function")
            ? Quickshell.shellPath("Services/window_manager.py").toString()
            : (Quickshell.env("HOME") + "/.config/quickshell/Services/window_manager.py");
        return p.replace(/^file:\/\//, "").replace(/^file:/, "");
    }

    // Pending payload buffer for debounced updates
    property var pendingUpdates: ({})

    Timer {
        id: debounceTimer
        interval: 40
        repeat: false
        onTriggered: {
            root.dispatchPendingUpdates();
        }
    }

    Process {
        id: getSettingsProc
        command: ["python3", root.scriptPath, "get"]
        running: false

        stdout: SplitParser {
            splitMarker: ""
            onRead: (data) => {
                try {
                    var parsed = JSON.parse(data.trim());
                    if (parsed && typeof parsed === "object") {
                        if (parsed.windowGapsIn !== undefined) root.gapsIn = parsed.windowGapsIn;
                        if (parsed.windowGapsOut !== undefined) root.gapsOut = parsed.windowGapsOut;
                        if (parsed.singleWindowGapsOut !== undefined) root.singleWindowGapsOut = parsed.singleWindowGapsOut;
                        if (parsed.windowBorderSize !== undefined) root.borderSize = parsed.windowBorderSize;
                        if (parsed.windowRounding !== undefined) root.rounding = parsed.windowRounding;
                        if (parsed.windowRoundingPower !== undefined) root.roundingPower = parsed.windowRoundingPower;
                        if (parsed.shadowEnabled !== undefined) root.shadowEnabled = parsed.shadowEnabled;
                        if (parsed.shadowRange !== undefined) root.shadowRange = parsed.shadowRange;
                        if (parsed.shadowRenderPower !== undefined) root.shadowRenderPower = parsed.shadowRenderPower;
                        if (parsed.activeOpacity !== undefined) root.activeOpacity = parsed.activeOpacity;
                        if (parsed.inactiveOpacity !== undefined) root.inactiveOpacity = parsed.inactiveOpacity;
                        if (parsed.layout !== undefined) root.layoutMode = parsed.layout;
                        if (parsed.smartSplit !== undefined) root.smartSplit = parsed.smartSplit;
                        root.settingsUpdated();
                    }
                } catch (e) {
                    console.log("Failed to parse window settings JSON:", e);
                }
                root.loading = false;
            }
        }

        onExited: {
            root.loading = false;
        }
    }

    function refresh() {
        if (getSettingsProc.running) return;
        root.loading = true;
        getSettingsProc.command = ["python3", root.scriptPath, "get"];
        getSettingsProc.running = true;
    }

    function updateSetting(key, val) {
        var obj = {};
        obj[key] = val;
        updateSettings(obj);
    }

    function updateSettings(delta) {
        if (!delta || typeof delta !== "object") return;

        if (delta.windowGapsIn !== undefined) root.gapsIn = delta.windowGapsIn;
        if (delta.windowGapsOut !== undefined) root.gapsOut = delta.windowGapsOut;
        if (delta.singleWindowGapsOut !== undefined) root.singleWindowGapsOut = delta.singleWindowGapsOut;
        if (delta.windowBorderSize !== undefined) root.borderSize = delta.windowBorderSize;
        if (delta.windowRounding !== undefined) root.rounding = delta.windowRounding;
        if (delta.windowRoundingPower !== undefined) root.roundingPower = delta.windowRoundingPower;
        if (delta.shadowEnabled !== undefined) root.shadowEnabled = delta.shadowEnabled;
        if (delta.shadowRange !== undefined) root.shadowRange = delta.shadowRange;
        if (delta.shadowRenderPower !== undefined) root.shadowRenderPower = delta.shadowRenderPower;
        if (delta.activeOpacity !== undefined) root.activeOpacity = delta.activeOpacity;
        if (delta.inactiveOpacity !== undefined) root.inactiveOpacity = delta.inactiveOpacity;
        if (delta.layout !== undefined) root.layoutMode = delta.layout;
        if (delta.smartSplit !== undefined) root.smartSplit = delta.smartSplit;

        for (var k in delta) {
            root.pendingUpdates[k] = delta[k];
        }

        debounceTimer.restart();
    }

    Process {
        id: applySettingsProc
        running: false
        onExited: running = false
    }

    function dispatchPendingUpdates() {
        var payload = root.pendingUpdates;
        root.pendingUpdates = {};

        var keys = Object.keys(payload);
        if (keys.length === 0) return;

        var cmd = [
            "python3",
            root.scriptPath,
            "apply",
            JSON.stringify(payload)
        ];

        if (typeof Quickshell.execDetached === "function") {
            Quickshell.execDetached(cmd);
        } else {
            applySettingsProc.command = cmd;
            applySettingsProc.running = false;
            applySettingsProc.running = true;
        }

        root.settingsUpdated();
    }

    Component.onCompleted: {
        root.refresh();
    }
}
