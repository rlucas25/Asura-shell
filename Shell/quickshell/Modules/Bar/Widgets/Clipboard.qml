import QtQuick
import QtQuick.Layouts
import Quickshell
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
    readonly property int count: ClipboardService.count
    property string icon: "content_paste"

    signal clicked()

    readonly property bool isVertical: Config.isBarVertical
    implicitWidth: isVertical ? Math.round(22 * Config.barIconScale) : (clipLabel.implicitWidth + Math.round(12 * Config.barIconScale))
    implicitHeight: isVertical ? Math.round(22 * Config.barIconScale) : clipLabel.implicitHeight
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

    RowLayout {
        id: clipLabel

        visible: !root.isVertical
        anchors.centerIn: parent
        spacing: root.expanded ? 5 : 0

        Icon {
            name: icon

            color: root.color1
        }

        Text {
            id: clipText
            visible: opacity > 0
            opacity: root.expanded ? 1 : 0
            text: root.count;

            color: color1

            font.family: "Google Sans"
            font.pixelSize: Math.round(14 * Config.barIconScale)
            font.weight: 500
            verticalAlignment: Text.AlignVCenter
            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

        }

    }

    Item {
        id: verticalContent

        visible: root.isVertical
        anchors.centerIn: parent
        width: Math.round(22 * Config.barIconScale)
        height: Math.round(22 * Config.barIconScale)

        Icon {
            id: vClipIcon

            anchors.centerIn: parent
            name: root.icon
            color: root.color1
            opacity: root.expanded ? 0 : 1
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
        }

        Text {
            id: vClipCount

            anchors.centerIn: parent
            text: root.count
            font.family: "Google Sans"
            font.pixelSize: Math.round(11 * Config.barIconScale)
            font.weight: 600
            color: root.color1
            opacity: root.expanded ? 1 : 0
            visible: opacity > 0
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

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

