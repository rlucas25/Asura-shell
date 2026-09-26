pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Ethernet State

    property bool ethernetConnected: false
    property string ethernetName: ""
    property string ethernetIp: ""
    property string ethernetIface: ""

    // Wi-Fi State

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

    // Combined Online State

    readonly property bool isOnline: ethernetConnected || connected

    // Operation State

    property bool isScanning: false
    property string connectingSsid: ""
    property string statusMessage: ""
    property bool isError: false
    property bool paused: false

    // Script location

    readonly property string scriptPath: (typeof Quickshell.shellPath === "function")
        ? Quickshell.shellPath("Services/wifi_manager.py")
        : Quickshell.configPath("Services/wifi_manager.py")

    // ---------------------------------------------------------
    // ICONS
    // ---------------------------------------------------------

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

    // ---------------------------------------------------------
    // STATUS
    // ---------------------------------------------------------

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

            // Ethernet

            if (data.ethernet && data.ethernet.connected) {
                root.ethernetConnected = true
                root.ethernetName = data.ethernet.name || "Conexão Cabeada"
                root.ethernetIp = data.ethernet.ip || ""
                root.ethernetIface = data.ethernet.iface || ""
            } else {
                root.ethernetConnected = false
                root.ethernetName = ""
                root.ethernetIp = ""
                root.ethernetIface = ""
            }

            // Wi-Fi

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
                "WifiService: Erro ao parsear JSON de status:",
                e
            )
        }
    }

    // ---------------------------------------------------------
    // REFRESH
    // ---------------------------------------------------------

    // Refresh current status without forcing full rescan

    function refresh() {
        if (!root.paused && !statusProc.running) {
            statusProc.running = true
        }
    }

    // ---------------------------------------------------------
    // SCAN
    // ---------------------------------------------------------

    // Force scan for nearby networks

    function rescan() {
        if (root.isScanning)
            return

        root.isScanning = true
        rescanProc.running = true
    }

    // ---------------------------------------------------------
    // WI-FI TOGGLE
    // ---------------------------------------------------------

    // Toggle Wi-Fi Radio

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

    // ---------------------------------------------------------
    // CONNECT
    // ---------------------------------------------------------

    // Connect to network

    function connect(ssid, password, isHidden) {
        if (!ssid)
            return

        root.connectingSsid = ssid

        root.showStatus(
            "Conectando a " + ssid + "...",
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
                    "Conectado a " + ssid + "!",
                    false
                )

                root.refresh()
            } else {
                const errMsg = (data && data.message)
                    ? data.message
                    : "Falha ao conectar."

                root.showStatus(errMsg, true)
            }
        }

        actionProc.running = true
    }

    // ---------------------------------------------------------
    // DISCONNECT
    // ---------------------------------------------------------

    // Disconnect from current Wi-Fi

    function disconnect() {
        const prevSsid = root.activeSsid

        root.showStatus(
            "Desconectando...",
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
                    "Desconectado de " + prevSsid,
                    false
                )

                root.refresh()
            } else {
                root.showStatus(
                    "Erro ao desconectar.",
                    true
                )
            }
        }

        actionProc.running = true
    }

    // ---------------------------------------------------------
    // FORGET NETWORK
    // ---------------------------------------------------------

    // Forget / Delete saved network

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
                    "Rede " + ssid + " esquecida.",
                    false
                )

                root.refresh()
            } else {
                root.showStatus(
                    "Falha ao esquecer rede " + ssid,
                    true
                )
            }
        }

        actionProc.running = true
    }

    // ---------------------------------------------------------
    // PROCESSES
    // ---------------------------------------------------------

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

    // ---------------------------------------------------------
    // TIMERS
    // ---------------------------------------------------------

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

    // ---------------------------------------------------------
    // LIFECYCLE
    // ---------------------------------------------------------

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
