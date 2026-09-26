pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Singleton {
    id: root

    property var openSources: []
    readonly property bool hasOpenMenu: openSources.length > 0

    signal closeAllRequested()
    signal toggleLauncherRequested(string monitorName)
    signal toggleWallpaperRequested(string monitorName)
    signal toggleMainMenuRequested(string monitorName)
    signal togglePlayerRequested(string monitorName)
    signal toggleRightMenuRequested(string menuType, string monitorName)

    function registerMenuOpen(source) {
        var list = openSources.slice();
        for (var i = 0; i < list.length; i++) {
            if (list[i] !== source && list[i]) {
                if (typeof list[i].closeMenus === "function")
                    list[i].closeMenus();
                else if (typeof list[i].close === "function")
                    list[i].close();
            }
        }
        openSources = [source];
    }

    function unregisterMenuOpen(source) {
        var list = openSources.slice();
        var idx = list.indexOf(source);
        if (idx !== -1) {
            list.splice(idx, 1);
            openSources = list;
        }
    }

    function closeAll() {
        openSources = [];
        closeAllRequested();
    }

    function getFocusedMonitorName() {
        return (Hyprland.focusedMonitor && Hyprland.focusedMonitor.name) ? Hyprland.focusedMonitor.name : "";
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            if (root.hasOpenMenu)
                root.closeAll();
        }
        function onFocusedMonitorChanged() {
            if (root.hasOpenMenu)
                root.closeAll();
        }
    }

    IpcHandler {
        target: "launcher"
        function toggle() { root.toggleLauncherRequested(root.getFocusedMonitorName()); }
        function open() { root.toggleLauncherRequested(root.getFocusedMonitorName()); }
        function close() { root.closeAll(); }
    }

    IpcHandler {
        target: "wallpaper"
        function toggle() { root.toggleWallpaperRequested(root.getFocusedMonitorName()); }
        function open() { root.toggleWallpaperRequested(root.getFocusedMonitorName()); }
        function close() { root.closeAll(); }
    }

    IpcHandler {
        target: "mainmenu"
        function toggle() { root.toggleMainMenuRequested(root.getFocusedMonitorName()); }
        function open() { root.toggleMainMenuRequested(root.getFocusedMonitorName()); }
        function close() { root.closeAll(); }
    }

    IpcHandler {
        target: "player"
        function toggle() { root.togglePlayerRequested(root.getFocusedMonitorName()); }
        function open() { root.togglePlayerRequested(root.getFocusedMonitorName()); }
        function close() { root.closeAll(); }
    }

    IpcHandler {
        target: "wifi"
        function toggle() { root.toggleRightMenuRequested("wifi", root.getFocusedMonitorName()); }
        function open() { root.toggleRightMenuRequested("wifi", root.getFocusedMonitorName()); }
        function close() { root.closeAll(); }
    }

    IpcHandler {
        target: "bluetooth"
        function toggle() { root.toggleRightMenuRequested("bluetooth", root.getFocusedMonitorName()); }
        function open() { root.toggleRightMenuRequested("bluetooth", root.getFocusedMonitorName()); }
        function close() { root.closeAll(); }
    }

    IpcHandler {
        target: "battery"
        function toggle() { root.toggleRightMenuRequested("battery", root.getFocusedMonitorName()); }
        function open() { root.toggleRightMenuRequested("battery", root.getFocusedMonitorName()); }
        function close() { root.closeAll(); }
    }

    IpcHandler {
        target: "power"
        function toggle() { root.toggleRightMenuRequested("power", root.getFocusedMonitorName()); }
        function open() { root.toggleRightMenuRequested("power", root.getFocusedMonitorName()); }
        function close() { root.closeAll(); }
    }

    IpcHandler {
        target: "volume"
        function toggle() { root.toggleRightMenuRequested("volume", root.getFocusedMonitorName()); }
        function open() { root.toggleRightMenuRequested("volume", root.getFocusedMonitorName()); }
        function close() { root.closeAll(); }
    }

    IpcHandler {
        target: "clipboardBar"
        function toggle() { root.toggleRightMenuRequested("clipboard", root.getFocusedMonitorName()); }
        function open() { root.toggleRightMenuRequested("clipboard", root.getFocusedMonitorName()); }
        function close() { root.closeAll(); }
    }
}
