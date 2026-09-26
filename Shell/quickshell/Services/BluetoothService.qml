pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

Singleton {
    id: root
    readonly property var adapter: Bluetooth.adapters && Bluetooth.adapters.values && Bluetooth.adapters.values.length > 0 
        ? Bluetooth.adapters.values[0] 
        : null

    readonly property bool bluetoothEnabled: adapter ? (adapter.state === BluetoothAdapterState.Enabled) : false
    readonly property var allDevices: Bluetooth.devices && Bluetooth.devices.values ? Bluetooth.devices.values : []

    readonly property var connectedDevices: allDevices.filter(d => d && d.state === BluetoothDeviceState.Connected)
    readonly property var pairedDevices: allDevices.filter(d => d && d.paired && d.state !== BluetoothDeviceState.Connected)
    readonly property var availableDevices: allDevices.filter(d => d && !d.paired && d.name && d.name.trim() !== "")

    readonly property bool hasConnectedDevice: connectedDevices.length > 0
    readonly property string activeDeviceName: hasConnectedDevice ? (connectedDevices[0].name || "Device") : ""

    property bool isScanning: false
    property string connectingAddress: ""
    property string statusMessage: ""

    Timer {
        id: statusResetTimer
        interval: 3500
        onTriggered: root.statusMessage = ""
    }

    function showStatus(msg) {
        root.statusMessage = msg;
        statusResetTimer.restart();
    }

    // Process helper for command execution
    Process {
        id: cmdProc
        command: []
    }

    function togglePower() {
        var newState = !bluetoothEnabled;
        cmdProc.command = ["bluetoothctl", "power", newState ? "on" : "off"];
        cmdProc.running = true;
        showStatus(newState ? "Enabling Bluetooth..." : "Disabling Bluetooth...");
    }

    Process {
        id: scanProc
        command: ["bluetoothctl", "scan", root.isScanning ? "off" : "on"]
        onExited: {
            // keep scan state in sync
        }
    }

    function toggleScan() {
        if (!bluetoothEnabled)
            return;
        root.isScanning = !root.isScanning;
        cmdProc.command = ["bluetoothctl", "scan", root.isScanning ? "on" : "off"];
        cmdProc.running = true;
        showStatus(root.isScanning ? "Searching for devices..." : "Search completed.");
    }

    function connectDevice(mac) {
        if (!mac) return;
        connectingAddress = mac;
        showStatus("Connecting to " + mac + "...");
        cmdProc.command = ["bluetoothctl", "connect", mac];
        cmdProc.running = true;
    }

    function disconnectDevice(mac) {
        if (!mac) return;
        showStatus("Disconnecting...");
        cmdProc.command = ["bluetoothctl", "disconnect", mac];
        cmdProc.running = true;
    }

    function pairDevice(mac) {
        if (!mac) return;
        connectingAddress = mac;
        showStatus("Paring...");
        cmdProc.command = ["bash", "-c", "bluetoothctl pair " + mac + " && bluetoothctl trust " + mac + " && bluetoothctl connect " + mac];
        cmdProc.running = true;
    }

    function removeDevice(mac) {
        if (!mac) return;
        showStatus("Removing device...");
        cmdProc.command = ["bluetoothctl", "remove", mac];
        cmdProc.running = true;
    }

    function getDeviceIcon(iconName, name) {
        var lowerIcon = (iconName || "").toLowerCase();
        var lowerName = (name || "").toLowerCase();

        if (lowerIcon.includes("headset") || lowerIcon.includes("audio-headset") || lowerName.includes("headphone") || lowerName.includes("fone") || lowerName.includes("buds") || lowerName.includes("airpods"))
            return "headphones";
        if (lowerIcon.includes("gamepad") || lowerIcon.includes("gaming") || lowerIcon.includes("joystick") || lowerName.includes("controller") || lowerName.includes("xbox") || lowerName.includes("dualshock") || lowerName.includes("dualsense"))
            return "stadia_controller";
        if (lowerIcon.includes("keyboard") || lowerName.includes("keyboard") || lowerName.includes("teclado"))
            return "keyboard";
        if (lowerIcon.includes("mouse") || lowerName.includes("mouse"))
            return "mouse";
        if (lowerIcon.includes("phone") || lowerName.includes("phone") || lowerName.includes("iphone") || lowerName.includes("galaxy"))
            return "mobile_2";
        if (lowerIcon.includes("speaker") || lowerIcon.includes("audio") || lowerName.includes("speaker") || lowerName.includes("caixa") || lowerName.includes("jbl"))
            return "speaker";

        return "bluetooth";
    }
}
