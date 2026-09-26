pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Services

Singleton {
    id: root

    property int barCount: 20
    property var bars: {
        var arr = [];
        for (var i = 0; i < barCount; i++) arr.push(0);
        return arr;
    }

    property var _pendingBars: []

    property int activeConsumers: 0
    property bool isPlaying: PlayerService.isPlaying
    property bool isRestarting: false

    property bool processEnabled: activeConsumers > 0 && (isPlaying || decayTimer.running) && !isRestarting

    function registerConsumer() {
        activeConsumers++;
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
    }

    function restartCava() {
        if (!processEnabled) return;
        isRestarting = true;
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

    // Aumentado para 10 segundos. Evita ficar matando/criando processos se a música 
    // tiver um trecho silencioso longo onde o Cava não envia novas saídas.
    Timer {
        id: dataWatchdog
        interval: 10000
        running: cavaProcess.running && root.isPlaying
        repeat: false
        onTriggered: root.restartCava()
    }

    // Limitador de FPS (Throttle)
    // Atualiza o visual apenas 1x por frame (~16ms), ignorando floods do stdout
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

    Process {
        id: cavaProcess
        running: root.processEnabled
        command: ["cava", "-p", Quickshell.env("HOME") + "/.config/cava/config_qml"]
        onExited: {
            if (root.processEnabled) {
                root.restartCava();
            }
        }
        stdout: SplitParser {
            onRead: data => {
                if (!root.processEnabled) return;
                dataWatchdog.restart();
                
                var str = data ? data.trim() : "";
                if (str.length === 0) return;

                var parts = str.split(";");
                var len = Math.min(parts.length, root.barCount);
                var newBars = [];
                for (var i = 0; i < root.barCount; i++) {
                    newBars.push(i < len ? (parseInt(parts[i]) || 0) : 0);
                }
                
                // Em vez de atualizar a UI, apenas guardamos na memória
                root._pendingBars = newBars;
            }
        }
    }

    Component.onCompleted: {
        preflightProc.running = true;
    }

    Component.onDestruction: {
        cavaProcess.running = false;
    }
}