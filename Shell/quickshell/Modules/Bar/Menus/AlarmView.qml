import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Asura
import qs.Services

Item {
    id: root

    // Semantic Colors
    property color primary: Colors.cfg.primary
    property color secondary: Colors.cfg.secondary
    property color surfaceContainer: Colors.cfg.surfaceContainer
    property color surfaceVariant: Colors.cfg.surfaceVariant
    property color background: Colors.cfg.background
    property color text: Colors.cfg.text
    property color textSecondary: Colors.cfg.textSecondary
    property color textBright: Colors.cfg.textBright
    property color foreground: Colors.cfg.on_primary
    property color errorCol: Colors.cfg.error
    property color successCol: Colors.cfg.success
    property color warningCol: Colors.cfg.warning

    // Form state (New / Edit)
    property bool isFormOpen: false
    property bool isEditing: false
    property string editingId: ""
    property int formHour: 7
    property int formMinute: 0
    property string formTitle: ""
    property var formDays: []

    // Open form for a new alarm
    function openNewAlarm() {
        var now = new Date();
        formHour = (now.getHours() + 1) % 24;
        formMinute = 0;
        formTitle = "";
        formDays = [];
        isEditing = false;
        editingId = "";
        isFormOpen = true;
    }

    // Open form to edit an existing alarm
    function openEditAlarm(alarm) {
        formHour = alarm.hour;
        formMinute = alarm.minute;
        formTitle = alarm.title ? alarm.title : "";
        formDays = alarm.days ? alarm.days.slice() : [];
        isEditing = true;
        editingId = alarm.id;
        isFormOpen = true;
    }

    // Toggle a day index in formDays (0 = Sun .. 6 = Sat)
    function toggleFormDay(dayIdx) {
        var arr = formDays.slice();
        var idx = arr.indexOf(dayIdx);
        if (idx !== -1) {
            arr.splice(idx, 1);
        } else {
            arr.push(dayIdx);
            arr.sort((a, b) => a - b);
        }
        formDays = arr;
    }

    // Save alarm from form
    function saveForm() {
        var title = formTitle.trim() ? formTitle.trim() : "Alarm";
        if (isEditing) {
            AlarmService.updateAlarm(editingId, title, formHour, formMinute, formDays);
        } else {
            AlarmService.addAlarm(title, formHour, formMinute, formDays);
        }
        isFormOpen = false;
    }

    // Cancel form
    function cancelForm() {
        isFormOpen = false;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // === RINGING ALERT BANNER ===
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: AlarmService.isRinging ? 52 : 0
            radius: 12
            color: Qt.alpha(root.errorCol, 0.22)
            border.color: root.errorCol
            border.width: 1
            visible: AlarmService.isRinging
            clip: true

            Behavior on Layout.preferredHeight {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutQuad
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 12

                // Ringing animated icon
                Text {
                    text: "󰀠"
                    font.pixelSize: 22
                    color: root.errorCol

                    SequentialAnimation on scale {
                        running: AlarmService.isRinging
                        loops: Animation.Infinite
                        NumberAnimation {
                            to: 1.25
                            duration: 400
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            to: 1.0
                            duration: 400
                            easing.type: Easing.InOutQuad
                        }
                    }
                }

                // Ringing alert details
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "Alarm Ringing!"
                        font.pixelSize: 13
                        font.bold: true
                        color: root.textBright
                    }

                    Text {
                        text: AlarmService.activeRingingAlarm ? (AlarmService.activeRingingAlarm.title + " • " + AlarmService.formatTime(AlarmService.activeRingingAlarm.hour, AlarmService.activeRingingAlarm.minute)) : "Ringing now"
                        font.pixelSize: 11
                        color: root.textSecondary
                        elide: Text.ElideRight
                    }
                }

                // Dismiss button
                Rectangle {
                    implicitWidth: 120
                    implicitHeight: 32
                    radius: 16
                    color: root.errorCol

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "󰅖"
                            font.pixelSize: 13
                            color: root.foreground
                        }

                        Text {
                            text: "Dismiss"
                            font.pixelSize: 12
                            font.bold: true
                            color: root.foreground
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: AlarmService.dismissAlarm()
                    }
                }
            }
        }

        // === HEADER CONTROLS ===
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            spacing: 10

            // Title and active count badge
            RowLayout {
                spacing: 8

                Text {
                    text: "󰀠"
                    font.pixelSize: 18
                    color: root.primary
                }

                Text {
                    text: "Alarms"
                    font.pixelSize: 15
                    font.bold: true
                    color: root.textBright
                }

                Rectangle {
                    implicitWidth: countText.implicitWidth + 14
                    implicitHeight: 20
                    radius: 10
                    color: AlarmService.activeCount > 0 ? Qt.alpha(root.primary, 0.18) : root.surfaceContainer
                    border.color: AlarmService.activeCount > 0 ? Qt.alpha(root.primary, 0.35) : "transparent"

                    Text {
                        id: countText
                        anchors.centerIn: parent
                        text: AlarmService.activeCount + " active"
                        font.pixelSize: 10
                        font.bold: true
                        color: AlarmService.activeCount > 0 ? root.primary : root.textSecondary
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            // New Alarm Button
            Rectangle {
                implicitWidth: addBtnRow.implicitWidth + 24
                implicitHeight: 32
                radius: 16
                color: addHover.hovered ? Qt.alpha(root.primary, 0.9) : root.primary
                visible: !root.isFormOpen

                RowLayout {
                    id: addBtnRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "+"
                        font.pixelSize: 16
                        font.bold: true
                        color: root.foreground
                    }

                    Text {
                        text: "New Alarm"
                        font.pixelSize: 11
                        font.bold: true
                        color: root.foreground
                    }
                }

                HoverHandler {
                    id: addHover
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openNewAlarm()
                }
            }
        }

        // === MAIN CONTENT ===
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.isFormOpen ? 1 : 0

            // === ALARMS LIST VIEW ===
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Empty state display
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    visible: AlarmService.alarms.length === 0

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰀠"
                        font.pixelSize: 52
                        color: Qt.alpha(root.textSecondary, 0.35)
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "No alarms configured"
                        font.pixelSize: 14
                        font.bold: true
                        color: root.textSecondary
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Create one-time or recurring alarms for your daily routine."
                        font.pixelSize: 11
                        color: Qt.alpha(root.textSecondary, 0.7)
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 140
                        implicitHeight: 34
                        radius: 17
                        color: Qt.alpha(root.primary, 0.2)
                        border.color: root.primary

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "+"
                                font.pixelSize: 14
                                font.bold: true
                                color: root.primary
                            }

                            Text {
                                text: "Create First"
                                font.pixelSize: 11
                                font.bold: true
                                color: root.primary
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openNewAlarm()
                        }
                    }
                }

                // Scrollable list of alarms
                ListView {
                    id: alarmList
                    anchors.fill: parent
                    clip: true
                    spacing: 8
                    visible: AlarmService.alarms.length > 0
                    model: AlarmService.alarms

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    // Alarm card delegate
                    delegate: Rectangle {
                        id: cardRoot
                        required property var modelData
                        required property int index

                        readonly property var liveAlarm: {
                            var id = cardRoot.modelData.id;
                            var arr = AlarmService.alarms;
                            for (var i = 0; i < arr.length; i++) {
                                if (arr[i].id === id) return arr[i];
                            }
                            return cardRoot.modelData;
                        }
                        readonly property var liveDays: liveAlarm.days && Array.isArray(liveAlarm.days) ? liveAlarm.days : []

                        width: alarmList.width
                        implicitHeight: 74
                        radius: 14
                        color: liveAlarm.enabled ? root.surfaceContainer : Qt.alpha(root.surfaceContainer, 0.45)
                        border.color: liveAlarm.enabled ? Qt.alpha(root.primary, 0.2) : Qt.alpha(root.textSecondary, 0.08)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 16

                            Rectangle {
                                implicitWidth: 38
                                implicitHeight: 38
                                radius: 19
                                color: cardRoot.liveAlarm.enabled ? Qt.alpha(root.primary, 0.18) : Qt.alpha(root.textSecondary, 0.1)

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰀠"
                                    font.pixelSize: 18
                                    color: cardRoot.liveAlarm.enabled ? root.primary : root.textSecondary
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    spacing: 10
                                    Layout.alignment: Qt.AlignLeft

                                    Text {
                                        text: AlarmService.formatTime(cardRoot.liveAlarm.hour, cardRoot.liveAlarm.minute)
                                        font.pixelSize: 26
                                        font.bold: true
                                        font.family: "jetbrainsMono Nerd Font Propo"
                                        color: cardRoot.liveAlarm.enabled ? root.textBright : root.textSecondary
                                    }

                                    Text {
                                        text: cardRoot.liveAlarm.title ? cardRoot.liveAlarm.title : "Alarm"
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: cardRoot.liveAlarm.enabled ? root.text : root.textSecondary
                                        elide: Text.ElideRight
                                        Layout.maximumWidth: 260
                                    }
                                }

                                RowLayout {
                                    spacing: 4

                                    Repeater {
                                        model: [0, 1, 2, 3, 4, 5, 6]

                                        delegate: Rectangle {
                                            required property int modelData
                                            required property int index

                                            readonly property bool isDayActive: cardRoot.liveDays.indexOf(modelData) !== -1

                                            implicitWidth: 22
                                            implicitHeight: 18
                                            radius: 4
                                            color: {
                                                if (!cardRoot.liveAlarm.enabled)
                                                    return isDayActive ? Qt.alpha(root.textSecondary, 0.15) : "transparent";
                                                return isDayActive ? Qt.alpha(root.primary, 0.22) : Qt.alpha(root.surfaceVariant, 0.3);
                                            }
                                            border.color: isDayActive && cardRoot.liveAlarm.enabled ? root.primary : "transparent"
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: AlarmService.dayLabels[modelData][0]
                                                font.pixelSize: 9
                                                font.bold: isDayActive
                                                color: {
                                                    if (!cardRoot.liveAlarm.enabled)
                                                        return isDayActive ? root.textSecondary : Qt.alpha(root.textSecondary, 0.4);
                                                    return isDayActive ? root.primary : Qt.alpha(root.textSecondary, 0.5);
                                                }
                                            }
                                        }
                                    }

                                    Item {
                                        implicitWidth: 6
                                    }

                                    Text {
                                        text: "• " + AlarmService.formatDaysSummary(cardRoot.liveDays)
                                        font.pixelSize: 10
                                        color: cardRoot.liveAlarm.enabled ? root.textSecondary : Qt.alpha(root.textSecondary, 0.6)
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            // Edit and delete controls
                            RowLayout {
                                spacing: 10

                                // Edit button
                                Rectangle {
                                    implicitWidth: 32
                                    implicitHeight: 32
                                    radius: 16
                                    color: editH.hovered ? Qt.alpha(root.primary, 0.2) : Qt.alpha(root.background, 0.6)

                                    HoverHandler {
                                        id: editH
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰏫"
                                        font.pixelSize: 14
                                        color: editH.hovered ? root.primary : root.textSecondary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.openEditAlarm(cardRoot.modelData)
                                    }
                                }

                                // Delete button
                                Rectangle {
                                    implicitWidth: 32
                                    implicitHeight: 32
                                    radius: 16
                                    color: delH.hovered ? Qt.alpha(root.errorCol, 0.22) : Qt.alpha(root.background, 0.6)

                                    HoverHandler {
                                        id: delH
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰆴"
                                        font.pixelSize: 14
                                        color: delH.hovered ? root.errorCol : root.textSecondary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: AlarmService.removeAlarm(cardRoot.modelData.id)
                                    }
                                }

                                Item {
                                    implicitWidth: 4
                                }

                                // Toggle switch
                                Rectangle {
                                    id: toggleTrack
                                    implicitWidth: 46
                                    implicitHeight: 24
                                    radius: 12
                                    color: cardRoot.modelData.enabled ? root.primary : Qt.alpha(root.surfaceVariant, 0.8)

                                    Rectangle {
                                        id: toggleKnob
                                        width: 18
                                        height: 18
                                        radius: 9
                                        color: cardRoot.modelData.enabled ? root.foreground : root.textSecondary
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: cardRoot.modelData.enabled ? parent.width - width - 3 : 3

                                        Behavior on x {
                                            NumberAnimation {
                                                duration: 150
                                                easing.type: Easing.OutQuad
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: AlarmService.toggleAlarm(cardRoot.modelData.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // === CREATE OR EDIT FORM PANEL ===
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 16
                color: root.surfaceContainer
                border.color: Qt.alpha(root.primary, 0.25)
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // Form header
                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: root.isEditing ? "Edit Alarm" : "Add New Alarm"
                            font.pixelSize: 14
                            font.bold: true
                            color: root.textBright
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            implicitWidth: 26
                            implicitHeight: 26
                            radius: 13
                            color: Qt.alpha(root.background, 0.6)

                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                font.pixelSize: 12
                                color: root.textSecondary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.cancelForm()
                            }
                        }
                    }

                    // Time spinners
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 16

                        // Hours selector
                        ColumnLayout {
                            spacing: 4
                            Layout.alignment: Qt.AlignHCenter

                            Text {
                                text: "HOUR"
                                font.pixelSize: 9
                                font.bold: true
                                color: root.textSecondary
                                Layout.alignment: Qt.AlignHCenter
                            }

                            RowLayout {
                                spacing: 6

                                Rectangle {
                                    implicitWidth: 28
                                    implicitHeight: 28
                                    radius: 14
                                    color: Qt.alpha(root.primary, 0.15)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "−"
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: root.primary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.formHour = (root.formHour - 1 + 24) % 24
                                    }
                                }

                                Rectangle {
                                    implicitWidth: 60
                                    implicitHeight: 40
                                    radius: 8
                                    color: root.background
                                    border.color: Qt.alpha(root.primary, 0.3)

                                    TextInput {
                                        id: hourInput
                                        anchors.centerIn: parent
                                        text: {
                                            var h12 = root.formHour % 12;
                                            if (h12 === 0) h12 = 12;
                                            return (h12 < 10 ? "0" : "") + h12;
                                        }
                                        color: root.textBright
                                        font.pixelSize: 20
                                        font.bold: true
                                        font.family: "JetbrainsMono Nerd Font Propo"
                                        horizontalAlignment: Text.AlignHCenter
                                        inputMethodHints: Qt.ImhDigitsOnly
                                        maximumLength: 2
                                        onEditingFinished: {
                                            var val = parseInt(text);
                                            if (!isNaN(val)) {
                                                val = Math.max(1, Math.min(12, val));
                                                var isPm = root.formHour >= 12;
                                                if (val === 12) {
                                                    root.formHour = isPm ? 12 : 0;
                                                } else {
                                                    root.formHour = isPm ? (val + 12) : val;
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    implicitWidth: 28
                                    implicitHeight: 28
                                    radius: 14
                                    color: Qt.alpha(root.primary, 0.15)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "+"
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: root.primary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.formHour = (root.formHour + 1) % 24
                                    }
                                }
                            }
                        }

                        Text {
                            text: ":"
                            font.pixelSize: 28
                            font.bold: true
                            color: root.primary
                            Layout.alignment: Qt.AlignVCenter
                        }

                        // Minutes selector
                        ColumnLayout {
                            spacing: 4
                            Layout.alignment: Qt.AlignHCenter

                            Text {
                                text: "MINUTE"
                                font.pixelSize: 9
                                font.bold: true
                                color: root.textSecondary
                                Layout.alignment: Qt.AlignHCenter
                            }

                            RowLayout {
                                spacing: 6

                                Rectangle {
                                    implicitWidth: 28
                                    implicitHeight: 28
                                    radius: 14
                                    color: Qt.alpha(root.primary, 0.15)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "−"
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: root.primary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.formMinute = (root.formMinute - 1 + 60) % 60
                                    }
                                }

                                Rectangle {
                                    implicitWidth: 60
                                    implicitHeight: 40
                                    radius: 8
                                    color: root.background
                                    border.color: Qt.alpha(root.primary, 0.3)

                                    TextInput {
                                        id: minInput
                                        anchors.centerIn: parent
                                        text: (root.formMinute < 10 ? "0" : "") + root.formMinute
                                        color: root.textBright
                                        font.pixelSize: 20
                                        font.bold: true
                                        font.family: "JetbrainsMono Nerd Font Propo"
                                        horizontalAlignment: Text.AlignHCenter
                                        inputMethodHints: Qt.ImhDigitsOnly
                                        maximumLength: 2
                                        onEditingFinished: {
                                            var val = parseInt(text);
                                            if (!isNaN(val))
                                                root.formMinute = Math.max(0, Math.min(59, val));

                                        }
                                    }
                                }

                                Rectangle {
                                    implicitWidth: 28
                                    implicitHeight: 28
                                    radius: 14
                                    color: Qt.alpha(root.primary, 0.15)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "+"
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: root.primary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.formMinute = (root.formMinute + 1) % 60
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            spacing: 4
                            Layout.alignment: Qt.AlignHCenter

                            Text {
                                text: "PERIOD"
                                font.pixelSize: 9
                                font.bold: true
                                color: root.textSecondary
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Rectangle {
                                implicitWidth: 46
                                implicitHeight: 40
                                radius: 8
                                color: Qt.alpha(root.primary, 0.15)
                                border.color: Qt.alpha(root.primary, 0.3)

                                Text {
                                    anchors.centerIn: parent
                                    text: root.formHour >= 12 ? "PM" : "AM"
                                    font.pixelSize: 14
                                    font.bold: true
                                    font.family: "JetbrainsMono Nerd Font Propo"
                                    color: root.primary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.formHour >= 12) {
                                            root.formHour -= 12;
                                        } else {
                                            root.formHour += 12;
                                        }
                                    }
                                }
                            }
                        }

                        // Quick time presets
                        RowLayout {
                            spacing: 6
                            Layout.leftMargin: 10

                            Repeater {
                                model: [{
                                    "label": "+15m",
                                    "action": function() {
                                        var m = root.formMinute + 15;
                                        if (m >= 60) {
                                            root.formHour = (root.formHour + Math.floor(m / 60)) % 24;
                                            root.formMinute = m % 60;
                                        } else {
                                            root.formMinute = m;
                                        }
                                    }
                                }, {
                                    "label": "+30m",
                                    "action": function() {
                                        var m = root.formMinute + 30;
                                        if (m >= 60) {
                                            root.formHour = (root.formHour + Math.floor(m / 60)) % 24;
                                            root.formMinute = m % 60;
                                        } else {
                                            root.formMinute = m;
                                        }
                                    }
                                }, {
                                    "label": "07:00 AM",
                                    "action": function() {
                                        root.formHour = 7;
                                        root.formMinute = 0;
                                    }
                                }, {
                                    "label": "08:00 AM",
                                    "action": function() {
                                        root.formHour = 8;
                                        root.formMinute = 0;
                                    }
                                }]

                                delegate: Rectangle {
                                    required property var modelData
                                    implicitWidth: presetText.implicitWidth + 14
                                    implicitHeight: 24
                                    radius: 6
                                    color: Qt.alpha(root.background, 0.7)
                                    border.color: Qt.alpha(root.textSecondary, 0.15)

                                    Text {
                                        id: presetText
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: root.textSecondary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: modelData.action()
                                    }
                                }
                            }
                        }
                    }

                    // Title text field
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: "TITLE / NAME"
                            font.pixelSize: 9
                            font.bold: true
                            color: root.textSecondary
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 36
                            radius: 8
                            color: root.background
                            border.color: titleIn.activeFocus ? root.primary : Qt.alpha(root.textSecondary, 0.15)

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                Text {
                                    text: "󰏫"
                                    font.pixelSize: 13
                                    color: root.textSecondary
                                }

                                TextInput {
                                    id: titleIn
                                    Layout.fillWidth: true
                                    text: root.formTitle
                                    color: root.textBright
                                    font.pixelSize: 12
                                    font.bold: true
                                    onTextChanged: root.formTitle = text
                                }

                                Text {
                                    text: "e.g. Wake up, Meeting"
                                    font.pixelSize: 11
                                    color: Qt.alpha(root.textSecondary, 0.4)
                                    visible: titleIn.text.length === 0 && !titleIn.activeFocus
                                }
                            }
                        }
                    }

                    // Recurrence selector
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "REPEAT"
                                font.pixelSize: 9
                                font.bold: true
                                color: root.textSecondary
                            }

                            Text {
                                text: "• " + AlarmService.formatDaysSummary(root.formDays)
                                font.pixelSize: 10
                                color: root.primary
                                font.bold: true
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            // Quick day presets
                            RowLayout {
                                spacing: 6

                                Rectangle {
                                    implicitWidth: 64
                                    implicitHeight: 20
                                    radius: 10
                                    color: Qt.alpha(root.background, 0.7)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Weekdays"
                                        font.pixelSize: 9
                                        color: root.textSecondary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.formDays = [1, 2, 3, 4, 5]
                                    }
                                }

                                Rectangle {
                                    implicitWidth: 64
                                    implicitHeight: 20
                                    radius: 10
                                    color: Qt.alpha(root.background, 0.7)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Weekend"
                                        font.pixelSize: 9
                                        color: root.textSecondary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.formDays = [0, 6]
                                    }
                                }

                                Rectangle {
                                    implicitWidth: 64
                                    implicitHeight: 20
                                    radius: 10
                                    color: Qt.alpha(root.background, 0.7)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Every Day"
                                        font.pixelSize: 9
                                        color: root.textSecondary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.formDays = [0, 1, 2, 3, 4, 5, 6]
                                    }
                                }

                                Rectangle {
                                    implicitWidth: 54
                                    implicitHeight: 20
                                    radius: 10
                                    color: Qt.alpha(root.background, 0.7)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Once"
                                        font.pixelSize: 9
                                        color: root.textSecondary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.formDays = []
                                    }
                                }
                            }
                        }

                        // Day selector chips
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: [0, 1, 2, 3, 4, 5, 6]

                                delegate: Rectangle {
                                    required property int modelData
                                    required property int index

                                    readonly property bool isSelected: root.formDays.indexOf(modelData) !== -1

                                    Layout.fillWidth: true
                                    implicitHeight: 32
                                    radius: 8
                                    color: isSelected ? root.primary : root.background
                                    border.color: isSelected ? root.primary : Qt.alpha(root.textSecondary, 0.15)

                                    Text {
                                        anchors.centerIn: parent
                                        text: AlarmService.dayLabels[modelData]
                                        font.pixelSize: 11
                                        font.bold: isSelected
                                        color: isSelected ? root.foreground : root.textSecondary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.toggleFormDay(modelData)
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }

                    // Form action buttons
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Item {
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            implicitWidth: 90
                            implicitHeight: 34
                            radius: 17
                            color: Qt.alpha(root.background, 0.8)
                            border.color: Qt.alpha(root.textSecondary, 0.2)

                            Text {
                                anchors.centerIn: parent
                                text: "Cancel"
                                font.pixelSize: 11
                                font.bold: true
                                color: root.textSecondary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.cancelForm()
                            }
                        }

                        Rectangle {
                            implicitWidth: 120
                            implicitHeight: 34
                            radius: 17
                            color: root.primary

                            Text {
                                anchors.centerIn: parent
                                text: root.isEditing ? "Save Changes" : "Create Alarm"
                                font.pixelSize: 11
                                font.bold: true
                                color: root.foreground
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.saveForm()
                            }
                        }
                    }
                }
            }
        }
    }
}
