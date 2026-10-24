pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Asura

Item {
    id: root

    readonly property bool isBlurEnabled: (Config.cfg && Config.cfg.blurEnabled !== undefined) ? Config.cfg.blurEnabled : true
    readonly property string blurStrength: Config.effectiveBlurStrength

    readonly property string scriptPath: {
        var p = (typeof Quickshell.shellPath === "function")
            ? Quickshell.shellPath("Services/blur_manager.py").toString()
            : (Quickshell.env("HOME") + "/.config/quickshell/Services/blur_manager.py");
        return p.replace(/^file:\/\//, "").replace(/^file:/, "");
    }

    Process {
        id: blurProc
        running: false
        onExited: running = false
    }

    function applyBlur(enabled, strength, customSize, customPasses) {
        var isEn = (enabled !== undefined) ? enabled : root.isBlurEnabled;
        var st = (strength !== undefined) ? strength : root.blurStrength;

        var cmd = ["python3", root.scriptPath, "apply", isEn ? "true" : "false", String(st)];
        if (customSize !== undefined && customSize !== null) {
            cmd.push(String(customSize));
            if (customPasses !== undefined && customPasses !== null) {
                cmd.push(String(customPasses));
            }
        }

        if (typeof Quickshell.execDetached === "function") {
            Quickshell.execDetached(cmd);
        } else {
            blurProc.command = cmd;
            blurProc.running = false;
            blurProc.running = true;
        }
    }

    Component.onCompleted: {
        Qt.callLater(function() {
            root.applyBlur(root.isBlurEnabled, root.blurStrength);
        });
    }

    onIsBlurEnabledChanged: {
        root.applyBlur(root.isBlurEnabled, root.blurStrength);
    }

    onBlurStrengthChanged: {
        root.applyBlur(root.isBlurEnabled, root.blurStrength);
    }
}
