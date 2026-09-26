import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.Asura
import qs.Services

PanelWindow {
    id: root

    property color primary: Colors.cfg.primary
    property color secondary: Colors.cfg.secondary
    property color background: Colors.cfg.background
    property color surfaceContainer: Colors.cfg.surfaceContainer
    property color on_primary: Colors.cfg.on_primary
    property color text: Colors.cfg.text

    // Compatibility aliases
    property alias color1: root.primary
    property alias color2: root.secondary
    property alias foreground: root.on_primary
    property alias textColor: root.text

    signal notificationClicked()

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        right: true
    }

    margins {
        top: 30
        right: 10
    }

    implicitWidth: 360
    implicitHeight: 110
    color: "transparent"

    visible: NotificationService.popupVisible

    mask: Region {
        item: toastCard
    }

    Rectangle {
        id: toastCard
        anchors.fill: parent
        radius: 16
        color: background
        border.color: Qt.alpha(root.color1, 0.4)
        border.width: 1
        clip: true

        opacity: NotificationService.popupVisible ? 1.0 : 0.0
        scale: NotificationService.popupVisible ? 1.0 : 0.92

        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // App Icon Circle
            Rectangle {
                Layout.preferredWidth: 42
                Layout.preferredHeight: 42
                radius: 21
                color: Qt.alpha(root.color1, 0.15)
                border.color: Qt.alpha(root.color1, 0.3)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: NotificationService.activePopup ? NotificationService.activePopup.appIcon : "󰂚"
                    font.pixelSize: 20
                    font.family: "GeistMono Nerd Font Propo Propo"
                    color: root.color1
                }
            }

            // Notification Info
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: NotificationService.activePopup ? NotificationService.activePopup.appName : "Notificação"
                        font.pixelSize: 10
                        font.family: "GeistMono Nerd Font Propo"
                        font.bold: true
                        color: root.color1
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: NotificationService.activePopup ? NotificationService.activePopup.time : ""
                        font.pixelSize: 9
                        font.family: "GeistMono Nerd Font Propo"
                        color: Qt.alpha(root.textColor, 0.5)
                    }
                }

                Text {
                    text: NotificationService.activePopup ? NotificationService.activePopup.summary : ""
                    font.pixelSize: 12
                    font.family: "GeistMono Nerd Font Propo"
                    font.bold: true
                    color: root.textColor
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: NotificationService.activePopup ? NotificationService.activePopup.body : ""
                    font.pixelSize: 10
                    font.family: "GeistMono Nerd Font Propo"
                    color: Qt.alpha(root.textColor, 0.7)
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                }
            }

            // Dismiss X Button
            Rectangle {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                radius: 13
                color: closeH.hovered ? Qt.alpha(Colors.cfg.warning, 0.2) : Qt.alpha(root.textColor, 0.06)

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    font.pixelSize: 12
                    font.family: "GeistMono Nerd Font Propo Propo"
                    color: closeH.hovered ? Colors.cfg.warning : Qt.alpha(root.textColor, 0.6)
                }

                HoverHandler { id: closeH }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        NotificationService.dismissPopup();
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.notificationClicked();
            }
        }
    }
}
