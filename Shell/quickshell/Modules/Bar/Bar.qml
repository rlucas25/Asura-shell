import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Animations
import qs.Asura
import qs.Components
import qs.Modules
import qs.Modules.Bar.Menus
import qs.Modules.Bar.Widgets
import qs.Modules.Clipboard
import qs.Modules.Launcher
import qs.Services

PanelWindow {

    id: root

    property int mode
    property real bgOpacity: -1
    property real widthStages
    property bool exclusiveMode: false
    property bool autoHide: (Config.cfg && Config.cfg.autoHide !== undefined) ? Config.cfg.autoHide : false
    property bool mouseInBar: false
    property string activeMenuName: ""
    property string activeMenuZone: ""
    property string lastMenuName: "controlpanel"
    property string lastMenuZone: "center"
    readonly property string displayedMenuName: (activeMenuName !== "") ? activeMenuName : lastMenuName
    readonly property string displayedMenuZone: (activeMenuZone !== "") ? activeMenuZone : lastMenuZone

    readonly property bool leftOpen: activeMenuName !== "" && activeMenuZone === "left"
    readonly property bool centerOpen: activeMenuName !== "" && activeMenuZone === "center"
    readonly property bool rightOpen: activeMenuName !== "" && activeMenuZone === "right"

    property bool controlPanelOpen: activeMenuName === "controlpanel"
    onControlPanelOpenChanged: {
        if (controlPanelOpen && activeMenuName !== "controlpanel") {
            toggleMenu("controlpanel", "center");
        } else if (!controlPanelOpen && activeMenuName === "controlpanel") {
            closeMenus();
        }
    }

    property bool launcherOpen: activeMenuName === "launcher"
    onLauncherOpenChanged: {
        if (launcherOpen && activeMenuName !== "launcher") {
            toggleMenu("launcher", "center");
        } else if (!launcherOpen && activeMenuName === "launcher") {
            closeMenus();
        }
    }

    property bool wallpaperSelectorOpen: activeMenuName === "wallpaper"
    onWallpaperSelectorOpenChanged: {
        if (wallpaperSelectorOpen && activeMenuName !== "wallpaper") {
            toggleMenu("wallpaper", "center");
        } else if (!wallpaperSelectorOpen && activeMenuName === "wallpaper") {
            closeMenus();
        }
    }

    property bool playerMenuOpen: activeMenuName === "player"
    onPlayerMenuOpenChanged: {
        if (playerMenuOpen && activeMenuName !== "player") {
            var zone = BarWidgetService.findWidgetZone("player") || "center";
            toggleMenu("player", zone);
        } else if (!playerMenuOpen && activeMenuName === "player") {
            closeMenus();
        }
    }

    property string centerViewMode: "player"
    property string rightMenuType: activeMenuZone === "right" ? activeMenuName : lastMenuName
    property string lastRightMenuType: lastMenuName
    property bool trayMenuOpen: false
    readonly property bool anyMenuOpen: activeMenuName !== "" || trayMenuOpen
    readonly property bool barRevealed: !autoHide || mouseInBar || anyMenuOpen
    property real barSlideY: barRevealed ? 0 : -35
    readonly property bool isAnyMenuOpenOrClosing: anyMenuOpen || MenuService.hasOpenMenu || centerCapsule.height > 30.5 || rightCapsule.height > 30.5 || leftCapsule.height > 30.5
    property real contentWidth: mode == 0 ? (screen.width * widthStages) : screen.width
    property color backgroundBar: mode <= 1 ? "transparent" : root.barBackground
    property color primary: Colors.cfg.primary
    property color secondary: Colors.cfg.secondary
    property color tertiary: Colors.cfg.tertiary
    property color background: Colors.cfg.background
    property color surface: Colors.cfg.surface
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
    // ============================================================
    // BAR BACKGROUND OPACITY
    // ============================================================
    property string pendingControlPanelTab: "dashboard"
    readonly property real barOpacity: (root.bgOpacity >= 0) ? root.bgOpacity : (Config.cfg && Config.cfg.opacity !== undefined && Config.cfg.opacity >= 0) ? Config.cfg.opacity : 1
    readonly property color barBackground: Qt.alpha(root.background, Math.max(0, Math.min(1, root.barOpacity)))
    property alias color1: root.primary
    property alias color2: root.secondary
    property alias textColor: root.text
    property alias foreground: root.on_primary
    property alias base02: root.surfaceContainer

    function toggleMenu(menuName, zone) {
        var targetZone = zone;
        if (menuName === "controlpanel" || menuName === "launcher" || menuName === "wallpaper") {
            targetZone = "center";
        }
        if (activeMenuName === menuName && activeMenuZone === targetZone) {
            closeMenus();
        } else {
            activeMenuName = menuName;
            activeMenuZone = targetZone;
            lastMenuName = menuName;
            lastMenuZone = targetZone;
        }
    }

    function openControlPanel(tab, zone) {
        pendingControlPanelTab = tab;
        activeMenuName = "controlpanel";
        activeMenuZone = "center";
        lastMenuName = "controlpanel";
        lastMenuZone = "center";
    }

    function getMenuWidth(name) {
        switch (name) {
        case "controlpanel":
            return 1040;
        case "wallpaper":
            return 900;
        case "launcher":
            return 440;
        case "player":
            return 400;
        case "clipboard":
        case "volume":
        case "bluetooth":
        case "wifi":
        case "battery":
        case "power":
            return 360;
        default:
            return 360;
        }
    }

    function getMenuHeight(name) {
        switch (name) {
        case "clipboard":
            return 480;
        case "volume":
            return 460;
        case "bluetooth":
            return 450;
        case "wifi":
            return 440;
        case "battery":
            return 420;
        case "power":
            return 380;
        case "controlpanel":
            return 460;
        case "wallpaper":
            return 360;
        case "player":
            return 485;
        case "launcher":
            return 382;
        default:
            return 400;
        }
    }

    function cycleCenterViewMode(delta) {
        var modes = ["player", "timer", "recording", "activeWindow"];
        var idx = modes.indexOf(centerViewMode);
        if (idx === -1)
            idx = 0;

        if (delta > 0)
            idx = (idx + 1) % modes.length;
        else
            idx = (idx - 1 + modes.length) % modes.length;
        centerViewMode = modes[idx];
    }

    onRightMenuTypeChanged: {
        if (rightMenuType !== "")
            lastRightMenuType = rightMenuType;

    }
    onAnyMenuOpenChanged: {
        if (anyMenuOpen) {
            MenuService.registerMenuOpen(root);
        } else {
            MenuService.unregisterMenuOpen(root);
            if (!barHoverHandler.hovered)
                root.mouseInBar = false;
            else
                hideTimer.restart();
        }
    }

    Component.onDestruction: {
        MenuService.unregisterMenuOpen(root);
    }
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: (exclusiveMode && !autoHide) ? 30 : 0
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: (launcherOpen || wallpaperSelectorOpen || controlPanelOpen) ? WlrKeyboardFocus.Exclusive : (anyMenuOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None)
    implicitWidth: screen.width
    implicitHeight: screen.height
    color: "transparent"

    function closeMenus() {
        activeMenuName = "";
        activeMenuZone = "";
        trayMenuOpen = false;
        root.mouseInBar = false;
    }

    Connections {
        target: MenuService

        function onCloseAllRequested() {
            root.closeMenus();
        }

        function onToggleLauncherRequested(monitorName) {
            if (!monitorName || root.screen.name === monitorName) {
                root.toggleMenu("launcher", "center");
            } else {
                root.closeMenus();
            }
        }

        function onToggleWallpaperRequested(monitorName) {
            if (!monitorName || root.screen.name === monitorName) {
                root.toggleMenu("wallpaper", "center");
            } else {
                root.closeMenus();
            }
        }

        function onToggleControlPanelRequested(monitorName) {
            if (!monitorName || root.screen.name === monitorName) {
                root.toggleMenu("controlpanel", "center");
            } else {
                root.closeMenus();
            }
        }

        function onTogglePlayerRequested(monitorName) {
            if (!monitorName || root.screen.name === monitorName) {
                var zone = BarWidgetService.findWidgetZone("player") || "center";
                root.toggleMenu("player", zone);
            } else {
                root.closeMenus();
            }
        }

        function onToggleRightMenuRequested(menuType, monitorName) {
            if (!monitorName || root.screen.name === monitorName) {
                var zone = BarWidgetService.findWidgetZone(menuType) || "right";
                root.toggleMenu(menuType, zone);
            } else {
                root.closeMenus();
            }
        }
    }

    Connections {
        function onIsLockedChanged() {
            if (LockScreenService.isLocked) {
                root.closeMenus();
            }
        }

        target: LockScreenService
    }

    Connections {
        target: RecorderService
        function onIsRecordingChanged() {
            if (RecorderService.isRecording) {
                root.centerViewMode = "recording";
            }
        }
    }

    anchors {
        top: true
        left: true
        right: true
    }


    MouseArea {
        id: dismissBackdrop

        anchors.fill: parent
        enabled: anyMenuOpen || MenuService.hasOpenMenu
        z: 2
        onClicked: {
            MenuService.closeAll();
        }
    }

    Item {
        id: barHoverDetector

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.barRevealed ? 35 : 3
        z: 2

        HoverHandler {
            id: barHoverHandler

            onHoveredChanged: {
                if (hovered) {
                    hideTimer.stop();
                    root.mouseInBar = true;
                } else {
                    hideTimer.restart();
                }
            }
        }

    }

    Timer {
        id: hideTimer

        interval: 350
        repeat: false
        onTriggered: {
            if (!barHoverHandler.hovered && !root.anyMenuOpen)
                root.mouseInBar = false;

        }
    }

    Item {
        id: backgroundSurface

        anchors.top: parent.top
        anchors.topMargin: root.barSlideY
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.max(30, Math.max(leftCapsule.height, Math.max(centerCapsule.height, rightCapsule.height))) + 30
        opacity: root.barOpacity
        layer.enabled: root.barOpacity < 1

        ConcaveCorner {
            visible: mode === 0
            width: 32
            height: 30
            anchors.top: capsulesContainer.top
            anchors.right: capsulesContainer.left
            anchors.rightMargin: -2
            color: root.background
            cornerRadius: 50
            position: "topRight"
        }

        ConcaveCorner {
            visible: mode === 0
            width: 32
            height: 30
            anchors.top: capsulesContainer.top
            anchors.left: capsulesContainer.right
            anchors.leftMargin: -2
            color: root.background
            cornerRadius: 50
            position: "topLeft"
        }

        Item {
            // ====================================================
            // BAR TOP BACKGROUND
            // ====================================================
            // ====================================================
            // LEFT CAPSULE BACKGROUND
            // ====================================================
            // ----------------------------------------------------
            // LEFT TOP CONCAVE
            // ----------------------------------------------------
            // ----------------------------------------------------
            // LEFT LOWER CONCAVE
            // ----------------------------------------------------
            // ====================================================
            // CENTER CAPSULE BACKGROUND
            // ====================================================
            // ----------------------------------------------------
            // CENTER LEFT CONCAVE
            // ----------------------------------------------------
            // ----------------------------------------------------
            // CENTER RIGHT CONCAVE
            // ----------------------------------------------------
            // ====================================================
            // RIGHT CAPSULE BACKGROUND
            // ====================================================
            // ----------------------------------------------------
            // RIGHT LEFT CONCAVE
            // ----------------------------------------------------
            // ----------------------------------------------------
            // RIGHT LOWER CONCAVE
            // ----------------------------------------------------

            id: capsulesContainer

            width: root.contentWidth
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            height: parent.height

            Rectangle {
                height: 30
                width: parent.width
                color: mode === 2 ? "transparent" : root.background
                bottomLeftRadius: mode === 1 ? 0 : 100
                bottomRightRadius: mode === 1 ? 0 : 100
            }

            Rectangle {
                id: leftCapsule

                anchors.top: parent.top
                anchors.left: parent.left
                height: leftOpen ? (leftMenuHost.contentImplicitHeight + 30) : 30
                width: leftOpen ? Math.max(leftMenuHost.contentImplicitWidth, leftElementsLayout.implicitWidth + 32) : (leftElementsLayout.implicitWidth + 32)
                topLeftRadius: 0
                topRightRadius: 0
                bottomRightRadius: leftOpen ? 20 : 15
                bottomLeftRadius: mode === 0 ? 20 : 0
                color: (leftOpen || leftCapsule.height > 30.5 || mode === 2) ? root.background : "transparent"

                Behavior on height {
                    Anim {
                        type: "emphasized"
                        duration: 400
                    }

                }

                Behavior on width {
                    Anim {
                        type: "emphasized"
                        duration: 400
                    }

                }

                Behavior on bottomLeftRadius {
                    Anim {
                        type: "emphasized"
                        duration: 400
                    }

                }

                Behavior on bottomRightRadius {
                    Anim {
                        type: "emphasized"
                        duration: 400
                    }

                }

            }

            ConcaveCorner {
                visible: leftOpen || leftCapsule.height > 30.5 || mode === 2
                width: 32
                height: 30
                anchors.top: leftCapsule.top
                anchors.left: leftCapsule.right
                anchors.leftMargin: -2
                color: root.background
                cornerRadius: 50
                position: "topLeft"
            }

            ConcaveCorner {
                visible: mode != 0 && (leftOpen || leftCapsule.height > 30.5 || mode >= 1)
                width: 30
                height: 30
                anchors.top: leftCapsule.bottom
                anchors.left: leftCapsule.left
                anchors.topMargin: -1
                color: root.background
                cornerRadius: 50
                position: "topLeft"
            }

            Rectangle {
                id: centerCapsule

                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                height: centerOpen ? (centerMenuHost.contentImplicitHeight + 30) : 30
                width: centerOpen ? Math.max(centerMenuHost.contentImplicitWidth, centerElementsLayout.implicitWidth < 136 ? 200 : centerElementsLayout.implicitWidth + 64) : (centerElementsLayout.implicitWidth < 136 ? 200 : centerElementsLayout.implicitWidth + 64)
                bottomLeftRadius: centerOpen ? 20 : 15
                bottomRightRadius: centerOpen ? 20 : 15
                color: (centerOpen || centerCapsule.height > 30.5 || mode === 2) ? root.background : "transparent"

                Behavior on bottomLeftRadius {
                    Anim {
                        type: "expressive"
                        duration: 400
                    }

                }

                Behavior on bottomRightRadius {
                    Anim {
                        type: "expressive"
                        duration: 400
                    }

                }

                Behavior on height {
                    Anim {
                        type: "expressive"
                        duration: 450
                    }

                }

                Behavior on width {
                    Anim {
                        type: "expressive"
                        duration: 450
                    }

                }

            }

            ConcaveCorner {
                width: 30
                height: centerCapsule.height
                anchors.top: centerCapsule.top
                anchors.right: centerCapsule.left
                anchors.rightMargin: -1
                anchors.topMargin: root.mode != 2 && centerOpen ? 30 : 0
                color: background
                cornerRadius: 50
                position: "topRight"

                Behavior on anchors.topMargin {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutExpo
                    }

                }

            }
            ConcaveCorner {
                width: 30
                height: centerCapsule.height
                anchors.top: centerCapsule.top
                anchors.left: centerCapsule.right
                anchors.leftMargin: -1
                anchors.topMargin: root.mode != 2 && centerOpen ? 30 : 0
                Behavior on anchors.topMargin {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutExpo
                    }
                }
                color: background
                cornerRadius: 50
                position: "topLeft"
            }

            Rectangle {
                id: rightCapsule

                anchors.top: parent.top
                anchors.right: parent.right
                height: rightOpen ? (rightMenuHost.contentImplicitHeight + 30) : 30
                width: rightOpen ? Math.max(rightMenuHost.contentImplicitWidth, rightElementsLayout.implicitWidth + 32) : rightElementsLayout.implicitWidth
                topLeftRadius: 0
                topRightRadius: 0
                bottomLeftRadius: rightOpen ? 20 : 15
                bottomRightRadius: mode === 0 ? 20 : 0
                color: (rightOpen || rightCapsule.height > 30.5 || mode === 2) ? root.background : "transparent"

                Behavior on bottomLeftRadius {
                    Anim {
                        type: "expressive"
                        duration: 400
                    }

                }

                Behavior on bottomRightRadius {
                    Anim {
                        type: "expressive"
                        duration: 400
                    }

                }

                Behavior on height {
                    Anim {
                        type: "expressive"
                        duration: 450
                    }

                }

                Behavior on width {
                    Anim {
                        type: "expressive"
                        duration: 450
                    }

                }

            }

            ConcaveCorner {
                visible: rightOpen || rightCapsule.height > 30.5 || root.mode >= 1
                width: 30
                height: 30
                anchors.top: rightCapsule.top
                anchors.right: rightCapsule.left
                anchors.rightMargin: -1
                color: root.background
                cornerRadius: 50
                position: "topRight"
            }

            ConcaveCorner {
                visible: rightOpen || rightCapsule.height > 30.5 || root.mode >= 1
                width: 30
                height: 30
                anchors.top: rightCapsule.bottom
                anchors.right: rightCapsule.right
                anchors.topMargin: -1
                color: root.background
                cornerRadius: 50
                position: "topRight"
            }

        }

    }

    component MenuHost: Item {
        id: mh
        required property string zone

        readonly property bool isZoneActive: (root.activeMenuZone === mh.zone && root.activeMenuName !== "")
        readonly property bool isZoneVisible: isZoneActive || (root.lastMenuZone === mh.zone && (mh.zone === "left" ? leftCapsule.height > 30.5 : (mh.zone === "center" ? centerCapsule.height > 30.5 : rightCapsule.height > 30.5)))
        readonly property string currentMenu: isZoneActive ? root.activeMenuName : root.lastMenuName

        readonly property real contentImplicitWidth: {
            var m = currentMenu;
            var fallback = root.getMenuWidth(m);
            if (m === "controlpanel" && loaderControlPanel.item && loaderControlPanel.item.implicitWidth > 0) return loaderControlPanel.item.implicitWidth;
            if (m === "launcher" && loaderLauncher.item && loaderLauncher.item.implicitWidth > 0) return loaderLauncher.item.implicitWidth;
            if (m === "wallpaper" && loaderWallpaper.item && loaderWallpaper.item.implicitWidth > 0) return loaderWallpaper.item.implicitWidth;
            if (m === "player" && loaderPlayer.item && loaderPlayer.item.implicitWidth > 0) return loaderPlayer.item.implicitWidth;
            if (m === "wifi" && loaderWifi.item && loaderWifi.item.implicitWidth > 0) return loaderWifi.item.implicitWidth;
            if (m === "bluetooth" && loaderBluetooth.item && loaderBluetooth.item.implicitWidth > 0) return loaderBluetooth.item.implicitWidth;
            if (m === "battery" && loaderBattery.item && loaderBattery.item.implicitWidth > 0) return loaderBattery.item.implicitWidth;
            if (m === "power" && loaderPower.item && loaderPower.item.implicitWidth > 0) return loaderPower.item.implicitWidth;
            if (m === "volume" && loaderVolume.item && loaderVolume.item.implicitWidth > 0) return loaderVolume.item.implicitWidth;
            if (m === "clipboard" && loaderClipboard.item && loaderClipboard.item.implicitWidth > 0) return loaderClipboard.item.implicitWidth;
            return fallback;
        }
        readonly property real contentImplicitHeight: {
            var m = currentMenu;
            var fallback = root.getMenuHeight(m);
            if (m === "controlPanel" && loaderControlPanel.item && loaderControlPanel.item.implicitHeight > 0) return loaderControlPanel.item.implicitHeight;
            if (m === "launcher" && loaderLauncher.item && loaderLauncher.item.implicitHeight > 0) return loaderLauncher.item.implicitHeight;
            if (m === "wallpaper" && loaderWallpaper.item && loaderWallpaper.item.implicitHeight > 0) return loaderWallpaper.item.implicitHeight;
            if (m === "player" && loaderPlayer.item && loaderPlayer.item.implicitHeight > 0) return loaderPlayer.item.implicitHeight;
            if (m === "wifi" && loaderWifi.item && loaderWifi.item.implicitHeight > 0) return loaderWifi.item.implicitHeight;
            if (m === "bluetooth" && loaderBluetooth.item && loaderBluetooth.item.implicitHeight > 0) return loaderBluetooth.item.implicitHeight;
            if (m === "battery" && loaderBattery.item && loaderBattery.item.implicitHeight > 0) return loaderBattery.item.implicitHeight;
            if (m === "power" && loaderPower.item && loaderPower.item.implicitHeight > 0) return loaderPower.item.implicitHeight;
            if (m === "volume" && loaderVolume.item && loaderVolume.item.implicitHeight > 0) return loaderVolume.item.implicitHeight;
            if (m === "clipboard" && loaderClipboard.item && loaderClipboard.item.implicitHeight > 0) return loaderClipboard.item.implicitHeight;
            return fallback;
        }

        visible: isZoneVisible || opacity > 0.001
        opacity: isZoneActive ? 1 : 0
        scale: isZoneActive ? 1 : 0.95
        transformOrigin: mh.zone === "left" ? Item.TopLeft : (mh.zone === "right" ? Item.TopRight : Item.Top)

        Behavior on opacity {
            Anim {
                type: "effects"
                duration: 220
            }
        }

        Behavior on scale {
            Anim {
                type: "expressive"
                duration: 400
            }
        }

        Loader {
            id: loaderControlPanel
            anchors.fill: parent
            active: mh.isZoneVisible && mh.currentMenu === "controlpanel"
            visible: active
            sourceComponent: Component {
                ControlPanel {
                    primary: root.primary
                    secondary: root.secondary
                    background: root.background
                    surfaceContainer: root.surfaceContainer
                    on_primary: root.on_primary
                    text: root.text
                    activeTab: root.pendingControlPanelTab
                    onHideMenu: {
                        root.closeMenus();
                    }
                }
            }
        }

        Loader {
            id: loaderLauncher
            anchors.fill: parent
            active: mh.isZoneVisible && mh.currentMenu === "launcher"
            visible: active
            sourceComponent: Component {
                AppLauncher {
                    isOpen: mh.isZoneActive && mh.currentMenu === "launcher"
                    onRequestWallpaper: {
                        root.toggleMenu("wallpaper", "center");
                    }
                    onHideLauncher: {
                        root.closeMenus();
                    }
                    onRequestOpenMenu: function(name, tab) {
                        root.closeMenus();
                        if (tab && tab !== "") root.pendingControlPanelTab = tab;
                        Qt.callLater(function() { root.toggleMenu(name, "center"); });
                    }
                }
            }
        }

        Loader {
            id: loaderWallpaper
            anchors.fill: parent
            active: mh.isZoneVisible && mh.currentMenu === "wallpaper"
            visible: active
            sourceComponent: Component {
                WallpaperSelector {
                    primary: root.primary
                    surfaceContainer: root.surfaceContainer
                }
            }
        }

        Loader {
            id: loaderPlayer
            anchors.fill: parent
            active: mh.isZoneVisible && mh.currentMenu === "player"
            visible: active
            sourceComponent: Component {
                PlayerMenu {
                    primary: root.primary
                    secondary: root.secondary
                    background: root.background
                    surfaceContainer: root.surfaceContainer
                    on_primary: root.on_primary
                    text: root.text
                    onHideMenu: {
                        root.closeMenus();
                    }
                }
            }
        }

        Loader {
            id: loaderWifi
            anchors.fill: parent
            active: mh.isZoneVisible && mh.currentMenu === "wifi"
            visible: active
            sourceComponent: Component {
                WifiMenu {}
            }
        }

        Loader {
            id: loaderBluetooth
            anchors.fill: parent
            active: mh.isZoneVisible && mh.currentMenu === "bluetooth"
            visible: active
            sourceComponent: Component {
                BluetoothMenu {}
            }
        }

        Loader {
            id: loaderBattery
            anchors.fill: parent
            active: mh.isZoneVisible && mh.currentMenu === "battery"
            visible: active
            sourceComponent: Component {
                BatteryMenu {}
            }
        }

        Loader {
            id: loaderPower
            anchors.fill: parent
            active: mh.isZoneVisible && mh.currentMenu === "power"
            visible: active
            sourceComponent: Component {
                BarPowerMenu {}
            }
        }

        Loader {
            id: loaderVolume
            anchors.fill: parent
            active: mh.isZoneVisible && mh.currentMenu === "volume"
            visible: active
            sourceComponent: Component {
                VolumeMenu {}
            }
        }

        Loader {
            id: loaderClipboard
            anchors.fill: parent
            active: mh.isZoneVisible && mh.currentMenu === "clipboard"
            visible: active
            sourceComponent: Component {
                ClipboardMenu {
                    onHideMenu: {
                        root.closeMenus();
                    }
                }
            }
        }
    }

    Item {
        id: menuContentsContainer

        z: 2
        width: root.contentWidth
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.barSlideY
        height: capsulesContainer.height

        Item {
            id: leftMenuClip
            anchors.top: parent.top
            anchors.left: parent.left
            width: leftCapsule.width
            height: leftCapsule.height
            clip: true
            visible: leftOpen || leftCapsule.height > 30.5

            MouseArea {
                anchors.fill: parent
            }

            MenuHost {
                id: leftMenuHost
                zone: "left"
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 30
                anchors.bottom: parent.bottom
            }
        }

        Item {
            id: centerMenuClip
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: centerCapsule.width
            height: centerCapsule.height
            clip: true
            visible: centerOpen || centerCapsule.height > 30.5

            MouseArea {
                anchors.fill: parent
            }

            MenuHost {
                id: centerMenuHost
                zone: "center"
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 30
                anchors.bottom: parent.bottom
            }
        }

        Item {
            id: rightMenuClip
            anchors.top: parent.top
            anchors.right: parent.right
            width: rightCapsule.width
            height: rightCapsule.height
            clip: true
            visible: rightOpen || rightCapsule.height > 30.5

            MouseArea {
                anchors.fill: parent
            }

            MenuHost {
                id: rightMenuHost
                zone: "right"
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 30
                anchors.bottom: parent.bottom
            }
        }
    }

    Component {
        id: launcherComponent
        LauncherIcon {
            textColor: root.text
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.toggleMenu("launcher", "center");
                }
            }
        }
    }

    Component {
        id: workspacesComponent
        Workspaces {
            primary: root.primary
            surfaceContainer: root.surfaceContainer
        }
    }

    Component {
        id: trayComponent
        TrayButton {
            id: tb
            primary: root.textBright
            parentWindow: root
            onMenuOpenChanged: {
                root.trayMenuOpen = tb.menuOpen || tb.appMenuOpen;
            }
            onAppMenuOpenChanged: {
                root.trayMenuOpen = tb.menuOpen || tb.appMenuOpen;
            }
        }
    }

    Component {
        id: playerComponent
        Player {
            viewMode: root.centerViewMode
            onScrollRequested: (delta) => {
                root.cycleCenterViewMode(delta);
            }
            onClicked: {
                if (root.activeMenuName === "controlpanel" && root.activeMenuZone === "center") {
                    root.closeMenus();
                    return;
                }
                var tab = root.centerViewMode === "timer" ? "timer" : "dashboard";
                root.openControlPanel(tab, "center");
            }
        }
    }

    Component {
        id: clockComponent
        Clock {
            textColor: root.textBright
        }
    }

    Component {
        id: clipboardComponent
        Clipboard {
            text: root.textBright
            onClicked: {
                root.toggleMenu("clipboard", parent.targetZone);
            }
        }
    }

    Component {
        id: volumeComponent
        Volume {
            text: root.textBright
            onClicked: {
                root.toggleMenu("volume", parent.targetZone);
            }
        }
    }

    Component {
        id: bluetoothComponent
        Bluetooth {
            text: root.textBright
            onClicked: {
                root.toggleMenu("bluetooth", parent.targetZone);
            }
        }
    }

    Component {
        id: wifiComponent
        Wifi {
            text: root.textBright
            onClicked: {
                root.toggleMenu("wifi", parent.targetZone);
            }
        }
    }

    Component {
        id: batteryComponent
        Battery {
            color1: root.textBright
            color2: root.secondary
            onClicked: {
                root.toggleMenu("battery", parent.targetZone);
            }
        }
    }

    Component {
        id: powerComponent
        PowerButton {
            secondary: root.secondary
            warning: Colors.cfg.warning
            onClicked: {
                root.toggleMenu("power", parent.targetZone);
            }
        }
    }

    component SingleWidgetLoader: Loader {
        id: swl
        property string zone: ""
        required property var modelData
        readonly property var widgetData: modelData
        property string targetZone: zone
        visible: widgetData && widgetData.visible !== false
        active: visible

        Layout.preferredWidth: item ? (item.implicitWidth > 0 ? item.implicitWidth : item.width) : implicitWidth
        Layout.preferredHeight: item ? (item.implicitHeight > 0 ? item.implicitHeight : item.height) : implicitHeight
        Layout.alignment: Qt.AlignVCenter

        sourceComponent: {
            if (!widgetData) return null;
            var t = BarWidgetService.normalizeType(widgetData.type);
            switch (t) {
            case "launcher": return launcherComponent;
            case "workspaces": return workspacesComponent;
            case "tray": return trayComponent;
            case "player": return playerComponent;
            case "clock": return clockComponent;
            case "clipboard": return clipboardComponent;
            case "volume": return volumeComponent;
            case "bluetooth": return bluetoothComponent;
            case "wifi": return wifiComponent;
            case "battery": return batteryComponent;
            case "power": return powerComponent;
            default: return null;
            }
        }
    }

    component WidgetGroupDelegate: Item {
        id: wgd
        property string zone: ""
        required property var modelData

        readonly property bool isGroup: !!(modelData && modelData.isGroup)
        implicitWidth: isGroup ? groupItem.implicitWidth : singleLoader.implicitWidth
        implicitHeight: isGroup ? groupItem.implicitHeight : singleLoader.implicitHeight
        width: implicitWidth
        height: implicitHeight
        Layout.preferredWidth: implicitWidth
        Layout.preferredHeight: implicitHeight
        Layout.alignment: Qt.AlignVCenter

        Item {
            id: groupItem
            visible: wgd.isGroup
            implicitWidth: groupRow.implicitWidth
            implicitHeight: groupRow.implicitHeight
            anchors.verticalCenter: parent.verticalCenter
            height: implicitHeight
            width: implicitWidth

            Rectangle {
                anchors.fill: parent
                color: root.surfaceVariant
                radius: 100
            }

            RowLayout {
                id: groupRow
                anchors.fill: parent
                spacing: 0

                Repeater {
                    model: (wgd.modelData && wgd.modelData.isGroup) ? wgd.modelData.items : []
                    delegate: SingleWidgetLoader {
                        zone: wgd.zone
                    }
                }
            }
        }

        SingleWidgetLoader {
            id: singleLoader
            visible: !wgd.isGroup
            zone: wgd.zone
            modelData: (!wgd.isGroup && wgd.modelData) ? wgd.modelData.item : null
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Item {
        id: iconsSection

        z: 2
        width: root.contentWidth
        height: 30
        anchors.top: parent.top
        anchors.topMargin: root.barSlideY
        anchors.horizontalCenter: parent.horizontalCenter

        RowLayout {
            id: leftElementsLayout

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 10
            spacing: 4

            Repeater {
                model: BarWidgetService.getGroupedWidgets(BarWidgetService.leftWidgets)
                delegate: WidgetGroupDelegate {
                    zone: "left"
                }
            }
        }

        RowLayout {
            id: centerElementsLayout

            anchors.centerIn: parent
            spacing: 6

            Repeater {
                model: BarWidgetService.getGroupedWidgets(BarWidgetService.centerWidgets)
                delegate: WidgetGroupDelegate {
                    zone: "center"
                }
            }
        }

        RowLayout {
            id: rightElementsLayout

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 10
            spacing: 4

            Repeater {
                model: BarWidgetService.getGroupedWidgets(BarWidgetService.rightWidgets)
                delegate: WidgetGroupDelegate {
                    zone: "right"
                }
            }
        }
    }

    Behavior on barSlideY {
        Anim {
            type: "expressive"
            duration: 450
        }

    }

    mask: Region {
        Region {
            x: (root.isAnyMenuOpenOrClosing || (root.autoHide && !root.barRevealed)) ? 0 : ((screen.width - root.contentWidth) / 2)
            y: 0
            width: (root.isAnyMenuOpenOrClosing || (root.autoHide && !root.barRevealed)) ? screen.width : root.contentWidth
            height: root.isAnyMenuOpenOrClosing ? screen.height : (root.barRevealed ? 30 : 3)
        }

    }

}
