import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Animations
import qs.Asura
import qs.Services

Rectangle {
    id: root

    // Semantic colors
    property color primary: Colors.cfg.primary
    property color secondary: Colors.cfg.secondary
    property color tertiary: Colors.cfg.tertiary
    property color background: Colors.cfg.background
    property color surface: Qt.alpha(Colors.cfg.surface, Math.max(0, Math.min(1, Config.cfg.opacity)))
    property color surfaceContainer: Colors.cfg.surfaceContainer
    property color surfaceVariant: Colors.cfg.surfaceVariant
    property color borderCol: Colors.cfg.border
    property color on_primary: Colors.cfg.on_primary
    property color text: Colors.cfg.text
    property color textSecondary: Colors.cfg.textSecondary
    property color textBright: Colors.cfg.textBright
    property color warning: Colors.cfg.warning
    property color error: Colors.cfg.error
    property color success: Colors.cfg.success
    // Compatibility aliases
    property alias color1: root.primary
    property alias color2: root.secondary
    property alias textColor: root.text
    property alias textMuted: root.textSecondary
    property alias foreground: root.on_primary
    // Whether this tab is currently selected and visible
    property bool tabActive: false

    radius: 18
    color: root.surface

    // Staggered entrance animations
    CardEntrance {
        id: notifHeaderEntrance

        active: root.tabActive
        delay: 20
        startOffsetY: 12
    }

    CardEntrance {
        id: notifEmptyEntrance

        active: root.tabActive && NotificationService.notifications.length === 0
        delay: 60
        startOffsetY: 16
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        RowLayout {
            id: notifHeaderRow

            Layout.fillWidth: true
            opacity: notifHeaderEntrance.opacity
            scale: notifHeaderEntrance.scale

            Text {
                text: "Notification Center"
                font.pixelSize: 14
                font.bold: true
                color: root.textMuted
                Layout.fillWidth: true
            }

            Rectangle {
                implicitWidth: 80
                implicitHeight: 28
                radius: 8
                color: root.surfaceContainer
                border.color: Colors.cfg.warning

                Text {
                    anchors.centerIn: parent
                    text: "Clear All"
                    font.pixelSize: 10
                    font.bold: true
                    color: Colors.cfg.warning
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationService.clearAll()
                }

            }

            transform: Translate {
                y: notifHeaderEntrance.offsetY
            }

        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: notifCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: notifCol

                width: parent.width
                spacing: 8

                Repeater {
                    model: NotificationService.notifications

                    delegate: Rectangle {
                        id: notifCard

                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        Layout.preferredHeight: 84
                        radius: 16
                        color: cardH.hovered ? Qt.alpha(root.surfaceContainer, 0.9) : root.surfaceContainer
                        border.color: cardH.hovered ? Qt.alpha(root.color1, 0.4) : Qt.alpha(root.color1, 0.18)
                        border.width: 1
                        clip: true
                        opacity: notifCardEntrance.opacity
                        scale: notifCardEntrance.scale

                        HoverHandler {
                            id: cardH
                        }

                        // Staggered entrance animation for each notification item
                        CardEntrance {
                            id: notifCardEntrance

                            active: root.tabActive
                            delay: Math.min(50 + notifCard.index * 35, 250)
                            startOffsetY: 16
                        }

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
                                    text: (notifCard.modelData && (notifCard.modelData.appIcon || notifCard.modelData.icon)) ? (notifCard.modelData.appIcon || notifCard.modelData.icon) : "󰂚"
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
                                        text: (notifCard.modelData && notifCard.modelData.appName) ? notifCard.modelData.appName : "Notification"
                                        font.pixelSize: 10
                                        font.family: "GeistMono Nerd Font Propo"
                                        font.bold: true
                                        color: root.color1
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: (notifCard.modelData && notifCard.modelData.time) ? notifCard.modelData.time : ""
                                        font.pixelSize: 9
                                        font.family: "GeistMono Nerd Font Propo"
                                        color: Qt.alpha(root.textColor, 0.5)
                                    }

                                }

                                Text {
                                    text: (notifCard.modelData && (notifCard.modelData.summary || notifCard.modelData.title)) ? (notifCard.modelData.summary || notifCard.modelData.title) : ""
                                    font.pixelSize: 12
                                    font.family: "GeistMono Nerd Font Propo"
                                    font.bold: true
                                    color: root.textColor
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    visible: text.length > 0
                                }

                                Text {
                                    text: (notifCard.modelData && notifCard.modelData.body) ? notifCard.modelData.body : ""
                                    font.pixelSize: 10
                                    font.family: "GeistMono Nerd Font Propo"
                                    color: Qt.alpha(root.textColor, 0.7)
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    wrapMode: Text.NoWrap
                                    visible: text.length > 0
                                }

                            }

                            // Dismiss X Button
                            Rectangle {
                                Layout.preferredWidth: 26
                                Layout.preferredHeight: 26
                                radius: 13
                                color: notifCloseH.hovered ? Qt.alpha(Colors.cfg.warning, 0.2) : Qt.alpha(root.textColor, 0.06)
                                border.color: notifCloseH.hovered ? Qt.alpha(Colors.cfg.warning, 0.4) : "transparent"
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    font.pixelSize: 12
                                    font.family: "GeistMono Nerd Font Propo Propo"
                                    color: notifCloseH.hovered ? Colors.cfg.warning : Qt.alpha(root.textColor, 0.6)
                                }

                                HoverHandler {
                                    id: notifCloseH
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (notifCard.modelData && notifCard.modelData.id !== undefined) {
                                            NotificationService.removeNotification(notifCard.modelData.id);
                                        } else {
                                            NotificationService.removeNotification(notifCard.index);
                                        }
                                    }
                                }

                            }

                        }

                        transform: Translate {
                            y: notifCardEntrance.offsetY
                        }

                    }

                }

                ColumnLayout {
                    id: notifEmptyState

                    visible: NotificationService.notifications.length === 0
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 40
                    spacing: 6
                    opacity: notifEmptyEntrance.opacity
                    scale: notifEmptyEntrance.scale

                    Text {
                        text: "󰂚"
                        font.pixelSize: 32
                        font.family: "GeistMono Nerd Font Propo Propo"
                        color: Qt.alpha(root.textColor, 0.3)
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "No archived notifications"
                        font.pixelSize: 12
                        color: root.textMuted
                        Layout.alignment: Qt.AlignHCenter
                    }

                    transform: Translate {
                        y: notifEmptyEntrance.offsetY
                    }

                }

            }

        }

    }

}
