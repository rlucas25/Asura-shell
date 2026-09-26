pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int masterVolume: 70
    property bool masterMuted: false
    property int micVolume: 80
    property bool micMuted: false
    property var appStreams: []

    property int pendingSyncAppId: -1
    property int pendingSyncVol: 100
    property string pendingSyncAppName: ""

    readonly property string scriptPath: (typeof Quickshell.shellPath === "function") 
        ? Quickshell.shellPath("Services/audio_manager.py") 
        : Quickshell.configPath("Services/audio_manager.py")

    Process {
        id: audioGetProc
        command: ["python3", root.scriptPath, "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "") return;
                try {
                    var data = JSON.parse(text.trim());
                    if (data.master) {
                        root.masterVolume = data.master.volume;
                        root.masterMuted = data.master.muted;
                    }
                    if (data.mic) {
                        root.micVolume = data.mic.volume;
                        root.micMuted = data.mic.muted;
                    }
                    if (Array.isArray(data.apps)) {
                        root.appStreams = data.apps;
                    }
                } catch (e) {
                    console.warn("AudioService parse error:", e);
                }
            }
        }
    }

    Process { id: directActionProc; command: [] }
    Process { id: spotifyVolProc; command: [] }
    Process { id: masterActionProc; command: [] }
    Process { id: micActionProc; command: [] }
    Process { id: audioActionProc; command: [] }

    Timer {
        id: syncTimer
        interval: 200
        repeat: false
        onTriggered: {
            if (root.pendingSyncAppId !== -1) {
                audioActionProc.command = [
                    "python3",
                    root.scriptPath,
                    "set-app",
                    root.pendingSyncAppId.toString(),
                    root.pendingSyncVol.toString(),
                    root.pendingSyncAppName
                ];
                audioActionProc.running = false;
                audioActionProc.running = true;
            }
        }
    }

    function refresh() {
        if (!audioGetProc.running) {
            audioGetProc.running = true;
        }
    }

    function setMasterVolume(val) {
        var clamped = Math.max(0, Math.min(100, val));
        root.masterVolume = clamped;
        masterActionProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (clamped / 100).toFixed(2)];
        masterActionProc.running = false;
        masterActionProc.running = true;
    }

    function toggleMasterMute() {
        root.masterMuted = !root.masterMuted;
        masterActionProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"];
        masterActionProc.running = false;
        masterActionProc.running = true;
    }

    function setMicVolume(val) {
        var clamped = Math.max(0, Math.min(100, val));
        root.micVolume = clamped;
        micActionProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", (clamped / 100).toFixed(2)];
        micActionProc.running = false;
        micActionProc.running = true;
    }

    function toggleMicMute() {
        root.micMuted = !root.micMuted;
        micActionProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"];
        micActionProc.running = false;
        micActionProc.running = true;
    }

    function setAppVolume(appId, val, appName) {
        var clamped = Math.max(0, Math.min(150, val));
        for (var i = 0; i < root.appStreams.length; i++) {
            if (root.appStreams[i].id === appId) {
                root.appStreams[i].volume = clamped;
                break;
            }
        }

        directActionProc.command = ["pactl", "set-sink-input-volume", appId.toString(), clamped.toString() + "%"];
        directActionProc.running = false;
        directActionProc.running = true;

        var name = appName || "";
        if (!name) {
            for (var j = 0; j < root.appStreams.length; j++) {
                if (root.appStreams[j].id === appId) {
                    name = root.appStreams[j].name || "";
                    break;
                }
            }
        }

        if (name && name.toLowerCase().indexOf("spotify") !== -1) {
            spotifyVolProc.command = ["playerctl", "-p", "spotify", "volume", (clamped / 100.0).toFixed(2)];
            spotifyVolProc.running = false;
            spotifyVolProc.running = true;
        }

        root.pendingSyncAppId = appId;
        root.pendingSyncVol = clamped;
        root.pendingSyncAppName = name;
        syncTimer.restart();
    }

    function toggleAppMute(appId, appName) {
        for (var i = 0; i < root.appStreams.length; i++) {
            if (root.appStreams[i].id === appId) {
                root.appStreams[i].muted = !root.appStreams[i].muted;
                break;
            }
        }

        directActionProc.command = ["pactl", "set-sink-input-mute", appId.toString(), "toggle"];
        directActionProc.running = false;
        directActionProc.running = true;

        var name = appName || "";
        if (!name) {
            for (var j = 0; j < root.appStreams.length; j++) {
                if (root.appStreams[j].id === appId) {
                    name = root.appStreams[j].name || "";
                    break;
                }
            }
        }

        audioActionProc.command = ["python3", root.scriptPath, "mute-app", appId.toString(), name];
        audioActionProc.running = false;
        audioActionProc.running = true;
    }

    Process {
        id: pactlSubProc
        command: ["pactl", "subscribe"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                if (data && (data.includes("sink") || data.includes("source") || data.includes("server"))) {
                    debounceTimer.restart();
                }
            }
        }
    }

    Timer {
        id: debounceTimer
        interval: 100
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()

    Component.onDestruction: {
        pactlSubProc.running = false;
        pactlSubProc.kill();
    }
}
