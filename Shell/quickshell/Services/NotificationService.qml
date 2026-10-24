pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.Asura

Singleton {
    id: root

    property var notifications: [
        {
            id: 1,
            appName: "Asura Shell",
            summary: "Welcome to Shell",
            body: "Dashboard and notification center integrated successfully.",
            time: "Now",
            appIcon: "preferences-desktop-notification"
        }
    ]

    property var popupQueue: []
    property var activePopup: null
    property bool popupVisible: activePopup !== null
    property int unreadCount: notifications.length

    Process {
        id: soundProc
        command: ["paplay", "/usr/share/sounds/freedesktop/stereo/message.oga"]
    }

    Process {
        id: chimeProc
        command: ["paplay", "/usr/share/sounds/freedesktop/stereo/complete.oga"]
    }

    function playSound() {
        if (!Config.cfg.soundEffects || !Config.cfg.alertsPopups) return;
        var soundFile = Config.cfg.notificationSound || "message.oga";
        if (!soundFile.startsWith("/")) {
            soundFile = "/usr/share/sounds/freedesktop/stereo/" + soundFile;
        }
        soundProc.command = ["paplay", soundFile];
        soundProc.running = false;
        soundProc.running = true;
    }

    function playChime() {
        chimeProc.running = false;
        chimeProc.running = true;
    }

    function getAppIcon(appName) {
        return IconService.getAppIcon(appName);
    }

    function addNotification(appName, summary, body, icon) {
        var now = new Date();
        var timeStr = (now.getHours() < 10 ? "0" : "") + now.getHours() + ":" + (now.getMinutes() < 10 ? "0" : "") + now.getMinutes();
        var notif = {
            id: Date.now() + Math.random(),
            appName: appName || "Application",
            summary: summary || "Notification",
            body: body || "",
            time: timeStr,
            appIcon: icon || getAppIcon(appName)
        };

        var list = root.notifications.slice();
        list.unshift(notif);
        if (list.length > 20) {
            list = list.slice(0, 20);
        }
        root.notifications = list;
        root.unreadCount = list.length;

        if (Config.cfg.alertsPopups) {
            showPopup(notif);
            playSound();
        }
    }

    function showPopup(notif) {
        root.activePopup = notif;
        popupTimer.restart();
    }

    function dismissPopup() {
        root.activePopup = null;
    }

    Timer {
        id: popupTimer
        interval: (Config.cfg && Config.cfg.notificationTimeout) ? Config.cfg.notificationTimeout : 4500
        repeat: false
        onTriggered: {
            root.dismissPopup();
        }
    }

    function removeNotification(id) {
        var list = root.notifications.filter(n => n.id !== id);
        root.notifications = list;
        root.unreadCount = list.length;
        if (root.activePopup && root.activePopup.id === id) {
            root.dismissPopup();
        }
    }

    function clearAll() {
        root.notifications = [];
        root.unreadCount = 0;
        root.dismissPopup();
    }

    NotificationServer {
        id: server
        onNotification: notif => {
            var icon = notif.appIcon || root.getAppIcon(notif.appName);
            root.addNotification(
                notif.appName,
                notif.summary,
                notif.body,
                icon
            );
        }
    }
}
