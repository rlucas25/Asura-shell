RowLayout {
    Layout.fillHeight: true
    Layout.fillWidth: true
    spacing: 12

    Rectangle {
        id: tasksPanel

        Layout.fillWidth: true
        Layout.fillHeight: true

        radius: 20
        color: root.surfaceContainer

        QtObject {
            id: taskStartTimeInput

            property string text: ""
            property string period: "AM"
            property bool activeFocus: taskStartTimeEditor.activeFocus

            function forceActiveFocus() {
                taskStartTimeEditor.forceActiveFocus()
            }
        }

        QtObject {
            id: taskEndTimeInput

            property string text: ""
            property string period: "AM"
            property bool activeFocus: taskEndTimeEditor.activeFocus

            function forceActiveFocus() {
                taskEndTimeEditor.forceActiveFocus()
            }
        }

        function normalize12Hour(value) {
            var clean = value.trim()

            if (!clean)
                return ""

            var parts = clean.split(":")
            var hour = parseInt(parts[0])
            var minute = parts.length > 1 ? parseInt(parts[1]) : 0

            if (isNaN(hour))
                return ""

            if (isNaN(minute))
                minute = 0

            hour = Math.max(1, Math.min(12, hour))
            minute = Math.max(0, Math.min(59, minute))

            return (hour < 10 ? "0" : "") + hour
                 + ":"
                 + (minute < 10 ? "0" : "") + minute
        }

        function displayTo24(value, period) {
            var normalized = normalize12Hour(value)

            if (!normalized)
                return ""

            var parts = normalized.split(":")
            var hour = parseInt(parts[0])
            var minute = parseInt(parts[1])

            if (period === "PM" && hour !== 12)
                hour += 12

            if (period === "AM" && hour === 12)
                hour = 0

            return (hour < 10 ? "0" : "") + hour
                 + ":"
                 + (minute < 10 ? "0" : "") + minute
        }

        function format12Hour(value) {
            if (!value || value.length < 4)
                return ""

            var parts = value.split(":")
            var hour = parseInt(parts[0])
            var minute = parseInt(parts[1])

            if (isNaN(hour) || isNaN(minute))
                return ""

            var period = hour >= 12 ? "PM" : "AM"
            var displayHour = hour % 12

            if (displayHour === 0)
                displayHour = 12

            return (displayHour < 10 ? "0" : "") + displayHour
                 + ":"
                 + (minute < 10 ? "0" : "") + minute
                 + " "
                 + period
        }

        function syncStartTime() {
            var value = taskStartTimeEditor.text.trim()
            if (!value) {
                taskStartTimeInput.text = ""
                return
            }

            if (!/^([1-9]|1[0-2])(:([0-5][0-9]))?$/.test(value))
                return

            taskStartTimeEditor.text = normalize12Hour(value)
            taskStartTimeInput.text =
                displayTo24(taskStartTimeEditor.text, taskStartTimeInput.period)
        }

        function syncEndTime() {
            var value = taskEndTimeEditor.text.trim()
            if (!value) {
                taskEndTimeInput.text = ""
                return
            }

            if (!/^([1-9]|1[0-2])(:([0-5][0-9]))?$/.test(value))
                return

            taskEndTimeEditor.text = normalize12Hour(value)
            taskEndTimeInput.text =
                displayTo24(taskEndTimeEditor.text, taskEndTimeInput.period)
        }

        function submitTask() {
            syncStartTime()
            syncEndTime()
            root.submitNewTask()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Tasks"

                        font.family: "Google Sans"
                        font.pixelSize: 18
                        font.weight: Font.DemiBold

                        color: root.textColor
                    }

                    Text {
                        text:
                            root.selectedDay
                            + " "
                            + root.monthNames[root.displayedMonth].substring(0, 3)

                        font.family: "Google Sans"
                        font.pixelSize: 10

                        color: root.textMuted
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 30

                    radius: 15
                    color: Qt.alpha(root.color1, 0.14)

                    Text {
                        anchors.centerIn: parent

                        text:
                            TaskService.getTasksForDate(
                                root.displayedYear,
                                root.displayedMonth,
                                root.selectedDay
                            ).length

                        font.family: "Google Sans"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold

                        color: root.color1
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 128

                radius: 20
                color: root.surface

                border.width:
                    taskInput.activeFocus
                    || taskStartTimeInput.activeFocus
                    || taskEndTimeInput.activeFocus
                    ? 2
                    : 1

                border.color:
                    taskInput.activeFocus
                    || taskStartTimeInput.activeFocus
                    || taskEndTimeInput.activeFocus
                    ? root.color1
                    : Qt.alpha(root.textColor, 0.08)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42

                            radius: 14
                            color: Qt.alpha(root.textColor, 0.04)

                            border.width: taskInput.activeFocus ? 2 : 1
                            border.color:
                                taskInput.activeFocus
                                ? root.color1
                                : Qt.alpha(root.textColor, 0.08)

                            TextInput {
                                id: taskInput

                                anchors.fill: parent

                                leftPadding: 14
                                rightPadding: 14

                                verticalAlignment: TextInput.AlignVCenter

                                font.family: "Google Sans"
                                font.pixelSize: 12

                                color: root.textColor

                                clip: true
                                selectByMouse: true

                                onAccepted: tasksPanel.submitTask()

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 14
                                    anchors.verticalCenter: parent.verticalCenter

                                    text: "New task"

                                    font.family: "Google Sans"
                                    font.pixelSize: 12

                                    color: root.textMuted

                                    visible:
                                        !taskInput.text
                                        && !taskInput.activeFocus
                                }
                            }
                        }

                        Rectangle {
                            id: addTaskButton

                            Layout.preferredWidth: 42
                            Layout.preferredHeight: 42

                            radius: 21
                            color: root.color1

                            scale:
                                addTaskMouse.pressed
                                ? 0.94
                                : addTaskHover.hovered
                                ? 1.04
                                : 1

                            Text {
                                anchors.centerIn: parent

                                text: "󰐕"

                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 20

                                color: root.foreground
                            }

                            HoverHandler {
                                id: addTaskHover
                            }

                            MouseArea {
                                id: addTaskMouse

                                anchors.fill: parent

                                cursorShape: Qt.PointingHandCursor

                                onClicked: tasksPanel.submitTask()
                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 140
                                    easing.type: Easing.OutBack
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Rectangle {
                            Layout.preferredWidth:
                                dateChipContent.implicitWidth + 26

                            Layout.preferredHeight: 42

                            radius: 14

                            color:
                                root.taskIncludeDate
                                ? Qt.alpha(root.color1, 0.14)
                                : Qt.alpha(root.textColor, 0.04)

                            border.width: 1

                            border.color:
                                root.taskIncludeDate
                                ? Qt.alpha(root.color1, 0.55)
                                : Qt.alpha(root.textColor, 0.08)

                            RowLayout {
                                id: dateChipContent

                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: "󰸗"

                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 16

                                    color:
                                        root.taskIncludeDate
                                        ? root.color1
                                        : root.textMuted
                                }

                                Text {
                                    text:
                                        root.taskIncludeDate
                                        ? root.selectedDay
                                          + " "
                                          + root.monthNames[root.displayedMonth].substring(0, 3)
                                        : "No date"

                                    font.family: "Google Sans"
                                    font.pixelSize: 10
                                    font.weight:
                                        root.taskIncludeDate
                                        ? Font.DemiBold
                                        : Font.Normal

                                    color:
                                        root.taskIncludeDate
                                        ? root.color1
                                        : root.textMuted
                                }
                            }

                            MouseArea {
                                anchors.fill: parent

                                cursorShape: Qt.PointingHandCursor

                                onClicked:
                                    root.taskIncludeDate =
                                        !root.taskIncludeDate
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 160
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 126
                            Layout.preferredHeight: 42

                            radius: 14

                            color:
                                taskStartTimeInput.activeFocus
                                ? Qt.alpha(root.color1, 0.08)
                                : Qt.alpha(root.textColor, 0.04)

                            border.width:
                                taskStartTimeInput.activeFocus ? 2 : 1

                            border.color:
                                taskStartTimeInput.activeFocus
                                ? root.color1
                                : Qt.alpha(root.textColor, 0.08)

                            RowLayout {
                                anchors.fill: parent

                                anchors.leftMargin: 12
                                anchors.rightMargin: 5

                                spacing: 4

                                Text {
                                    text: "Start"

                                    font.family: "Google Sans"
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold

                                    color: root.textMuted
                                }

                                TextInput {
                                    id: taskStartTimeEditor

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28

                                    verticalAlignment: TextInput.AlignVCenter

                                    font.family: "Google Sans"
                                    font.pixelSize: 12
                                    font.weight: Font.Medium

                                    color: root.textColor

                                    clip: true
                                    selectByMouse: true
                                    maximumLength: 5

                                    inputMethodHints: Qt.ImhTime

                                    validator: RegularExpressionValidator {
                                        regularExpression:
                                            /^$|^([1-9]|1[0-2])(:([0-5]?[0-9])?)?$/
                                    }

                                    onEditingFinished:
                                        tasksPanel.syncStartTime()

                                    onAccepted: {
                                        tasksPanel.syncStartTime()
                                        tasksPanel.submitTask()
                                    }

                                    Text {
                                        anchors.fill: parent

                                        verticalAlignment: Text.AlignVCenter

                                        text: "hh:mm"

                                        font.family: "Google Sans"
                                        font.pixelSize: 11

                                        color: root.textMuted

                                        visible:
                                            !taskStartTimeEditor.text
                                            && !taskStartTimeEditor.activeFocus
                                    }
                                }

                                RowLayout {
                                    spacing: 1

                                    Repeater {
                                        model: ["AM", "PM"]

                                        delegate: Rectangle {
                                            required property string modelData

                                            Layout.preferredWidth: 28
                                            Layout.preferredHeight: 30

                                            radius: 10

                                            color:
                                                taskStartTimeInput.period
                                                === modelData
                                                ? Qt.alpha(root.color1, 0.18)
                                                : "transparent"

                                            Text {
                                                anchors.centerIn: parent

                                                text: modelData

                                                font.family: "Google Sans"
                                                font.pixelSize: 8
                                                font.weight: Font.DemiBold

                                                color:
                                                    taskStartTimeInput.period
                                                    === modelData
                                                    ? root.color1
                                                    : root.textMuted
                                            }

                                            MouseArea {
                                                anchors.fill: parent

                                                cursorShape:
                                                    Qt.PointingHandCursor

                                                onClicked: {
                                                    taskStartTimeInput.period =
                                                        modelData
                                                    tasksPanel.syncStartTime()
                                                }
                                            }

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 150
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 126
                            Layout.preferredHeight: 42

                            radius: 14

                            color:
                                taskEndTimeInput.activeFocus
                                ? Qt.alpha(root.color1, 0.08)
                                : Qt.alpha(root.textColor, 0.04)

                            border.width:
                                taskEndTimeInput.activeFocus ? 2 : 1

                            border.color:
                                taskEndTimeInput.activeFocus
                                ? root.color1
                                : Qt.alpha(root.textColor, 0.08)

                            RowLayout {
                                anchors.fill: parent

                                anchors.leftMargin: 12
                                anchors.rightMargin: 5

                                spacing: 4

                                Text {
                                    text: "End"

                                    font.family: "Google Sans"
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold

                                    color: root.textMuted
                                }

                                TextInput {
                                    id: taskEndTimeEditor

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28

                                    verticalAlignment: TextInput.AlignVCenter

                                    font.family: "Google Sans"
                                    font.pixelSize: 12
                                    font.weight: Font.Medium

                                    color: root.textColor

                                    clip: true
                                    selectByMouse: true
                                    maximumLength: 5

                                    inputMethodHints: Qt.ImhTime

                                    validator: RegularExpressionValidator {
                                        regularExpression:
                                            /^$|^([1-9]|1[0-2])(:([0-5]?[0-9])?)?$/
                                    }

                                    onEditingFinished:
                                        tasksPanel.syncEndTime()

                                    onAccepted: {
                                        tasksPanel.syncEndTime()
                                        tasksPanel.submitTask()
                                    }

                                    Text {
                                        anchors.fill: parent

                                        verticalAlignment: Text.AlignVCenter

                                        text: "hh:mm"

                                        font.family: "Google Sans"
                                        font.pixelSize: 11

                                        color: root.textMuted

                                        visible:
                                            !taskEndTimeEditor.text
                                            && !taskEndTimeEditor.activeFocus
                                    }
                                }

                                RowLayout {
                                    spacing: 1

                                    Repeater {
                                        model: ["AM", "PM"]

                                        delegate: Rectangle {
                                            required property string modelData

                                            Layout.preferredWidth: 28
                                            Layout.preferredHeight: 30

                                            radius: 10

                                            color:
                                                taskEndTimeInput.period
                                                === modelData
                                                ? Qt.alpha(root.color1, 0.18)
                                                : "transparent"

                                            Text {
                                                anchors.centerIn: parent

                                                text: modelData

                                                font.family: "Google Sans"
                                                font.pixelSize: 8
                                                font.weight: Font.DemiBold

                                                color:
                                                    taskEndTimeInput.period
                                                    === modelData
                                                    ? root.color1
                                                    : root.textMuted
                                            }

                                            MouseArea {
                                                anchors.fill: parent

                                                cursorShape:
                                                    Qt.PointingHandCursor

                                                onClicked: {
                                                    taskEndTimeInput.period =
                                                        modelData
                                                    tasksPanel.syncEndTime()
                                                }
                                            }

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 150
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            readonly property bool canNotify:
                                root.taskIncludeDate
                                && taskStartTimeInput.text.length > 0

                            Layout.preferredWidth: 42
                            Layout.preferredHeight: 42

                            radius: 14

                            color:
                                canNotify && root.taskNotify
                                ? Qt.alpha(root.color1, 0.16)
                                : Qt.alpha(root.textColor, 0.04)

                            border.width: 1

                            border.color:
                                canNotify && root.taskNotify
                                ? Qt.alpha(root.color1, 0.5)
                                : Qt.alpha(root.textColor, 0.08)

                            Text {
                                anchors.centerIn: parent

                                text:
                                    root.taskNotify && parent.canNotify
                                    ? "󰂚"
                                    : "󰂛"

                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 18

                                color:
                                    root.taskNotify && parent.canNotify
                                    ? root.color1
                                    : root.textMuted
                            }

                            MouseArea {
                                anchors.fill: parent

                                cursorShape:
                                    Qt.PointingHandCursor

                                onClicked: {
                                    if (parent.canNotify) {
                                        root.taskNotify =
                                            !root.taskNotify
                                    } else {
                                        taskStartTimeInput.forceActiveFocus()
                                    }
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
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
                            model:
                                TaskService.getTasksForDate(
                                    root.displayedYear,
                                    root.displayedMonth,
                                    root.selectedDay
                                )

                            delegate: Rectangle {
                                id: taskItemRoot

                                required property var modelData

                                readonly property bool isOverdue:
                                    TaskService.isOverdue(
                                        taskItemRoot.modelData
                                    )

                                Layout.fillWidth: true

                                Layout.preferredHeight:
                                    taskSubtitleRow.visible
                                    ? 62
                                    : 52

                                radius: 16

                                color:
                                    taskItemHover.hovered
                                    ? Qt.alpha(root.textColor, 0.05)
                                    : "transparent"

                                RowLayout {
                                    anchors.fill: parent

                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10

                                    spacing: 10

                                    Rectangle {
                                        Layout.preferredWidth: 22
                                        Layout.preferredHeight: 22

                                        radius: 11

                                        color:
                                            taskItemRoot.modelData.done
                                            ? root.color1
                                            : "transparent"

                                        border.width:
                                            taskItemRoot.modelData.done
                                            ? 0
                                            : 2

                                        border.color:
                                            taskItemRoot.modelData.done
                                            ? root.color1
                                            : root.textMuted

                                        Text {
                                            anchors.centerIn: parent

                                            text: "✓"

                                            font.family: "Google Sans"
                                            font.pixelSize: 11
                                            font.weight: Font.Bold

                                            color: root.foreground

                                            visible:
                                                taskItemRoot.modelData.done
                                        }

                                        MouseArea {
                                            anchors.fill: parent

                                            cursorShape:
                                                Qt.PointingHandCursor

                                            onClicked:
                                                TaskService.toggleTask(
                                                    taskItemRoot.modelData.id
                                                )
                                        }

                                        scale:
                                            taskCheckHover.hovered
                                            ? 1.08
                                            : 1

                                        HoverHandler {
                                            id: taskCheckHover
                                        }

                                        Behavior on scale {
                                            NumberAnimation {
                                                duration: 120
                                                easing.type: Easing.OutBack
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true

                                        spacing: 3

                                        Text {
                                            Layout.fillWidth: true

                                            text:
                                                taskItemRoot.modelData.text

                                            font.family: "Google Sans"
                                            font.pixelSize: 11
                                            font.weight: Font.Medium

                                            font.strikeout:
                                                taskItemRoot.modelData.done

                                            color:
                                                taskItemRoot.modelData.done
                                                ? root.color1
                                                : root.textColor

                                            elide: Text.ElideRight
                                        }

                                        RowLayout {
                                            id: taskSubtitleRow

                                            Layout.fillWidth: true

                                            spacing: 6

                                            visible:
                                                taskSubtitleText.text.length > 0

                                            Text {
                                                id: taskSubtitleText

                                                Layout.fillWidth: true

                                                text: {
                                                    var str = ""

                                                    var startDisp =
                                                        tasksPanel.format12Hour(
                                                            taskItemRoot.modelData.startTime
                                                        )

                                                    var endDisp =
                                                        tasksPanel.format12Hour(
                                                            taskItemRoot.modelData.endTime
                                                        )

                                                    var timeRange =
                                                        startDisp
                                                        + (
                                                            endDisp
                                                            ? " - " + endDisp
                                                            : ""
                                                        )

                                                    if (taskItemRoot.isOverdue) {
                                                        str =
                                                            taskItemRoot.modelData.date

                                                        if (timeRange)
                                                            str +=
                                                                " • "
                                                                + timeRange
                                                    } else if (timeRange) {
                                                        str = timeRange
                                                    }

                                                    return str
                                                }

                                                font.family: "Google Sans"
                                                font.pixelSize: 9

                                                font.weight:
                                                    taskItemRoot.isOverdue
                                                    ? Font.DemiBold
                                                    : Font.Normal

                                                color:
                                                    taskItemRoot.isOverdue
                                                    ? root.color2
                                                    : root.textMuted

                                                elide:
                                                    Text.ElideRight
                                            }

                                            Rectangle {
                                                visible:
                                                    !!taskItemRoot.modelData.notify
                                                    && !taskItemRoot.modelData.done

                                                Layout.preferredWidth: 22
                                                Layout.preferredHeight: 22

                                                radius: 11

                                                color:
                                                    Qt.alpha(
                                                        root.color1,
                                                        0.12
                                                    )

                                                Text {
                                                    anchors.centerIn: parent

                                                    text: "󰂚"

                                                    font.family:
                                                        "Material Symbols Rounded"

                                                    font.pixelSize: 12

                                                    color: root.color1
                                                }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 30
                                        Layout.preferredHeight: 30

                                        radius: 15

                                        visible:
                                            taskItemHover.hovered

                                        color:
                                            Qt.alpha(
                                                root.textColor,
                                                0.07
                                            )

                                        Text {
                                            anchors.centerIn: parent

                                            text: "󰅖"

                                            font.family:
                                                "Material Symbols Rounded"

                                            font.pixelSize: 16

                                            color: root.textMuted
                                        }

                                        MouseArea {
                                            anchors.fill: parent

                                            cursorShape:
                                                Qt.PointingHandCursor

                                            onClicked:
                                                TaskService.removeTask(
                                                    taskItemRoot.modelData.id
                                                )
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
                            visible:
                                TaskService.getTasksForDate(
                                    root.displayedYear,
                                    root.displayedMonth,
                                    root.selectedDay
                                ).length === 0

                            Layout.fillWidth: true
                            Layout.preferredHeight: 112

                            radius: 18

                            color:
                                Qt.alpha(
                                    root.textColor,
                                    0.03
                                )

                            ColumnLayout {
                                anchors.centerIn: parent

                                spacing: 8

                                Text {
                                    Layout.alignment:
                                        Qt.AlignHCenter

                                    text: "󰷐"

                                    font.family:
                                        "Material Symbols Rounded"

                                    font.pixelSize: 30

                                    color: root.textMuted
                                }

                                Text {
                                    Layout.alignment:
                                        Qt.AlignHCenter

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

            Behavior on border.color {
                ColorAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}