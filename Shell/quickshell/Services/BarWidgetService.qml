pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services

Singleton {
    id: root

    readonly property var defaultLeft: [
        { "id": "left-1", "type": "launcher", "category": "general_icons", "visible": true },
        { "id": "left-2", "type": "workspaces", "category": "general_icons", "visible": true, "hasBackground": false },
        { "id": "left-cpu", "type": "cpu", "category": "status_capsule", "visible": true },
        { "id": "left-ram", "type": "ram", "category": "status_capsule", "visible": true },
        { "id": "left-gpu", "type": "gpu", "category": "status_capsule", "visible": true },
        { "id": "left-3", "type": "tray", "category": "general_icons", "visible": true, "hasBackground": false }
    ]

    readonly property var defaultCenter: [
        { "id": "center-1", "type": "player", "category": "general_icons", "visible": true, "hasBackground": false }
    ]

    readonly property var defaultRight: [
        { "id": "right-1", "type": "clock", "category": "general_icons", "visible": true, "hasBackground": false },
        { "id": "right-3", "type": "volume", "category": "status_capsule", "visible": true, "hasBackground": true },
        { "id": "right-bluetooth", "type": "bluetooth", "category": "status_capsule", "visible": true },
        { "id": "right-wifi", "type": "wifi", "category": "status_capsule", "visible": true },
        { "id": "right-6", "type": "battery", "category": "status_capsule", "visible": true, "hasBackground": true },
        { "id": "right-7", "type": "power", "category": "general_icons", "visible": true, "hasBackground": false }
    ]

    property var leftWidgets: [
        { "id": "left-1", "type": "launcher", "category": "general_icons", "visible": true },
        { "id": "left-2", "type": "workspaces", "category": "general_icons", "visible": true, "hasBackground": false },
        { "id": "left-cpu", "type": "cpu", "category": "status_capsule", "visible": true },
        { "id": "left-ram", "type": "ram", "category": "status_capsule", "visible": true },
        { "id": "left-gpu", "type": "gpu", "category": "status_capsule", "visible": true },
        { "id": "left-3", "type": "tray", "category": "general_icons", "visible": true, "hasBackground": false }
    ]

    property var centerWidgets: [
        { "id": "center-1", "type": "player", "category": "general_icons", "visible": true, "hasBackground": false }
    ]

    property var rightWidgets: [
        { "id": "right-1", "type": "clock", "category": "general_icons", "visible": true, "hasBackground": false },
        { "id": "right-3", "type": "volume", "category": "status_capsule", "visible": true, "hasBackground": true },
        { "id": "right-bluetooth", "type": "bluetooth", "category": "status_capsule", "visible": true },
        { "id": "right-wifi", "type": "wifi", "category": "status_capsule", "visible": true },
        { "id": "right-6", "type": "battery", "category": "status_capsule", "visible": true, "hasBackground": true },
        { "id": "right-7", "type": "power", "category": "general_icons", "visible": true, "hasBackground": false }
    ]

    readonly property var iconMap: ({
        "window_mode": "\ue66b",
        "keyboard": "\ue312",
        "volume": "\ue050",
        "wifi": "\ue63e",
        "bluetooth": "\ue1a7",
        "battery": "\ue1a3",
        "clipboard": "\ue14f",
        "cpu": "\ue322",
        "ram": "\ue1db",
        "gpu": "\ue30d",
        "launcher": "\ueb9b",
        "workspaces": "\ue9b0",
        "player": "\ue3a1",
        "clock": "\ue192",
        "tray": "\ueb75",
        "power": "\ue8ac",
        "brightness": "\ue1ae",
        "disk": "\ue875",
        "tasks": "\ue85d",
        "dock_to_left": "\uf7e5",
        "align_horizontal_center": "\ue00f",
        "dock_to_right": "\uf7e4",
        "arrow_back": "\ue5c4",
        "arrow_forward": "\ue5c8"
    })

    readonly property var availableWidgets: [
        { "type": "window_mode", "name": "Window Layout", "icon": "\ue66b", "category": "status_capsule", "description": "Switch workspace window tiling layout (scrolling, dwindle, master, monocle)" },
        { "type": "keyboard", "name": "Keyboard Layout", "icon": "\ue312", "category": "status_capsule", "description": "Keyboard language layout indicator and switcher" },
        { "type": "volume", "name": "Volume", "icon": "\ue050", "category": "status_capsule", "description": "Audio output control and menu" },
        { "type": "wifi", "name": "Wi-Fi Network", "icon": "\ue63e", "category": "status_capsule", "description": "Wireless network connections" },
        { "type": "bluetooth", "name": "Bluetooth", "icon": "\ue1a7", "category": "status_capsule", "description": "Bluetooth devices pairing" },
        { "type": "battery", "name": "Battery", "icon": "\ue1a3", "category": "status_capsule", "description": "Power and battery percentage" },
        { "type": "clipboard", "name": "Clipboard", "icon": "\ue14f", "category": "status_capsule", "description": "Clipboard history and manager" },
        { "type": "tasks", "name": "Tasks", "icon": "\ue85d", "category": "status_capsule", "description": "Upcoming and high-priority tasks monitor" },
        { "type": "cpu", "name": "CPU Usage", "icon": "\ue322", "category": "status_capsule", "description": "CPU processor usage monitor" },
        { "type": "ram", "name": "RAM Usage", "icon": "\ue1db", "category": "status_capsule", "description": "RAM memory usage monitor" },
        { "type": "gpu", "name": "GPU Usage", "icon": "\ue30d", "category": "status_capsule", "description": "GPU graphics usage monitor" },
        { "type": "launcher", "name": "App Launcher", "icon": "\ueb9b", "category": "general_icons", "description": "Application launcher and runner" },
        { "type": "workspaces", "name": "Workspaces", "icon": "\ue9b0", "category": "general_icons", "description": "Hyprland workspace switcher" },
        { "type": "player", "name": "Media Player", "icon": "\ue3a1", "category": "general_icons", "description": "Music player and timer controls" },
        { "type": "clock", "name": "Clock", "icon": "\ue192", "category": "general_icons", "description": "Current time and date display" },
        { "type": "tray", "name": "System Tray", "icon": "\ueb75", "category": "general_icons", "description": "Status notifier tray icons" },
        { "type": "power", "name": "Power Button", "icon": "\ue8ac", "category": "general_icons", "description": "Power off, reboot, lock menu" },
        { "type": "brightness", "name": "Brightness", "icon": "\ue1ae", "category": "status_capsule", "description": "Display screen backlight brightness" },
        { "type": "disk", "name": "Disk Usage", "icon": "\ue875", "category": "status_capsule", "description": "Disk storage space usage monitor" }
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
        var fallbackIcon = iconMap[norm] || "\ue1bd";
        return { "type": norm, "name": norm, "icon": fallbackIcon, "category": "general_icons", "description": "" };
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
        var insertIdx = targetList.length;
        if (typeof targetIndex === "number" && targetIndex >= 0) {
            insertIdx = Math.min(targetIndex, targetList.length);
        }
        targetList.splice(insertIdx, 0, foundItem);

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
        if (fromIndex < 0 || fromIndex >= list.length || toIndex < 0 || toIndex > list.length) return;
        if (toIndex === fromIndex || toIndex === fromIndex + 1) return;
        var item = list.splice(fromIndex, 1)[0];
        var insertIdx = toIndex;
        if (toIndex > fromIndex) {
            insertIdx = toIndex - 1;
        }
        if (insertIdx < 0) insertIdx = 0;
        if (insertIdx > list.length) insertIdx = list.length;
        list.splice(insertIdx, 0, item);
        if (zone === "left") leftWidgets = list;
        else if (zone === "center") centerWidgets = list;
        else rightWidgets = list;
        saveConfig();
    }

    function itemHasBackground(item) {
        if (!item) return false;
        if (item.hasBackground !== undefined) return !!item.hasBackground;
        return item.category === "status_capsule";
    }

    function toggleBackground(zone, id) {
        var list = (zone === "left" ? leftWidgets : (zone === "center" ? centerWidgets : rightWidgets)).slice();
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === id) {
                var clone = Object.assign({}, list[i]);
                var hasBg = itemHasBackground(clone);
                clone.hasBackground = !hasBg;
                clone.category = clone.hasBackground ? "status_capsule" : "general_icons";
                list[i] = clone;
                break;
            }
        }
        if (zone === "left") leftWidgets = list;
        else if (zone === "center") centerWidgets = list;
        else rightWidgets = list;
        saveConfig();
    }

    function isTypeCapsule(type) {
        var norm = normalizeType(type);
        var all = [].concat(leftWidgets, centerWidgets, rightWidgets);
        for (var i = 0; i < all.length; i++) {
            if (normalizeType(all[i].type) === norm) {
                return itemHasBackground(all[i]);
            }
        }
        return getWidgetInfo(norm).category === "status_capsule";
    }

    function toggleBackgroundByType(type) {
        var norm = normalizeType(type);
        var zones = [
            { name: "left", getList: function() { return leftWidgets; }, setList: function(l) { leftWidgets = l; } },
            { name: "center", getList: function() { return centerWidgets; }, setList: function(l) { centerWidgets = l; } },
            { name: "right", getList: function() { return rightWidgets; }, setList: function(l) { rightWidgets = l; } }
        ];
        var found = false;
        for (var z = 0; z < zones.length; z++) {
            var list = zones[z].getList().slice();
            var modified = false;
            for (var i = 0; i < list.length; i++) {
                if (normalizeType(list[i].type) === norm) {
                    var clone = Object.assign({}, list[i]);
                    var hasBg = itemHasBackground(clone);
                    clone.hasBackground = !hasBg;
                    clone.category = clone.hasBackground ? "status_capsule" : "general_icons";
                    list[i] = clone;
                    modified = true;
                    found = true;
                }
            }
            if (modified) {
                zones[z].setList(list);
            }
        }
        if (found) {
            saveConfig();
        }
    }

    function dropMove(srcZone, srcIndex, widgetId, dstZone, dstIndex) {
        if (srcZone === dstZone) {
            moveWidget(srcZone, srcIndex, dstIndex);
        } else {
            transferWidget(widgetId, srcZone, dstZone, dstIndex);
        }
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
            var isStatus = itemHasBackground(item);
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
        var pyScript = "import os, json; p = os.path.expanduser('~/.config/asura/bar_widgets.json'); os.makedirs(os.path.dirname(p), exist_ok=True); open(p, 'w').write(" + JSON.stringify(jsonStr) + ")";
        saveProc.command = ["python3", "-c", pyScript];
        saveProc.running = false;
        saveProc.running = true;
    }

    Process {
        id: loadProc
        command: ["python3", "-c", "import os, json; p = os.path.expanduser('~/.config/asura/bar_widgets.json'); print(open(p).read() if os.path.exists(p) else '')"]
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

    function reload() {
        loadProc.running = false;
        loadProc.running = true;
    }
}
