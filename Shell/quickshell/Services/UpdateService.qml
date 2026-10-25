pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Asura

Item {
    id: root

    property string currentVersion: "v0.1.2"
    property string latestVersion: "v0.1.2"
    property bool updateAvailable: false
    property bool checking: false
    property bool updating: false
    property string statusMessage: qsTr("System is up to date")
    property double lastCheckTimestamp: 0
    property string lastCheckStr: ""
    property bool lastCheckWasAuto: false

    signal checkFinished(bool success, bool available)
    signal updateFinished(bool success, string message)

    readonly property string asuraBin: {
        var home = Quickshell.env("HOME") || "";
        return home + "/.local/bin/asura";
    }

    // Delayed initial check on shell startup (8s after launch to avoid startup lag)
    Timer {
        id: startupTimer
        interval: 8000
        repeat: false
        running: true
        onTriggered: {
            root.checkForUpdates(false, true);
        }
    }

    // Periodic check every 12 hours (lightweight; hits 24h cache or queries tiny raw version)
    Timer {
        id: periodicTimer
        interval: 12 * 60 * 60 * 1000
        repeat: true
        running: true
        onTriggered: {
            root.checkForUpdates(false, true);
        }
    }

    // Smooth shell reload after successful update
    Timer {
        id: reloadShellTimer
        interval: 1400
        repeat: false
        onTriggered: {
            Quickshell.reload(true);
        }
    }

    Process {
        id: checkProc
        command: [root.asuraBin, "update", "--check", "--json"]
        running: false

        stdout: SplitParser {
            splitMarker: ""
            onRead: (data) => {
                root.parseCheckOutput(data);
            }
        }

        stderr: SplitParser {
            splitMarker: ""
            onRead: (data) => {
                if (data && data.trim().length > 0) {
                    console.log("[UpdateService] check warning/stderr:", data.trim());
                }
            }
        }

        onExited: (exitCode) => {
            root.checking = false;
        }
    }

    Process {
        id: updateProc
        command: [root.asuraBin, "update", "--no-reload"]
        running: false

        stderr: SplitParser {
            splitMarker: ""
            onRead: (data) => {
                if (data && data.trim().length > 0) {
                    console.log("[UpdateService] update stderr:", data.trim());
                }
            }
        }

        onExited: (exitCode) => {
            root.updating = false;
            if (exitCode === 0) {
                root.updateAvailable = false;
                root.currentVersion = root.latestVersion;
                root.statusMessage = qsTr("Updated successfully! Reloading shell...");

                try {
                    NotificationService.addNotification(
                        qsTr("Asura Shell"),
                        qsTr("Update Completed"),
                        qsTr("Successfully updated to %1. Reloading interface...").arg(root.latestVersion),
                        "system-software-update"
                    );
                } catch (e) {
                    console.log("[UpdateService] Could not send notification:", e);
                }

                root.updateFinished(true, root.statusMessage);
                reloadShellTimer.restart();
            } else {
                root.statusMessage = qsTr("Update failed. Check terminal with 'asura update'.");
                try {
                    NotificationService.addNotification(
                        qsTr("Asura Shell"),
                        qsTr("Update Failed"),
                        qsTr("Could not complete update. Check terminal logs."),
                        "dialog-error"
                    );
                } catch (e) {
                    console.log("[UpdateService] Could not send notification:", e);
                }
                root.updateFinished(false, root.statusMessage);
            }
        }
    }

    function checkForUpdates(force = false, isAuto = false) {
        if (root.checking || root.updating) return;

        root.checking = true;
        root.lastCheckWasAuto = isAuto;
        root.statusMessage = qsTr("Checking for updates...");

        var cmd = [root.asuraBin, "update", "--check", "--json"];
        if (force) {
            cmd.push("--force");
        }
        checkProc.command = cmd;
        checkProc.running = true;
    }

    function applyUpdate(isAuto = false) {
        if (root.updating) return;

        root.updating = true;
        root.statusMessage = qsTr("Applying update...");
        updateProc.command = [root.asuraBin, "update", "--no-reload"];
        updateProc.running = true;
    }

    function parseCheckOutput(raw) {
        try {
            var trimmed = raw.trim();
            if (!trimmed) return;
            var obj = JSON.parse(trimmed);
            if (obj && typeof obj === "object") {
                if (obj.current_version) {
                    root.currentVersion = "v" + String(obj.current_version).replace(/^v/, "");
                }
                if (obj.latest_version) {
                    root.latestVersion = "v" + String(obj.latest_version).replace(/^v/, "");
                }
                root.updateAvailable = !!obj.update_available;
                root.lastCheckTimestamp = obj.timestamp || (Date.now() / 1000);

                var d = new Date(root.lastCheckTimestamp * 1000);
                var hours = ("0" + d.getHours()).slice(-2);
                var minutes = ("0" + d.getMinutes()).slice(-2);
                root.lastCheckStr = `${hours}:${minutes}`;

                if (root.updateAvailable) {
                    root.statusMessage = qsTr("Update available (%1)").arg(root.latestVersion);
                    if (Config.cfg && Config.cfg.autoUpdate && !root.updating) {
                        console.log("[UpdateService] Auto-update active, applying update now...");
                        root.applyUpdate(true);
                    }
                } else {
                    root.statusMessage = qsTr("Asura Shell is up to date");
                }

                root.checkFinished(true, root.updateAvailable);
            }
        } catch (e) {
            console.log("[UpdateService] Parse error:", e, "output was:", raw);
            root.statusMessage = qsTr("Update check completed");
            root.checkFinished(false, false);
        }
    }
}
