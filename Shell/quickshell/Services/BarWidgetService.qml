pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services

Singleton {
    id: root

    readonly property var defaultLeft: [
        { "id": "left-1", "type": "launcher", "category": "general_icons", "visible": true },
        { "id": "left-2", "type": "workspaces", "category": "general_icons", "visible": true },
        { "id": "left-3", "type": "tray", "category": "general_icons", "visible": true }
    ]

    readonly property var defaultCenter: [
        { "id": "center-1", "type": "player", "category": "general_icons", "visible": true }
    ]

    readonly property var defaultRight: [
        { "id": "right-1", "type": "clock", "category": "general_icons", "visible": true },
        { "id": "right-2", "type": "clipboard", "category": "status_capsule", "visible": true },
        { "id": "right-3", "type": "volume", "category": "status_capsule", "visible": true },
        { "id": "right-4", "type": "bluetooth", "category": "status_capsule", "visible": true },
        { "id": "right-5", "type": "wifi", "category": "status_capsule", "visible": true },
        { "id": "right-6", "type": "battery", "category": "status_capsule", "visible": true },
        { "id": "right-7", "type": "power", "category": "general_icons", "visible": true }
    ]

    property var leftWidgets: [
        { "id": "left-1", "type": "launcher", "category": "general_icons", "visible": true },
        { "id": "left-2", "type": "workspaces", "category": "general_icons", "visible": true },
        { "id": "left-3", "type": "tray", "category": "general_icons", "visible": true }
    ]

    property var centerWidgets: [
        { "id": "center-1", "type": "player", "category": "general_icons", "visible": true }
    ]

    property var rightWidgets: [
        { "id": "right-1", "type": "clock", "category": "general_icons", "visible": true },
        { "id": "right-2", "type": "clipboard", "category": "status_capsule", "visible": true },
        { "id": "right-3", "type": "volume", "category": "status_capsule", "visible": true },
        { "id": "right-4", "type": "bluetooth", "category": "status_capsule", "visible": true },
        { "id": "right-5", "type": "wifi", "category": "status_capsule", "visible": true },
        { "id": "right-6", "type": "battery", "category": "status_capsule", "visible": true },
        { "id": "right-7", "type": "power", "category": "general_icons", "visible": true }
    ]

    readonly property var availableWidgets: [
        { "type": "volume", "name": "Volume", "icon": "󰕾", "category": "status_capsule", "description": "Audio output control and menu" },
        { "type": "wifi", "name": "Wi-Fi Network", "icon": "󰤨", "category": "status_capsule", "description": "Wireless network connections" },
        { "type": "bluetooth", "name": "Bluetooth", "icon": "󰂯", "category": "status_capsule", "description": "Bluetooth devices pairing" },
        { "type": "battery", "name": "Battery", "icon": "󰁹", "category": "status_capsule", "description": "Power and battery percentage" },
        { "type": "clipboard", "name": "Clipboard", "icon": "󰅌", "category": "status_capsule", "description": "Clipboard history and manager" },
        { "type": "launcher", "name": "App Launcher", "icon": "󱗼", "category": "general_icons", "description": "Application launcher and runner" },
        { "type": "workspaces", "name": "Workspaces", "icon": "󰮯", "category": "general_icons", "description": "Hyprland workspace switcher" },
        { "type": "player", "name": "Media Player", "icon": "󰎆", "category": "general_icons", "description": "Music player and timer controls" },
        { "type": "clock", "name": "Clock", "icon": "󰥔", "category": "general_icons", "description": "Current time and date display" },
        { "type": "tray", "name": "System Tray", "icon": "󱊖", "category": "general_icons", "description": "Status notifier tray icons" },
        { "type": "power", "name": "Power Button", "icon": "󰐥", "category": "general_icons", "description": "Power off, reboot, lock menu" }
    ]

    function generateId() {
        return 'w_' + Date.now().toString(36) + '_' + Math.random().toString(36).substring(2, 9);
    }

    function normalizeType(t) {
        if (!t) return "";
        return t.replace("_widget", "");
    }

    function getWidgetInfo(t) {
        var norm = normalizeType(t);
        for (var i = 0; i < availableWidgets.length; i++) {
            if (availableWidgets[i].type === norm) return availableWidgets[i];
        }
        return { "type": norm, "name": norm, "icon": "󰘔", "category": "general_icons", "description": "" };
    }

    function findWidgetZone(rawType) {
        var t = normalizeType(rawType);
        var checkZone = function(list) {
            for (var i = 0; i < list.length; i++) {
                if (normalizeType(list[i].type) === t && list[i].visible !== false) return true;
            }
            return false;
        };
        if (checkZone(leftWidgets)) return "left";
        if (checkZone(centerWidgets)) return "center";
        if (checkZone(rightWidgets)) return "right";
        var checkAny = function(list) {
            for (var i = 0; i < list.length; i++) {
                if (normalizeType(list[i].type) === t) return true;
            }
            return false;
        };
        if (checkAny(leftWidgets)) return "left";
        if (checkAny(centerWidgets)) return "center";
        if (checkAny(rightWidgets)) return "right";
        return "right";
    }

    function addWidget(zone, type, category) {
        var norm = normalizeType(type);
        var cat = category || (getWidgetInfo(norm).category || "general_icons");
        var item = {
            "id": generateId(),
            "type": norm,
            "category": cat,
            "visible": true
        };
        if (zone === "left") {
            var l = leftWidgets.slice();
            l.push(item);
            leftWidgets = l;
        } else if (zone === "center") {
            var c = centerWidgets.slice();
            c.push(item);
            centerWidgets = c;
        } else {
            var r = rightWidgets.slice();
            r.push(item);
            rightWidgets = r;
        }
        saveConfig();
    }

    function removeWidget(zone, id) {
        var list = (zone === "left" ? leftWidgets : (zone === "center" ? centerWidgets : rightWidgets)).slice();
        var idx = -1;
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === id) {
                idx = i;
                break;
            }
        }
        if (idx !== -1) {
            list.splice(idx, 1);
            if (zone === "left") leftWidgets = list;
            else if (zone === "center") centerWidgets = list;
            else rightWidgets = list;
            saveConfig();
        }
    }

    function toggleVisibility(zone, id) {
        var list = (zone === "left" ? leftWidgets : (zone === "center" ? centerWidgets : rightWidgets)).slice();
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === id) {
                var clone = Object.assign({}, list[i]);
                clone.visible = (clone.visible === undefined) ? false : !clone.visible;
                list[i] = clone;
                break;
            }
        }
        if (zone === "left") leftWidgets = list;
        else if (zone === "center") centerWidgets = list;
        else rightWidgets = list;
        saveConfig();
    }

    function moveWidgetUp(zone, index) {
        if (index <= 0) return;
        var list = (zone === "left" ? leftWidgets : (zone === "center" ? centerWidgets : rightWidgets)).slice();
        var temp = list[index];
        list[index] = list[index - 1];
        list[index - 1] = temp;
        if (zone === "left") leftWidgets = list;
        else if (zone === "center") centerWidgets = list;
        else rightWidgets = list;
        saveConfig();
    }

    function moveWidgetDown(zone, index) {
        var list = (zone === "left" ? leftWidgets : (zone === "center" ? centerWidgets : rightWidgets)).slice();
        if (index < 0 || index >= list.length - 1) return;
        var temp = list[index];
        list[index] = list[index + 1];
        list[index + 1] = temp;
        if (zone === "left") leftWidgets = list;
        else if (zone === "center") centerWidgets = list;
        else rightWidgets = list;
        saveConfig();
    }

    function transferWidget(id, fromZone, toZone, targetIndex) {
        if (fromZone === toZone) return;
        var sourceList = (fromZone === "left" ? leftWidgets : (fromZone === "center" ? centerWidgets : rightWidgets)).slice();
        var foundItem = null;
        for (var i = 0; i < sourceList.length; i++) {
            if (sourceList[i].id === id) {
                foundItem = sourceList.splice(i, 1)[0];
                break;
            }
        }
        if (!foundItem) return;
        var targetList = (toZone === "left" ? leftWidgets : (toZone === "center" ? centerWidgets : rightWidgets)).slice();
        if (typeof targetIndex === "number" && targetIndex >= 0 && targetIndex <= targetList.length) {
            targetList.splice(targetIndex, 0, foundItem);
        } else {
            targetList.push(foundItem);
        }
        if (fromZone === "left") leftWidgets = sourceList;
        else if (fromZone === "center") centerWidgets = sourceList;
        else rightWidgets = sourceList;

        if (toZone === "left") leftWidgets = targetList;
        else if (toZone === "center") centerWidgets = targetList;
        else rightWidgets = targetList;
        saveConfig();
    }

    function moveWidget(zone, fromIndex, toIndex) {
        var list = (zone === "left" ? leftWidgets : (zone === "center" ? centerWidgets : rightWidgets)).slice();
        if (fromIndex < 0 || fromIndex >= list.length || toIndex < 0 || toIndex >= list.length) return;
        var item = list.splice(fromIndex, 1)[0];
        list.splice(toIndex, 0, item);
        if (zone === "left") leftWidgets = list;
        else if (zone === "center") centerWidgets = list;
        else rightWidgets = list;
        saveConfig();
    }

    function resetToDefaults() {
        leftWidgets = JSON.parse(JSON.stringify(defaultLeft));
        centerWidgets = JSON.parse(JSON.stringify(defaultCenter));
        rightWidgets = JSON.parse(JSON.stringify(defaultRight));
        saveConfig();
    }

    function getGroupedWidgets(list) {
        if (!list || !Array.isArray(list)) return [];
        var result = [];
        var currentGroup = [];
        for (var i = 0; i < list.length; i++) {
            var item = list[i];
            if (!item || item.visible === false) continue;
            var isStatus = (item.category === "status_capsule");
            if (isStatus) {
                currentGroup.push(item);
            } else {
                if (currentGroup.length > 0) {
                    result.push({ "isGroup": true, "items": currentGroup });
                    currentGroup = [];
                }
                result.push({ "isGroup": false, "item": item });
            }
        }
        if (currentGroup.length > 0) {
            result.push({ "isGroup": true, "items": currentGroup });
        }
        return result;
    }

    Process {
        id: saveProc
        command: []
    }

    function saveConfig() {
        var data = {
            "left": leftWidgets,
            "center": centerWidgets,
            "right": rightWidgets
        };
        var jsonStr = JSON.stringify(data);
        var pyScript = "import os, json; p = os.path.expanduser('~/.config/quickshell/Asura/config/bar_widgets.json'); os.makedirs(os.path.dirname(p), exist_ok=True); open(p, 'w').write(" + JSON.stringify(jsonStr) + ")";
        saveProc.command = ["python3", "-c", pyScript];
        saveProc.running = false;
        saveProc.running = true;
    }

    Process {
        id: loadProc
        command: ["python3", "-c", "import os, json; p = os.path.expanduser('~/.config/quickshell/Asura/config/bar_widgets.json'); print(open(p).read() if os.path.exists(p) else '')"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text && this.text.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(this.text.trim());
                        if (parsed && typeof parsed === "object") {
                            if (Array.isArray(parsed.left)) root.leftWidgets = parsed.left;
                            if (Array.isArray(parsed.center)) root.centerWidgets = parsed.center;
                            if (Array.isArray(parsed.right)) root.rightWidgets = parsed.right;
                        }
                    } catch (e) {
                        root.resetToDefaults();
                    }
                } else {
                    root.resetToDefaults();
                }
            }
        }
    }
}
