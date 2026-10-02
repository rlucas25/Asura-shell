import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Animations
import qs.Asura
import qs.Components
import qs.Services

Item {
    id: root

    // SEMANTIC COLORS
    property color primary: Colors.cfg.primary
    property color secondary: Colors.cfg.secondary
    property color tertiary: Colors.cfg.tertiary
    property color background: Colors.cfg.background
    property color surface: Qt.alpha(Colors.cfg.surface, Math.max(0, Math.min(1, Config.cfg.opacity)))
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
    // COMPATIBILITY ALIASES
    property alias color1: root.primary
    property alias color2: root.secondary
    property alias textColor: root.text
    property alias textMuted: root.textSecondary
    property alias foreground: root.on_primary
    property string activeTab: "dashboard" // "dashboard" | "system" | "timer" | "notifications"
    // Tab switching scroll transition
    readonly property var tabsList: ["dashboard", "timer", "notifications", "system"]
    property string currentTab: activeTab
    property string previousTab: activeTab
    property int scrollDirection: 1 // 1: scrolling forward (down), -1: scrolling backward (up)
    property real scrollProgress: 1
    property bool isTransitioning: false

    signal hideMenu()

    function getTabY(tabName) {
        if (!isTransitioning)
            return 0;

        var h = tabsViewport.height > 0 ? tabsViewport.height : 430;
        if (tabName === currentTab)
            return (1 - scrollProgress) * (scrollDirection * h);

        if (tabName === previousTab)
            return -scrollProgress * (scrollDirection * h);

        return 0;
    }

    function getTabOpacity(tabName) {
        if (!isTransitioning)
            return tabName === currentTab ? 1 : 0;

        if (tabName === currentTab)
            return 0.35 + 0.65 * scrollProgress;

        if (tabName === previousTab)
            return 1 - 0.65 * scrollProgress;

        return 0;
    }

    function isTabVisible(tabName) {
        if (!root.visible)
            return false;

        if (!isTransitioning)
            return tabName === currentTab;

        return tabName === currentTab || tabName === previousTab;
    }

    implicitWidth: 1040
    implicitHeight: 460
    // Keyboard navigation
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            const tabs = ["dashboard", "timer", "notifications", "system"];
            const cur = tabs.indexOf(root.activeTab);
            if (event.key === Qt.Key_Tab)
                root.activeTab = tabs[(cur + 1) % tabs.length];
            else
                root.activeTab = tabs[(cur - 1 + tabs.length) % tabs.length];
            event.accepted = true;
            return ;
        }
        if (event.key === Qt.Key_Space) {
            if (root.activeTab === "dashboard") {
                if (PlayerService.activePlayer)
                    PlayerService.activePlayer.togglePlaying();

                event.accepted = true;
                return ;
            }
            if (root.activeTab === "timer") {
                const m = TimerService.activeMode;
                if (m === "pomodoro")
                    TimerService.togglePomodoro();
                else if (m === "timer")
                    TimerService.toggleTimer();
                else if (m === "stopwatch")
                    TimerService.toggleStopwatch();
                event.accepted = true;
                return ;
            }
        }
        if (event.key === Qt.Key_Escape) {
            root.hideMenu();
            event.accepted = true;
        }
    }
    onVisibleChanged: {
        if (root.visible)
            Qt.callLater(function() {
            root.forceActiveFocus();
        });

    }
    onActiveTabChanged: {
        if (activeTab === currentTab)
            return ;

        var oldIdx = tabsList.indexOf(currentTab);
        var newIdx = tabsList.indexOf(activeTab);
        if (oldIdx < 0)
            oldIdx = 0;

        if (newIdx < 0)
            newIdx = 0;

        var count = tabsList.length;
        if (newIdx === (oldIdx + 1) % count)
            scrollDirection = 1;
        else if (newIdx === (oldIdx - 1 + count) % count)
            scrollDirection = -1;
        else
            scrollDirection = (newIdx > oldIdx) ? 1 : -1;
        previousTab = currentTab;
        currentTab = activeTab;
        if (root.visible) {
            scrollAnim.stop();
            scrollProgress = 0;
            isTransitioning = true;
            scrollAnim.restart();
        } else {
            scrollProgress = 1;
            isTransitioning = false;
        }
    }

    MenuEntrance {
        id: panelEntrance

        active: root.visible
        duration: 380
        startScale: 0.7
        startOffsetY: 8
    }

    MenuEntrance {
        id: sidebarEntrance

        active: root.visible
        duration: 280
        startOffsetY: 0
    }

    NumberAnimation {
        id: scrollAnim

        target: root
        property: "scrollProgress"
        from: 0
        to: 1
        duration: 340
        easing.type: Easing.OutCubic
        onFinished: {
            root.isTransitioning = false;
        }
    }

    Binding {
        target: SystemMonitorService
        property: "active"
        value: root.visible && root.activeTab === "system"
    }

    Process {
        id: openSettingsProc

        command: ["quickshell", "ipc", "call", "settings", "open"]
    }

    // MAIN CONTAINER: SIDEBAR + CONTENT TABS
    Rectangle {
        id: mainContainer

        //clip: true
        anchors.fill: parent
        color: "transparent"
        radius: 30
        scale: panelEntrance.scale
        opacity: panelEntrance.opacity
        transformOrigin: Item.Top

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 14

            // LEFT SIDEBAR
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 58
                radius: 24
                color: root.surface
                opacity: sidebarEntrance.opacity

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 7
                    spacing: 8

                    Item {
                        id: tabsNavContainer

                        Layout.fillWidth: true
                        implicitHeight: tabsColumn.implicitHeight

                        Rectangle {
                            id: activeIndicator

                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 44
                            height: 44
                            radius: 16
                            color: root.color1
                            y: {
                                if (root.activeTab === "dashboard")
                                    return tabDash.y;

                                if (root.activeTab === "timer")
                                    return tabTimer.y;

                                if (root.activeTab === "notifications")
                                    return tabNotif.y;

                                if (root.activeTab === "system")
                                    return tabSys.y;

                                return 0;
                            }

                            Behavior on y {
                                NumberAnimation {
                                    duration: 320
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.15
                                }

                            }

                        }

                        Column {
                            id: tabsColumn

                            anchors.fill: parent
                            spacing: 8

                            Rectangle {
                                id: tabDash

                                width: parent.width
                                height: 44
                                radius: 16
                                color: root.activeTab === "dashboard" ? "transparent" : (dashH.hovered ? Qt.alpha(root.textColor, 0.06) : "transparent")
                                scale: dashMouse.pressed ? 0.92 : (dashH.hovered ? 1.04 : 1)

                                Text {
                                    anchors.centerIn: parent
                                    text: "dashboard"
                                    font.pixelSize: 22
                                    font.family: "Material Symbols Rounded"
                                    color: root.activeTab === "dashboard" ? root.foreground : (dashH.hovered ? root.color1 : root.textMuted)

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 180
                                            easing.type: Easing.OutCubic
                                        }

                                    }

                                }

                                HoverHandler {
                                    id: dashH
                                }

                                MouseArea {
                                    id: dashMouse

                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.activeTab = "dashboard"
                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 140
                                        easing.type: Easing.OutBack
                                    }

                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 180
                                        easing.type: Easing.OutCubic
                                    }

                                }

                            }

                            Rectangle {
                                id: tabTimer

                                width: parent.width
                                height: 44
                                radius: 16
                                color: root.activeTab === "timer" ? "transparent" : (timerH.hovered ? Qt.alpha(root.textColor, 0.06) : "transparent")
                                scale: timerMouse.pressed ? 0.92 : (timerH.hovered ? 1.04 : 1)

                                Text {
                                    anchors.centerIn: parent
                                    text: "timer"
                                    font.pixelSize: 22
                                    font.family: "Material Symbols Rounded"
                                    color: root.activeTab === "timer" ? root.foreground : (TimerService.isAnyActive ? root.color1 : (timerH.hovered ? root.color1 : root.textMuted))

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 180
                                            easing.type: Easing.OutCubic
                                        }

                                    }

                                }

                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 6
                                    width: 7
                                    height: 7
                                    radius: 3.5
                                    color: root.activeTab === "timer" ? root.foreground : root.color1
                                    visible: TimerService.isAnyActive
                                }

                                HoverHandler {
                                    id: timerH
                                }

                                MouseArea {
                                    id: timerMouse

                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.activeTab = "timer"
                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 140
                                        easing.type: Easing.OutBack
                                    }

                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 180
                                        easing.type: Easing.OutCubic
                                    }

                                }

                            }

                            Rectangle {
                                id: tabNotif

                                width: parent.width
                                height: 44
                                radius: 16
                                color: root.activeTab === "notifications" ? "transparent" : (notifH.hovered ? Qt.alpha(root.textColor, 0.06) : "transparent")
                                scale: notifMouse.pressed ? 0.92 : (notifH.hovered ? 1.04 : 1)

                                Text {
                                    anchors.centerIn: parent
                                    text: "notifications"
                                    font.pixelSize: 22
                                    font.family: "Material Symbols Rounded"
                                    color: root.activeTab === "notifications" ? root.foreground : (notifH.hovered ? root.color1 : root.textMuted)

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 180
                                            easing.type: Easing.OutCubic
                                        }

                                    }

                                }

                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 4
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: Colors.cfg.warning
                                    visible: NotificationService.unreadCount > 0 && root.activeTab !== "notifications"

                                    Text {
                                        anchors.centerIn: parent
                                        text: NotificationService.unreadCount > 9 ? "9+" : NotificationService.unreadCount
                                        font.family: "Google Sans"
                                        font.pixelSize: 8
                                        font.bold: true
                                        color: "#ffffff"
                                    }

                                }

                                HoverHandler {
                                    id: notifH
                                }

                                MouseArea {
                                    id: notifMouse

                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.activeTab = "notifications"
                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 140
                                        easing.type: Easing.OutBack
                                    }

                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 180
                                        easing.type: Easing.OutCubic
                                    }

                                }

                            }

                            Rectangle {
                                id: tabSys

                                width: parent.width
                                height: 44
                                radius: 16
                                color: root.activeTab === "system" ? "transparent" : (sysH.hovered ? Qt.alpha(root.textColor, 0.06) : "transparent")
                                scale: sysMouse.pressed ? 0.92 : (sysH.hovered ? 1.04 : 1)

                                Text {
                                    anchors.centerIn: parent
                                    text: "memory"
                                    font.pixelSize: 22
                                    font.family: "Material Symbols Rounded"
                                    color: root.activeTab === "system" ? root.foreground : (sysH.hovered ? root.color1 : root.textMuted)

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 180
                                            easing.type: Easing.OutCubic
                                        }

                                    }

                                }

                                HoverHandler {
                                    id: sysH
                                }

                                MouseArea {
                                    id: sysMouse

                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.activeTab = "system"
                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 140
                                        easing.type: Easing.OutBack
                                    }

                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 180
                                        easing.type: Easing.OutCubic
                                    }

                                }

                            }

                        }

                    }

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 1
                        Layout.alignment: Qt.AlignHCenter
                        color: Qt.alpha(root.textColor, 0.08)
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        radius: 16
                        color: setSideH.hovered ? Qt.alpha(root.textColor, 0.06) : "transparent"
                        scale: setMouse.pressed ? 0.92 : (setSideH.hovered ? 1.04 : 1)

                        Text {
                            anchors.centerIn: parent
                            text: "settings"
                            font.pixelSize: 22
                            font.family: "Material Symbols Rounded"
                            color: setSideH.hovered ? root.color1 : root.textMuted

                            Behavior on color {
                                ColorAnimation {
                                    duration: 180
                                    easing.type: Easing.OutCubic
                                }

                            }

                        }

                        HoverHandler {
                            id: setSideH
                        }

                        MouseArea {
                            id: setMouse

                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                openSettingsProc.running = false;
                                openSettingsProc.running = true;
                                root.hideMenu();
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 140
                                easing.type: Easing.OutBack
                            }

                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 180
                                easing.type: Easing.OutCubic
                            }

                        }

                    }

                    Item {
                        Layout.fillHeight: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        radius: 16
                        color: closeSideH.hovered ? Qt.alpha(Colors.cfg.warning, 0.15) : "transparent"
                        scale: closeMouse.pressed ? 0.92 : (closeSideH.hovered ? 1.04 : 1)

                        Text {
                            anchors.centerIn: parent
                            text: "close"
                            font.pixelSize: 22
                            font.family: "Material Symbols Rounded"
                            color: closeSideH.hovered ? Colors.cfg.warning : root.textMuted

                            Behavior on color {
                                ColorAnimation {
                                    duration: 180
                                    easing.type: Easing.OutCubic
                                }

                            }

                        }

                        HoverHandler {
                            id: closeSideH
                        }

                        MouseArea {
                            id: closeMouse

                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.hideMenu()
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 140
                                easing.type: Easing.OutBack
                            }

                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 180
                                easing.type: Easing.OutCubic
                            }

                        }

                    }

                }

                transform: Translate {
                    x: (1 - sidebarEntrance.progress) * -12
                }

            }

            // MAIN CONTENT TABS VIEWPORT
            Item {
                id: tabsViewport

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                // VIEW 1: DASHBOARD TAB
                DashboardTab {
                    anchors.fill: parent
                    visible: root.isTabVisible("dashboard")
                    opacity: root.getTabOpacity("dashboard")
                    tabActive: root.activeTab === "dashboard" && root.visible

                    transform: Translate {
                        y: root.getTabY("dashboard")
                    }
                }

                // VIEW 2: PRODUCTIVITY TAB (Pomodoro / Timer / Stopwatch)
                TimerTab {
                    anchors.fill: parent
                    visible: root.isTabVisible("timer")
                    opacity: root.getTabOpacity("timer")
                    tabActive: root.activeTab === "timer" && root.visible

                    transform: Translate {
                        y: root.getTabY("timer")
                    }
                }

                // VIEW 3: NOTIFICATIONS TAB
                NotificationsTab {
                    anchors.fill: parent
                    visible: root.isTabVisible("notifications")
                    opacity: root.getTabOpacity("notifications")
                    tabActive: root.activeTab === "notifications" && root.visible

                    transform: Translate {
                        y: root.getTabY("notifications")
                    }
                }

                // VIEW 4: SYSTEM MONITOR TAB
                SystemTab {
                    anchors.fill: parent
                    visible: root.isTabVisible("system")
                    opacity: root.getTabOpacity("system")
                    tabActive: root.activeTab === "system" && root.visible

                    transform: Translate {
                        y: root.getTabY("system")
                    }
                }

            }

        }

        transform: Translate {
            y: panelEntrance.offsetY
        }

    }

}
