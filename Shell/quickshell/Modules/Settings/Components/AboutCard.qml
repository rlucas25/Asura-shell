import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Asura

Rectangle {
    id: cardRoot

    property string icon: ""
    property string label: ""
    property string value: ""
    property string subtitle: ""
    property real progress: -1 // 0.0 to 1.0, or -1 if no progress bar
    property color accentColor: Colors.cfg.primary
    property var clickAction: null
    property string copyText: ""
    signal copied(string text)

    Layout.fillWidth: true
    implicitHeight: 82
    radius: 14
    color: cardMa.containsMouse ? Qt.alpha(Colors.cfg.surface, 0.95) : Colors.cfg.surface
    border.color: cardMa.containsMouse ? Qt.alpha(cardRoot.accentColor, 0.45) : Qt.alpha(Colors.cfg.base03, 0.4)
    border.width: 1
    scale: cardMa.pressed ? 0.98 : (cardMa.containsMouse ? 1.01 : 1.0)

    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 14

        Rectangle {
            implicitWidth: 46
            implicitHeight: 46
            radius: 12
            color: Qt.alpha(cardRoot.accentColor, 0.15)
            border.color: Qt.alpha(cardRoot.accentColor, 0.3)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: cardRoot.icon
                font.pixelSize: 24
                font.family: "Material Symbols Rounded"
                color: cardRoot.accentColor
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Text {
                text: cardRoot.label.toUpperCase()
                font.pixelSize: 11
                font.bold: true
                font.family: "Google Sans"
                color: Colors.cfg.textSecondary
                elide: Text.ElideRight
            }

            Text {
                text: cardRoot.value !== "" ? cardRoot.value : qsTr("Loading...")
                font.pixelSize: 14
                font.bold: true
                font.family: "Google Sans"
                color: Colors.cfg.textBright
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                visible: cardRoot.subtitle !== "" && cardRoot.progress < 0
                text: cardRoot.subtitle
                font.pixelSize: 11
                font.family: "Google Sans"
                color: Colors.cfg.textSecondary
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Rectangle {
                visible: cardRoot.progress >= 0
                Layout.fillWidth: true
                implicitHeight: 4
                radius: 2
                color: Qt.alpha(Colors.cfg.base03, 0.5)

                Rectangle {
                    width: Math.max(0, Math.min(parent.width, parent.width * cardRoot.progress))
                    height: parent.height
                    radius: 2
                    color: cardRoot.progress > 0.85 ? Colors.cfg.error : (cardRoot.progress > 0.7 ? Colors.cfg.warning : cardRoot.accentColor)

                    Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }

        Rectangle {
            visible: cardRoot.clickAction !== null || cardRoot.copyText !== ""
            implicitWidth: 28
            implicitHeight: 28
            radius: 14
            color: cardMa.containsMouse ? Qt.alpha(cardRoot.accentColor, 0.2) : Qt.alpha(Colors.cfg.base03, 0.25)

            Text {
                anchors.centerIn: parent
                text: cardRoot.copyText !== "" ? "content_copy" : "chevron_right"
                font.pixelSize: 16
                font.family: "Material Symbols Rounded"
                color: cardMa.containsMouse ? cardRoot.accentColor : Colors.cfg.textSecondary
            }
        }
    }

    MouseArea {
        id: cardMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: (cardRoot.clickAction !== null || cardRoot.copyText !== "") ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (cardRoot.clickAction) {
                cardRoot.clickAction();
            } else if (cardRoot.copyText !== "") {
                Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | wl-copy", "_", cardRoot.copyText]);
                cardRoot.copied(cardRoot.copyText);
            }
        }
    }

    ToolTip.visible: cardMa.containsMouse && (cardRoot.copyText !== "" || cardRoot.clickAction !== null)
    ToolTip.text: cardRoot.copyText !== "" ? qsTr("Click to copy: %1").arg(cardRoot.copyText) : qsTr("Click to open")
    ToolTip.delay: 400
}
