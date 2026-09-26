pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool isLocked: false
    property bool isAuthenticating: false
    property string username: ""
onIsLockedChanged: {
        submapProc.command = ["hyprctl", "dispatch", "submap", isLocked ? "lockscreen" : "reset"];
        submapProc.running = true;
    }

    Process {
        id: submapProc
        running: false
        onExited: running = false
    }
    signal authSuccess()
    signal authFailed()

    function lock() {
        isLocked = true;
    }

    function unlock() {
        authSuccess();
        unlockDelayTimer.restart();
    }

    function toggle() {
        if (isLocked) {
            isLocked = false;
        } else {
            lock();
        }
    }

    Timer {
        id: authTimeoutTimer
        interval: 4000
        repeat: false
        onTriggered: {
            if (root.isAuthenticating) {
                root.isAuthenticating = false;
                if (authProc.running) {
                    authProc.kill();
                }
                root.authFailed();
            }
        }
    }

    property string pendingPassword: ""

    function tryUnlock(password) {
        if (isAuthenticating) return;
        isAuthenticating = true;
        pendingPassword = password;
        authTimeoutTimer.restart();

        if (authProc.running) {
            authProc.kill();
        }
        authProc.running = true;
    }

    readonly property string scriptPath: (typeof Quickshell.shellPath === "function")
        ? Quickshell.shellPath("Services/auth_helper.py")
        : (Quickshell.env("HOME") + "/.config/quickshell/Services/auth_helper.py")

    Process {
        id: userProc
        command: ["python3", root.scriptPath, "--user"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var trimmed = data ? data.trim() : "";
                if (trimmed.length > 0) {
                    root.username = trimmed;
                }
            }
        }
    }

    Process {
        id: authProc
        command: ["python3", root.scriptPath]
        running: false

        onRunningChanged: {
            if (running && root.pendingPassword) {
                authProc.write(root.pendingPassword + "\n");
                root.pendingPassword = "";
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.isAuthenticating = false;
            root.pendingPassword = "";
            if (exitCode === 0) {
                root.authSuccess();
                unlockDelayTimer.restart();
            } else {
                root.authFailed();
            }
        }
    }

    Timer {
        id: unlockDelayTimer
        interval: 280
        repeat: false
        onTriggered: {
            root.isLocked = false;
        }
    }
}
