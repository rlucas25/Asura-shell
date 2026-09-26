import Qt5Compat.GraphicalEffects

import QtQuick
import QtQuick.Layouts

import Quickshell

import Quickshell.Io

import Quickshell.Services.Mpris

import qs.Asura

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
    readonly property var viewList: [
        "player",
        "timer",
        "recording",
        "activeWindow"
    ]

    readonly property int activeCarouselIndex: {
        var idx = viewList.indexOf(viewMode)
        return idx >= 0 ? idx : 0
    }

    // Variáveis para controlar a rolagem infinita
    property int virtualScrollIndex: 0
    property int __lastCarouselIndex: 0

    onActiveCarouselIndexChanged: {
        var newIdx = activeCarouselIndex
        var oldIdx = __lastCarouselIndex
        var count = viewList.length

        // Detecta a direção baseada na mudança circular do índice
        if (newIdx === (oldIdx + 1) % count) {
            virtualScrollIndex++ // Rolou para baixo/frente
        } else if (newIdx === (oldIdx - 1 + count) % count) {
            virtualScrollIndex-- // Rolou para cima/trás
        } else {
            virtualScrollIndex += (newIdx - oldIdx) // Fallback para pulos
        }
        __lastCarouselIndex = newIdx
    }

    // Função que reposiciona os painéis simulando uma esteira infinita
    function getSlotY(index, vIndex) {
        var count = viewList.length
        if (count === 0) return 0
        
        var currentMod = ((vIndex % count) + count) % count
        var diff = index - currentMod

        // Mantém a diferença no intervalo [-1, count - 2]
        while (diff < -1) diff += count
        while (diff > count - 2) diff -= count

        return (vIndex + diff) * itemStride
    }

    readonly property var player: PlayerService.activePlayer

    property string artUrl:
        player && player.trackArtUrl
            ? player.trackArtUrl
            : ""

    readonly property var audioBars: CavaService.bars

    readonly property bool wantsCava: root.viewMode === "player"

    signal clicked()
    signal scrollRequested(int delta)

    implicitWidth: {
        if (viewMode === "timer")
            return timerDisplayRow.implicitWidth + 16

        if (viewMode === "activeWindow") {
            return Math.min(
                260,
                Math.max(
                    120,
                    activeWinRow.implicitWidth + 16
                )
            )
        }

        if (viewMode === "recording") {
            return (
                numBars * barWidth
            ) +
            (
                (numBars - 1) * spacing
            ) +
            96
        }

        return (
            numBars * barWidth
        ) +
        (
            (numBars - 1) * spacing
        ) +
        92
    }

    implicitHeight: maxBarHeight

    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    onWantsCavaChanged: {
        if (wantsCava)
            CavaService.registerConsumer()
        else
            CavaService.unregisterConsumer()
    }

    Component.onCompleted: {
        // Inicializa o virtualIndex com a aba atual na criação do componente
        virtualScrollIndex = activeCarouselIndex
        __lastCarouselIndex = activeCarouselIndex

        if (wantsCava)
            CavaService.registerConsumer()
    }

    Component.onDestruction: {
        if (wantsCava)
            CavaService.unregisterConsumer()
    }

    Timer {
        id: scrollCooldownTimer

        interval: root.scrollCooldown
        repeat: false

        onTriggered: {
            root.isScrollBusy = false
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
                wheel.accepted = true
                return
            }

            var delta = wheel.angleDelta.y

            if (delta === 0)
                delta = wheel.pixelDelta.y

            if (Math.abs(delta) < 15) {
                wheel.accepted = true
                return
            }

            root.isScrollBusy = true
            scrollCooldownTimer.restart()

            root.scrollRequested(
                delta > 0
                    ? 120
                    : -120
            )

            wheel.accepted = true
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

            // Animação infinita atrelada ao virtualScrollIndex em vez do index absoluto
            y: -root.virtualScrollIndex * root.itemStride

            Behavior on y {
                NumberAnimation {
                    duration: root.scrollAnimationDuration
                    easing.type: Easing.OutCubic
                }
            }

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

                                readonly property real rawVal:
                                    (
                                        root.audioBars &&
                                        root.audioBars[index] !== undefined
                                    )
                                        ? root.audioBars[index]
                                        : 0

                                readonly property real amp:
                                    Math.max(0, Math.min(1, rawVal / 100000))

                                width: root.barWidth
                                height: root.maxBarHeight

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: root.barWidth
                                    height: rawVal > 0
                                            ? Math.max(3, amp * root.maxBarHeight)
                                            : 2
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
                            color: toggleBarPlayH.hovered
                                    ? Qt.alpha(root.textColor, 0.35)
                                    : "transparent"

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
                                        root.player.togglePlaying()
                                }
                            }
                        }

                        Rectangle {
                            implicitWidth: 24
                            implicitHeight: 24
                            radius: 12
                            color: nextBarTrackH.hovered
                                    ? Qt.alpha(root.textColor, 0.35)
                                    : "transparent"

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
                                        root.player.next()
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

                    Icon {
                        id: pomodoroPizza

                        property real cycleProgress:
                            TimerService.totalCycles > 0
                                ? (completedCycles / TimerService.totalCycles)
                                : 0

                        visible: cycleProgress > 0.00 && TimerService.activeMode === "pomodoro"

                        property int completedCycles: {
                            if (TimerService.pomodoroPhase === "longBreak") {
                                return TimerService.totalCycles
                            }
                            if (TimerService.pomodoroPhase === "shortBreak") {
                                return TimerService.currentCycle
                            }
                            return Math.max(0, TimerService.currentCycle - 1)
                        }

                        fill: cycleProgress <= 0.05 ? 0 : 1
                        font.variableAxes: fill
                        font.pixelSize: 22
                        color: root.primary

                        text: {
                            if (cycleProgress <= 0.05) return "circle"
                            if (cycleProgress < 0.18) return "clock_loader_10"
                            if (cycleProgress < 0.35) return "clock_loader_20"
                            if (cycleProgress < 0.58) return "clock_loader_40"
                            if (cycleProgress < 0.70) return "clock_loader_60"
                            if (cycleProgress < 0.84) return "clock_loader_80"
                            if (cycleProgress < 0.98) return "clock_loader_90"
                            return "check_circle"
                        }
                    }

                    Item {
                        readonly property bool hasBar:
                            TimerService.activeMode === "timer" ||
                            TimerService.activeMode === "pomodoro"

                        height: 15
                        implicitWidth: hasBar ? 100 : timeText.implicitWidth

                        Rectangle {
                            anchors.fill: parent
                            color: Qt.alpha(root.textColor, 0.2)
                            radius: 50
                            visible: parent.hasBar
                            opacity: parent.hasBar ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation { duration: 250 }
                            }
                        }

                        Rectangle {
                            height: parent.height
                            width: parent.hasBar ? (parent.width * TimerService.activeProgress) : 0
                            color: root.primary
                            radius: 50
                            visible: parent.hasBar

                            Behavior on width {
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        Text {
                            id: timeText
                            anchors.centerIn: parent
                            text: TimerService.activeDisplayTime
                            font.pixelSize: 10
                            font.family: "GeistMono Nerd Font Propo"
                            font.bold: true
                            color: root.textColor
                        }

                        Behavior on implicitWidth {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Rectangle {
                        z: 15
                        implicitWidth: 24
                        implicitHeight: 24
                        radius: 12
                        color: toggleBarTimerH.hovered
                                ? Qt.alpha(root.textColor, 0.35)
                                : "transparent"

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
                                TimerService.stopAlarmLoop()
                                TimerService.toggleActive()
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
                        color: RecorderService.isRecording
                                ? Colors.cfg.error
                                : root.textColor


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
                        color: RecorderService.isRecording
                                ? Colors.cfg.error
                                : root.textColor
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        height: root.maxBarHeight
                        spacing: root.spacing

                        Repeater {
                            model: root.numBars

                            Item {
                                required property int index

                                readonly property real rawVal:
                                    (
                                        RecorderService.bars &&
                                        RecorderService.bars[index] !== undefined
                                    )
                                        ? RecorderService.bars[index]
                                        : 0

                                readonly property real amp:
                                    Math.max(0, Math.min(1, rawVal / 100000))

                                width: root.barWidth
                                height: root.maxBarHeight

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: root.barWidth
                                    height: rawVal > 0
                                            ? Math.max(3, amp * root.maxBarHeight)
                                            : 2
                                    radius: width / 2
                                    color: RecorderService.isRecording
                                            ? Qt.alpha(Colors.cfg.error, 0.4 + amp * 0.6)
                                            : Qt.alpha(root.textColor, 0.25)

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

                        color: recBtnH.hovered
                                ? (RecorderService.isRecording
                                    ? Qt.alpha(Colors.cfg.error, 0.35)
                                    : Qt.alpha(root.textColor, 0.35))
                                : "transparent"

                        Icon {
                            anchors.centerIn: parent
                            font.variableAxes: fill
                            text: RecorderService.isRecording ? "crop_square" : "screen_record"
                            font.pixelSize: 20
                            fill: 1
                            weight: 400
                            color: RecorderService.isRecording
                                    ? Colors.cfg.error
                                    : root.textColor
                        }

                        HoverHandler {
                            id: recBtnH
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: function(mouse) {
                                mouse.accepted = true
                                RecorderService.toggleRecording()
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
                            var name = ActiveWindowService.activeDisplayName
                            var title = ActiveWindowService.activeTitle

                            if (title && title.length > 0 && !title.startsWith(name)) {
                                return name + ": " + title
                            }

                            return name
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
        }
    }
}