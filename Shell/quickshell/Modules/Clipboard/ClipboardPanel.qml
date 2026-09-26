import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.Animations
import qs.Asura
import qs.Services

PanelWindow {
    id: root

    property bool isOpen: false

    screen: Quickshell.screens.find(s => s.name === (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "")) || null
    WlrLayershell.namespace: "ClipboardPanel"
    visible: isOpen
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    onIsOpenChanged: {
        if (isOpen)
            MenuService.registerMenuOpen(root);
        else
            MenuService.unregisterMenuOpen(root);
    }

    Component.onDestruction: {
        MenuService.unregisterMenuOpen(root);
    }

    Connections {
        target: MenuService
        function onCloseAllRequested() {
            root.isOpen = false;
        }
    }

    IpcHandler {
        function toggle() {
            root.isOpen = !root.isOpen;
        }

        function open() {
            root.isOpen = true;
        }

        function close() {
            root.isOpen = false;
        }

        target: "clipboard"
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.isOpen = false;
            MenuService.closeAll();
        }
    }

    Rectangle {
        width: 500
        height: 600
        anchors.centerIn: parent
        radius: 15
        color: Colors.cfg.background

        MouseArea {
            anchors.fill: parent
        }

        ClipboardMenu {
            anchors.fill: parent
            onHideMenu: {
                root.isOpen = false;
                MenuService.closeAll();
            }
        }
    }

}
