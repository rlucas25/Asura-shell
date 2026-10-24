import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Wayland
import qs.Asura
import qs.Modules.Bar.Widgets

Item {
    id: root

    property color color1: Colors.cfg.textBright
    property color color2: Colors.cfg.secondary
    property alias primary: root.color1
    property alias secondary: root.color2
    property bool isCharging: UPower.displayDevice && UPower.displayDevice.state === UPowerDeviceState.Charging
    property bool hidePercentage: false
    readonly property bool hasBattery: !!(UPower.displayDevice && UPower.displayDevice.isPresent)
    property bool pluggedIn: !hasBattery || (UPower.displayDevice ? (UPower.displayDevice.state === UPowerDeviceState.Unknown || UPower.displayDevice.state === UPowerDeviceState.FullyCharged) : true)
    property int percent: hasBattery ? Math.round(100 * UPower.displayDevice.percentage) : 100
    property bool hoverEnabled: (typeof Config !== "undefined" && Config.barWidgetHoverTextEnabled !== undefined) ? Config.barWidgetHoverTextEnabled : true
    readonly property bool isHovered: hoverHandler.hovered
    readonly property bool expanded: isHovered && root.hoverEnabled
    property alias opened: root.isHovered
    property alias hovered: root.isHovered
    property string currentEnergyMode: "balanced"

    signal clicked()

    function setEnergyMode(modeName) {
        root.currentEnergyMode = modeName;
        powerSetProc.command = ["powerprofilesctl", "set", modeName];
        powerSetProc.running = false;
        powerSetProc.running = true;
    }

    readonly property bool isVertical: Config.isBarVertical
    implicitWidth: isVertical ? Math.round(22 * Config.barIconScale) : ((root.isCharging || root.pluggedIn) ? batteryCharging.implicitWidth + Math.round(12 * Config.barIconScale) : battery.implicitWidth + Math.round(12 * Config.barIconScale))
    implicitHeight: isVertical ? Math.round(22 * Config.barIconScale) : battery.implicitHeight
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

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
        scale: root.isVertical ? Math.min(1.0, (root.implicitWidth - 2) / 28) : 1.0

        Rectangle {
            id: batteryBody

            width: 27
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

            Text {
                anchors.centerIn: parent
                text: root.percent
                font.family: "GeistMono Mono Nerd Font Propo"
                font.pixelSize: root.percent >= 100 ? 9 : 10
                font.bold: true
                font.weight: Font.Bold
                color: Colors.cfg.surfaceContainer
                styleColor: root.percent > 50 ? root.color1 : Colors.cfg.surfaceContainer
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
            visible: opacity > 0 && !root.isVertical
            font.family: "Google Sans"
            font.pixelSize: Math.round(14 * Config.barIconScale)
            font.bold: true
            font.weight: Font.Bold
            verticalAlignment: Text.AlignVCenter
            text: (root.hidePercentage || root.pluggedIn ? "" : root.percent + "% ")
            color: root.percent > 15 ? root.color1 : root.color2
        }

    }

    ToolTip.visible: root.isVertical && root.expanded
    ToolTip.text: root.percent + "%" + (root.isCharging ? " (" + qsTr("Charging") + ")" : (root.pluggedIn ? " (" + qsTr("Plugged in") + ")" : ""))
    ToolTip.delay: 300

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }

    }

}
