import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import qs.Animations
import qs.Asura
import qs.Components
import qs.Modules.Bar.Menus
import qs.Services

ColumnLayout {
    id: root

    spacing: 10
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

    property bool tabActive: false

    CardEntrance {
        id: headerEntrance
        active: root.tabActive
        delay: 20
        startOffsetY: 12
    }

    CardEntrance {
        id: pomoLeftEntrance
        active: root.tabActive && TimerService.activeMode === "pomodoro"
        delay: 70
        startOffsetY: 20
    }

    CardEntrance {
        id: pomoRightEntrance
        active: root.tabActive && TimerService.activeMode === "pomodoro"
        delay: 130
        startOffsetY: 20
    }

    CardEntrance {
        id: timerCardEntrance
        active: root.tabActive && TimerService.activeMode === "timer"
        delay: 70
        startOffsetY: 20
    }

    CardEntrance {
        id: stopwatchCardEntrance
        active: root.tabActive && TimerService.activeMode === "stopwatch"
        delay: 70
        startOffsetY: 20
    }

    CardEntrance {
        id: alarmCardEntrance
        active: root.tabActive && TimerService.activeMode === "alarm"
        delay: 70
        startOffsetY: 20
    }

    RowLayout {
        id: modeSelectorRow
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        spacing: 10
        opacity: headerEntrance.opacity
        scale: headerEntrance.scale
        transform: Translate {
            y: headerEntrance.offsetY
        }

        Repeater {
            model: [{
                "mode": "pomodoro",
                "icon": "timelapse",
                "label": "Pomodoro"
            }, {
                "mode": "timer",
                "icon": "timer",
                "label": "Timer"
            }, {
                "mode": "stopwatch",
                "icon": "pace",
                "label": "Stopwatch"
            }, {
                "mode": "alarm",
                "icon": "alarm",
                "label": "Alarm"
            }]

            delegate: Rectangle {
                id: modeBtn
                required property var modelData
                required property int index

                Layout.fillWidth: true
                implicitHeight: 36
                radius: Math.round(Config.effectiveGeneralRadius * 0.7)
                color: TimerService.activeMode === modelData.mode ? root.color1 : (modeHover.hovered ? root.surfaceContainer : "transparent")
                border.color: TimerService.activeMode === modelData.mode ? root.color1 : Qt.alpha(root.textColor, 0.08)
                border.width: 1
                scale: modeMouse.pressed ? 0.94 : (modeHover.hovered ? 1.02 : 1.0)

                Behavior on scale {
                    NumberAnimation {
                        duration: 140
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on border.color {
                    ColorAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: modelData.icon
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 16
                        color: TimerService.activeMode === modelData.mode ? root.foreground : (modeHover.hovered ? root.textColor : root.textMuted)

                        Behavior on color {
                            ColorAnimation {
                                duration: 180
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Text {
                        text: modelData.label
                        font.family: "Google Sans"
                        font.pixelSize: 12
                        font.bold: true
                        color: TimerService.activeMode === modelData.mode ? root.foreground : (modeHover.hovered ? root.textColor : root.textMuted)

                        Behavior on color {
                            ColorAnimation {
                                duration: 180
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                }

                HoverHandler {
                    id: modeHover
                }

                MouseArea {
                    id: modeMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: TimerService.activeMode = modelData.mode
                }

            }

        }

    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 12
                        visible: TimerService.activeMode === "pomodoro"

                        Rectangle {
                            id: pomoLeftCard
                            Layout.fillHeight: true
                            Layout.preferredWidth: 480
                            radius: Math.round(Config.effectiveGeneralRadius * 0.88)
                            color: root.surface
                            border.color: Qt.alpha(root.textColor, 0.08)
                            border.width: 1
                            opacity: pomoLeftEntrance.opacity
                            scale: pomoLeftEntrance.scale
                            transform: Translate {
                                y: pomoLeftEntrance.offsetY
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 6

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
                                                    font.family: "Google Sans"
                                                    color: TimerService.pomodoroPhase === modelData.key ? root.foreground : root.textMuted
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

                                Item {
                                    id: pomoCircleContainer

                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.preferredWidth: 180
                                    Layout.preferredHeight: 180

                                    CircularProgress {
                                        id: pomoCircle

                                        anchors.fill: parent
                                        lineWidth: 6
                                        color: TimerService.pomodoroPhase === "work" ? root.color1 : (TimerService.pomodoroPhase === "shortBreak" ? Colors.cfg.success : Colors.cfg.warning)
                                        trackColor: Qt.alpha(pomoCircle.color, 0.12)
                                        value: {
                                            var total = (TimerService.pomodoroPhase === "work" ? TimerService.workMinutes : (TimerService.pomodoroPhase === "shortBreak" ? TimerService.shortBreakMinutes : TimerService.longBreakMinutes)) * 60;
                                            return total > 0 ? Math.max(0.0, Math.min(1.0, 1.0 - (TimerService.pomodoroSecondsLeft / total))) : 0.0;
                                        }
                                        opacity: TimerService.pomodoroRunning ? 1.0 : 0.0
                                        scale: TimerService.pomodoroRunning ? 1.0 : 0.94

                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 300
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Behavior on scale {
                                            NumberAnimation {
                                                duration: 300
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }

                                    Column {
                                        id: pomoTimeCol

                                        anchors.centerIn: parent
                                        spacing: 4
                                        scale: TimerService.pomodoroRunning ? 1.0 : 1.35
                                        transformOrigin: Item.Center

                                        Behavior on scale {
                                            NumberAnimation {
                                                duration: 320
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Text {
                                            id: pomoTimeText

                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: TimerService.formatSeconds(TimerService.pomodoroSecondsLeft)
                                            font.pixelSize: text.length > 5 ? 30 : 38
                                            font.family: "JetbrainsMono Nerd Font Propo"
                                            font.bold: true
                                            color: TimerService.pomodoroRunning ? root.color1 : root.textBright

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 250
                                                }
                                            }
                                        }

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: TimerService.pomodoroPhase === "work" ? "Focus Session" : (TimerService.pomodoroPhase === "shortBreak" ? "Short Break" : "Long Break")
                                            font.pixelSize: 11
                                            color: root.textMuted
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: TimerService.togglePomodoro()
                                    }
                                }

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
                                            text: "replay"
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 18
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
                                            text: TimerService.pomodoroRunning ? "pause" : "play_arrow"
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 26
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
                                            text: "skip_next"
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 18
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

                        Rectangle {
                            id: pomoRightCard
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            radius: Math.round(Config.effectiveGeneralRadius * 0.88)
                            color: root.surface
                            border.color: Qt.alpha(root.textColor, 0.08)
                            border.width: 1
                            opacity: pomoRightEntrance.opacity
                            scale: pomoRightEntrance.scale
                            transform: Translate {
                                y: pomoRightEntrance.offsetY
                            }

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
                                            text: "timer"
                                            font.family: "Material Symbols Rounded"
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
                                            text: "coffee"
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 18
                                            color: Colors.cfg.success
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
                                                    color: Qt.alpha(Colors.cfg.success, 0.15)

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "−"
                                                        font.pixelSize: 14
                                                        font.bold: true
                                                        color: Colors.cfg.success
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
                                                    color: Qt.alpha(Colors.cfg.success, 0.15)

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "+"
                                                        font.pixelSize: 14
                                                        font.bold: true
                                                        color: Colors.cfg.success
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
                                            text: "autorenew"
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 18
                                            color: Colors.cfg.secondary
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
                                                    color: Qt.alpha(Colors.cfg.secondary, 0.15)

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "−"
                                                        font.pixelSize: 14
                                                        font.bold: true
                                                        color: Colors.cfg.secondary
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
                                                    color: Qt.alpha(Colors.cfg.secondary, 0.15)

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "+"
                                                        font.pixelSize: 14
                                                        font.bold: true
                                                        color: Colors.cfg.secondary
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

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    radius: 8
                                    color: Qt.alpha(Colors.cfg.warning, 0.08)
                                    border.color: Qt.alpha(Colors.cfg.warning, 0.15)

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        spacing: 6

                                        Text {
                                            text: "hourglass_bottom"
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 14
                                            color: Colors.cfg.warning
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
                                            color: Qt.alpha(Colors.cfg.warning, 0.15)

                                            Text {
                                                anchors.centerIn: parent
                                                text: "−"
                                                font.pixelSize: 12
                                                font.bold: true
                                                color: Colors.cfg.warning
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
                                            color: Colors.cfg.warning
                                        }

                                        Rectangle {
                                            implicitWidth: 20
                                            implicitHeight: 20
                                            radius: 10
                                            color: Qt.alpha(Colors.cfg.warning, 0.15)

                                            Text {
                                                anchors.centerIn: parent
                                                text: "+"
                                                font.pixelSize: 12
                                                font.bold: true
                                                color: Colors.cfg.warning
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

                    Rectangle {
                        id: timerCard
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Math.round(Config.effectiveGeneralRadius * 0.88)
                        color: root.surface
                        border.color: Qt.alpha(root.textColor, 0.08)
                        border.width: 1
                        visible: TimerService.activeMode === "timer"
                        opacity: timerCardEntrance.opacity
                        scale: timerCardEntrance.scale
                        transform: Translate {
                            y: timerCardEntrance.offsetY
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 14

                            Item {
                                id: timerCircleContainer

                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 180
                                Layout.preferredHeight: 180

                                CircularProgress {
                                    id: timerCircle

                                    anchors.fill: parent
                                    lineWidth: 6
                                    color: root.color1
                                    trackColor: Qt.alpha(root.color1, 0.12)
                                    value: TimerService.timerTotalSeconds > 0 ? Math.max(0.0, Math.min(1.0, 1.0 - (TimerService.timerSecondsLeft / TimerService.timerTotalSeconds))) : 0.0
                                    opacity: TimerService.timerRunning ? 1.0 : 0.0
                                    scale: TimerService.timerRunning ? 1.0 : 0.94

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 300
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 300
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }

                                Item {
                                    id: timerTextContainer

                                    anchors.centerIn: parent
                                    width: timerTimeText.implicitWidth
                                    height: timerTimeText.implicitHeight
                                    scale: TimerService.timerRunning ? 1.0 : 1.45
                                    transformOrigin: Item.Center

                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 320
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Text {
                                        id: timerTimeText

                                        anchors.centerIn: parent
                                        text: TimerService.formatSeconds(TimerService.timerSecondsLeft)
                                        font.pixelSize: text.length > 5 ? 30 : 38
                                        font.family: "JetbrainsMono Nerd Font Propo"
                                        font.bold: true
                                        color: TimerService.timerRunning ? root.color1 : root.textBright

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 250
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: TimerService.toggleTimer()
                                }
                            }

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

                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 220
                                height: 38
                                radius: 10
                                color: root.surfaceContainer
                                border.width: timerManualIn.activeFocus ? 2 : 1
                                border.color: timerManualIn.activeFocus ? root.color1 : Qt.alpha(root.textColor, 0.08)

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 180
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 6

                                    Text {
                                        text: "Define:"
                                        font.family: "Google Sans"
                                        font.pixelSize: 11
                                        color: root.textMuted
                                    }

                                    TextInput {
                                        id: timerManualIn

                                        Layout.fillWidth: true
                                        text: Math.round(TimerService.timerTotalSeconds / 60).toString()
                                        color: root.textBright
                                        font.family: "Google Sans"
                                        font.pixelSize: 13
                                        font.bold: true
                                        selectByMouse: true
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
                                        text: "replay"
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 20
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
                                        text: TimerService.timerRunning ? "pause" : "play_arrow"
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 26
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

                    Rectangle {
                        id: stopwatchCard
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Math.round(Config.effectiveGeneralRadius * 0.88)
                        color: root.surface
                        border.color: Qt.alpha(root.textColor, 0.08)
                        border.width: 1
                        visible: TimerService.activeMode === "stopwatch"
                        opacity: stopwatchCardEntrance.opacity
                        scale: stopwatchCardEntrance.scale
                        transform: Translate {
                            y: stopwatchCardEntrance.offsetY
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 16

                            Item {
                                Layout.fillHeight: true
                            }

                            Text {
                                text: TimerService.formatSeconds(TimerService.stopwatchSeconds)
                                font.pixelSize: 58
                                font.family: "JetbrainsMono Nerd Font Propo"
                                font.bold: true
                                color: TimerService.stopwatchRunning ? root.color1 : root.textMuted
                                Layout.alignment: Qt.AlignHCenter
                            }

                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 18

                                Rectangle {
                                    implicitWidth: 44
                                    implicitHeight: 44
                                    radius: 22
                                    color: root.surfaceContainer

                                    Text {
                                        anchors.centerIn: parent
                                        text: "replay"
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 20
                                        color: root.textColor
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: TimerService.resetStopwatch()
                                    }

                                }

                                Rectangle {
                                    implicitWidth: 56
                                    implicitHeight: 56
                                    radius: 28
                                    color: root.color1
                                    scale: stopPlayH.hovered ? 1.06 : 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: TimerService.stopwatchRunning ? "pause" : "play_arrow"
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 26
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

                                Rectangle {
                                    implicitWidth: 44
                                    implicitHeight: 44
                                    radius: 22
                                    color: root.surfaceContainer
                                    opacity: TimerService.stopwatchRunning ? 1 : 0.4

                                    Text {
                                        anchors.centerIn: parent
                                        text: "flag"
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 20
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

                    AlarmView {
                        id: alarmView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: TimerService.activeMode === "alarm"
                        opacity: alarmCardEntrance.opacity
                        scale: alarmCardEntrance.scale
                        transform: Translate {
                            y: alarmCardEntrance.offsetY
                        }
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

}
