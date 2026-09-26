pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    property string activeClass: ""
    property string activeTitle: ""
    property string activeDisplayName: ""
    property string activeIcon: ""

    function getAppFriendlyName(klass, title) {
        if (!klass && !title) return "";
        var lowerClass = (klass || "").toLowerCase();
        var lowerTitle = (title || "").toLowerCase();

        if (lowerClass.includes("brave")) return "Brave";
        if (lowerClass.includes("vivaldi" )) return "Vivaldi";
        if (lowerClass.includes("firefox")) return "Firefox";
        if (lowerClass.includes("chrome") || lowerClass.includes("chromium")) return "Chrome";
        if (lowerClass.includes("kitty")) return "Kitty";
        if (lowerClass.includes("alacritty")) return "Alacritty";
        if (lowerClass.includes("foot")) return "Foot";
        if (lowerClass.includes("spotify")) return "Spotify";
        if (lowerClass.includes("code") || lowerClass.includes("vscodium")) return "VS Code";
        if (lowerClass.includes("discord") || lowerClass.includes("vesktop") || lowerClass.includes("webcord")) return "Discord";
        if (lowerClass.includes("telegram")) return "Telegram";
        if (lowerClass.includes("thunar") || lowerClass.includes("nautilus") || lowerClass.includes("dolphin")) return "Files";
        if (lowerClass.includes("gimp")) return "GIMP";
        if (lowerClass.includes("inkscape")) return "Inkscape";
        if (lowerClass.includes("vlc") || lowerClass.includes("mpv")) return "Player";
        if (lowerClass.includes("obsidian")) return "Obsidian";
        if (lowerClass.includes("terraria")) return "Terraria";
        if (lowerClass.includes("steam")) return "Steam";

        if (klass && klass.trim().length > 0) {
            return klass.charAt(0).toUpperCase() + klass.slice(1);
        }
        return "Active Window";
    }

    function getAppIcon(klass, title) {
        if (!klass && !title) return "";
        var lowerClass = (klass || "").toLowerCase();
        var lowerTitle = (title || "").toLowerCase();

        if (lowerClass.includes("brave") || lowerClass.includes("vivaldi")) return "󰊯";
        if (lowerClass.includes("firefox")) return "󰈹";
        if (lowerClass.includes("chrome") || lowerClass.includes("chromium")) return "󰊯";
        if (lowerClass.includes("kitty") || lowerClass.includes("alacritty") || lowerClass.includes("foot") || lowerClass.includes("terminal")) return "󰄛";
        if (lowerClass.includes("spotify")) return "󰓇";
        if (lowerClass.includes("code") || lowerClass.includes("vscodium")) return "󰨞";
        if (lowerClass.includes("discord") || lowerClass.includes("vesktop") || lowerClass.includes("webcord")) return "󰙯";
        if (lowerClass.includes("telegram")) return "󰈰";
        if (lowerClass.includes("thunar") || lowerClass.includes("nautilus") || lowerClass.includes("dolphin")) return "󰉋";
        if (lowerClass.includes("gimp") || lowerClass.includes("inkscape")) return "󰽉";
        if (lowerClass.includes("vlc") || lowerClass.includes("mpv")) return "󰕼";
        if (lowerClass.includes("obsidian")) return "";
        if (lowerClass.includes("steam")) return "󰓓";
        if (lowerClass.includes("notion")) return "";

        return "󰖲";
    }

    readonly property string eventsScriptPath: (typeof Quickshell.shellPath === "function")
        ? Quickshell.shellPath("Services/hyprland_events.py")
        : (Quickshell.env("HOME") + "/.config/quickshell/Services/hyprland_events.py")

    readonly property string previewScriptPath: (typeof Quickshell.shellPath === "function")
        ? Quickshell.shellPath("Services/window_preview_helper.py")
        : (Quickshell.env("HOME") + "/.config/quickshell/Services/window_preview_helper.py")

    function updateFromClassAndTitle(klass, title) {
        if (!klass && !title) {
            root.activeClass = "";
            root.activeTitle = "";
            root.activeDisplayName = "";
            root.activeIcon = "";
            return;
        }
        root.activeClass = klass || "";
        root.activeTitle = title || "";
        root.activeDisplayName = root.getAppFriendlyName(klass, title);
        root.activeIcon = root.getAppIcon(klass, title);
    }

    // Initial snapshot fetch
    Process {
        id: activeWinProc
        command: ["hyprctl", "activewindow", "-j"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var output = this.text ? this.text.trim() : "";
                if (!output || output === "{}" || output === "null") {
                    root.updateFromClassAndTitle("", "");
                    return;
                }
                try {
                    var json = JSON.parse(output);
                    root.updateFromClassAndTitle(json.class || "", json.title || "");
                } catch (e) {
                }
            }
        }
    }

    // Real-time Hyprland event listener via socket2
    Process {
        id: hyprEventsProc
        command: ["python3", root.eventsScriptPath]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var line = data ? data.trim() : "";
                if (!line) return;
                try {
                    var ev = JSON.parse(line);
                    root.updateFromClassAndTitle(ev.class, ev.title);
                } catch (e) {
                }
            }
        }
    }

    // Background passive thumbnail snapshot daemon (event-driven on window focus)
    Process {
        id: previewDaemonProc
        command: ["python3", root.previewScriptPath, "daemon"]
        running: true
    }

    Component.onCompleted: {
        activeWinProc.running = true;
    }

    Component.onDestruction: {
        hyprEventsProc.running = false;
        hyprEventsProc.kill();
        previewDaemonProc.running = false;
        previewDaemonProc.kill();
    }
}
