import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Wayland
import qs.Modules.Bar.Widgets
import qs.Services

Item {
    id: root

    property color color1
    property alias primary: root.color1
    property alias text: root.color1
    readonly property bool isHovered: hoverHandler.hovered
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

    implicitWidth: bluetooth.implicitWidth + 12
    implicitHeight: bluetooth.implicitHeight
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
        spacing: root.isHovered ? 5 : 0

        Icon {
            name: icon
            color: root.color1
        }

        Text {
            id: bluetoothText

            visible: opacity > 0
            opacity: root.isHovered && isConnected && BluetoothService.activeDeviceName.length > 0 ? 1 : 0
            font.family: "Google Sans"
            font.pixelSize: 14
            font.weight: 500
            verticalAlignment: Text.AlignVCenter
            
            text: BluetoothService.activeDeviceName + batt
            color: color1

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }

            }

        }

    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }

    }

}
