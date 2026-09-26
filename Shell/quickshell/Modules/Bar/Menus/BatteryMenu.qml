import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.Animations
import qs.Asura

Item {
    id: root

    // === PROPERTIES ===
    property color primary: Colors.cfg.primary
    property color secondary: Colors.cfg.secondary
    property color background: Colors.cfg.background
    property color surfaceContainer: Colors.cfg.surfaceContainer
    property color on_primary: Colors.cfg.on_primary
    property color text: Colors.cfg.text

    // Compatibility aliases
    property alias color1: root.primary
    property alias color2: root.secondary
    property alias foreground: root.on_primary
    property alias textColor: root.text

    property string currentEnergyMode: "balanced"

    readonly property bool isCharging: UPower.displayDevice ? (UPower.displayDevice.state === UPowerDeviceState.Charging) : false
    readonly property bool isPlugged: UPower.displayDevice ? (UPower.displayDevice.state === UPowerDeviceState.Unknown || isCharging) : false

    // === DIMENSIONS ===
    implicitWidth: 360
    implicitHeight: 420

    // === HELPER FUNCTIONS ===
    function setEnergyMode(modeName) {
        root.currentEnergyMode = modeName;
        powerSetProc.command = ["powerprofilesctl", "set", modeName];
        powerSetProc.running = false;
        powerSetProc.running = true;
    }

    // === ANIMATIONS ===
    MenuEntrance {
        id: batteryEntrance

        active: root.visible
        duration: 320
        startOffsetY: 14
    }

    // === PROCESSES AND TIMERS ===
    Process {
        id: powerGetProc

        command: ["powerprofilesctl", "get"]

        stdout: SplitParser {
            onRead: (data) => {
                if (data && data.trim())
                    root.currentEnergyMode = data.trim();
            }
        }
    }

    Process {
        id: powerSetProc

        command: []
    }

    Timer {
        interval: 5000
        running: root.visible
        repeat: true
        onTriggered: {
            if (!powerGetProc.running)
                powerGetProc.running = true;
        }
    }

    // === UI CONTENT ===
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        opacity: batteryEntrance.opacity

        transform: Translate {
            y: batteryEntrance.offsetY
        }

        // Top header
        RowLayout {
            id: header

            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Energy Management"
                font.pixelSize: 16
                font.bold: true
                color: root.textColor
            }

            Item {
                Layout.fillWidth: true
            }
        }

        // Battery status card
        Rectangle {
            id: statusCard

            readonly property int batteryPercent: UPower.displayDevice ? Math.round(100 * UPower.displayDevice.percentage) : 100

            visible: !root.isPlugged
            anchors.horizontalCenter: parent.horizontalCenter
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: 85
            radius: 14
            color: Qt.alpha(root.textColor, 0)

            RowLayout {
                anchors.fill: parent

                // Battery progress bar
                Rectangle {
                    Layout.preferredWidth: parent.width
                    Layout.preferredHeight: parent.height
                    radius: 10
                    color: Qt.alpha(root.textColor, 0.1)

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * Math.max(0.05, Math.min(1, statusCard.batteryPercent / 100))
                        radius: 10
                        color: statusCard.batteryPercent > 20 ? root.color1 : Colors.cfg.warning
                    }

                    Text {
                        anchors.leftMargin: 20
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: statusCard.batteryPercent + "%"
                        color: root.background
                        font.pixelSize: 50
                        font.family: "Google Sans"
                    }
                }
            }
        }

        Text {
            text: "Power Profile"
            font.family: "Google Sans"
            font.pixelSize: 14
            font.bold: true
            color: root.textColor
        }

        // 1. Performance mode card
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 65
            radius: 12
            color: root.currentEnergyMode === "performance" ? Qt.alpha(root.color1, 0.2) : (perfItemH.hovered ? Qt.alpha(root.textColor, 0.08) : Qt.alpha(root.textColor, 0.03))
            border.color: root.currentEnergyMode === "performance" ? root.color1 : Qt.alpha(root.textColor, 0.08)
            border.width: root.currentEnergyMode === "performance" ? 2 : 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 45
                    Layout.preferredHeight: 45
                    Layout.alignment: Qt.AlignVCenter
                    color: root.currentEnergyMode === "performance" ? root.color1 : Qt.alpha(root.textColor, 0.08)
                    radius: root.currentEnergyMode === "performance" ? 30 : 12

                    Behavior on radius {
                        NumberAnimation {
                            duration: 200
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "rocket_launch"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 22
                        color: root.currentEnergyMode === "performance" ? root.foreground : root.color1
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 1

                    Text {
                        Layout.fillWidth: true
                        text: "Performance Mode"
                        font.pixelSize: 14
                        font.family: "Google Sans"
                        font.bold: true
                        color: root.textColor
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Maximum performance of CPU/GPU"
                        font.family: "Google Sans"
                        font.pixelSize: 9
                        color: Qt.alpha(root.textColor, 0.5)
                    }
                }
            }

            HoverHandler {
                id: perfItemH
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.setEnergyMode("performance")
            }
        }

        // 2. Balanced mode card
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 65
            radius: 12
            color: root.currentEnergyMode === "balanced" ? Qt.alpha(root.color1, 0.2) : (balItemH.hovered ? Qt.alpha(root.textColor, 0.08) : Qt.alpha(root.textColor, 0.03))
            border.color: root.currentEnergyMode === "balanced" ? root.color1 : Qt.alpha(root.textColor, 0.08)
            border.width: root.currentEnergyMode === "balanced" ? 2 : 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 45
                    Layout.preferredHeight: 45
                    Layout.alignment: Qt.AlignVCenter
                    color: root.currentEnergyMode === "balanced" ? root.color1 : Qt.alpha(root.textColor, 0.08)
                    radius: root.currentEnergyMode === "balanced" ? 30 : 12

                    Behavior on radius {
                        NumberAnimation {
                            duration: 200
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "balance"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 22
                        color: root.currentEnergyMode === "balanced" ? root.foreground : root.color1
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 1

                    Text {
                        Layout.fillWidth: true
                        text: "Balanced Mode"
                        font.pixelSize: 14
                        font.family: "Google Sans"
                        font.bold: true
                        color: root.textColor
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Dynamic and intelligent consumption (Default)"
                        font.pixelSize: 9
                        font.family: "Google Sans"
                        color: Qt.alpha(root.textColor, 0.5)
                    }
                }
            }

            HoverHandler {
                id: balItemH
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.setEnergyMode("balanced")
            }
        }

        // 3. Power saver mode card
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 65
            radius: 12
            color: root.currentEnergyMode === "power-saver" ? Qt.alpha(Colors.cfg.secondary, 0.2) : (savItemH.hovered ? Qt.alpha(root.textColor, 0.08) : Qt.alpha(root.textColor, 0.03))
            border.color: root.currentEnergyMode === "power-saver" ? Colors.cfg.secondary : Qt.alpha(root.textColor, 0.08)
            border.width: root.currentEnergyMode === "power-saver" ? 2 : 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 45
                    Layout.preferredHeight: 45
                    Layout.alignment: Qt.AlignVCenter
                    color: root.currentEnergyMode === "power-saver" ? Colors.cfg.secondary : Qt.alpha(root.textColor, 0.08)
                    radius: root.currentEnergyMode === "power-saver" ? 30 : 12

                    Behavior on radius {
                        NumberAnimation {
                            duration: 200
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "energy_savings_leaf"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 22
                        color: root.currentEnergyMode === "power-saver" ? root.foreground : Colors.cfg.secondary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 1

                    Text {
                        Layout.fillWidth: true
                        text: "Power Saver Mode"
                        font.pixelSize: 14
                        font.family: "Google Sans"
                        font.bold: true
                        color: root.textColor
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Reduces consumption for maximum autonomy"
                        font.pixelSize: 9
                        font.family: "Google Sans"
                        color: Qt.alpha(root.textColor, 0.5)
                    }
                }
            }

            HoverHandler {
                id: savItemH
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.setEnergyMode("power-saver")
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }

    // === LIFECYCLE ===
    Component.onCompleted: {
        powerGetProc.running = true;
    }
}
