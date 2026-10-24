import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Wayland
import qs.Modules.Bar.Widgets
import qs.Services
import qs.Asura

Item {
    id: root

    property color color1: Colors.cfg.textBright
    property alias primary: root.color1
    property alias text: root.color1
    property bool hoverEnabled: (typeof Config !== "undefined" && Config.barWidgetHoverTextEnabled !== undefined) ? Config.barWidgetHoverTextEnabled : true
    readonly property bool isHovered: hoverHandler.hovered
    readonly property bool expanded: isHovered && root.hoverEnabled
    property alias hovered: root.isHovered
    property alias opened: root.isHovered
    readonly property bool isEnabled: BluetoothService.bluetoothEnabled
    readonly property bool isConnected: BluetoothService.hasConnectedDevice
    readonly property var connectedDev: isConnected ? BluetoothService.connectedDevices[0] : null
    property string icon: {
        if (!isEnabled)
            return "bluetooth_disabled";

        if (isConnected)
            return "bluetooth_connected";

        return "bluetooth";
    }

    signal clicked()

    readonly property bool isVertical: Config.isBarVertical
    implicitWidth: isVertical ? Math.round(22 * Config.barIconScale) : (bluetooth.implicitWidth + Math.round(12 * Config.barIconScale))
    implicitHeight: isVertical ? Math.round(22 * Config.barIconScale) : bluetooth.implicitHeight
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

        opacity: root.isHovered ? 0.2 : 0
        color: color1
        anchors.fill: parent
        radius: 100

        Behavior on opacity {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }
    }

    RowLayout {
        id: bluetooth

        anchors.centerIn: parent
        spacing: (!root.isVertical && root.expanded) ? 5 : 0

        Icon {
            name: icon
            color: root.color1
        }

        Text {
            id: bluetoothText

            visible: opacity > 0 && !root.isVertical
            opacity: (!root.isVertical && root.expanded && isConnected && BluetoothService.activeDeviceName.length > 0) ? 1 : 0
            font.family: "Google Sans"
            font.pixelSize: Math.round(14 * Config.barIconScale)
            font.weight: 500
            verticalAlignment: Text.AlignVCenter
            
            text: BluetoothService.activeDeviceName
            color: color1

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    ToolTip.visible: root.isVertical && root.expanded && isConnected && BluetoothService.activeDeviceName.length > 0
    ToolTip.text: BluetoothService.activeDeviceName
    ToolTip.delay: 300

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }
}
