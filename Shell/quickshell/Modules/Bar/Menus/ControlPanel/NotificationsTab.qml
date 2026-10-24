import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Animations
import qs.Asura
import qs.Services
import qs.Components

Rectangle {
    id: root

    property color primary: Colors.cfg.primary
    property color secondary: Colors.cfg.secondary
    property color tertiary: Colors.cfg.tertiary
    property color background: Colors.cfg.background
    property color surface: Qt.alpha(Colors.cfg.surface, Config.effectiveGeneralOpacity)
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
    property alias color1: root.primary
    property alias color2: root.secondary
    property alias textColor: root.text
    property alias textMuted: root.textSecondary
    property alias foreground: root.on_primary
    property bool tabActive: false

    radius: Config.effectiveGeneralRadius
    color: root.surface
    border.color: Qt.alpha(root.textColor, 0.08)
    border.width: 1

    CardEntrance {
        id: notifHeaderEntrance

        active: root.tabActive
        delay: 20
        startOffsetY: 12
    }

    CardEntrance {
        id: notifListEntrance

        active: root.tabActive
        delay: 50
        duration: 340
        startOffsetY: 18
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
                font.family: "Google Sans"
                font.pixelSize: 14
                font.bold: true
                color: root.textMuted
                Layout.fillWidth: true
            }

            Rectangle {
                id: clearAllBtn

                visible: NotificationService.notifications.length > 0
                implicitWidth: 84
                implicitHeight: 28
                radius: Math.round(Config.effectiveGeneralRadius * 0.5)
                color: clearAllH.hovered ? Qt.alpha(Colors.cfg.warning, 0.18) : root.surfaceContainer
                border.color: clearAllH.hovered ? Colors.cfg.warning : Qt.alpha(Colors.cfg.warning, 0.35)
                border.width: 1
                scale: clearAllMouse.pressed ? 0.92 : (clearAllH.hovered ? 1.04 : 1)

                Behavior on scale {
                    NumberAnimation {
                        duration: 140
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                HoverHandler {
                    id: clearAllH
                }

                Text {
                    anchors.centerIn: parent
                    text: "Clear All"
                    font.family: "Google Sans"
                    font.pixelSize: 11
                    font.bold: true
                    color: Colors.cfg.warning
                }

                MouseArea {
                    id: clearAllMouse

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationService.clearAll()
                }

            }

            transform: Translate {
                y: notifHeaderEntrance.offsetY
            }

        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Flickable {
                id: notifFlickable

                anchors.fill: parent
                contentHeight: notifCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                visible: NotificationService.notifications.length > 0
                opacity: notifListEntrance.opacity
                scale: notifListEntrance.scale

                transform: Translate {
                    y: notifListEntrance.offsetY
                }

                ColumnLayout {
                    id: notifCol

                    width: notifFlickable.width
                    spacing: 8

                    Repeater {
                        model: (NotificationService.notifications || []).slice(0, 20)

                        delegate: Rectangle {
                            id: notifCard

                            required property var modelData
                            required property int index

                            readonly property var notifId: (modelData && modelData.id !== undefined) ? modelData.id : null
                            property bool dismissing: false

                            Layout.fillWidth: true
                            Layout.preferredHeight: dismissing ? 0 : 84
                            radius: Math.round(Config.effectiveGeneralRadius * 0.88)
                            color: cardH.hovered ? Qt.alpha(root.surfaceVariant, 0.6) : root.surfaceContainer
                            border.color: cardH.hovered ? Qt.alpha(root.color1, 0.35) : Qt.alpha(root.textColor, 0.08)
                            border.width: 1
                            clip: true
                            opacity: dismissing ? 0.0 : 1.0
                            scale: dismissing ? 0.95 : (cardH.hovered ? 1.01 : 1.0)

                            Behavior on Layout.preferredHeight {
                                NumberAnimation {
                                    duration: 220
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 180
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 180
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 160
                                    easing.type: Easing.OutCubic
                                }
                            }

                            transform: Translate {
                                x: notifCard.dismissing ? 50 : 0

                                Behavior on x {
                                    NumberAnimation {
                                        duration: 180
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            Timer {
                                id: dismissTimer

                                interval: 220
                                repeat: false
                                onTriggered: {
                                    if (notifCard.notifId !== null && notifCard.notifId !== undefined) {
                                        NotificationService.removeNotification(notifCard.notifId);
                                    } else {
                                        NotificationService.removeNotification(notifCard.index);
                                    }
                                }
                            }

                            HoverHandler {
                                id: cardH
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                Rectangle {
                                    Layout.preferredWidth: 42
                                    Layout.preferredHeight: 42
                                    radius: 21
                                    color: Qt.alpha(root.color1, 0.15)
                                    border.color: Qt.alpha(root.color1, 0.3)
                                    border.width: 1

                                    ThemedIcon {
                                        anchors.centerIn: parent
                                        size: 22
                                        source: (notifCard.modelData && (notifCard.modelData.appIcon || notifCard.modelData.icon)) ? (notifCard.modelData.appIcon || notifCard.modelData.icon) : "preferences-desktop-notification"
                                        color: root.color1
                                        fallbackGlyph: "notifications"
                                    }

                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 2

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Text {
                                            text: (notifCard.modelData && notifCard.modelData.appName) ? notifCard.modelData.appName : "Notification"
                                            font.pixelSize: 11
                                            font.family: "Google Sans"
                                            font.bold: true
                                            color: root.color1
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: (notifCard.modelData && notifCard.modelData.time) ? notifCard.modelData.time : ""
                                            font.pixelSize: 10
                                            font.family: "Google Sans"
                                            color: Qt.alpha(root.textColor, 0.5)
                                        }

                                    }

                                    Text {
                                        text: (notifCard.modelData && (notifCard.modelData.summary || notifCard.modelData.title)) ? (notifCard.modelData.summary || notifCard.modelData.title) : ""
                                        font.pixelSize: 12
                                        font.family: "Google Sans"
                                        font.bold: true
                                        color: root.textColor
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        visible: text.length > 0
                                    }

                                    Text {
                                        text: (notifCard.modelData && notifCard.modelData.body) ? notifCard.modelData.body : ""
                                        font.pixelSize: 11
                                        font.family: "Google Sans"
                                        color: Qt.alpha(root.textColor, 0.7)
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        wrapMode: Text.NoWrap
                                        visible: text.length > 0
                                    }

                                }

                                Rectangle {
                                    Layout.preferredWidth: 26
                                    Layout.preferredHeight: 26
                                    radius: 13
                                    color: notifCloseH.hovered ? Qt.alpha(Colors.cfg.warning, 0.2) : Qt.alpha(root.textColor, 0.06)
                                    border.color: notifCloseH.hovered ? Qt.alpha(Colors.cfg.warning, 0.4) : "transparent"
                                    border.width: 1
                                    scale: notifCloseMouse.pressed ? 0.90 : (notifCloseH.hovered ? 1.08 : 1)

                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 140
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 180
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "close"
                                        font.pixelSize: 14
                                        font.family: "Material Symbols Rounded"
                                        color: notifCloseH.hovered ? Colors.cfg.warning : Qt.alpha(root.textColor, 0.6)
                                    }

                                    HoverHandler {
                                        id: notifCloseH
                                    }

                                    MouseArea {
                                        id: notifCloseMouse

                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (notifCard.dismissing) return;
                                            notifCard.dismissing = true;
                                            dismissTimer.restart();
                                        }
                                    }

                                }

                            }

                        }

                    }

                }

            }

            ColumnLayout {
                id: notifEmptyState

                anchors.centerIn: parent
                visible: NotificationService.notifications.length === 0
                spacing: 8
                opacity: notifEmptyEntrance.opacity
                scale: notifEmptyEntrance.scale

                Text {
                    text: "notifications_off"
                    font.pixelSize: 36
                    font.family: "Material Symbols Rounded"
                    color: Qt.alpha(root.textColor, 0.3)
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "No archived notifications"
                    font.family: "Google Sans"
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
