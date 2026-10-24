pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services

Singleton {
    id: root
    
    property string activeMode: "pomodoro" // "pomodoro" | "timer" | "stopwatch" | "alarm"

    signal stateTransitionOccurred(string icon, string message)

    property bool alarmLoopRunning: false

    Process {
        id: alarmLoopProc
        command: ["bash", "-c", "while true; do paplay /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga; done"]
        running: root.alarmLoopRunning
    }

    Process {
        id: killAlarmProc
        command: ["killall", "-q", "paplay"]
    }

    function startAlarmLoop() {
        alarmLoopRunning = false; // kill current loop if any
        alarmLoopRunning = true;
    }

    function stopAlarmLoop() {
        alarmLoopRunning = false;
        killAlarmProc.running = false;
        killAlarmProc.running = true;
    }

    property int workMinutes: 25
    property int shortBreakMinutes: 5
    property int longBreakMinutes: 15
    property int totalCycles: 4
    property int currentCycle: 1

    property string pomodoroPhase: "work" // "work" | "shortBreak" | "longBreak"
    property int pomodoroSecondsLeft: workMinutes * 60
    property bool pomodoroRunning: false

    function startPomodoro() {
        pomodoroRunning = true;
    }

    function pausePomodoro() {
        pomodoroRunning = false;
    }

    function togglePomodoro() {
        pomodoroRunning = !pomodoroRunning;
    }

    function resetPomodoro() {
        pomodoroRunning = false;
        if (pomodoroPhase === "work")
            pomodoroSecondsLeft = workMinutes * 60;
        else if (pomodoroPhase === "shortBreak")
            pomodoroSecondsLeft = shortBreakMinutes * 60;
        else
            pomodoroSecondsLeft = longBreakMinutes * 60;
    }

    function setPomodoroPhase(phase, autoStart) {
        pomodoroRunning = (autoStart === true);
        pomodoroPhase = phase;
        if (phase === "work")
            pomodoroSecondsLeft = workMinutes * 60;
        else if (phase === "shortBreak")
            pomodoroSecondsLeft = shortBreakMinutes * 60;
        else
            pomodoroSecondsLeft = longBreakMinutes * 60;
    }

    function skipPomodoro(isAutoTriggered) {
        var autoStart = (isAutoTriggered === true);

        if (pomodoroPhase === "work") {
            if (currentCycle >= totalCycles) {
                currentCycle = 1;
                setPomodoroPhase("longBreak", autoStart);
                stateTransitionOccurred("check", "All cycles completed!");
                NotificationService.addNotification("Pomodoro", "Congratulations! All cycles completed!", "Starting long break of " + longBreakMinutes + " minutes.", "󰄉");
            } else {
                setPomodoroPhase("shortBreak", autoStart);
                stateTransitionOccurred("self_improvement", "Time for a break");
                NotificationService.addNotification("Pomodoro", "Time for a break!", "Focus completed! Enjoy the short break of " + shortBreakMinutes + " minutes.", "󰄉");
            }
        } else {
            if (pomodoroPhase === "shortBreak") {
                currentCycle++;
            }
            setPomodoroPhase("work", autoStart);
            stateTransitionOccurred("neurology", "Time to focus");
            NotificationService.addNotification("Pomodoro", "Time to Focus!", "Break completed! Starting focus session (" + currentCycle + "/" + totalCycles + ") for " + workMinutes + " minutes.", "󰄉");
        }
    }

    property int timerTotalSeconds: 300 // 5 minutes default
    property int timerSecondsLeft: 300
    property bool timerRunning: false
    property bool timerRinging: false

    function startTimer() {
        if (timerSecondsLeft <= 0)
            timerSecondsLeft = timerTotalSeconds;
        timerRinging = false;
        timerRunning = true;
    }

    function pauseTimer() {
        if (timerRinging) {
            stopAlarmLoop();
            timerRinging = false;
            timerRunning = false;
            timerSecondsLeft = timerTotalSeconds;
        } else {
            timerRunning = false;
        }
    }

    function toggleTimer() {
        if (timerRunning)
            pauseTimer();
        else
            startTimer();
    }

    function resetTimer() {
        if (timerRinging) {
            stopAlarmLoop();
            timerRinging = false;
        }
        timerRunning = false;
        timerSecondsLeft = timerTotalSeconds;
    }

    function setTimerDuration(seconds) {
        if (timerRinging) {
            stopAlarmLoop();
            timerRinging = false;
        }
        timerRunning = false;
        timerTotalSeconds = Math.max(10, seconds);
        timerSecondsLeft = timerTotalSeconds;
    }

    function addTimerSeconds(seconds) {
        var n = Math.max(0, timerSecondsLeft + seconds);
        timerSecondsLeft = n;
        if (n > timerTotalSeconds)
            timerTotalSeconds = n;
    }

    property int stopwatchSeconds: 0
    property bool stopwatchRunning: false
    property var stopwatchLaps: []

    function startStopwatch() {
        stopwatchRunning = true;
    }

    function pauseStopwatch() {
        stopwatchRunning = false;
    }

    function toggleStopwatch() {
        stopwatchRunning = !stopwatchRunning;
    }

    function resetStopwatch() {
        stopwatchRunning = false;
        stopwatchSeconds = 0;
        stopwatchLaps = [];
    }

    function addLap() {
        var list = stopwatchLaps.slice();
        list.unshift({
            lap: list.length + 1,
            time: formatSeconds(stopwatchSeconds)
        });
        stopwatchLaps = list;
    }

    function formatSeconds(secs) {
        if (!secs || isNaN(secs) || secs < 0)
            return "00:00";
        var h = Math.floor(secs / 3600);
        var m = Math.floor((secs % 3600) / 60);
        var s = Math.floor(secs % 60);
        if (h > 0) {
            return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
        }
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
    }

    Timer {
        interval: 1000
        running: root.pomodoroRunning || root.timerRunning || root.stopwatchRunning
        repeat: true
        onTriggered: {
            if (root.pomodoroRunning) {
                if (root.pomodoroSecondsLeft > 1) {
                    root.pomodoroSecondsLeft--;
                } else {
                    root.pomodoroSecondsLeft = 0;
                    root.skipPomodoro(true);
                }
            }

            if (root.timerRunning && !root.timerRinging) {
                if (root.timerSecondsLeft > 0) {
                    root.timerSecondsLeft--;
                } else {
                    root.timerRinging = true;
                    root.startAlarmLoop();
                    root.stateTransitionOccurred("󰔛", "Time's up!");
                    NotificationService.addNotification("Timer", "Time's up!", "Your timer has expired.", "󰔛");
                }
            }

            if (root.stopwatchRunning) {
                root.stopwatchSeconds++;
            }
        }
    }

    readonly property bool isAnyActive: pomodoroRunning || timerRunning || timerRinging || stopwatchRunning || (pomodoroSecondsLeft < (workMinutes * 60) && pomodoroSecondsLeft > 0) || (timerSecondsLeft < timerTotalSeconds && timerSecondsLeft > 0) || stopwatchSeconds > 0 || AlarmService.isRinging
 readonly property string activeIcon: {
        if (activeMode === "pomodoro") {
            if (pomodoroPhase === "work") return "neurology";
            return "self_improvement";
        }
        if (activeMode === "timer") return "hourglass_bottom";
        if (activeMode === "stopwatch") return "pace";
        return "alarm";
    }
    readonly property string activeLabel: {
        if (activeMode === "pomodoro") {
            if (pomodoroPhase === "work") return "Focus (" + currentCycle + "/" + totalCycles + ")";
            if (pomodoroPhase === "shortBreak") return "Short Break";
            return "Long Break";
        }
        if (activeMode === "timer") return "Timer";
        if (activeMode === "stopwatch") return "Stopwatch";
        return "Alarm";
    }

    readonly property string activeDisplayTime: {
        if (activeMode === "pomodoro") return formatSeconds(pomodoroSecondsLeft);
        if (activeMode === "timer") return formatSeconds(timerSecondsLeft);
        if (activeMode === "stopwatch") return formatSeconds(stopwatchSeconds);
        return AlarmService.isRinging ? "Ringing!" : AlarmService.nextAlarmCountdown;
    }

    readonly property bool activeIsRunning: {
        if (activeMode === "pomodoro") return pomodoroRunning;
        if (activeMode === "timer") return timerRunning || timerRinging;
        if (activeMode === "stopwatch") return stopwatchRunning;
        return AlarmService.isRinging;
    }

    readonly property real activeProgress: {
        if (activeMode === "pomodoro") {
            var total = (pomodoroPhase === "work" ? workMinutes : (pomodoroPhase === "shortBreak" ? shortBreakMinutes : longBreakMinutes)) * 60;
            return total > 0 ? (1.0 - (pomodoroSecondsLeft / total)) : 0;
        }
        if (activeMode === "timer") {
            if (timerRinging) return 1.0;
            return timerTotalSeconds > 0 ? (1.0 - (timerSecondsLeft / timerTotalSeconds)) : 0;
        }
        return 0;
    }

    function toggleActive() {
        if (activeMode === "pomodoro") togglePomodoro();
        else if (activeMode === "timer") toggleTimer();
        else if (activeMode === "stopwatch") toggleStopwatch();
        else if (AlarmService.isRinging) AlarmService.dismissAlarm();
    }
}

