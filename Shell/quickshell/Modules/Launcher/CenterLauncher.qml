import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Animations
import qs.Asura
import qs.Modules
import qs.Services

PanelWindow {
    id: root

    property bool isOpen: false
    property string currentView: "launcher"
    property real uiScale: 1.0
    readonly property var activeContent: currentView === "wallpaper" ? wallpaperLoader.item : (currentView === "presets" ? presetLoader.item : launcherLoader.item)

    WlrLayershell.namespace: "CenterLauncher"
    visible: isOpen
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    function toggle() {
        if (isOpen) {
            close();
        } else {
            open();
        }
    }

    function open() {
        isOpen = true;
    }

    function close() {
        isOpen = false;
        currentView = "launcher";
    }

    onIsOpenChanged: {
        if (isOpen) {
            MenuService.registerMenuOpen(root);
            AppLauncherState.show();
        } else {
            MenuService.unregisterMenuOpen(root);
            AppLauncherState.hide();
            root.currentView = "launcher";
        }
    }

    Component.onDestruction: {
        MenuService.unregisterMenuOpen(root);
    }

    Connections {
        target: MenuService

        function onCloseAllRequested() {
            root.isOpen = false;
        }

        function onToggleLauncherRequested(monitorName) {
            if (Config.cfg && Config.cfg.launcherPosition !== "center" && Config.cfg.launcherPosition !== "centralizado") {
                if (root.isOpen)
                    root.close();
                return;
            }

            var target = (monitorName && monitorName !== "") ? monitorName : (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "");
            if (target === "" && Quickshell.screens && Quickshell.screens.length > 0)
                target = Quickshell.screens[0].name;

            if (root.screen && root.screen.name === target) {
                if (root.isOpen && root.currentView === "launcher") {
                    root.close();
                } else {
                    root.currentView = "launcher";
                    root.open();
                }
            } else {
                root.close();
            }
        }

        function onOpenLauncherRequested(monitorName) {
            if (Config.cfg && Config.cfg.launcherPosition !== "center" && Config.cfg.launcherPosition !== "centralizado") {
                if (root.isOpen)
                    root.close();
                return;
            }

            var target = (monitorName && monitorName !== "") ? monitorName : (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "");
            if (target === "" && Quickshell.screens && Quickshell.screens.length > 0)
                target = Quickshell.screens[0].name;

            if (root.screen && root.screen.name === target) {
                root.currentView = "launcher";
                root.open();
            } else {
                root.close();
            }
        }

        function onToggleWallpaperRequested(monitorName) {
            if (Config.cfg && Config.cfg.launcherPosition !== "center" && Config.cfg.launcherPosition !== "centralizado") {
                if (root.isOpen)
                    root.close();
                return;
            }

            var target = (monitorName && monitorName !== "") ? monitorName : (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "");
            if (target === "" && Quickshell.screens && Quickshell.screens.length > 0)
                target = Quickshell.screens[0].name;

            if (root.screen && root.screen.name === target) {
                if (root.isOpen && root.currentView === "wallpaper") {
                    root.close();
                } else {
                    root.currentView = "wallpaper";
                    root.open();
                }
            } else {
                root.close();
            }
        }

        function onTogglePresetsRequested(monitorName) {
            if (Config.cfg && Config.cfg.launcherPosition !== "center" && Config.cfg.launcherPosition !== "centralizado") {
                if (root.isOpen)
                    root.close();
                return;
            }

            var target = (monitorName && monitorName !== "") ? monitorName : (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "");
            if (target === "" && Quickshell.screens && Quickshell.screens.length > 0)
                target = Quickshell.screens[0].name;

            if (root.screen && root.screen.name === target) {
                if (root.isOpen && root.currentView === "presets") {
                    root.close();
                } else {
                    root.currentView = "presets";
                    root.open();
                }
            } else {
                root.close();
            }
        }
    }

    Rectangle {
        id: scrim

        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)
        opacity: root.isOpen ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutQuad
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.close();
                MenuService.closeAll();
            }
        }
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: (activeContent && activeContent.implicitWidth > 0) ? activeContent.implicitWidth : ((currentView === "wallpaper" || currentView === "presets") ? 1050 : Math.round(520 * 1.1))
        height: (activeContent && activeContent.implicitHeight > 0) ? activeContent.implicitHeight : ((currentView === "wallpaper" || currentView === "presets") ? 395 : Math.round(420 * 1.1))
        radius: Config.effectiveMenuRadius
        color: Qt.alpha(Colors.cfg.background, Config.effectiveGeneralOpacity)
        border.color: Qt.alpha(Colors.cfg.primary, 0.3)
        border.width: 1
        clip: true

        scale: root.isOpen ? 1.0 : 0.95
        opacity: root.isOpen ? 1.0 : 0.0

        Behavior on scale {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutBack
                easing.overshoot: 1.08
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutQuad
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        Loader {
            id: launcherLoader

            anchors.fill: parent
            active: root.isOpen && root.currentView === "launcher"
            visible: active

            sourceComponent: Component {
                AppLauncher {
                    isOpen: root.isOpen && root.currentView === "launcher"
                    panelW: Math.round(520 * uiScale)
                    maxVisible: 8

                    onRequestWallpaper: {
                        root.currentView = "wallpaper";
                    }

                    onRequestPresets: {
                        root.currentView = "presets";
                    }

                    onHideLauncher: {
                        root.close();
                        MenuService.closeAll();
                    }

                    onRequestOpenMenu: function(name, tab) {
                        if (name === "wallpaper") {
                            root.currentView = "wallpaper";
                            return;
                        }
                        if (name === "presets" || name === "preset") {
                            root.currentView = "presets";
                            return;
                        }
                        root.close();
                        if (name === "controlpanel" || name === "controlPanel") {
                            MenuService.toggleControlPanelRequested(root.screen ? root.screen.name : "");
                        } else if (name === "player") {
                            MenuService.togglePlayerRequested(root.screen ? root.screen.name : "");
                        } else {
                            MenuService.closeAll();
                        }
                    }
                }
            }
        }

        Loader {
            id: wallpaperLoader

            anchors.fill: parent
            active: root.isOpen && root.currentView === "wallpaper"
            visible: active
            onLoaded: {
                if (item)
                    item.forceActiveFocus();
            }

            sourceComponent: Component {
                WallpaperSelector {
                }
            }
        }

        Loader {
            id: presetLoader

            anchors.fill: parent
            active: root.isOpen && root.currentView === "presets"
            visible: active
            onLoaded: {
                if (item) {
                    item.forceActiveFocus();
                    if (typeof item.focusSearchInput === "function")
                        item.focusSearchInput();
                }
            }

            sourceComponent: Component {
                PresetSelector {
                }
            }
        }
    }
}
