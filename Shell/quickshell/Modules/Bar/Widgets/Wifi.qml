import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Services
import qs.Modules.Bar.Widgets
import qs.Asura

Item {
    id: root

    property color color1: Colors.cfg.textBright
    property alias primary: root.color1
    property alias text: root.color1

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

    signal clicked()

    readonly property bool isVertical: Config.isBarVertical
    implicitWidth: isVertical ? Math.round(22 * Config.barIconScale) : (wifiIcon.implicitWidth + Math.round(12 * Config.barIconScale))
    implicitHeight: isVertical ? Math.round(22 * Config.barIconScale) : wifiIcon.implicitHeight
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
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
        fill: 1
    }
}