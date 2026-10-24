import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import qs.Services

Item {
    id: winItem

    required property var root
    required property var screenMockup
    required property var previewCard
    property int windowId: 0
    property string title: ""
    property string icon: ""
    readonly property bool isFocused: previewCard.focusedWindowId === windowId

    RectangularGlow {
        anchors.fill: winRect
        visible: WindowService.shadowEnabled
        glowRadius: screenMockup.previewShadowRange
        spread: 0.05
        color: Qt.rgba(0, 0, 0, winItem.isFocused ? 0.65 : 0.38)
        cornerRadius: screenMockup.previewRounding + 2
    }

    Rectangle {
        id: winRect
        anchors.fill: parent
        radius: screenMockup.previewRounding
        color: Qt.alpha(root.surface, winItem.isFocused ? WindowService.activeOpacity : WindowService.inactiveOpacity)
        border.color: winItem.isFocused ? root.color1 : Qt.alpha(root.textColor, 0.22)
        border.width: screenMockup.previewBorder
        clip: true

        Rectangle {
            id: winHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 18
            color: winItem.isFocused ? Qt.alpha(root.color1, 0.2) : Qt.alpha(root.textColor, 0.07)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                spacing: 4

                Rectangle { implicitWidth: 6; implicitHeight: 6; radius: 3; color: winItem.isFocused ? "#ef5350" : Qt.alpha(root.textColor, 0.25) }
                Rectangle { implicitWidth: 6; implicitHeight: 6; radius: 3; color: winItem.isFocused ? "#ffca28" : Qt.alpha(root.textColor, 0.25) }
                Rectangle { implicitWidth: 6; implicitHeight: 6; radius: 3; color: winItem.isFocused ? "#66bb6a" : Qt.alpha(root.textColor, 0.25) }

                Text {
                    text: winItem.title + (winItem.isFocused ? qsTr(" (Active)") : "")
                    font.pixelSize: 8
                    font.bold: winItem.isFocused
                    font.family: "Google Sans"
                    color: winItem.isFocused ? root.textBright : root.textMuted
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    leftPadding: 3
                }
            }
        }

        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 6
            text: winItem.icon
            font.pixelSize: 22
            font.family: "Material Symbols Rounded"
            color: winItem.isFocused ? Qt.alpha(root.color1, 0.5) : Qt.alpha(root.textColor, 0.18)
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: previewCard.focusedWindowId = winItem.windowId
        }
    }
}
