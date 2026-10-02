pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Services

Singleton {
    id: root

    // Bar spectrum point resolution (20 bands calibrated for Player widget and audio visualizer)
    property int barCount: 20
    property var bars: {
        var arr = [];
        for (var i = 0; i < barCount; i++) arr.push(0);
        return arr;
    }
    readonly property var points: root.bars
    property real normalizationCeiling: 100000
    property bool audioSignalActive: false

    property var _pendingBars: []

    property int activeConsumers: 0
    property bool isPlaying: PlayerService.isPlaying
    property bool isRestarting: false

    property bool processEnabled: activeConsumers > 0 && (isPlaying || decayTimer.running) && !isRestarting

    readonly property string userConfigPath: Quickshell.env("HOME") + "/.config/cava/config_qml"

    function registerConsumer() {
        activeConsumers++;
        if (activeConsumers === 1 && !ensureConfigProc.running && !cavaProcess.running) {
            ensureConfigProc.running = true;
        }
    }

    function unregisterConsumer() {
        activeConsumers = Math.max(0, activeConsumers - 1);
    }

    function resetBars() {
        var empty = [];
        for (var i = 0; i < root.barCount; i++) {
            empty.push(0);
        }
        root.bars = empty;
        root._pendingBars = empty;
        root.audioSignalActive = false;
    }

    function restartCava() {
        if (!processEnabled) return;
        isRestarting = true;
        resetBars();
        restartTimer.restart();
    }

    onIsPlayingChanged: {
        if (isPlaying) {
            decayTimer.stop();
        } else if (activeConsumers > 0) {
            decayTimer.restart();
        } else {
            resetBars();
        }
    }

    onProcessEnabledChanged: {
        if (!processEnabled) {
            resetBars();
        } else if (!cavaProcess.running && !ensureConfigProc.running) {
            ensureConfigProc.running = true;
        }
    }

    Timer {
        id: decayTimer
        interval: 1200
        repeat: false
        onTriggered: {
            if (!root.isPlaying) {
                root.resetBars();
            }
        }
    }

    Timer {
        id: restartTimer
        interval: 400
        repeat: false
        onTriggered: root.isRestarting = false
    }

    // Watchdog to restart cava if long silence occurs during playback
    Timer {
        id: dataWatchdog
        interval: 10000
        running: cavaProcess.running && root.isPlaying
        repeat: false
        onTriggered: root.restartCava()
    }

    // 60 FPS throttled render ticker to prevent frame spikes
    Timer {
        id: renderTimer
        interval: 16 
        running: root.processEnabled
        repeat: true
        onTriggered: {
            if (root._pendingBars.length > 0) {
                root.bars = root._pendingBars;
            }
        }
    }

    Process {
        id: preflightProc
        command: ["pkill", "-x", "cava"]
    }

    // Ensure user cava configuration file exists with proper 20-band settings and custom tuning
    Process {
        id: ensureConfigProc
        running: false
        command: [
            "bash", "-c",
            "if [ ! -f \"" + root.userConfigPath + "\" ]; then " +
            "mkdir -p \"$(dirname \"" + root.userConfigPath + "\")\" && " +
            "cat > \"" + root.userConfigPath + "\" << 'EOF'\n" +
            "[general]\n" +
            "bars = 20\n" +
            "framerate = 60\n" +
            "autosens = 5\n" +
            "sensitivity = 100\n" +
            "channels = stereo\n\n" +
            "[output]\n" +
            "method = raw\n" +
            "raw_target = /dev/stdout\n" +
            "data_format = ascii\n" +
            "ascii_max_range = 100000\n" +
            "bar_delimiter = 59\n\n" +
            "[smoothing]\n" +
            "integral = 100\n" +
            "gravity = 0\n" +
            "waves = 40\n" +
            "noise_reduction = 10\n\n" +
            "[eq]\n" +
            "1 = 1.1\n" +
            "2 = 1.15\n" +
            "3 = 1.2\n" +
            "4 = 1.5\n" +
            "5 = 1.2\n" +
            "EOF\n" +
            "fi"
        ]
        onExited: (code) => {
            if (root.processEnabled) {
                cavaProcess.running = true;
            }
        }
    }

    Process {
        id: cavaProcess
        running: root.processEnabled && !ensureConfigProc.running
        command: ["cava", "-p", root.userConfigPath]
        onExited: {
            if (root.processEnabled) {
                root.restartCava();
            }
        }
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (!root.processEnabled) return;
                dataWatchdog.restart();
                
                var str = data ? data.trim() : "";
                if (str.length === 0) return;

                var parts = str.split(";");
                var len = Math.min(parts.length, root.barCount);
                var newBars = [];
                var maxVal = 0;
                for (var i = 0; i < root.barCount; i++) {
                    var val = i < len ? (parseInt(parts[i]) || 0) : 0;
                    newBars.push(val);
                    if (val > maxVal) maxVal = val;
                }
                
                root.audioSignalActive = (maxVal > 80);
                root._pendingBars = newBars;
            }
        }
    }

    Component.onCompleted: {
        preflightProc.running = true;
        ensureConfigProc.running = true;
    }

    Component.onDestruction: {
        cavaProcess.running = false;
    }
}