import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Wayland
import qs.Modules.Bar.Widgets
import qs.Asura

Item {
    id: root

    property color color1
    property color color2
    property alias primary: root.color1
    property alias secondary: root.color2
    property bool isCharging: UPower.displayDevice && UPower.displayDevice.state === UPowerDeviceState.Charging
    
    property bool hidePercentage: false
    property bool pluggedIn: UPower.displayDevice ? (UPower.displayDevice.state === UPowerDeviceState.Unknown || UPower.displayDevice.state === UPowerDeviceState.FullyCharged) : false
    property int percent: UPower.displayDevice.isPresent ? Math.round(100 * UPower.displayDevice.percentage) : 100
    readonly property bool isHovered: hoverHandler.hovered
    property alias opened: root.isHovered
    property alias hovered: root.isHovered
    property string currentEnergyMode: "balanced"

    function setEnergyMode(modeName) {
        root.currentEnergyMode = modeName;
        powerSetProc.command = ["powerprofilesctl", "set", modeName];
        powerSetProc.running = false;
        powerSetProc.running = true;
    }

    Timer {
        interval: 5000
        running: root.pluggedIn || root.isCharging
        repeat: true
        triggeredOnStart: true
        onTriggered: powerGetProc.running = true
    }

    Process {
        id: powerSetProc
        command: []
    }

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

    signal clicked

    implicitWidth: root.isCharging ? batteryCharging.implicitWidth + 12 : battery.implicitWidth + 12 
    implicitHeight: battery.implicitHeight
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    HoverHandler {
        id: hoverHandler
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Rectangle {
        id: capsuleBackground
        anchors.fill: parent
        radius: height / 2
        color: root.color1
        opacity: root.isHovered ? 0.2 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
    }

    Row {
        id: battery
        visible: !root.isCharging && !root.pluggedIn
        anchors.centerIn: parent
        spacing: 2

        // Battery body
        Rectangle {
            id: batteryBody
            width: 25
            height: 15
            color: "transparent"
            Rectangle {
                id: batteryBackground
                anchors.fill: parent
                radius: 5
                opacity: 0.35
                color: root.color1
                border.width: 1.5
                border.color: root.color1
            }

            // Filler
            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 2

                width: Math.max(0, (parent.width - 4) * (root.percent / 100))
                radius: 3

                color: root.percent > 15 ? root.color1 : root.color2
                opacity: 1
            }

            // Percent number
            Text {
                anchors.centerIn: parent
                text: root.percent
                font.family: "Google Sans"
                font.pixelSize: 11
                color: root.percent > 15 ? root.color1 : Colors.cfg.surfaceContainer
            }
        }

        Rectangle {
            width: 3
            height: 8
            radius: 1.5
            color: root.color1
            opacity: 0.35
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    RowLayout {
        id: batteryCharging
        visible: root.isCharging || root.pluggedIn
        anchors.centerIn: parent
        spacing: 3

        Icon {
            name: root.isCharging ? "bolt" : (root.currentEnergyMode === "performance" ? "rocket_launch" : (root.currentEnergyMode === "balanced" ? "balance" : "energy_savings_leaf"))
            color: root.color1
        }

        Text {
            visible: opacity > 0
            font.family: "Google Sans"
            font.pixelSize: 14
            font.weight: 500
            verticalAlignment: Text.AlignVCenter

            text: (root.hidePercentage || root.pluggedIn ? "" : root.percent + "% ")
            color: root.percent > 15 ? root.color1 : root.color2
        }
    }
}