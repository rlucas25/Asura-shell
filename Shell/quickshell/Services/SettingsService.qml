pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Asura

Item {
    id: root

    property bool isOpen: false
    property string currentTab: "general"
    property bool pendingKeyRecorder: false
    property var activeWindow: null

    signal keyRecorderRequested()

    Timer {
        id: closeSafetyTimer
        interval: 600
        repeat: false
        onTriggered: {
            if (root.isOpen && (!root.activeWindow || !root.activeWindow.visible)) {
                root.forceClose();
            }
        }
    }

    function open(tabName) {
        closeSafetyTimer.stop();
        if (tabName && typeof tabName === "string" && tabName.length > 0) {
            root.currentTab = tabName;
        }
        if (root.isOpen && root.activeWindow) {
            if (typeof root.activeWindow.openTab === "function") {
                root.activeWindow.openTab(root.currentTab);
            }
            if (root.activeWindow.focusTimer) {
                root.activeWindow.focusTimer.restart();
            }
            return;
        }
        root.isOpen = true;
    }

    function close() {
        closeSafetyTimer.restart();
        if (root.activeWindow && typeof root.activeWindow.closeWindow === "function" && root.isOpen) {
            root.activeWindow.closeWindow();
        } else {
            root.forceClose();
        }
    }

    function forceClose() {
        closeSafetyTimer.stop();
        root.isOpen = false;
        root.activeWindow = null;
    }

    function toggle() {
        if (root.isOpen) {
            if (root.activeWindow && root.activeWindow.isClosing) {
                root.open();
                return;
            }
            root.close();
        } else {
            root.open();
        }
    }

    function openTab(tabName) {
        root.open(tabName);
    }

    function openKeyRecorder() {
        root.currentTab = "shortcuts";
        if (root.isOpen && root.activeWindow) {
            if (typeof root.activeWindow.openKeyRecorder === "function") {
                root.activeWindow.openKeyRecorder({
                    id: "new",
                    label: "Custom Hotkey",
                    chord: "SUPER + ALT + K",
                    action: "exec",
                    value: "kitty",
                    isCustom: true
                });
            }
        } else {
            root.pendingKeyRecorder = true;
            root.open("shortcuts");
        }
    }

    function toggleAppHidden(appId) {
        if (!appId || !Config.cfg) return;
        var norm = String(appId).trim().replace(/\.desktop$/i, "");
        var list = (Config.cfg.launcherHiddenApps && Array.isArray(Config.cfg.launcherHiddenApps))
            ? Config.cfg.launcherHiddenApps.slice()
            : [];
        var idx = -1;
        for (var i = 0; i < list.length; i++) {
            if (String(list[i]).trim().replace(/\.desktop$/i, "") === norm) {
                idx = i;
                break;
            }
        }
        if (idx !== -1) {
            list.splice(idx, 1);
        } else {
            list.push(norm);
        }
        Config.cfg.launcherHiddenApps = list;
        Config.save();
    }

    function unhideAllApps() {
        if (Config.cfg) {
            Config.cfg.launcherHiddenApps = [];
            Config.save();
        }
    }

    function toggleTemplate(tplName) {
        if (!tplName || !Config.cfg) return;
        var list = (Config.cfg.disabledTemplates && Array.isArray(Config.cfg.disabledTemplates))
            ? Config.cfg.disabledTemplates.slice()
            : [];
        var idx = list.indexOf(tplName);
        if (idx !== -1) {
            list.splice(idx, 1);
        } else {
            list.push(tplName);
        }
        Config.cfg.disabledTemplates = list;
        Config.save();
    }

    function applyTemplatesNow() {
        applyTemplatesProc.running = false;
        applyTemplatesProc.running = true;
    }

    Process {
        id: applyTemplatesProc
        command: ["/usr/bin/bash", (typeof Quickshell.shellPath === "function") ? Quickshell.shellPath("scripts/colors/switchwall.sh") : (Quickshell.env("HOME") + "/.config/quickshell/scripts/colors/switchwall.sh")]
        running: false
    }

    Connections {
        target: MenuService
        function onOpenSettingsTabRequested(tabName) {
            root.openTab(tabName);
        }
    }

    IpcHandler {
        target: "settings"

        function toggle() {
            root.toggle();
        }

        function open() {
            root.open();
        }

        function openTab(tabName: string) {
            root.openTab(tabName);
        }

        function search(query: string) {
            root.open();
            if (root.activeWindow && typeof root.activeWindow.setSearchQuery === "function") {
                root.activeWindow.setSearchQuery(query);
            }
        }

        function openKeyRecorder() {
            root.openKeyRecorder();
        }

        function close() {
            root.close();
        }

        function reload() {
            Quickshell.reload(true);
        }

        function toggleAppHidden(appId: string) {
            root.toggleAppHidden(appId);
        }

        function unhideAllApps() {
            root.unhideAllApps();
        }

        function scrollTo(y: real) {
            if (root.activeWindow && typeof root.activeWindow.scrollTo === "function") {
                root.activeWindow.scrollTo(y);
            }
        }

        function setClockFormat(fmt: string) {
            Config.cfg.clockFormat = fmt;
            Config.save();
        }

        function setClock24h(val: bool) {
            Config.cfg.clock24h = val;
            Config.save();
        }

        function setWeekStartsOnMonday(val: bool) {
            Config.cfg.weekStartsOnMonday = val;
            Config.save();
        }

        function setHardwareHidePercent(val: bool) {
            Config.cfg.hardwareHidePercent = val;
            Config.save();
        }

        function setHardwareShowAbsolute(val: bool) {
            Config.cfg.hardwareShowAbsolute = val;
            Config.save();
        }

        function setBarWidgetHoverTextEnabled(val: bool) {
            Config.cfg.barWidgetHoverTextEnabled = val;
            Config.save();
        }

        function setBarHoverMenusEnabled(val: bool) {
            Config.cfg.barHoverMenusEnabled = val;
            Config.save();
        }

        function setAppTheming(val: bool) {
            Config.cfg.appThemingEnabled = val;
            Config.save();
        }

        function toggleTemplate(name: string) {
            root.toggleTemplate(name);
        }

        function applyTemplates() {
            root.applyTemplatesNow();
        }
    }
}
