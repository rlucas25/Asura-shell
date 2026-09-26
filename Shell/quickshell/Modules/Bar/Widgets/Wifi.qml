import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Services
import qs.Modules.Bar.Widgets

// === NETWORK STATUS WIDGET ===

Item {
    id: root

    // Theme color properties
    property color color1: "#c3c0ff"
    property alias primary: root.color1
    property alias text: root.color1

    // State properties
    readonly property bool isHovered: hoverHandler.hovered
    property alias hovered: root.isHovered
    property alias opened: root.isHovered

    readonly property bool isEthernet: WifiService.ethernetConnected
    readonly property string ethName: WifiService.ethernetName
    readonly property int wifiSignal: WifiService.activeSignal
    readonly property string wifiName: WifiService.activeSsid
    readonly property bool isEnabled: WifiService.wifiEnabled
    readonly property bool isConnected: WifiService.connected || isEthernet
    readonly property string icon: WifiService.getNetworkIcon()

    // Signals
    signal clicked()

    // Geometry and sizing
    implicitWidth: wifiIcon.implicitWidth + 12
    implicitHeight: wifiIcon.implicitHeight
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    // === VISUAL CAPSULE & ICON ===

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
                duration: 250
                easing.type: Easing.OutCubic
            }
        }
    }

    Icon {
        id: wifiIcon

        anchors.centerIn: parent
        name: root.icon
        color: root.color1
        font.variableAxes: fill
    }
}