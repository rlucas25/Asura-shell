import QtQuick
import QtQuick.Layouts
import Quickshell
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
    readonly property int count: ClipboardService.count
    property string icon: "content_paste"

    signal clicked()

    implicitWidth: clipLabel.implicitWidth + 12
    implicitHeight: clipLabel.implicitHeight
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

        anchors.centerIn: parent
        spacing: root.isHovered ? 5 : 0

        Icon {
            name: icon

            color: root.color1
        }

        Text {
            id: clipText
            visible: opacity > 0
            opacity: root.isHovered ? 1 : 0
            text: root.count;

            color: color1

            font.family: "Google Sans"
            font.pixelSize: 14
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

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }

    }

}
