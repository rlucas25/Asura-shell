import QtQuick
import Quickshell
import Quickshell.Io
import qs.Asura
import qs.Services
pragma Singleton

Singleton {
    id: root

    readonly property bool clock24h: (Config.cfg && Config.cfg.clock24h !== undefined) ? Config.cfg.clock24h : false

    property var allTasks: []
    readonly property alias tasks: root.allTasks
    property string configDir: ""
    readonly property string taskManagerScript: (typeof Quickshell.shellPath === "function") ? Quickshell.shellPath("Services/task_manager.py") : (Quickshell.env("HOME") + "/.config/quickshell/Services/task_manager.py")

    function getPriorityWeight(p) {
        if (p === "high") return 3;
        if (p === "medium") return 2;
        if (p === "low") return 1;
        return 0;
    }

    function getPriorityColor(p) {
        if (p === "high") return Colors.cfg.error;
        if (p === "medium") return (Colors.cfg.base09 ? Colors.cfg.base09 : Colors.cfg.warning);
        if (p === "low") return (Colors.cfg.tertiary ? Colors.cfg.tertiary : Colors.cfg.secondary);
        return Colors.cfg.outline;
    }

    function getPriorityLabel(p) {
        if (p === "high") return "High";
        if (p === "medium") return "Medium";
        if (p === "low") return "Low";
        return "Normal";
    }

    function getNextPriority(p) {
        if (p === "none" || !p) return "low";
        if (p === "low") return "medium";
        if (p === "medium") return "high";
        return "none";
    }

    function getNextTask() {
        var now = new Date();
        var todayKey = formatDateKey(now.getFullYear(), now.getMonth(), now.getDate());
        var pending = [];
        for (var i = 0; i < allTasks.length; i++) {
            var t = allTasks[i];
            if (!t.done) {
                pending.push(t);
            }
        }
        if (pending.length === 0)
            return null;

        pending.sort(function(a, b) {
            var aToday = (a.date === todayKey || isOverdue(a));
            var bToday = (b.date === todayKey || isOverdue(b));
            if (aToday !== bToday)
                return aToday ? -1 : 1;

            var pwA = getPriorityWeight(a.priority);
            var pwB = getPriorityWeight(b.priority);
            if (pwA !== pwB)
                return pwB - pwA;

            var timeA = a.startTime || "99:99";
            var timeB = b.startTime || "99:99";
            return timeA.localeCompare(timeB);
        });

        return {
            "task": pending[0],
            "pendingCount": pending.length,
            "hasHighPriority": pending.some(function(t) { return t.priority === "high"; })
        };
    }

    function formatDateKey(year, month, day) {
        var m = (month + 1);
        var d = day;
        return year + "-" + (m < 10 ? "0" : "") + m + "-" + (d < 10 ? "0" : "") + d;
    }

    function isOverdue(task) {
        if (!task || task.done || !task.date || task.date === "")
            return false;

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
            if (allTasks[i].date === key)
                return true;

        }
        return false;
    }

    function getTaskWorkloadOnDate(year, month, day) {
        var key = formatDateKey(year, month, day);
        var now = new Date();
        var todayKey = formatDateKey(now.getFullYear(), now.getMonth(), now.getDate());
        var isToday = (key === todayKey);
        var pending = 0;
        var completed = 0;
        for (var i = 0; i < allTasks.length; i++) {
            var t = allTasks[i];
            if (t.date === key) {
                if (t.done)
                    completed++;
                else
                    pending++;
            } else if (isToday && (!t.date || t.date === "" || isOverdue(t))) {
                if (t.done)
                    completed++;
                else
                    pending++;
            }
        }
        return {
            "pending": pending,
            "completed": completed,
            "total": pending + completed
        };
    }

    function hasPendingTasksOnDate(year, month, day) {
        var key = formatDateKey(year, month, day);
        var now = new Date();
        var todayKey = formatDateKey(now.getFullYear(), now.getMonth(), now.getDate());
        var isToday = (key === todayKey);
        for (var i = 0; i < allTasks.length; i++) {
            var t = allTasks[i];
            if (t.date === key && !t.done)
                return true;

            if (isToday && !t.done && (!t.date || t.date === "" || isOverdue(t)))
                return true;

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
            if (t.date === key)
                result.push(t);
            else if (isViewingToday && (!t.date || t.date === "" || isOverdue(t)))
                result.push(t);
        }
        result.sort(function(a, b) {
            if (a.done !== b.done)
                return a.done ? 1 : -1;

            if (!a.done) {
                var pwA = root.getPriorityWeight(a.priority);
                var pwB = root.getPriorityWeight(b.priority);
                if (pwA !== pwB)
                    return pwB - pwA;
            }

            var dateA = a.date || "9999-99-99";
            var dateB = b.date || "9999-99-99";
            if (dateA !== dateB)
                return dateA.localeCompare(dateB);

            var timeA = a.startTime || "99:99";
            var timeB = b.startTime || "99:99";
            return timeA.localeCompare(timeB);
        });
        return result;
    }

    function formatDisplayTime(str, override24) {
        if (!str)
            return "";

        var s = str.trim();
        if (!s)
            return "";

        var is24 = (override24 !== undefined) ? !!override24 : root.clock24h;

        var isPM = (s.indexOf("PM") !== -1 || s.indexOf("pm") !== -1);
        var isAM = (s.indexOf("AM") !== -1 || s.indexOf("am") !== -1);
        var cleanStr = s.replace(/am|pm|gmt|utc/gi, "").trim();

        var parts = cleanStr.split(":");
        if (parts.length < 2)
            return s;

        var h = parseInt(parts[0], 10);
        var m = parseInt(parts[1], 10);
        if (isNaN(h) || isNaN(m))
            return s;

        if (isPM && h < 12)
            h += 12;
        if (isAM && h === 12)
            h = 0;

        if (is24) {
            var hh24 = (h < 10 ? "0" : "") + h;
            var mm24 = (m < 10 ? "0" : "") + m;
            return hh24 + ":" + mm24;
        } else {
            var ap = h >= 12 ? "PM" : "AM";
            var h12 = h % 12;
            if (h12 === 0)
                h12 = 12;

            var hh12 = (h12 < 10 ? "0" : "") + h12;
            var mm12 = (m < 10 ? "0" : "") + m;
            return hh12 + ":" + mm12 + " " + ap;
        }
    }

    function cleanTimeStr(val) {
        if (!val)
            return "";

        var s = val.toString().trim();
        return formatDisplayTime(s);
    }

    property bool isSaving: false

    Timer {
        id: saveCooldownTimer
        interval: 700
        repeat: false
        onTriggered: root.isSaving = false
    }

    function saveTasks() {
        root.isSaving = true;
        saveCooldownTimer.stop();
        var jsonStr = JSON.stringify(allTasks, null, 4);
        saveProc.command = ["python3", root.taskManagerScript, "save", jsonStr];
        saveProc.running = false;
        saveProc.running = true;
    }

    function openTodoFile() {
        openFileProc.command = ["python3", root.taskManagerScript, "open"];
        openFileProc.running = false;
        openFileProc.running = true;
    }

    function normalizeTime(str) {
        if (!str)
            return "";

        var s = str.trim();
        var isPM = (s.indexOf("PM") !== -1 || s.indexOf("pm") !== -1);
        var isAM = (s.indexOf("AM") !== -1 || s.indexOf("am") !== -1);
        var cleanStr = s.replace(/am|pm/gi, "").trim();

        if (cleanStr.indexOf(":") === -1) {
            var hOnly = parseInt(cleanStr, 10);
            if (!isNaN(hOnly)) {
                if (isPM && hOnly < 12)
                    hOnly += 12;
                if (isAM && hOnly === 12)
                    hOnly = 0;
                if (hOnly >= 0 && hOnly <= 23)
                    return (hOnly < 10 ? "0" : "") + hOnly + ":00";
            }
            return "";
        }

        var parts = cleanStr.split(":");
        if (parts.length === 2) {
            var h = parseInt(parts[0], 10);
            var m = parts[1] === "" ? 0 : parseInt(parts[1], 10);
            if (!isNaN(h) && !isNaN(m)) {
                if (isPM && h < 12)
                    h += 12;
                if (isAM && h === 12)
                    h = 0;
                if (h >= 0 && h <= 23 && m >= 0 && m <= 59)
                    return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m;
            }
        }
        return "";
    }

    function getSubtaskStats(task) {
        if (!task || !Array.isArray(task.subtasks) || task.subtasks.length === 0)
            return null;

        var total = task.subtasks.length;
        var completed = 0;
        for (var i = 0; i < total; i++) {
            if (task.subtasks[i].done)
                completed++;
        }
        return {
            "total": total,
            "completed": completed,
            "isAllDone": completed === total && total > 0,
            "text": completed + "/" + total
        };
    }

    function addSubtask(taskId, text) {
        if (!text || text.trim() === "")
            return ;

        var list = root.allTasks.slice();
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === taskId) {
                var item = Object.assign({}, list[i]);
                var subtasks = Array.isArray(item.subtasks) ? item.subtasks.slice() : [];
                subtasks.push({
                    "id": Date.now() * 1000 + Math.floor(Math.random() * 900 + 100),
                    "text": text.trim(),
                    "done": false
                });
                item.subtasks = subtasks;
                list[i] = item;
                break;
            }
        }
        root.allTasks = list;
        root.saveTasks();
    }

    function toggleSubtask(taskId, subtaskId, subtaskIndex) {
        var list = root.allTasks.slice();
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === taskId) {
                var item = Object.assign({}, list[i]);
                var subtasks = Array.isArray(item.subtasks) ? item.subtasks.slice() : [];
                var allDone = true;
                var toggled = false;

                var targetIdx = -1;
                if (subtaskIndex !== undefined && subtaskIndex !== null && subtaskIndex >= 0 && subtaskIndex < subtasks.length) {
                    targetIdx = subtaskIndex;
                } else {
                    for (var k = 0; k < subtasks.length; k++) {
                        if (subtasks[k].id === subtaskId) {
                            targetIdx = k;
                            break;
                        }
                    }
                }

                for (var j = 0; j < subtasks.length; j++) {
                    var st = Object.assign({}, subtasks[j]);
                    if (j === targetIdx && !toggled) {
                        st.done = !st.done;
                        toggled = true;
                    }
                    if (!st.done) {
                        allDone = false;
                    }
                    subtasks[j] = st;
                }
                item.subtasks = subtasks;
                if (subtasks.length > 0) {
                    item.done = allDone;
                    if (allDone) {
                        item.column = "done";
                    } else if (item.column === "done") {
                        item.column = "ongoing";
                    }
                }
                list[i] = item;
                break;
            }
        }
        root.allTasks = list;
        root.saveTasks();
    }

    function removeSubtask(taskId, subtaskId, subtaskIndex) {
        var list = root.allTasks.slice();
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === taskId) {
                var item = Object.assign({}, list[i]);
                var subtasks = Array.isArray(item.subtasks) ? item.subtasks.slice() : [];
                var targetIdx = -1;
                if (subtaskIndex !== undefined && subtaskIndex !== null && subtaskIndex >= 0 && subtaskIndex < subtasks.length) {
                    targetIdx = subtaskIndex;
                } else {
                    for (var k = 0; k < subtasks.length; k++) {
                        if (subtasks[k].id === subtaskId) {
                            targetIdx = k;
                            break;
                        }
                    }
                }
                if (targetIdx >= 0) {
                    subtasks.splice(targetIdx, 1);
                } else {
                    var removed = false;
                    subtasks = subtasks.filter(function(st) {
                        if (!removed && st.id === subtaskId) {
                            removed = true;
                            return false;
                        }
                        return true;
                    });
                }
                item.subtasks = subtasks;
                list[i] = item;
                break;
            }
        }
        root.allTasks = list;
        root.saveTasks();
    }

    function addTask(text, dateStr, startTimeStr, endTimeStr, notifyBool, priorityStr) {
        if (!text || text.trim() === "")
            return ;

        var list = root.allTasks.slice();
        var normalizedStart = normalizeTime(startTimeStr);
        var normalizedEnd = normalizeTime(endTimeStr);
        var newTask = {
            "id": Date.now() + Math.floor(Math.random() * 1000),
            "text": text.trim(),
            "date": dateStr || "",
            "startTime": normalizedStart,
            "endTime": normalizedEnd,
            "notify": !!notifyBool,
            "notified": false,
            "done": false,
            "priority": priorityStr || "none",
            "subtasks": [],
            "createdAt": Qt.formatTime(new Date(), root.clock24h ? "HH:mm" : "hh:mm AP")
        };
        list.push(newTask);
        root.allTasks = list;
        root.saveTasks();
    }

    function updateTask(taskId, text, dateStr, startTimeStr, endTimeStr, notifyBool, priorityStr) {
        if (!text || text.trim() === "")
            return ;

        var list = root.allTasks.slice();
        var normalizedStart = normalizeTime(startTimeStr);
        var normalizedEnd = normalizeTime(endTimeStr);
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === taskId) {
                var item = Object.assign({}, list[i]);
                item.text = text.trim();
                item.date = (dateStr !== undefined && dateStr !== null) ? dateStr : "";
                item.startTime = normalizedStart;
                item.endTime = normalizedEnd;
                item.notify = !!notifyBool;
                item.notified = false;
                if (priorityStr !== undefined && priorityStr !== null)
                    item.priority = priorityStr;
                list[i] = item;
                break;
            }
        }
        root.allTasks = list;
        root.saveTasks();
    }

    function moveTaskColumn(taskId, dir) {
        var list = root.allTasks.slice();
        var cols = ["todo", "ongoing", "done"];
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === taskId) {
                var currentCol = list[i].column || (list[i].done ? "done" : "todo");
                var idx = cols.indexOf(currentCol);
                if (idx === -1) idx = 0;
                var nextIdx = Math.max(0, Math.min(cols.length - 1, idx + dir));
                var targetCol = cols[nextIdx];
                var item = Object.assign({}, list[i]);
                item.column = targetCol;
                item.done = (targetCol === "done");
                list[i] = item;
                break;
            }
        }
        root.allTasks = list;
        root.saveTasks();
    }

    function setTaskColumn(taskId, targetCol) {
        var list = root.allTasks.slice();
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === taskId) {
                var item = Object.assign({}, list[i]);
                item.column = targetCol;
                item.done = (targetCol === "done");
                list[i] = item;
                break;
            }
        }
        root.allTasks = list;
        root.saveTasks();
    }

    function toggleTask(taskId) {
        var list = root.allTasks.slice();
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === taskId) {
                var item = Object.assign({}, list[i]);
                var targetDone = !item.done;
                item.done = targetDone;
                item.column = targetDone ? "done" : "todo";
                if (Array.isArray(item.subtasks)) {
                    var newSubtasks = [];
                    for (var s = 0; s < item.subtasks.length; s++) {
                        var st = Object.assign({}, item.subtasks[s]);
                        if (targetDone) {
                            st.done = true;
                        }
                        newSubtasks.push(st);
                    }
                    item.subtasks = newSubtasks;
                }
                list[i] = item;
                break;
            }
        }
        root.allTasks = list;
        root.saveTasks();
    }

    function removeTask(taskId) {
        var list = root.allTasks.filter((t) => {
            return t.id !== taskId;
        });
        root.allTasks = list;
        root.saveTasks();
    }

    function mapTasksFromRaw(parsed) {
        if (!Array.isArray(parsed))
            return;

        var seenSubtaskIds = {};
        root.allTasks = parsed.map(function(item) {
            return {
                "id": item.id,
                "text": item.text,
                "date": (item.date !== undefined && item.date !== null) ? item.date : "",
                "startTime": item.startTime || "",
                "endTime": item.endTime || "",
                "notify": !!item.notify,
                "notified": !!item.notified,
                "done": !!item.done,
                "priority": item.priority || "none",
                "column": item.column || (item.done ? "done" : "todo"),
                "subtasks": Array.isArray(item.subtasks) ? item.subtasks.map(function(st) {
                    var sId = st.id;
                    if (!sId || seenSubtaskIds[sId]) {
                        sId = Date.now() * 1000 + Math.floor(Math.random() * 900 + 100);
                    }
                    seenSubtaskIds[sId] = true;
                    return {
                        "id": sId,
                        "text": st.text || "",
                        "done": !!st.done
                    };
                }) : [],
                "createdAt": root.cleanTimeStr(item.createdAt)
            };
        });
    }

    Component.onDestruction: {
        loadProc.running = false;
        loadProc.kill();
        saveProc.running = false;
        saveProc.kill();
        openFileProc.running = false;
        openFileProc.kill();
        syncFromMdProc.running = false;
        syncFromMdProc.kill();
    }

    Process {
        id: saveProc

        command: []
        onExited: {
            saveCooldownTimer.restart();
        }
    }

    Process {
        id: openFileProc

        command: []
    }

    Process {
        id: loadProc

        command: ["python3", root.taskManagerScript, "load"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text && this.text.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(this.text.trim());
                        if (Array.isArray(parsed)) {
                            root.mapTasksFromRaw(parsed);
                        }
                    } catch (e) {
                        root.allTasks = [{
                            "id": 1,
                            "text": "Check shell notifications",
                            "date": root.formatDateKey(new Date().getFullYear(), new Date().getMonth(), new Date().getDate()),
                            "startTime": "",
                            "endTime": "",
                            "notify": false,
                            "notified": false,
                            "done": false,
                            "priority": "none",
                            "subtasks": []
                        }, {
                            "id": 2,
                            "text": "Focus Pomodoro session",
                            "date": root.formatDateKey(new Date().getFullYear(), new Date().getMonth(), new Date().getDate()),
                            "startTime": "",
                            "endTime": "",
                            "notify": false,
                            "notified": false,
                            "done": false,
                            "priority": "high",
                            "subtasks": []
                        }];
                        root.saveTasks();
                    }
                }
            }
        }
    }

    FileView {
        id: todoFileWatcher

        path: Quickshell.env("HOME") + "/.config/asura/data/TODO.md"
        watchChanges: true
        onFileChanged: {
            reload();
            if (root.isSaving)
                return;
            mdSyncDebounceTimer.restart();
        }
    }

    Timer {
        id: mdSyncDebounceTimer

        interval: 300
        repeat: false
        onTriggered: {
            if (root.isSaving)
                return;
            syncFromMdProc.command = ["python3", root.taskManagerScript, "sync-from-md"];
            syncFromMdProc.running = false;
            syncFromMdProc.running = true;
        }
    }

    Process {
        id: syncFromMdProc

        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text && this.text.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(this.text.trim());
                        if (parsed && parsed.status === "unchanged") {
                            return;
                        }
                        if (Array.isArray(parsed)) {
                            root.mapTasksFromRaw(parsed);
                        }
                    } catch (e) {
                    }
                }
            }
        }
    }

    Timer {
        id: notificationTimer

        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            if (root.allTasks.length === 0)
                return ;

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

}
