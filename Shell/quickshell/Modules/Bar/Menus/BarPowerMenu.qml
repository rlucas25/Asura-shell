import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.Asura
import qs.Services
import qs.Animations

Item {
    id: root

    property color background: Colors.cfg.background
    property color surfaceContainer: Colors.cfg.surfaceContainer
    property color primary: Colors.cfg.primary
    property color on_primary: Colors.cfg.on_primary
    property color textColor: Colors.cfg.text
    property color secondary: Colors.cfg.secondary
    property color warning: Colors.cfg.warning
    property color success: Colors.cfg.success

    implicitWidth: 360
    implicitHeight: 380
    clip: true

    function executeAction(cmdArray) {
        sysCmdProc.command = cmdArray;
        sysCmdProc.running = false;
        sysCmdProc.running = true;
    }

    Process {
        id: sysCmdProc

        command: []
    }

    MenuEntrance {
        id: powerEntrance

        active: root.visible
        duration: 320
        startOffsetY: 14
        startScale: 0.96
    }

    component PowerHoldButton: Rectangle {
        id: btnRoot

        property string iconText: ""
        property string titleText: ""
        property color accentColor: Colors.cfg.secondary
        property int fillDuration: 650
        property real fillLevel: 0.0
        property bool isTriggered: false
        property real popScale: 1.0

        signal triggered()

        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 14
        clip: true
        scale: popScale

        color: btnHover.hovered ? Qt.alpha(accentColor, 0.15) : Qt.alpha(root.textColor, 0.04)
        border.color: btnHover.hovered ? Qt.alpha(accentColor, 0.4) : Qt.alpha(root.textColor, 0.08)
        border.width: 1

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: 150
            }
        }

        Rectangle {
            id: maskShape

            anchors.fill: parent
            radius: btnRoot.radius
            color: "white"
            visible: false
        }

        Item {
            id: fillContent

            anchors.fill: parent
            visible: false

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * btnRoot.fillLevel
                color: Qt.alpha(btnRoot.accentColor, 0.32)
            }
        }

        OpacityMask {
            anchors.fill: parent
            source: fillContent
            maskSource: maskShape
            visible: btnRoot.fillLevel > 0
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            Rectangle {
                implicitWidth: 32
                implicitHeight: 32
                radius: 16
                color: Qt.alpha(btnRoot.accentColor, btnRoot.fillLevel > 0.1 ? 0.45 : 0.2)

                Behavior on color {
                    ColorAnimation {
                        duration: 100
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: btnRoot.iconText
                    font.pixelSize: 16
                    font.family: "GeistMono Nerd Font Propo"
                    color: btnRoot.accentColor
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: btnRoot.titleText
                    font.pixelSize: 11
                    font.bold: true
                    font.family: "GeistMono Nerd Font Propo"
                    color: root.textColor
                }

                Text {
                    text: btnRoot.fillLevel > 0.01 ? "Hold to confirm..." : "Hold to activate"
                    font.pixelSize: 9
                    font.family: "GeistMono Nerd Font Propo"
                    color: btnRoot.fillLevel > 0.01 ? btnRoot.accentColor : Qt.alpha(root.textColor, 0.45)
                    opacity: btnHover.hovered || btnRoot.fillLevel > 0 ? 1.0 : 0.65
                }
            }
        }

        HoverHandler {
            id: btnHover
        }

        MouseArea {
            id: btnMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: btnRoot.isTriggered ? Qt.ArrowCursor : Qt.PointingHandCursor

            onPressed: {
                if (!btnRoot.isTriggered) {
                    drainAnim.stop();
                    fillAnim.start();
                }
            }

            onReleased: {
                if (!btnRoot.isTriggered && btnRoot.fillLevel < 1.0) {
                    fillAnim.stop();
                    drainAnim.start();
                }
            }

            onCanceled: {
                if (!btnRoot.isTriggered && btnRoot.fillLevel < 1.0) {
                    fillAnim.stop();
                    drainAnim.start();
                }
            }
        }

        NumberAnimation {
            id: fillAnim

            target: btnRoot
            property: "fillLevel"
            to: 1.0
            duration: btnRoot.fillDuration * (1.0 - btnRoot.fillLevel)
            easing.type: Easing.InQuad

            onFinished: {
                btnRoot.isTriggered = true;
                popAnim.start();
                btnRoot.triggered();
                autoResetTimer.restart();
            }
        }

        NumberAnimation {
            id: drainAnim

            target: btnRoot
            property: "fillLevel"
            to: 0.0
            duration: 180 * btnRoot.fillLevel
            easing.type: Easing.OutQuad
        }

        SequentialAnimation {
            id: popAnim

            NumberAnimation {
                target: btnRoot
                property: "popScale"
                to: 1.04
                duration: 80
                easing.type: Easing.OutQuad
            }

            NumberAnimation {
                target: btnRoot
                property: "popScale"
                to: 1.0
                duration: 120
                easing.type: Easing.OutQuad
            }
        }

        Timer {
            id: autoResetTimer

            interval: 1200
            repeat: false
            onTriggered: {
                btnRoot.isTriggered = false;
                btnRoot.fillLevel = 0.0;
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12
        opacity: powerEntrance.opacity
        scale: powerEntrance.scale
        transform: Translate {
            y: powerEntrance.offsetY
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            columnSpacing: 10
            rowSpacing: 10

            PowerHoldButton {
                iconText: "󰌾"
                titleText: "Lock"
                accentColor: Colors.cfg.secondary
                onTriggered: LockScreenService.lock()
            }

            PowerHoldButton {
                iconText: "󰤄"
                titleText: "Suspend"
                accentColor: Colors.cfg.secondary
                onTriggered: root.executeAction(["systemctl", "suspend"])
            }

            PowerHoldButton {
                iconText: "󰒲"
                titleText: "Hibernate"
                accentColor: root.primary
                onTriggered: root.executeAction(["systemctl", "hibernate"])
            }

            PowerHoldButton {
                iconText: "󰍃"
                titleText: "Log Out"
                accentColor: root.primary
                onTriggered: root.executeAction(["killall", "Hyprland"])
            }

            PowerHoldButton {
                iconText: "󰜉"
                titleText: "Reboot"
                accentColor: Colors.cfg.warning
                onTriggered: root.executeAction(["systemctl", "reboot"])
            }

            PowerHoldButton {
                iconText: "󰐥"
                titleText: "Shut Down"
                accentColor: Colors.cfg.warning
                onTriggered: root.executeAction(["systemctl", "poweroff"])
            }
        }
    }
}
