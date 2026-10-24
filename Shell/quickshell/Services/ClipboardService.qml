pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var items: []
    readonly property int count: items.length
    property bool active: false

    signal itemsUpdated()

    readonly property string scriptPath: (typeof Quickshell.shellPath === "function")
        ? Quickshell.shellPath("Services/clipboard_manager.py")
        : (Quickshell.env("HOME") + "/.config/quickshell/Services/clipboard_manager.py")

    Process {
        id: daemonProc
        command: ["python3", root.scriptPath, "daemon"]
        running: true
    }

    Process {
        id: listProc
        command: ["python3", root.scriptPath, "list"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(text.trim());
                        if (Array.isArray(parsed)) {
                            root.items = parsed;
                            root.itemsUpdated();
                        }
                    } catch (e) {
                    }
                }
            }
        }
    }

    Process {
        id: actionProc
        command: []
        onExited: {
            root.refresh();
        }
    }

    function refresh() {
        if (!listProc.running) {
            listProc.running = true;
        }
    }

    function copyItem(id) {
        actionProc.command = ["python3", root.scriptPath, "copy", String(id)];
        actionProc.running = false;
        actionProc.running = true;
    }
        function pasteItem(id) {
        actionProc.command = ["python3", root.scriptPath, "paste", String(id)];
        actionProc.running = false;
        actionProc.running = true;
    }

    function deleteItem(id) {
        actionProc.command = ["python3", root.scriptPath, "delete", String(id)];
        actionProc.running = false;
        actionProc.running = true;
    }

    function clearAll() {
        actionProc.command = ["python3", root.scriptPath, "clear"];
        actionProc.running = false;
        actionProc.running = true;
    }

    Component.onCompleted: {
        root.refresh();
    }

    Component.onDestruction: {
        if (daemonProc.running) {
            daemonProc.kill();
        }
        if (listProc.running) {
            listProc.kill();
        }
    }
}
