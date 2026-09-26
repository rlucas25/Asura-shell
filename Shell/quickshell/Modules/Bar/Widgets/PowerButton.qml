import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import qs.Asura
import qs.Modules.Bar.Widgets

Item {
    id: root

    property color color1: Colors.cfg.primary
    property color warningColor: Colors.cfg.warning

    property alias primary: root.color1
    property alias secondary: root.color1
    property alias warning: root.warningColor

    signal clicked()

    // ---------------------------------------------------------
    // SIZE
    // ---------------------------------------------------------

    implicitWidth: powerIcon.implicitWidth + 12
    implicitHeight: powerIcon.implicitHeight

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

    readonly property bool isHovered: hoverHandler.hovered

    property alias hovered: root.isHovered
    property alias opened: root.isHovered

    MouseArea {
        anchors.fill: parent

        cursorShape: Qt.PointingHandCursor

        onClicked: {
            root.clicked()
        }
    }

    Rectangle {
        id: capsuleBackground

        anchors.fill: parent

        radius: height / 2

        color: root.warningColor

        opacity: root.isHovered ? 0.2 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }
    }

    // ---------------------------------------------------------
    // ICON
    // ---------------------------------------------------------

    Icon {
        id: powerIcon

        anchors.centerIn: parent

        name: "power_settings_new"


        color: root.isHovered
            ? root.warningColor
            : root.color1
    }
}