pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Asura

Singleton {
    id: root

    property bool isRecording: false
    property bool isStopping: false
    property bool cavaReady: false
    property int recordingDuration: 0
    property string recordingDisplayTime: "00:00"
    property string currentFilePath: ""
    property string lastSavedPath: ""

    property int barCount: 20
    property var bars: {
        var arr = [];
        for (var i = 0; i < barCount; i++) arr.push(0);
        return arr;
    }
    property var _pendingBars: []

    readonly property string scriptPath: (typeof Quickshell.shellPath === "function")
        ? Quickshell.shellPath("Services/recorder_manager.py").toString()
        : (Quickshell.env("HOME") + "/.local/share/asura/Shell/quickshell/Services/recorder_manager.py")

    readonly property string resolvedFolder: {
        var f = (Config.cfg && Config.cfg.recordingsFolder) ? Config.cfg.recordingsFolder : "~/Videos/Recordings";
        if (f.startsWith("~/")) {
            return Quickshell.env("HOME") + f.substring(1);
        } else if (f.startsWith("/")) {
            return f;
        } else {
            return Quickshell.env("HOME") + "/" + f;
        }
    }

    Timer {
        id: durationTimer
        interval: 1000
        repeat: true
        running: root.isRecording && !root.isStopping
        onTriggered: {
            root.recordingDuration++;
            var m = Math.floor(root.recordingDuration / 60);
            var s = root.recordingDuration % 60;
            var mm = m < 10 ? "0" + m : "" + m;
            var ss = s < 10 ? "0" + s : "" + s;
            root.recordingDisplayTime = mm + ":" + ss;
        }
    }

    Timer {
        id: renderTimer
        interval: 16
        running: root.isRecording && !root.isStopping
        repeat: true
        onTriggered: {
            if (root._pendingBars.length > 0) {
                root.bars = root._pendingBars;
            }
        }
    }

    Timer {
        id: cavaStartTimer
        interval: 600
        repeat: false
        onTriggered: {
            if (root.isRecording && !root.isStopping) {
                root.cavaReady = true;
            }
        }
    }

    Timer {
        id: stopSafetyTimer
        interval: 6000
        repeat: false
        onTriggered: {
            if (root.isRecording || root.isStopping) {
                root.finishRecording(false);
            }
        }
    }

    Process {
        id: stopProc
        command: []
    }

    Process {
        id: notifyProc
        command: []
    }

    Process {
        id: cleanupAudioProc
        command: []
    }

    Process {
        id: recordProcess
        command: []
        onExited: (exitCode, exitStatus) => {
            stopSafetyTimer.stop();
            root.finishRecording(exitCode === 0);
        }
    }

    Process {
        id: micCavaProcess
        running: root.isRecording && !root.isStopping && root.cavaReady
        command: ["cava", "-p", Quickshell.env("HOME") + "/.config/cava/config_mic"]
        stdout: SplitParser {
            onRead: data => {
                if (!root.isRecording || root.isStopping) return;
                var str = data ? data.trim() : "";
                if (str.length === 0) return;
                var parts = str.split(";");
                var len = Math.min(parts.length, root.barCount);
                var newBars = [];
                for (var i = 0; i < root.barCount; i++) {
                    newBars.push(i < len ? (parseInt(parts[i]) || 0) : 0);
                }
                root._pendingBars = newBars;
            }
        }
    }

    function resetBars() {
        var empty = [];
        for (var i = 0; i < root.barCount; i++) {
            empty.push(0);
        }
        root.bars = empty;
        root._pendingBars = empty;
    }

    function cleanupAudio() {
        cleanupAudioProc.command = ["python3", root.scriptPath, "cleanup-audio"];
        cleanupAudioProc.running = false;
        cleanupAudioProc.running = true;
    }

    function startRecording() {
        if (root.isRecording || root.isStopping) return;
        var dir = root.resolvedFolder;
        var now = new Date();
        var ts = Qt.formatDateTime(now, "yyyy-MM-dd_hh-mm-ss");
        var filename = "recording_" + ts + ".mp4";
        root.currentFilePath = dir + "/" + filename;
        root.recordingDuration = 0;
        root.recordingDisplayTime = "00:00";
        root.resetBars();
        root.cavaReady = false;

        root.isRecording = true;
        root.isStopping = false;

        recordProcess.command = ["python3", root.scriptPath, "record", root.currentFilePath];
        recordProcess.running = true;

        cavaStartTimer.start();
    }

    function stopRecording() {
        if (!root.isRecording || root.isStopping) return;
        root.isStopping = true;
        cavaStartTimer.stop();
        root.cavaReady = false;

        stopProc.command = ["python3", root.scriptPath, "stop"];
        stopProc.running = false;
        stopProc.running = true;

        stopSafetyTimer.start();
    }

    function finishRecording(success) {
        cavaStartTimer.stop();
        stopSafetyTimer.stop();
        root.cavaReady = false;
        root.isRecording = false;
        root.isStopping = false;
        recordProcess.running = false;
        root.lastSavedPath = root.currentFilePath;
        root.resetBars();
        root.recordingDuration = 0;
        root.recordingDisplayTime = "00:00";

        if (success === undefined || success === true) {
            if (root.lastSavedPath.length > 0) {
                notifyProc.command = ["notify-send", "-a", "Screen Recorder", "Recording Saved", root.lastSavedPath, "-i", "camera-video"];
                notifyProc.running = false;
                notifyProc.running = true;
            }
        } else {
            notifyProc.command = ["notify-send", "-a", "Screen Recorder", "Recording Stopped", "Failed to save screen recording.", "-i", "dialog-error"];
            notifyProc.running = false;
            notifyProc.running = true;
        }
    }

    function toggleRecording() {
        if (root.isStopping) return;
        if (root.isRecording) {
            stopRecording();
        } else {
            startRecording();
        }
    }

    IpcHandler {
        target: "recorder"

        function toggle() {
            root.toggleRecording();
        }

        function start() {
            root.startRecording();
        }

        function stop() {
            root.stopRecording();
        }
    }

    Process {
        id: initProc
        command: []
    }

    Component.onCompleted: {
        var initScript = "import os; p = os.path.expanduser('~/.config/cava/config_mic');\n" +
            "os.makedirs(os.path.dirname(p), exist_ok=True);\n" +
            "open(p, 'w').write('''[general]\\nbars = 20\\nframerate = 60\\nautosens = 1\\nsensitivity = 100\\nchannels = mono\\n\\n[input]\\nmethod = pulse\\nsource = recording_combined.monitor\\n\\n[output]\\nmethod = raw\\nraw_target = /dev/stdout\\ndata_format = ascii\\nascii_max_range = 100000\\nbar_delimiter = 59\\n\\n[smoothing]\\nintegral = 80\\ngravity = 100\\nwaves = 20\\nnoise_reduction = 15\\n''')";
        initProc.command = ["python3", "-c", initScript];
        initProc.running = true;
        cleanupAudio();
    }

    Component.onDestruction: {
        if (root.isRecording || root.isStopping) {
            stopRecording();
        }
        cleanupAudio();
    }
}
