import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Asura
import qs.Modules.Bar.Widgets
import qs.Services

Item {
    id: root

    property color color1: Colors.cfg.textBright
    property alias primary: root.color1
    property alias text: root.color1

    property bool hoverEnabled: (typeof Config !== "undefined" && Config.barWidgetHoverTextEnabled !== undefined) ? Config.barWidgetHoverTextEnabled : true
    readonly property bool isHovered: hoverHandler.hovered && root.hoverEnabled
    property alias hovered: root.isHovered
    property alias opened: root.isHovered

    readonly property string shortCode: KeyboardLayoutService.shortLayout || "EN"
    readonly property string fullLayout: KeyboardLayoutService.currentLayout || ""

    signal clicked()

    readonly property bool isVertical: Config.isBarVertical
    implicitWidth: isVertical ? Math.round(22 * Config.barIconScale) : (contentRow.implicitWidth + Math.round(14 * Config.barIconScale))
    implicitHeight: isVertical ? Math.round(22 * Config.barIconScale) : Math.round(26 * Config.barIconScale)
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    HoverHandler {
        id: hoverHandler
        enabled: root.hoverEnabled
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            KeyboardLayoutService.nextLayout();
            root.clicked();
        }
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
        id: contentRow

        anchors.centerIn: parent
        spacing: root.isVertical ? 0 : 5

        Icon {
            id: kbdIcon

            visible: !root.isVertical
            name: "keyboard"
            size: 16
            color: root.color1
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            id: langLabel

            text: root.shortCode
            font.family: "Google Sans"
            font.pixelSize: Math.round((root.isVertical ? 11 : 12) * Config.barIconScale)
            font.weight: 600
            color: root.color1
            verticalAlignment: Text.AlignVCenter
            Layout.alignment: Qt.AlignVCenter

            Behavior on text {
                SequentialAnimation {
                    NumberAnimation {
                        target: langLabel
                        property: "scale"
                        to: 1.15
                        duration: 80
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: langLabel
                        property: "scale"
                        to: 1.0
                        duration: 120
                        easing.type: Easing.OutQuad
                    }
                }
            }
        }
    }

    ToolTip.visible: root.isHovered && root.fullLayout.length > 0
    ToolTip.text: qsTr("Keyboard: ") + root.fullLayout
    ToolTip.delay: 400
}
