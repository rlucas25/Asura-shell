pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property int brightness: 100
    property int maxBrightness: 100
    property real brightnessPercent: brightness / 100.0

    function setBrightness(percent) {
        var p = Math.max(1, Math.min(100, percent));
        setProc.command = ["brightnessctl", "set", p + "%"];
        setProc.running = false;
        setProc.running = true;
        root.brightness = p;
    }

    function refresh() {
        if (!getProc.running && root.maxBrightness > 1) {
            getProc.running = true;
        }
    }

    Process {
        id: maxProc
        command: ["brightnessctl", "m"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var v = parseInt(data.trim());
                if (!isNaN(v) && v > 0) {
                    root.maxBrightness = v;
                    if (v > 1 && !getProc.running)
                        getProc.running = true;
                }
            }
        }
    }

    Process {
        id: getProc
        command: ["brightnessctl", "g"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                var v = parseInt(data.trim());
                if (!isNaN(v) && root.maxBrightness > 1) {
                    var percent = Math.round((v / root.maxBrightness) * 100);
                    if (percent !== root.brightness) {
                        root.brightness = percent;
                        root.brightnessChanged();
                    }
                }
            }
        }
    }

    Process {
        id: setProc
        command: []
        running: false
    }

    Timer {
        interval: 3000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }
}
