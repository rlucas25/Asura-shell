pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Asura

Item {
    id: root

    property var shortcuts: []
    property var customShortcuts: []
    property var conflicts: []
    property int totalCount: 0
    property int conflictCount: 0
    property bool busy: false

    readonly property string managerPath: (typeof Quickshell.shellPath === "function")
        ? Quickshell.shellPath("Services/shortcuts_manager.py")
        : (Quickshell.env("HOME") + "/.local/share/asura/Shell/quickshell/Services/shortcuts_manager.py")

    signal shortcutsLoaded()

    Component.onCompleted: {
        root.reload();
    }

    Process {
        id: getProcess

        command: ["python3", root.managerPath, "get"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.busy = false;
                try {
                    var data = JSON.parse(this.text);
                    root.shortcuts = data.items || [];
                    root.customShortcuts = data.custom || [];
                    root.conflicts = data.conflicts || [];
                    root.totalCount = data.totalCount || 0;
                    root.conflictCount = data.conflictCount || 0;
                    root.shortcutsLoaded();
                } catch (e) {
                    console.error("ShortcutsService: Failed to parse shortcuts JSON:", e);
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim()) {
                    console.warn("ShortcutsService get stderr:", this.text.trim());
                }
            }
        }
    }

    Process {
        id: actionProcess

        running: false
        onExited: (exitCode, exitStatus) => {
            root.busy = false;
            root.reload();
        }
    }

    function reload() {
        if (root.busy) return;
        root.busy = true;
        getProcess.running = true;
    }

    function setShortcut(varName, chord) {
        if (!varName) return;
        root.busy = true;
        actionProcess.command = ["python3", root.managerPath, "set_var", varName, chord];
        actionProcess.running = true;
    }

    function resetShortcut(varName) {
        if (!varName) return;
        root.busy = true;
        actionProcess.command = ["python3", root.managerPath, "reset_var", varName];
        actionProcess.running = true;
    }

    function resetAllDefaults() {
        root.busy = true;
        actionProcess.command = ["python3", root.managerPath, "reset_all"];
        actionProcess.running = true;
    }

    function saveCustomShortcuts(customList) {
        root.busy = true;
        actionProcess.command = ["python3", root.managerPath, "save_custom", JSON.stringify(customList)];
        actionProcess.running = true;
    }

    function addCustomShortcut(label, chord, action, value) {
        var list = root.customShortcuts.slice();
        var newItem = {
            id: "custom_" + Date.now(),
            label: label || "New Shortcut",
            chord: chord || "SUPER + ALT + X",
            action: action || "exec",
            value: value || "",
            enabled: true
        };
        list.push(newItem);
        root.saveCustomShortcuts(list);
    }

    function updateCustomShortcut(id, label, chord, action, value) {
        var list = root.customShortcuts.slice();
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === id) {
                list[i].label = label;
                list[i].chord = chord;
                list[i].action = action;
                list[i].value = value;
                break;
            }
        }
        root.saveCustomShortcuts(list);
    }

    function deleteCustomShortcut(id) {
        var list = root.customShortcuts.filter(function(item) {
            return item.id !== id;
        });
        root.saveCustomShortcuts(list);
    }

    function toggleCustomShortcut(id) {
        var list = root.customShortcuts.slice();
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === id) {
                list[i].enabled = !list[i].enabled;
                break;
            }
        }
        root.saveCustomShortcuts(list);
    }

    function normalizeChord(chord) {
        if (!chord) return "";
        var parts = chord.replace(/\+/g, " ").trim().split(/\s+/);
        var mods = [];
        var keys = [];
        for (var i = 0; i < parts.length; i++) {
            var p = parts[i].toUpperCase();
            if (p === "SUPER" || p === "SUPER_L" || p === "SUPER_R" || p === "WIN" || p === "MOD4") {
                if (mods.indexOf("SUPER") === -1) mods.push("SUPER");
            } else if (p === "CTRL" || p === "CONTROL" || p === "LCTRL" || p === "RCTRL") {
                if (mods.indexOf("CTRL") === -1) mods.push("CTRL");
            } else if (p === "ALT" || p === "MOD1" || p === "LALT" || p === "RALT") {
                if (mods.indexOf("ALT") === -1) mods.push("ALT");
            } else if (p === "SHIFT" || p === "LSHIFT" || p === "RSHIFT") {
                if (mods.indexOf("SHIFT") === -1) mods.push("SHIFT");
            } else if (p !== "") {
                keys.push(p);
            }
        }
        return mods.concat(keys).join(" + ");
    }

    function isChordConflicting(chord, excludeId) {
        var norm = root.normalizeChord(chord);
        if (!norm) return false;
        var count = 0;
        for (var i = 0; i < root.shortcuts.length; i++) {
            if (root.shortcuts[i].id !== excludeId && root.shortcuts[i].normalized === norm) {
                count++;
            }
        }
        for (var j = 0; j < root.customShortcuts.length; j++) {
            if (root.customShortcuts[j].id !== excludeId && root.customShortcuts[j].enabled !== false && root.customShortcuts[j].normalized === norm) {
                count++;
            }
        }
        return count > 0;
    }
}
