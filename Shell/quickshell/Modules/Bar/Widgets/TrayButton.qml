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
    readonly property bool isVertical: Config.isBarVertical
    property color color1: Colors.cfg.textBright
    property alias primary: root.color1
    property alias text: root.color1
    property bool openTray: false
    property bool appMenuOpen: false
    property alias menuOpen: root.openTray
    property var parentWindow: null
    property bool hovered: false

    visible: itemCount > 0
    implicitWidth: visible ? (isVertical ? Math.round(24 * Config.barIconScale) : mainLayout.implicitWidth) : 0
    implicitHeight: visible ? (isVertical ? mainLayout.implicitHeight : Math.round(30 * Config.barIconScale)) : 0

    Timer {
        id: hideTimer

        interval: 800
        repeat: false
        onTriggered: {
            if (!root.hovered && !root.appMenuOpen)
                root.openTray = false;
        }
    }

    GridLayout {
        id: mainLayout

        columns: isVertical ? 1 : -1
        rows: isVertical ? -1 : 1
        anchors.centerIn: parent
        rowSpacing: isVertical ? 6 : 0
        columnSpacing: isVertical ? 0 : 8

        Item {
            implicitWidth: Math.round(20 * Config.barIconScale)
            implicitHeight: Math.round(20 * Config.barIconScale)
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: isVertical ? (root.openTray ? "󰅃" : "󰅀") : (root.openTray ? "󰅂" : "󰅀")
                font.pixelSize: Math.round(16 * Config.barIconScale)
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

        GridLayout {
            id: trayIcons

            columns: isVertical ? 1 : -1
            rows: isVertical ? -1 : 1
            visible: root.openTray
            opacity: root.openTray ? 1 : 0
            rowSpacing: isVertical ? 6 : 0
            columnSpacing: isVertical ? 0 : 6
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

            Repeater {
                model: SystemTray.items

                delegate: Rectangle {
                    id: trayItemRoot

                    required property var modelData

                    implicitWidth: Math.round(22 * Config.barIconScale)
                    implicitHeight: Math.round(22 * Config.barIconScale)
                    radius: Math.round(6 * Config.barIconScale)
                    color: itemMouse.containsMouse ? Qt.alpha(root.color1, 0.2) : "transparent"
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                    Image {
                        anchors.centerIn: parent
                        width: Math.round(16 * Config.barIconScale)
                        height: Math.round(16 * Config.barIconScale)
                        source: trayItemRoot.modelData.icon
                        sourceSize.width: Math.round(16 * Config.barIconScale)
                        sourceSize.height: Math.round(16 * Config.barIconScale)
                        smooth: true
                    }

                    TrayContextMenu {
                        id: trayMenu

                        menu: trayItemRoot.modelData.menu
                        parentWindow: root.parentWindow
                        trayItem: trayItemRoot.modelData
                        x: {
                            if (!root.isVertical)
                                return trayItemRoot.mapToItem(null, 0, trayItemRoot.height).x;
                            if (Config.barPosition === "right")
                                return Math.max(8, trayItemRoot.mapToItem(null, -256, 0).x);
                            return Math.min(Screen.width - 256, trayItemRoot.mapToItem(null, trayItemRoot.width + 6, 0).x);
                        }
                        y: {
                            if (!root.isVertical)
                                return trayItemRoot.mapToItem(null, 0, trayItemRoot.height).y;
                            var targetY = trayItemRoot.mapToItem(null, 0, 0).y;
                            return Math.max(8, Math.min(Screen.height - 300, targetY));
                        }
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
                                return;
                            }
                            if (mouse.button === Qt.MiddleButton) {
                                trayItemRoot.modelData.secondaryActivate();
                                return;
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
