pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services

Singleton {
    id: root
    
    // ─────────────────────────────────────────────────────────────────────────
    // GENERAL STATE & ALARM AUDIO
    // ─────────────────────────────────────────────────────────────────────────
    property string activeMode: "pomodoro" // "pomodoro" | "timer" | "stopwatch" | "alarm"

    // Emitted on every Pomodoro/Timer phase transition.
    // message: Short English label (e.g. "Time to focus")
    signal stateTransitionOccurred(string icon, string message)

    // true while the looping alarm is active; cleared by stopAlarmLoop()
    property bool alarmLoopRunning: false

    // Loops the alarm sound indefinitely via a bash while-loop.
    // Quickshell kills the bash process (SIGKILL) when running → false;
    // any in-flight paplay instance finishes its current play-through and stops.
    Process {
        id: alarmLoopProc
        command: ["bash", "-c", "while true; do paplay /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga; done"]
        running: root.alarmLoopRunning
    }

    // Forcibly kills any lingering paplay process left behind when bash is SIGKILL'd.
    Process {
        id: killAlarmProc
        command: ["killall", "-q", "paplay"]
    }

    // Start (or restart) the looping alarm.
    function startAlarmLoop() {
        alarmLoopRunning = false; // kill current loop if any
        alarmLoopRunning = true;
    }

    // Stop the alarm completely. Called by the play/pause bar button.
    function stopAlarmLoop() {
        alarmLoopRunning = false;
        // Also kill any orphaned paplay child process
        killAlarmProc.running = false;
        killAlarmProc.running = true;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 1. POMODORO STATE
    // ─────────────────────────────────────────────────────────────────────────
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

    // ─────────────────────────────────────────────────────────────────────────
    // 2. CUSTOM TIMER STATE
    // ─────────────────────────────────────────────────────────────────────────
    property int timerTotalSeconds: 300 // 5 minutes default
    property int timerSecondsLeft: 300
    property bool timerRunning: false
    // True while the timer has finished and the alarm is ringing
    property bool timerRinging: false

    function startTimer() {
        if (timerSecondsLeft <= 0)
            timerSecondsLeft = timerTotalSeconds;
        timerRinging = false;
        timerRunning = true;
    }

    // Pause the timer; if it was ringing, stop the alarm and reset
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

    // ─────────────────────────────────────────────────────────────────────────
    // 3. STOPWATCH STATE
    // ─────────────────────────────────────────────────────────────────────────
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

    // ─────────────────────────────────────────────────────────────────────────
    // FORMATTING & TICKING TIMER
    // ─────────────────────────────────────────────────────────────────────────
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
            // Pomodoro state machine tick
            if (root.pomodoroRunning) {
                if (root.pomodoroSecondsLeft > 1) {
                    root.pomodoroSecondsLeft--;
                } else {
                    root.pomodoroSecondsLeft = 0;
                    root.skipPomodoro(true);
                }
            }

            // Custom timer tick: when it reaches zero, enter ringing state
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

            // Stopwatch tick
            if (root.stopwatchRunning) {
                root.stopwatchSeconds++;
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SHARED SUMMARY PROPERTIES FOR BAR WIDGET
    // ─────────────────────────────────────────────────────────────────────────
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

    // Ringing timer still counts as "running" so the bar shows the pause button
    readonly property bool activeIsRunning: {
        if (activeMode === "pomodoro") return pomodoroRunning;
        if (activeMode === "timer") return timerRunning || timerRinging;
        if (activeMode === "stopwatch") return stopwatchRunning;
        return AlarmService.isRinging;
    }

    // Full progress when the timer is ringing (bar stays filled)
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

