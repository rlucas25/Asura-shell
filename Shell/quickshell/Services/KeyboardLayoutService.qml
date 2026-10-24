pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string currentLayout: "Portuguese (Brazil)"
    property string shortLayout: "BR"
    property string mainDevice: ""
    property var availableLayouts: []
    property int currentIndex: 0
    property bool available: false

    signal layoutChanged(string shortCode, string fullName)

    readonly property string watcherScriptPath: (typeof Quickshell.shellPath === "function")
        ? Quickshell.shellPath("Services/keyboard_watcher.py")
        : (Quickshell.env("HOME") + "/.config/quickshell/Services/keyboard_watcher.py")

    function deriveShortLayout(activeKeymap, layoutStr, activeIndex) {
        if (layoutStr) {
            var parts = layoutStr.split(",").map(function(s) { return s.trim(); }).filter(function(s) { return s.length > 0; });
            if (typeof activeIndex === "number" && activeIndex >= 0 && activeIndex < parts.length) {
                var code = parts[activeIndex].split("(")[0].trim().toUpperCase();
                if (code.length >= 1 && code.length <= 3) {
                    return code;
                }
            }
        }
        var km = (activeKeymap || "").toLowerCase().trim();
        var map = {
            "portuguese (brazil)": "BR",
            "portuguese": "PT",
            "english (us)": "US",
            "english (uk)": "UK",
            "spanish": "ES",
            "french": "FR",
            "german": "DE",
            "italian": "IT",
            "russian": "RU",
            "japanese": "JA",
            "korean": "KO",
            "chinese": "ZH"
        };
        if (map[km]) return map[km];
        for (var k in map) {
            if (km.indexOf(k) !== -1) return map[k];
        }
        var match = (activeKeymap || "").match(/\(([^)]+)\)/);
        if (match && match[1]) {
            var inside = match[1].trim().toUpperCase();
            if (inside.length >= 2 && inside.length <= 3) return inside;
        }
        if (activeKeymap && activeKeymap.trim().length >= 2) {
            return activeKeymap.trim().substring(0, 2).toUpperCase();
        }
        return "EN";
    }

    function applyState(name, layout, shortCode, layouts, index) {
        root.mainDevice = name || root.mainDevice;
        root.currentLayout = layout || root.currentLayout;
        root.shortLayout = shortCode || root.deriveShortLayout(layout, (layouts || []).join(","), index);
        root.availableLayouts = layouts || root.availableLayouts;
        root.currentIndex = (typeof index === "number") ? index : root.currentIndex;
        root.available = true;
        root.layoutChanged(root.shortLayout, root.currentLayout);
    }

    function nextLayout() {
        switchProc.command = ["hyprctl", "switchxkblayout", "all", "next"];
        switchProc.running = false;
        switchProc.running = true;
    }

    Process {
        id: switchProc
        command: ["hyprctl", "switchxkblayout", "all", "next"]
        running: false
    }

    Process {
        id: initProc
        command: ["hyprctl", "devices", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var output = this.text ? this.text.trim() : "";
                if (!output) return;
                try {
                    var data = JSON.parse(output);
                    var keyboards = data.keyboards || [];
                    if (!keyboards.length) return;
                    var mainKb = null;
                    for (var i = 0; i < keyboards.length; i++) {
                        if (keyboards[i].main) {
                            mainKb = keyboards[i];
                            break;
                        }
                    }
                    if (!mainKb) {
                        for (var j = 0; j < keyboards.length; j++) {
                            if (keyboards[j].layout) {
                                mainKb = keyboards[j];
                                break;
                            }
                        }
                    }
                    if (!mainKb) mainKb = keyboards[0];
                    var km = mainKb.active_keymap || "";
                    if (km.toLowerCase() === "error") return;
                    var layoutStr = mainKb.layout || "";
                    var idx = mainKb.active_layout_index || 0;
                    var layouts = layoutStr ? layoutStr.split(",").map(function(s) { return s.trim(); }).filter(function(s) { return s.length > 0; }) : [];
                    var shortCode = root.deriveShortLayout(km, layoutStr, idx);
                    root.applyState(mainKb.name || "", km, shortCode, layouts, idx);
                } catch (e) {}
            }
        }
    }

    // Real-time watcher via Hyprland socket2
    Process {
        id: watcherProc
        command: ["python3", root.watcherScriptPath]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var line = data ? data.trim() : "";
                if (!line) return;
                try {
                    var ev = JSON.parse(line);
                    root.applyState(ev.name, ev.layout, ev.short, ev.layouts, ev.index);
                } catch (e) {}
            }
        }
    }

    Component.onDestruction: {
        watcherProc.running = false;
        watcherProc.kill();
    }
}
