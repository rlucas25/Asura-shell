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

    readonly property string layoutName: WindowModeService.currentLayoutName
    readonly property string layoutIcon: WindowModeService.currentLayoutIcon
    readonly property string layoutDesc: WindowModeService.currentLayoutDesc

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
            WindowModeService.cycleLayout();
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
        spacing: root.isVertical ? 0 : 6

        Text {
            id: modeIcon

            text: root.layoutIcon
            font.family: "GeistMono Nerd Font Propo"
            font.pixelSize: Math.round((root.isVertical ? 15 : 16) * Config.barIconScale)
            color: root.color1
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Layout.alignment: Qt.AlignVCenter

            Behavior on text {
                SequentialAnimation {
                    NumberAnimation {
                        target: modeIcon
                        property: "scale"
                        to: 1.25
                        duration: 80
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: modeIcon
                        property: "scale"
                        to: 1.0
                        duration: 120
                        easing.type: Easing.OutQuad
                    }
                }
            }
        }

        Text {
            id: modeLabel

            visible: !root.isVertical
            text: root.layoutName
            font.family: "Google Sans"
            font.pixelSize: Math.round(12 * Config.barIconScale)
            font.weight: 600
            color: root.color1
            verticalAlignment: Text.AlignVCenter
            Layout.alignment: Qt.AlignVCenter

            Behavior on text {
                SequentialAnimation {
                    NumberAnimation {
                        target: modeLabel
                        property: "scale"
                        to: 1.12
                        duration: 80
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: modeLabel
                        property: "scale"
                        to: 1.0
                        duration: 120
                        easing.type: Easing.OutQuad
                    }
                }
            }
        }
    }

    ToolTip.visible: root.isHovered
    ToolTip.text: qsTr("Window Layout: ") + root.layoutName + " (" + root.layoutDesc + ")\n" + qsTr("Click to cycle layout (Super+Tab)")
    ToolTip.delay: 400
}
