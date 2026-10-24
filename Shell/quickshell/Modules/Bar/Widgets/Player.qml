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
    property color on_primary: Colors.cfg.on_primary
    property string viewMode: "player"
    property bool hovered: false
    property int barWidth: 5
    property int maxBarHeight: 20
    property int numBars: 20
    property int spacing: 4
    readonly property int scrollAnimationDuration: 240
    readonly property real itemStride: root.isVertical ? 50 : 36
    readonly property int scrollCooldown: 280
    property bool isScrollBusy: false
    readonly property var viewList: ["player", "timer", "recording", "activeWindow"]
    readonly property int activeCarouselIndex: {
        var idx = viewList.indexOf(viewMode);
        return idx >= 0 ? idx : 0;
    }
    property int virtualScrollIndex: 0
    property int __lastCarouselIndex: 0
    readonly property var player: PlayerService.activePlayer
    property string artUrl: player && player.trackArtUrl ? player.trackArtUrl : ""
    readonly property var audioBars: CavaService.bars
    readonly property bool wantsCava: root.viewMode === "player"
    readonly property bool isVertical: Config.isBarVertical

    signal clicked()
    signal scrollRequested(int delta)

    function getSlotY(index, vIndex) {
        var count = viewList.length;
        if (count === 0)
            return 0;

        var currentMod = ((vIndex % count) + count) % count;
        var diff = index - currentMod;
        while (diff < -1)diff += count
        while (diff > count - 2)diff -= count
        return (vIndex + diff) * itemStride;
    }

    onActiveCarouselIndexChanged: {
        var newIdx = activeCarouselIndex;
        var oldIdx = __lastCarouselIndex;
        var count = viewList.length;
        if (newIdx === (oldIdx + 1) % count)
            virtualScrollIndex++;
        else if (newIdx === (oldIdx - 1 + count) % count)
            virtualScrollIndex--;
        else
            virtualScrollIndex += (newIdx - oldIdx);
        __lastCarouselIndex = newIdx;
    }
    clip: true
    implicitWidth: {
        if (root.isVertical)
            return 24;

        if (viewMode === "timer")
            return timerDisplayRow.implicitWidth + 16;

        if (viewMode === "activeWindow")
            return Math.min(260, Math.max(120, activeWinRow.implicitWidth + 16));

        if (viewMode === "recording")
            return (numBars * barWidth) + ((numBars - 1) * spacing) + 116;

        return (numBars * barWidth) + ((numBars - 1) * spacing) + 116;
    }
    implicitHeight: {
        if (root.isVertical)
            return (root.viewMode === "player" && (PlayerService.isPlaying || root.hovered)) ? Math.round(48 * Config.barIconScale) : Math.round(26 * Config.barIconScale);

        return Math.round(26 * Config.barIconScale);
    }
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    onWantsCavaChanged: {
        if (wantsCava)
            CavaService.registerConsumer();
        else
            CavaService.unregisterConsumer();
    }
    Component.onCompleted: {
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

    HoverHandler {
        id: playerHoverHandler
        onHoveredChanged: root.hovered = hovered
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
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
                height: root.height
                enabled: root.viewMode === "player"

                Column {
                    id: verticalPlayerCol

                    visible: root.isVertical
                    anchors.centerIn: parent
                    spacing: 3

                    Item {
                        id: vinylItem

                        width: 22
                        height: 22

                        Rectangle {
                            id: coverBgV

                            anchors.fill: parent
                            radius: width / 2
                            color: Qt.alpha(root.textColor, 0.12)
                            antialiasing: true
                        }

                        Item {
                            id: rotatingVinyl

                            anchors.fill: parent

                            Image {
                                id: coverImageV

                                anchors.fill: parent
                                source: root.artUrl
                                sourceSize: Qt.size(48, 48)
                                fillMode: Image.PreserveAspectCrop
                                visible: false
                                asynchronous: true
                            }

                            Rectangle {
                                id: coverMaskV

                                anchors.fill: parent
                                radius: width / 2
                                antialiasing: true
                                visible: false
                            }

                            OpacityMask {
                                anchors.fill: parent
                                source: coverImageV
                                maskSource: coverMaskV
                                visible: root.artUrl !== ""
                            }

                            Rectangle {
                                visible: root.artUrl !== ""
                                width: 6
                                height: 6
                                radius: 3
                                anchors.centerIn: parent
                                color: Colors.cfg.background
                                border.color: Qt.alpha(root.textColor, 0.3)
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
                            font.pixelSize: Math.round(18 * Config.barIconScale)
                            font.family: "Material Symbols Rounded"
                        }

                    }

                    Item {
                        id: verticalControlsArea

                        visible: PlayerService.isPlaying || root.hovered
                        width: 22
                        height: 18

                        Row {
                            id: miniEqualizerRow

                            anchors.centerIn: parent
                            spacing: 2
                            visible: PlayerService.isPlaying && !verticalPlayBtnHover.hovered

                            Repeater {
                                model: 4

                                Item {
                                    required property int index
                                    readonly property int sampleIdx: [1, 4, 8, 12][index]
                                    readonly property real rawVal: (root.audioBars && root.audioBars[sampleIdx] !== undefined) ? root.audioBars[sampleIdx] : 0
                                    readonly property real amp: Math.max(0, Math.min(1, rawVal / 100000))

                                    width: 3
                                    height: 14

                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 3
                                        height: rawVal > 0 ? Math.max(3, amp * 14) : 2
                                        radius: 1.5
                                        color: Qt.alpha(root.primary, 0.45 + amp * 0.55)

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
                            id: verticalPlayBtn

                            anchors.centerIn: parent
                            width: 18
                            height: 18
                            radius: 9
                            visible: verticalPlayBtnHover.hovered || !PlayerService.isPlaying
                            color: verticalPlayBtnHover.hovered ? Qt.alpha(root.textColor, 0.25) : "transparent"

                            Icon {
                                anchors.centerIn: parent
                                text: PlayerService.isPlaying ? "pause" : "play_arrow"
                                fill: 1
                                weight: 400
                                font.pixelSize: 16
                                color: root.textColor
                            }

                            HoverHandler {
                                id: verticalPlayBtnHover
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: function(mouse) {
                                    mouse.accepted = true;
                                    if (root.player)
                                        root.player.togglePlaying();

                                }
                            }

                        }

                    }

                }

                Row {
                    id: albumArtContainer

                    visible: !root.isVertical
                    anchors.centerIn: parent
                    spacing: 10

                    Item {
                        id: albumArtItem

                        width: 22
                        height: 22
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            id: coverBg

                            anchors.fill: parent
                            radius: width / 2
                            color: Qt.alpha(root.textColor, 0.12)
                            antialiasing: true
                        }

                        Image {
                            id: coverImage

                            anchors.fill: parent
                            source: root.artUrl
                            sourceSize: Qt.size(48, 48)
                            fillMode: Image.PreserveAspectCrop
                            visible: false
                            asynchronous: true
                        }

                        Rectangle {
                            id: coverMask

                            anchors.fill: parent
                            radius: width / 2
                            antialiasing: true
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
                            font.pixelSize: Math.round(18 * Config.barIconScale)
                            font.family: "Material Symbols Rounded"
                        }

                    }

                    Row {
                        id: barsArea

                        visible: !root.isVertical
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
                        visible: !root.isVertical
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Rectangle {
                            implicitWidth: toggleBarPlayH.hovered ? 26 : 24
                            implicitHeight: toggleBarPlayH.hovered ? 26 : 24
                            radius: 16
                            color: root.primary

                            Icon {
                                anchors.centerIn: parent
                                text: PlayerService.isPlaying ? "pause" : "play_arrow"
                                fill: 0
                                weight: 600
                                font.pixelSize: Math.round(16 * Config.barIconScale)
                                color: root.on_primary
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

                            Behavior on implicitWidth {
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.OutCubic
                                }

                            }

                            Behavior on implicitHeight {
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.OutCubic
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
                height: root.height
                enabled: root.viewMode === "timer"

                Item {
                    visible: root.isVertical
                    anchors.centerIn: parent
                    width: 22
                    height: 22

                    PieProgress {
                        anchors.centerIn: parent
                        width: 20
                        height: 20
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

                    Icon {
                        anchors.centerIn: parent
                        visible: TimerService.activeMode !== "pomodoro"
                        text: TimerService.activeIcon
                        fill: 1
                        weight: 300
                        font.pixelSize: 20
                        color: root.textColor
                    }

                }

                RowLayout {
                    id: timerDisplayRow

                    visible: !root.isVertical
                    anchors.centerIn: parent
                    spacing: 8

                    Icon {
                        text: TimerService.activeIcon
                        fill: 1
                        weight: 300
                        font.pixelSize: 22
                        color: root.textColor
                    }

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
                        value: {
                            if (TimerService.totalCycles <= 0)
                                return 0;

                            if (TimerService.pomodoroPhase === "longBreak")
                                return 1;

                            var baseCycle = Math.max(0, TimerService.currentCycle - 1);
                            var currentPhaseFraction = (TimerService.pomodoroPhase === "work") ? TimerService.activeProgress : 1;
                            return Math.max(0, Math.min(1, (baseCycle + currentPhaseFraction) / TimerService.totalCycles));
                        }
                        scale: pieHover.hovered ? 1.15 : 1

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

                    ProgressBar {
                        id: timerProgressBar

                        visible: !root.isVertical
                        height: 15
                        hasBar: TimerService.activeMode === "timer" || TimerService.activeMode === "pomodoro"
                        value: TimerService.activeProgress
                        text: TimerService.activeDisplayTime
                        color: root.primary
                        trackColor: Qt.alpha(root.textColor, 0.2)
                        textColor: Colors.cfg.background
                    }

                    Rectangle {
                        visible: !root.isVertical
                        z: 15
                        implicitWidth: 24
                        implicitHeight: 24
                        radius: 12
                        color: toggleBarTimerH.hovered ? Qt.alpha(root.textColor, 0.35) : "transparent"

                        Icon {
                            anchors.centerIn: parent
                            text: TimerService.activeIsRunning ? "pause" : "play_arrow"
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
                height: root.height
                enabled: root.viewMode === "recording"

                Item {
                    visible: root.isVertical
                    anchors.centerIn: parent
                    width: 22
                    height: 22

                    Icon {
                        anchors.centerIn: parent
                        text: RecorderService.isRecording ? "radio_button_checked" : "screen_record"
                        font.pixelSize: 20
                        fill: 1
                        weight: 400
                        color: RecorderService.isRecording ? Colors.cfg.error : root.textColor

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

                }

                Row {
                    id: recordingDisplayRow

                    visible: !root.isVertical
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
                        visible: !root.isVertical
                        anchors.verticalCenter: parent.verticalCenter
                        text: (RecorderService.isRecording || RecorderService.isStopping) ? RecorderService.recordingDisplayTime : "00:00"
                        font.pixelSize: 11
                        font.family: "GeistMono Nerd Font Propo"
                        font.bold: true
                        color: RecorderService.isRecording ? Colors.cfg.error : root.textColor
                    }

                    Row {
                        visible: !root.isVertical
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
                        visible: !root.isVertical
                        z: 15
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24
                        height: 24
                        radius: 12
                        color: recBtnH.hovered ? (RecorderService.isRecording ? Qt.alpha(Colors.cfg.error, 0.35) : Qt.alpha(root.textColor, 0.35)) : "transparent"

                        Icon {
                            anchors.centerIn: parent
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
                height: root.height
                enabled: root.viewMode === "activeWindow"

                Item {
                    visible: root.isVertical
                    anchors.centerIn: parent
                    width: 22
                    height: 22

                    ThemedIcon {
                        anchors.centerIn: parent
                        size: 18
                        source: ActiveWindowService.activeIcon
                        color: root.textColor
                    }

                }

                RowLayout {
                    id: activeWinRow

                    visible: !root.isVertical
                    anchors.centerIn: parent
                    spacing: 8

                    ThemedIcon {
                        size: 20
                        source: ActiveWindowService.activeIcon
                        color: root.textColor
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        visible: !root.isVertical
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

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }

    }

}
