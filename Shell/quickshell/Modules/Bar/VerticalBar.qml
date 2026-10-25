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

    property string barPosition: (Config.barPosition && Config.barPosition !== "") ? Config.barPosition : "left"
    readonly property bool isVertical: true
    readonly property bool isHorizontal: false
    readonly property bool isLeft: root.barPosition === "left"
    readonly property bool isRight: root.barPosition === "right"
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
        if (root.barPosition === "left")
            return -offset;

        return offset;
    }
    property real barSlideX: barSlideOffset
    property real barSlideY: 0
    readonly property bool isAnyMenuOpenOrClosing: anyMenuOpen || verticalControlPanelHost.height > 1 || verticalLauncherHost.height > 1 || verticalPopoutHost.width > 1
    property real contentSpan: mode == 0 ? (screen.height * widthStages) : screen.height
    property real contentWidth: root.barThickness
    property real contentHeight: root.contentSpan
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
        if (!groups || groups.length === 0) return false;
        return leftElementsLayout.implicitHeight > 0 || leftElementsLayout.children.length > 1;
    }
    readonly property bool hasCenterWidgets: {
        var groups = BarWidgetService.getGroupedWidgets(BarWidgetService.centerWidgets);
        if (!groups || groups.length === 0) return false;
        return centerElementsLayout.implicitHeight > 0 || centerElementsLayout.children.length > 1;
    }
    readonly property bool hasRightWidgets: {
        var groups = BarWidgetService.getGroupedWidgets(BarWidgetService.rightWidgets);
        if (!groups || groups.length === 0) return false;
        return rightElementsLayout.implicitHeight > 0 || rightElementsLayout.children.length > 1;
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
    readonly property bool isPopoutDockedToBottom: {
        if (!verticalPopoutHost.isPopoutMenu)
            return false;

        if (root.displayedMenuZone === "right" || root.displayedMenuZone === "bottom")
            return true;

        var h = (vPopoutMenuHost && vPopoutMenuHost.contentImplicitHeight > 0) ? vPopoutMenuHost.contentImplicitHeight : root.getMenuHeight(root.displayedMenuName);
        var center = (root.activeWidgetCenterY > 0) ? root.activeWidgetCenterY : (screen.height - 240);
        return (center + (h / 2) >= screen.height - 40);
    }
    readonly property bool isPopoutDockedToTop: {
        if (!verticalPopoutHost.isPopoutMenu)
            return false;

        if (root.displayedMenuZone === "left" || root.displayedMenuZone === "top")
            return true;

        var h = (vPopoutMenuHost && vPopoutMenuHost.contentImplicitHeight > 0) ? vPopoutMenuHost.contentImplicitHeight : root.getMenuHeight(root.displayedMenuName);
        var center = (root.activeWidgetCenterY > 0) ? root.activeWidgetCenterY : 140;
        return (center - (h / 2) <= 40);
    }
    readonly property real popoutTargetY: {
        var h = (vPopoutMenuHost && vPopoutMenuHost.contentImplicitHeight > 0) ? vPopoutMenuHost.contentImplicitHeight : root.getMenuHeight(root.displayedMenuName);
        if (isPopoutDockedToBottom)
            return screen.height - h;

        if (isPopoutDockedToTop)
            return 0;

        var center = (root.activeWidgetCenterY > 0) ? root.activeWidgetCenterY : (screen.height / 2);
        var idealY = center - (h / 2);
        return Math.max(0, Math.min(screen.height - h, idealY));
    }
    readonly property real maskX: {
        if (root.isAnyMenuOpenOrClosing)
            return 0;

        if (root.barPosition === "right")
            return screen.width - (root.barRevealed ? root.barThickness : 4);

        return 0;
    }
    readonly property real maskY: {
        if (root.isAnyMenuOpenOrClosing)
            return 0;

        if (autoHide && !root.barRevealed)
            return 0;

        return (mode > 0) ? 0 : ((screen.height - root.contentHeight) / 2);
    }
    readonly property real maskWidth: {
        if (root.isAnyMenuOpenOrClosing)
            return screen.width;

        return root.barRevealed ? root.barThickness : 4;
    }
    readonly property real maskHeight: {
        if (root.isAnyMenuOpenOrClosing)
            return screen.height;

        if (autoHide && !root.barRevealed)
            return screen.height;

        return (mode > 0) ? screen.height : root.contentHeight;
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
        if (sourceItem && sourceItem.mapToItem) {
            try {
                var pt = sourceItem.mapToItem(backgroundSurface, 0, sourceItem.height / 2);
                root.activeWidgetCenterY = pt.y;
            } catch (e) {
                root.activeWidgetCenterY = -1;
            }
        } else {
            root.activeWidgetCenterY = -1;
        }
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

    readonly property bool hoverMenusEnabled: (Config.cfg && Config.cfg.barHoverMenusEnabled !== undefined) ? Config.cfg.barHoverMenusEnabled : false
    readonly property var hoverEligibleMenus: ["volume", "brightness", "clipboard", "bluetooth", "wifi", "battery", "power"]
    function isMenuHoverEligible(name) {
        return hoverEligibleMenus.indexOf(name) !== -1;
    }

    property string pendingHoverMenu: ""
    property string pendingHoverZone: ""
    property var pendingHoverSourceItem: null
    property bool isHoveringWidget: false
    property bool isHoveringMenu: false

    Timer {
        id: hoverOpenTimer
        interval: 120
        repeat: false
        onTriggered: {
            if (!root.hoverMenusEnabled) return;
            if (root.pendingHoverMenu === "") return;
            if (!root.isHoveringWidget) return;
            if (!root.isMenuHoverEligible(root.pendingHoverMenu)) return;
            if (root.activeMenuName !== "" && !root.isMenuHoverEligible(root.activeMenuName)) return;

            root.openWidgetMenu(root.pendingHoverMenu, root.pendingHoverZone, root.pendingHoverSourceItem);
        }
    }

    Timer {
        id: hoverCloseTimer
        interval: 280
        repeat: false
        onTriggered: {
            if (!root.hoverMenusEnabled) return;
            if (!root.isHoveringWidget && !root.isHoveringMenu) {
                if (root.isMenuHoverEligible(root.activeMenuName)) {
                    root.closeMenus();
                }
            }
        }
    }

    function openWidgetMenu(menuName, zone, sourceItem) {
        if (sourceItem && sourceItem.mapToItem) {
            try {
                var pt = sourceItem.mapToItem(backgroundSurface, 0, sourceItem.height / 2);
                root.activeWidgetCenterY = pt.y;
            } catch (e) {
                root.activeWidgetCenterY = -1;
            }
        } else {
            root.activeWidgetCenterY = -1;
        }
        var targetZone = zone;
        if (!targetZone || targetZone === "")
            targetZone = BarWidgetService.findWidgetZone(menuName) || "right";

        openMenu(menuName, targetZone);
    }

    function handleWidgetHover(menuName, zone, sourceItem, hovered) {
        if (!hoverMenusEnabled) return;
        if (!isMenuHoverEligible(menuName)) return;

        if (hovered) {
            isHoveringWidget = true;
            hoverCloseTimer.stop();

            // Strictly do not hijack if Launcher or System Monitor / Control Panel is open
            if (activeMenuName !== "" && !isMenuHoverEligible(activeMenuName)) {
                return;
            }

            pendingHoverMenu = menuName;
            pendingHoverZone = zone || "";
            pendingHoverSourceItem = sourceItem || null;

            if (activeMenuName !== "" && isMenuHoverEligible(activeMenuName) && activeMenuName !== menuName) {
                hoverOpenTimer.interval = 40;
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
            if (isMenuHoverEligible(activeMenuName)) {
                hoverCloseTimer.restart();
            }
        }
    }

    function updateMenuHover(hovered) {
        if (!hoverMenusEnabled) return;
        isHoveringMenu = hovered;
        if (hovered) {
            hoverCloseTimer.stop();
        } else {
            if (!isHoveringWidget && isMenuHoverEligible(activeMenuName)) {
                hoverCloseTimer.restart();
            }
        }
    }

    property bool isHoveringControlPanelSensor: false
    property bool isHoveringControlPanelMenu: false

    Timer {
        id: cpHoverOpenTimer
        interval: 120
        repeat: false
        onTriggered: {
            if (!root.hoverMenusEnabled) return;
            if (!root.isHoveringControlPanelSensor && !root.isHoveringControlPanelMenu) return;
            if (root.activeMenuName === "controlpanel") return;
            root.openControlPanel("dashboard", "center");
        }
    }

    Timer {
        id: cpHoverCloseTimer
        interval: 280
        repeat: false
        onTriggered: {
            if (!root.hoverMenusEnabled) return;
            if (!root.isHoveringControlPanelSensor && !root.isHoveringControlPanelMenu) {
                if (root.activeMenuName === "controlpanel") {
                    root.closeMenus();
                }
            }
        }
    }

    function handleControlPanelHover(hovered) {
        if (!hoverMenusEnabled) return;
        isHoveringControlPanelSensor = hovered;
        if (hovered) {
            cpHoverCloseTimer.stop();
            if (activeMenuName !== "controlpanel") {
                cpHoverOpenTimer.restart();
            }
        } else {
            cpHoverOpenTimer.stop();
            if (activeMenuName === "controlpanel") {
                cpHoverCloseTimer.restart();
            }
        }
    }

    function updateControlPanelMenuHover(hovered) {
        if (!hoverMenusEnabled) return;
        isHoveringControlPanelMenu = hovered;
        if (hovered) {
            cpHoverCloseTimer.stop();
        } else {
            if (!isHoveringControlPanelSensor && activeMenuName === "controlpanel") {
                cpHoverCloseTimer.restart();
            }
        }
    }

    property bool isHoveringLauncherSensor: false
    property bool isHoveringLauncherMenu: false

    Timer {
        id: launcherHoverOpenTimer
        interval: 120
        repeat: false
        onTriggered: {
            if (!root.hoverMenusEnabled || !root.isDefaultLauncher) return;
            if (!root.isHoveringLauncherSensor && !root.isHoveringLauncherMenu) return;
            if (root.activeMenuName === "launcher") return;
            root.openMenu("launcher", "center");
        }
    }

    Timer {
        id: launcherHoverCloseTimer
        interval: 280
        repeat: false
        onTriggered: {
            if (!root.hoverMenusEnabled || !root.isDefaultLauncher) return;
            if (!root.isHoveringLauncherSensor && !root.isHoveringLauncherMenu) {
                if (root.activeMenuName === "launcher") {
                    root.closeMenus();
                }
            }
        }
    }

    function handleLauncherHover(hovered) {
        if (!hoverMenusEnabled || !isDefaultLauncher) return;
        isHoveringLauncherSensor = hovered;
        if (hovered) {
            launcherHoverCloseTimer.stop();
            if (activeMenuName !== "launcher") {
                launcherHoverOpenTimer.restart();
            }
        } else {
            launcherHoverOpenTimer.stop();
            if (activeMenuName === "launcher") {
                launcherHoverCloseTimer.restart();
            }
        }
    }

    function updateLauncherMenuHover(hovered) {
        if (!hoverMenusEnabled || !isDefaultLauncher) return;
        isHoveringLauncherMenu = hovered;
        if (hovered) {
            launcherHoverCloseTimer.stop();
        } else {
            if (!isHoveringLauncherSensor && activeMenuName === "launcher") {
                launcherHoverCloseTimer.restart();
            }
        }
    }

    function getMenuWidth(name) {
        switch (name) {
        case "controlpanel":
            return 1040;
        case "wallpaper":
        case "presets":
            return 1050;
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
            return 395;
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
        if (launcherOpen)
            Qt.callLater(function() {
                if (vLauncherMenuHost)
                    vLauncherMenuHost.forceActiveFocus();

            });

    }
    onWallpaperSelectorOpenChanged: {
        if (wallpaperSelectorOpen && activeMenuName !== "wallpaper")
            toggleMenu("wallpaper", "center");
        else if (!wallpaperSelectorOpen && activeMenuName === "wallpaper")
            closeMenus();
        if (wallpaperSelectorOpen)
            Qt.callLater(function() {
                if (vLauncherMenuHost)
                    vLauncherMenuHost.forceActiveFocus();
            });
    }
    onPresetSelectorOpenChanged: {
        if (presetSelectorOpen && activeMenuName !== "presets")
            toggleMenu("presets", "center");
        else if (!presetSelectorOpen && activeMenuName === "presets")
            closeMenus();
        if (presetSelectorOpen)
            Qt.callLater(function() {
                if (vLauncherMenuHost)
                    vLauncherMenuHost.forceActiveFocus();
            });
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
                return;
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
                return;
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
        top: true
        bottom: true
        left: root.barPosition === "left"
        right: root.barPosition === "right"
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

        x: root.barPosition === "right" ? (parent.width - width) : 0
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.barRevealed ? (root.barThickness + 5) : 6
        height: parent.height
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
            var maxW = root.barThickness + 5;
            var outOfBounds = barHoverHandler.point.position.x > maxW || barHoverHandler.point.position.x < 0;
            if ((!barHoverHandler.hovered || outOfBounds) && !root.isMouseOverBar) {
                if (!root.anyMenuOpen)
                    root.mouseInBar = false;

            }
        }
    }

    Item {
        id: backgroundSurface

        x: root.barPosition === "right" ? (parent.width - width + root.barSlideX) : root.barSlideX
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.barThickness
        height: parent.height
        opacity: Math.max(0, Math.min(1, root.barOpacity))
        layer.enabled: true
        layer.smooth: true

        ConcaveCorner {
            visible: root.barPosition === "left" && mode !== 2 && (Config.cfg && Config.cfg.barMeltEnabled !== false) && (capsulesContainer.height < parent.height - 2)
            width: root.barThickness
            height: Config.effectiveBarMeltRadius
            anchors.bottom: capsulesContainer.top
            anchors.left: parent.left
            color: root.barBackground
            position: "bottomLeft"
        }

        ConcaveCorner {
            visible: root.barPosition === "left" && mode !== 2 && (Config.cfg && Config.cfg.barMeltEnabled !== false) && (capsulesContainer.height < parent.height - 2)
            width: root.barThickness
            height: Config.effectiveBarMeltRadius
            anchors.top: capsulesContainer.bottom
            anchors.left: parent.left
            color: root.barBackground
            position: "topLeft"
        }

        ConcaveCorner {
            visible: root.barPosition === "right" && mode !== 2 && (Config.cfg && Config.cfg.barMeltEnabled !== false) && (capsulesContainer.height < parent.height - 2)
            width: root.barThickness
            height: Config.effectiveBarMeltRadius
            anchors.bottom: capsulesContainer.top
            anchors.right: parent.right
            color: root.barBackground
            position: "bottomRight"
        }

        ConcaveCorner {
            visible: root.barPosition === "right" && mode !== 2 && (Config.cfg && Config.cfg.barMeltEnabled !== false) && (capsulesContainer.height < parent.height - 2)
            width: root.barThickness
            height: Config.effectiveBarMeltRadius
            anchors.top: capsulesContainer.bottom
            anchors.right: parent.right
            color: root.barBackground
            position: "topRight"
        }

        Item {
            id: capsulesContainer

            x: 0
            width: root.barThickness
            height: mode === 2 ? parent.height : root.contentSpan
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.fill: parent
                color: mode === 2 ? "transparent" : root.barBackground
                radius: 0
                topLeftRadius: (root.barPosition === "right" && mode !== 1 && (!Config.cfg || Config.cfg.barMeltEnabled === false)) ? Math.min(15, Config.effectiveBarCapsuleRadius) : 0
                bottomLeftRadius: (root.barPosition === "right" && mode !== 1 && (!Config.cfg || Config.cfg.barMeltEnabled === false)) ? Math.min(15, Config.effectiveBarCapsuleRadius) : 0
                topRightRadius: (root.barPosition === "left" && mode !== 1 && (!Config.cfg || Config.cfg.barMeltEnabled === false)) ? Math.min(15, Config.effectiveBarCapsuleRadius) : 0
                bottomRightRadius: (root.barPosition === "left" && mode !== 1 && (!Config.cfg || Config.cfg.barMeltEnabled === false)) ? Math.min(15, Config.effectiveBarCapsuleRadius) : 0
            }

            Rectangle {
                id: leadCapsule

                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                height: (mode === 2 && !root.hasLeftWidgets)
                    ? 0
                    : (leftElementsLayout.implicitHeight > 0
                        ? (leftElementsLayout.implicitHeight + (Config.effectiveBarEdgeSpacing * 2))
                        : 0)
                visible: mode === 2 && root.hasLeftWidgets && height > 0
                color: root.barBackground

                radius: 0
                bottomRightRadius: (root.barPosition === "left" && mode === 2)
                    ? Config.effectiveBarCapsuleRadius : 0
                bottomLeftRadius: (root.barPosition === "right" && mode === 2)
                    ? Config.effectiveBarCapsuleRadius : 0
                topRightRadius: (root.barPosition === "left" && mode === 2 && (!Config.cfg || Config.cfg.barMeltEnabled === false))
                    ? Config.effectiveBarCapsuleRadius : 0
                topLeftRadius: (root.barPosition === "right" && mode === 2 && (!Config.cfg || Config.cfg.barMeltEnabled === false))
                    ? Config.effectiveBarCapsuleRadius : 0

                Behavior on height {
                    Anim {
                        type: "emphasized"
                        duration: 400
                    }
                }
            }

            Rectangle {
                id: centerCapsule

                anchors.centerIn: parent
                width: parent.width
                height: (mode === 2 && !root.hasCenterWidgets)
                    ? 0
                    : (centerElementsLayout.implicitHeight > 0
                        ? (centerElementsLayout.implicitHeight + (Config.effectiveBarEdgeSpacing * 2))
                        : 0)
                visible: mode === 2 && root.hasCenterWidgets && height > 0
                color: root.barBackground

                radius: 0
                topRightRadius: (root.barPosition === "left" && mode === 2)
                    ? Config.effectiveBarCapsuleRadius : 0
                bottomRightRadius: (root.barPosition === "left" && mode === 2)
                    ? Config.effectiveBarCapsuleRadius : 0
                topLeftRadius: (root.barPosition === "right" && mode === 2)
                    ? Config.effectiveBarCapsuleRadius : 0
                bottomLeftRadius: (root.barPosition === "right" && mode === 2)
                    ? Config.effectiveBarCapsuleRadius : 0

                Behavior on height {
                    Anim {
                        type: "expressive"
                        duration: 450
                    }
                }
            }

            Rectangle {
                id: tailCapsule

                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                height: (mode === 2 && !root.hasRightWidgets)
                    ? 0
                    : (rightElementsLayout.implicitHeight > 0
                        ? (rightElementsLayout.implicitHeight + (Config.effectiveBarEdgeSpacing * 2))
                        : 0)
                visible: mode === 2 && root.hasRightWidgets && height > 0
                color: root.barBackground

                radius: 0
                topRightRadius: (root.barPosition === "left" && mode === 2)
                    ? Config.effectiveBarCapsuleRadius : 0
                topLeftRadius: (root.barPosition === "right" && mode === 2)
                    ? Config.effectiveBarCapsuleRadius : 0
                bottomRightRadius: (root.barPosition === "left" && mode === 2 && (!Config.cfg || Config.cfg.barMeltEnabled === false))
                    ? Config.effectiveBarCapsuleRadius : 0
                bottomLeftRadius: (root.barPosition === "right" && mode === 2 && (!Config.cfg || Config.cfg.barMeltEnabled === false))
                    ? Config.effectiveBarCapsuleRadius : 0

                Behavior on height {
                    Anim {
                        type: "expressive"
                        duration: 450
                    }
                }
            }

            ConcaveCorner {
                visible: root.barPosition === "left" && mode === 2 && (Config.cfg && Config.cfg.barMeltEnabled !== false) && leadCapsule.visible
                width: root.barThickness
                height: Config.effectiveBarMeltRadius
                anchors.top: leadCapsule.bottom
                anchors.left: parent.left
                color: root.barBackground
                position: "topLeft"
            }

            ConcaveCorner {
                visible: root.barPosition === "left" && mode === 2 && (Config.cfg && Config.cfg.barMeltEnabled !== false) && centerCapsule.visible
                width: root.barThickness
                height: Config.effectiveBarMeltRadius
                anchors.bottom: centerCapsule.top
                anchors.left: parent.left
                color: root.barBackground
                position: "bottomLeft"
            }

            ConcaveCorner {
                visible: root.barPosition === "left" && mode === 2 && (Config.cfg && Config.cfg.barMeltEnabled !== false) && centerCapsule.visible
                width: root.barThickness
                height: Config.effectiveBarMeltRadius
                anchors.top: centerCapsule.bottom
                anchors.left: parent.left
                color: root.barBackground
                position: "topLeft"
            }

            ConcaveCorner {
                visible: root.barPosition === "left" && mode === 2 && (Config.cfg && Config.cfg.barMeltEnabled !== false) && tailCapsule.visible
                width: root.barThickness
                height: Config.effectiveBarMeltRadius
                anchors.bottom: tailCapsule.top
                anchors.left: parent.left
                color: root.barBackground
                position: "bottomLeft"
            }

            ConcaveCorner {
                visible: root.barPosition === "right" && mode === 2 && (Config.cfg && Config.cfg.barMeltEnabled !== false) && leadCapsule.visible
                width: root.barThickness
                height: Config.effectiveBarMeltRadius
                anchors.top: leadCapsule.bottom
                anchors.right: parent.right
                color: root.barBackground
                position: "topRight"
            }

            ConcaveCorner {
                visible: root.barPosition === "right" && mode === 2 && (Config.cfg && Config.cfg.barMeltEnabled !== false) && centerCapsule.visible
                width: root.barThickness
                height: Config.effectiveBarMeltRadius
                anchors.bottom: centerCapsule.top
                anchors.right: parent.right
                color: root.barBackground
                position: "bottomRight"
            }

            ConcaveCorner {
                visible: root.barPosition === "right" && mode === 2 && (Config.cfg && Config.cfg.barMeltEnabled !== false) && centerCapsule.visible
                width: root.barThickness
                height: Config.effectiveBarMeltRadius
                anchors.top: centerCapsule.bottom
                anchors.right: parent.right
                color: root.barBackground
                position: "topRight"
            }

            ConcaveCorner {
                visible: root.barPosition === "right" && mode === 2 && (Config.cfg && Config.cfg.barMeltEnabled !== false) && tailCapsule.visible
                width: root.barThickness
                height: Config.effectiveBarMeltRadius
                anchors.bottom: tailCapsule.top
                anchors.right: parent.right
                color: root.barBackground
                position: "bottomRight"
            }
        }
    }

    ConcaveCorner {
        visible: root.barPosition === "left" && mode >= 1 && (Config.cfg && Config.cfg.barMeltEnabled !== false) && (mode !== 2 || (root.hasLeftWidgets && leadCapsule.height > 0))
        opacity: backgroundSurface.opacity
        width: Config.effectiveBarMeltRadius
        height: Config.effectiveBarMeltRadius
        anchors.top: backgroundSurface.top
        anchors.left: backgroundSurface.right
        color: root.barBackground
        position: "topLeft"
    }

    ConcaveCorner {
        visible: root.barPosition === "left" && mode >= 1 && (Config.cfg && Config.cfg.barMeltEnabled !== false) && (mode !== 2 || (root.hasRightWidgets && tailCapsule.height > 0))
        opacity: backgroundSurface.opacity
        width: Config.effectiveBarMeltRadius
        height: Config.effectiveBarMeltRadius
        anchors.bottom: backgroundSurface.bottom
        anchors.left: backgroundSurface.right
        color: root.barBackground
        position: "bottomLeft"
    }

    ConcaveCorner {
        visible: root.barPosition === "right" && mode >= 1 && (Config.cfg && Config.cfg.barMeltEnabled !== false) && (mode !== 2 || (root.hasLeftWidgets && leadCapsule.height > 0))
        opacity: backgroundSurface.opacity
        width: Config.effectiveBarMeltRadius
        height: Config.effectiveBarMeltRadius
        anchors.top: backgroundSurface.top
        anchors.right: backgroundSurface.left
        color: root.barBackground
        position: "topRight"
    }

    ConcaveCorner {
        visible: root.barPosition === "right" && mode >= 1 && (Config.cfg && Config.cfg.barMeltEnabled !== false) && (mode !== 2 || (root.hasRightWidgets && tailCapsule.height > 0))
        opacity: backgroundSurface.opacity
        width: Config.effectiveBarMeltRadius
        height: Config.effectiveBarMeltRadius
        anchors.bottom: backgroundSurface.bottom
        anchors.right: backgroundSurface.left
        color: root.barBackground
        position: "bottomRight"
    }

    Item {
        id: verticalControlPanelHost

        visible: root.controlPanelOpen || verticalControlPanelHost.height > 1
        z: 3
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: (Config.cfg && Config.cfg.barMeltEnabled !== false) ? 0 : 10
        width: root.controlPanelOpen ? vControlPanelMenuHost.contentImplicitWidth : 200
        height: root.controlPanelOpen ? vControlPanelMenuHost.contentImplicitHeight : 0

        ConcaveCorner {
            visible: (Config.cfg && Config.cfg.barMeltEnabled !== false) && (root.controlPanelOpen || verticalControlPanelHost.height > 1)
            opacity: (root.controlPanelOpen && verticalControlPanelHost.height > 8) ? 1 : 0
            width: Config.effectiveBarMeltRadius
            height: Config.effectiveBarMeltRadius
            anchors.top: verticalControlPanelHost.top
            anchors.right: verticalControlPanelHost.left
            color: root.barBackground
            position: "topRight"

            Behavior on opacity {
                Anim {
                    type: "effects"
                    duration: 180
                }

            }

        }

        ConcaveCorner {
            visible: (Config.cfg && Config.cfg.barMeltEnabled !== false) && (root.controlPanelOpen || verticalControlPanelHost.height > 1)
            opacity: (root.controlPanelOpen && verticalControlPanelHost.height > 8) ? 1 : 0
            width: Config.effectiveBarMeltRadius
            height: Config.effectiveBarMeltRadius
            anchors.top: verticalControlPanelHost.top
            anchors.left: verticalControlPanelHost.right
            color: root.barBackground
            position: "topLeft"

            Behavior on opacity {
                Anim {
                    type: "effects"
                    duration: 180
                }

            }

        }

        Rectangle {
            id: vControlPanelBg

            anchors.fill: parent
            color: root.barBackground
            radius: (Config.cfg && Config.cfg.barMeltEnabled !== false) ? 0 : Config.effectiveMenuRadius
            topLeftRadius: (Config.cfg && Config.cfg.barMeltEnabled !== false) ? 0 : Config.effectiveMenuRadius
            topRightRadius: (Config.cfg && Config.cfg.barMeltEnabled !== false) ? 0 : Config.effectiveMenuRadius
            bottomLeftRadius: (Config.cfg && Config.cfg.barMeltEnabled !== false) ? (root.controlPanelOpen ? Math.round(Config.effectiveBarCapsuleRadius * 1.33) : Config.effectiveBarCapsuleRadius) : Config.effectiveMenuRadius
            bottomRightRadius: (Config.cfg && Config.cfg.barMeltEnabled !== false) ? (root.controlPanelOpen ? Math.round(Config.effectiveBarCapsuleRadius * 1.33) : Config.effectiveBarCapsuleRadius) : Config.effectiveMenuRadius
            border.color: root.borderCol
            border.width: (Config.cfg && Config.cfg.barMeltEnabled !== false) ? 0 : 1
            clip: true

            MouseArea {
                anchors.fill: parent
                onClicked: {
                }
            }

            HoverHandler {
                enabled: root.hoverMenusEnabled && root.controlPanelOpen
                onHoveredChanged: root.updateControlPanelMenuHover(hovered)
            }

            MenuHost {
                id: vControlPanelMenuHost

                allowedMenu: "controlpanel"
                zone: "center"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                width: parent.width
                height: contentImplicitHeight
                z: 1
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

    Item {
        id: verticalLauncherHost

        readonly property bool isDefaultLauncher: root.isDefaultLauncher
        readonly property bool isLauncherOrWallpaperOpen: root.launcherOpen || root.wallpaperSelectorOpen || root.presetSelectorOpen

        visible: isDefaultLauncher && (isLauncherOrWallpaperOpen || verticalLauncherHost.height > 1)
        z: 3
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: (Config.cfg && Config.cfg.barMeltEnabled !== false) ? 0 : 10
        width: vLauncherMenuHost.contentImplicitWidth
        height: isLauncherOrWallpaperOpen ? vLauncherMenuHost.contentImplicitHeight : 0

        ConcaveCorner {
            visible: (Config.cfg && Config.cfg.barMeltEnabled !== false) && (verticalLauncherHost.isLauncherOrWallpaperOpen || verticalLauncherHost.height > 1)
            opacity: (verticalLauncherHost.isLauncherOrWallpaperOpen && verticalLauncherHost.height > 8) ? 1 : 0
            width: Config.effectiveBarMeltRadius
            height: Config.effectiveBarMeltRadius
            anchors.bottom: verticalLauncherHost.bottom
            anchors.right: verticalLauncherHost.left
            color: root.barBackground
            position: "bottomRight"

            Behavior on opacity {
                Anim {
                    type: "effects"
                    duration: 180
                }
            }
        }

        ConcaveCorner {
            visible: (Config.cfg && Config.cfg.barMeltEnabled !== false) && (verticalLauncherHost.isLauncherOrWallpaperOpen || verticalLauncherHost.height > 1)
            opacity: (verticalLauncherHost.isLauncherOrWallpaperOpen && verticalLauncherHost.height > 8) ? 1 : 0
            width: Config.effectiveBarMeltRadius
            height: Config.effectiveBarMeltRadius
            anchors.bottom: verticalLauncherHost.bottom
            anchors.left: verticalLauncherHost.right
            color: root.barBackground
            position: "bottomLeft"

            Behavior on opacity {
                Anim {
                    type: "effects"
                    duration: 180
                }
            }
        }

        Rectangle {
            id: vLauncherBg

            anchors.fill: parent
            color: root.barBackground
            radius: (Config.cfg && Config.cfg.barMeltEnabled !== false) ? 0 : Config.effectiveMenuRadius
            topLeftRadius: (Config.cfg && Config.cfg.barMeltEnabled !== false) ? (verticalLauncherHost.isLauncherOrWallpaperOpen ? Math.round(Config.effectiveBarCapsuleRadius * 1.33) : Config.effectiveBarCapsuleRadius) : Config.effectiveMenuRadius
            topRightRadius: (Config.cfg && Config.cfg.barMeltEnabled !== false) ? (verticalLauncherHost.isLauncherOrWallpaperOpen ? Math.round(Config.effectiveBarCapsuleRadius * 1.33) : Config.effectiveBarCapsuleRadius) : Config.effectiveMenuRadius
            bottomLeftRadius: (Config.cfg && Config.cfg.barMeltEnabled !== false) ? 0 : Config.effectiveMenuRadius
            bottomRightRadius: (Config.cfg && Config.cfg.barMeltEnabled !== false) ? 0 : Config.effectiveMenuRadius
            border.color: root.borderCol
            border.width: (Config.cfg && Config.cfg.barMeltEnabled !== false) ? 0 : 1
            clip: true

            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            HoverHandler {
                enabled: root.hoverMenusEnabled && root.isDefaultLauncher && (root.launcherOpen || root.wallpaperSelectorOpen || root.presetSelectorOpen)
                onHoveredChanged: root.updateLauncherMenuHover(hovered)
            }

            MenuHost {
                id: vLauncherMenuHost

                allowedMenu: "center"
                zone: "center"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                width: parent.width
                height: contentImplicitHeight
                z: 1
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
        }

        Behavior on height {
            Anim {
                type: "expressive"
                duration: 450
            }
        }
    }

    Item {
        id: cpTopEdgeSensor

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: 320
        height: 10
        z: 10
        visible: root.hoverMenusEnabled

        HoverHandler {
            enabled: root.hoverMenusEnabled
            onHoveredChanged: root.handleControlPanelHover(hovered)
        }
    }

    Item {
        id: launcherBottomEdgeSensor

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: 320
        height: 10
        z: 10
        visible: root.hoverMenusEnabled && root.isDefaultLauncher

        HoverHandler {
            enabled: root.hoverMenusEnabled && root.isDefaultLauncher
            onHoveredChanged: root.handleLauncherHover(hovered)
        }
    }

    Item {
        id: verticalPopoutHost

        readonly property bool isPopoutMenu: root.displayedMenuName !== "controlpanel" && root.displayedMenuName !== "launcher" && root.displayedMenuName !== "wallpaper" && root.displayedMenuName !== "presets"

        visible: isPopoutMenu && (root.anyMenuOpen || verticalPopoutHost.width > 1)
        z: 3
        x: {
            var gap = (Config.cfg && Config.cfg.barMeltEnabled !== false) ? 0 : 8;
            if (root.barPosition === "right")
                return parent.width - width - root.barThickness - gap;
            return root.barThickness + gap;
        }
        anchors.top: parent.top
        anchors.topMargin: root.popoutTargetY
        width: (root.anyMenuOpen && isPopoutMenu) ? vPopoutMenuHost.contentImplicitWidth : 0
        height: vPopoutMenuHost.contentImplicitHeight

        HoverHandler {
            enabled: root.hoverMenusEnabled && verticalPopoutHost.visible && verticalPopoutHost.width > 10
            onHoveredChanged: root.updateMenuHover(hovered)
        }

        ConcaveCorner {
            visible: root.barPosition === "left" && (Config.cfg && Config.cfg.barMeltEnabled !== false) && verticalPopoutHost.isPopoutMenu && (root.anyMenuOpen || verticalPopoutHost.width > 1) && !root.isPopoutDockedToTop
            opacity: (root.anyMenuOpen && verticalPopoutHost.isPopoutMenu && verticalPopoutHost.width > 8) ? 1 : 0
            width: Config.effectiveBarMeltRadius
            height: Config.effectiveBarMeltRadius
            anchors.bottom: verticalPopoutHost.top
            anchors.left: verticalPopoutHost.left
            color: root.barBackground
            position: "bottomLeft"

            Behavior on opacity {
                Anim {
                    type: "effects"
                    duration: 180
                }

            }

        }

        ConcaveCorner {
            visible: root.barPosition === "left" && (Config.cfg && Config.cfg.barMeltEnabled !== false) && verticalPopoutHost.isPopoutMenu && (root.anyMenuOpen || verticalPopoutHost.width > 1) && !root.isPopoutDockedToBottom
            opacity: (root.anyMenuOpen && verticalPopoutHost.isPopoutMenu && verticalPopoutHost.width > 8) ? 1 : 0
            width: Config.effectiveBarMeltRadius
            height: Config.effectiveBarMeltRadius
            anchors.top: verticalPopoutHost.bottom
            anchors.left: verticalPopoutHost.left
            color: root.barBackground
            position: "topLeft"

            Behavior on opacity {
                Anim {
                    type: "effects"
                    duration: 180
                }

            }

        }

        ConcaveCorner {
            visible: root.barPosition === "right" && (Config.cfg && Config.cfg.barMeltEnabled !== false) && verticalPopoutHost.isPopoutMenu && (root.anyMenuOpen || verticalPopoutHost.width > 1) && !root.isPopoutDockedToTop
            opacity: (root.anyMenuOpen && verticalPopoutHost.isPopoutMenu && verticalPopoutHost.width > 8) ? 1 : 0
            width: Config.effectiveBarMeltRadius
            height: Config.effectiveBarMeltRadius
            anchors.bottom: verticalPopoutHost.top
            anchors.right: verticalPopoutHost.right
            color: root.barBackground
            position: "bottomRight"

            Behavior on opacity {
                Anim {
                    type: "effects"
                    duration: 180
                }

            }

        }

        ConcaveCorner {
            visible: root.barPosition === "right" && (Config.cfg && Config.cfg.barMeltEnabled !== false) && verticalPopoutHost.isPopoutMenu && (root.anyMenuOpen || verticalPopoutHost.width > 1) && !root.isPopoutDockedToBottom
            opacity: (root.anyMenuOpen && verticalPopoutHost.isPopoutMenu && verticalPopoutHost.width > 8) ? 1 : 0
            width: Config.effectiveBarMeltRadius
            height: Config.effectiveBarMeltRadius
            anchors.top: verticalPopoutHost.bottom
            anchors.right: verticalPopoutHost.right
            color: root.barBackground
            position: "topRight"

            Behavior on opacity {
                Anim {
                    type: "effects"
                    duration: 180
                }

            }

        }

        Rectangle {
            id: vPopoutBg

            anchors.fill: parent
            color: root.barBackground
            radius: (Config.cfg && Config.cfg.barMeltEnabled !== false) ? 0 : Config.effectiveMenuRadius
            topLeftRadius: (Config.cfg && Config.cfg.barMeltEnabled !== false) ? (root.barPosition === "right" ? (root.isPopoutDockedToTop ? 0 : Math.round(Config.effectiveBarCapsuleRadius * 1.33)) : 0) : Config.effectiveMenuRadius
            bottomLeftRadius: (Config.cfg && Config.cfg.barMeltEnabled !== false) ? (root.barPosition === "right" ? (root.isPopoutDockedToBottom ? 0 : Math.round(Config.effectiveBarCapsuleRadius * 1.33)) : 0) : Config.effectiveMenuRadius
            topRightRadius: (Config.cfg && Config.cfg.barMeltEnabled !== false) ? (root.barPosition === "left" ? (root.isPopoutDockedToTop ? 0 : Math.round(Config.effectiveBarCapsuleRadius * 1.33)) : 0) : Config.effectiveMenuRadius
            bottomRightRadius: (Config.cfg && Config.cfg.barMeltEnabled !== false) ? (root.barPosition === "left" ? (root.isPopoutDockedToBottom ? 0 : Math.round(Config.effectiveBarCapsuleRadius * 1.33)) : 0) : Config.effectiveMenuRadius
            border.color: root.borderCol
            border.width: (Config.cfg && Config.cfg.barMeltEnabled !== false) ? 0 : 1
            clip: true

            MouseArea {
                anchors.fill: parent
                onClicked: {
                }
            }

            MenuHost {
                id: vPopoutMenuHost

                allowedMenu: "popout"
                zone: root.displayedMenuZone
                x: root.barPosition === "right" ? (parent.width - width) : 0
                anchors.top: parent.top
                width: contentImplicitWidth
                height: contentImplicitHeight
                z: 1
            }

            Behavior on topLeftRadius {
                Anim {
                    type: "expressive"
                    duration: 400
                }

            }

            Behavior on bottomLeftRadius {
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

            Behavior on bottomRightRadius {
                Anim {
                    type: "expressive"
                    duration: 400
                }

            }

        }

        Behavior on anchors.topMargin {
            Anim {
                type: "emphasized"
                duration: 250
            }

        }

        Behavior on width {
            Anim {
                type: "expressive"
                duration: 450
            }

        }

        Behavior on height {
            Anim {
                type: "expressive"
                duration: 450
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

        Workspaces {}
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

        VerticalPlayer {
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

        Clock {}
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
        width: root.barThickness
        height: parent.height
        x: root.barPosition === "right" ? (parent.width - width + root.barSlideX) : root.barSlideX
        anchors.verticalCenter: parent.verticalCenter
        visible: (Config.cfg && Config.cfg.barVisualizerEnabled !== undefined) ? Config.cfg.barVisualizerEnabled : false
        clip: true

        BarVisualizer {
            width: parent.height
            height: parent.width
            anchors.centerIn: parent
            rotation: root.barPosition === "left" ? 90 : -90
            barRadius: root.mode === 1 ? 0 : Config.effectiveBarCapsuleRadius
            primaryColor: root.primary
            secondaryColor: root.secondary
        }

    }

    Item {
        id: iconsSection

        z: 4
        width: root.barThickness
        height: capsulesContainer.height
        x: root.barPosition === "right" ? (parent.width - width + root.barSlideX) : root.barSlideX
        anchors.verticalCenter: parent.verticalCenter

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
            columns: 1
            rows: -1
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: Config.effectiveBarEdgeSpacing
            rowSpacing: Config.effectiveBarWidgetSpacing
            columnSpacing: Config.effectiveBarWidgetSpacing

            Behavior on anchors.topMargin {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on rowSpacing {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            Repeater {
                model: BarWidgetService.getGroupedWidgets(BarWidgetService.leftWidgets)

                delegate: WidgetGroupDelegate {
                    zone: "left"
                }

            }

        }

        GridLayout {
            id: centerElementsLayout

            visible: mode !== 2 || root.hasCenterWidgets
            columns: 1
            rows: -1
            anchors.centerIn: parent
            rowSpacing: Config.effectiveBarWidgetSpacing
            columnSpacing: Config.effectiveBarWidgetSpacing

            Behavior on rowSpacing {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            Repeater {
                model: BarWidgetService.getGroupedWidgets(BarWidgetService.centerWidgets)

                delegate: WidgetGroupDelegate {
                    zone: "center"
                }

            }

        }

        GridLayout {
            id: rightElementsLayout

            visible: mode !== 2 || root.hasRightWidgets
            columns: 1
            rows: -1
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: Config.effectiveBarEdgeSpacing
            rowSpacing: Config.effectiveBarWidgetSpacing
            columnSpacing: Config.effectiveBarWidgetSpacing

            Behavior on anchors.bottomMargin {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on rowSpacing {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            Repeater {
                model: BarWidgetService.getGroupedWidgets(BarWidgetService.rightWidgets)

                delegate: WidgetGroupDelegate {
                    zone: "right"
                }

            }

        }

    }

    component MenuHost: Item {
        id: mh

        required property string zone
        property string allowedMenu: ""
        readonly property string currentMenu: (allowedMenu !== "" && allowedMenu !== "popout" && allowedMenu !== "center")
            ? allowedMenu
            : (root.activeMenuName !== "" ? root.activeMenuName : root.lastMenuName)
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

        Loader {
            id: loaderControlPanel

            property bool _loaded: false

            width: item ? item.implicitWidth : root.getMenuWidth("controlpanel")
            height: item ? item.implicitHeight : root.getMenuHeight("controlpanel")
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            active: (mh.allowedMenu === "controlpanel") && (_loaded || (mh.currentMenu === "controlpanel" || mh.currentMenu === "controlPanel"))
            visible: (mh.allowedMenu === "controlpanel") && (mh.currentMenu === "controlpanel" || mh.currentMenu === "controlPanel")
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

            width: item ? item.implicitWidth : root.getMenuWidth("launcher")
            height: item ? item.implicitHeight : root.getMenuHeight("launcher")
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            active: (mh.allowedMenu === "launcher" || mh.allowedMenu === "center") && mh.currentMenu === "launcher"
            visible: active
            onLoaded: {
                if (item)
                    item.forceActiveFocus();
            }

            sourceComponent: Component {
                AppLauncher {
                    isOpen: root.activeMenuName === "launcher"
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
            active: (mh.allowedMenu === "wallpaper" || mh.allowedMenu === "center") && mh.currentMenu === "wallpaper"
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
            id: loaderPresets

            anchors.fill: parent
            active: (mh.allowedMenu === "presets" || mh.allowedMenu === "center") && mh.currentMenu === "presets"
            visible: active
            onLoaded: {
                if (item)
                    item.forceActiveFocus();
            }

            sourceComponent: Component {
                PresetSelector {
                }
            }
        }

        Loader {
            id: loaderPlayer

            width: item ? item.implicitWidth : mh.contentImplicitWidth
            height: item ? item.implicitHeight : mh.contentImplicitHeight
            anchors.top: parent.top
            x: root.barPosition === "right" ? (parent.width - width) : 0
            active: mh.allowedMenu === "popout" && mh.currentMenu === "player"
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

            width: item ? item.implicitWidth : mh.contentImplicitWidth
            height: item ? item.implicitHeight : mh.contentImplicitHeight
            anchors.top: parent.top
            x: root.barPosition === "right" ? (parent.width - width) : 0
            active: mh.allowedMenu === "popout" && mh.currentMenu === "wifi"
            visible: active

            sourceComponent: Component {
                WifiMenu {
                }

            }

        }

        Loader {
            id: loaderBluetooth

            width: item ? item.implicitWidth : mh.contentImplicitWidth
            height: item ? item.implicitHeight : mh.contentImplicitHeight
            anchors.top: parent.top
            x: root.barPosition === "right" ? (parent.width - width) : 0
            active: mh.allowedMenu === "popout" && mh.currentMenu === "bluetooth"
            visible: active

            sourceComponent: Component {
                BluetoothMenu {
                }

            }

        }

        Loader {
            id: loaderBattery

            width: item ? item.implicitWidth : mh.contentImplicitWidth
            height: item ? item.implicitHeight : mh.contentImplicitHeight
            anchors.top: parent.top
            x: root.barPosition === "right" ? (parent.width - width) : 0
            active: mh.allowedMenu === "popout" && mh.currentMenu === "battery"
            visible: active

            sourceComponent: Component {
                BatteryMenu {
                }

            }

        }

        Loader {
            id: loaderPower

            width: item ? item.implicitWidth : mh.contentImplicitWidth
            height: item ? item.implicitHeight : mh.contentImplicitHeight
            anchors.top: parent.top
            x: root.barPosition === "right" ? (parent.width - width) : 0
            active: mh.allowedMenu === "popout" && mh.currentMenu === "power"
            visible: active

            sourceComponent: Component {
                BarPowerMenu {
                }

            }

        }

        Loader {
            id: loaderVolume

            width: item ? item.implicitWidth : mh.contentImplicitWidth
            height: item ? item.implicitHeight : mh.contentImplicitHeight
            anchors.top: parent.top
            x: root.barPosition === "right" ? (parent.width - width) : 0
            active: mh.allowedMenu === "popout" && mh.currentMenu === "volume"
            visible: active

            sourceComponent: Component {
                VolumeMenu {
                }

            }

        }

        Loader {
            id: loaderBrightness

            width: item ? item.implicitWidth : mh.contentImplicitWidth
            height: item ? item.implicitHeight : mh.contentImplicitHeight
            anchors.top: parent.top
            x: root.barPosition === "right" ? (parent.width - width) : 0
            active: mh.allowedMenu === "popout" && mh.currentMenu === "brightness"
            visible: active

            sourceComponent: Component {
                BrightnessMenu {
                }

            }

        }

        Loader {
            id: loaderClipboard

            width: item ? item.implicitWidth : mh.contentImplicitWidth
            height: item ? item.implicitHeight : mh.contentImplicitHeight
            anchors.top: parent.top
            x: root.barPosition === "right" ? (parent.width - width) : 0
            active: mh.allowedMenu === "popout" && mh.currentMenu === "clipboard"
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

    component SingleWidgetLoader: Loader {
        id: swl

        property string zone: ""
        required property var modelData
        readonly property var widgetData: modelData
        property string targetZone: zone

        visible: widgetData && widgetData.visible !== false
        active: visible
        Layout.preferredWidth: Math.min(item ? (item.implicitWidth > 0 ? item.implicitWidth : item.width) : Math.round(22 * Config.barScale), root.barThickness - 4)
        Layout.preferredHeight: item ? (item.implicitHeight > 0 ? item.implicitHeight : item.height) : Math.round(22 * Config.barIconScale)
        Layout.alignment: Qt.AlignHCenter
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
        readonly property real capsuleWidth: Math.min(Math.round(24 * Config.barScale), root.barThickness - 4)
        readonly property real capsuleVerticalPadding: Config.effectiveBarCapsulePadding

        implicitWidth: isGroup ? capsuleWidth : Math.min(singleLoader.implicitWidth, root.barThickness - 4)
        implicitHeight: isGroup ? (groupRow.implicitHeight + (capsuleVerticalPadding * 2)) : singleLoader.implicitHeight
        width: implicitWidth
        height: implicitHeight
        Layout.preferredWidth: implicitWidth
        Layout.preferredHeight: implicitHeight
        Layout.alignment: Qt.AlignHCenter

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

        Item {
            id: groupItem

            visible: wgd.isGroup
            implicitWidth: wgd.capsuleWidth
            implicitHeight: groupRow.implicitHeight + (wgd.capsuleVerticalPadding * 2)
            anchors.centerIn: parent
            height: implicitHeight
            width: implicitWidth

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

            Rectangle {
                anchors.fill: parent
                color: root.color1
                opacity: 0.25
                radius: Config.effectiveBarCapsuleRadius === 0 ? 0 : (width / 2)
            }

            GridLayout {
                id: groupRow

                anchors.centerIn: parent
                columns: 1
                rows: -1
                rowSpacing: Config.effectiveBarCapsuleWidgetSpacing
                columnSpacing: Config.effectiveBarCapsuleWidgetSpacing

                Behavior on rowSpacing {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

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
            anchors.centerIn: parent
        }

    }

    Behavior on barSlideX {
        Anim {
            type: "expressive"
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
            item: (root.hoverMenusEnabled && !root.isAnyMenuOpenOrClosing) ? cpTopEdgeSensor : null
        }

        Region {
            item: (root.hoverMenusEnabled && root.isDefaultLauncher && !root.isAnyMenuOpenOrClosing) ? launcherBottomEdgeSensor : null
        }
    }

}
