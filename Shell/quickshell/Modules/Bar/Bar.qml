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
import qs.Modules.Bar.Menus.ControlPanel
import qs.Modules.Bar.Widgets
import qs.Modules.Clipboard
import qs.Modules.Launcher
import qs.Services

PanelWindow {
    id: root

    property string barPosition: (Config.barPosition && Config.barPosition !== "") ? Config.barPosition : "top"
    readonly property bool isVertical: false
    readonly property bool isHorizontal: true
    readonly property int barThickness: Config.effectiveBarThickness
    property int mode
    property real bgOpacity: -1
    property real widthStages
    property bool exclusiveMode: (Config.cfg && Config.cfg.exclusiveMode !== undefined) ? Config.cfg.exclusiveMode : true
    property bool autoHide: (Config.cfg && Config.cfg.autoHide !== undefined) ? Config.cfg.autoHide : false
    property bool mouseInBar: false
    readonly property bool isExternalLauncherOpen: (Config.cfg && (Config.cfg.launcherPosition === "center" || Config.cfg.launcherPosition === "centralizado" || Config.cfg.launcherPosition === "zen" || Config.cfg.launcherPosition === "zen mode")) && AppLauncherState.launcherVisible
    readonly property bool isDefaultLauncher: !Config.cfg || (Config.cfg.launcherPosition !== "center" && Config.cfg.launcherPosition !== "centralizado" && Config.cfg.launcherPosition !== "zen" && Config.cfg.launcherPosition !== "zen mode")
    readonly property bool isMouseOverBar: barHoverHandler.hovered || (typeof iconsSectionHoverHandler !== "undefined" && iconsSectionHoverHandler && iconsSectionHoverHandler.hovered)
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
    property bool launcherOpen: activeMenuName === "launcher"
    property bool wallpaperSelectorOpen: activeMenuName === "wallpaper"
    property bool presetSelectorOpen: activeMenuName === "presets"
    property bool playerMenuOpen: activeMenuName === "player"
    property string centerViewMode: "player"
    property string rightMenuType: activeMenuZone === "right" ? activeMenuName : lastMenuName
    property string lastRightMenuType: lastMenuName
    property bool trayMenuOpen: false
    readonly property bool anyMenuOpen: activeMenuName !== "" || trayMenuOpen
    readonly property bool barRevealed: (!autoHide || mouseInBar || anyMenuOpen)
    readonly property real barSlideOffset: {
        if (barRevealed)
            return 0;

        var offset = root.barThickness + 20;
        if (root.barPosition === "bottom")
            return offset;

        return -offset;
    }
    property real barSlideX: 0
    property real barSlideY: barSlideOffset
    readonly property bool isAnyMenuOpenOrClosing: anyMenuOpen || (centerCapsule.height > (root.barThickness + 0.5) || rightCapsule.height > (root.barThickness + 0.5) || leftCapsule.height > (root.barThickness + 0.5))
    property real contentSpan: mode == 0 ? (screen.width * widthStages) : screen.width
    property real contentWidth: root.contentSpan
    property real contentHeight: root.barThickness
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
    readonly property bool hasLeftWidgets: {
        var groups = BarWidgetService.getGroupedWidgets(BarWidgetService.leftWidgets);
        if (!groups || groups.length === 0)
            return false;

        return leftElementsLayout.implicitWidth > 0 || leftElementsLayout.children.length > 1;
    }
    readonly property bool hasCenterWidgets: {
        var groups = BarWidgetService.getGroupedWidgets(BarWidgetService.centerWidgets);
        if (!groups || groups.length === 0)
            return false;

        return centerElementsLayout.implicitWidth > 0 || centerElementsLayout.children.length > 1;
    }
    readonly property bool hasRightWidgets: {
        var groups = BarWidgetService.getGroupedWidgets(BarWidgetService.rightWidgets);
        if (!groups || groups.length === 0)
            return false;

        return rightElementsLayout.implicitWidth > 0 || rightElementsLayout.children.length > 1;
    }
    property string pendingControlPanelTab: "dashboard"
    readonly property real barOpacity: (root.bgOpacity >= 0) ? root.bgOpacity : Config.effectiveBarOpacity
    readonly property color solidBackground: Qt.rgba(root.background.r, root.background.g, root.background.b, 1)
    readonly property color barBackground: solidBackground
    property alias color1: root.primary
    property alias color2: root.secondary
    property alias textColor: root.text
    property alias foreground: root.on_primary
    property alias base02: root.surfaceContainer
    property real activeWidgetCenterY: -1
    readonly property bool hoverMenusEnabled: (Config.cfg && Config.cfg.barHoverMenusEnabled !== undefined) ? Config.cfg.barHoverMenusEnabled : false
    readonly property var hoverEligibleMenus: ["volume", "brightness", "clipboard", "bluetooth", "wifi", "battery", "power"]
    property string pendingHoverMenu: ""
    property string pendingHoverZone: ""
    property var pendingHoverSourceItem: null
    property bool isHoveringWidget: false
    property bool isHoveringMenu: false
    property bool isHoveringControlPanelSensor: false
    property bool isHoveringControlPanelMenu: false
    property bool isHoveringLauncherSensor: false
    property bool isHoveringLauncherMenu: false
    readonly property real maskX: {
        if (root.isAnyMenuOpenOrClosing)
            return 0;

        return (root.autoHide || mode > 0) ? 0 : ((screen.width - root.contentWidth) / 2);
    }
    readonly property real maskY: {
        if (root.isAnyMenuOpenOrClosing)
            return 0;

        if (root.barPosition === "bottom")
            return screen.height - (root.barRevealed ? (root.barThickness + 5) : 4);

        return 0;
    }
    readonly property real maskWidth: {
        if (root.isAnyMenuOpenOrClosing)
            return screen.width;

        return (root.autoHide || mode > 0) ? screen.width : root.contentWidth;
    }
    readonly property real maskHeight: {
        if (root.isAnyMenuOpenOrClosing)
            return screen.height;

        return root.barRevealed ? (root.barThickness + 5) : 4;
    }

    function toggleMenu(menuName, zone) {
        var targetZone = zone;
        if (menuName === "controlpanel" || menuName === "launcher" || menuName === "wallpaper" || menuName === "presets")
            targetZone = "center";
        else if (!targetZone || targetZone === "")
            targetZone = BarWidgetService.findWidgetZone(menuName) || "right";
        if (activeMenuName === menuName && activeMenuZone === targetZone) {
            closeMenus();
        } else {
            activeMenuName = menuName;
            activeMenuZone = targetZone;
            lastMenuName = menuName;
            lastMenuZone = targetZone;
        }
    }

    function toggleWidgetMenu(menuName, zone, sourceItem) {
        var targetZone = zone;
        if (!targetZone || targetZone === "")
            targetZone = BarWidgetService.findWidgetZone(menuName) || "right";

        toggleMenu(menuName, targetZone);
    }

    function openMenu(menuName, zone) {
        var targetZone = zone;
        if (menuName === "controlpanel" || menuName === "launcher" || menuName === "wallpaper" || menuName === "presets")
            targetZone = "center";
        else if (!targetZone || targetZone === "")
            targetZone = BarWidgetService.findWidgetZone(menuName) || "right";
        activeMenuName = menuName;
        activeMenuZone = targetZone;
        lastMenuName = menuName;
        lastMenuZone = targetZone;
    }

    function openControlPanel(tab, zone) {
        pendingControlPanelTab = tab;
        activeMenuName = "controlpanel";
        activeMenuZone = "center";
        lastMenuName = "controlpanel";
        lastMenuZone = "center";
    }

    function isMenuHoverEligible(name) {
        return hoverEligibleMenus.indexOf(name) !== -1;
    }

    function openWidgetMenu(menuName, zone, sourceItem) {
        var targetZone = zone;
        if (!targetZone || targetZone === "")
            targetZone = BarWidgetService.findWidgetZone(menuName) || "right";

        openMenu(menuName, targetZone);
    }

    function handleWidgetHover(menuName, zone, sourceItem, hovered) {
        if (!hoverMenusEnabled)
            return ;

        if (!isMenuHoverEligible(menuName))
            return ;

        if (hovered) {
            isHoveringWidget = true;
            hoverCloseTimer.stop();
            // Strictly do not hijack if Launcher or System Monitor / Control Panel is open
            if (activeMenuName !== "" && !isMenuHoverEligible(activeMenuName))
                return ;

            pendingHoverMenu = menuName;
            pendingHoverZone = zone || "";
            pendingHoverSourceItem = sourceItem || null;
            if (activeMenuName !== "" && isMenuHoverEligible(activeMenuName) && activeMenuName !== menuName) {
                hoverOpenTimer.interval = 140;
                hoverOpenTimer.restart();
            } else if (activeMenuName === menuName) {
                hoverOpenTimer.stop();
            } else {
                hoverOpenTimer.interval = 120;
                hoverOpenTimer.restart();
            }
        } else {
            if (pendingHoverMenu === menuName && hoverOpenTimer.running) {
                hoverOpenTimer.stop();
                pendingHoverMenu = "";
            }
            isHoveringWidget = false;
            if (isMenuHoverEligible(activeMenuName))
                hoverCloseTimer.restart();

        }
    }

    function updateMenuHover(hovered) {
        if (!hoverMenusEnabled)
            return ;

        isHoveringMenu = hovered;
        if (hovered) {
            hoverCloseTimer.stop();
        } else {
            if (!isHoveringWidget && isMenuHoverEligible(activeMenuName))
                hoverCloseTimer.restart();

        }
    }

    function handleControlPanelHover(hovered) {
        if (!hoverMenusEnabled)
            return ;

        isHoveringControlPanelSensor = hovered;
        if (hovered) {
            cpHoverCloseTimer.stop();
            if (activeMenuName !== "controlpanel")
                cpHoverOpenTimer.restart();

        } else {
            cpHoverOpenTimer.stop();
            if (activeMenuName === "controlpanel")
                cpHoverCloseTimer.restart();

        }
    }

    function updateControlPanelMenuHover(hovered) {
        if (!hoverMenusEnabled)
            return ;

        isHoveringControlPanelMenu = hovered;
        if (hovered) {
            cpHoverCloseTimer.stop();
        } else {
            if (!isHoveringControlPanelSensor && activeMenuName === "controlpanel")
                cpHoverCloseTimer.restart();

        }
    }

    function handleLauncherHover(hovered) {
        if (!hoverMenusEnabled || !isDefaultLauncher)
            return ;

        isHoveringLauncherSensor = hovered;
        if (hovered) {
            launcherHoverCloseTimer.stop();
            if (activeMenuName !== "launcher")
                launcherHoverOpenTimer.restart();

        } else {
            launcherHoverOpenTimer.stop();
            if (activeMenuName === "launcher")
                launcherHoverCloseTimer.restart();

        }
    }

    function updateLauncherMenuHover(hovered) {
        if (!hoverMenusEnabled || !isDefaultLauncher)
            return ;

        isHoveringLauncherMenu = hovered;
        if (hovered) {
            launcherHoverCloseTimer.stop();
        } else {
            if (!isHoveringLauncherSensor && activeMenuName === "launcher")
                launcherHoverCloseTimer.restart();

        }
    }

    function getMenuWidth(name) {
        switch (name) {
        case "controlpanel":
            return 1040;
        case "wallpaper":
        case "presets":
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
        case "brightness":
            return 210;
        case "controlpanel":
            return 460;
        case "wallpaper":
        case "presets":
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

    function closeMenus() {
        activeMenuName = "";
        activeMenuZone = "";
        trayMenuOpen = false;
        root.mouseInBar = false;
        root.activeWidgetCenterY = -1;
        pendingHoverMenu = "";
        hoverOpenTimer.stop();
        hoverCloseTimer.stop();
    }

    onIsMouseOverBarChanged: {
        if (isMouseOverBar) {
            hideTimer.stop();
            root.mouseInBar = true;
        } else {
            hideTimer.restart();
        }
    }
    onControlPanelOpenChanged: {
        if (controlPanelOpen && activeMenuName !== "controlpanel")
            toggleMenu("controlpanel", "center");
        else if (!controlPanelOpen && activeMenuName === "controlpanel")
            closeMenus();
    }
    onLauncherOpenChanged: {
        if (launcherOpen && activeMenuName !== "launcher")
            toggleMenu("launcher", "center");
        else if (!launcherOpen && activeMenuName === "launcher")
            closeMenus();
    }
    onWallpaperSelectorOpenChanged: {
        if (wallpaperSelectorOpen && activeMenuName !== "wallpaper")
            toggleMenu("wallpaper", "center");
        else if (!wallpaperSelectorOpen && activeMenuName === "wallpaper")
            closeMenus();
    }
    onPresetSelectorOpenChanged: {
        if (presetSelectorOpen && activeMenuName !== "presets")
            toggleMenu("presets", "center");
        else if (!presetSelectorOpen && activeMenuName === "presets")
            closeMenus();
    }
    onPlayerMenuOpenChanged: {
        if (playerMenuOpen && activeMenuName !== "player") {
            var zone = BarWidgetService.findWidgetZone("player") || "center";
            toggleMenu("player", zone);
        } else if (!playerMenuOpen && activeMenuName === "player") {
            closeMenus();
        }
    }
    onRightMenuTypeChanged: {
        if (rightMenuType !== "")
            lastRightMenuType = rightMenuType;

    }
    onAnyMenuOpenChanged: {
        if (anyMenuOpen) {
            root.mouseInBar = true;
            MenuService.registerMenuOpen(root);
        } else {
            MenuService.unregisterMenuOpen(root);
            if (!root.isMouseOverBar)
                root.mouseInBar = false;
            else
                hideTimer.restart();
        }
    }
    Component.onDestruction: {
        MenuService.unregisterMenuOpen(root);
    }
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: (exclusiveMode && !autoHide) ? root.barThickness : 0
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: (launcherOpen || wallpaperSelectorOpen || presetSelectorOpen || controlPanelOpen) ? WlrKeyboardFocus.Exclusive : (anyMenuOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None)
    implicitWidth: screen.width
    implicitHeight: screen.height
    color: "transparent"
    onIsExternalLauncherOpenChanged: {
        if (isExternalLauncherOpen) {
            root.mouseInBar = false;
            hideTimer.stop();
            if (activeMenuName !== "")
                root.closeMenus();

        }
    }

    Timer {
        id: hoverOpenTimer

        interval: 120
        repeat: false
        onTriggered: {
            if (!root.hoverMenusEnabled)
                return ;

            if (root.pendingHoverMenu === "")
                return ;

            if (!root.isHoveringWidget)
                return ;

            if (!root.isMenuHoverEligible(root.pendingHoverMenu))
                return ;

            if (root.activeMenuName !== "" && !root.isMenuHoverEligible(root.activeMenuName))
                return ;

            root.openWidgetMenu(root.pendingHoverMenu, root.pendingHoverZone, root.pendingHoverSourceItem);
        }
    }

    Timer {
        id: hoverCloseTimer

        interval: 280
        repeat: false
        onTriggered: {
            if (!root.hoverMenusEnabled)
                return ;

            if (!root.isHoveringWidget && !root.isHoveringMenu) {
                if (root.isMenuHoverEligible(root.activeMenuName))
                    root.closeMenus();

            }
        }
    }

    Timer {
        id: cpHoverOpenTimer

        interval: 120
        repeat: false
        onTriggered: {
            if (!root.hoverMenusEnabled)
                return ;

            if (!root.isHoveringControlPanelSensor && !root.isHoveringControlPanelMenu)
                return ;

            if (root.activeMenuName === "controlpanel")
                return ;

            root.openControlPanel("dashboard", "center");
        }
    }

    Timer {
        id: cpHoverCloseTimer

        interval: 450
        repeat: false
        onTriggered: {
            if (!root.hoverMenusEnabled)
                return ;

            if (!root.isHoveringControlPanelSensor && !root.isHoveringControlPanelMenu) {
                if (root.activeMenuName === "controlpanel")
                    root.closeMenus();

            }
        }
    }

    Timer {
        id: launcherHoverOpenTimer

        interval: 120
        repeat: false
        onTriggered: {
            if (!root.hoverMenusEnabled || !root.isDefaultLauncher)
                return ;

            if (!root.isHoveringLauncherSensor && !root.isHoveringLauncherMenu)
                return ;

            if (root.activeMenuName === "launcher")
                return ;

            root.openMenu("launcher", "center");
        }
    }

    Timer {
        id: launcherHoverCloseTimer

        interval: 280
        repeat: false
        onTriggered: {
            if (!root.hoverMenusEnabled || !root.isDefaultLauncher)
                return ;

            if (!root.isHoveringLauncherSensor && !root.isHoveringLauncherMenu) {
                if (root.activeMenuName === "launcher")
                    root.closeMenus();

            }
        }
    }

    Connections {
        function onCloseAllRequested() {
            root.closeMenus();
        }

        function onToggleLauncherRequested(monitorName) {
            if (Config.cfg && (Config.cfg.launcherPosition === "center" || Config.cfg.launcherPosition === "centralizado" || Config.cfg.launcherPosition === "zen" || Config.cfg.launcherPosition === "zen mode")) {
                if (root.activeMenuName === "launcher")
                    root.closeMenus();

                return ;
            }
            var target = (monitorName && monitorName !== "") ? monitorName : (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "");
            if (target === "" && Quickshell.screens && Quickshell.screens.length > 0)
                target = Quickshell.screens[0].name;

            if (root.screen && root.screen.name === target)
                root.toggleMenu("launcher", "center");
            else
                root.closeMenus();
        }

        function onOpenLauncherRequested(monitorName) {
            if (Config.cfg && (Config.cfg.launcherPosition === "center" || Config.cfg.launcherPosition === "centralizado" || Config.cfg.launcherPosition === "zen" || Config.cfg.launcherPosition === "zen mode")) {
                if (root.activeMenuName === "launcher")
                    root.closeMenus();

                return ;
            }
            var target = (monitorName && monitorName !== "") ? monitorName : (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "");
            if (target === "" && Quickshell.screens && Quickshell.screens.length > 0)
                target = Quickshell.screens[0].name;

            if (root.screen && root.screen.name === target)
                root.openMenu("launcher", "center");
            else
                root.closeMenus();
        }

        function onToggleWallpaperRequested(monitorName) {
            if (Config.cfg && (Config.cfg.launcherPosition === "center" || Config.cfg.launcherPosition === "centralizado" || Config.cfg.launcherPosition === "zen" || Config.cfg.launcherPosition === "zen mode")) {
                if (root.activeMenuName === "wallpaper")
                    root.closeMenus();

                return ;
            }
            if (!monitorName || root.screen.name === monitorName)
                root.toggleMenu("wallpaper", "center");
            else
                root.closeMenus();
        }

        function onTogglePresetsRequested(monitorName) {
            if (Config.cfg && (Config.cfg.launcherPosition === "center" || Config.cfg.launcherPosition === "centralizado" || Config.cfg.launcherPosition === "zen" || Config.cfg.launcherPosition === "zen mode")) {
                if (root.activeMenuName === "presets")
                    root.closeMenus();

                return ;
            }
            if (!monitorName || root.screen.name === monitorName)
                root.toggleMenu("presets", "center");
            else
                root.closeMenus();
        }

        function onToggleControlPanelRequested(monitorName) {
            if (!monitorName || root.screen.name === monitorName)
                root.toggleMenu("controlpanel", "center");
            else
                root.closeMenus();
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

        target: MenuService
    }

    Connections {
        function onIsLockedChanged() {
            if (LockScreenService.isLocked)
                root.closeMenus();

        }

        target: LockScreenService
    }

    Connections {
        function onIsRecordingChanged() {
            if (RecorderService.isRecording)
                root.centerViewMode = "recording";

        }

        target: RecorderService
    }

    anchors {
        top: root.barPosition === "top"
        bottom: root.barPosition === "bottom"
        left: true
        right: true
    }

    MouseArea {
        id: dismissBackdrop

        anchors.fill: parent
        enabled: anyMenuOpen
        z: 2
        onClicked: {
            root.closeMenus();
        }
    }

    Item {
        id: barHoverDetector

        y: root.barPosition === "bottom" ? (parent.height - height) : 0
        anchors.left: parent.left
        anchors.right: parent.right
        width: parent.width
        height: root.barRevealed ? (root.barThickness + 5) : 6
        z: 2

        HoverHandler {
            id: barHoverHandler

            enabled: root.autoHide
            onHoveredChanged: {
                if (hovered) {
                    hideTimer.stop();
                    root.mouseInBar = true;
                } else {
                    if (!root.isMouseOverBar)
                        hideTimer.restart();

                }
            }
        }

    }

    Timer {
        id: hideTimer

        interval: 400
        repeat: false
        onTriggered: {
            if (!root.isMouseOverBar && !root.anyMenuOpen)
                root.mouseInBar = false;

        }
    }

    Timer {
        id: hideWatchdog

        interval: 600
        repeat: true
        running: root.autoHide && root.mouseInBar && !root.anyMenuOpen
        onTriggered: {
            var maxH = root.barThickness + 5;
            var outOfBounds = barHoverHandler.point.position.y > maxH || barHoverHandler.point.position.y < 0;
            if ((!barHoverHandler.hovered || outOfBounds) && !root.isMouseOverBar) {
                if (!root.anyMenuOpen)
                    root.mouseInBar = false;

            }
        }
    }

    Item {
        id: backgroundSurface

        y: root.barPosition === "bottom" ? (parent.height - height + root.barSlideY) : root.barSlideY
        anchors.left: parent.left
        anchors.right: parent.right
        width: parent.width
        height: Math.max(root.barThickness, Math.max(leftCapsule.height, Math.max(centerCapsule.height, rightCapsule.height))) + root.barThickness
        opacity: Math.max(0, Math.min(1, root.barOpacity))
        layer.enabled: true
        layer.smooth: true

        ConcaveCorner {
            visible: root.barPosition === "top" && mode === 0 && (Config.cfg && Config.cfg.barMeltEnabled !== false)
            width: Config.effectiveBarMeltRadius
            height: root.barThickness
            anchors.top: capsulesContainer.top
            anchors.right: capsulesContainer.left
            anchors.rightMargin: 0
            color: root.barBackground
            position: "topRight"
        }

        ConcaveCorner {
            visible: root.barPosition === "top" && mode === 0 && (Config.cfg && Config.cfg.barMeltEnabled !== false)
            width: Config.effectiveBarMeltRadius
            height: root.barThickness
            anchors.top: capsulesContainer.top
            anchors.left: capsulesContainer.right
            anchors.leftMargin: 0
            color: root.barBackground
            position: "topLeft"
        }

        ConcaveCorner {
            visible: root.barPosition === "bottom" && mode === 0 && (Config.cfg && Config.cfg.barMeltEnabled !== false)
            width: Config.effectiveBarMeltRadius
            height: root.barThickness
            anchors.bottom: capsulesContainer.bottom
            anchors.right: capsulesContainer.left
            anchors.rightMargin: 0
            color: root.barBackground
            position: "bottomRight"
        }

        ConcaveCorner {
            visible: root.barPosition === "bottom" && mode === 0 && (Config.cfg && Config.cfg.barMeltEnabled !== false)
            width: Config.effectiveBarMeltRadius
            height: root.barThickness
            anchors.bottom: capsulesContainer.bottom
            anchors.left: capsulesContainer.right
            anchors.leftMargin: 0
            color: root.barBackground
            position: "bottomLeft"
        }

        Item {
            id: capsulesContainer

            width: root.contentWidth
            height: parent.height
            y: 0
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                width: parent.width
                height: root.barThickness
                y: root.barPosition === "bottom" ? (parent.height - height) : 0
                anchors.left: parent.left
                anchors.right: parent.right
                color: mode === 2 ? "transparent" : root.barBackground
                radius: 0
                bottomLeftRadius: root.barPosition === "top" && mode !== 1 ? Math.min(15, Config.effectiveBarCapsuleRadius) : 0
                bottomRightRadius: root.barPosition === "top" && mode !== 1 ? Math.min(15, Config.effectiveBarCapsuleRadius) : 0
                topLeftRadius: root.barPosition === "bottom" && mode !== 1 ? Math.min(15, Config.effectiveBarCapsuleRadius) : 0
                topRightRadius: root.barPosition === "bottom" && mode !== 1 ? Math.min(15, Config.effectiveBarCapsuleRadius) : 0
            }

            Rectangle {
                id: leftCapsule

                y: root.barPosition === "bottom" ? (parent.height - height) : 0
                anchors.left: parent.left
                width: leftOpen ? Math.max(leftMenuHost.contentImplicitWidth, leftElementsLayout.implicitWidth + 24) : ((mode === 2 && !root.hasLeftWidgets) ? 0 : (leftElementsLayout.implicitWidth + 24))
                height: leftOpen ? (leftMenuHost.contentImplicitHeight + root.barThickness) : root.barThickness
                visible: mode !== 2 || root.hasLeftWidgets || leftOpen
                radius: 0
                bottomRightRadius: root.barPosition === "top" ? (leftOpen ? Math.round(Config.effectiveBarCapsuleRadius * 1.33) : Config.effectiveBarCapsuleRadius) : 0
                bottomLeftRadius: root.barPosition === "top" && mode === 0 ? (leftOpen ? Math.round(Config.effectiveBarCapsuleRadius * 1.33) : Config.effectiveBarCapsuleRadius) : 0
                topRightRadius: root.barPosition === "bottom" ? (leftOpen ? Math.round(Config.effectiveBarCapsuleRadius * 1.33) : Config.effectiveBarCapsuleRadius) : 0
                topLeftRadius: root.barPosition === "bottom" && mode === 0 ? (leftOpen ? Math.round(Config.effectiveBarCapsuleRadius * 1.33) : Config.effectiveBarCapsuleRadius) : 0
                color: (leftOpen || leftCapsule.height > (root.barThickness + 0.5) || (mode === 2 && root.hasLeftWidgets)) ? root.barBackground : "transparent"

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

                Behavior on topLeftRadius {
                    Anim {
                        type: "emphasized"
                        duration: 400
                    }

                }

                Behavior on topRightRadius {
                    Anim {
                        type: "emphasized"
                        duration: 400
                    }

                }

            }

            ConcaveCorner {
                visible: root.barPosition === "top" && (Config.cfg && Config.cfg.barMeltEnabled !== false) && (leftOpen || leftCapsule.height > (root.barThickness + 0.5) || (mode === 2 && root.hasLeftWidgets))
                width: Config.effectiveBarMeltRadius
                height: root.barThickness
                anchors.top: leftCapsule.top
                anchors.left: leftCapsule.right
                anchors.leftMargin: -1
                color: root.barBackground
                position: "topLeft"
            }

            ConcaveCorner {
                visible: root.barPosition === "top" && (Config.cfg && Config.cfg.barMeltEnabled !== false) && mode != 0 && (leftOpen || leftCapsule.height > (root.barThickness + 0.5) || (mode >= 1 && (mode !== 2 || root.hasLeftWidgets)))
                width: Config.effectiveBarMeltRadius
                height: root.barThickness
                anchors.top: leftCapsule.bottom
                anchors.left: leftCapsule.left
                anchors.topMargin: 0
                color: root.barBackground
                position: "topLeft"
            }

            ConcaveCorner {
                visible: root.barPosition === "bottom" && (Config.cfg && Config.cfg.barMeltEnabled !== false) && (leftOpen || leftCapsule.height > (root.barThickness + 0.5) || (mode === 2 && root.hasLeftWidgets))
                width: Config.effectiveBarMeltRadius
                height: root.barThickness
                anchors.bottom: leftCapsule.bottom
                anchors.left: leftCapsule.right
                anchors.leftMargin: -1
                color: root.barBackground
                position: "bottomLeft"
            }

            ConcaveCorner {
                visible: root.barPosition === "bottom" && (Config.cfg && Config.cfg.barMeltEnabled !== false) && mode != 0 && (leftOpen || leftCapsule.height > (root.barThickness + 0.5) || (mode >= 1 && (mode !== 2 || root.hasLeftWidgets)))
                width: Config.effectiveBarMeltRadius
                height: root.barThickness
                anchors.bottom: leftCapsule.top
                anchors.left: leftCapsule.left
                anchors.bottomMargin: 0
                color: root.barBackground
                position: "bottomLeft"
            }

            Rectangle {
                id: centerCapsule

                y: root.barPosition === "bottom" ? (parent.height - height) : 0
                anchors.horizontalCenter: parent.horizontalCenter
                width: centerOpen ? Math.max(centerMenuHost.contentImplicitWidth, centerElementsLayout.implicitWidth < 136 ? 200 : centerElementsLayout.implicitWidth + 64) : ((mode === 2 && !root.hasCenterWidgets) ? 0 : (centerElementsLayout.implicitWidth < 136 ? (root.hasCenterWidgets ? 200 : 0) : centerElementsLayout.implicitWidth + 64))
                height: centerOpen ? (centerMenuHost.contentImplicitHeight + root.barThickness) : root.barThickness
                visible: mode !== 2 || root.hasCenterWidgets || centerOpen
                radius: 0
                bottomLeftRadius: root.barPosition === "top" ? (centerOpen ? Math.round(Config.effectiveBarCapsuleRadius * 1.33) : Config.effectiveBarCapsuleRadius) : 0
                bottomRightRadius: root.barPosition === "top" ? (centerOpen ? Math.round(Config.effectiveBarCapsuleRadius * 1.33) : Config.effectiveBarCapsuleRadius) : 0
                topLeftRadius: root.barPosition === "bottom" ? (centerOpen ? Math.round(Config.effectiveBarCapsuleRadius * 1.33) : Config.effectiveBarCapsuleRadius) : 0
                topRightRadius: root.barPosition === "bottom" ? (centerOpen ? Math.round(Config.effectiveBarCapsuleRadius * 1.33) : Config.effectiveBarCapsuleRadius) : 0
                color: (centerOpen || centerCapsule.height > (root.barThickness + 0.5) || (mode === 2 && root.hasCenterWidgets)) ? root.barBackground : "transparent"

                HoverHandler {
                    enabled: root.hoverMenusEnabled && !root.centerOpen
                    onHoveredChanged: root.handleControlPanelHover(hovered)
                }

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

                Behavior on topLeftRadius {
                    Anim {
                        type: "expressive"
                        duration: 400
                    }

                }

                Behavior on topRightRadius {
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
                visible: root.barPosition === "top" && (Config.cfg && Config.cfg.barMeltEnabled !== false) && (centerOpen || centerCapsule.height > (root.barThickness + 0.5) || (mode === 2 && root.hasCenterWidgets))
                width: Config.effectiveBarMeltRadius
                height: (root.mode !== 2 && (centerOpen || centerCapsule.height > (root.barThickness + 0.5))) ? Config.effectiveBarMeltRadius : Math.min(root.barThickness, Config.effectiveBarMeltRadius)
                anchors.top: centerCapsule.top
                anchors.right: centerCapsule.left
                anchors.rightMargin: -1
                anchors.topMargin: root.mode !== 2 && (centerOpen || centerCapsule.height > (root.barThickness + 0.5)) ? root.barThickness : 0
                color: root.barBackground
                position: "topRight"

                Behavior on anchors.topMargin {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutExpo
                    }

                }

            }

            ConcaveCorner {
                visible: root.barPosition === "top" && (Config.cfg && Config.cfg.barMeltEnabled !== false) && (centerOpen || centerCapsule.height > (root.barThickness + 0.5) || (mode === 2 && root.hasCenterWidgets))
                width: Config.effectiveBarMeltRadius
                height: (root.mode !== 2 && (centerOpen || centerCapsule.height > (root.barThickness + 0.5))) ? Config.effectiveBarMeltRadius : Math.min(root.barThickness, Config.effectiveBarMeltRadius)
                anchors.top: centerCapsule.top
                anchors.left: centerCapsule.right
                anchors.leftMargin: -1
                anchors.topMargin: root.mode !== 2 && (centerOpen || centerCapsule.height > (root.barThickness + 0.5)) ? root.barThickness : 0
                color: root.barBackground
                position: "topLeft"

                Behavior on anchors.topMargin {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutExpo
                    }

                }

            }

            ConcaveCorner {
                visible: root.barPosition === "bottom" && (Config.cfg && Config.cfg.barMeltEnabled !== false) && (centerOpen || centerCapsule.height > (root.barThickness + 0.5) || (mode === 2 && root.hasCenterWidgets))
                width: Config.effectiveBarMeltRadius
                height: (root.mode !== 2 && (centerOpen || centerCapsule.height > (root.barThickness + 0.5))) ? Config.effectiveBarMeltRadius : Math.min(root.barThickness, Config.effectiveBarMeltRadius)
                anchors.bottom: centerCapsule.bottom
                anchors.right: centerCapsule.left
                anchors.rightMargin: -1
                anchors.bottomMargin: root.mode !== 2 && (centerOpen || centerCapsule.height > (root.barThickness + 0.5)) ? root.barThickness : 0
                color: root.barBackground
                position: "bottomRight"

                Behavior on anchors.bottomMargin {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutExpo
                    }

                }

            }

            ConcaveCorner {
                visible: root.barPosition === "bottom" && (Config.cfg && Config.cfg.barMeltEnabled !== false) && (centerOpen || centerCapsule.height > (root.barThickness + 0.5) || (mode === 2 && root.hasCenterWidgets))
                width: Config.effectiveBarMeltRadius
                height: (root.mode !== 2 && (centerOpen || centerCapsule.height > (root.barThickness + 0.5))) ? Config.effectiveBarMeltRadius : Math.min(root.barThickness, Config.effectiveBarMeltRadius)
                anchors.bottom: centerCapsule.bottom
                anchors.left: centerCapsule.right
                anchors.leftMargin: -1
                anchors.bottomMargin: root.mode !== 2 && (centerOpen || centerCapsule.height > (root.barThickness + 0.5)) ? root.barThickness : 0
                color: root.barBackground
                position: "bottomLeft"

                Behavior on anchors.bottomMargin {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutExpo
                    }

                }

            }

            Rectangle {
                id: rightCapsule

                y: root.barPosition === "bottom" ? (parent.height - height) : 0
                anchors.right: parent.right
                width: rightOpen ? Math.max(rightMenuHost.contentImplicitWidth, rightElementsLayout.implicitWidth + 24) : ((mode === 2 && !root.hasRightWidgets) ? 0 : (rightElementsLayout.implicitWidth + 24))
                height: rightOpen ? (rightMenuHost.contentImplicitHeight + root.barThickness) : root.barThickness
                visible: mode !== 2 || root.hasRightWidgets || rightOpen
                radius: 0
                bottomLeftRadius: root.barPosition === "top" ? (rightOpen ? Math.round(Config.effectiveBarCapsuleRadius * 1.33) : Config.effectiveBarCapsuleRadius) : 0
                bottomRightRadius: root.barPosition === "top" && mode === 0 ? (rightOpen ? Math.round(Config.effectiveBarCapsuleRadius * 1.33) : Config.effectiveBarCapsuleRadius) : 0
                topLeftRadius: root.barPosition === "bottom" ? (rightOpen ? Math.round(Config.effectiveBarCapsuleRadius * 1.33) : Config.effectiveBarCapsuleRadius) : 0
                topRightRadius: root.barPosition === "bottom" && mode === 0 ? (rightOpen ? Math.round(Config.effectiveBarCapsuleRadius * 1.33) : Config.effectiveBarCapsuleRadius) : 0
                color: (rightOpen || rightCapsule.height > (root.barThickness + 0.5) || (mode === 2 && root.hasRightWidgets)) ? root.barBackground : "transparent"

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

                Behavior on topLeftRadius {
                    Anim {
                        type: "expressive"
                        duration: 400
                    }

                }

                Behavior on topRightRadius {
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
                visible: root.barPosition === "top" && (Config.cfg && Config.cfg.barMeltEnabled !== false) && (rightOpen || rightCapsule.height > (root.barThickness + 0.5) || (mode === 2 && root.hasRightWidgets))
                width: Config.effectiveBarMeltRadius
                height: root.barThickness
                anchors.top: rightCapsule.top
                anchors.right: rightCapsule.left
                anchors.rightMargin: -1
                color: root.barBackground
                position: "topRight"
            }

            ConcaveCorner {
                visible: root.barPosition === "top" && (Config.cfg && Config.cfg.barMeltEnabled !== false) && mode != 0 && (rightOpen || rightCapsule.height > (root.barThickness + 0.5) || (mode >= 1 && (mode !== 2 || root.hasRightWidgets)))
                width: Config.effectiveBarMeltRadius
                height: root.barThickness
                anchors.top: rightCapsule.bottom
                anchors.right: rightCapsule.right
                anchors.topMargin: 0
                color: root.barBackground
                position: "topRight"
            }

            ConcaveCorner {
                visible: root.barPosition === "bottom" && (Config.cfg && Config.cfg.barMeltEnabled !== false) && (rightOpen || rightCapsule.height > (root.barThickness + 0.5) || (mode === 2 && root.hasRightWidgets))
                width: Config.effectiveBarMeltRadius
                height: root.barThickness
                anchors.bottom: rightCapsule.bottom
                anchors.right: rightCapsule.left
                anchors.rightMargin: -1
                color: root.barBackground
                position: "bottomRight"
            }

            ConcaveCorner {
                visible: root.barPosition === "bottom" && (Config.cfg && Config.cfg.barMeltEnabled !== false) && mode != 0 && (rightOpen || rightCapsule.height > (root.barThickness + 0.5) || (mode >= 1 && (mode !== 2 || root.hasRightWidgets)))
                width: Config.effectiveBarMeltRadius
                height: root.barThickness
                anchors.bottom: rightCapsule.top
                anchors.right: rightCapsule.right
                anchors.bottomMargin: 0
                color: root.barBackground
                position: "bottomRight"
            }

        }

    }

    Item {
        id: menuContentsContainer

        z: 3
        width: root.contentWidth
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.barPosition === "bottom" ? (parent.height - height + root.barSlideY) : root.barSlideY
        height: capsulesContainer.height

        Item {
            id: leftMenuClip

            y: root.barPosition === "bottom" ? (parent.height - height) : 0
            anchors.left: parent.left
            width: leftCapsule.width
            height: leftCapsule.height
            clip: true
            visible: leftOpen || leftCapsule.height > (root.barThickness + 0.5)

            MouseArea {
                anchors.fill: parent
                onClicked: {
                }
            }

            HoverHandler {
                enabled: root.hoverMenusEnabled && leftOpen
                onHoveredChanged: root.updateMenuHover(hovered)
            }

            MenuHost {
                id: leftMenuHost

                zone: "left"
                anchors.fill: parent
                z: 1
                anchors.topMargin: root.barPosition === "top" ? root.barThickness : 0
                anchors.bottomMargin: root.barPosition === "bottom" ? root.barThickness : 0
            }

        }

        Item {
            id: centerMenuClip

            y: root.barPosition === "bottom" ? (parent.height - height) : 0
            anchors.horizontalCenter: parent.horizontalCenter
            width: centerCapsule.width
            height: centerCapsule.height
            clip: true
            visible: centerOpen || centerCapsule.height > (root.barThickness + 0.5)

            MouseArea {
                anchors.fill: parent
                onClicked: {
                }
            }

            HoverHandler {
                enabled: root.hoverMenusEnabled && centerOpen
                onHoveredChanged: {
                    root.updateMenuHover(hovered);
                    if (root.activeMenuName === "controlpanel")
                        root.updateControlPanelMenuHover(hovered);
                    else if (root.activeMenuName === "launcher")
                        root.updateLauncherMenuHover(hovered);
                }
            }

            MenuHost {
                id: centerMenuHost

                zone: "center"
                anchors.fill: parent
                z: 1
                anchors.topMargin: root.barPosition === "top" ? root.barThickness : 0
                anchors.bottomMargin: root.barPosition === "bottom" ? root.barThickness : 0
            }

        }

        Item {
            id: rightMenuClip

            y: root.barPosition === "bottom" ? (parent.height - height) : 0
            anchors.right: parent.right
            width: rightCapsule.width
            height: rightCapsule.height
            clip: true
            visible: rightOpen || rightCapsule.height > (root.barThickness + 0.5)

            MouseArea {
                anchors.fill: parent
                onClicked: {
                }
            }

            HoverHandler {
                enabled: root.hoverMenusEnabled && rightOpen
                onHoveredChanged: root.updateMenuHover(hovered)
            }

            MenuHost {
                id: rightMenuHost

                zone: "right"
                anchors.fill: parent
                z: 1
                anchors.topMargin: root.barPosition === "top" ? root.barThickness : 0
                anchors.bottomMargin: root.barPosition === "bottom" ? root.barThickness : 0
            }

        }

    }

    Component {
        id: launcherComponent

        LauncherIcon {
            HoverHandler {
                enabled: root.hoverMenusEnabled && root.isDefaultLauncher
                onHoveredChanged: root.handleLauncherHover(hovered)
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (Config.cfg && (Config.cfg.launcherPosition === "center" || Config.cfg.launcherPosition === "centralizado" || Config.cfg.launcherPosition === "zen" || Config.cfg.launcherPosition === "zen mode"))
                        MenuService.toggleLauncherRequested(root.screen ? root.screen.name : "");
                    else
                        root.toggleMenu("launcher", "center");
                }
            }

        }

    }

    Component {
        id: workspacesComponent

        Workspaces {
        }

    }

    Component {
        id: trayComponent

        TrayButton {
            id: tb

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
                    return ;
                }
                var tab = root.centerViewMode === "timer" ? "timer" : "dashboard";
                root.openControlPanel(tab, "center");
            }
        }

    }

    Component {
        id: clockComponent

        Clock {
        }

    }

    Component {
        id: tasksComponent

        Tasks {
            id: tasksWidget

            onClicked: {
                root.openControlPanel("dashboard", parent ? parent.targetZone : "center");
            }
        }
    }

    Component {
        id: clipboardComponent

        Clipboard {
            id: clipWidget

            onClicked: {
                root.toggleWidgetMenu("clipboard", parent ? parent.targetZone : "right", clipWidget);
            }
            onIsHoveredChanged: {
                root.handleWidgetHover("clipboard", parent ? parent.targetZone : "right", clipWidget, isHovered);
            }
        }

    }

    Component {
        id: volumeComponent

        Volume {
            id: volWidget

            onClicked: {
                root.toggleWidgetMenu("volume", parent ? parent.targetZone : "right", volWidget);
            }
            onIsHoveredChanged: {
                root.handleWidgetHover("volume", parent ? parent.targetZone : "right", volWidget, isHovered);
            }
        }

    }

    Component {
        id: bluetoothComponent

        Bluetooth {
            id: btWidget

            onClicked: {
                root.toggleWidgetMenu("bluetooth", parent ? parent.targetZone : "right", btWidget);
            }
            onIsHoveredChanged: {
                root.handleWidgetHover("bluetooth", parent ? parent.targetZone : "right", btWidget, isHovered);
            }
        }

    }

    Component {
        id: wifiComponent

        Wifi {
            id: wifiWidget

            onClicked: {
                root.toggleWidgetMenu("wifi", parent ? parent.targetZone : "right", wifiWidget);
            }
            onIsHoveredChanged: {
                root.handleWidgetHover("wifi", parent ? parent.targetZone : "right", wifiWidget, isHovered);
            }
        }

    }

    Component {
        id: batteryComponent

        Battery {
            id: batWidget

            onClicked: {
                root.toggleWidgetMenu("battery", parent ? parent.targetZone : "right", batWidget);
            }
            onIsHoveredChanged: {
                root.handleWidgetHover("battery", parent ? parent.targetZone : "right", batWidget, isHovered);
            }
        }

    }

    Component {
        id: keyboardComponent

        Keyboard {
            onClicked: {
                KeyboardLayoutService.nextLayout();
            }
        }

    }

    Component {
        id: windowModeComponent

        WindowMode {
            onClicked: {
                WindowModeService.cycleLayout();
            }
        }

    }

    Component {
        id: powerComponent

        PowerButton {
            id: pwrWidget

            onClicked: {
                root.toggleWidgetMenu("power", parent ? parent.targetZone : "right", pwrWidget);
            }
            onIsHoveredChanged: {
                root.handleWidgetHover("power", parent ? parent.targetZone : "right", pwrWidget, isHovered);
            }
        }

    }

    Component {
        id: cpuComponent

        Cpu {
            onClicked: {
                if (root.activeMenuName === "controlpanel" && root.pendingControlPanelTab === "system")
                    root.closeMenus();
                else
                    root.openControlPanel("system", parent ? parent.targetZone : "center");
            }
        }

    }

    Component {
        id: ramComponent

        Ram {
            onClicked: {
                if (root.activeMenuName === "controlpanel" && root.pendingControlPanelTab === "system")
                    root.closeMenus();
                else
                    root.openControlPanel("system", parent ? parent.targetZone : "center");
            }
        }

    }

    Component {
        id: gpuComponent

        Gpu {
            onClicked: {
                if (root.activeMenuName === "controlpanel" && root.pendingControlPanelTab === "system")
                    root.closeMenus();
                else
                    root.openControlPanel("system", parent ? parent.targetZone : "center");
            }
        }

    }

    Component {
        id: brightnessComponent

        Brightness {
            id: brightWidget

            onClicked: {
                root.toggleWidgetMenu("brightness", parent ? parent.targetZone : "right", brightWidget);
            }
            onIsHoveredChanged: {
                root.handleWidgetHover("brightness", parent ? parent.targetZone : "right", brightWidget, isHovered);
            }
        }

    }

    Component {
        id: diskComponent

        Disk {
            onClicked: {
                if (root.activeMenuName === "controlpanel" && root.pendingControlPanelTab === "system")
                    root.closeMenus();
                else
                    root.openControlPanel("system", parent ? parent.targetZone : "center");
            }
        }

    }

    Item {
        id: barVisualizerHost

        z: 1
        width: root.contentWidth
        height: root.barThickness
        y: root.barPosition === "bottom" ? (parent.height - height + root.barSlideY) : root.barSlideY
        anchors.horizontalCenter: parent.horizontalCenter
        visible: (Config.cfg && Config.cfg.barVisualizerEnabled !== undefined) ? Config.cfg.barVisualizerEnabled : true
        clip: true

        BarVisualizer {
            width: parent.width
            height: parent.height
            anchors.centerIn: parent
            rotation: 0
            barRadius: root.mode === 1 ? 0 : Config.effectiveBarCapsuleRadius
            primaryColor: root.primary
            secondaryColor: root.secondary
        }

    }

    Item {
        id: iconsSection

        z: 4
        width: root.contentWidth
        height: root.barThickness
        y: root.barPosition === "bottom" ? (parent.height - height + root.barSlideY) : root.barSlideY
        anchors.horizontalCenter: parent.horizontalCenter

        HoverHandler {
            id: iconsSectionHoverHandler

            enabled: root.autoHide
            onHoveredChanged: {
                if (hovered) {
                    hideTimer.stop();
                    root.mouseInBar = true;
                } else {
                    if (!barHoverHandler.hovered)
                        hideTimer.restart();

                }
            }
        }

        GridLayout {
            id: leftElementsLayout

            visible: mode !== 2 || root.hasLeftWidgets
            columns: -1
            rows: 1
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Config.effectiveBarEdgeSpacing
            rowSpacing: Config.effectiveBarWidgetSpacing
            columnSpacing: Config.effectiveBarWidgetSpacing

            Repeater {
                model: BarWidgetService.getGroupedWidgets(BarWidgetService.leftWidgets)

                delegate: WidgetGroupDelegate {
                    zone: "left"
                }

            }

            Behavior on anchors.leftMargin {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }

            }

            Behavior on columnSpacing {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }

            }

        }

        GridLayout {
            id: centerElementsLayout

            visible: mode !== 2 || root.hasCenterWidgets
            columns: -1
            rows: 1
            anchors.centerIn: parent
            rowSpacing: Config.effectiveBarWidgetSpacing
            columnSpacing: Config.effectiveBarWidgetSpacing

            Repeater {
                model: BarWidgetService.getGroupedWidgets(BarWidgetService.centerWidgets)

                delegate: WidgetGroupDelegate {
                    zone: "center"
                }

            }

            Behavior on columnSpacing {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }

            }

        }

        GridLayout {
            id: rightElementsLayout

            visible: mode !== 2 || root.hasRightWidgets
            columns: -1
            rows: 1
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: Config.effectiveBarEdgeSpacing
            rowSpacing: Config.effectiveBarWidgetSpacing
            columnSpacing: Config.effectiveBarWidgetSpacing

            Repeater {
                model: BarWidgetService.getGroupedWidgets(BarWidgetService.rightWidgets)

                delegate: WidgetGroupDelegate {
                    zone: "right"
                }

            }

            Behavior on anchors.rightMargin {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }

            }

            Behavior on columnSpacing {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }

            }

        }

    }

    Item {
        id: launcherBottomEdgeSensor

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: 320
        height: 10
        z: 10
        visible: root.hoverMenusEnabled && root.isDefaultLauncher && root.barPosition === "top"

        HoverHandler {
            enabled: root.hoverMenusEnabled && root.isDefaultLauncher && root.barPosition === "top"
            onHoveredChanged: root.handleLauncherHover(hovered)
        }

    }

    Item {
        id: launcherTopEdgeSensor

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: 320
        height: 10
        z: 10
        visible: root.hoverMenusEnabled && root.isDefaultLauncher && root.barPosition === "bottom"

        HoverHandler {
            enabled: root.hoverMenusEnabled && root.isDefaultLauncher && root.barPosition === "bottom"
            onHoveredChanged: root.handleLauncherHover(hovered)
        }

    }

    component MenuHost: Item {
        id: mh

        required property string zone
        readonly property bool isZoneActive: (root.activeMenuZone === mh.zone && root.activeMenuName !== "")
        readonly property bool isZoneVisible: (isZoneActive || (root.lastMenuZone === mh.zone && (mh.zone === "left" ? leftCapsule.height > (root.barThickness + 0.5) : (mh.zone === "center" ? centerCapsule.height > (root.barThickness + 0.5) : rightCapsule.height > (root.barThickness + 0.5)))))
        readonly property string currentMenu: isZoneActive ? root.activeMenuName : root.lastMenuName
        readonly property real contentImplicitWidth: {
            var m = currentMenu;
            var fallback = root.getMenuWidth(m);
            if ((m === "controlpanel" || m === "controlPanel") && loaderControlPanel.item && loaderControlPanel.item.implicitWidth > 0)
                return loaderControlPanel.item.implicitWidth;

            if (m === "launcher" && loaderLauncher.item && loaderLauncher.item.implicitWidth > 0)
                return loaderLauncher.item.implicitWidth;

            if (m === "wallpaper" && loaderWallpaper.item && loaderWallpaper.item.implicitWidth > 0)
                return loaderWallpaper.item.implicitWidth;

            if (m === "presets" && loaderPresets.item && loaderPresets.item.implicitWidth > 0)
                return loaderPresets.item.implicitWidth;

            if (m === "player" && loaderPlayer.item && loaderPlayer.item.implicitWidth > 0)
                return loaderPlayer.item.implicitWidth;

            if (m === "wifi" && loaderWifi.item && loaderWifi.item.implicitWidth > 0)
                return loaderWifi.item.implicitWidth;

            if (m === "bluetooth" && loaderBluetooth.item && loaderBluetooth.item.implicitWidth > 0)
                return loaderBluetooth.item.implicitWidth;

            if (m === "battery" && loaderBattery.item && loaderBattery.item.implicitWidth > 0)
                return loaderBattery.item.implicitWidth;

            if (m === "power" && loaderPower.item && loaderPower.item.implicitWidth > 0)
                return loaderPower.item.implicitWidth;

            if (m === "volume" && loaderVolume.item && loaderVolume.item.implicitWidth > 0)
                return loaderVolume.item.implicitWidth;

            if (m === "clipboard" && loaderClipboard.item && loaderClipboard.item.implicitWidth > 0)
                return loaderClipboard.item.implicitWidth;

            return fallback;
        }
        readonly property real contentImplicitHeight: {
            var m = currentMenu;
            var fallback = root.getMenuHeight(m);
            if ((m === "controlpanel" || m === "controlPanel") && loaderControlPanel.item && loaderControlPanel.item.implicitHeight > 0)
                return loaderControlPanel.item.implicitHeight;

            if (m === "launcher" && loaderLauncher.item && loaderLauncher.item.implicitHeight > 0)
                return loaderLauncher.item.implicitHeight;

            if (m === "wallpaper" && loaderWallpaper.item && loaderWallpaper.item.implicitHeight > 0)
                return loaderWallpaper.item.implicitHeight;

            if (m === "presets" && loaderPresets.item && loaderPresets.item.implicitHeight > 0)
                return loaderPresets.item.implicitHeight;

            if (m === "player" && loaderPlayer.item && loaderPlayer.item.implicitHeight > 0)
                return loaderPlayer.item.implicitHeight;

            if (m === "wifi" && loaderWifi.item && loaderWifi.item.implicitHeight > 0)
                return loaderWifi.item.implicitHeight;

            if (m === "bluetooth" && loaderBluetooth.item && loaderBluetooth.item.implicitHeight > 0)
                return loaderBluetooth.item.implicitHeight;

            if (m === "battery" && loaderBattery.item && loaderBattery.item.implicitHeight > 0)
                return loaderBattery.item.implicitHeight;

            if (m === "power" && loaderPower.item && loaderPower.item.implicitHeight > 0)
                return loaderPower.item.implicitHeight;

            if (m === "volume" && loaderVolume.item && loaderVolume.item.implicitHeight > 0)
                return loaderVolume.item.implicitHeight;

            if (m === "clipboard" && loaderClipboard.item && loaderClipboard.item.implicitHeight > 0)
                return loaderClipboard.item.implicitHeight;

            return fallback;
        }

        opacity: isZoneActive ? 1 : 0
        scale: isZoneActive ? 1 : 0.95
        clip: true

        HoverHandler {
            enabled: root.hoverMenusEnabled && mh.isZoneActive
            onHoveredChanged: root.updateMenuHover(hovered)
        }

        Loader {
            id: loaderControlPanel

            property bool _loaded: false

            width: item ? item.implicitWidth : root.getMenuWidth("controlpanel")
            height: item ? item.implicitHeight : root.getMenuHeight("controlpanel")
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            active: _loaded || (mh.isZoneVisible && mh.currentMenu === "controlpanel")
            visible: mh.isZoneVisible && mh.currentMenu === "controlpanel"
            onLoaded: _loaded = true

            sourceComponent: Component {
                ControlPanel {
                    visible: loaderControlPanel.visible
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
                    onRequestPresets: {
                        root.toggleMenu("presets", "center");
                    }
                    onHideLauncher: {
                        root.closeMenus();
                    }
                    onRequestOpenMenu: function(name, tab) {
                        root.closeMenus();
                        if (tab && tab !== "")
                            root.pendingControlPanelTab = tab;

                        Qt.callLater(function() {
                            root.toggleMenu(name, "center");
                        });
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
                }

            }

        }

        Loader {
            id: loaderPresets

            anchors.fill: parent
            active: mh.isZoneVisible && mh.currentMenu === "presets"
            visible: active

            sourceComponent: Component {
                PresetSelector {
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
                }

            }

        }

        Loader {
            id: loaderWifi

            anchors.fill: parent
            active: mh.isZoneVisible && mh.currentMenu === "wifi"
            visible: active

            sourceComponent: Component {
                WifiMenu {
                }

            }

        }

        Loader {
            id: loaderBluetooth

            anchors.fill: parent
            active: mh.isZoneVisible && mh.currentMenu === "bluetooth"
            visible: active

            sourceComponent: Component {
                BluetoothMenu {
                }

            }

        }

        Loader {
            id: loaderBattery

            anchors.fill: parent
            active: mh.isZoneVisible && mh.currentMenu === "battery"
            visible: active

            sourceComponent: Component {
                BatteryMenu {
                }

            }

        }

        Loader {
            id: loaderPower

            anchors.fill: parent
            active: mh.isZoneVisible && mh.currentMenu === "power"
            visible: active

            sourceComponent: Component {
                BarPowerMenu {
                }

            }

        }

        Loader {
            id: loaderVolume

            anchors.fill: parent
            active: mh.isZoneVisible && mh.currentMenu === "volume"
            visible: active

            sourceComponent: Component {
                VolumeMenu {
                }

            }

        }

        Loader {
            id: loaderBrightness

            anchors.fill: parent
            active: mh.isZoneVisible && mh.currentMenu === "brightness"
            visible: active

            sourceComponent: Component {
                BrightnessMenu {
                }

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
        Layout.alignment: Qt.AlignCenter
        sourceComponent: {
            if (!widgetData)
                return null;

            var t = BarWidgetService.normalizeType(widgetData.type);
            switch (t) {
            case "launcher":
                return launcherComponent;
            case "workspaces":
                return workspacesComponent;
            case "tray":
                return trayComponent;
            case "player":
                return playerComponent;
            case "clock":
                return clockComponent;
            case "tasks":
                return tasksComponent;
            case "clipboard":
                return clipboardComponent;
            case "volume":
                return volumeComponent;
            case "bluetooth":
                return bluetoothComponent;
            case "wifi":
                return wifiComponent;
            case "battery":
                return batteryComponent;
            case "power":
                return powerComponent;
            case "cpu":
                return cpuComponent;
            case "ram":
                return ramComponent;
            case "gpu":
                return gpuComponent;
            case "disk":
                return diskComponent;
            case "brightness":
                return brightnessComponent;
            case "keyboard":
                return keyboardComponent;
            case "window_mode":
                return windowModeComponent;
            default:
                return null;
            }
        }
    }

    component WidgetGroupDelegate: Item {
        id: wgd

        property string zone: ""
        required property var modelData
        readonly property bool isGroup: !!(modelData && modelData.isGroup)
        readonly property real capsuleHorizontalPadding: Config.effectiveBarCapsulePadding
        readonly property real capsuleHeight: Math.min(Math.round(24 * Config.barScale), root.barThickness - 4)

        implicitWidth: isGroup ? (groupRow.implicitWidth + (capsuleHorizontalPadding * 2)) : singleLoader.implicitWidth
        implicitHeight: isGroup ? capsuleHeight : singleLoader.implicitHeight
        width: implicitWidth
        height: implicitHeight
        Layout.preferredWidth: implicitWidth
        Layout.preferredHeight: implicitHeight
        Layout.alignment: Qt.AlignCenter

        Item {
            id: groupItem

            visible: wgd.isGroup
            implicitWidth: groupRow.implicitWidth + (wgd.capsuleHorizontalPadding * 2)
            implicitHeight: wgd.capsuleHeight
            anchors.centerIn: parent
            height: implicitHeight
            width: implicitWidth

            Rectangle {
                anchors.fill: parent
                color: root.color1
                opacity: 0.25
                radius: Config.effectiveBarCapsuleRadius === 0 ? 0 : (height / 2)
            }

            GridLayout {
                id: groupRow

                anchors.centerIn: parent
                columns: -1
                rows: 1
                rowSpacing: Config.effectiveBarCapsuleWidgetSpacing
                columnSpacing: Config.effectiveBarCapsuleWidgetSpacing

                Repeater {
                    model: (wgd.modelData && wgd.modelData.isGroup) ? wgd.modelData.items : []

                    delegate: SingleWidgetLoader {
                        zone: wgd.zone
                    }

                }

                Behavior on columnSpacing {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }

                }

            }

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }

            }

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }

            }

        }

        SingleWidgetLoader {
            id: singleLoader

            visible: !wgd.isGroup
            zone: wgd.zone
            modelData: (!wgd.isGroup && wgd.modelData) ? wgd.modelData.item : null
            anchors.centerIn: parent
        }

        Behavior on implicitWidth {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }

        }

        Behavior on implicitHeight {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }

        }

    }

    Behavior on barSlideY {
        Anim {
            type: ""
            duration: 450
        }

    }

    mask: Region {
        Region {
            x: root.maskX
            y: root.maskY
            width: root.maskWidth
            height: root.maskHeight
        }

        Region {
            item: (root.hoverMenusEnabled && root.isDefaultLauncher && root.barPosition === "top" && !root.isAnyMenuOpenOrClosing) ? launcherBottomEdgeSensor : null
        }

        Region {
            item: (root.hoverMenusEnabled && root.isDefaultLauncher && root.barPosition === "bottom" && !root.isAnyMenuOpenOrClosing) ? launcherTopEdgeSensor : null
        }

    }

}
