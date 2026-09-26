pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services

Singleton {
    id: root

    // === ALARMS STATE ===
    property var alarms: []
    readonly property int activeCount: {
        var count = 0;
        for (var i = 0; i < alarms.length; i++) {
            if (alarms[i].enabled)
                count++;
        }
        return count;
    }

    // Ringing state
    property bool isRinging: false
    property var activeRingingAlarm: null

    signal alarmTriggered(var alarm)

    readonly property var dayLabels: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    readonly property var dayFullLabels: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    function formatTime(hour, minute) {
        var h = parseInt(hour) || 0;
        var m = parseInt(minute) || 0;
        var ap = h >= 12 ? "PM" : "AM";
        var h12 = h % 12;
        if (h12 === 0) h12 = 12;
        var hh = (h12 < 10 ? "0" : "") + h12;
        var mm = (m < 10 ? "0" : "") + m;
        return hh + ":" + mm + " " + ap;
    }

    // Recurrence days summary helper
    function formatDaysSummary(days) {
        if (!days || !Array.isArray(days) || days.length === 0)
            return "Once";

        if (days.length === 7)
            return "Every day";

        var sorted = days.slice().sort((a, b) => a - b);
        var isWeekdays = (sorted.length === 5 && sorted[0] === 1 && sorted[1] === 2 && sorted[2] === 3 && sorted[3] === 4 && sorted[4] === 5);
        if (isWeekdays)
            return "Weekdays";

        var isWeekend = (sorted.length === 2 && sorted.indexOf(0) !== -1 && sorted.indexOf(6) !== -1);
        if (isWeekend)
            return "Weekend";

        var names = [];
        for (var i = 0; i < sorted.length; i++) {
            var d = sorted[i];
            if (d >= 0 && d < dayLabels.length) {
                names.push(dayLabels[d]);
            }
        }
        return names.join(", ");
    }

    // === PERSISTENCE ===
    Process {
        id: saveProc
        command: []
    }

    // Save alarms to ~/.config/quickshell/alarms.json via Python helper
    function saveAlarms() {
        var jsonStr = JSON.stringify(root.alarms);
        var pyScript = "import os, json; p = os.path.expanduser('~/.config/quickshell/alarms.json'); os.makedirs(os.path.dirname(p), exist_ok=True); open(p, 'w').write(" + JSON.stringify(jsonStr) + ")";
        saveProc.command = ["python3", "-c", pyScript];
        saveProc.running = false;
        saveProc.running = true;
    }

    // Load alarms from ~/.config/quickshell/alarms.json
    Process {
        id: loadProc
        command: ["python3", "-c", "import os, json; p = os.path.expanduser('~/.config/quickshell/alarms.json'); print(open(p).read() if os.path.exists(p) else '[]')"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text && this.text.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(this.text.trim());
                        if (Array.isArray(parsed)) {
                            root.alarms = parsed;
                        }
                    } catch (e) {
                        root.alarms = [];
                    }
                }
            }
        }
    }

    // === CRUD OPERATIONS ===
    function addAlarm(title, hour, minute, days) {
        var list = root.alarms.slice();
        var newAlarm = {
            id: "alarm_" + Date.now() + "_" + Math.floor(Math.random() * 10000),
            title: title && title.trim() ? title.trim() : "Alarm",
            hour: Math.max(0, Math.min(23, parseInt(hour) || 0)),
            minute: Math.max(0, Math.min(59, parseInt(minute) || 0)),
            days: Array.isArray(days) ? days.slice().sort((a, b) => a - b) : [],
            enabled: true,
            lastFiredDate: ""
        };
        list.push(newAlarm);
        root.alarms = list;
        root.saveAlarms();
        return newAlarm;
    }

    function updateAlarm(id, title, hour, minute, days) {
        var list = root.alarms.slice();
        var found = false;
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === id) {
                list[i].title = title && title.trim() ? title.trim() : "Alarm";
                list[i].hour = Math.max(0, Math.min(23, parseInt(hour) || 0));
                list[i].minute = Math.max(0, Math.min(59, parseInt(minute) || 0));
                list[i].days = Array.isArray(days) ? days.slice().sort((a, b) => a - b) : [];
                list[i].lastFiredDate = "";
                found = true;
                break;
            }
        }
        if (found) {
            root.alarms = list;
            root.saveAlarms();
        }
    }

    function removeAlarm(id) {
        if (root.activeRingingAlarm && root.activeRingingAlarm.id === id) {
            root.dismissAlarm();
        }
        var list = root.alarms.filter(a => a.id !== id);
        root.alarms = list;
        root.saveAlarms();
    }

    function toggleAlarm(id) {
        var list = root.alarms.slice();
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === id) {
                list[i].enabled = !list[i].enabled;
                if (list[i].enabled) {
                    list[i].lastFiredDate = "";
                }
                break;
            }
        }
        root.alarms = list;
        root.saveAlarms();
    }

    function setAlarmEnabled(id, enable) {
        var list = root.alarms.slice();
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === id) {
                list[i].enabled = enable;
                if (enable) {
                    list[i].lastFiredDate = "";
                }
                break;
            }
        }
        root.alarms = list;
        root.saveAlarms();
    }

    // === ALARM TRIGGERING & AUDIO CONTROL ===
    function triggerAlarm(alarm, todayKey) {
        var list = root.alarms.slice();
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === alarm.id) {
                list[i].lastFiredDate = todayKey;
                // One-time alarm rule: auto-disable after firing
                var isRecurring = list[i].days && Array.isArray(list[i].days) && list[i].days.length > 0;
                if (!isRecurring) {
                    list[i].enabled = false;
                }
                break;
            }
        }
        root.alarms = list;
        root.saveAlarms();

        // Update active ringing state
        root.isRinging = true;
        root.activeRingingAlarm = alarm;
        root.alarmTriggered(alarm);

        var timeStr = root.formatTime(alarm.hour, alarm.minute);
        var alarmName = alarm.title && alarm.title.trim() ? alarm.title.trim() : "Alarm";

        // Sound alert loop
        TimerService.startAlarmLoop();

        // Visual overlay transition popup
        TimerService.stateTransitionOccurred("󰀠", alarmName + " (" + timeStr + ")");

        // Desktop system notification
        NotificationService.addNotification("Alarm", alarmName, "The alarm scheduled for " + timeStr + " is ringing!", "󰀠");
    }

    // Silence and dismiss the ringing alarm
    function dismissAlarm() {
        root.isRinging = false;
        root.activeRingingAlarm = null;
        TimerService.stopAlarmLoop();
    }

    // === CHECK LOOP ===
    Timer {
        id: checkTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (root.alarms.length === 0)
                return ;

            var now = new Date();
            var curHour = now.getHours();
            var curMinute = now.getMinutes();
            var curDay = now.getDay(); // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
            var todayKey = now.getFullYear() + "-" + (now.getMonth() + 1) + "-" + now.getDate();

            for (var i = 0; i < root.alarms.length; i++) {
                var a = root.alarms[i];
                if (!a || !a.enabled)
                    continue;

                // Match hour and minute
                if (a.hour === curHour && a.minute === curMinute) {
                    // Prevent firing multiple times during the same minute
                    if (a.lastFiredDate === todayKey)
                        continue;

                    // Check day of week recurrence
                    var isRecurring = a.days && Array.isArray(a.days) && a.days.length > 0;
                    if (isRecurring) {
                        if (a.days.indexOf(curDay) === -1) {
                            continue;
                        }
                    }

                    // Trigger alarm
                    root.triggerAlarm(a, todayKey);
                }
            }
        }
    }

    Component.onDestruction: {
        loadProc.running = false;
        saveProc.running = false;
    }
}
