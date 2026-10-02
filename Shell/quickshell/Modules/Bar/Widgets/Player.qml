import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Asura
import qs.Components
import qs.Modules.Bar.Widgets
import qs.Services

Item {
    id: root

    property color textColor: Colors.cfg.text
    property color primary: Colors.cfg.primary
    property string viewMode: "player"
    property bool hovered: false
    property int barWidth: 5
    property int maxBarHeight: 20
    property int numBars: 20
    property int spacing: 4
    readonly property int scrollAnimationDuration: 240
    readonly property real itemStride: 36
    readonly property int scrollCooldown: 280
    property bool isScrollBusy: false
    readonly property var viewList: ["player", "timer", "recording", "activeWindow"]
    readonly property int activeCarouselIndex: {
        var idx = viewList.indexOf(viewMode);
        return idx >= 0 ? idx : 0;
    }
    // Scroll variables
    property int virtualScrollIndex: 0
    property int __lastCarouselIndex: 0
    readonly property var player: PlayerService.activePlayer
    property string artUrl: player && player.trackArtUrl ? player.trackArtUrl : ""
    readonly property var audioBars: CavaService.bars
    readonly property bool wantsCava: root.viewMode === "player"

    signal clicked()
    signal scrollRequested(int delta)

    // Function that repositions panels simulating an infinite conveyor belt
    function getSlotY(index, vIndex) {
        var count = viewList.length;
        if (count === 0)
            return 0;

        var currentMod = ((vIndex % count) + count) % count;
        var diff = index - currentMod;
        // Keeps the difference in the interval [-1, count - 2]
        while (diff < -1)diff += count
        while (diff > count - 2)diff -= count
        return (vIndex + diff) * itemStride;
    }

    onActiveCarouselIndexChanged: {
        // Scrolled down/foward
        // Scrolled up/back

        var newIdx = activeCarouselIndex;
        var oldIdx = __lastCarouselIndex;
        var count = viewList.length;
        // Detects scroll direction
        if (newIdx === (oldIdx + 1) % count)
            virtualScrollIndex++;
        else if (newIdx === (oldIdx - 1 + count) % count)
            virtualScrollIndex--;
        else
            virtualScrollIndex += (newIdx - oldIdx);
        // Fallback to jumps
        __lastCarouselIndex = newIdx;
    }
    implicitWidth: {
        if (viewMode === "timer")
            return timerDisplayRow.implicitWidth + 16;

        if (viewMode === "activeWindow")
            return Math.min(260, Math.max(120, activeWinRow.implicitWidth + 16));

        if (viewMode === "recording")
            return (numBars * barWidth) + ((numBars - 1) * spacing) + 96;

        return (numBars * barWidth) + ((numBars - 1) * spacing) + 92;
    }
    implicitHeight: maxBarHeight
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    onWantsCavaChanged: {
        if (wantsCava)
            CavaService.registerConsumer();
        else
            CavaService.unregisterConsumer();
    }
    Component.onCompleted: {
        // Initializes virtualIndex with the current tab at component creation
        virtualScrollIndex = activeCarouselIndex;
        __lastCarouselIndex = activeCarouselIndex;
        if (wantsCava)
            CavaService.registerConsumer();

    }
    Component.onDestruction: {
        if (wantsCava)
            CavaService.unregisterConsumer();

    }

    Timer {
        id: scrollCooldownTimer

        interval: root.scrollCooldown
        repeat: false
        onTriggered: {
            root.isScrollBusy = false;
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: root.clicked()
        onWheel: function(wheel) {
            if (root.isScrollBusy) {
                wheel.accepted = true;
                return ;
            }
            var delta = wheel.angleDelta.y;
            if (delta === 0)
                delta = wheel.pixelDelta.y;

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
        id: carouselViewport

        anchors.fill: parent
        clip: true
        z: 1

        Item {
            id: carouselReel

            anchors.left: parent.left
            anchors.right: parent.right
            y: -root.virtualScrollIndex * root.itemStride

            Item {
                id: playerSlot

                y: root.getSlotY(0, root.virtualScrollIndex)
                width: parent.width
                height: root.maxBarHeight
                enabled: root.viewMode === "player"

                Row {
                    id: albumArtContainer

                    anchors.centerIn: parent
                    spacing: 10

                    Item {
                        width: 20
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            id: coverImage

                            anchors.fill: parent
                            source: root.artUrl
                            fillMode: Image.PreserveAspectCrop
                            visible: false
                        }

                        Rectangle {
                            id: coverMask

                            anchors.fill: parent
                            radius: width / 2
                            visible: false
                        }

                        OpacityMask {
                            anchors.fill: parent
                            source: coverImage
                            maskSource: coverMask
                            visible: root.artUrl !== ""
                        }

                        Text {
                            visible: root.artUrl === ""
                            anchors.centerIn: parent
                            text: "music_note"
                            color: root.textColor
                            font.pixelSize: 20
                            font.family: "Material Symbols Rounded"
                        }

                    }

                    Row {
                        id: barsArea

                        anchors.verticalCenter: parent.verticalCenter
                        height: root.maxBarHeight
                        spacing: root.spacing

                        Repeater {
                            model: root.numBars

                            Item {
                                required property int index
                                readonly property real rawVal: (root.audioBars && root.audioBars[index] !== undefined) ? root.audioBars[index] : 0
                                readonly property real amp: Math.max(0, Math.min(1, rawVal / 100000))

                                width: root.barWidth
                                height: root.maxBarHeight

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: root.barWidth
                                    height: rawVal > 0 ? Math.max(3, amp * root.maxBarHeight) : 2
                                    radius: width / 2
                                    color: Qt.alpha(root.primary, 0.35 + amp * 0.65)

                                    Behavior on height {
                                        NumberAnimation {
                                            duration: 50
                                            easing.type: Easing.OutCubic
                                        }

                                    }

                                }

                            }

                        }

                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Rectangle {
                            implicitWidth: 24
                            implicitHeight: 24
                            radius: 12
                            color: toggleBarPlayH.hovered ? Qt.alpha(root.textColor, 0.35) : "transparent"

                            Icon {
                                anchors.centerIn: parent
                                text: PlayerService.isPlaying ? "pause" : "play_arrow"
                                font.variableAxes: fill
                                fill: 1
                                weight: 400
                                font.pixelSize: 22
                                color: root.textColor
                            }

                            HoverHandler {
                                id: toggleBarPlayH
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.player)
                                        root.player.togglePlaying();

                                }
                            }

                        }

                        Rectangle {
                            implicitWidth: 24
                            implicitHeight: 24
                            radius: 12
                            color: nextBarTrackH.hovered ? Qt.alpha(root.textColor, 0.35) : "transparent"

                            Icon {
                                anchors.centerIn: parent
                                text: "skip_next"
                                font.variableAxes: fill
                                fill: 1
                                weight: 400
                                font.pixelSize: 22
                                color: root.textColor
                            }

                            HoverHandler {
                                id: nextBarTrackH
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.player)
                                        root.player.next();

                                }
                            }

                        }

                    }

                }

            }

            Item {
                id: timerSlot

                y: root.getSlotY(1, root.virtualScrollIndex)
                width: parent.width
                height: root.maxBarHeight
                enabled: root.viewMode === "timer"

                RowLayout {
                    id: timerDisplayRow

                    anchors.centerIn: parent
                    spacing: 8

                    Icon {
                        font.variableAxes: fill
                        text: TimerService.activeIcon
                        fill: 1
                        weight: 300
                        font.pixelSize: 22
                        color: root.textColor
                    }

                    // Dynamic pie progress indicator for pomodoro cycles
                    PieProgress {
                        id: pomodoroPie

                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 18
                        Layout.alignment: Qt.AlignVCenter
                        visible: TimerService.activeMode === "pomodoro"
                        color: root.primary
                        trackColor: Qt.alpha(root.textColor, 0.18)
                        strokeColor: Qt.alpha(root.primary, 0.4)
                        strokeWidth: 1

                        // Coherent cycle progress: base completed cycles + ongoing session fraction
                        value: {
                            if (TimerService.totalCycles <= 0)
                                return 0.0;

                            if (TimerService.pomodoroPhase === "longBreak")
                                return 1.0;

                            var baseCycle = Math.max(0, TimerService.currentCycle - 1);
                            var currentPhaseFraction = (TimerService.pomodoroPhase === "work")
                                ? TimerService.activeProgress
                                : 1.0;

                            return Math.max(0.0, Math.min(1.0, (baseCycle + currentPhaseFraction) / TimerService.totalCycles));
                        }

                        scale: pieHover.hovered ? 1.15 : 1.0

                        HoverHandler {
                            id: pieHover
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    // Leak-proof progress bar for pomodoro and timer countdown
                    ProgressBar {
                        id: timerProgressBar

                        height: 15
                        hasBar: TimerService.activeMode === "timer" || TimerService.activeMode === "pomodoro"
                        value: TimerService.activeProgress
                        text: TimerService.activeDisplayTime
                        color: root.primary
                        trackColor: Qt.alpha(root.textColor, 0.2)
                        textColor: Colors.cfg.background
                    }

                    Rectangle {
                        z: 15
                        implicitWidth: 24
                        implicitHeight: 24
                        radius: 12
                        color: toggleBarTimerH.hovered ? Qt.alpha(root.textColor, 0.35) : "transparent"

                        Icon {
                            anchors.centerIn: parent
                            text: TimerService.activeIsRunning ? "pause" : "play_arrow"
                            font.variableAxes: fill
                            fill: 1
                            weight: 400
                            font.pixelSize: 22
                            color: root.textColor
                        }

                        HoverHandler {
                            id: toggleBarTimerH
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                TimerService.toggleActive();
                            }
                        }

                    }

                }

            }

            Item {
                id: recordingSlot

                y: root.getSlotY(2, root.virtualScrollIndex)
                width: parent.width
                height: root.maxBarHeight
                enabled: root.viewMode === "recording"

                Row {
                    id: recordingDisplayRow

                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        width: 10
                        height: 10
                        radius: 7
                        color: RecorderService.isRecording ? Colors.cfg.error : root.textColor
                        anchors.verticalCenter: parent.verticalCenter

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

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: RecorderService.recordingDisplayTime
                        font.pixelSize: 11
                        font.family: "GeistMono Nerd Font Propo"
                        font.bold: true
                        color: RecorderService.isRecording ? Colors.cfg.error : root.textColor
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        height: root.maxBarHeight
                        spacing: root.spacing

                        Repeater {
                            model: root.numBars

                            Item {
                                required property int index
                                readonly property real rawVal: (RecorderService.bars && RecorderService.bars[index] !== undefined) ? RecorderService.bars[index] : 0
                                readonly property real amp: Math.max(0, Math.min(1, rawVal / 100000))

                                width: root.barWidth
                                height: root.maxBarHeight

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: root.barWidth
                                    height: rawVal > 0 ? Math.max(3, amp * root.maxBarHeight) : 2
                                    radius: width / 2
                                    color: RecorderService.isRecording ? Qt.alpha(Colors.cfg.error, 0.4 + amp * 0.6) : Qt.alpha(root.textColor, 0.25)

                                    Behavior on height {
                                        NumberAnimation {
                                            duration: 50
                                            easing.type: Easing.OutCubic
                                        }

                                    }

                                }

                            }

                        }

                    }

                    Rectangle {
                        z: 15
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24
                        height: 24
                        radius: 12
                        color: recBtnH.hovered ? (RecorderService.isRecording ? Qt.alpha(Colors.cfg.error, 0.35) : Qt.alpha(root.textColor, 0.35)) : "transparent"

                        Icon {
                            anchors.centerIn: parent
                            font.variableAxes: fill
                            text: RecorderService.isRecording ? "crop_square" : "screen_record"
                            font.pixelSize: 20
                            fill: 1
                            weight: 400
                            color: RecorderService.isRecording ? Colors.cfg.error : root.textColor
                        }

                        HoverHandler {
                            id: recBtnH
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: function(mouse) {
                                mouse.accepted = true;
                                RecorderService.toggleRecording();
                            }
                        }

                    }

                }

            }

            Item {
                id: activeWinSlot

                y: root.getSlotY(3, root.virtualScrollIndex)
                width: parent.width
                height: root.maxBarHeight
                enabled: root.viewMode === "activeWindow"

                RowLayout {
                    id: activeWinRow

                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: ActiveWindowService.activeIcon
                        font.pixelSize: 20
                        font.family: "GeistMono Nerd Font Propo Propo"
                        color: root.textColor
                    }

                    Text {
                        text: {
                            var name = ActiveWindowService.activeDisplayName;
                            var title = ActiveWindowService.activeTitle;
                            if (title && title.length > 0 && !title.startsWith(name))
                                return name + ": " + title;

                            return name;
                        }
                        font.pixelSize: 12
                        font.family: "GeistMono Nerd Font Propo"
                        font.bold: true
                        color: root.textColor
                        elide: Text.ElideRight
                        Layout.maximumWidth: 220
                    }

                }

            }

            Behavior on y {
                NumberAnimation {
                    duration: root.scrollAnimationDuration
                    easing.type: Easing.OutCubic
                }

            }

        }

    }

}
