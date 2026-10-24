pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    property string currentLayout: "dwindle"
    property var currentWorkspaceId: 1
    readonly property var availableLayouts: ["scrolling", "dwindle", "master", "monocle"]

    readonly property string helperScriptPath: {
        var p = (typeof Quickshell.shellPath === "function")
            ? Quickshell.shellPath("Services/window_mode_helper.py").toString()
            : (Quickshell.env("HOME") + "/.config/quickshell/Services/window_mode_helper.py");
        return p.replace(/^file:\/\//, "").replace(/^file:/, "");
    }

    readonly property string currentLayoutName: {
        switch (root.currentLayout) {
        case "scrolling":
            return "Scrolling";
        case "dwindle":
            return "Dwindle";
        case "master":
            return "Master";
        case "monocle":
            return "Monocle";
        default:
            return root.currentLayout ? (root.currentLayout.charAt(0).toUpperCase() + root.currentLayout.slice(1)) : "Dwindle";
        }
    }

    readonly property string currentLayoutShort: {
        switch (root.currentLayout) {
        case "scrolling":
            return "SC";
        case "dwindle":
            return "DW";
        case "master":
            return "MS";
        case "monocle":
            return "MO";
        default:
            return root.currentLayout ? root.currentLayout.slice(0, 2).toUpperCase() : "DW";
        }
    }

    readonly property string currentLayoutIcon: {
        switch (root.currentLayout) {
        case "scrolling":
            return "󱂬";
        case "dwindle":
            return "󰕰";
        case "master":
            return "󰕮";
        case "monocle":
            return "󰊓";
        default:
            return "󰕰";
        }
    }

    readonly property string currentLayoutDesc: {
        switch (root.currentLayout) {
        case "scrolling":
            return qsTr("PaperWM column strip");
        case "dwindle":
            return qsTr("Dynamic spiral tree");
        case "master":
            return qsTr("Master & stack columns");
        case "monocle":
            return qsTr("Single window fullscreen");
        default:
            return qsTr("Window organization");
        }
    }

    signal layoutChanged(string layoutName, string layoutIcon)

    onCurrentLayoutChanged: {
        root.layoutChanged(root.currentLayoutName, root.currentLayoutIcon);
    }

    function applyState(layout, wsId) {
        if (layout) {
            root.currentLayout = layout;
        }
        if (wsId !== undefined) {
            root.currentWorkspaceId = wsId;
        }
    }

    function cycleLayout() {
        var idx = availableLayouts.indexOf(root.currentLayout);
        var nextLayout = (idx >= 0) ? availableLayouts[(idx + 1) % availableLayouts.length] : "dwindle";
        root.currentLayout = nextLayout;

        cycleProc.command = ["python3", root.helperScriptPath, "cycle"];
        cycleProc.running = false;
        cycleProc.running = true;
    }

    function setLayout(layoutName) {
        if (!layoutName) return;
        var target = layoutName.toLowerCase().trim();
        root.currentLayout = target;

        setProc.command = ["python3", root.helperScriptPath, "set", target];
        setProc.running = false;
        setProc.running = true;
    }

    function refresh() {
        if (queryProc.running) return;
        queryProc.command = ["python3", root.helperScriptPath, "get"];
        queryProc.running = false;
        queryProc.running = true;
    }

    Process {
        id: cycleProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text && this.text.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(this.text.trim());
                        if (parsed && parsed.layout) {
                            root.applyState(parsed.layout, parsed.workspace);
                        }
                    } catch (e) {
                    }
                }
            }
        }
    }

    Process {
        id: setProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text && this.text.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(this.text.trim());
                        if (parsed && parsed.layout) {
                            root.applyState(parsed.layout, parsed.workspace);
                        }
                    } catch (e) {
                    }
                }
            }
        }
    }

    Process {
        id: queryProc
        command: ["python3", root.helperScriptPath, "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text && this.text.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(this.text.trim());
                        if (parsed && parsed.layout) {
                            root.applyState(parsed.layout, parsed.workspace);
                        }
                    } catch (e) {
                    }
                }
            }
        }
    }

    Timer {
        id: pollTimer
        interval: 1500
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            root.refresh();
        }
    }

    IpcHandler {
        target: "windowmode"

        function cycle() {
            root.cycleLayout();
        }

        function refresh() {
            root.refresh();
        }

        function setLayout(mode: string) {
            root.setLayout(mode);
        }
    }
}
