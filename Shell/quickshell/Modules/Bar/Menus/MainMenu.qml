import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland
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
    // COMPATIBILITY ALIASES
    property alias color1: root.primary
    property alias color2: root.secondary
    property alias textColor: root.text
    property alias textMuted: root.textSecondary
    property alias foreground: root.on_primary
    property string activeTab: "dashboard" // "dashboard" | "system" | "timer" | "notifications"
    // ─────────────────────────────────────────────────────────────────────────
    // 1. STATE & AUDIO / BRIGHTNESS / POWER / CALENDAR SERVICES
    // ─────────────────────────────────────────────────────────────────────────
    readonly property var player: PlayerService.activePlayer
    readonly property bool isPlaying: player ? (player.playbackState === MprisPlaybackState.Playing) : false
    property string artUrl: player && player.trackArtUrl ? player.trackArtUrl : ""
    property int volumeLevel: AudioService.masterVolume
    property bool volumeMuted: AudioService.masterMuted
    property int micLevel: AudioService.micVolume
    property bool micMuted: AudioService.micMuted
    property int brightnessLevel: BrightnessService.brightness
    // Calendar navigation state
    property var currentDate: new Date()
    property int displayedMonth: currentDate.getMonth()
    property int displayedYear: currentDate.getFullYear()
    property int selectedDay: currentDate.getDate()
    readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    readonly property var weekDayNames: ["S", "M", "T", "W", "T", "F", "S"]
    // Energy mode polling via powerprofilesctl
    property string currentEnergyMode: "balanced"
    property bool nightLightActive: false
    property bool caffeineActive: false
    property bool gameModeActive: false
    property bool taskIncludeDate: true
    property bool taskNotify: false

    signal hideMenu()

    function submitNewTask() {
        var title = taskInput.text.trim();
        if (!title)
            return ;

        tasksPanel.prepareTimes();
        var finalDate = taskIncludeDate ? TaskService.formatDateKey(root.displayedYear, root.displayedMonth, root.selectedDay) : "";
        var finalStart = taskStartTimeInput.internalTime ? taskStartTimeInput.internalTime : "";
        var finalEnd = taskEndTimeInput.internalTime ? taskEndTimeInput.internalTime : "";
        var finalNotify = (finalDate !== "" && finalStart !== "" && taskNotify);
        TaskService.addTask(title, finalDate, finalStart, finalEnd, finalNotify);
        taskInput.text = "";
        taskStartTimeInput.text = "";
        taskStartTimeInput.internalTime = "";
        taskEndTimeInput.text = "";
        taskEndTimeInput.internalTime = "";
        taskNotify = false;
    }

    function getDaysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate();
    }

    function getFirstDayOfWeek(year, month) {
        return new Date(year, month, 1).getDay();
    }

    function changeMonth(delta) {
        var m = displayedMonth + delta;
        var y = displayedYear;
        if (m > 11) {
            m = 0;
            y++;
        } else if (m < 0) {
            m = 11;
            y--;
        }
        displayedMonth = m;
        displayedYear = y;
        selectedDay = 1;
    }

    function formatTime(seconds) {
        if (!seconds || isNaN(seconds) || seconds < 0)
            return "00:00";

        var m = Math.floor(seconds / 60);
        var s = Math.floor(seconds % 60);
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
    }

    function setBrightness(val) {
        BrightnessService.setBrightness(val);
    }

    function cycleEnergyMode() {
        var modes = ["performance", "balanced", "power-saver"];
        var idx = modes.indexOf(root.currentEnergyMode);
        var nextMode = modes[(idx + 1) % modes.length];
        root.currentEnergyMode = nextMode;
        powerSetProc.command = ["powerprofilesctl", "set", nextMode];
        powerSetProc.running = false;
        powerSetProc.running = true;
    }

    function toggleNightLight() {
        root.nightLightActive = !root.nightLightActive;
        if (root.nightLightActive) {
            nightLightProc.command = ["wlsunset", "-T", "4500", "-t", "3500"];
            nightLightProc.running = false;
            nightLightProc.running = true;
        } else {
            nightLightProc.command = ["pkill", "wlsunset"];
            nightLightProc.running = false;
            nightLightProc.running = true;
        }
    }

    function toggleCaffeine() {
        if (!runCaffeineProc.running)
            runCaffeineProc.running = true;

    }

    function toggleGameMode() {
        if (!runGameModeProc.running)
            runGameModeProc.running = true;

    }

    function refreshToggleStates() {
        if (!checkCaffeineProc.running)
            checkCaffeineProc.running = true;

        if (!checkGameModeProc.running)
            checkGameModeProc.running = true;

    }

    implicitWidth: 1040
    implicitHeight: 460
    // === KEYBOARD NAVIGATION ===
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
                if (root.player)
                    root.player.togglePlaying();

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
        if (root.visible) {
            Qt.callLater(function() {
                root.forceActiveFocus();
            });
            if (!brightGetProc.running)
                brightGetProc.running = true;

            if (!powerGetProc.running)
                powerGetProc.running = true;

            root.refreshToggleStates();
        }
    }
    Component.onCompleted: {
        brightGetProc.running = true;
        powerGetProc.running = true;
        root.refreshToggleStates();
    }
    Component.onDestruction: {
        nightLightProc.running = false;
    }

    MenuEntrance {
        id: sidebarEntrance

        active: root.visible
        duration: 280
        startOffsetY: 0
    }

    MenuEntrance {
        id: dashEntrance

        active: root.visible && root.activeTab === "dashboard"
        duration: 320
        startOffsetY: 14
    }

    MenuEntrance {
        id: timerEntrance

        active: root.visible && root.activeTab === "timer"
        duration: 320
        startOffsetY: 14
    }

    MenuEntrance {
        id: notifEntrance

        active: root.visible && root.activeTab === "notifications"
        duration: 320
        startOffsetY: 14
    }

    MenuEntrance {
        id: sysEntrance

        active: root.visible && root.activeTab === "system"
        duration: 320
        startOffsetY: 14
    }

    Binding {
        target: SystemMonitorService
        property: "active"
        value: root.visible && root.activeTab === "system"
    }

    Process {
        id: brightGetProc

        command: ["brightnessctl", "-m"]

        stdout: SplitParser {
            onRead: (data) => {
                if (!data)
                    return ;

                var parts = data.split(",");
                if (parts.length >= 4) {
                    var pct = parseInt(parts[3].replace("%", ""));
                    if (!isNaN(pct))
                        root.brightnessLevel = pct;

                }
            }
        }

    }

    Process {
        id: powerGetProc

        command: ["powerprofilesctl", "get"]

        stdout: SplitParser {
            onRead: (data) => {
                if (data && data.trim())
                    root.currentEnergyMode = data.trim();

            }
        }

    }

    Process {
        id: runCaffeineProc

        command: ["bash", "-c", "bash ~/.config/hypr/scripts/caffeine.sh"]
        running: false
        onExited: {
            running = false;
            checkCaffeineProc.running = true;
        }
    }

    Process {
        id: runGameModeProc

        command: ["bash", "-c", "bash ~/.config/hypr/scripts/gamemode.sh"]
        running: false
        onExited: {
            running = false;
            checkGameModeProc.running = true;
        }
    }

    Process {
        id: brightSetProc

        command: []
    }

    Process {
        id: powerSetProc

        command: []
    }

    Process {
        id: openSettingsProc

        command: ["quickshell", "ipc", "call", "settings", "open"]
    }

    Process {
        id: nightLightProc

        command: []
    }

    Process {
        id: wtypeProc

        command: []
    }

    Process {
        id: checkCaffeineProc

        command: ["pidof", "hypridle"]
        running: true
        onExited: (exitCode) => {
            root.caffeineActive = (exitCode !== 0);
            running = false;
        }
    }

    Process {
        id: checkGameModeProc

        command: ["test", "-f", "/tmp/gamemode_on"]
        running: true
        onExited: (exitCode) => {
            root.gameModeActive = (exitCode === 0);
            running = false;
        }
    }

    Timer {
        id: toggleCheckTimer

        interval: 350
        repeat: false
        onTriggered: {
            checkCaffeineProc.running = false;
            checkCaffeineProc.running = true;
            checkGameModeProc.running = false;
            checkGameModeProc.running = true;
        }
    }

    Timer {
        interval: 4000
        running: root.visible
        repeat: true
        onTriggered: {
            if (!brightGetProc.running)
                brightGetProc.running = true;

            if (!powerGetProc.running)
                powerGetProc.running = true;

            root.refreshToggleStates();
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 2. MAIN CONTAINER: SIDEBAR + CONTENT TABS
    // ─────────────────────────────────────────────────────────────────────────
    Rectangle {
        //clip: true

        anchors.fill: parent
        color: "transparent"
        radius: 30

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 14

            // LEFT SIDEBAR (TAB SWITCHER)
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

            // MAIN CONTENT TABS
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // VIEW 1: DASHBOARD TAB
                RowLayout {
                    // 3. RIGHT COLUMN
                    // === RIGHT AREA ===

                    anchors.fill: parent
                    spacing: 10
                    visible: root.activeTab === "dashboard"
                    opacity: dashEntrance.opacity

                    // LEFT: PLAYER MENU
                    Rectangle {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 260
                        radius: 18
                        color: root.surface

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 8

                            // Header
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 24
                                spacing: 6

                                Text {
                                    id: playIcon

                                    text: PlayerService.getAppIcon(root.player ? root.player.identity : "")
                                    anchors.left: parent.left
                                    font.pixelSize: 30
                                    font.family: "GeistMono Nerd Font Propo Propo"
                                    color: root.color1
                                }

                                Text {
                                    text: root.player ? (root.player.identity || "Media") : "No Player"
                                    font.pixelSize: 12
                                    font.family: "GeistMono Nerd Font Propo"
                                    font.bold: true
                                    color: root.textMuted
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    visible: PlayerService.playerCount > 1
                                    anchors.right: parent.right
                                    implicitWidth: 22
                                    implicitHeight: 22
                                    radius: 20
                                    color: root.surfaceContainer

                                    Text {
                                        anchors.centerIn: parent
                                        text: ""
                                        font.pixelSize: 11
                                        color: root.color1
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: PlayerService.cycleNextPlayer()
                                    }

                                }

                            }

                            Item {
                                id: playerContainer

                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 230
                                Layout.preferredHeight: 230

                                Shape {
                                    id: circularSeekBar

                                    property real playerSeek: Math.max(0, Math.min(1, root.player.position / root.player.length))

                                    anchors.fill: parent
                                    layer.enabled: true
                                    layer.samples: 4

                                    ShapePath {
                                        strokeColor: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.12)
                                        strokeWidth: circularSeekBarH.hovered ? 8 : 2
                                        fillColor: "transparent"
                                        capStyle: ShapePath.RoundCap

                                        PathAngleArc {
                                            centerX: circularSeekBar.width / 2
                                            centerY: circularSeekBar.height / 2
                                            radiusX: (circularSeekBar.width / 2) - 11
                                            radiusY: radiusX
                                            startAngle: 0
                                            sweepAngle: 360
                                        }

                                        Behavior on strokeWidth {
                                            NumberAnimation {
                                                duration: 250
                                                easing.type: Easing.OutQuad
                                            }

                                        }

                                    }

                                    ShapePath {
                                        strokeColor: root.color1
                                        strokeWidth: circularSeekBarH.hovered ? 8 : 2
                                        fillColor: "transparent"
                                        capStyle: ShapePath.RoundCap

                                        PathAngleArc {
                                            centerX: circularSeekBar.width / 2
                                            centerY: circularSeekBar.height / 2
                                            radiusX: (circularSeekBar.width / 2) - 11
                                            radiusY: radiusX
                                            startAngle: -90
                                            sweepAngle: circularSeekBar.playerSeek * 360
                                        }

                                        Behavior on strokeWidth {
                                            NumberAnimation {
                                                duration: 250
                                                easing.type: Easing.OutQuad
                                            }

                                        }

                                    }

                                    HoverHandler {
                                        id: circularSeekBarH
                                    }

                                    MouseArea {
                                        function seekFromMouse(mouseX, mouseY) {
                                            var cx = width / 2;
                                            var cy = height / 2;
                                            var dx = mouseX - cx;
                                            var dy = mouseY - cy;
                                            var distance = Math.sqrt(dx * dx + dy * dy);
                                            if (distance < 80)
                                                return ;

                                            var angle = Math.atan2(dy, dx);
                                            angle += Math.PI / 2;
                                            if (angle < 0)
                                                angle += 2 * Math.PI;

                                            var ratio = angle / (2 * Math.PI);
                                            var newPosition = ratio * root.player.length;
                                            root.player.position = newPosition;
                                        }

                                        anchors.fill: parent
                                        onClicked: seekFromMouse(mouse.x, mouse.y)
                                        onPositionChanged: {
                                            if (pressed)
                                                seekFromMouse(mouse.x, mouse.y);

                                        }
                                    }

                                    Behavior on playerSeek {
                                        NumberAnimation {
                                            duration: 250
                                            easing.type: Easing.OutQuad
                                        }

                                    }

                                }

                                Item {
                                    id: vinylDisc

                                    width: 200
                                    height: 200
                                    anchors.centerIn: parent

                                    Item {
                                        anchors.fill: parent

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: width / 2
                                            color: "#141416"
                                            border.color: Qt.alpha(root.color1, 0.3)

                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: parent.width - 20
                                                height: parent.height - 20
                                                radius: width / 2
                                                color: "transparent"
                                                border.color: Qt.alpha("#ffffff", 0.08)
                                            }

                                        }

                                        Item {
                                            anchors.centerIn: parent
                                            width: 140
                                            height: 140

                                            Image {
                                                id: albumImg

                                                anchors.fill: parent
                                                source: root.artUrl
                                                fillMode: Image.PreserveAspectCrop
                                                visible: false
                                            }

                                            Rectangle {
                                                id: albumMask

                                                anchors.fill: parent
                                                radius: width / 2
                                                visible: false
                                            }

                                            OpacityMask {
                                                anchors.fill: parent
                                                source: albumImg
                                                maskSource: albumMask
                                                visible: root.artUrl !== ""
                                            }

                                            Rectangle {
                                                anchors.fill: parent
                                                radius: width / 2
                                                color: root.surfaceContainer
                                                visible: root.artUrl === ""

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "󰎆"
                                                    color: root.color1
                                                    font.pixelSize: 30
                                                    font.family: "GeistMono Nerd Font Propo Propo"
                                                }

                                            }

                                        }

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 18
                                            height: 18
                                            radius: 9
                                            color: "#141416"
                                            border.color: "#ffffff"
                                            border.width: 2
                                        }

                                        RotationAnimation on rotation {
                                            from: 0
                                            to: 360
                                            duration: 8000
                                            loops: Animation.Infinite
                                            running: root.isPlaying
                                        }

                                    }

                                }
                                // Stylus / Tone Arm Indicator

                                Rectangle {
                                    id: toneArm

                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.topMargin: 14
                                    width: 4
                                    height: 82
                                    radius: 2
                                    color: Qt.alpha(root.textColor, 0.5)
                                    transformOrigin: Item.Top
                                    rotation: root.isPlaying ? 24 : 0

                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 8
                                        height: 10
                                        radius: 2
                                        color: root.color1
                                    }

                                    Behavior on rotation {
                                        NumberAnimation {
                                            duration: 400
                                            easing.type: Easing.OutBack
                                        }

                                    }

                                }

                            }
                            // Track Info

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: root.player && root.player.trackTitle ? root.player.trackTitle : "No music playing"
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: root.textMuted
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: {
                                        if (!root.player)
                                            return "~";

                                        if (Array.isArray(root.player.trackArtists))
                                            return root.player.trackArtists.join(", ");

                                        if (root.player.trackArtists)
                                            return String(root.player.trackArtists);

                                        if (root.player.trackArtist)
                                            return String(root.player.trackArtist);

                                        return "~";
                                    }
                                    font.pixelSize: 11
                                    color: root.textMuted
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                }

                            }

                            // Media Controls
                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 14

                                Rectangle {
                                    implicitWidth: 34
                                    implicitHeight: 34
                                    radius: 17
                                    color: prevH.hovered ? root.surfaceContainer : "transparent"
                                    scale: prevH.hovered ? 1.1 : 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰒮"
                                        font.pixelSize: 20
                                        color: root.color1
                                    }

                                    HoverHandler {
                                        id: prevH
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.player && root.player.canGoPrevious)
                                                root.player.previous();

                                        }
                                    }

                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 120
                                        }

                                    }

                                }

                                Rectangle {
                                    implicitWidth: 50
                                    implicitHeight: 50
                                    radius: 50
                                    color: root.color1
                                    scale: playH.hovered ? 1.1 : 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.isPlaying ? "" : ""
                                        font.pixelSize: 25
                                        color: root.foreground
                                        scale: playH.hovered ? 1.1 : 1

                                        Behavior on scale {
                                            NumberAnimation {
                                                duration: 120
                                            }

                                        }

                                    }

                                    HoverHandler {
                                        id: playH
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.player && root.player.canControl)
                                                root.player.togglePlaying();

                                        }
                                    }

                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 120
                                        }

                                    }

                                }

                                Rectangle {
                                    implicitWidth: 34
                                    implicitHeight: 34
                                    radius: 17
                                    color: nextH.hovered ? root.surfaceContainer : "transparent"
                                    scale: nextH.hovered ? 1.1 : 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰒭"
                                        font.pixelSize: 20
                                        color: root.color1
                                    }

                                    HoverHandler {
                                        id: nextH
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.player && root.player.canGoNext)
                                                root.player.next();

                                        }
                                    }

                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 120
                                        }

                                    }

                                }

                            }

                        }

                    }

                    // 2. CENTER COLUMN: CALENDAR + Toggles
                    ColumnLayout {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 0
                        spacing: 10

                        Rectangle {
                            id: calendarCard

                            property string calendarViewMode: "monthly"

                            // === WEEKLY VIEW HELPERS ===
                            function weekStartDate() {
                                var d = new Date(root.displayedYear, root.displayedMonth, root.selectedDay);
                                var day = d.getDay();
                                d.setDate(d.getDate() - day);
                                return d;
                            }

                            function getWeekDayDate(colIdx) {
                                var s = weekStartDate();
                                return new Date(s.getFullYear(), s.getMonth(), s.getDate() + colIdx);
                            }

                            function getTasksForWeekDay(colIdx) {
                                var d = getWeekDayDate(colIdx);
                                return TaskService.getTasksForDate(d.getFullYear(), d.getMonth(), d.getDate());
                            }

                            function taskStartHour(task) {
                                if (!task.startTime || task.startTime === "")
                                    return -1;

                                var parts = task.startTime.split(":");
                                return parseInt(parts[0]);
                            }

                            function taskStartMinute(task) {
                                if (!task.startTime)
                                    return 0;

                                var parts = task.startTime.split(":");
                                return parseInt(parts[1]) || 0;
                            }

                            function taskEndHour(task) {
                                if (!task.endTime || task.endTime === "")
                                    return -1;

                                var parts = task.endTime.split(":");
                                return parseInt(parts[0]);
                            }

                            function taskEndMinute(task) {
                                if (!task.endTime || task.endTime === "")
                                    return 0;

                                var parts = task.endTime.split(":");
                                return parseInt(parts[1]) || 0;
                            }

                            function taskHeightPx(task) {
                                var startH = taskStartHour(task);
                                if (startH < 0)
                                    return 0;

                                var startM = taskStartMinute(task);
                                var endH = taskEndHour(task);
                                if (endH < 0)
                                    return 36;

                                var endM = taskEndMinute(task);
                                var durationMin = (endH * 60 + endM) - (startH * 60 + startM);
                                if (durationMin <= 0)
                                    return 36;

                                return Math.max(22, durationMin * 36 / 60);
                            }

                            function weekRangeLabel() {
                                var s = weekStartDate();
                                var e = getWeekDayDate(6);
                                var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
                                return months[s.getMonth()] + " " + s.getDate() + " – " + months[e.getMonth()] + " " + e.getDate() + ", " + e.getFullYear();
                            }

                            Layout.fillWidth: true
                            Layout.preferredHeight: 315
                            radius: 18
                            color: root.surface
                            clip: true

                            ColumnLayout {
                                id: calendarArea

                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 6

                                // === CALENDAR HEADER ===
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Text {
                                        text: calendarCard.calendarViewMode === "monthly" ? (root.monthNames[root.displayedMonth] + " " + root.displayedYear) : calendarCard.weekRangeLabel()
                                        font.pixelSize: 11
                                        font.family: "GeistMono Nerd Font Propo"
                                        font.bold: true
                                        color: root.text
                                        Layout.fillWidth: true
                                    }

                                    // View mode toggle
                                    Rectangle {
                                        implicitWidth: 22
                                        implicitHeight: 22
                                        radius: 11
                                        color: viewModeH.hovered ? Qt.alpha(root.primary, 0.18) : Qt.alpha(root.primary, 0.1)
                                        border.color: Qt.alpha(root.primary, 0.3)
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: calendarCard.calendarViewMode === "monthly" ? "calendar_today" : "event_list"
                                            font.pixelSize: 12
                                            font.family: "Material Symbols Rounded"
                                            color: root.primary
                                        }

                                        HoverHandler {
                                            id: viewModeH
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: calendarCard.calendarViewMode = (calendarCard.calendarViewMode === "monthly" ? "weekly" : "monthly")
                                        }

                                    }

                                    // Prev button
                                    Rectangle {
                                        implicitWidth: 22
                                        implicitHeight: 22
                                        radius: 11
                                        color: prevMH.hovered ? root.surfaceContainer : Qt.alpha(root.surfaceContainer, 0.6)
                                        border.color: Qt.alpha(root.text, 0.12)
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: "arrow_back_ios_new"
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 10
                                            color: root.text
                                        }

                                        HoverHandler {
                                            id: prevMH
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (calendarCard.calendarViewMode === "monthly") {
                                                    root.changeMonth(-1);
                                                } else {
                                                    root.selectedDay = calendarCard.getWeekDayDate(0).getDate() - 7;
                                                    var prev = new Date(calendarCard.weekStartDate());
                                                    prev.setDate(prev.getDate() - 7);
                                                    root.displayedMonth = prev.getMonth();
                                                    root.displayedYear = prev.getFullYear();
                                                    root.selectedDay = prev.getDate();
                                                }
                                            }
                                        }

                                    }

                                    // Next button
                                    Rectangle {
                                        implicitWidth: 22
                                        implicitHeight: 22
                                        radius: 11
                                        color: nextMH.hovered ? root.surfaceContainer : Qt.alpha(root.surfaceContainer, 0.6)
                                        border.color: Qt.alpha(root.text, 0.12)
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: "arrow_forward_ios"
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 10
                                            color: root.text
                                        }

                                        HoverHandler {
                                            id: nextMH
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (calendarCard.calendarViewMode === "monthly") {
                                                    root.changeMonth(1);
                                                } else {
                                                    var next = new Date(calendarCard.weekStartDate());
                                                    next.setDate(next.getDate() + 7);
                                                    root.displayedMonth = next.getMonth();
                                                    root.displayedYear = next.getFullYear();
                                                    root.selectedDay = next.getDate();
                                                }
                                            }
                                        }

                                    }

                                }

                                // === MONTHLY VIEW ===
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 4
                                    visible: calendarCard.calendarViewMode === "monthly"

                                    GridLayout {
                                        Layout.fillWidth: true
                                        columns: 7
                                        columnSpacing: 0
                                        rowSpacing: 0

                                        Repeater {
                                            model: root.weekDayNames

                                            delegate: Item {
                                                required property var modelData

                                                Layout.fillWidth: true
                                                implicitHeight: 20

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                    color: root.color1
                                                }

                                            }

                                        }

                                    }

                                    GridLayout {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        columns: 7
                                        rowSpacing: 2
                                        columnSpacing: 0

                                        Repeater {
                                            model: 42

                                            delegate: Item {
                                                readonly property int offset: root.getFirstDayOfWeek(root.displayedYear, root.displayedMonth)
                                                readonly property int totalDays: root.getDaysInMonth(root.displayedYear, root.displayedMonth)
                                                readonly property int dayNum: index - offset + 1
                                                readonly property bool isValid: dayNum >= 1 && dayNum <= totalDays
                                                readonly property bool isToday: isValid && dayNum === root.currentDate.getDate() && root.displayedMonth === root.currentDate.getMonth() && root.displayedYear === root.currentDate.getFullYear()
                                                readonly property bool isSelected: isValid && dayNum === root.selectedDay
                                                readonly property bool hasTask: isValid && TaskService.hasPendingTasksOnDate(root.displayedYear, root.displayedMonth, dayNum)

                                                Layout.fillWidth: true
                                                Layout.fillHeight: true

                                                Rectangle {
                                                    anchors.centerIn: parent
                                                    width: 22
                                                    height: 22
                                                    radius: 11
                                                    visible: isValid
                                                    color: isSelected ? root.color1 : (isToday ? Qt.alpha(root.color1, 0.25) : (dayH.hovered ? root.surfaceContainer : "transparent"))

                                                    Text {
                                                        anchors.centerIn: parent
                                                        anchors.verticalCenterOffset: hasTask ? -2 : 0
                                                        text: isValid ? dayNum : ""
                                                        font.pixelSize: 9
                                                        font.bold: isToday || isSelected
                                                        color: isSelected ? root.foreground : (isToday ? root.color1 : root.textMuted)
                                                    }

                                                    Rectangle {
                                                        visible: hasTask
                                                        anchors.bottom: parent.bottom
                                                        anchors.bottomMargin: 2
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        width: 3
                                                        height: 3
                                                        radius: 1.5
                                                        color: isSelected ? root.foreground : root.color1
                                                    }

                                                    HoverHandler {
                                                        id: dayH
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            if (isValid)
                                                                root.selectedDay = dayNum;

                                                        }
                                                    }

                                                }

                                            }

                                        }

                                    }

                                }

                                // === WEEKLY VIEW ===
                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    visible: calendarCard.calendarViewMode === "weekly"
                                    clip: true

                                    // Day header row
                                    Row {
                                        id: weekHeaderRow

                                        anchors.top: parent.top
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        height: 26

                                        Item {
                                            width: 28
                                            height: parent.height
                                        }

                                        Repeater {
                                            model: 7

                                            delegate: Item {
                                                required property int index
                                                readonly property var dayDate: calendarCard.getWeekDayDate(index)
                                                readonly property bool isToday: {
                                                    var n = root.currentDate;
                                                    return dayDate.getFullYear() === n.getFullYear() && dayDate.getMonth() === n.getMonth() && dayDate.getDate() === n.getDate();
                                                }
                                                readonly property bool isSelected: dayDate.getFullYear() === root.displayedYear && dayDate.getMonth() === root.displayedMonth && dayDate.getDate() === root.selectedDay

                                                width: (weekHeaderRow.width - 28) / 7
                                                height: weekHeaderRow.height

                                                Rectangle {
                                                    anchors.centerIn: parent
                                                    width: parent.width - 4
                                                    height: 22
                                                    radius: 8
                                                    color: isSelected ? root.primary : (isToday ? Qt.alpha(root.primary, 0.18) : (wkDayH.hovered ? Qt.alpha(root.primary, 0.1) : "transparent"))

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: ["S", "M", "T", "W", "T", "F", "S"][dayDate.getDay()] + " " + dayDate.getDate()
                                                        font.pixelSize: 9
                                                        font.bold: isToday || isSelected
                                                        color: isSelected ? root.foreground : (isToday ? root.primary : root.textMuted)
                                                    }

                                                    HoverHandler {
                                                        id: wkDayH
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            root.displayedMonth = dayDate.getMonth();
                                                            root.displayedYear = dayDate.getFullYear();
                                                            root.selectedDay = dayDate.getDate();
                                                        }
                                                    }

                                                }

                                            }

                                        }

                                    }

                                    // Scrollable hour grid
                                    ScrollView {
                                        anchors.top: weekHeaderRow.bottom
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        clip: true
                                        ScrollBar.vertical.policy: ScrollBar.AsNeeded
                                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                                        Item {
                                            width: parent.width
                                            height: 24 * 36

                                            // Horizontal column separators
                                            Repeater {
                                                model: 8

                                                delegate: Rectangle {
                                                    required property int index

                                                    x: 28 + index * ((parent.width - 28) / 7)
                                                    y: 0
                                                    width: 1
                                                    height: parent.height
                                                    color: Qt.alpha(root.textMuted, 0.1)
                                                    visible: index > 0
                                                }

                                            }

                                            // Hour rows
                                            Repeater {
                                                model: 24

                                                delegate: Item {
                                                    required property int index

                                                    x: 0
                                                    y: index * 36
                                                    width: parent.width
                                                    height: 36

                                                    Rectangle {
                                                        anchors.bottom: parent.bottom
                                                        width: parent.width
                                                        height: 1
                                                        color: Qt.alpha(root.textMuted, 0.07)
                                                    }

                                                    Text {
                                                        anchors.left: parent.left
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        width: 26
                                                        text: {
                                                            var h = index % 12 || 12;
                                                            return h + (index < 12 ? "a" : "p");
                                                        }
                                                        font.pixelSize: 8
                                                        color: Qt.alpha(root.textMuted, 0.55)
                                                        horizontalAlignment: Text.AlignRight
                                                    }

                                                }

                                            }

                                            // Task blocks per column
                                            Repeater {
                                                model: 7

                                                delegate: Item {
                                                    required property int index
                                                    readonly property int colIndex: index
                                                    readonly property real colW: (parent.width - 28) / 7
                                                    readonly property var colTasks: calendarCard.getTasksForWeekDay(colIndex)

                                                    x: 28 + colIndex * colW
                                                    y: 0
                                                    width: colW
                                                    height: parent.height

                                                    Repeater {
                                                        model: colTasks

                                                        delegate: Rectangle {
                                                            required property var modelData
                                                            readonly property int startH: calendarCard.taskStartHour(modelData)
                                                            readonly property int startM: calendarCard.taskStartMinute(modelData)
                                                            readonly property bool timed: startH >= 0

                                                            y: timed ? (startH * 36 + startM * 36 / 60) : 0
                                                            x: 2
                                                            width: parent.width - 4
                                                            height: timed ? calendarCard.taskHeightPx(modelData) : 0
                                                            visible: timed
                                                            radius: 5
                                                            color: modelData.done ? Qt.alpha(root.textMuted, 0.15) : Qt.alpha(root.primary, 0.22)
                                                            border.color: modelData.done ? Qt.alpha(root.textMuted, 0.2) : Qt.alpha(root.primary, 0.5)
                                                            border.width: 1
                                                            clip: true

                                                            Text {
                                                                anchors.fill: parent
                                                                anchors.margins: 3
                                                                text: modelData.text
                                                                font.pixelSize: 8
                                                                font.bold: !modelData.done
                                                                color: modelData.done ? root.textMuted : root.text
                                                                wrapMode: Text.WordWrap
                                                                elide: Text.ElideRight
                                                            }

                                                        }

                                                    }

                                                }

                                            }

                                        }

                                    }

                                }

                            }

                        }

                        // Bottom Box: 4 Quick Toggles
                        GridLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            columns: 4
                            columnSpacing: 8
                            rowSpacing: 8

                            // 1. Wi-Fi
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 14
                                color: WifiService.wifiEnabled ? Qt.alpha(root.color1, 0.2) : root.surface
                                border.color: WifiService.wifiEnabled ? root.color1 : Qt.alpha(root.textColor, 0.08)

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 2

                                    Text {
                                        text: WifiService.wifiEnabled ? "signal_wifi_4_bar" : "signal_wifi_off"
                                        font.pixelSize: 20
                                        font.family: "Material Symbols Rounded"
                                        color: WifiService.wifiEnabled ? root.color1 : root.textMuted
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: WifiService.toggleWifi()
                                }

                            }

                            // 2. Bluetooth
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 14
                                color: BluetoothService.bluetoothEnabled ? Qt.alpha(root.color1, 0.2) : root.surface
                                border.color: BluetoothService.bluetoothEnabled ? root.color1 : Qt.alpha(root.textColor, 0.08)

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 2

                                    Text {
                                        text: BluetoothService.bluetoothEnabled ? "bluetooth" : "bluetooth_disabled"
                                        font.pixelSize: 20
                                        font.family: "Material Symbols Rounded"
                                        color: BluetoothService.bluetoothEnabled ? root.color1 : root.textMuted
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: BluetoothService.togglePower()
                                }

                            }

                            // 3. Caffeine Mode
                            Rectangle {
                                id: caffeine

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 14
                                color: root.caffeineActive ? Qt.alpha(root.color1, 0.2) : root.surface
                                border.color: root.caffeineActive ? root.color1 : Qt.alpha(root.textColor, 0.08)

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 2

                                    Text {
                                        text: "local_cafe"
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 20
                                        color: root.caffeineActive ? root.color1 : root.textMuted
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.toggleCaffeine()
                                }

                            }

                            // 4. Night Light
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 14
                                color: root.nightLightActive ? Qt.alpha(root.color1, 0.2) : root.surface
                                border.color: root.nightLightActive ? root.color1 : Qt.alpha(root.textColor, 0.08)

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 2

                                    Text {
                                        text: root.nightLightActive ? "bedtime" : "bedtime_off"
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 20
                                        color: root.nightLightActive ? root.color1 : root.textMuted
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.toggleNightLight()
                                }

                            }

                            // 5. Game Mode
                            Rectangle {
                                id: generic1

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 14
                                color: root.gameModeActive ? Qt.alpha(root.color1, 0.2) : root.surface
                                border.color: root.gameModeActive ? root.color1 : Qt.alpha(root.textColor, 0.08)

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 2

                                    Text {
                                        text: "gamepad"
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 20
                                        color: root.gameModeActive ? root.color1 : root.textMuted
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.toggleGameMode()
                                }

                            }

                            // 6. Microphone
                            Rectangle {
                                id: generic2

                                readonly property bool micActive: !AudioService.micMuted

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 14
                                color: micActive ? Qt.alpha(root.color1, 0.2) : root.surface
                                border.color: micActive ? root.color1 : Qt.alpha(root.textColor, 0.08)

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 2

                                    Text {
                                        text: generic2.micActive ? "mic" : "mic_off"
                                        font.pixelSize: 20
                                        font.family: "Material Symbols Rounded"
                                        color: generic2.micActive ? root.color1 : root.textMuted
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: AudioService.toggleMicMute()
                                }

                            }

                            // 7. Do Not Disturb
                            Rectangle {
                                id: generic3

                                readonly property bool dndActive: Config.cfg ? !Config.cfg.alertsPopups : false

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 14
                                color: dndActive ? Qt.alpha(root.color1, 0.2) : root.surface
                                border.color: dndActive ? root.color1 : Qt.alpha(root.textColor, 0.08)

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 2

                                    Text {
                                        text: generic3.dndActive ? "do_not_disturb_on" : "do_not_disturb_off"
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 20
                                        color: generic3.dndActive ? root.color1 : root.textMuted
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Config.cfg.alertsPopups = !Config.cfg.alertsPopups;
                                        Config.save();
                                    }
                                }

                            }

                            // 8. Screen Recording
                            Rectangle {
                                id: generic4

                                readonly property bool isRecording: RecorderService.isRecording

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 14
                                color: isRecording ? Qt.alpha(Colors.cfg.error, 0.2) : root.surface
                                border.color: isRecording ? Colors.cfg.error : Qt.alpha(root.textColor, 0.08)

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 2

                                    Text {
                                        text: generic4.isRecording ? "stop" : "screen_record"
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 20
                                        color: generic4.isRecording ? Colors.cfg.error : root.textMuted
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        RecorderService.toggleRecording();
                                    }
                                }

                            }

                        }

                    }

                 RowLayout {
    Layout.fillHeight: true
    Layout.fillWidth: true
    spacing: 10 // Reduzido de 12

    Rectangle {
        id: tasksPanel

        property string taskStartPeriod: "AM"
        property string taskEndPeriod: "AM"

        function normalize12Hour(value) {
            var clean = value.trim();
            if (clean.length === 0)
                return "";

            var parts = clean.split(":");
            var hour = parseInt(parts[0]);
            var minute = parts.length > 1 ? parseInt(parts[1]) : 0;
            if (isNaN(hour))
                return "";

            if (isNaN(minute))
                minute = 0;

            hour = Math.max(1, Math.min(12, hour));
            minute = Math.max(0, Math.min(59, minute));
            return (hour < 10 ? "0" : "") + hour + ":" + (minute < 10 ? "0" : "") + minute;
        }

        function convertTo24Hour(value, period) {
            var normalized = normalize12Hour(value);
            if (normalized.length === 0)
                return "";

            var parts = normalized.split(":");
            var hour = parseInt(parts[0]);
            var minute = parseInt(parts[1]);
            if (period === "AM" && hour === 12)
                hour = 0;
            else if (period === "PM" && hour !== 12)
                hour += 12;
            return (hour < 10 ? "0" : "") + hour + ":" + (minute < 10 ? "0" : "") + minute;
        }

        function convertFrom24Hour(value) {
            if (!value || value.length < 4)
                return {
                "time": "",
                "period": "AM"
            };

            var parts = value.split(":");
            var hour = parseInt(parts[0]);
            var minute = parseInt(parts[1]);
            if (isNaN(hour) || isNaN(minute))
                return {
                "time": "",
                "period": "AM"
            };

            var period = hour >= 12 ? "PM" : "AM";
            var displayHour = hour % 12;
            if (displayHour === 0)
                displayHour = 12;

            return {
                "time": (displayHour < 10 ? "0" : "") + displayHour + ":" + (minute < 10 ? "0" : "") + minute,
                "period": period
            };
        }

        function prepareTimes() {
            taskStartTimeInput.text = normalize12Hour(taskStartTimeInput.text);
            taskEndTimeInput.text = normalize12Hour(taskEndTimeInput.text);
            taskStartTimeInput.internalTime = convertTo24Hour(taskStartTimeInput.text, taskStartPeriod);
            taskEndTimeInput.internalTime = convertTo24Hour(taskEndTimeInput.text, taskEndPeriod);
        }

        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 16 // Reduzido de 20
        color: root.surfaceContainer

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12 // Reduzido de 14
            spacing: 8 // Reduzido de 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Tasks (" + root.selectedDay + " " + root.monthNames[root.displayedMonth].substring(0, 3) + ")"
                        font.family: "Google Sans"
                        font.pixelSize: 13 // Reduzido de 14
                        font.weight: Font.DemiBold
                        color: root.textColor
                    }

                    Text {
                        text: "Tasks for the selected day"
                        font.family: "Google Sans"
                        font.pixelSize: 9
                        color: root.textMuted
                    }

                }

                Rectangle {
                    implicitWidth: 26 // Reduzido de 32
                    implicitHeight: 22 // Reduzido de 28
                    radius: 11 // Reduzido de 14
                    color: Qt.alpha(root.color1, 0.14)

                    Text {
                        anchors.centerIn: parent
                        text: TaskService.getTasksForDate(root.displayedYear, root.displayedMonth, root.selectedDay).length
                        font.family: "Google Sans"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: root.color1
                    }

                }

            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: root.taskIncludeDate ? 98 : 52 // Reduzido de 128 : 68
                radius: 14 // Reduzido de 20
                color: root.surface
                border.width: taskInput.activeFocus || taskStartTimeInput.activeFocus || taskEndTimeInput.activeFocus ? 2 : 1
                border.color: taskInput.activeFocus || taskStartTimeInput.activeFocus || taskEndTimeInput.activeFocus ? root.color1 : Qt.alpha(root.textColor, 0.08)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10 // Reduzido de 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30 // Reduzido de 35
                            radius: 10 // Reduzido de 14
                            color: Qt.alpha(root.textColor, 0.04)
                            border.width: taskInput.activeFocus ? 2 : 1
                            border.color: taskInput.activeFocus ? root.color1 : Qt.alpha(root.textColor, 0.08)

                            TextInput {
                                id: taskInput

                                anchors.fill: parent
                                leftPadding: 12
                                rightPadding: 12
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: "Google Sans"
                                font.pixelSize: 11 // Reduzido de 12
                                color: root.textColor
                                clip: true
                                selectByMouse: true
                                onAccepted: root.submitNewTask()

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "New task"
                                    font.family: "Google Sans"
                                    font.pixelSize: 11 // Reduzido de 12
                                    color: root.textMuted
                                    visible: !taskInput.text && !taskInput.activeFocus
                                }

                            }

                        }

                        Rectangle {
                            Layout.minimumWidth: 20
                            Layout.maximumWidth: 40
                            Layout.preferredWidth: 30 // Reduzido de 38
                            Layout.preferredHeight: 30 // Reduzido de 38
                            radius: 10 // Reduzido de 14
                            color: root.taskIncludeDate ? Qt.alpha(root.color1, 0.14) : Qt.alpha(root.textColor, 0.04)
                            border.width: 1
                            border.color: root.taskIncludeDate ? Qt.alpha(root.color1, 0.55) : Qt.alpha(root.textColor, 0.08)
                            ToolTip.visible: dateHover.hovered
                            ToolTip.text: root.taskIncludeDate ? root.selectedDay + " " + root.monthNames[root.displayedMonth].substring(0, 3) : "No date"

                            Text {
                                anchors.centerIn: parent
                                text: "󰸗"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 16 // Reduzido de 17
                                color: root.taskIncludeDate ? root.color1 : root.textMuted
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.taskIncludeDate = !root.taskIncludeDate;
                                }
                            }

                            HoverHandler {
                                id: dateHover
                            }

                        }

                        Rectangle {
                            Layout.preferredWidth: 30 // Reduzido de 38
                            Layout.preferredHeight: 30 // Reduzido de 38
                            radius: 15 // Reduzido de 21
                            color: root.color1

                            Text {
                                anchors.centerIn: parent
                                text: "󰐕"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 18 // Reduzido de 20
                                color: root.foreground
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.submitNewTask()
                            }

                        }

                    }

                    RowLayout {
                        id: taskOptionsRow

                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: 6
                        visible: root.taskIncludeDate
                        opacity: root.taskIncludeDate ? 1 : 0

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 80
                            Layout.preferredWidth: 86
                            Layout.maximumWidth: 120
                            Layout.preferredHeight: 32 // Reduzido de 42
                            radius: 10 // Reduzido de 14
                            color: taskStartTimeInput.activeFocus ? Qt.alpha(root.color1, 0.08) : Qt.alpha(root.textColor, 0.04)
                            border.width: taskStartTimeInput.activeFocus ? 2 : 1
                            border.color: taskStartTimeInput.activeFocus ? root.color1 : Qt.alpha(root.textColor, 0.08)
                            clip: true

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 4
                                spacing: 2

                                TextInput {
                                    id: taskStartTimeInput

                                    property string internalTime: ""

                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 26
                                    Layout.preferredHeight: 28
                                    verticalAlignment: TextInput.AlignVCenter
                                    horizontalAlignment: TextInput.AlignHCenter
                                    font.family: "Google Sans"
                                    font.pixelSize: 10 // Reduzido de 11
                                    font.weight: Font.Medium
                                    color: root.textColor
                                    clip: true
                                    selectByMouse: true
                                    maximumLength: 5
                                    inputMethodHints: Qt.ImhTime
                                    onEditingFinished: {
                                        text = tasksPanel.normalize12Hour(text);
                                        internalTime = tasksPanel.convertTo24Hour(text, tasksPanel.taskStartPeriod);
                                    }
                                    onAccepted: root.submitNewTask()

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignHCenter
                                        text: "Start"
                                        font.family: "Google Sans"
                                        font.pixelSize: 9
                                        color: root.textMuted
                                        visible: !taskStartTimeInput.text && !taskStartTimeInput.activeFocus
                                    }

                                    validator: RegularExpressionValidator {
                                        regularExpression: /^$|^([1-9]|1[0-2])(:([0-5]?[0-9])?)?$/
                                    }

                                }

                                Rectangle {
                                    Layout.preferredWidth: 32 // Reduzido de 36
                                    Layout.minimumWidth: 32
                                    Layout.maximumWidth: 32
                                    Layout.preferredHeight: 24 // Reduzido de 28
                                    radius: 8 // Reduzido de 10
                                    color: Qt.alpha(root.color1, 0.14)

                                    Text {
                                        anchors.centerIn: parent
                                        text: tasksPanel.taskStartPeriod
                                        font.family: "Google Sans"
                                        font.pixelSize: 8
                                        font.weight: Font.DemiBold
                                        color: root.color1
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            tasksPanel.taskStartPeriod = tasksPanel.taskStartPeriod === "AM" ? "PM" : "AM";
                                            taskStartTimeInput.internalTime = tasksPanel.convertTo24Hour(taskStartTimeInput.text, tasksPanel.taskStartPeriod);
                                        }
                                    }

                                }

                            }

                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 80
                            Layout.preferredWidth: 86
                            Layout.maximumWidth: 120
                            Layout.preferredHeight: 32 // Reduzido de 42
                            radius: 10 // Reduzido de 14
                            color: taskEndTimeInput.activeFocus ? Qt.alpha(root.color1, 0.08) : Qt.alpha(root.textColor, 0.04)
                            border.width: taskEndTimeInput.activeFocus ? 2 : 1
                            border.color: taskEndTimeInput.activeFocus ? root.color1 : Qt.alpha(root.textColor, 0.08)
                            clip: true

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 4
                                spacing: 2

                                TextInput {
                                    id: taskEndTimeInput

                                    property string internalTime: ""

                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 26
                                    Layout.preferredHeight: 28
                                    verticalAlignment: TextInput.AlignVCenter
                                    horizontalAlignment: TextInput.AlignHCenter
                                    font.family: "Google Sans"
                                    font.pixelSize: 10 // Reduzido de 11
                                    font.weight: Font.Medium
                                    color: root.textColor
                                    clip: true
                                    selectByMouse: true
                                    maximumLength: 5
                                    inputMethodHints: Qt.ImhTime
                                    onEditingFinished: {
                                        text = tasksPanel.normalize12Hour(text);
                                        internalTime = tasksPanel.convertTo24Hour(text, tasksPanel.taskEndPeriod);
                                    }
                                    onAccepted: root.submitNewTask()

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignHCenter
                                        text: "End"
                                        font.family: "Google Sans"
                                        font.pixelSize: 9
                                        color: root.textMuted
                                        visible: !taskEndTimeInput.text && !taskEndTimeInput.activeFocus
                                    }

                                    validator: RegularExpressionValidator {
                                        regularExpression: /^$|^([1-9]|1[0-2])(:([0-5]?[0-9])?)?$/
                                    }

                                }

                                Rectangle {
                                    Layout.preferredWidth: 32 // Reduzido de 36
                                    Layout.minimumWidth: 32
                                    Layout.maximumWidth: 32
                                    Layout.preferredHeight: 24 // Reduzido de 28
                                    radius: 8 // Reduzido de 10
                                    color: Qt.alpha(root.color1, 0.14)

                                    Text {
                                        anchors.centerIn: parent
                                        text: tasksPanel.taskEndPeriod
                                        font.family: "Google Sans"
                                        font.pixelSize: 8
                                        font.weight: Font.DemiBold
                                        color: root.color1
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            tasksPanel.taskEndPeriod = tasksPanel.taskEndPeriod === "AM" ? "PM" : "AM";
                                            taskEndTimeInput.internalTime = tasksPanel.convertTo24Hour(taskEndTimeInput.text, tasksPanel.taskEndPeriod);
                                        }
                                    }

                                }

                            }

                        }

                        Rectangle {
                            readonly property bool canNotify: root.taskIncludeDate && taskStartTimeInput.text.trim().length > 0

                            Layout.minimumWidth: 20
                            Layout.maximumWidth: 40
                            Layout.preferredWidth: 30 // Reduzido de 38
                            Layout.preferredHeight: 30 // Reduzido de 38
                            radius: 10 // Reduzido de 14
                            color: canNotify && root.taskNotify ? Qt.alpha(root.color1, 0.16) : Qt.alpha(root.textColor, 0.04)
                            border.width: 1
                            border.color: canNotify && root.taskNotify ? Qt.alpha(root.color1, 0.5) : Qt.alpha(root.textColor, 0.08)

                            Text {
                                anchors.centerIn: parent
                                text: root.taskNotify && parent.canNotify ? "󰂚" : "󰂛"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 16 // Reduzido de 17
                                color: root.taskNotify && parent.canNotify ? root.color1 : root.textMuted
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (parent.canNotify)
                                        root.taskNotify = !root.taskNotify;
                                    else
                                        taskStartTimeInput.forceActiveFocus();
                                }
                            }

                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 180
                                easing.type: Easing.OutCubic
                            }

                        }

                    }

                }

            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: taskCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: taskCol

                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: TaskService.getTasksForDate(root.displayedYear, root.displayedMonth, root.selectedDay)

                        delegate: Rectangle {
                            id: taskItemRoot

                            required property var modelData
                            readonly property bool isOverdue: TaskService.isOverdue(taskItemRoot.modelData)

                            Layout.fillWidth: true
                            Layout.preferredHeight: taskSubtitleRow.visible ? 52 : 40 // Reduzido de 62 : 52
                            radius: 12 // Reduzido de 16
                            color: taskItemHover.hovered ? Qt.alpha(root.textColor, 0.05) : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 10

                                Rectangle {
                                    Layout.preferredWidth: 18 // Reduzido de 22
                                    Layout.preferredHeight: 18 // Reduzido de 22
                                    radius: 9 // Reduzido de 11
                                    color: taskItemRoot.modelData.done ? root.color1 : "transparent"
                                    border.width: taskItemRoot.modelData.done ? 0 : 2
                                    border.color: taskItemRoot.modelData.done ? root.color1 : root.textMuted

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✓"
                                        font.family: "Google Sans"
                                        font.pixelSize: 10 // Reduzido de 11
                                        font.weight: Font.Bold
                                        color: root.foreground
                                        visible: taskItemRoot.modelData.done
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: TaskService.toggleTask(taskItemRoot.modelData.id)
                                    }

                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2 // Reduzido de 3

                                    Text {
                                        Layout.fillWidth: true
                                        text: taskItemRoot.modelData.text
                                        font.family: "Google Sans"
                                        font.pixelSize: 10 // Reduzido de 11
                                        font.weight: Font.Medium
                                        font.strikeout: taskItemRoot.modelData.done
                                        color: taskItemRoot.modelData.done ? root.color1 : root.textColor
                                        elide: Text.ElideRight
                                    }

                                    RowLayout {
                                        id: taskSubtitleRow

                                        Layout.fillWidth: true
                                        spacing: 6
                                        visible: taskSubtitleText.text.length > 0

                                        Text {
                                            id: taskSubtitleText

                                            Layout.fillWidth: true
                                            text: {
                                                var str = "";
                                                var startDisp = tasksPanel.convertFrom24Hour(taskItemRoot.modelData.startTime);
                                                var endDisp = tasksPanel.convertFrom24Hour(taskItemRoot.modelData.endTime);
                                                var startText = startDisp.time ? startDisp.time + " " + startDisp.period : "";
                                                var endText = endDisp.time ? endDisp.time + " " + endDisp.period : "";
                                                var timeRange = startText + (endText ? " - " + endText : "");
                                                if (taskItemRoot.isOverdue) {
                                                    str = taskItemRoot.modelData.date;
                                                    if (timeRange)
                                                        str += " • " + timeRange;

                                                } else if (timeRange) {
                                                    str = timeRange;
                                                }
                                                return str;
                                            }
                                            font.family: "Google Sans"
                                            font.pixelSize: 8 // Reduzido de 9
                                            font.weight: taskItemRoot.isOverdue ? Font.DemiBold : Font.Normal
                                            color: taskItemRoot.isOverdue ? root.color2 : root.textMuted
                                            elide: Text.ElideRight
                                        }

                                        Rectangle {
                                            visible: !!taskItemRoot.modelData.notify && !taskItemRoot.modelData.done
                                            Layout.preferredWidth: 16 // Reduzido de 22
                                            Layout.preferredHeight: 16 // Reduzido de 22
                                            radius: 8 // Reduzido de 11
                                            color: Qt.alpha(root.color1, 0.12)

                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰂚"
                                                font.family: "Material Symbols Rounded"
                                                font.pixelSize: 10 // Reduzido de 12
                                                color: root.color1
                                            }

                                        }

                                    }

                                }

                                Rectangle {
                                    Layout.preferredWidth: 26 // Reduzido de 30
                                    Layout.preferredHeight: 26 // Reduzido de 30
                                    radius: 13 // Reduzido de 15
                                    visible: taskItemHover.hovered
                                    color: Qt.alpha(root.textColor, 0.07)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅖"
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 15 // Reduzido de 16
                                        color: root.textMuted
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: TaskService.removeTask(taskItemRoot.modelData.id)
                                    }

                                }

                            }

                            HoverHandler {
                                id: taskItemHover
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 140
                                    easing.type: Easing.OutCubic
                                }

                            }

                        }

                    }

                    Rectangle {
                        visible: TaskService.getTasksForDate(root.displayedYear, root.displayedMonth, root.selectedDay).length === 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80 // Reduzido de 112
                        radius: 14 // Reduzido de 18
                        color: Qt.alpha(root.textColor, 0.03)

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "󰷐"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 24 // Reduzido de 30
                                color: root.textMuted
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "No tasks for this day"
                                font.family: "Google Sans"
                                font.pixelSize: 10
                                color: root.textMuted
                            }

                        }

                    }

                }

            }

        }

    }

}

                    transform: Translate {
                        y: dashEntrance.offsetY
                    }

                }

                // ─────────────────────────────────────────────────────────────
                // VIEW 2: PRODUCTIVITY TAB (Pomodoro / Timer / Stopwatch)
                // ─────────────────────────────────────────────────────────────
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    visible: root.activeTab === "timer"
                    opacity: timerEntrance.opacity

                    // ── Mode Selector Header ──
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: 30
                        spacing: 10

                        Repeater {
                            model: [{
                                "mode": "pomodoro",
                                "icon": "󰄉",
                                "label": "Pomodoro"
                            }, {
                                "mode": "timer",
                                "icon": "󰔛",
                                "label": "Timer"
                            }, {
                                "mode": "stopwatch",
                                "icon": "󰑐",
                                "label": "Stopwatch"
                            }, {
                                "mode": "alarm",
                                "icon": "󰀠",
                                "label": "Alarm"
                            }]

                            delegate: Rectangle {
                                required property var modelData
                                required property int index

                                Layout.fillWidth: true
                                implicitHeight: 36
                                radius: 12
                                color: TimerService.activeMode === modelData.mode ? root.color1 : (modeHover.hovered ? root.surfaceContainer : "transparent")
                                border.color: TimerService.activeMode === modelData.mode ? root.color1 : Qt.alpha(root.textMuted, 0.08)

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Text {
                                        text: modelData.icon
                                        font.pixelSize: 14
                                        color: TimerService.activeMode === modelData.mode ? root.foreground : root.textMuted
                                    }

                                    Text {
                                        text: modelData.label
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: TimerService.activeMode === modelData.mode ? root.foreground : root.textMuted
                                    }

                                }

                                HoverHandler {
                                    id: modeHover
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: TimerService.activeMode = modelData.mode
                                }

                            }

                        }

                    }

                    // POMODORO VIEW
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 12
                        visible: TimerService.activeMode === "pomodoro"

                        // ── Left: Big Display + Controls ──
                        Rectangle {
                            Layout.fillHeight: true
                            Layout.preferredWidth: 480
                            radius: 18
                            color: root.surface
                            border.color: Qt.alpha(root.textMuted, 0.08)

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 6

                                // Phase chips
                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 8

                                    Repeater {
                                        model: [{
                                            "key": "work",
                                            "label": "Focus"
                                        }, {
                                            "key": "shortBreak",
                                            "label": "Short Break"
                                        }, {
                                            "key": "longBreak",
                                            "label": "Long Break"
                                        }]

                                        delegate: Rectangle {
                                            required property var modelData
                                            required property int index

                                            implicitWidth: chipRow.implicitWidth + 20
                                            implicitHeight: 28
                                            radius: 14
                                            color: TimerService.pomodoroPhase === modelData.key ? root.color1 : root.surfaceContainer

                                            RowLayout {
                                                id: chipRow

                                                anchors.centerIn: parent
                                                spacing: 4

                                                Text {
                                                    text: modelData.label
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                    color: TimerService.pomodoroPhase === modelData.key ? root.background : root.textMuted
                                                }

                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: TimerService.setPomodoroPhase(modelData.key)
                                            }

                                        }

                                    }

                                }

                                Item {
                                    Layout.fillHeight: true
                                }

                                // Big Time Display
                                Text {
                                    text: TimerService.formatSeconds(TimerService.pomodoroSecondsLeft)
                                    font.pixelSize: 58
                                    font.family: "JetbrainsMono Nerd Font Propo"
                                    font.bold: true
                                    color: TimerService.pomodoroRunning ? root.color1 : root.textMuted
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                // Phase label below time
                                Text {
                                    text: TimerService.pomodoroPhase === "work" ? "Focus Session" : (TimerService.pomodoroPhase === "shortBreak" ? "Short Break" : "Long Break")
                                    font.pixelSize: 12
                                    color: root.textMuted
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                // Cycle dots + counter
                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 6

                                    Repeater {
                                        model: TimerService.totalCycles

                                        delegate: Rectangle {
                                            required property int index

                                            width: 10
                                            height: 10
                                            radius: 5
                                            color: index < TimerService.currentCycle ? root.color1 : root.surfaceContainer
                                            border.color: root.color1
                                        }

                                    }

                                    Text {
                                        text: "Cycle " + TimerService.currentCycle + "/" + TimerService.totalCycles
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: root.textMuted
                                    }

                                }

                                Item {
                                    Layout.fillHeight: true
                                }

                                // Quick add buttons
                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 8

                                    Repeater {
                                        model: [{
                                            "label": "-5m",
                                            "sec": -300
                                        }, {
                                            "label": "-1m",
                                            "sec": -60
                                        }, {
                                            "label": "+1m",
                                            "sec": 60
                                        }, {
                                            "label": "+5m",
                                            "sec": 300
                                        }]

                                        delegate: Rectangle {
                                            required property var modelData
                                            required property int index

                                            implicitWidth: 56
                                            implicitHeight: 28
                                            radius: 14
                                            color: qaHover.hovered ? Qt.alpha(root.color1, 0.18) : root.surfaceContainer
                                            border.color: qaHover.hovered ? root.color1 : "transparent"

                                            HoverHandler {
                                                id: qaHover
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.label
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: root.textMuted
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    TimerService.pomodoroSecondsLeft += modelData.sec;
                                                }
                                            }

                                        }

                                    }

                                }

                                Item {
                                    height: 4
                                }

                                // Play / Reset / Skip controls
                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 18

                                    Rectangle {
                                        implicitWidth: 40
                                        implicitHeight: 40
                                        radius: 20
                                        color: root.surfaceContainer

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰑐"
                                            font.pixelSize: 16
                                            color: root.textMuted
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: TimerService.resetPomodoro()
                                        }

                                    }

                                    Rectangle {
                                        implicitWidth: 56
                                        implicitHeight: 56
                                        radius: 28
                                        color: root.color1
                                        scale: pomoPlayH.hovered ? 1.06 : 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: TimerService.pomodoroRunning ? "" : ""
                                            font.pixelSize: 22
                                            color: root.foreground
                                        }

                                        HoverHandler {
                                            id: pomoPlayH
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: TimerService.togglePomodoro()
                                        }

                                        Behavior on scale {
                                            NumberAnimation {
                                                duration: 120
                                            }

                                        }

                                    }

                                    Rectangle {
                                        implicitWidth: 40
                                        implicitHeight: 40
                                        radius: 20
                                        color: root.surfaceContainer

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰒭"
                                            font.pixelSize: 16
                                            color: root.textMuted
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: TimerService.skipPomodoro(false)
                                        }

                                    }

                                }

                            }

                        }

                        // ── Right: 3 Config Fields ──
                        Rectangle {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            radius: 18
                            color: root.surface

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 8

                                Text {
                                    text: "Configuration"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.textMuted
                                }

                                Item {
                                    Layout.fillHeight: true
                                }

                                // ── Field 1: Focus Time──
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 52
                                    radius: 12
                                    color: root.surfaceContainer

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 8

                                        Text {
                                            text: "󱎫"
                                            font.pixelSize: 18
                                            color: root.color1
                                        }

                                        ColumnLayout {
                                            spacing: 0
                                            Layout.fillWidth: true

                                            Text {
                                                text: "Focus Time"
                                                font.pixelSize: 10
                                                color: root.textMuted
                                            }

                                            RowLayout {
                                                spacing: 6

                                                Rectangle {
                                                    implicitWidth: 24
                                                    implicitHeight: 24
                                                    radius: 12
                                                    color: Qt.alpha(root.color1, 0.15)

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "−"
                                                        font.pixelSize: 14
                                                        font.bold: true
                                                        color: root.color1
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            TimerService.workMinutes = Math.max(1, TimerService.workMinutes - 5);
                                                            TimerService.resetPomodoro();
                                                        }
                                                    }

                                                }

                                                Rectangle {
                                                    implicitWidth: 52
                                                    implicitHeight: 24
                                                    radius: 6
                                                    color: Qt.alpha(root.background, 0.6)
                                                    border.color: Qt.alpha(root.textColor, 0.1)

                                                    TextInput {
                                                        anchors.centerIn: parent
                                                        text: TimerService.workMinutes.toString()
                                                        color: root.textBright
                                                        font.pixelSize: 13
                                                        font.bold: true
                                                        horizontalAlignment: Text.AlignHCenter
                                                        inputMethodHints: Qt.ImhDigitsOnly
                                                        onAccepted: {
                                                            var v = parseInt(text);
                                                            if (!isNaN(v) && v > 0 && v <= 180) {
                                                                TimerService.workMinutes = v;
                                                                TimerService.resetPomodoro();
                                                            }
                                                        }
                                                    }

                                                }

                                                Text {
                                                    text: "min"
                                                    font.pixelSize: 10
                                                    color: root.textMuted
                                                }

                                                Rectangle {
                                                    implicitWidth: 24
                                                    implicitHeight: 24
                                                    radius: 12
                                                    color: Qt.alpha(root.color1, 0.15)

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "+"
                                                        font.pixelSize: 14
                                                        font.bold: true
                                                        color: root.color1
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            TimerService.workMinutes = Math.min(180, TimerService.workMinutes + 5);
                                                            TimerService.resetPomodoro();
                                                        }
                                                    }

                                                }

                                            }

                                        }

                                    }

                                }

                                // ── Field 2: Short Break ──
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 52
                                    radius: 12
                                    color: root.surfaceContainer

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 8

                                        Text {
                                            text: "󰒫"
                                            font.pixelSize: 18
                                            color: Colors.cfg.base0B
                                        }

                                        ColumnLayout {
                                            spacing: 0
                                            Layout.fillWidth: true

                                            Text {
                                                text: "Short Break"
                                                font.pixelSize: 10
                                                color: root.textMuted
                                            }

                                            RowLayout {
                                                spacing: 6

                                                Rectangle {
                                                    implicitWidth: 24
                                                    implicitHeight: 24
                                                    radius: 12
                                                    color: Qt.alpha(Colors.cfg.base0B, 0.15)

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "−"
                                                        font.pixelSize: 14
                                                        font.bold: true
                                                        color: Colors.cfg.base0B
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            TimerService.shortBreakMinutes = Math.max(1, TimerService.shortBreakMinutes - 1);
                                                        }
                                                    }

                                                }

                                                Rectangle {
                                                    implicitWidth: 52
                                                    implicitHeight: 24
                                                    radius: 6
                                                    color: Qt.alpha(root.background, 0.6)
                                                    border.color: Qt.alpha(root.textColor, 0.1)

                                                    TextInput {
                                                        anchors.centerIn: parent
                                                        text: TimerService.shortBreakMinutes.toString()
                                                        color: root.textBright
                                                        font.pixelSize: 13
                                                        font.bold: true
                                                        horizontalAlignment: Text.AlignHCenter
                                                        inputMethodHints: Qt.ImhDigitsOnly
                                                        onAccepted: {
                                                            var v = parseInt(text);
                                                            if (!isNaN(v) && v > 0 && v <= 60)
                                                                TimerService.shortBreakMinutes = v;

                                                        }
                                                    }

                                                }

                                                Text {
                                                    text: "min"
                                                    font.pixelSize: 10
                                                    color: root.textMuted
                                                }

                                                Rectangle {
                                                    implicitWidth: 24
                                                    implicitHeight: 24
                                                    radius: 12
                                                    color: Qt.alpha(Colors.cfg.base0B, 0.15)

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "+"
                                                        font.pixelSize: 14
                                                        font.bold: true
                                                        color: Colors.cfg.base0B
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            TimerService.shortBreakMinutes = Math.min(60, TimerService.shortBreakMinutes + 1);
                                                        }
                                                    }

                                                }

                                            }

                                        }

                                    }

                                }

                                // ── Field 3: Number of Sessions ──
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 52
                                    radius: 12
                                    color: root.surfaceContainer

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 8

                                        Text {
                                            text: "󰑘"
                                            font.pixelSize: 18
                                            color: Colors.cfg.base0E
                                        }

                                        ColumnLayout {
                                            spacing: 0
                                            Layout.fillWidth: true

                                            Text {
                                                text: "Number of Sessions"
                                                font.pixelSize: 10
                                                color: root.textMuted
                                            }

                                            RowLayout {
                                                spacing: 6

                                                Rectangle {
                                                    implicitWidth: 24
                                                    implicitHeight: 24
                                                    radius: 12
                                                    color: Qt.alpha(Colors.cfg.base0E, 0.15)

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "−"
                                                        font.pixelSize: 14
                                                        font.bold: true
                                                        color: Colors.cfg.base0E
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            TimerService.totalCycles = Math.max(1, TimerService.totalCycles - 1);
                                                        }
                                                    }

                                                }

                                                Rectangle {
                                                    implicitWidth: 52
                                                    implicitHeight: 24
                                                    radius: 6
                                                    color: Qt.alpha(root.background, 0.6)
                                                    border.color: Qt.alpha(root.textColor, 0.1)

                                                    TextInput {
                                                        anchors.centerIn: parent
                                                        text: TimerService.totalCycles.toString()
                                                        color: root.textBright
                                                        font.pixelSize: 13
                                                        font.bold: true
                                                        horizontalAlignment: Text.AlignHCenter
                                                        inputMethodHints: Qt.ImhDigitsOnly
                                                        onAccepted: {
                                                            var v = parseInt(text);
                                                            if (!isNaN(v) && v > 0 && v <= 20)
                                                                TimerService.totalCycles = v;

                                                        }
                                                    }

                                                }

                                                Text {
                                                    text: "×"
                                                    font.pixelSize: 11
                                                    color: root.textMuted
                                                }

                                                Rectangle {
                                                    implicitWidth: 24
                                                    implicitHeight: 24
                                                    radius: 12
                                                    color: Qt.alpha(Colors.cfg.base0E, 0.15)

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "+"
                                                        font.pixelSize: 14
                                                        font.bold: true
                                                        color: Colors.cfg.base0E
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            TimerService.totalCycles = Math.min(20, TimerService.totalCycles + 1);
                                                        }
                                                    }

                                                }

                                            }

                                        }

                                    }

                                }

                                Item {
                                    Layout.fillHeight: true
                                }

                                // Long break info
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    radius: 8
                                    color: Qt.alpha(Colors.cfg.base0A, 0.08)
                                    border.color: Qt.alpha(Colors.cfg.base0A, 0.15)

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        spacing: 6

                                        Text {
                                            text: "󰄉"
                                            font.pixelSize: 13
                                            color: Colors.cfg.base0A
                                        }

                                        Text {
                                            text: "long break: " + TimerService.longBreakMinutes + "min (after " + TimerService.totalCycles + " cycles)"
                                            font.pixelSize: 10
                                            color: root.textMuted
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        Rectangle {
                                            implicitWidth: 20
                                            implicitHeight: 20
                                            radius: 10
                                            color: Qt.alpha(Colors.cfg.base0A, 0.15)

                                            Text {
                                                anchors.centerIn: parent
                                                text: "−"
                                                font.pixelSize: 12
                                                font.bold: true
                                                color: Colors.cfg.base0A
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    TimerService.longBreakMinutes = Math.max(5, TimerService.longBreakMinutes - 5);
                                                }
                                            }

                                        }

                                        Text {
                                            text: TimerService.longBreakMinutes + "m"
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: Colors.cfg.base0A
                                        }

                                        Rectangle {
                                            implicitWidth: 20
                                            implicitHeight: 20
                                            radius: 10
                                            color: Qt.alpha(Colors.cfg.base0A, 0.15)

                                            Text {
                                                anchors.centerIn: parent
                                                text: "+"
                                                font.pixelSize: 12
                                                font.bold: true
                                                color: Colors.cfg.base0A
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    TimerService.longBreakMinutes = Math.min(60, TimerService.longBreakMinutes + 5);
                                                }
                                            }

                                        }

                                    }

                                }

                            }

                        }

                    }

                    // CUSTOM TIMER VIEW
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 18
                        color: root.surface
                        visible: TimerService.activeMode === "timer"

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 14

                            // Big Time Display
                            Text {
                                text: TimerService.formatSeconds(TimerService.timerSecondsLeft)
                                font.pixelSize: 58
                                font.family: "JetbrainsMono Nerd Font Propo"
                                font.bold: true
                                color: TimerService.timerRunning ? root.color1 : root.textMuted
                                Layout.alignment: Qt.AlignHCenter
                            }

                            // Quick Add Buttons
                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 8

                                Repeater {
                                    model: [{
                                        "label": "+5m",
                                        "sec": 300
                                    }, {
                                        "label": "+10m",
                                        "sec": 600
                                    }, {
                                        "label": "+15m",
                                        "sec": 900
                                    }, {
                                        "label": "+30m",
                                        "sec": 1800
                                    }, {
                                        "label": "+1h",
                                        "sec": 3600
                                    }]

                                    delegate: Rectangle {
                                        required property var modelData
                                        required property int index

                                        implicitWidth: 60
                                        implicitHeight: 30
                                        radius: 15
                                        color: tqaH.hovered ? Qt.alpha(root.color1, 0.18) : root.surfaceContainer
                                        border.color: tqaH.hovered ? root.color1 : "transparent"

                                        HoverHandler {
                                            id: tqaH
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: root.textMuted
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: TimerService.addTimerSeconds(modelData.sec)
                                        }

                                    }

                                }

                            }

                            // Manual Input Field
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 220
                                height: 38
                                radius: 10
                                color: root.surfaceContainer

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 6

                                    Text {
                                        text: "Define:"
                                        font.pixelSize: 10
                                        color: root.textMuted
                                    }

                                    TextInput {
                                        id: timerManualIn

                                        Layout.fillWidth: true
                                        text: Math.round(TimerService.timerTotalSeconds / 60).toString()
                                        color: root.textBright
                                        font.pixelSize: 13
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        inputMethodHints: Qt.ImhDigitsOnly
                                        onAccepted: {
                                            var v = parseInt(text.trim());
                                            if (!isNaN(v) && v > 0)
                                                TimerService.setTimerDuration(v * 60);

                                        }
                                    }

                                    Text {
                                        text: "min"
                                        font.pixelSize: 10
                                        color: root.textMuted
                                    }

                                }

                            }

                            // Play / Reset Controls
                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 20

                                Rectangle {
                                    implicitWidth: 44
                                    implicitHeight: 44
                                    radius: 22
                                    color: root.surfaceContainer

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰑐"
                                        font.pixelSize: 18
                                        color: root.textMuted
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: TimerService.resetTimer()
                                    }

                                }

                                Rectangle {
                                    implicitWidth: 56
                                    implicitHeight: 56
                                    radius: 28
                                    color: root.color1
                                    scale: timerPlayH.hovered ? 1.06 : 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: TimerService.timerRunning ? "" : ""
                                        font.pixelSize: 22
                                        color: root.foreground
                                    }

                                    HoverHandler {
                                        id: timerPlayH
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: TimerService.toggleTimer()
                                    }

                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 120
                                        }

                                    }

                                }

                            }

                        }

                    }

                    // STOPWATCH VIEW
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 18
                        color: root.surface
                        visible: TimerService.activeMode === "stopwatch"

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 16

                            Item {
                                Layout.fillHeight: true
                            }

                            // Big Time Display
                            Text {
                                text: TimerService.formatSeconds(TimerService.stopwatchSeconds)
                                font.pixelSize: 58
                                font.family: "JetbrainsMono Nerd Font Propo"
                                font.bold: true
                                color: TimerService.stopwatchRunning ? root.color1 : root.textMuted
                                Layout.alignment: Qt.AlignHCenter
                            }

                            // Controls
                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 18

                                // Reset
                                Rectangle {
                                    implicitWidth: 44
                                    implicitHeight: 44
                                    radius: 22
                                    color: root.surfaceContainer

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰑐"
                                        font.pixelSize: 18
                                        color: root.textColor
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: TimerService.resetStopwatch()
                                    }

                                }

                                // Play/Pause
                                Rectangle {
                                    implicitWidth: 56
                                    implicitHeight: 56
                                    radius: 28
                                    color: root.color1
                                    scale: stopPlayH.hovered ? 1.06 : 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: TimerService.stopwatchRunning ? "" : ""
                                        font.pixelSize: 22
                                        color: root.foreground
                                    }

                                    HoverHandler {
                                        id: stopPlayH
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: TimerService.toggleStopwatch()
                                    }

                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 120
                                        }

                                    }

                                }

                                // Lap
                                Rectangle {
                                    implicitWidth: 44
                                    implicitHeight: 44
                                    radius: 22
                                    color: root.surfaceContainer
                                    opacity: TimerService.stopwatchRunning ? 1 : 0.4

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰐕"
                                        font.pixelSize: 18
                                        color: root.textColor
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        enabled: TimerService.stopwatchRunning
                                        onClicked: TimerService.addLap()
                                    }

                                }

                            }

                            // Laps list
                            Flickable {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                contentHeight: lapsCol.height
                                visible: TimerService.stopwatchLaps.length > 0

                                ColumnLayout {
                                    id: lapsCol

                                    width: parent.width
                                    spacing: 4

                                    Repeater {
                                        model: TimerService.stopwatchLaps

                                        delegate: Rectangle {
                                            required property var modelData
                                            required property int index

                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 26
                                            radius: 6
                                            color: index % 2 === 0 ? Qt.alpha(root.surfaceContainer, 0.5) : "transparent"

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 4
                                                spacing: 8

                                                Text {
                                                    text: "#" + modelData.lap
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                    color: root.color1
                                                }

                                                Text {
                                                    text: modelData.time
                                                    font.pixelSize: 10
                                                    font.family: "JetbrainsMono Nerd Font Propo"
                                                    color: root.textColor
                                                    Layout.fillWidth: true
                                                    horizontalAlignment: Text.AlignRight
                                                }

                                            }

                                        }

                                    }

                                }

                            }

                            Item {
                                Layout.fillHeight: true
                                visible: TimerService.stopwatchLaps.length === 0
                            }

                        }

                    }

                    // === ALARM VIEW ===
                    AlarmView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: TimerService.activeMode === "alarm"
                        primary: root.color1
                        secondary: root.color2
                        surfaceContainer: root.surfaceContainer
                        surfaceVariant: root.surfaceVariant
                        background: root.background
                        text: root.text
                        textSecondary: root.textMuted
                        textBright: root.textBright
                        foreground: root.foreground
                        errorCol: root.error
                        successCol: root.success
                        warningCol: root.warning
                    }

                    transform: Translate {
                        y: timerEntrance.offsetY
                    }

                }

                // ─────────────────────────────────────────────────────────────
                // VIEW 3: NOTIFICATIONS TAB
                // ─────────────────────────────────────────────────────────────
                Rectangle {
                    anchors.fill: parent
                    radius: 18
                    color: root.surface
                    visible: root.activeTab === "notifications"
                    opacity: notifEntrance.opacity

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "Notification Center"
                                font.pixelSize: 14
                                font.bold: true
                                color: root.textMuted
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                implicitWidth: 80
                                implicitHeight: 28
                                radius: 8
                                color: root.surfaceContainer
                                border.color: Colors.cfg.warning

                                Text {
                                    anchors.centerIn: parent
                                    text: "Clear All"
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: Colors.cfg.warning
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NotificationService.clearAll()
                                }

                            }

                        }

                        Flickable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentHeight: notifCol.implicitHeight
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            ColumnLayout {
                                id: notifCol

                                width: parent.width
                                spacing: 8

                                Repeater {
                                    model: NotificationService.notifications

                                    delegate: Rectangle {
                                        id: notifCard

                                        required property var modelData
                                        required property int index

                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 56
                                        radius: 12
                                        color: root.surfaceContainer

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            spacing: 10

                                            Rectangle {
                                                implicitWidth: 34
                                                implicitHeight: 34
                                                radius: 17
                                                color: Qt.alpha(root.color1, 0.2)

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: notifCard.modelData.icon || "󰂚"
                                                    font.pixelSize: 16
                                                    font.family: "GeistMono Nerd Font Propo Propo"
                                                    color: root.color1
                                                }

                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2

                                                RowLayout {
                                                    Layout.fillWidth: true

                                                    Text {
                                                        text: notifCard.modelData.title
                                                        font.pixelSize: 11
                                                        font.bold: true
                                                        color: root.textColor
                                                        Layout.fillWidth: true
                                                        elide: Text.ElideRight
                                                    }

                                                    Text {
                                                        text: notifCard.modelData.time || ""
                                                        font.pixelSize: 9
                                                        color: root.textMuted
                                                    }

                                                }

                                                Text {
                                                    text: notifCard.modelData.body
                                                    font.pixelSize: 10
                                                    color: root.textMuted
                                                    Layout.fillWidth: true
                                                    elide: Text.ElideRight
                                                }

                                            }

                                            Text {
                                                text: "󰅖"
                                                font.pixelSize: 12
                                                color: root.textMuted

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: NotificationService.removeNotification(notifCard.index)
                                                }

                                            }

                                        }

                                    }

                                }

                                ColumnLayout {
                                    visible: NotificationService.notifications.length === 0
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.topMargin: 40
                                    spacing: 6

                                    Text {
                                        text: "󰂚"
                                        font.pixelSize: 32
                                        font.family: "GeistMono Nerd Font Propo Propo"
                                        color: Qt.alpha(root.textColor, 0.3)
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                    Text {
                                        text: "No archived notifications"
                                        font.pixelSize: 12
                                        color: root.textMuted
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                }

                            }

                        }

                    }

                    transform: Translate {
                        y: notifEntrance.offsetY
                    }

                }

                // ─────────────────────────────────────────────────────────────
                // VIEW 4: SYSTEM MONITOR TAB
                // ─────────────────────────────────────────────────────────────
                Rectangle {
                    anchors.fill: parent
                    radius: 18
                    color: root.surface
                    visible: root.activeTab === "system"
                    opacity: sysEntrance.opacity

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        // ── 3 Main Metrics Cards (CPU, RAM, GPU) with Circular Gauges ──
                        RowLayout {
                            // ================================================================
                            // CPU
                            // ================================================================
                            // ================================================================
                            // RAM
                            // ================================================================
                            // ================================================================
                            // GPU
                            // ================================================================

                            Layout.fillWidth: true
                            Layout.preferredHeight: 195
                            spacing: 12

                            Rectangle {
                                id: cpuCard

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 14
                                color: root.surface
                                scale: cpuHover.hovered ? 1.015 : 1

                                HoverHandler {
                                    id: cpuHover
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 4

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Text {
                                            text: "󰻠  CPU"
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: root.color1
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: SystemMonitorService.cpuTemp + "°C"
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: SystemMonitorService.cpuTemp > 75 ? Colors.cfg.warning : root.textMuted
                                        }

                                    }

                                    Item {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true

                                        OrganicProgress {
                                            anchors.fill: parent
                                            color: root.color1
                                            value: SystemMonitorService.cpuPercent / 100
                                            lineWidth: 8
                                            organicAmount: 2
                                        }

                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 2

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: SystemMonitorService.cpuPercent.toFixed(1) + "%"
                                                font.pixelSize: 15
                                                font.bold: true
                                                color: root.textColor
                                                scale: cpuHover.hovered ? 1.04 : 1

                                                Behavior on scale {
                                                    NumberAnimation {
                                                        duration: 180
                                                        easing.type: Easing.OutCubic
                                                    }

                                                }

                                            }

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: SystemMonitorService.cpuCores + " Cores"
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: root.textMuted
                                            }

                                        }

                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: SystemMonitorService.cpuModel
                                        font.pixelSize: 10
                                        color: root.textMuted
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                    }

                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 180
                                        easing.type: Easing.OutCubic
                                    }

                                }

                            }

                            Rectangle {
                                id: ramCard

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 14
                                color: root.surface
                                scale: ramHover.hovered ? 1.015 : 1

                                HoverHandler {
                                    id: ramHover
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 4

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Text {
                                            text: "󰘚  RAM"
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: Colors.cfg.secondary
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: SystemMonitorService.swapPercent > 0 ? ("Swap: " + SystemMonitorService.swapPercent.toFixed(0) + "%") : "Normal"
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: root.textMuted
                                        }

                                    }

                                    Item {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true

                                        OrganicProgress {
                                            anchors.fill: parent
                                            color: Colors.cfg.secondary
                                            value: SystemMonitorService.memPercent / 100
                                            lineWidth: 8
                                            organicAmount: 2
                                        }

                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 2

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: SystemMonitorService.memPercent.toFixed(1) + "%"
                                                font.pixelSize: 15
                                                font.bold: true
                                                color: root.textColor
                                                scale: ramHover.hovered ? 1.04 : 1

                                                Behavior on scale {
                                                    NumberAnimation {
                                                        duration: 180
                                                        easing.type: Easing.OutCubic
                                                    }

                                                }

                                            }

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: SystemMonitorService.memUsedGb.toFixed(1) + " / " + SystemMonitorService.memTotalGb.toFixed(1) + " GB"
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: root.textMuted
                                            }

                                        }

                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: (SystemMonitorService.memTotalGb - SystemMonitorService.memUsedGb).toFixed(1) + " GB Free"
                                        font.pixelSize: 10
                                        color: root.textMuted
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                    }

                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 180
                                        easing.type: Easing.OutCubic
                                    }

                                }

                            }

                            Rectangle {
                                id: gpuCard

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 14
                                color: root.surface
                                scale: gpuHover.hovered ? 1.015 : 1

                                HoverHandler {
                                    id: gpuHover
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 4

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Text {
                                            text: "󰢮  GPU"
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: Colors.cfg.warning
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: SystemMonitorService.gpuAvailable ? (SystemMonitorService.gpuTemp + "°C") : "N/A"
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: (SystemMonitorService.gpuAvailable && SystemMonitorService.gpuTemp > 80) ? Colors.cfg.warning : root.textMuted
                                        }

                                    }

                                    Item {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true

                                        OrganicProgress {
                                            anchors.fill: parent
                                            color: Colors.cfg.warning
                                            value: SystemMonitorService.gpuPercent / 100
                                            lineWidth: 8
                                            organicAmount: 2.2
                                        }

                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 2

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: SystemMonitorService.gpuPercent.toFixed(1) + "%"
                                                font.pixelSize: 15
                                                font.bold: true
                                                color: root.textColor
                                                scale: gpuHover.hovered ? 1.04 : 1

                                                Behavior on scale {
                                                    NumberAnimation {
                                                        duration: 180
                                                        easing.type: Easing.OutCubic
                                                    }

                                                }

                                            }

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: SystemMonitorService.gpuAvailable && SystemMonitorService.gpuTotalGb > 0 ? (SystemMonitorService.gpuUsedGb.toFixed(1) + " / " + SystemMonitorService.gpuTotalGb.toFixed(1) + " GB") : (SystemMonitorService.gpuAvailable ? "Active" : "0.0 / 0.0 GB")
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: root.textMuted
                                            }

                                        }

                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: SystemMonitorService.gpuAvailable ? SystemMonitorService.gpuName : "No dedicated GPU"
                                        font.pixelSize: 10
                                        color: root.textMuted
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                    }

                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 180
                                        easing.type: Easing.OutCubic
                                    }

                                }

                            }

                        }

                        // ── Bottom: Top Active Processes Table ──
                        Rectangle {
                            Layout.fillWidth: true
                            height: 145
                            radius: 14
                            clip: true
                            color: root.surfaceContainer

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 0

                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        text: "Top Active Processes (CPU / Memory)"
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: root.textMuted
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: "PID"
                                        font.pixelSize: 10
                                        color: root.textMuted
                                        Layout.preferredWidth: 60
                                        horizontalAlignment: Text.AlignRight
                                    }

                                    Text {
                                        text: "CPU"
                                        font.pixelSize: 10
                                        color: root.textMuted
                                        Layout.preferredWidth: 65
                                        horizontalAlignment: Text.AlignRight
                                    }

                                    Text {
                                        text: "MEM"
                                        font.pixelSize: 10
                                        color: root.textMuted
                                        Layout.preferredWidth: 65
                                        horizontalAlignment: Text.AlignRight
                                    }

                                }

                                Repeater {
                                    model: SystemMonitorService.topProcs || []

                                    delegate: Rectangle {
                                        id: procItem

                                        required property var modelData
                                        required property int index

                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 22
                                        radius: 6
                                        color: index % 2 === 0 ? Qt.alpha(root.textColor, 0.03) : "transparent"

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 6
                                            anchors.rightMargin: 6
                                            spacing: 8

                                            Text {
                                                text: procItem.modelData.name
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: root.textColor
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                text: String(procItem.modelData.pid)
                                                font.pixelSize: 9
                                                font.family: "GeistMono Nerd Font Propo"
                                                color: root.textMuted
                                                Layout.preferredWidth: 60
                                                horizontalAlignment: Text.AlignRight
                                            }

                                            Rectangle {
                                                Layout.preferredWidth: 55
                                                Layout.preferredHeight: 18
                                                radius: 4
                                                color: Qt.alpha(root.color1, 0.15)

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: procItem.modelData.cpu.toFixed(1) + "%"
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                    color: root.color1
                                                }

                                            }

                                            Rectangle {
                                                Layout.preferredWidth: 55
                                                Layout.preferredHeight: 18
                                                radius: 4
                                                color: Qt.alpha(Colors.cfg.secondary, 0.15)

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: procItem.modelData.mem.toFixed(1) + "%"
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                    color: Colors.cfg.secondary
                                                }

                                            }

                                        }

                                    }

                                }

                                Item {
                                    Layout.fillHeight: true
                                }

                            }

                        }

                    }

                    transform: Translate {
                        y: sysEntrance.offsetY
                    }

                }

            }

        }

    }

}
