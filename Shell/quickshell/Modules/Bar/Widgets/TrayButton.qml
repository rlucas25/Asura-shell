import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import qs.Asura
import qs.Modules.Bar.Menus

Item {
    id: root

    readonly property int itemCount: (SystemTray.items && SystemTray.items.values) ? SystemTray.items.values.length : (SystemTray.items ? SystemTray.items.length : 0)
    property color color1: Colors.cfg.primary
    property alias primary: root.color1
    property alias text: root.color1
    property bool openTray: false
    property bool appMenuOpen: false
    property alias menuOpen: root.openTray
    property var parentWindow: null
    property bool hovered: false

    visible: itemCount > 0
    implicitWidth: visible ? mainRow.implicitWidth : 0
    implicitHeight: 30

    Timer {
        id: hideTimer

        interval: 800
        repeat: false
        onTriggered: {
            if (!root.hovered && !root.appMenuOpen)
                root.openTray = false;

        }
    }

    RowLayout {
        id: mainRow

        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Item {
            implicitWidth: 20
            implicitHeight: 20

            Text {
                anchors.centerIn: parent
                text: root.openTray ? "󰅂" : "󰅀"
                font.pixelSize: 16
                font.family: "GeistMono Nerd Font Propo Propo"
                color: root.color1

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }

                }

            }

            HoverHandler {
                id: trayH

                onHoveredChanged: {
                    root.hovered = hovered;
                    if (hovered) {
                        root.openTray = true;
                        hideTimer.stop();
                    } else {
                        hideTimer.restart();
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.openTray = !root.openTray;
                    if (root.openTray)
                        hideTimer.stop();

                }
            }

        }

        RowLayout {
            id: trayIcons

            visible: root.openTray
            opacity: root.openTray ? 1 : 0
            spacing: 6

            Repeater {
                model: SystemTray.items

                delegate: Rectangle {
                    id: trayItemRoot

                    required property var modelData

                    implicitWidth: 22
                    implicitHeight: 22
                    radius: 6
                    color: itemMouse.containsMouse ? Qt.alpha(root.color1, 0.2) : "transparent"

                    Image {
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        source: trayItemRoot.modelData.icon
                        sourceSize.width: 16
                        sourceSize.height: 16
                        smooth: true
                    }

                    TrayContextMenu {
                        id: trayMenu

                        menu: trayItemRoot.modelData.menu
                        parentWindow: root.parentWindow
                        trayItem: trayItemRoot.modelData
                        x: trayItemRoot.mapToItem(null, 0, trayItemRoot.height).x
                        y: trayItemRoot.mapToItem(null, 0, trayItemRoot.height).y
                        onOpened: {
                            root.appMenuOpen = true;
                            root.hovered = true;
                            hideTimer.stop();
                        }
                        onClosed: {
                            root.appMenuOpen = false;
                            if (!root.hovered)
                                hideTimer.restart();

                        }
                    }

                    MouseArea {
                        id: itemMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        cursorShape: Qt.PointingHandCursor
                        onEntered: {
                            root.hovered = true;
                            hideTimer.stop();
                        }
                        onExited: {
                            root.hovered = false;
                            if (!trayMenu.visible)
                                hideTimer.restart();

                        }
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.RightButton) {
                                if (trayItemRoot.modelData.hasMenu && trayItemRoot.modelData.menu) {
                                    if (trayMenu.visible)
                                        trayMenu.close();
                                    else
                                        trayMenu.open();
                                }
                                return ;
                            }
                            if (mouse.button === Qt.MiddleButton) {
                                trayItemRoot.modelData.secondaryActivate();
                                return ;
                            }
                            if (trayItemRoot.modelData.onlyMenu && trayItemRoot.modelData.hasMenu)
                                trayMenu.open();
                            else
                                trayItemRoot.modelData.activate();
                        }
                        onWheel: (wheel) => {
                            var delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.pixelDelta.y;
                            if (delta !== 0)
                                trayItemRoot.modelData.scroll(delta > 0 ? 1 : -1, Qt.Vertical);

                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }

                    }

                }

            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCirc
                }

            }

        }

    }

}
