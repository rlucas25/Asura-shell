import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Asura

Popup {
    id: root

    property var menu: null
    property var parentWindow: null
    property var trayItem: null
    readonly property color backgroundColor: Qt.alpha(Colors.cfg.background, 0.97)
    readonly property color borderColor: Qt.alpha(Colors.cfg.primary, 0.3)
    readonly property color hoverColor: Qt.alpha(Colors.cfg.primary, 0.16)
    readonly property color textColor: Colors.cfg.text
    readonly property color mutedColor: Qt.alpha(Colors.cfg.foreground, 0.55)
    readonly property color accentColor: Colors.cfg.primary

    width: 250
    padding: 7
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    modal: false
    focus: true
    parent: Overlay.overlay
    opacity: root.visible ? 1 : 0
    scale: root.visible ? 1 : 0.96
    onOpened: {
        if (root.menu)
            menuOpener.menu = root.menu;

    }
    onClosed: {
        if (root.trayItem)
            root.trayItem = null;

    }

    QsMenuOpener {
        id: menuOpener

        menu: root.menu
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 120
            easing.type: Easing.OutCubic
        }

    }

    Behavior on scale {
        NumberAnimation {
            duration: 140
            easing.type: Easing.OutCubic
        }

    }

    background: Rectangle {
        radius: 12
        color: root.backgroundColor
        border.width: 1
        border.color: root.borderColor

        Rectangle {
            anchors.fill: parent
            anchors.margins: -5
            z: -1
            radius: parent.radius + 5
            color: Qt.alpha(Colors.cfg.background, 0.25)
            opacity: 0.35
        }

    }

    contentItem: ColumnLayout {
        spacing: 2

        Repeater {
            model: menuOpener.children

            delegate: Item {
                id: menuItemRoot

                required property var modelData

                Layout.fillWidth: true
                implicitWidth: 236
                implicitHeight: modelData.isSeparator ? 9 : 32
                visible: true

                Rectangle {
                    visible: menuItemRoot.modelData.isSeparator
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 1
                    color: Qt.alpha(Colors.cfg.foreground, 0.1)
                }

                Rectangle {
                    id: itemBackground

                    visible: !menuItemRoot.modelData.isSeparator
                    anchors.fill: parent
                    radius: 7
                    color: itemMouse.containsMouse ? root.hoverColor : "transparent"

                    Image {
                        id: itemIcon

                        anchors.left: parent.left
                        anchors.leftMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        height: 18
                        visible: menuItemRoot.modelData.icon !== ""
                        source: menuItemRoot.modelData.icon
                        sourceSize.width: 18
                        sourceSize.height: 18
                        smooth: true
                        opacity: menuItemRoot.modelData.enabled ? 1 : 0.35
                    }

                    Item {
                        id: iconSpace

                        anchors.left: parent.left
                        anchors.leftMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        height: 18
                        visible: !itemIcon.visible
                    }

                    Text {
                        id: checkIcon

                        anchors.left: itemIcon.visible ? itemIcon.right : iconSpace.right
                        anchors.leftMargin: 7
                        anchors.verticalCenter: parent.verticalCenter
                        visible: menuItemRoot.modelData.buttonType !== 0 && menuItemRoot.modelData.checkState !== 0
                        text: menuItemRoot.modelData.checkState === Qt.Checked ? "󰄬" : "󰄱"
                        font.family: "GeistMono Nerd Font Propo Propo"
                        font.pixelSize: 15
                        color: root.accentColor
                        opacity: menuItemRoot.modelData.enabled ? 1 : 0.35
                    }

                    Text {
                        id: itemText

                        anchors.left: checkIcon.visible ? checkIcon.right : (itemIcon.visible ? itemIcon.right : iconSpace.right)
                        anchors.leftMargin: 9
                        anchors.right: submenuArrow.visible ? submenuArrow.left : parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: menuItemRoot.modelData.text
                        color: menuItemRoot.modelData.enabled ? root.textColor : root.mutedColor
                        font.family: "GeistMono Nerd Font Propo Propo"
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        id: submenuArrow

                        anchors.right: parent.right
                        anchors.rightMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                        visible: menuItemRoot.modelData.hasChildren
                        text: "󰅂"
                        font.family: "GeistMono Nerd Font Propo Propo"
                        font.pixelSize: 15
                        color: itemMouse.containsMouse ? root.accentColor : root.mutedColor
                    }

                    MouseArea {
                        id: itemMouse

                        anchors.fill: parent
                        enabled: !menuItemRoot.modelData.isSeparator && menuItemRoot.modelData.enabled
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            //Submenus:
                            if (menuItemRoot.modelData.hasChildren) {
                                menuItemRoot.modelData.display(root.parentWindow, 0, 0);
                                return ;
                            }
                            //Normal item
                            menuItemRoot.modelData.triggered();
                            root.close();
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 90
                        }

                    }

                }

            }

        }

    }

}
