import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Asura
import qs.Components
import qs.Services

Item {
    id: root

    property color textColor: Colors.cfg.text
    property color primary: Colors.cfg.primary
    property color on_primary: Colors.cfg.on_primary
    property string viewMode: "player"
    property bool hovered: false
    readonly property var player: PlayerService.activePlayer
    property string artUrl: player && player.trackArtUrl ? player.trackArtUrl : ""
    readonly property var audioBars: CavaService.bars
    readonly property bool wantsCava: root.viewMode === "player"
    readonly property bool hasMedia: !!(player && (player.trackTitle || player.trackArtist))
    property bool isScrollBusy: false

    signal clicked()
    signal scrollRequested(int delta)

    function toVerticalColumn(str) {
        if (!str || typeof str !== "string")
            return "";

        return str.split("").map(function(ch) {
            return ch === " " ? "\u00A0" : ch;
        }).join("\n");
    }

    function formatVerticalTime(str) {
        if (!str || typeof str !== "string")
            return "";

        var clean = str.replace(/:/g, " ").trim();
        var parts = clean.split(/\s+/);
        return parts.join("\n");
    }

    implicitWidth: Math.round(24 * Config.barIconScale)
    implicitHeight: {
        if (root.viewMode === "player") {
            if (PlayerService.isPlaying || root.hovered || root.hasMedia)
                return Math.round(176 * Config.barIconScale);

            return Math.round(32 * Config.barIconScale);
        }
        if (root.viewMode === "timer") {
            var timerHasHours = (TimerService.activeMode === "pomodoro" ? TimerService.pomodoroSecondsLeft : (TimerService.activeMode === "timer" ? TimerService.timerSecondsLeft : TimerService.stopwatchSeconds)) >= 3600;
            if (TimerService.activeMode === "pomodoro")
                return timerHasHours ? 160 : 138;

            return timerHasHours ? 144 : 124;
        }
        if (root.viewMode === "recording") {
            var recHasHours = RecorderService.recordingDisplayTime && RecorderService.recordingDisplayTime.length > 5;
            return recHasHours ? 144 : 124;
        }
        if (root.viewMode === "activeWindow")
            return 196;

        return 32;
    }
    onWantsCavaChanged: {
        if (wantsCava)
            CavaService.registerConsumer();
        else
            CavaService.unregisterConsumer();
    }
    Component.onCompleted: {
        if (wantsCava)
            CavaService.registerConsumer();

    }
    Component.onDestruction: {
        if (wantsCava)
            CavaService.unregisterConsumer();

    }

    Timer {
        id: scrollCooldownTimer

        interval: 280
        repeat: false
        onTriggered: root.isScrollBusy = false
    }

    Timer {
        interval: 500
        running: PlayerService.isPlaying
        repeat: true
        onTriggered: {
            if (root.player && typeof root.player.positionChanged === "function")
                root.player.positionChanged();

        }
    }

    HoverHandler {
        id: playerHoverHandler
        onHoveredChanged: root.hovered = hovered
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                if (root.player)
                    root.player.togglePlaying();

            } else if (mouse.button === Qt.MiddleButton) {
                if (root.player)
                    root.player.next();

            } else {
                root.clicked();
            }
        }
        onWheel: (wheel) => {
            if (root.isScrollBusy) {
                wheel.accepted = true;
                return ;
            }
            var delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.pixelDelta.y;
            if (Math.abs(delta) < 15) {
                wheel.accepted = true;
                return ;
            }
            root.isScrollBusy = true;
            scrollCooldownTimer.restart();
            root.scrollRequested(delta > 0 ? 120 : -120);
            wheel.accepted = true;
        }
    }

    Item {
        anchors.fill: parent
        clip: true

        Item {
            id: playerContainer

            anchors.fill: parent
            visible: root.viewMode === "player"

            Column {
                anchors.centerIn: parent
                spacing: Math.round(5 * Config.barIconScale)
                width: parent.width

                Item {
                    id: vinylCoverArea

                    width: Math.round(20 * Config.barIconScale)
                    height: Math.round(20 * Config.barIconScale)
                    anchors.horizontalCenter: parent.horizontalCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Qt.alpha(root.textColor, 0.12)
                        antialiasing: true
                    }

                    Item {
                        id: vinylRotator

                        anchors.fill: parent

                        Image {
                            id: vinylArt

                            anchors.fill: parent
                            source: root.artUrl
                            sourceSize: Qt.size(48, 48)
                            fillMode: Image.PreserveAspectCrop
                            visible: false
                            asynchronous: true
                        }

                        Rectangle {
                            id: vinylMask

                            anchors.fill: parent
                            radius: width / 2
                            antialiasing: true
                            visible: false
                        }

                        OpacityMask {
                            anchors.fill: parent
                            source: vinylArt
                            maskSource: vinylMask
                            visible: root.artUrl !== ""
                        }

                        Rectangle {
                            visible: root.artUrl !== ""
                            width: Math.round(6 * Config.barIconScale)
                            height: Math.round(6 * Config.barIconScale)
                            radius: Math.round(3 * Config.barIconScale)
                            anchors.centerIn: parent
                            color: Colors.cfg.background
                            border.color: Qt.alpha(root.textColor, 0.35)
                            border.width: 1
                        }

                        RotationAnimation on rotation {
                            running: PlayerService.isPlaying && root.artUrl !== ""
                            loops: Animation.Infinite
                            from: 0
                            to: 360
                            duration: 8000
                        }

                    }

                    Text {
                        visible: root.artUrl === ""
                        anchors.centerIn: parent
                        text: "music_note"
                        color: root.textColor
                        font.pixelSize: Math.round(16 * Config.barIconScale)
                        font.family: "Material Symbols Rounded"
                    }

                }

                Item {
                    id: visualizerSlot

                    width: Math.round(18 * Config.barIconScale)
                    height: visualizerCol.implicitHeight
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: PlayerService.isPlaying || root.hovered || root.hasMedia

                    Column {
                        id: visualizerCol

                        anchors.centerIn: parent
                        spacing: Math.max(1, Math.round(1.5 * Config.barIconScale))

                        Repeater {
                            model: 20

                            Item {
                                required property int index
                                readonly property real rawVal: (root.audioBars && root.audioBars[index] !== undefined) ? root.audioBars[index] : 0
                                readonly property real amp: Math.max(0, Math.min(1, rawVal / 100000))

                                width: visualizerSlot.width
                                height: Math.max(2.5, Math.round(3.5 * Config.barIconScale))

                                Rectangle {
                                    anchors.centerIn: parent
                                    height: parent.height
                                    width: rawVal > 0 ? Math.max(3, amp * parent.width) : 3
                                    radius: height / 2
                                    color: Qt.alpha(root.primary, 0.4 + amp * 0.6)

                                    Behavior on width {
                                        NumberAnimation {
                                            duration: 50
                                            easing.type: Easing.OutCubic
                                        }

                                    }

                                }

                            }

                        }

                    }

                }

                Column {
                    id: controlsColumn

                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Math.round(4 * Config.barIconScale)
                    visible: PlayerService.isPlaying || root.hovered || root.hasMedia

                    Rectangle {
                        id: playBtn

                        width: Math.round(20 * Config.barIconScale)
                        height: Math.round(20 * Config.barIconScale)
                        radius: height / 2
                        color: playHover.hovered ? Qt.lighter(root.primary, 1.15) : root.primary
                        anchors.horizontalCenter: parent.horizontalCenter
                        scale: playArea.pressed ? 0.92 : (playHover.hovered ? 1.06 : 1)

                        Text {
                            anchors.centerIn: parent
                            text: PlayerService.isPlaying ? "pause" : "play_arrow"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: Math.round(14 * Config.barIconScale)
                            color: root.on_primary
                        }

                        HoverHandler {
                            id: playHover
                        }

                        MouseArea {
                            id: playArea

                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: (mouse) => {
                                mouse.accepted = true;
                                if (root.player)
                                    root.player.togglePlaying();

                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }

                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }

                        }

                    }

                    Rectangle {
                        id: nextBtn

                        width: Math.round(18 * Config.barIconScale)
                        height: Math.round(16 * Config.barIconScale)
                        radius: height / 2
                        color: nextHover.hovered ? Qt.alpha(root.textColor, 0.22) : "transparent"
                        anchors.horizontalCenter: parent.horizontalCenter
                        scale: nextArea.pressed ? 0.92 : (nextHover.hovered ? 1.06 : 1)

                        Text {
                            anchors.centerIn: parent
                            text: "skip_next"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: Math.round(14 * Config.barIconScale)
                            color: root.textColor
                        }

                        HoverHandler {
                            id: nextHover
                        }

                        MouseArea {
                            id: nextArea

                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: (mouse) => {
                                mouse.accepted = true;
                                if (root.player)
                                    root.player.next();

                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }

                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }

                        }

                    }

                }

            }

        }

        Item {
            id: timerContainer

            anchors.fill: parent
            visible: root.viewMode === "timer"

            Column {
                anchors.centerIn: parent
                spacing: 5
                width: parent.width

                Item {
                    width: 20
                    height: 20
                    anchors.horizontalCenter: parent.horizontalCenter

                    Icon {
                        anchors.centerIn: parent
                        name: TimerService.activeIcon
                        size: 18
                        color: root.textColor
                    }

                }

                PieProgress {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 14
                    height: 14
                    visible: TimerService.activeMode === "pomodoro"
                    color: root.primary
                    trackColor: Qt.alpha(root.textColor, 0.18)
                    strokeColor: Qt.alpha(root.primary, 0.4)
                    strokeWidth: 1.5
                    value: {
                        if (TimerService.totalCycles <= 0)
                            return 0;

                        if (TimerService.pomodoroPhase === "longBreak")
                            return 1;

                        var baseCycle = Math.max(0, TimerService.currentCycle - 1);
                        var currentPhaseFraction = (TimerService.pomodoroPhase === "work") ? TimerService.activeProgress : 1;
                        return Math.max(0, Math.min(1, (baseCycle + currentPhaseFraction) / TimerService.totalCycles));
                    }
                }

                Item {
                    id: timerInfoSlot

                    width: Math.round(20 * Config.barIconScale)
                    height: timerText.implicitHeight
                    clip: false
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        id: timerText

                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Math.round(12 * Config.barIconScale)
                        font.weight: 700
                        font.family: "Google Sans"
                        lineHeight: 0.92
                        color: root.textColor
                        text: {
                            var tStr = "";
                            if (TimerService.activeMode === "pomodoro")
                                tStr = TimerService.formatSeconds(TimerService.pomodoroSecondsLeft);
                            else if (TimerService.activeMode === "timer")
                                tStr = TimerService.formatSeconds(TimerService.timerSecondsLeft);
                            else
                                tStr = TimerService.formatSeconds(TimerService.stopwatchSeconds);
                            return root.formatVerticalTime(tStr);
                        }
                    }

                }

                Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    color: root.primary
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        anchors.centerIn: parent
                        text: (TimerService.pomodoroRunning || TimerService.timerRunning || TimerService.stopwatchRunning) ? "pause" : "play_arrow"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 14
                        color: root.on_primary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (mouse) => {
                            mouse.accepted = true;
                            if (TimerService.activeMode === "pomodoro")
                                TimerService.togglePomodoro();
                            else if (TimerService.activeMode === "timer")
                                TimerService.toggleTimer();
                            else
                                TimerService.toggleStopwatch();
                        }
                    }

                }

            }

        }

        Item {
            id: recContainer

            anchors.fill: parent
            visible: root.viewMode === "recording"

            Column {
                anchors.centerIn: parent
                spacing: 6
                width: parent.width

                Rectangle {
                    width: 12
                    height: 12
                    radius: 6
                    color: RecorderService.isRecording ? Colors.cfg.error : root.textColor
                    anchors.horizontalCenter: parent.horizontalCenter

                    SequentialAnimation on opacity {
                        running: RecorderService.isRecording
                        loops: Animation.Infinite

                        NumberAnimation {
                            from: 1
                            to: 0.2
                            duration: 600
                            easing.type: Easing.InOutQuad
                        }

                        NumberAnimation {
                            from: 0.2
                            to: 1
                            duration: 600
                            easing.type: Easing.InOutQuad
                        }

                    }

                }

                Item {
                    id: recInfoSlot

                    width: Math.round(20 * Config.barIconScale)
                    height: recText.implicitHeight
                    clip: false
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        id: recText

                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Math.round(12 * Config.barIconScale)
                        font.weight: 700
                        font.family: "Google Sans"
                        lineHeight: 0.92
                        color: RecorderService.isRecording ? Colors.cfg.error : root.textColor
                        text: root.formatVerticalTime(RecorderService.recordingDisplayTime)
                    }

                }

                Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    color: Qt.alpha(Colors.cfg.error, 0.2)
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        anchors.centerIn: parent
                        text: RecorderService.isRecording ? "stop" : "radio_button_checked"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 14
                        color: Colors.cfg.error
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (mouse) => {
                            mouse.accepted = true;
                            RecorderService.toggleRecording();
                        }
                    }

                }

            }

        }

        Item {
            id: activeWinContainer

            anchors.fill: parent
            visible: root.viewMode === "activeWindow"

            Column {
                anchors.centerIn: parent
                spacing: 5
                width: parent.width

                ThemedIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    size: 16
                    source: ActiveWindowService.activeIcon
                    color: root.textColor
                }

                Item {
                    id: winColumnSlot

                    property real scrollY: 0
                    readonly property real overflow: Math.max(0, winTitleText.implicitHeight - height)

                    width: Math.round(20 * Config.barIconScale)
                    height: 140
                    clip: true
                    anchors.horizontalCenter: parent.horizontalCenter

                    Connections {
                        function onActiveTitleChanged() {
                            winColumnSlot.scrollY = 0;
                        }

                        target: ActiveWindowService
                    }

                    Text {
                        id: winTitleText

                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        color: root.textColor
                        font.pixelSize: Math.round(10 * Config.barIconScale)
                        font.bold: true
                        font.family: "GeistMono Nerd Font Propo"
                        lineHeight: 0.85
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: winColumnSlot.overflow > 0 ? winColumnSlot.scrollY : Math.round((winColumnSlot.height - implicitHeight) / 2)
                        text: {
                            var t = ActiveWindowService.activeTitle;
                            var n = ActiveWindowService.activeDisplayName;
                            var display = (t && t.length > 0) ? t : (n && n.length > 0 ? n : "Desktop");
                            return root.toVerticalColumn(display);
                        }
                    }

                    SequentialAnimation on scrollY {
                        running: winColumnSlot.overflow > 0
                        loops: Animation.Infinite

                        PauseAnimation {
                            duration: 1200
                        }

                        NumberAnimation {
                            to: -winColumnSlot.overflow
                            duration: Math.max(1600, winColumnSlot.overflow * 28)
                            easing.type: Easing.Linear
                        }

                        PauseAnimation {
                            duration: 1200
                        }

                        NumberAnimation {
                            to: 0
                            duration: Math.max(1000, winColumnSlot.overflow * 18)
                            easing.type: Easing.InOutQuad
                        }

                    }

                }

            }

        }

    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }

    }

}
