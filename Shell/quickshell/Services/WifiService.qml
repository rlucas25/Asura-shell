pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool ethernetConnected: false
    property string ethernetName: ""
    property string ethernetIp: ""
    property string ethernetIface: ""

    property bool wifiEnabled: true
    property bool connected: activeSsid !== ""
    property string activeSsid: ""
    property int activeSignal: 0
    property string activeFreq: ""
    property string activeBand: ""
    property string activeIp: ""
    property string activeSecurity: ""
    property string activeBssid: ""
    property var networks: []

    readonly property bool isOnline: ethernetConnected || connected

    property bool isScanning: false
    property string connectingSsid: ""
    property string statusMessage: ""
    property bool isError: false
    property bool paused: false

    readonly property string scriptPath: {
        var p = (typeof Quickshell.shellPath === "function")
            ? Quickshell.shellPath("Services/wifi_manager.py").toString()
            : (Quickshell.env("HOME") + "/.local/share/asura/Shell/quickshell/Services/wifi_manager.py");
        return p.replace(/^file:\/\//, "").replace(/^file:/, "");
    }

    function getSignalIcon(signal, enabled) {
        if (enabled === false)
            return "signal_wifi_off"

        if (signal >= 80)
            return "signal_wifi_4_bar"

        if (signal >= 60)
            return "network_wifi_3_bar"

        if (signal >= 40)
            return "network_wifi_2_bar"

        if (signal >= 15)
            return "network_wifi_1_bar"

        return "signal_wifi_0_bar"
    }

    function getNetworkIcon() {
        if (root.ethernetConnected)
            return "lan"

        if (root.connected)
            return root.getSignalIcon(
                root.activeSignal,
                root.wifiEnabled
            )

        if (root.wifiEnabled)
            return "signal_wifi_0_bar"

        return "signal_wifi_off"
    }

    function showStatus(msg, isErr) {
        statusMessage = msg
        isError = !!isErr
        clearMsgTimer.restart()
    }

    function parseStatusJson(text) {
        if (!text || text.trim() === "")
            return

        try {
            const data = JSON.parse(text.trim())

            if (data.ethernet && data.ethernet.connected) {
                root.ethernetConnected = true
                root.ethernetName = data.ethernet.name || "Wired Connection"
                root.ethernetIp = data.ethernet.ip || ""
                root.ethernetIface = data.ethernet.iface || ""
            } else {
                root.ethernetConnected = false
                root.ethernetName = ""
                root.ethernetIp = ""
                root.ethernetIface = ""
            }

            root.wifiEnabled = !!data.enabled

            if (data.active) {
                root.activeSsid = data.active.ssid || ""
                root.activeSignal = data.active.signal || 0
                root.activeFreq = data.active.freq || ""
                root.activeBand = data.active.band || ""
                root.activeIp = data.active.ip || ""
                root.activeSecurity = data.active.security || ""
                root.activeBssid = data.active.bssid || ""
            } else {
                root.activeSsid = ""
                root.activeSignal = 0
                root.activeFreq = ""
                root.activeBand = ""
                root.activeIp = ""
                root.activeSecurity = ""
                root.activeBssid = ""
            }

            if (!root.paused) {
                root.networks = Array.isArray(data.networks)
                    ? data.networks
                    : []
            }

        } catch (e) {
            console.warn(
                "WifiService: Error parsing status JSON:",
                e
            )
        }
    }

    function refresh() {
        if (!root.paused && !statusProc.running) {
            statusProc.running = true
        }
    }

    function rescan() {
        if (root.isScanning)
            return

        root.isScanning = true
        rescanProc.running = true
    }

    function toggleWifi(enable) {
        const action = enable ? "on" : "off"

        actionProc.command = [
            "python3",
            root.scriptPath,
            action
        ]

        actionProc.callback = function(data) {
            root.wifiEnabled = enable

            if (!enable) {
                root.activeSsid = ""
                root.activeSignal = 0
                root.networks = []
            } else {
                root.rescan()
            }
        }

        actionProc.running = true
    }

    function connect(ssid, password, isHidden) {
        if (!ssid)
            return

        root.connectingSsid = ssid

        root.showStatus(
            "Connecting to " + ssid + "...",
            false
        )

        const args = [
            "python3",
            root.scriptPath,
            "connect",
            ssid
        ]

        if (password)
            args.push(password)
        else
            args.push("")

        if (isHidden)
            args.push("hidden")

        actionProc.command = args

        actionProc.callback = function(data) {
            root.connectingSsid = ""

            if (data && data.success) {
                root.showStatus(
                    "Connected to " + ssid + "!",
                    false
                )

                root.refresh()
            } else {
                const errMsg = (data && data.message)
                    ? data.message
                    : "Failed to connect."

                root.showStatus(errMsg, true)
            }
        }

        actionProc.running = true
    }

    function disconnect() {
        const prevSsid = root.activeSsid

        root.showStatus(
            "Disconnecting...",
            false
        )

        actionProc.command = [
            "python3",
            root.scriptPath,
            "disconnect"
        ]

        actionProc.callback = function(data) {
            if (data && data.success) {
                root.activeSsid = ""
                root.activeSignal = 0

                root.showStatus(
                    "Disconnected from " + prevSsid,
                    false
                )

                root.refresh()
            } else {
                root.showStatus(
                    "Failed to disconnect.",
                    true
                )
            }
        }

        actionProc.running = true
    }

    function forget(ssid) {
        if (!ssid)
            return

        actionProc.command = [
            "python3",
            root.scriptPath,
            "forget",
            ssid
        ]

        actionProc.callback = function(data) {
            if (data && data.success) {
                root.showStatus(
                    "Network " + ssid + " forgotten.",
                    false
                )

                root.refresh()
            } else {
                root.showStatus(
                    "Failed to forget network " + ssid,
                    true
                )
            }
        }

        actionProc.running = true
    }

    Process {
        id: statusProc

        command: [
            "python3",
            root.scriptPath,
            "status"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                root.parseStatusJson(text)
            }
        }
    }

    Process {
        id: rescanProc

        command: [
            "python3",
            root.scriptPath,
            "rescan"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                root.isScanning = false
                root.parseStatusJson(text)
            }
        }
    }

    Process {
        id: actionProc

        property var callback: null

        stdout: StdioCollector {
            onStreamFinished: {
                let parsed = null

                try {
                    parsed = JSON.parse(text)
                } catch (e) {
                    console.warn(
                        "WifiService action parse error:",
                        e,
                        text
                    )
                }

                if (actionProc.callback) {
                    actionProc.callback(parsed)
                    actionProc.callback = null
                }

                root.refresh()
            }
        }
    }

    Timer {
        id: pollTimer

        interval: 3500
        running: true
        repeat: true

        onTriggered: root.refresh()
    }

    Timer {
        id: clearMsgTimer

        interval: 5000
        repeat: false

        onTriggered: {
            root.statusMessage = ""
            root.isError = false
        }
    }

    Component.onCompleted: {
        root.refresh()
    }

    Component.onDestruction: {
        statusProc.running = false
        statusProc.kill()

        rescanProc.running = false
        rescanProc.kill()

        actionProc.running = false
        actionProc.kill()
    }
}
