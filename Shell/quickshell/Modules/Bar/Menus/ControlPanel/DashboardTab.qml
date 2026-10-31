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
import qs.Modules.Bar.Menus
import qs.Services

RowLayout {
    id: root

    property color primary: Colors.cfg.primary
    property color secondary: Colors.cfg.secondary
    property color tertiary: Colors.cfg.tertiary
    property color background: Colors.cfg.background
    property color surface: Qt.alpha(Colors.cfg.surface, Config.effectiveGeneralOpacity)
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
    property alias color1: root.primary
    property alias color2: root.secondary
    property alias textColor: root.text
    property alias textMuted: root.textSecondary
    property alias foreground: root.on_primary
    readonly property var player: PlayerService.activePlayer
    readonly property bool isPlaying: player ? (player.playbackState === MprisPlaybackState.Playing) : false
    property string artUrl: player && player.trackArtUrl ? player.trackArtUrl : ""
    property var currentDate: new Date()
    property int displayedMonth: currentDate.getMonth()
    property int displayedYear: currentDate.getFullYear()
    property int selectedDay: currentDate.getDate()
    readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    readonly property var shortMonthNames: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    readonly property var englishDaysShort: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    readonly property var englishDaysLong: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    readonly property var weekDayNames: (Config.cfg && Config.cfg.weekStartsOnMonday)
        ? ["M", "T", "W", "T", "F", "S", "S"]
        : ["S", "M", "T", "W", "T", "F", "S"]
    readonly property bool clock24h: (Config.cfg && Config.cfg.clock24h !== undefined) ? Config.cfg.clock24h : false
    readonly property string clockFormat: (Config.cfg && Config.cfg.clockFormat) ? Config.cfg.clockFormat : "time_calendar"
    property string currentEnergyMode: "balanced"
    property bool nightLightActive: false
    property bool caffeineActive: false
    property bool gameModeActive: false
    property bool taskIncludeDate: true
    property bool taskNotify: true
    property bool tabActive: false
    property bool tasksExpanded: false

    function getMonthName(monthIndex) {
        return root.monthNames[monthIndex] || "";
    }

    function getShortMonthName(monthIndex) {
        return root.shortMonthNames[monthIndex] || "";
    }

    function formatDateByConfig(dateObj) {
        if (!dateObj)
            return "";

        var dayName = root.englishDaysShort[dateObj.getDay()];
        var fullDayName = root.englishDaysLong[dateObj.getDay()];
        var monthShort = root.shortMonthNames[dateObj.getMonth()];
        var d = dateObj.getDate();
        var dd = (d < 10 ? "0" : "") + d;
        var m = dateObj.getMonth() + 1;
        var mm = (m < 10 ? "0" : "") + m;
        var yyyy = dateObj.getFullYear();

        switch (root.clockFormat) {
        case "time_only":
            return dd + "/" + mm + "/" + yyyy;
        case "time_day":
            return dayName + ", " + dd;
        case "time_day_month":
            return dd + " " + monthShort;
        case "time_full":
            return fullDayName + ", " + dd + " " + monthShort;
        case "time_calendar":
        default:
            return dayName + ", " + dd + "/" + mm;
        }
    }

    function formatTaskDate(dateStr) {
        if (!dateStr)
            return "";

        var parts = dateStr.split("-");
        if (parts.length !== 3)
            return dateStr;

        var y = parseInt(parts[0], 10);
        var m = parseInt(parts[1], 10) - 1;
        var d = parseInt(parts[2], 10);
        if (isNaN(y) || isNaN(m) || isNaN(d))
            return dateStr;

        return root.formatDateByConfig(new Date(y, m, d));
    }

    function submitNewTask() {
        var title = taskInput.text.trim();
        if (!title)
            return ;

        tasksPanel.prepareTimes();
        if (tasksPanel.hasTimeError)
            return ;

        var finalDate = TaskService.formatDateKey(root.displayedYear, root.displayedMonth, root.selectedDay);
        var finalStart = taskStartTimeInput.internalTime ? taskStartTimeInput.internalTime : "";
        var finalEnd = taskEndTimeInput.internalTime ? taskEndTimeInput.internalTime : "";
        var finalNotify = (finalStart !== "" && taskNotify);
        TaskService.addTask(title, finalDate, finalStart, finalEnd, finalNotify, tasksPanel.taskPriority);
        taskInput.text = "";
        taskStartTimeInput.text = "";
        taskStartTimeInput.internalTime = "";
        taskEndTimeInput.text = "";
        taskEndTimeInput.internalTime = "";
        taskNotify = true;
        tasksPanel.taskPriority = "none";
        if (calendarCard.calendarViewMode === "weekly")
            Qt.callLater(calendarCard.scrollToFirstTask);

    }

    function getDaysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate();
    }

    function getFirstDayOfWeek(year, month) {
        var day = new Date(year, month, 1).getDay();
        if (Config.cfg && Config.cfg.weekStartsOnMonday) {
            return (day + 6) % 7;
        }
        return day;
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

    spacing: 10
    onTabActiveChanged: {
        if (root.tabActive)
            root.currentDate = new Date();

        if (root.tabActive && root.player)
            root.player.positionChanged();

    }
    onPlayerChanged: {
        if (root.player)
            root.player.positionChanged();

    }
    onIsPlayingChanged: {
        if (root.isPlaying && root.player)
            root.player.positionChanged();

    }
    onVisibleChanged: {
        if (root.visible) {
            if (!powerGetProc.running)
                powerGetProc.running = true;

            root.refreshToggleStates();
            if (root.player)
                root.player.positionChanged();

        }
    }
    Component.onCompleted: {
        powerGetProc.running = true;
        root.refreshToggleStates();
        if (root.player)
            root.player.positionChanged();

    }
    Component.onDestruction: {
        nightLightProc.running = false;
    }

    Timer {
        interval: 500
        running: root.isPlaying && (root.tabActive || root.visible)
        repeat: true
        onTriggered: {
            if (root.player)
                root.player.positionChanged();

        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: {
            var n = new Date();
            if (n.getDate() !== root.currentDate.getDate() || n.getMonth() !== root.currentDate.getMonth())
                root.currentDate = n;

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
        id: powerSetProc

        command: []
    }

    Process {
        id: nightLightProc

        command: []
    }

    Process {
        id: runCaffeineProc

        command: [
            "bash", "-c",
            "if [ -f \"$HOME/.config/hypr/scripts/caffeine.sh\" ]; then bash \"$HOME/.config/hypr/scripts/caffeine.sh\"; elif pidof hypridle >/dev/null 2>&1; then pkill hypridle; else nohup hypridle >/dev/null 2>&1 & fi"
        ]
        running: false
        onExited: {
            running = false;
            checkCaffeineProc.running = true;
        }
    }

    Process {
        id: runGameModeProc

        command: [
            "bash", "-c",
            "if [ -f \"$HOME/.config/hypr/scripts/gamemode.sh\" ]; then bash \"$HOME/.config/hypr/scripts/gamemode.sh\"; elif [ -f /tmp/gamemode_on ]; then rm -f /tmp/gamemode_on && hyprctl reload; else touch /tmp/gamemode_on && hyprctl reload; fi"
        ]
        running: false
        onExited: {
            running = false;
            checkGameModeProc.running = true;
        }
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
            if (!powerGetProc.running)
                powerGetProc.running = true;

            root.refreshToggleStates();
        }
    }

    CardEntrance {
        id: playerCardEntrance

        active: root.tabActive
        delay: 30
        duration: 420
        startOffsetY: 20
        startScale: 0.94
        overshoot: 1.12
    }

    CardEntrance {
        id: centerColEntrance

        active: root.tabActive
        delay: 90
        duration: 420
        startOffsetY: 20
        startScale: 0.94
        overshoot: 1.12
    }

    CardEntrance {
        id: tasksCardEntrance

        active: root.tabActive
        delay: 150
        duration: 420
        startOffsetY: 20
        startScale: 0.94
        overshoot: 1.12
    }

    Rectangle {
        id: playerCard

        visible: !root.tasksExpanded
        Layout.fillHeight: true
        Layout.preferredWidth: visible ? 260 : 0
        radius: Config.effectiveGeneralRadius
        color: root.surface
        opacity: playerCardEntrance.opacity
        scale: playerCardEntrance.scale

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                spacing: 6

                ThemedIcon {
                    id: playIcon

                    source: (root.player && root.player.identity) ? PlayerService.getAppIcon(root.player.identity) : ""
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    size: 28
                    color: root.color1
                    fallbackGlyph: "music_note"
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
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
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

                    property real playerSeek: (root.player && root.player.length > 0) ? Math.max(0, Math.min(1, (root.player.position || 0) / root.player.length)) : 0

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
                            root.player.positionChanged();
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
                            color: Colors.cfg.surfaceContainerLowest
                            border.color: Qt.alpha(root.color1, 0.3)

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width - 20
                                height: parent.height - 20
                                radius: width / 2
                                color: "transparent"
                                border.color: Qt.alpha(root.textBright, 0.08)
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
                                visible: root.artUrl !== "" && albumImg.status === Image.Ready
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: root.surfaceContainer
                                visible: root.artUrl === "" || albumImg.status !== Image.Ready

                                Text {
                                    anchors.centerIn: parent
                                    text: "music_note"
                                    color: root.color1
                                    font.pixelSize: 32
                                    font.family: "Material Symbols Rounded"
                                }

                            }

                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: 18
                            height: 18
                            radius: 9
                            color: Colors.cfg.surfaceContainerLowest
                            border.color: root.textBright
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

        transform: Translate {
            y: playerCardEntrance.offsetY
        }

    }

    ColumnLayout {
        id: centerColumn

        visible: !root.tasksExpanded
        Layout.fillHeight: true
        Layout.preferredWidth: visible ? 0 : 0
        Layout.fillWidth: visible
        spacing: 10
        opacity: centerColEntrance.opacity
        scale: centerColEntrance.scale

        Rectangle {
            id: calendarCard

            property string calendarViewMode: "monthly"
            property bool monthPickerOpen: false
            property int pickerYear: root.displayedYear

            function weekStartDate() {
                var d = new Date(root.displayedYear, root.displayedMonth, root.selectedDay);
                var day = d.getDay();
                if (Config.cfg && Config.cfg.weekStartsOnMonday) {
                    day = (day + 6) % 7;
                }
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

            function getEarliestWeekTaskHour() {
                var earliestH = 24;
                var earliestM = 60;
                for (var i = 0; i < 7; i++) {
                    var tasks = getTasksForWeekDay(i);
                    for (var j = 0; j < tasks.length; j++) {
                        var h = taskStartHour(tasks[j]);
                        if (h >= 0) {
                            var m = taskStartMinute(tasks[j]);
                            if (h < earliestH || (h === earliestH && m < earliestM)) {
                                earliestH = h;
                                earliestM = m;
                            }
                        }
                    }
                }
                if (earliestH < 24)
                    return earliestH + (earliestM / 60);

                return -1;
            }

            function scrollToFirstTask() {
                if (typeof weekScrollView === "undefined" || !weekScrollView)
                    return ;

                var earliest = getEarliestWeekTaskHour();
                var targetHour = earliest >= 0 ? earliest : 8;
                var targetY = Math.max(0, Math.floor(targetHour) * 36);
                var maxY = Math.max(0, weekScrollView.contentHeight - weekScrollView.height);
                weekScrollView.contentItem.contentY = Math.min(maxY, targetY);
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
                var sm = root.getShortMonthName(s.getMonth());
                var em = root.getShortMonthName(e.getMonth());
                if (s.getMonth() === e.getMonth())
                    return sm + " " + s.getDate() + " – " + e.getDate() + ", " + e.getFullYear();

                return sm + " " + s.getDate() + " – " + em + " " + e.getDate() + ", " + e.getFullYear();
            }

            onCalendarViewModeChanged: {
                if (calendarViewMode === "weekly")
                    Qt.callLater(scrollToFirstTask);

            }
            Layout.fillWidth: true
            Layout.preferredHeight: 315
            radius: Config.effectiveGeneralRadius
            color: root.surface
            clip: true

            ColumnLayout {
                id: calendarArea

                anchors.fill: parent
                anchors.margins: 14
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        radius: 8
                        color: monthTitleH.hovered ? Qt.alpha(root.primary, 0.1) : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 2
                            spacing: 4

                            Text {
                                text: calendarCard.calendarViewMode === "monthly" ? (root.getMonthName(root.displayedMonth) + " " + root.displayedYear) : calendarCard.weekRangeLabel()
                                font.pixelSize: 11
                                font.family: "GeistMono Nerd Font Propo"
                                font.bold: true
                                color: root.text
                            }

                            Text {
                                visible: calendarCard.calendarViewMode === "monthly"
                                text: calendarCard.monthPickerOpen ? "arrow_drop_up" : "arrow_drop_down"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 16
                                color: root.primary
                            }

                            Item {
                                Layout.fillWidth: true
                            }
                        }

                        HoverHandler {
                            id: monthTitleH
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: calendarCard.calendarViewMode === "monthly" ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (calendarCard.calendarViewMode === "monthly") {
                                    calendarCard.pickerYear = root.displayedYear;
                                    calendarCard.monthPickerOpen = !calendarCard.monthPickerOpen;
                                }
                            }
                        }
                    }

                    Rectangle {
                        implicitHeight: 22
                        implicitWidth: todayText.implicitWidth + 14
                        radius: 11
                        color: todayH.hovered ? Qt.alpha(root.primary, 0.22) : Qt.alpha(root.primary, 0.1)
                        border.color: Qt.alpha(root.primary, 0.3)
                        border.width: 1

                        Text {
                            id: todayText
                            anchors.centerIn: parent
                            text: "Today"
                            font.pixelSize: 10
                            font.bold: true
                            font.family: "GeistMono Nerd Font Propo"
                            color: root.primary
                        }

                        HoverHandler {
                            id: todayH
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var now = new Date();
                                root.currentDate = now;
                                root.displayedMonth = now.getMonth();
                                root.displayedYear = now.getFullYear();
                                root.selectedDay = now.getDate();
                                calendarCard.monthPickerOpen = false;
                                if (calendarCard.calendarViewMode === "weekly")
                                    Qt.callLater(calendarCard.scrollToFirstTask);
                            }
                        }
                    }

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
                                    Qt.callLater(calendarCard.scrollToFirstTask);
                                }
                            }
                        }

                    }

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
                                    Qt.callLater(calendarCard.scrollToFirstTask);
                                }
                            }
                        }

                    }

                }

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
                                readonly property var workload: isValid ? (TaskService.tasks, TaskService.getTaskWorkloadOnDate(root.displayedYear, root.displayedMonth, dayNum)) : ({ "pending": 0, "completed": 0, "total": 0 })
                                readonly property int pendingCount: workload ? workload.pending : 0
                                readonly property int completedCount: workload ? workload.completed : 0
                                readonly property int totalCount: workload ? workload.total : 0

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
                                        anchors.verticalCenterOffset: totalCount > 0 ? -2 : 0
                                        text: isValid ? dayNum : ""
                                        font.pixelSize: 9
                                        font.bold: isToday || isSelected
                                        color: isSelected ? root.foreground : (isToday ? root.color1 : root.textMuted)
                                    }

                                    Row {
                                        visible: pendingCount >= 3
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: 2
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 2

                                        Rectangle {
                                            width: 3
                                            height: 3
                                            radius: 1.5
                                            color: isSelected ? root.foreground : root.color1
                                        }

                                        Rectangle {
                                            width: 3
                                            height: 3
                                            radius: 1.5
                                            color: isSelected ? root.foreground : root.color1
                                        }
                                    }

                                    Rectangle {
                                        visible: pendingCount >= 1 && pendingCount < 3
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: 2
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 3
                                        height: 3
                                        radius: 1.5
                                        color: isSelected ? root.foreground : root.color1
                                    }

                                    Rectangle {
                                        visible: pendingCount === 0 && completedCount > 0
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: 2
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 3
                                        height: 3
                                        radius: 1.5
                                        color: isSelected ? Qt.alpha(root.foreground, 0.5) : Qt.alpha(root.color1, 0.4)
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

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: calendarCard.calendarViewMode === "weekly"
                    clip: true

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

                    ScrollView {
                        id: weekScrollView

                        anchors.top: weekHeaderRow.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        clip: true
                        contentWidth: availableWidth
                        contentHeight: 24 * 36
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                        onVisibleChanged: {
                            if (visible)
                                Qt.callLater(calendarCard.scrollToFirstTask);

                        }
                        Component.onCompleted: {
                            if (calendarCard.calendarViewMode === "weekly")
                                Qt.callLater(calendarCard.scrollToFirstTask);

                        }

                        Item {
                            width: parent.width
                            height: 24 * 36
                            implicitHeight: 24 * 36

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
                                            if (root.clock24h) {
                                                return (index < 10 ? "0" : "") + index + ":00";
                                            } else {
                                                var h = index % 12 || 12;
                                                return h + (index < 12 ? "a" : "p");
                                            }
                                        }
                                        font.pixelSize: 8
                                        color: Qt.alpha(root.textMuted, 0.55)
                                        horizontalAlignment: Text.AlignRight
                                    }

                                }

                            }

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
                                            ToolTip.visible: weekTaskH.hovered
                                            ToolTip.text: {
                                                var range = TaskService.formatDisplayTime(modelData.startTime, root.clock24h);
                                                if (modelData.endTime)
                                                    range += " - " + TaskService.formatDisplayTime(modelData.endTime, root.clock24h);

                                                return modelData.text + (range ? " (" + range + ")" : "");
                                            }

                                            HoverHandler {
                                                id: weekTaskH
                                            }

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

            Rectangle {
                id: monthPickerOverlay

                anchors.fill: parent
                radius: calendarCard.radius
                color: root.surface
                visible: calendarCard.monthPickerOpen
                z: 20

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            implicitWidth: 26
                            implicitHeight: 26
                            radius: 13
                            color: prevYrH.hovered ? root.surfaceContainer : Qt.alpha(root.surfaceContainer, 0.6)
                            border.color: Qt.alpha(root.text, 0.12)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "arrow_back_ios_new"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 11
                                color: root.text
                            }

                            HoverHandler {
                                id: prevYrH
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: calendarCard.pickerYear--
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: calendarCard.pickerYear
                            font.family: "GeistMono Nerd Font Propo"
                            font.pixelSize: 14
                            font.bold: true
                            color: root.text
                        }

                        Rectangle {
                            implicitWidth: 26
                            implicitHeight: 26
                            radius: 13
                            color: nextYrH.hovered ? root.surfaceContainer : Qt.alpha(root.surfaceContainer, 0.6)
                            border.color: Qt.alpha(root.text, 0.12)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "arrow_forward_ios"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 11
                                color: root.text
                            }

                            HoverHandler {
                                id: nextYrH
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: calendarCard.pickerYear++
                            }
                        }

                        Rectangle {
                            implicitWidth: 26
                            implicitHeight: 26
                            radius: 13
                            color: closePickerH.hovered ? Qt.alpha(root.error, 0.15) : Qt.alpha(root.text, 0.05)

                            Text {
                                anchors.centerIn: parent
                                text: "close"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 15
                                color: closePickerH.hovered ? root.error : root.textMuted
                            }

                            HoverHandler {
                                id: closePickerH
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: calendarCard.monthPickerOpen = false
                            }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: 4
                        rowSpacing: 8
                        columnSpacing: 8

                        Repeater {
                            model: root.shortMonthNames

                            delegate: Rectangle {
                                required property string modelData
                                required property int index

                                readonly property bool isSelected: index === root.displayedMonth && calendarCard.pickerYear === root.displayedYear
                                readonly property bool isCurrentMonth: index === root.currentDate.getMonth() && calendarCard.pickerYear === root.currentDate.getFullYear()

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 10
                                color: isSelected ? root.primary : (isCurrentMonth ? Qt.alpha(root.primary, 0.15) : (mCellH.hovered ? root.surfaceContainer : Qt.alpha(root.surfaceContainer, 0.35)))
                                border.color: isCurrentMonth && !isSelected ? root.primary : (isSelected ? root.primary : Qt.alpha(root.text, 0.08))
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.family: "Google Sans"
                                    font.pixelSize: 11
                                    font.bold: isSelected || isCurrentMonth
                                    color: isSelected ? root.foreground : (isCurrentMonth ? root.primary : root.text)
                                }

                                HoverHandler {
                                    id: mCellH
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.displayedMonth = index;
                                        root.displayedYear = calendarCard.pickerYear;
                                        root.selectedDay = 1;
                                        calendarCard.monthPickerOpen = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }

        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            DashboardToggleRow {
                Layout.fillWidth: true
                Layout.preferredHeight: 46

                DashboardQuickToggle {
                    active: WifiService.wifiEnabled
                    icon: active ? "network_wifi_3_bar" : "signal_wifi_off"
                    onClicked: WifiService.toggleWifi()
                }

                DashboardQuickToggle {
                    active: BluetoothService.bluetoothEnabled
                    icon: active ? "bluetooth" : "bluetooth_disabled"
                    onClicked: BluetoothService.togglePower()
                }

                DashboardQuickToggle {
                    id: caffeine
                    active: root.caffeineActive
                    icon: "coffee"
                    onClicked: root.toggleCaffeine()
                }

                DashboardQuickToggle {
                    active: root.nightLightActive
                    icon: active ? "bedtime" : "bedtime_off"
                    onClicked: root.toggleNightLight()
                }
            }

            DashboardToggleRow {
                Layout.fillWidth: true
                Layout.preferredHeight: 46

                DashboardQuickToggle {
                    id: generic1
                    active: root.gameModeActive
                    icon: "gamepad"
                    onClicked: root.toggleGameMode()
                }

                DashboardQuickToggle {
                    id: generic2
                    active: !AudioService.micMuted
                    icon: active ? "mic" : "mic_off"
                    onClicked: AudioService.toggleMicMute()
                }

                DashboardQuickToggle {
                    id: generic3
                    active: (Config.cfg && Config.cfg.alertsPopups !== undefined) ? !Config.cfg.alertsPopups : false
                    icon: active ? "do_not_disturb_on" : "do_not_disturb_off"
                    onClicked: {
                        Config.cfg.alertsPopups = !Config.cfg.alertsPopups;
                        Config.save();
                    }
                }

                DashboardQuickToggle {
                    id: generic4
                    active: RecorderService.isRecording
                    activeBgColor: Colors.cfg.error
                    icon: active ? "stop" : "screen_record"
                    onClicked: RecorderService.toggleRecording()
                }
            }
        }

        transform: Translate {
            y: centerColEntrance.offsetY
        }

    }

    RowLayout {
        Layout.fillHeight: true
        Layout.fillWidth: true
        spacing: 10
        opacity: tasksCardEntrance.opacity
        scale: tasksCardEntrance.scale

        Rectangle {
            id: tasksPanel

            readonly property bool is24: root.clock24h
            property string taskStartPeriod: "AM"
            property string taskEndPeriod: "AM"
            property string taskScope: "day"
            property string activeKanbanCol: "todo"
            property string taskSearch: ""
            property var delConfirmId: null
            readonly property var dayWorkload: (TaskService.tasks, TaskService.getTaskWorkloadOnDate(root.displayedYear, root.displayedMonth, root.selectedDay))
            readonly property int totalDayCount: dayWorkload ? dayWorkload.total : 0
            readonly property int pendingDayCount: dayWorkload ? dayWorkload.pending : 0
            readonly property int completedDayCount: dayWorkload ? dayWorkload.completed : 0
            readonly property int overdueDayCount: {
                var count = 0;
                var list = taskScope === "all" ? TaskService.allTasks : TaskService.getTasksForDate(root.displayedYear, root.displayedMonth, root.selectedDay);
                for (var i = 0; i < list.length; i++) {
                    if (TaskService.isOverdue(list[i])) count++;
                }
                return count;
            }

            function clearCompleted() {
                var remaining = TaskService.allTasks.filter(function(t) { return !t.done; });
                TaskService.allTasks = remaining;
                TaskService.saveTasks();
            }

            function getTasksForColumn(colKey) {
                var list = getFilteredTasks();
                return list.filter(function(t) {
                    var c = t.column || (t.done ? "done" : "todo");
                    return c === colKey;
                });
            }

            property string taskPriority: "none"
            property var editingTaskId: null
            property string editTaskText: ""
            property string editTaskDate: ""
            property string editTaskStartTime: ""
            property string editTaskEndTime: ""
            property string editTaskStartPeriod: "AM"
            property string editTaskEndPeriod: "AM"
            property bool editTaskNotify: false
            property string editTaskPriority: "none"

            function startEditing(task) {
                editingTaskId = task.id;
                editTaskText = task.text;
                editTaskDate = (task.date !== undefined && task.date !== null) ? task.date : "";
                editTaskNotify = !!task.notify;
                editTaskPriority = task.priority || "none";
                if (is24) {
                    editTaskStartTime = task.startTime || "";
                    editTaskEndTime = task.endTime || "";
                } else {
                    var sConv = convertFrom24Hour(task.startTime || "");
                    editTaskStartTime = sConv.time;
                    editTaskStartPeriod = sConv.period;
                    var eConv = convertFrom24Hour(task.endTime || "");
                    editTaskEndTime = eConv.time;
                    editTaskEndPeriod = eConv.period;
                }
            }

            function cancelEditing() {
                editingTaskId = null;
            }

            function saveEditing() {
                if (!editingTaskId)
                    return ;

                var trimmed = editTaskText.trim();
                if (trimmed.length === 0)
                    return ;

                var finalStart = "";
                var finalEnd = "";
                if (is24) {
                    finalStart = normalize24Hour(editTaskStartTime);
                    finalEnd = normalize24Hour(editTaskEndTime);
                } else {
                    finalStart = convertTo24Hour(editTaskStartTime, editTaskStartPeriod);
                    finalEnd = convertTo24Hour(editTaskEndTime, editTaskEndPeriod);
                }
                var finalNotify = (editTaskDate !== "" && finalStart !== "" && editTaskNotify);

                TaskService.updateTask(editingTaskId, trimmed, editTaskDate, finalStart, finalEnd, finalNotify, editTaskPriority);
                editingTaskId = null;
            }

            function getFilteredTasks() {
                var list = [];
                if (root.tasksExpanded && taskScope === "all") {
                    list = TaskService.allTasks.slice();
                    list.sort(function(a, b) {
                        if (a.done !== b.done) return a.done ? 1 : -1;
                        if (!a.done) {
                            var pwA = TaskService.getPriorityWeight(a.priority);
                            var pwB = TaskService.getPriorityWeight(b.priority);
                            if (pwA !== pwB) return pwB - pwA;
                        }
                        var dateA = a.date || "9999-99-99";
                        var dateB = b.date || "9999-99-99";
                        if (dateA !== dateB) return dateA.localeCompare(dateB);
                        var timeA = a.startTime || "99:99";
                        var timeB = b.startTime || "99:99";
                        return timeA.localeCompare(timeB);
                    });
                } else {
                    list = TaskService.getTasksForDate(root.displayedYear, root.displayedMonth, root.selectedDay);
                }

                if (taskSearch.trim().length > 0) {
                    var q = taskSearch.trim().toLowerCase();
                    list = list.filter(function(t) {
                        return (t.text && t.text.toLowerCase().indexOf(q) !== -1) ||
                               (t.date && t.date.indexOf(q) !== -1);
                    });
                }

                return list;
            }

            readonly property bool hasTimeError: {
                if (!taskInput.text.trim())
                    return false;

                var s = taskStartTimeInput.text.trim();
                var e = taskEndTimeInput.text.trim();
                if (s.length === 0 && e.length === 0)
                    return false;

                if (s.length === 0 && e.length > 0)
                    return true;

                if (s.length > 0 && e.length > 0) {
                    var start24 = getInternalTime(s, taskStartPeriod);
                    var end24 = getInternalTime(e, taskEndPeriod);
                    if (start24.length > 0 && end24.length > 0)
                        return end24 <= start24;

                }
                return false;
            }

            function normalize24Hour(value) {
                if (!value)
                    return "";

                var clean = value.trim();
                if (clean.length === 0)
                    return "";

                var parts = clean.split(":");
                var hour = parseInt(parts[0], 10);
                if (isNaN(hour))
                    return "";

                hour = Math.max(0, Math.min(23, hour));
                var minute = 0;
                if (parts.length > 1 && parts[1].trim() !== "") {
                    minute = parseInt(parts[1], 10);
                    if (isNaN(minute))
                        minute = 0;

                    minute = Math.max(0, Math.min(59, minute));
                }
                return (hour < 10 ? "0" : "") + hour + ":" + (minute < 10 ? "0" : "") + minute;
            }

            function normalize12Hour(value) {
                if (!value)
                    return "";

                var clean = value.trim();
                if (clean.length === 0)
                    return "";

                var parts = clean.split(":");
                var hour = parseInt(parts[0], 10);
                if (isNaN(hour))
                    return "";

                hour = Math.max(1, Math.min(12, hour));
                var minute = 0;
                if (parts.length > 1 && parts[1].trim() !== "") {
                    minute = parseInt(parts[1], 10);
                    if (isNaN(minute))
                        minute = 0;

                    minute = Math.max(0, Math.min(59, minute));
                }
                return (hour < 10 ? "0" : "") + hour + ":" + (minute < 10 ? "0" : "") + minute;
            }

            function normalizeInput(value) {
                return is24 ? normalize24Hour(value) : normalize12Hour(value);
            }

            function convertTo24Hour(value, period) {
                var normalized = normalize12Hour(value);
                if (normalized.length === 0)
                    return "";

                var parts = normalized.split(":");
                var hour = parseInt(parts[0], 10);
                var minute = parseInt(parts[1], 10);
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
                var hour = parseInt(parts[0], 10);
                var minute = parseInt(parts[1], 10);
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

            function getInternalTime(text, period) {
                if (!text || text.trim().length === 0)
                    return "";

                if (is24)
                    return normalize24Hour(text);
                else
                    return convertTo24Hour(text, period);
            }

            function prepareTimes() {
                if (is24) {
                    taskStartTimeInput.text = normalize24Hour(taskStartTimeInput.text);
                    taskEndTimeInput.text = normalize24Hour(taskEndTimeInput.text);
                    taskStartTimeInput.internalTime = taskStartTimeInput.text;
                    taskEndTimeInput.internalTime = taskEndTimeInput.text;
                } else {
                    taskStartTimeInput.text = normalize12Hour(taskStartTimeInput.text);
                    taskEndTimeInput.text = normalize12Hour(taskEndTimeInput.text);
                    if (taskStartPeriod === "PM")
                        taskEndPeriod = "PM";

                    taskStartTimeInput.internalTime = convertTo24Hour(taskStartTimeInput.text, taskStartPeriod);
                    taskEndTimeInput.internalTime = convertTo24Hour(taskEndTimeInput.text, taskEndPeriod);
                }
            }

            onIs24Changed: {
                if (taskStartTimeInput.internalTime) {
                    if (is24) {
                        taskStartTimeInput.text = taskStartTimeInput.internalTime;
                    } else {
                        var sConv = convertFrom24Hour(taskStartTimeInput.internalTime);
                        taskStartTimeInput.text = sConv.time;
                        taskStartPeriod = sConv.period;
                    }
                }
                if (taskEndTimeInput.internalTime) {
                    if (is24) {
                        taskEndTimeInput.text = taskEndTimeInput.internalTime;
                    } else {
                        var eConv = convertFrom24Hour(taskEndTimeInput.internalTime);
                        taskEndTimeInput.text = eConv.time;
                        taskEndPeriod = eConv.period;
                    }
                }
            }
            onTaskStartPeriodChanged: {
                if (!is24 && taskStartPeriod === "PM") {
                    taskEndPeriod = "PM";
                    taskEndTimeInput.internalTime = convertTo24Hour(taskEndTimeInput.text, taskEndPeriod);
                }
            }
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Config.effectiveGeneralRadius
            color: root.surface

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: {
                                if (root.tasksExpanded) {
                                    return tasksPanel.taskScope === "all" ? qsTr("All Tasks") : ("Tasks (" + root.formatDateByConfig(new Date(root.displayedYear, root.displayedMonth, root.selectedDay)) + ")");
                                }
                                var d = new Date(root.displayedYear, root.displayedMonth, root.selectedDay);
                                return "Tasks (" + root.formatDateByConfig(d) + ")";
                            }
                            font.family: "Google Sans Flex, Google Sans, sans-serif"
                            font.pixelSize: root.tasksExpanded ? 15 : 13
                            font.weight: Font.DemiBold
                            color: root.textColor
                        }

                        Text {
                            text: root.tasksExpanded ? (tasksPanel.taskScope === "all" ? qsTr("Showing all saved tasks across all dates") : qsTr("Expanded view • tasks for selected day")) : qsTr("Tasks for the selected day")
                            font.family: "Google Sans"
                            font.pixelSize: 9
                            color: root.textMuted
                        }
                    }

                    // In expanded mode: Quick Day Jumper buttons (when scope is "day")
                    RowLayout {
                        visible: root.tasksExpanded && tasksPanel.taskScope === "day"
                        spacing: 4

                        Rectangle {
                            implicitWidth: 26
                            implicitHeight: 28
                            radius: 8
                            color: prevDayH.hovered ? Qt.alpha(root.color1, 0.15) : Qt.alpha(root.textColor, 0.05)
                            border.width: 1
                            border.color: Qt.alpha(root.textColor, 0.08)
                            Text { anchors.centerIn: parent; text: "chevron_left"; font.family: "Material Symbols Rounded"; font.pixelSize: 15; color: root.textColor }
                            HoverHandler { id: prevDayH }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var d = new Date(root.displayedYear, root.displayedMonth, root.selectedDay - 1);
                                    root.displayedYear = d.getFullYear();
                                    root.displayedMonth = d.getMonth();
                                    root.selectedDay = d.getDate();
                                }
                            }
                        }

                        Rectangle {
                            implicitWidth: todayJumpText.implicitWidth + 14
                            implicitHeight: 28
                            radius: 8
                            color: todayJumpH.hovered ? Qt.alpha(root.color1, 0.15) : Qt.alpha(root.textColor, 0.05)
                            border.width: 1
                            border.color: Qt.alpha(root.textColor, 0.08)
                            Text {
                                id: todayJumpText
                                anchors.centerIn: parent
                                text: qsTr("Today")
                                font.family: "Google Sans"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: root.textColor
                            }
                            HoverHandler { id: todayJumpH }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var now = new Date();
                                    root.displayedYear = now.getFullYear();
                                    root.displayedMonth = now.getMonth();
                                    root.selectedDay = now.getDate();
                                }
                            }
                        }

                        Rectangle {
                            implicitWidth: 26
                            implicitHeight: 28
                            radius: 8
                            color: nextDayH.hovered ? Qt.alpha(root.color1, 0.15) : Qt.alpha(root.textColor, 0.05)
                            border.width: 1
                            border.color: Qt.alpha(root.textColor, 0.08)
                            Text { anchors.centerIn: parent; text: "chevron_right"; font.family: "Material Symbols Rounded"; font.pixelSize: 15; color: root.textColor }
                            HoverHandler { id: nextDayH }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var d = new Date(root.displayedYear, root.displayedMonth, root.selectedDay + 1);
                                    root.displayedYear = d.getFullYear();
                                    root.displayedMonth = d.getMonth();
                                    root.selectedDay = d.getDate();
                                }
                            }
                        }
                    }

                    // In expanded mode: Scope switcher (Day vs All)
                    Rectangle {
                        visible: root.tasksExpanded
                        implicitWidth: scopeRow.implicitWidth + 8
                        implicitHeight: 30
                        radius: 10
                        color: Qt.alpha(root.textColor, 0.05)
                        border.width: 1
                        border.color: Qt.alpha(root.textColor, 0.08)

                        RowLayout {
                            id: scopeRow
                            anchors.centerIn: parent
                            spacing: 2

                            Rectangle {
                                implicitWidth: dayScopeText.implicitWidth + 14
                                implicitHeight: 24
                                radius: 8
                                color: tasksPanel.taskScope === "day" ? root.color1 : "transparent"

                                Text {
                                    id: dayScopeText
                                    anchors.centerIn: parent
                                    text: qsTr("Day")
                                    font.family: "Google Sans"
                                    font.pixelSize: 10
                                    font.weight: tasksPanel.taskScope === "day" ? Font.DemiBold : Font.Normal
                                    color: tasksPanel.taskScope === "day" ? root.foreground : root.textColor
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: tasksPanel.taskScope = "day"
                                }
                            }

                            Rectangle {
                                implicitWidth: allScopeText.implicitWidth + 14
                                implicitHeight: 24
                                radius: 8
                                color: tasksPanel.taskScope === "all" ? root.color1 : "transparent"

                                Text {
                                    id: allScopeText
                                    anchors.centerIn: parent
                                    text: qsTr("All")
                                    font.family: "Google Sans"
                                    font.pixelSize: 10
                                    font.weight: tasksPanel.taskScope === "all" ? Font.DemiBold : Font.Normal
                                    color: tasksPanel.taskScope === "all" ? root.foreground : root.textColor
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: tasksPanel.taskScope = "all"
                                }
                            }
                        }
                    }


                    // Count Badge
                    Rectangle {
                        implicitWidth: countBadgeText.implicitWidth + 12
                        implicitHeight: 24
                        radius: 12
                        color: Qt.alpha(root.color1, 0.14)

                        Text {
                            id: countBadgeText
                            anchors.centerIn: parent
                            text: tasksPanel.taskScope === "all" && root.tasksExpanded ? TaskService.allTasks.length : tasksPanel.totalDayCount
                            font.family: "Google Sans"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            color: root.color1
                        }
                    }

                    // Open TODO.md in editor
                    Rectangle {
                        id: openTodoBtn
                        implicitWidth: 30
                        implicitHeight: 30
                        radius: 10
                        color: openTodoHover.hovered ? Qt.alpha(root.color1, 0.18) : Qt.alpha(root.textColor, 0.05)
                        border.width: 1
                        border.color: openTodoHover.hovered ? Qt.alpha(root.color1, 0.4) : Qt.alpha(root.textColor, 0.08)
                        scale: openTodoHover.hovered ? 1.08 : 1.0
                        ToolTip.visible: openTodoHover.hovered
                        ToolTip.text: qsTr("Open TODO.md in editor")

                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "description"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 16
                            color: openTodoHover.hovered ? root.color1 : root.textColor
                        }

                        HoverHandler { id: openTodoHover }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: TaskService.openTodoFile()
                        }
                    }

                    // Expand / Collapse icon button
                    Rectangle {
                        id: expandBtn
                        implicitWidth: 30
                        implicitHeight: 30
                        radius: 10
                        color: root.tasksExpanded ? root.color1 : (expandBtnHover.hovered ? Qt.alpha(root.textColor, 0.1) : Qt.alpha(root.textColor, 0.05))
                        border.width: root.tasksExpanded ? 0 : 1
                        border.color: root.tasksExpanded ? root.color1 : (expandBtnHover.hovered ? Qt.alpha(root.textColor, 0.15) : Qt.alpha(root.textColor, 0.08))
                        scale: expandBtnHover.hovered ? 1.08 : 1.0
                        ToolTip.visible: expandBtnHover.hovered
                        ToolTip.text: root.tasksExpanded ? qsTr("Collapse tasks view") : qsTr("Expand tasks view")

                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: root.tasksExpanded ? "close_fullscreen" : "open_in_full"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 16
                            color: root.tasksExpanded ? root.foreground : (expandBtnHover.hovered ? root.color1 : root.textColor)
                        }

                        HoverHandler { id: expandBtnHover }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.tasksExpanded = !root.tasksExpanded;
                            }
                        }
                    }
                }

                Rectangle {
                    readonly property bool showTimeOptions: taskInput.text.trim().length > 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: showTimeOptions ? 98 : 52
                    radius: Math.round(Config.effectiveGeneralRadius * 0.75)
                    color: root.surface
                    border.width: taskInput.activeFocus || taskStartTimeInput.activeFocus || taskEndTimeInput.activeFocus ? 2 : 1
                    border.color: taskInput.activeFocus || taskStartTimeInput.activeFocus || taskEndTimeInput.activeFocus ? root.color1 : Qt.alpha(root.textColor, 0.08)
                    clip: true

                    Behavior on Layout.preferredHeight {
                        NumberAnimation {
                            duration: 240
                            easing.type: Easing.OutCubic
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                radius: 10
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
                                    font.pixelSize: 11
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
                                        font.pixelSize: 11
                                        color: root.textMuted
                                        visible: !taskInput.text && !taskInput.activeFocus
                                    }

                                }

                            }

                            Rectangle {
                                id: priorityBtn
                                Layout.minimumWidth: 30
                                Layout.maximumWidth: 64
                                Layout.preferredWidth: tasksPanel.taskPriority !== "none" ? 56 : 30
                                Layout.preferredHeight: 30
                                radius: 10
                                color: {
                                    if (tasksPanel.taskPriority === "high") return Qt.alpha(Colors.cfg.error, 0.16);
                                    if (tasksPanel.taskPriority === "medium") return Qt.alpha(Colors.cfg.warning, 0.16);
                                    if (tasksPanel.taskPriority === "low") return Qt.alpha(Colors.cfg.secondary, 0.16);
                                    return Qt.alpha(root.textColor, 0.04);
                                }
                                border.width: 1
                                border.color: {
                                    if (tasksPanel.taskPriority === "high") return Qt.alpha(Colors.cfg.error, 0.5);
                                    if (tasksPanel.taskPriority === "medium") return Qt.alpha(Colors.cfg.warning, 0.5);
                                    if (tasksPanel.taskPriority === "low") return Qt.alpha(Colors.cfg.secondary, 0.5);
                                    return Qt.alpha(root.textColor, 0.08);
                                }
                                ToolTip.visible: priorityHover.hovered
                                ToolTip.text: qsTr("Priority: ") + TaskService.getPriorityLabel(tasksPanel.taskPriority)

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 3

                                    Text {
                                        text: "flag"
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 15
                                        color: TaskService.getPriorityColor(tasksPanel.taskPriority)
                                    }

                                    Text {
                                        visible: tasksPanel.taskPriority !== "none"
                                        text: tasksPanel.taskPriority === "high" ? "HIGH" : (tasksPanel.taskPriority === "medium" ? "MED" : "LOW")
                                        font.family: "Google Sans"
                                        font.pixelSize: 9
                                        font.weight: Font.Bold
                                        color: TaskService.getPriorityColor(tasksPanel.taskPriority)
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        tasksPanel.taskPriority = TaskService.getNextPriority(tasksPanel.taskPriority);
                                    }
                                }

                                HoverHandler {
                                    id: priorityHover
                                }

                                Behavior on Layout.preferredWidth {
                                    NumberAnimation {
                                        duration: 160
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 30
                                Layout.preferredHeight: 30
                                radius: 15
                                color: tasksPanel.hasTimeError ? Qt.alpha(root.error, 0.4) : root.color1

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰐕"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 18
                                    color: tasksPanel.hasTimeError ? Qt.alpha(root.foreground, 0.6) : root.foreground
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: tasksPanel.hasTimeError ? Qt.ForbiddenCursor : Qt.PointingHandCursor
                                    onClicked: root.submitNewTask()
                                }

                            }

                        }

                        RowLayout {
                            id: taskOptionsRow

                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            spacing: 6
                            visible: opacity > 0
                            opacity: parent.parent.showTimeOptions ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 80
                                Layout.preferredWidth: 86
                                Layout.maximumWidth: 120
                                Layout.preferredHeight: 32
                                radius: 10
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
                                        font.pixelSize: 10
                                        font.weight: Font.Medium
                                        color: root.textColor
                                        clip: true
                                        selectByMouse: true
                                        maximumLength: 5
                                        inputMethodHints: Qt.ImhTime
                                        onEditingFinished: {
                                            text = tasksPanel.normalizeInput(text);
                                            internalTime = tasksPanel.getInternalTime(text, tasksPanel.taskStartPeriod);
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
                                            regularExpression: tasksPanel.is24 ? /^$|^([0-1]?[0-9]|2[0-3])(:([0-5]?[0-9])?)?$/ : /^$|^([1-9]|1[0-2])(:([0-5]?[0-9])?)?$/
                                        }

                                    }

                                    Rectangle {
                                        visible: !tasksPanel.is24
                                        Layout.preferredWidth: visible ? 32 : 0
                                        Layout.minimumWidth: visible ? 32 : 0
                                        Layout.maximumWidth: visible ? 32 : 0
                                        Layout.preferredHeight: 24
                                        radius: 8
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
                                                if (tasksPanel.taskStartPeriod === "PM") {
                                                    tasksPanel.taskEndPeriod = "PM";
                                                    taskEndTimeInput.internalTime = tasksPanel.convertTo24Hour(taskEndTimeInput.text, tasksPanel.taskEndPeriod);
                                                }
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
                                Layout.preferredHeight: 32
                                radius: 10
                                color: tasksPanel.hasTimeError ? Qt.alpha(root.error, 0.12) : (taskEndTimeInput.activeFocus ? Qt.alpha(root.color1, 0.08) : Qt.alpha(root.textColor, 0.04))
                                border.width: tasksPanel.hasTimeError || taskEndTimeInput.activeFocus ? 2 : 1
                                border.color: tasksPanel.hasTimeError ? root.error : (taskEndTimeInput.activeFocus ? root.color1 : Qt.alpha(root.textColor, 0.08))
                                clip: true
                                ToolTip.visible: tasksPanel.hasTimeError && (endBoxHover.hovered || taskEndTimeInput.activeFocus)
                                ToolTip.text: taskStartTimeInput.text.trim().length === 0 ? "Start time required" : "End time must be after start time"

                                HoverHandler {
                                    id: endBoxHover
                                }

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
                                        font.pixelSize: 10
                                        font.weight: Font.Medium
                                        color: root.textColor
                                        clip: true
                                        selectByMouse: true
                                        maximumLength: 5
                                        inputMethodHints: Qt.ImhTime
                                        onEditingFinished: {
                                            text = tasksPanel.normalizeInput(text);
                                            internalTime = tasksPanel.getInternalTime(text, tasksPanel.taskEndPeriod);
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
                                            regularExpression: tasksPanel.is24 ? /^$|^([0-1]?[0-9]|2[0-3])(:([0-5]?[0-9])?)?$/ : /^$|^([1-9]|1[0-2])(:([0-5]?[0-9])?)?$/
                                        }

                                    }

                                    Rectangle {
                                        visible: !tasksPanel.is24
                                        Layout.preferredWidth: visible ? 32 : 0
                                        Layout.minimumWidth: visible ? 32 : 0
                                        Layout.maximumWidth: visible ? 32 : 0
                                        Layout.preferredHeight: 24
                                        radius: 8
                                        color: tasksPanel.taskStartPeriod === "PM" ? Qt.alpha(root.color1, 0.22) : Qt.alpha(root.color1, 0.14)
                                        ToolTip.visible: endPeriodHover.hovered && tasksPanel.taskStartPeriod === "PM"
                                        ToolTip.text: "End period must be PM when start is PM"

                                        Text {
                                            anchors.centerIn: parent
                                            text: tasksPanel.taskEndPeriod
                                            font.family: "Google Sans"
                                            font.pixelSize: 8
                                            font.weight: Font.DemiBold
                                            color: root.color1
                                        }

                                        HoverHandler {
                                            id: endPeriodHover
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: tasksPanel.taskStartPeriod === "PM" ? Qt.ForbiddenCursor : Qt.PointingHandCursor
                                            onClicked: {
                                                if (tasksPanel.taskStartPeriod === "PM")
                                                    tasksPanel.taskEndPeriod = "PM";
                                                else
                                                    tasksPanel.taskEndPeriod = tasksPanel.taskEndPeriod === "AM" ? "PM" : "AM";
                                                taskEndTimeInput.internalTime = tasksPanel.convertTo24Hour(taskEndTimeInput.text, tasksPanel.taskEndPeriod);
                                            }
                                        }

                                    }

                                }

                            }

                            Rectangle {
                                readonly property bool hasStartTime: taskStartTimeInput.text.trim().length > 0

                                visible: hasStartTime
                                opacity: hasStartTime ? 1 : 0
                                scale: hasStartTime ? 1 : 0.8

                                Layout.minimumWidth: 20
                                Layout.maximumWidth: 40
                                Layout.preferredWidth: 30
                                Layout.preferredHeight: 30
                                radius: 10
                                color: root.taskNotify ? root.color1 : Qt.alpha(root.textColor, 0.04)
                                border.width: 1
                                border.color: root.taskNotify ? root.color1 : Qt.alpha(root.textColor, 0.08)
                                ToolTip.visible: notifyHover.hovered
                                ToolTip.text: root.taskNotify ? qsTr("Notifications active") : qsTr("Notifications disabled")

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 180
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutBack
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: root.taskNotify ? "󰂚" : "󰂛"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 16
                                    color: root.taskNotify ? root.foreground : root.textMuted
                                }

                                HoverHandler {
                                    id: notifyHover
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.taskNotify = !root.taskNotify;
                                    }
                                }

                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                            }

                        }

                    }

                }

                // Kanban Column Switcher (Visible in Compact Mode for single-column focus)
                RowLayout {
                    id: compactColSwitcher
                    visible: !root.tasksExpanded
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? 32 : 0
                    opacity: visible ? 1 : 0
                    clip: true
                    spacing: 6

                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    Repeater {
                        model: [
                            { "key": "todo", "label": qsTr("To Do"), "icon": "format_list_bulleted", "color": root.textMuted },
                            { "key": "ongoing", "label": qsTr("Ongoing"), "icon": "hourglass_top", "color": Colors.cfg.warning },
                            { "key": "done", "label": qsTr("Done"), "icon": "check_circle", "color": (Colors.cfg.success ? Colors.cfg.success : root.color1) }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool isSelected: tasksPanel.activeKanbanCol === modelData.key
                            readonly property int colCount: {
                                var _ = TaskService.allTasks;
                                var __ = tasksPanel.taskScope;
                                var ___ = root.selectedDay;
                                var ____ = root.displayedMonth;
                                var _____ = root.displayedYear;
                                return tasksPanel.getTasksForColumn(modelData.key).length;
                            }

                            Layout.fillWidth: true
                            Layout.preferredHeight: 32
                            radius: 10
                            color: isSelected ? root.color1 : (colTabH.hovered ? Qt.alpha(root.textColor, 0.08) : Qt.alpha(root.textColor, 0.03))
                            border.width: 1
                            border.color: isSelected ? root.color1 : Qt.alpha(root.textColor, 0.08)

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 5

                                Text {
                                    text: modelData.icon
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 14
                                    color: isSelected ? root.foreground : root.textMuted
                                }

                                Text {
                                    text: modelData.label
                                    font.family: "Google Sans Flex, Google Sans, sans-serif"
                                    font.pixelSize: 11
                                    font.weight: isSelected ? Font.DemiBold : Font.Normal
                                    color: isSelected ? root.foreground : root.textMuted
                                }

                                Rectangle {
                                    implicitWidth: colBadgeText.implicitWidth + 8
                                    implicitHeight: 16
                                    radius: 8
                                    color: isSelected ? Qt.alpha(root.foreground, 0.22) : Qt.alpha(root.textColor, 0.06)

                                    Text {
                                        id: colBadgeText
                                        anchors.centerIn: parent
                                        text: colCount
                                        font.family: "Google Sans"
                                        font.pixelSize: 9
                                        font.weight: Font.Bold
                                        color: isSelected ? root.foreground : root.textMuted
                                    }
                                }
                            }

                            HoverHandler { id: colTabH }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: tasksPanel.activeKanbanCol = modelData.key
                            }
                        }
                    }
                }

                // Kanban Board View
                RowLayout {
                    id: kanbanBoardRow

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: root.tasksExpanded ? 10 : 0
                    Behavior on spacing { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

                    Repeater {
                        model: [
                            { "key": "todo", "label": qsTr("To Do"), "icon": "format_list_bulleted", "color": root.textMuted },
                            { "key": "ongoing", "label": qsTr("Ongoing"), "icon": "hourglass_top", "color": Colors.cfg.warning },
                            { "key": "done", "label": qsTr("Done"), "icon": "check_circle", "color": (Colors.cfg.success ? Colors.cfg.success : root.color1) }
                        ]

                        delegate: Rectangle {
                            id: kanbanColRoot
                            required property var modelData

                            property bool isDraggingCard: false

                            visible: root.tasksExpanded || tasksPanel.activeKanbanCol === modelData.key
                            opacity: visible ? 1 : 0
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: Math.round(Config.effectiveGeneralRadius * 0.8)
                            color: Qt.alpha(root.textColor, 0.03)
                            border.width: 1
                            border.color: Qt.alpha(root.textColor, 0.08)
                            z: isDraggingCard ? 50 : 1
                            clip: true

                            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                            readonly property var colTasks: {
                                var _ = TaskService.allTasks;
                                var __ = tasksPanel.taskScope;
                                var ___ = root.selectedDay;
                                var ____ = root.displayedMonth;
                                var _____ = root.displayedYear;
                                return tasksPanel.getTasksForColumn(modelData.key);
                            }

                            onColTasksChanged: {
                                isDraggingCard = false;
                                if (colFlickable) colFlickable.returnToBounds();
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: root.tasksExpanded ? 8 : 6
                                spacing: 6

                                // Column Header (Visible in expanded view where all 3 columns are shown)
                                RowLayout {
                                    visible: root.tasksExpanded
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: visible ? 28 : 0
                                    spacing: 5

                                    Text {
                                        text: kanbanColRoot.modelData.icon
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 15
                                        color: kanbanColRoot.modelData.color
                                    }

                                    Text {
                                        text: kanbanColRoot.modelData.label
                                        font.family: "Google Sans Flex, Google Sans, sans-serif"
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        color: root.textColor
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        implicitWidth: colCountText.implicitWidth + 8
                                        implicitHeight: 16
                                        radius: 8
                                        color: Qt.alpha(kanbanColRoot.modelData.color, 0.16)

                                        Text {
                                            id: colCountText
                                            anchors.centerIn: parent
                                            text: kanbanColRoot.colTasks.length
                                            font.family: "Google Sans"
                                            font.pixelSize: 9
                                            font.weight: Font.Bold
                                            color: kanbanColRoot.modelData.color
                                        }
                                    }

                                    Item { Layout.fillWidth: true }
                                }

                                // Scrollable Card List for this column
                                Flickable {
                                    id: colFlickable
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    contentWidth: width
                                    contentHeight: Math.max(height, kanbanCardCol.implicitHeight + 20)
                                    clip: true
                                    interactive: !kanbanColRoot.isDraggingCard
                                    flickableDirection: Flickable.VerticalFlick
                                    boundsBehavior: Flickable.StopAtBounds

                                    onContentHeightChanged: returnToBounds()

                                    ColumnLayout {
                                        id: kanbanCardCol
                                        x: 6
                                        y: 6
                                        width: Math.max(0, colFlickable.width - 12)
                                        spacing: 7

                                        Repeater {
                                            model: kanbanColRoot.colTasks

                                            delegate: Rectangle {
                                                id: kbCardRoot
                                                required property var modelData

                                                Component.onDestruction: {
                                                    if (kanbanColRoot) kanbanColRoot.isDraggingCard = false;
                                                }

                                                // Live reactive task reference directly bound to TaskService.allTasks
                                                readonly property var liveTask: {
                                                    var list = TaskService.allTasks;
                                                    for (var i = 0; i < list.length; i++) {
                                                        if (list[i].id === kbCardRoot.modelData.id) return list[i];
                                                    }
                                                    return kbCardRoot.modelData;
                                                }

                                                property bool isExpanded: false
                                                property bool isAddingSubtask: false
                                                readonly property bool isEditing: tasksPanel.editingTaskId === kbCardRoot.liveTask.id

                                                readonly property string currentColumn: kbCardRoot.liveTask.column || (kbCardRoot.liveTask.done ? "done" : "todo")
                                                readonly property bool hasSubtasks: !!kbCardRoot.liveTask.subtasks && Array.isArray(kbCardRoot.liveTask.subtasks) && kbCardRoot.liveTask.subtasks.length > 0
                                                readonly property var subtaskStats: TaskService.getSubtaskStats(kbCardRoot.liveTask)

                                                property real dragX: 0
                                                property bool isDragging: false

                                                z: isDragging ? 100 : ((kbCardH.hovered || isExpanded) ? 5 : 1)

                                                Layout.fillWidth: true
                                                Layout.preferredHeight: isEditing ? (kbEditCol.implicitHeight + 14) : (kbCardInnerCol.implicitHeight + (root.tasksExpanded ? 16 : 14))
                                                implicitHeight: Layout.preferredHeight
                                                radius: 10
                                                color: isDragging ? Qt.alpha(root.surface, 0.98) : (isExpanded ? Qt.alpha(root.surface, 0.95) : (kbCardH.hovered ? Qt.alpha(root.textColor, 0.08) : Qt.alpha(root.surface, 0.85)))
                                                border.width: 1
                                                border.color: isDragging ? root.color1 : (isExpanded ? Qt.alpha(root.color1, 0.35) : (kbCardH.hovered ? Qt.alpha(root.color1, 0.3) : Qt.alpha(root.textColor, 0.08)))
                                                scale: isDragging ? 1.02 : (kbCardH.hovered ? 1.01 : 1.0)

                                                transform: [
                                                    Translate {
                                                        id: cardTrans
                                                        x: kbCardRoot.dragX
                                                        y: kbCardRoot.isDragging ? -4 : (kbCardH.hovered ? -2 : 0)

                                                        Behavior on x {
                                                            enabled: !kbCardRoot.isDragging
                                                            NumberAnimation { duration: 180; easing.type: Easing.OutBack }
                                                        }
                                                        Behavior on y {
                                                            enabled: !kbCardRoot.isDragging
                                                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                                                        }
                                                    },
                                                    Rotation {
                                                        origin.x: kbCardRoot.width / 2
                                                        origin.y: kbCardRoot.height / 2
                                                        angle: Math.max(-6, Math.min(6, kbCardRoot.dragX * 0.05))

                                                        Behavior on angle {
                                                            enabled: !kbCardRoot.isDragging
                                                            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                                                        }
                                                    }
                                                ]

                                                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                                Behavior on color { ColorAnimation { duration: 180 } }
                                                Behavior on border.color { ColorAnimation { duration: 180 } }

                                                HoverHandler { id: kbCardH }

                                                // Universal Card Drag Area at base z: 0 underneath inner controls
                                                MouseArea {
                                                    id: cardDragArea
                                                    anchors.fill: parent
                                                    z: 0
                                                    hoverEnabled: true
                                                    cursorShape: kbCardRoot.isDragging ? Qt.ClosedHandCursor : (containsMouse ? Qt.OpenHandCursor : Qt.ArrowCursor)

                                                    property real startX: 0
                                                    property real startY: 0
                                                    property bool dragActive: false

                                                    onPressed: (mouse) => {
                                                        startX = mouse.x;
                                                        startY = mouse.y;
                                                        dragActive = false;
                                                    }

                                                    onPressedChanged: {
                                                        if (!pressed) {
                                                            dragActive = false;
                                                            kbCardRoot.isDragging = false;
                                                            if (kanbanColRoot) kanbanColRoot.isDraggingCard = false;
                                                        }
                                                    }

                                                    onPositionChanged: (mouse) => {
                                                        if (!pressed) return;
                                                        var dx = mouse.x - startX;
                                                        var dy = mouse.y - startY;

                                                        // Intentional threshold to differentiate simple click from horizontal drag
                                                        if (!dragActive && Math.abs(dx) > 8) {
                                                            dragActive = true;
                                                            kbCardRoot.isDragging = true;
                                                            if (kanbanColRoot) kanbanColRoot.isDraggingCard = true;
                                                        }

                                                        if (dragActive) {
                                                            var col = kbCardRoot.currentColumn;
                                                            if (col === "todo" && dx < 0) dx = dx * 0.25;
                                                            if (col === "done" && dx > 0) dx = dx * 0.25;

                                                            // Tactile rubber-banding beyond 45px
                                                            var maxTravel = 45;
                                                            if (dx > maxTravel) dx = maxTravel + (dx - maxTravel) * 0.15;
                                                            else if (dx < -maxTravel) dx = -maxTravel + (dx + maxTravel) * 0.15;

                                                            kbCardRoot.dragX = dx;
                                                        }
                                                    }

                                                    onReleased: {
                                                        var wasDragging = kbCardRoot.isDragging;
                                                        var currentDragX = kbCardRoot.dragX;
                                                        var col = kbCardRoot.currentColumn;
                                                        var taskId = kbCardRoot.liveTask ? kbCardRoot.liveTask.id : null;

                                                        // Reset drag states cleanly before modifying tasks or triggering model updates
                                                        kbCardRoot.dragX = 0;
                                                        kbCardRoot.isDragging = false;
                                                        if (kanbanColRoot) kanbanColRoot.isDraggingCard = false;
                                                        dragActive = false;

                                                        if (wasDragging && taskId) {
                                                            var thresh = 25;
                                                            if (currentDragX > thresh && col !== "done") {
                                                                Qt.callLater(function() {
                                                                    TaskService.moveTaskColumn(taskId, 1);
                                                                    if (!root.tasksExpanded) {
                                                                        if (col === "todo") tasksPanel.activeKanbanCol = "ongoing";
                                                                        else if (col === "ongoing") tasksPanel.activeKanbanCol = "done";
                                                                    }
                                                                });
                                                            } else if (currentDragX < -thresh && col !== "todo") {
                                                                Qt.callLater(function() {
                                                                    TaskService.moveTaskColumn(taskId, -1);
                                                                    if (!root.tasksExpanded) {
                                                                        if (col === "done") tasksPanel.activeKanbanCol = "ongoing";
                                                                        else if (col === "ongoing") tasksPanel.activeKanbanCol = "todo";
                                                                    }
                                                                });
                                                            }
                                                        }
                                                    }

                                                    onCanceled: {
                                                        kbCardRoot.dragX = 0;
                                                        kbCardRoot.isDragging = false;
                                                        if (kanbanColRoot) kanbanColRoot.isDraggingCard = false;
                                                        dragActive = false;
                                                    }

                                                    onDoubleClicked: {
                                                        tasksPanel.startEditing(kbCardRoot.liveTask);
                                                    }
                                                }

                                                // Real-time floating drag indicator (active on 15px drag)
                                                Rectangle {
                                                    anchors.fill: parent
                                                    radius: kbCardRoot.radius
                                                    visible: kbCardRoot.isDragging && Math.abs(kbCardRoot.dragX) > 15
                                                    color: {
                                                        if (kbCardRoot.dragX > 20) {
                                                            return kbCardRoot.currentColumn === "done" ? Qt.alpha(root.textColor, 0.15) : Qt.alpha(root.color1, 0.25);
                                                        } else if (kbCardRoot.dragX < -20) {
                                                            return kbCardRoot.currentColumn === "todo" ? Qt.alpha(root.textColor, 0.15) : Qt.alpha(root.color1, 0.25);
                                                        }
                                                        return Qt.alpha(root.textColor, 0.08);
                                                    }
                                                    border.width: 1.5
                                                    border.color: Math.abs(kbCardRoot.dragX) > 20 ? root.color1 : Qt.alpha(root.textColor, 0.2)
                                                    z: 25

                                                    RowLayout {
                                                        anchors.centerIn: parent
                                                        spacing: 6

                                                        Text {
                                                            text: kbCardRoot.dragX > 0 ? "arrow_forward" : "arrow_back"
                                                            font.family: "Material Symbols Rounded"
                                                            font.pixelSize: 16
                                                            color: Math.abs(kbCardRoot.dragX) > 20 ? root.color1 : root.textColor
                                                        }

                                                        Text {
                                                            text: {
                                                                if (kbCardRoot.dragX > 20) {
                                                                    if (kbCardRoot.currentColumn === "todo") return qsTr("Move to Ongoing");
                                                                    if (kbCardRoot.currentColumn === "ongoing") return qsTr("Move to Done");
                                                                    return qsTr("Already in Done");
                                                                } else if (kbCardRoot.dragX < -20) {
                                                                    if (kbCardRoot.currentColumn === "done") return qsTr("Move to Ongoing");
                                                                    if (kbCardRoot.currentColumn === "ongoing") return qsTr("Move to To Do");
                                                                    return qsTr("Already in To Do");
                                                                }
                                                                return qsTr("Move column");
                                                            }
                                                            font.family: "Google Sans Flex, Google Sans, sans-serif"
                                                            font.pixelSize: 12
                                                            font.weight: Font.DemiBold
                                                            color: Math.abs(kbCardRoot.dragX) > 20 ? root.color1 : root.textColor
                                                        }
                                                    }
                                                }

                                                // Inline edit view
                                                ColumnLayout {
                                                    id: kbEditCol
                                                    visible: kbCardRoot.isEditing
                                                    anchors.fill: parent
                                                    anchors.margins: 6
                                                    spacing: 4
                                                    z: 15

                                                    TextInput {
                                                        id: kbEditInput
                                                        Layout.fillWidth: true
                                                        font.family: "Google Sans Flex, Google Sans, sans-serif"
                                                        font.pixelSize: root.tasksExpanded ? 13 : 12
                                                        color: root.textColor
                                                        text: tasksPanel.editTaskText
                                                        selectByMouse: true
                                                        onTextChanged: tasksPanel.editTaskText = text
                                                        onAccepted: tasksPanel.saveEditing()
                                                    }

                                                    RowLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 4

                                                        Item { Layout.fillWidth: true }

                                                        Rectangle {
                                                            implicitWidth: 20
                                                            implicitHeight: 20
                                                            radius: 6
                                                            color: Qt.alpha(root.textColor, 0.08)
                                                            Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 10; color: root.textMuted }
                                                            MouseArea {
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: tasksPanel.cancelEditing()
                                                            }
                                                        }

                                                        Rectangle {
                                                            implicitWidth: 20
                                                            implicitHeight: 20
                                                            radius: 6
                                                            color: root.color1
                                                            Text { anchors.centerIn: parent; text: "✓"; font.pixelSize: 10; color: root.foreground }
                                                            MouseArea {
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: tasksPanel.saveEditing()
                                                            }
                                                        }
                                                    }
                                                }

                                                // Normal card view (z: 1 sits above cardDragArea)
                                                ColumnLayout {
                                                    id: kbCardInnerCol
                                                    visible: !kbCardRoot.isEditing
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    anchors.top: parent.top
                                                    anchors.margins: root.tasksExpanded ? 8 : 7
                                                    spacing: 4
                                                    z: 1
                                                    
                                                    // Row 1: Checkbox, Priority dot, Title (Constant width, zero hover reflow)
                                                    RowLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 6

                                                        // Checkbox marking task done
                                                        Rectangle {
                                                            Layout.preferredWidth: 18
                                                            Layout.preferredHeight: 18
                                                            radius: 9
                                                            color: kbCardRoot.liveTask.done ? root.color1 : "transparent"
                                                            border.width: kbCardRoot.liveTask.done ? 0 : 1.5
                                                            border.color: kbCardRoot.liveTask.done ? root.color1 : Qt.alpha(root.textColor, 0.3)
                                                            scale: kbCheckMa.pressed ? 0.85 : (kbCheckMa.containsMouse ? 1.15 : 1.0)
                                                            z: 10

                                                            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }

                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: "✓"
                                                                font.family: "Google Sans"
                                                                font.pixelSize: 10
                                                                font.weight: Font.Bold
                                                                color: root.foreground
                                                                visible: kbCardRoot.liveTask.done
                                                            }

                                                            MouseArea {
                                                                id: kbCheckMa
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: TaskService.toggleTask(kbCardRoot.liveTask.id)
                                                            }
                                                        }

                                                        // Priority dot (only shown if not 'none')
                                                        Rectangle {
                                                            visible: kbCardRoot.liveTask.priority && kbCardRoot.liveTask.priority !== "none"
                                                            Layout.preferredWidth: 6
                                                            Layout.preferredHeight: 6
                                                            radius: 3
                                                            color: TaskService.getPriorityColor(kbCardRoot.liveTask.priority)
                                                        }

                                                        // Title text - unhandled clicks/drags naturally pass to cardDragArea
                                                        Text {
                                                            Layout.fillWidth: true
                                                            Layout.rightMargin: 24
                                                            text: kbCardRoot.liveTask.text
                                                            font.family: "Google Sans Flex, Google Sans, sans-serif"
                                                            font.pixelSize: root.tasksExpanded ? 13 : 12
                                                            font.weight: Font.Medium
                                                            font.strikeout: kbCardRoot.liveTask.done
                                                            color: kbCardRoot.liveTask.done ? root.textMuted : root.textColor
                                                            wrapMode: Text.Wrap
                                                        }
                                                    }

                                                    // Row 2: Metadata (Date, Time, Subtasks badge)
                                                    RowLayout {
                                                        Layout.fillWidth: true
                                                        visible: !!kbCardRoot.liveTask.date || !!kbCardRoot.liveTask.startTime || kbCardRoot.hasSubtasks
                                                        spacing: 6

                                                        // Schedule info
                                                        RowLayout {
                                                            visible: !!kbCardRoot.liveTask.date || !!kbCardRoot.liveTask.startTime
                                                            spacing: 4

                                                            Text {
                                                                text: "schedule"
                                                                font.family: "Material Symbols Rounded"
                                                                font.pixelSize: 12
                                                                color: root.textMuted
                                                            }

                                                            Text {
                                                                text: {
                                                                    var s = "";
                                                                    if (kbCardRoot.liveTask.date) s += root.formatTaskDate(kbCardRoot.liveTask.date);
                                                                    if (kbCardRoot.liveTask.startTime) {
                                                                        var tDisp = TaskService.formatDisplayTime(kbCardRoot.liveTask.startTime, tasksPanel.is24);
                                                                        s += (s ? " • " : "") + tDisp;
                                                                    }
                                                                    return s;
                                                                }
                                                                font.family: "Google Sans"
                                                                font.pixelSize: 11
                                                                color: root.textMuted
                                                                elide: Text.ElideRight
                                                            }
                                                        }

                                                        Item { Layout.fillWidth: true }

                                                        // Subtask count & toggle pill
                                                        Rectangle {
                                                            visible: kbCardRoot.hasSubtasks
                                                            implicitWidth: subBadgeRow.implicitWidth + 10
                                                            implicitHeight: 20
                                                            radius: 10
                                                            color: kbCardRoot.isExpanded ? root.color1 : (subBadgeH.hovered ? Qt.alpha(root.textColor, 0.1) : Qt.alpha(root.textColor, 0.05))
                                                            border.width: 1
                                                            border.color: kbCardRoot.isExpanded ? root.color1 : Qt.alpha(root.textColor, 0.08)
                                                            scale: subBadgeMa.pressed ? 0.92 : 1.0
                                                            z: 10

                                                            Behavior on scale { NumberAnimation { duration: 120 } }
                                                            Behavior on color { ColorAnimation { duration: 150 } }
                                                            Behavior on border.color { ColorAnimation { duration: 150 } }

                                                            RowLayout {
                                                                id: subBadgeRow
                                                                anchors.centerIn: parent
                                                                spacing: 3

                                                                Text {
                                                                    text: kbCardRoot.isExpanded ? "expand_less" : "checklist"
                                                                    font.family: "Material Symbols Rounded"
                                                                    font.pixelSize: 12
                                                                    color: kbCardRoot.isExpanded ? root.foreground : root.textMuted
                                                                }

                                                                Text {
                                                                    text: kbCardRoot.subtaskStats ? (kbCardRoot.subtaskStats.completed + "/" + kbCardRoot.subtaskStats.total) : ""
                                                                    font.family: "Google Sans"
                                                                    font.pixelSize: 11
                                                                    font.weight: Font.Bold
                                                                    color: kbCardRoot.isExpanded ? root.foreground : root.textMuted
                                                                }
                                                            }

                                                            HoverHandler { id: subBadgeH }

                                                            MouseArea {
                                                                id: subBadgeMa
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: kbCardRoot.isExpanded = !kbCardRoot.isExpanded
                                                            }
                                                        }
                                                    }

                                                    // Row 3: Collapsible Checklist Drawer (Minimalist & Compact)
                                                    ColumnLayout {
                                                        id: checklistSectionCol
                                                        Layout.fillWidth: true
                                                        visible: kbCardRoot.isExpanded && (kbCardRoot.hasSubtasks || kbCardRoot.isAddingSubtask)
                                                        opacity: visible ? 1.0 : 0.0
                                                        spacing: 3

                                                        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                                                        Rectangle {
                                                            Layout.fillWidth: true
                                                            Layout.preferredHeight: 1
                                                            color: Qt.alpha(root.textColor, 0.06)
                                                            Layout.topMargin: 2
                                                            Layout.bottomMargin: 2
                                                        }

                                                        // Subtask items
                                                        Repeater {
                                                            model: (kbCardRoot.liveTask.subtasks && Array.isArray(kbCardRoot.liveTask.subtasks)) ? kbCardRoot.liveTask.subtasks : []

                                                            delegate: RowLayout {
                                                                id: subtaskItemRow
                                                                required property var modelData
                                                                required property int index
                                                                Layout.fillWidth: true
                                                                spacing: 6

                                                                // Subtask checkbox
                                                                Rectangle {
                                                                    Layout.preferredWidth: 15
                                                                    Layout.preferredHeight: 15
                                                                    radius: 4
                                                                    color: subtaskItemRow.modelData.done ? root.color1 : "transparent"
                                                                    border.width: subtaskItemRow.modelData.done ? 0 : 1.2
                                                                    border.color: subtaskItemRow.modelData.done ? root.color1 : Qt.alpha(root.textColor, 0.3)
                                                                    z: 10

                                                                    Text {
                                                                        anchors.centerIn: parent
                                                                        text: "✓"
                                                                        font.family: "Google Sans"
                                                                        font.pixelSize: 9
                                                                        font.weight: Font.Bold
                                                                        color: root.foreground
                                                                        visible: subtaskItemRow.modelData.done
                                                                    }

                                                                    MouseArea {
                                                                        anchors.fill: parent
                                                                        cursorShape: Qt.PointingHandCursor
                                                                        onClicked: TaskService.toggleSubtask(kbCardRoot.liveTask.id, subtaskItemRow.modelData.id, subtaskItemRow.index)
                                                                    }
                                                                }

                                                                Text {
                                                                    Layout.fillWidth: true
                                                                    text: subtaskItemRow.modelData.text
                                                                    font.family: "Google Sans Flex, Google Sans, sans-serif"
                                                                    font.pixelSize: 12
                                                                    font.strikeout: subtaskItemRow.modelData.done
                                                                    color: subtaskItemRow.modelData.done ? root.textMuted : root.textColor
                                                                    wrapMode: Text.Wrap
                                                                }

                                                                Rectangle {
                                                                    Layout.preferredWidth: 16
                                                                    Layout.preferredHeight: 16
                                                                    radius: 4
                                                                    color: subDelH.hovered ? Qt.alpha(Colors.cfg.error, 0.2) : "transparent"
                                                                    z: 10

                                                                    Text {
                                                                        anchors.centerIn: parent
                                                                        text: "✕"
                                                                        font.family: "Google Sans"
                                                                        font.pixelSize: 9
                                                                        color: subDelH.hovered ? Colors.cfg.error : root.textMuted
                                                                    }

                                                                    HoverHandler { id: subDelH }

                                                                    MouseArea {
                                                                        anchors.fill: parent
                                                                        cursorShape: Qt.PointingHandCursor
                                                                        onClicked: TaskService.removeSubtask(kbCardRoot.liveTask.id, subtaskItemRow.modelData.id, subtaskItemRow.index)
                                                                    }
                                                                }
                                                            }
                                                        }

                                                        // Inline Add Step field (discreet, compact)
                                                        Rectangle {
                                                            Layout.fillWidth: true
                                                            Layout.preferredHeight: 24
                                                            radius: 6
                                                            color: Qt.alpha(root.textColor, 0.04)
                                                            border.width: subtaskInput.activeFocus ? 1 : 0.6
                                                            border.color: subtaskInput.activeFocus ? root.color1 : Qt.alpha(root.textColor, 0.08)
                                                            z: 10

                                                            RowLayout {
                                                                anchors.fill: parent
                                                                anchors.leftMargin: 6
                                                                anchors.rightMargin: 4
                                                                spacing: 3

                                                                TextInput {
                                                                    id: subtaskInput
                                                                    Layout.fillWidth: true
                                                                    verticalAlignment: TextInput.AlignVCenter
                                                                    font.family: "Google Sans"
                                                                    font.pixelSize: 11
                                                                    color: root.textColor
                                                                    selectByMouse: true
                                                                    onAccepted: {
                                                                        var val = text.trim();
                                                                        if (val.length > 0) {
                                                                            TaskService.addSubtask(kbCardRoot.liveTask.id, val);
                                                                            text = "";
                                                                        }
                                                                    }

                                                                    Text {
                                                                        anchors.fill: parent
                                                                        verticalAlignment: Text.AlignVCenter
                                                                        text: qsTr("+ Add step... (Enter)")
                                                                        font.family: "Google Sans"
                                                                        font.pixelSize: 11
                                                                        color: root.textMuted
                                                                        visible: !subtaskInput.text && !subtaskInput.activeFocus
                                                                    }
                                                                }

                                                                Rectangle {
                                                                    visible: subtaskInput.text.trim().length > 0
                                                                    implicitWidth: 18
                                                                    implicitHeight: 18
                                                                    radius: 4
                                                                    color: root.color1

                                                                    Text {
                                                                        anchors.centerIn: parent
                                                                        text: "add"
                                                                        font.family: "Material Symbols Rounded"
                                                                        font.pixelSize: 12
                                                                        color: root.foreground
                                                                    }

                                                                    MouseArea {
                                                                        anchors.fill: parent
                                                                        cursorShape: Qt.PointingHandCursor
                                                                        onClicked: {
                                                                            var val = subtaskInput.text.trim();
                                                                            if (val.length > 0) {
                                                                                TaskService.addSubtask(kbCardRoot.liveTask.id, val);
                                                                                subtaskInput.text = "";
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }

                                                // Floating quick actions toolbar (anchored to kbCardRoot, zero layout reflow on hover)
                                                Rectangle {
                                                    id: cardQuickActions
                                                    anchors.top: parent.top
                                                    anchors.right: parent.right
                                                    anchors.topMargin: root.tasksExpanded ? 5 : 4
                                                    anchors.rightMargin: root.tasksExpanded ? 6 : 5
                                                    implicitHeight: 22
                                                    implicitWidth: quickActionsRow.implicitWidth + 6
                                                    radius: 6
                                                    color: Qt.alpha(root.surface, 0.94)
                                                    border.width: 1
                                                    border.color: Qt.alpha(root.textColor, 0.12)
                                                    z: 20
                                                    opacity: (kbCardH.hovered && !kbCardRoot.isDragging && !kbCardRoot.isEditing && tasksPanel.delConfirmId !== kbCardRoot.liveTask.id) ? 1.0 : 0.0
                                                    visible: opacity > 0

                                                    Behavior on opacity { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

                                                    RowLayout {
                                                        id: quickActionsRow
                                                        anchors.centerIn: parent
                                                        spacing: 2

                                                        // Add subtask button if none exist yet
                                                        Rectangle {
                                                            visible: !kbCardRoot.hasSubtasks
                                                            implicitWidth: 18
                                                            implicitHeight: 18
                                                            radius: 5
                                                            color: addSubH.hovered ? Qt.alpha(root.color1, 0.2) : "transparent"
                                                            ToolTip.visible: addSubH.hovered
                                                            ToolTip.text: qsTr("Add checklist")

                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: "add_task"
                                                                font.family: "Material Symbols Rounded"
                                                                font.pixelSize: 12
                                                                color: addSubH.hovered ? root.color1 : root.textMuted
                                                            }

                                                            HoverHandler { id: addSubH }

                                                            MouseArea {
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                    kbCardRoot.isAddingSubtask = true;
                                                                    kbCardRoot.isExpanded = true;
                                                                }
                                                            }
                                                        }

                                                        // Edit button
                                                        Rectangle {
                                                            implicitWidth: 18
                                                            implicitHeight: 18
                                                            radius: 5
                                                            color: kbEditH.hovered ? Qt.alpha(root.color1, 0.2) : "transparent"
                                                            ToolTip.visible: kbEditH.hovered
                                                            ToolTip.text: qsTr("Edit task")

                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: "edit"
                                                                font.family: "Material Symbols Rounded"
                                                                font.pixelSize: 11
                                                                color: kbEditH.hovered ? root.color1 : root.textMuted
                                                            }

                                                            HoverHandler { id: kbEditH }

                                                            MouseArea {
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: tasksPanel.startEditing(kbCardRoot.liveTask)
                                                            }
                                                        }

                                                        // Delete button
                                                        Rectangle {
                                                            implicitWidth: 18
                                                            implicitHeight: 18
                                                            radius: 5
                                                            color: kbDelH.hovered ? Qt.alpha(Colors.cfg.error, 0.2) : "transparent"
                                                            ToolTip.visible: kbDelH.hovered
                                                            ToolTip.text: qsTr("Delete task")

                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: "delete"
                                                                font.family: "Material Symbols Rounded"
                                                                font.pixelSize: 11
                                                                color: kbDelH.hovered ? Colors.cfg.error : root.textMuted
                                                            }

                                                            HoverHandler { id: kbDelH }

                                                            MouseArea {
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: tasksPanel.delConfirmId = kbCardRoot.liveTask.id
                                                            }
                                                        }
                                                    }
                                                }

                                                // Inline delete confirmation overlay for Kanban cards
                                                Rectangle {
                                                    anchors.fill: parent
                                                    radius: kbCardRoot.radius
                                                    visible: tasksPanel.delConfirmId === kbCardRoot.liveTask.id
                                                    color: Qt.alpha(root.surface, 0.96)
                                                    border.width: 1.5
                                                    border.color: Colors.cfg.error
                                                    z: 30

                                                    RowLayout {
                                                        anchors.fill: parent
                                                        anchors.margins: 6
                                                        spacing: 4

                                                        Text {
                                                            Layout.fillWidth: true
                                                            text: qsTr("Delete?")
                                                            font.family: "Google Sans"
                                                            font.pixelSize: 11
                                                            font.weight: Font.DemiBold
                                                            color: Colors.cfg.error
                                                        }

                                                        Rectangle {
                                                            implicitWidth: 18
                                                            implicitHeight: 18
                                                            radius: 4
                                                            color: Qt.alpha(root.textColor, 0.08)

                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: "✕"
                                                                font.family: "Google Sans"
                                                                font.pixelSize: 10
                                                                color: root.textColor
                                                            }

                                                            MouseArea {
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: tasksPanel.delConfirmId = null
                                                            }
                                                        }

                                                        Rectangle {
                                                            implicitWidth: 18
                                                            implicitHeight: 18
                                                            radius: 4
                                                            color: Colors.cfg.error

                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: "✓"
                                                                font.family: "Google Sans"
                                                                font.pixelSize: 10
                                                                font.weight: Font.Bold
                                                                color: root.foreground
                                                            }

                                                            MouseArea {
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                    TaskService.removeTask(kbCardRoot.liveTask.id);
                                                                    tasksPanel.delConfirmId = null;
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        // Empty state in column
                                        Rectangle {
                                            visible: kanbanColRoot.colTasks.length === 0
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 50
                                            radius: 8
                                            color: Qt.alpha(root.textColor, 0.02)

                                            Text {
                                                anchors.centerIn: parent
                                                text: qsTr("Empty")
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
            }

        }

        transform: Translate {
            y: tasksCardEntrance.offsetY
        }

    }

}
