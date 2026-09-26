pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services

Singleton {
    id: root

    property var allTasks: []
    readonly property alias tasks: root.allTasks
    property string configDir: ""

    function formatDateKey(year, month, day) {
        var m = (month + 1);
        var d = day;
        return year + "-" + (m < 10 ? "0" : "") + m + "-" + (d < 10 ? "0" : "") + d;
    }

    function isOverdue(task) {
        if (!task || task.done || !task.date || task.date === "") return false;
        var now = new Date();
        var todayKey = formatDateKey(now.getFullYear(), now.getMonth(), now.getDate());
        return task.date < todayKey;
    }

    function hasTaskOnDay(day) {
        var now = new Date();
        return hasTasksOnDate(now.getFullYear(), now.getMonth(), day);
    }

    function hasTasksOnDate(year, month, day) {
        var key = formatDateKey(year, month, day);
        for (var i = 0; i < allTasks.length; i++) {
            if (allTasks[i].date === key) {
                return true;
            }
        }
        return false;
    }

    function hasPendingTasksOnDate(year, month, day) {
        var key = formatDateKey(year, month, day);
        var now = new Date();
        var todayKey = formatDateKey(now.getFullYear(), now.getMonth(), now.getDate());
        var isToday = (key === todayKey);

        for (var i = 0; i < allTasks.length; i++) {
            var t = allTasks[i];
            if (t.date === key && !t.done) {
                return true;
            }
            if (isToday && !t.done && (!t.date || t.date === "" || isOverdue(t))) {
                return true;
            }
        }
        return false;
    }

    function getTasksForDate(year, month, day) {
        var key = formatDateKey(year, month, day);
        var now = new Date();
        var todayKey = formatDateKey(now.getFullYear(), now.getMonth(), now.getDate());
        var isViewingToday = (key === todayKey);

        var result = [];
        for (var i = 0; i < allTasks.length; i++) {
            var t = allTasks[i];
            if (t.date === key) {
                result.push(t);
            } else if (isViewingToday && (!t.date || t.date === "" || isOverdue(t))) {
                result.push(t);
            }
        }

        result.sort(function(a, b) {
            if (a.done !== b.done) return a.done ? 1 : -1;
            var dateA = a.date || "9999-99-99";
            var dateB = b.date || "9999-99-99";
            if (dateA !== dateB) return dateA.localeCompare(dateB);
            var timeA = a.startTime || "99:99";
            var timeB = b.startTime || "99:99";
            return timeA.localeCompare(timeB);
        });

        return result;
    }

    Process {
        id: saveProc
        command: []
    }

    function formatDisplayTime(str) {
        if (!str) return "";
        var s = str.trim();
        if (s.indexOf("AM") !== -1 || s.indexOf("PM") !== -1 || s.indexOf("am") !== -1 || s.indexOf("pm") !== -1) {
            return s;
        }
        var parts = s.split(":");
        if (parts.length >= 2) {
            var h = parseInt(parts[0], 10);
            var m = parseInt(parts[1], 10);
            if (!isNaN(h) && !isNaN(m)) {
                var ap = h >= 12 ? "PM" : "AM";
                var h12 = h % 12;
                if (h12 === 0) h12 = 12;
                var hh = (h12 < 10 ? "0" : "") + h12;
                var mm = (m < 10 ? "0" : "") + m;
                return hh + ":" + mm + " " + ap;
            }
        }
        return s;
    }

    function cleanTimeStr(val) {
        if (!val) return "";
        var s = val.toString().trim();
        if (s.indexOf("Horário") !== -1 || s.indexOf("Brasília") !== -1 || s.indexOf("GMT") !== -1) {
            var timePart = s.split(" ")[0];
            return formatDisplayTime(timePart);
        }
        return s;
    }

    function saveTasks() {
        var jsonStr = JSON.stringify(allTasks, null, 4);
        var pyScript = "import os, json; data = " + JSON.stringify(jsonStr) + "; p1 = os.path.expanduser('~/.config/quickshell/tasks.json'); os.makedirs(os.path.dirname(p1), exist_ok=True); open(p1, 'w').write(data); p2 = os.path.expanduser('~/Documents/Shell/quickshell/tasks.json'); (open(p2, 'w').write(data) if os.path.exists(os.path.dirname(p2)) else None)";
        saveProc.command = ["python3", "-c", pyScript];
        saveProc.running = false;
        saveProc.running = true;
    }

    Process {
        id: loadProc
        command: ["python3", "-c", "import os, json; p = os.path.expanduser('~/.config/quickshell/tasks.json'); print(open(p).read() if os.path.exists(p) else '[]')"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text && this.text.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(this.text.trim());
                        if (Array.isArray(parsed)) {
                            root.allTasks = parsed.map(function(item) {
                                return {
                                    id: item.id,
                                    text: item.text,
                                    date: (item.date !== undefined && item.date !== null) ? item.date : "",
                                    startTime: item.startTime || "",
                                    endTime: item.endTime || "",
                                    notify: !!item.notify,
                                    notified: !!item.notified,
                                    done: !!item.done,
                                    createdAt: root.cleanTimeStr(item.createdAt)
                                };
                            });
                        }
                    } catch (e) {
                        root.allTasks = [
                            { id: 1, text: "Check shell notifications", date: root.formatDateKey(new Date().getFullYear(), new Date().getMonth(), new Date().getDate()), startTime: "", endTime: "", notify: false, notified: false, done: false },
                            { id: 2, text: "Focus Pomodoro session", date: root.formatDateKey(new Date().getFullYear(), new Date().getMonth(), new Date().getDate()), startTime: "", endTime: "", notify: false, notified: false, done: false }
                        ];
                        root.saveTasks();
                    }
                }
            }
        }
    }

    function normalizeTime(str) {
        if (!str) return "";
        var s = str.trim();
        if (s.indexOf(":") === -1) {
            var hOnly = parseInt(s, 10);
            if (!isNaN(hOnly) && hOnly >= 0 && hOnly <= 23) {
                return (hOnly < 10 ? "0" : "") + hOnly + ":00";
            }
            return "";
        }
        var parts = s.split(":");
        if (parts.length === 2) {
            var h = parseInt(parts[0], 10);
            var m = parts[1] === "" ? 0 : parseInt(parts[1], 10);
            if (!isNaN(h) && !isNaN(m) && h >= 0 && h <= 23 && m >= 0 && m <= 59) {
                return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m;
            }
        }
        return "";
    }

    function addTask(text, dateStr, startTimeStr, endTimeStr, notifyBool) {
        if (!text || text.trim() === "") return;
        var list = root.allTasks.slice();
        var normalizedStart = normalizeTime(startTimeStr);
        var normalizedEnd = normalizeTime(endTimeStr);
        var newTask = {
            id: Date.now() + Math.floor(Math.random() * 1000),
            text: text.trim(),
            date: dateStr || "",
            startTime: normalizedStart,
            endTime: normalizedEnd,
            notify: !!notifyBool,
            notified: false,
            done: false,
            createdAt: Qt.formatTime(new Date(), "hh:mm AP")
        };
        list.push(newTask);
        root.allTasks = list;
        root.saveTasks();
    }

    function toggleTask(taskId) {
        var list = root.allTasks.slice();
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === taskId) {
                list[i].done = !list[i].done;
                break;
            }
        }
        root.allTasks = list;
        root.saveTasks();
    }

    function removeTask(taskId) {
        var list = root.allTasks.filter(t => t.id !== taskId);
        root.allTasks = list;
        root.saveTasks();
    }

    Timer {
        id: notificationTimer
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            if (root.allTasks.length === 0) return;
            var now = new Date();
            var todayKey = root.formatDateKey(now.getFullYear(), now.getMonth(), now.getDate());
            var curHours = now.getHours();
            var curMinutes = now.getMinutes();
            var nowTime = (curHours < 10 ? "0" : "") + curHours + ":" + (curMinutes < 10 ? "0" : "") + curMinutes;

            var modified = false;
            var list = root.allTasks.slice();
            for (var i = 0; i < list.length; i++) {
                var t = list[i];
                if (!t.done && t.notify && !t.notified && t.date === todayKey && t.startTime) {
                    if (nowTime >= t.startTime) {
                        t.notified = true;
                        modified = true;
                        var bodyStr = root.formatDisplayTime(t.startTime) + (t.endTime ? " - " + root.formatDisplayTime(t.endTime) : "");
                        NotificationService.addNotification("Tasks", t.text, bodyStr, "󰄲");
                    }
                }
            }
            if (modified) {
                root.allTasks = list;
                root.saveTasks();
            }
        }
    }

    Component.onDestruction: {
        loadProc.running = false;
        loadProc.kill();
        saveProc.running = false;
        saveProc.kill();
    }
}
