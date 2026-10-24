pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Asura
import qs.Services

Item {
    id: root

    property var presets: []
    property string activePresetId: ""
    property bool loading: false
    property string lastStatusMessage: ""

    signal presetsLoaded()
    signal presetApplied(string presetId, string name)
    signal presetSaved(string presetId, string name)
    signal presetDeleted(string presetId)

    readonly property string scriptPath: {
        var p = (typeof Quickshell.shellPath === "function")
            ? Quickshell.shellPath("Services/preset_manager.py").toString()
            : (Quickshell.env("HOME") + "/.config/quickshell/Services/preset_manager.py");
        return p.replace(/^file:\/\//, "").replace(/^file:/, "");
    }

    Process {
        id: listProc
        command: ["python3", root.scriptPath, "list"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                var out = this.text || text || "";
                if (out && out.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(out.trim());
                        if (Array.isArray(parsed)) {
                            root.presets = parsed;
                            root.presetsLoaded();
                        }
                    } catch (e) {
                        console.log("Failed to parse presets list JSON:", e);
                    }
                }
                root.loading = false;
            }
        }

        onExited: {
            root.loading = false;
        }
    }

    Process {
        id: actionProc
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                var out = this.text || text || "";
                if (out && out.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(out.trim());
                        if (parsed && typeof parsed === "object") {
                            if (parsed.status === "ok") {
                                if (parsed.appliedId) {
                                    root.activePresetId = parsed.appliedId;
                                    root.lastStatusMessage = qsTr("Preset applied successfully");
                                    if (typeof Config !== "undefined" && typeof Config.reload === "function") {
                                        Config.reload();
                                    }
                                    if (typeof Colors !== "undefined" && typeof Colors.reload === "function") {
                                        Colors.reload();
                                    }
                                    if (typeof BarWidgetService !== "undefined" && typeof BarWidgetService.reload === "function") {
                                        BarWidgetService.reload();
                                    }
                                    if (typeof WindowService !== "undefined" && typeof WindowService.refresh === "function") {
                                        WindowService.refresh();
                                    }
                                    if (typeof MonitorService !== "undefined" && typeof MonitorService.refresh === "function") {
                                        MonitorService.refresh();
                                    }
                                    if (typeof KeyboardService !== "undefined" && typeof KeyboardService.loadSettings === "function") {
                                        KeyboardService.loadSettings();
                                    }
                                    if (typeof ShortcutsService !== "undefined" && typeof ShortcutsService.reload === "function") {
                                        ShortcutsService.reload();
                                    }
                                    Qt.callLater(function() {
                                        if (typeof Colors !== "undefined" && typeof Colors.applyTemplates === "function") {
                                            Colors.applyTemplates();
                                        }
                                    });
                                    root.presetApplied(parsed.appliedId, parsed.name || "");
                                } else if (parsed.deletedId) {
                                    if (root.activePresetId === parsed.deletedId) {
                                        root.activePresetId = "";
                                    }
                                    root.lastStatusMessage = qsTr("Preset deleted successfully");
                                    var remaining = (root.presets || []).filter(function(p) { return p && p.id !== parsed.deletedId; });
                                    root.presets = remaining;
                                    root.presetDeleted(parsed.deletedId);
                                } else if (parsed.preset) {
                                    root.lastStatusMessage = qsTr("Preset saved successfully");
                                    var current = (root.presets || []).filter(function(p) { return p && p.id !== parsed.preset.id; });
                                    current.unshift(parsed.preset);
                                    root.presets = current;
                                    root.presetSaved(parsed.preset.id, parsed.preset.name);
                                }
                            } else if (parsed.message) {
                                root.lastStatusMessage = parsed.message;
                            }
                        }
                    } catch (e) {
                        console.log("Preset action stdout parse error:", e);
                    }
                }
                root.loading = false;
                root.loadPresets();
            }
        }

        onExited: {
            root.loading = false;
            root.loadPresets();
        }
    }

    function loadPresets() {
        if (listProc.running) return;
        root.loading = true;
        listProc.command = ["python3", root.scriptPath, "list"];
        listProc.running = true;
    }

    function saveCurrentPreset(name, tabs) {
        root.loading = true;
        if (typeof Config !== "undefined" && typeof Config.save === "function") {
            Config.save();
        }
        var payload = {
            "name": name ? name.trim() : "",
            "tabs": (tabs && Array.isArray(tabs)) ? tabs : ["theme", "general", "windows", "bar", "launcher", "apptheming"]
        };
        actionProc.command = [
            "python3",
            root.scriptPath,
            "save",
            JSON.stringify(payload)
        ];
        actionProc.running = false;
        actionProc.running = true;
    }

    function overwritePreset(presetId, tabs) {
        if (!presetId) return;
        root.loading = true;
        if (typeof Config !== "undefined" && typeof Config.save === "function") {
            Config.save();
        }
        var payload = {
            "id": presetId
        };
        if (tabs && Array.isArray(tabs)) {
            payload["tabs"] = tabs;
        }
        actionProc.command = [
            "python3",
            root.scriptPath,
            "overwrite",
            JSON.stringify(payload)
        ];
        actionProc.running = false;
        actionProc.running = true;
    }

    function applyPreset(presetId) {
        if (!presetId) return;
        root.loading = true;
        actionProc.command = [
            "python3",
            root.scriptPath,
            "apply",
            presetId
        ];
        actionProc.running = false;
        actionProc.running = true;
    }

    function deletePreset(presetId) {
        if (!presetId) return;
        root.loading = true;
        actionProc.command = [
            "python3",
            root.scriptPath,
            "delete",
            presetId
        ];
        actionProc.running = false;
        actionProc.running = true;
    }

    Component.onCompleted: {
        loadPresets();
    }
}
