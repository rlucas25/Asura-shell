import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Asura

RowLayout {
    id: toggleRoot

    property string icon: ""
    property string title: ""
    property string description: ""
    property string hint: ""
    property string hintIcon: "help"
    property bool checked: false
    signal toggled(bool newState)

    Layout.fillWidth: true
    spacing: 14

    Rectangle {
        visible: toggleRoot.icon !== ""
        implicitWidth: 36
        implicitHeight: 36
        radius: 10
        color: toggleRoot.checked ? Qt.alpha(Colors.cfg.primary, 0.22) : Qt.alpha(Colors.cfg.base03, 0.35)
        border.color: toggleRoot.checked ? Qt.alpha(Colors.cfg.primary, 0.45) : "transparent"
        border.width: 1

        Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Text {
            anchors.centerIn: parent
            text: toggleRoot.icon
            font.pixelSize: 18
            font.family: "Material Symbols Rounded"
            color: toggleRoot.checked ? Colors.cfg.primary : Colors.cfg.textSecondary
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: toggleRoot.description !== "" ? 3 : 0

        RowLayout {
            spacing: 6
            Layout.fillWidth: true

            Text {
                text: toggleRoot.title
                font.pixelSize: 14
                font.bold: true
                font.family: "Google Sans"
                color: Colors.cfg.textBright
            }

            Rectangle {
                visible: toggleRoot.hint !== ""
                implicitWidth: 18
                implicitHeight: 18
                radius: 9
                color: hintMa.containsMouse ? Qt.alpha(Colors.cfg.primary, 0.22) : Qt.alpha(Colors.cfg.base03, 0.3)
                border.color: hintMa.containsMouse ? Qt.alpha(Colors.cfg.primary, 0.5) : "transparent"
                border.width: 1

                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: toggleRoot.hintIcon
                    font.pixelSize: 12
                    font.family: "Material Symbols Rounded"
                    color: hintMa.containsMouse ? Colors.cfg.primary : Colors.cfg.textSecondary
                }

                MouseArea {
                    id: hintMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.WhatsThisCursor
                }

                ToolTip.visible: hintMa.containsMouse
                ToolTip.text: toggleRoot.hint
                ToolTip.delay: 200
            }

            Item { Layout.fillWidth: true }
        }

        Text {
            visible: toggleRoot.description !== ""
            text: toggleRoot.description
            font.pixelSize: 12
            font.family: "Google Sans"
            color: Colors.cfg.textSecondary
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }

    Rectangle {
        id: switchTrack

        implicitWidth: 50
        implicitHeight: 28
        radius: 14
        color: toggleRoot.checked ? Colors.cfg.primary : (toggleMa.containsMouse ? Qt.alpha(Colors.cfg.base03, 0.45) : Colors.cfg.surfaceContainer)
        border.color: toggleRoot.checked ? Colors.cfg.primary : (toggleMa.containsMouse ? Colors.cfg.base05 : Colors.cfg.base03)
        border.width: 1
        scale: toggleMa.pressed ? 0.95 : (toggleMa.containsMouse ? 1.02 : 1.0)

        Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.centerIn: thumb
            width: 34
            height: 34
            radius: 17
            color: toggleRoot.checked ? Colors.cfg.primary : Colors.cfg.text
            opacity: toggleMa.pressed ? 0.20 : (toggleMa.containsMouse ? 0.08 : 0.0)
            scale: toggleMa.pressed ? 1.08 : (toggleMa.containsMouse ? 1.0 : 0.6)

            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }

        Rectangle {
            id: thumb

            readonly property real finalWidth: toggleMa.pressed ? 24 : (toggleRoot.checked ? 22 : 18)

            anchors.verticalCenter: parent.verticalCenter
            width: finalWidth
            height: toggleRoot.checked ? 22 : 18
            radius: height / 2
            x: toggleRoot.checked
                ? (parent.width - finalWidth - (toggleMa.pressed ? 2 : 3))
                : (toggleMa.pressed ? 2 : 3)
            color: toggleRoot.checked ? Colors.cfg.on_primary : (toggleMa.containsMouse ? Colors.cfg.textBright : Colors.cfg.text)

            Behavior on x {
                NumberAnimation {
                    duration: 240
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.15
                }
            }
            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            id: toggleMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                toggleRoot.toggled(!toggleRoot.checked);
            }
        }
    }
}
