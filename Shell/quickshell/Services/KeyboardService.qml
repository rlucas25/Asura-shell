pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var activeLayouts: ["br", "us"]
    property string primaryLayout: "br"
    property string kbOptions: "grp:win_space_toggle"
    property bool numlockByDefault: false
    property int repeatRate: 35
    property int repeatDelay: 250
    property var allAvailableLayouts: []
    property bool loading: false

    property real mouseSensitivity: 0.0
    property string mouseAccelProfile: ""
    property bool mouseNaturalScroll: false
    property bool mouseLeftHanded: false
    property real mouseScrollFactor: 1.0
    property int mouseFollowFocus: 1
    property bool touchpadNaturalScroll: true
    property bool touchpadDisableWhileTyping: true
    property bool touchpadTapToClick: true
    property real touchpadScrollFactor: 0.5
    property bool cursorNoWarps: false

    signal settingsLoaded()
    signal settingsUpdated()

    readonly property string scriptPath: {
        var p = (typeof Quickshell.shellPath === "function")
            ? Quickshell.shellPath("Services/keyboard_manager.py").toString()
            : (Quickshell.env("HOME") + "/.config/quickshell/Services/keyboard_manager.py");
        return p.replace(/^file:\/\//, "").replace(/^file:/, "");
    }

    readonly property string layoutsJsonPath: {
        var p = (typeof Quickshell.shellPath === "function")
            ? Quickshell.shellPath("Services/keyboard_layouts.json").toString()
            : (Quickshell.env("HOME") + "/.config/quickshell/Services/keyboard_layouts.json");
        return p.replace(/^file:\/\//, "").replace(/^file:/, "");
    }

    Timer {
        id: debounceApplyTimer
        interval: 60
        repeat: false
        onTriggered: root.dispatchApply()
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
                        if (parsed.layouts && Array.isArray(parsed.layouts)) {
                            root.activeLayouts = parsed.layouts.slice();
                            root.primaryLayout = parsed.primaryLayout || (parsed.layouts[0] || "us");
                        }
                        if (parsed.kbOptions !== undefined) root.kbOptions = parsed.kbOptions;
                        if (parsed.numlockByDefault !== undefined) root.numlockByDefault = parsed.numlockByDefault;
                        if (parsed.repeatRate !== undefined) root.repeatRate = parsed.repeatRate;
                        if (parsed.repeatDelay !== undefined) root.repeatDelay = parsed.repeatDelay;

                        if (parsed.mouseSensitivity !== undefined) root.mouseSensitivity = parsed.mouseSensitivity;
                        if (parsed.mouseAccelProfile !== undefined) root.mouseAccelProfile = parsed.mouseAccelProfile;
                        if (parsed.mouseNaturalScroll !== undefined) root.mouseNaturalScroll = parsed.mouseNaturalScroll;
                        if (parsed.mouseLeftHanded !== undefined) root.mouseLeftHanded = parsed.mouseLeftHanded;
                        if (parsed.mouseScrollFactor !== undefined) root.mouseScrollFactor = parsed.mouseScrollFactor;
                        if (parsed.mouseFollowFocus !== undefined) root.mouseFollowFocus = parsed.mouseFollowFocus;
                        if (parsed.touchpadNaturalScroll !== undefined) root.touchpadNaturalScroll = parsed.touchpadNaturalScroll;
                        if (parsed.touchpadDisableWhileTyping !== undefined) root.touchpadDisableWhileTyping = parsed.touchpadDisableWhileTyping;
                        if (parsed.touchpadTapToClick !== undefined) root.touchpadTapToClick = parsed.touchpadTapToClick;
                        if (parsed.touchpadScrollFactor !== undefined) root.touchpadScrollFactor = parsed.touchpadScrollFactor;
                        if (parsed.cursorNoWarps !== undefined) root.cursorNoWarps = parsed.cursorNoWarps;

                        if (parsed.allAvailableLayouts && Array.isArray(parsed.allAvailableLayouts)) {
                            root.allAvailableLayouts = parsed.allAvailableLayouts;
                        }
                        root.settingsLoaded();
                    }
                } catch (e) {
                    console.log("Failed to parse keyboard & mouse settings JSON:", e);
                }
                root.loading = false;
            }
        }

        onExited: {
            root.loading = false;
        }
    }

    Process {
        id: applySettingsProc
        running: false
        onExited: running = false
    }

    function loadSettings() {
        if (root.loading) return;
        root.loading = true;
        getSettingsProc.command = ["python3", root.scriptPath, "get"];
        getSettingsProc.running = true;
    }

    function isLayoutActive(code) {
        if (!code) return false;
        var c = code.toLowerCase().trim();
        for (var i = 0; i < root.activeLayouts.length; i++) {
            if (String(root.activeLayouts[i]).toLowerCase().trim() === c) return true;
        }
        return false;
    }

    function getLayoutObject(code) {
        if (!code) return null;
        var c = code.toLowerCase().trim();
        for (var i = 0; i < root.allAvailableLayouts.length; i++) {
            if (root.allAvailableLayouts[i].code.toLowerCase() === c) {
                return root.allAvailableLayouts[i];
            }
        }
        return {
            "code": code,
            "name": code.toUpperCase(),
            "flag": "🌐"
        };
    }

    function getLayoutName(code) {
        var obj = getLayoutObject(code);
        return obj ? obj.name : (code ? code.toUpperCase() : "");
    }

    function getLayoutFlag(code) {
        var obj = getLayoutObject(code);
        return obj ? obj.flag : "🌐";
    }

    function addLayout(code) {
        if (!code || isLayoutActive(code)) return;
        var updated = root.activeLayouts.slice();
        updated.push(code.trim());
        root.activeLayouts = updated;
        root.primaryLayout = updated[0];
        root.queueApply();
    }

    function removeLayout(code) {
        if (root.activeLayouts.length <= 1) return; // Prevent removing last layout
        var updated = [];
        for (var i = 0; i < root.activeLayouts.length; i++) {
            if (root.activeLayouts[i].toLowerCase() !== code.toLowerCase()) {
                updated.push(root.activeLayouts[i]);
            }
        }
        root.activeLayouts = updated;
        root.primaryLayout = updated[0];
        root.queueApply();
    }

    function makePrimary(code) {
        if (!code || root.activeLayouts.length === 0) return;
        var c = code.toLowerCase().trim();
        if (root.activeLayouts[0].toLowerCase() === c) return; // Already primary

        var updated = [code];
        for (var i = 0; i < root.activeLayouts.length; i++) {
            if (root.activeLayouts[i].toLowerCase() !== c) {
                updated.push(root.activeLayouts[i]);
            }
        }
        root.activeLayouts = updated;
        root.primaryLayout = code;
        root.queueApply();
    }

    function moveUp(index) {
        if (index <= 0 || index >= root.activeLayouts.length) return;
        var updated = root.activeLayouts.slice();
        var temp = updated[index];
        updated[index] = updated[index - 1];
        updated[index - 1] = temp;
        root.activeLayouts = updated;
        root.primaryLayout = updated[0];
        root.queueApply();
    }

    function moveDown(index) {
        if (index < 0 || index >= root.activeLayouts.length - 1) return;
        var updated = root.activeLayouts.slice();
        var temp = updated[index];
        updated[index] = updated[index + 1];
        updated[index + 1] = temp;
        root.activeLayouts = updated;
        root.primaryLayout = updated[0];
        root.queueApply();
    }

    function setKbOption(opt) {
        if (root.kbOptions === opt) return;
        root.kbOptions = opt;
        root.queueApply();
    }

    function setNumlock(enabled) {
        if (root.numlockByDefault === enabled) return;
        root.numlockByDefault = enabled;
        root.queueApply();
    }

    function setRepeat(rate, delay) {
        root.repeatRate = rate;
        root.repeatDelay = delay;
        root.queueApply();
    }

    function setMouseSensitivity(val) {
        root.mouseSensitivity = Math.round(val * 100) / 100;
        root.queueApply();
    }

    function setMouseAccelProfile(val) {
        root.mouseAccelProfile = val;
        root.queueApply();
    }

    function setMouseNaturalScroll(val) {
        root.mouseNaturalScroll = val;
        root.queueApply();
    }

    function setMouseLeftHanded(val) {
        root.mouseLeftHanded = val;
        root.queueApply();
    }

    function setMouseScrollFactor(val) {
        root.mouseScrollFactor = Math.round(val * 10) / 10;
        root.queueApply();
    }

    function setMouseFollowFocus(val) {
        root.mouseFollowFocus = val;
        root.queueApply();
    }

    function setTouchpadNaturalScroll(val) {
        root.touchpadNaturalScroll = val;
        root.queueApply();
    }

    function setTouchpadDisableWhileTyping(val) {
        root.touchpadDisableWhileTyping = val;
        root.queueApply();
    }

    function setTouchpadTapToClick(val) {
        root.touchpadTapToClick = val;
        root.queueApply();
    }

    function setTouchpadScrollFactor(val) {
        root.touchpadScrollFactor = Math.round(val * 10) / 10;
        root.queueApply();
    }

    function setCursorNoWarps(val) {
        root.cursorNoWarps = val;
        root.queueApply();
    }

    function queueApply() {
        debounceApplyTimer.restart();
    }

    function dispatchApply() {
        var payload = {
            "layouts": root.activeLayouts,
            "kbOptions": root.kbOptions,
            "numlockByDefault": root.numlockByDefault,
            "repeatRate": root.repeatRate,
            "repeatDelay": root.repeatDelay,
            "mouseSensitivity": root.mouseSensitivity,
            "mouseAccelProfile": root.mouseAccelProfile,
            "mouseNaturalScroll": root.mouseNaturalScroll,
            "mouseLeftHanded": root.mouseLeftHanded,
            "mouseScrollFactor": root.mouseScrollFactor,
            "mouseFollowFocus": root.mouseFollowFocus,
            "touchpadNaturalScroll": root.touchpadNaturalScroll,
            "touchpadDisableWhileTyping": root.touchpadDisableWhileTyping,
            "touchpadTapToClick": root.touchpadTapToClick,
            "touchpadScrollFactor": root.touchpadScrollFactor,
            "cursorNoWarps": root.cursorNoWarps
        };

        var cmd = [
            "python3",
            root.scriptPath,
            "apply",
            JSON.stringify(payload)
        ];

        applySettingsProc.command = cmd;
        applySettingsProc.running = false;
        applySettingsProc.running = true;
        root.settingsUpdated();
    }

    Component.onCompleted: {
        loadSettings();
    }
}
