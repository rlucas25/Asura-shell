pragma Singleton

import QtQuick
import Quickshell
import qs.Asura

Singleton {
    id: root

    readonly property var _cache: ({})

    readonly property var aliases: ({
        "code-url-handler": "visual-studio-code",
        "code": "visual-studio-code",
        "vscodium": "vscodium",
        "vscode": "visual-studio-code",
        "spotify": "spotify",
        "spotify-client": "spotify",
        "firefox": "firefox",
        "brave": "brave-browser",
        "brave-browser": "brave-browser",
        "vivaldi": "vivaldi",
        "chrome": "google-chrome",
        "google-chrome": "google-chrome",
        "chromium": "chromium",
        "discord": "discord",
        "vesktop": "discord",
        "webcord": "discord",
        "kitty": "kitty",
        "alacritty": "Alacritty",
        "foot": "foot",
        "wezterm": "org.wezfurlong.wezterm",
        "telegram": "telegram",
        "telegramdesktop": "telegram",
        "thunar": "thunar",
        "nautilus": "org.gnome.Nautilus",
        "dolphin": "system-file-manager",
        "gimp": "gimp",
        "inkscape": "inkscape",
        "vlc": "vlc",
        "mpv": "mpv",
        "obsidian": "obsidian",
        "steam": "steam",
        "notion": "notion-app",
        "obs": "obs",
        "pavucontrol": "org.pulseaudio.pavucontrol"
    })

    readonly property var glyphFallbacks: ({
        "spotify": "󰓇",
        "firefox": "󰈹",
        "chrome": "󰊯",
        "chromium": "󰊯",
        "brave": "󰊯",
        "vivaldi": "󰊯",
        "kitty": "󰄛",
        "alacritty": "󰄛",
        "foot": "󰄛",
        "terminal": "󰄛",
        "code": "󰨞",
        "vscodium": "󰨞",
        "vscode": "󰨞",
        "discord": "󰙯",
        "vesktop": "󰙯",
        "webcord": "󰙯",
        "telegram": "󰈰",
        "thunar": "󰉋",
        "nautilus": "󰉋",
        "dolphin": "󰉋",
        "files": "󰉋",
        "gimp": "󰽉",
        "inkscape": "󰽉",
        "vlc": "󰕼",
        "mpv": "󰐎",
        "obsidian": "",
        "steam": "󰓓",
        "notion": "",
        "notification": "󰂚",
        "timer": "󰄉",
        "audio": "󰓃",
        "media": "󰎆"
    })

    function isGlyph(str) {
        if (!str || str.length === 0) return false;
        if (str.startsWith("/") || str.startsWith("file:") || str.startsWith("image:")) return false;
        if (str.endsWith(".png") || str.endsWith(".svg") || str.endsWith(".xpm")) return false;
        return str.length <= 2 || str.charCodeAt(0) > 255;
    }

    function getFallbackGlyph(appName) {
        if (!appName) return "󰖲";
        if (root.isGlyph(appName)) return appName;

        var lower = appName.toLowerCase();
        for (var key in root.glyphFallbacks) {
            if (lower.indexOf(key) !== -1) {
                return root.glyphFallbacks[key];
            }
        }
        return "󰖲";
    }

    function getAppIcon(appName, extraHint) {
        if (!appName && !extraHint) return "";

        var raw = (appName || extraHint || "").trim();
        if (raw.startsWith("/") || raw.startsWith("file:") || raw.startsWith("image:")) {
            return raw;
        }

        var lowerName = (appName || "").toLowerCase().trim();
        var lowerHint = (extraHint || "").toLowerCase().trim();
        var cacheKey = lowerName + "::" + lowerHint;

        if (root._cache[cacheKey]) {
            return root._cache[cacheKey];
        }

        var resolved = "";

        if (root.aliases[lowerName]) {
            resolved = root.aliases[lowerName];
        } else if (lowerHint && root.aliases[lowerHint]) {
            resolved = root.aliases[lowerHint];
        }

        if (!resolved && typeof DesktopEntries !== "undefined") {
            try {
                var entry = null;
                if (extraHint && DesktopEntries.byId) {
                    entry = DesktopEntries.byId(extraHint) || DesktopEntries.byId(lowerHint + ".desktop");
                }
                if (!entry && appName && DesktopEntries.byId) {
                    entry = DesktopEntries.byId(appName) || DesktopEntries.byId(lowerName + ".desktop");
                }
                if (!entry && DesktopEntries.heuristicLookup) {
                    entry = (appName ? DesktopEntries.heuristicLookup(appName) : null)
                         || (extraHint ? DesktopEntries.heuristicLookup(extraHint) : null)
                         || DesktopEntries.heuristicLookup(lowerName);
                }
                if (entry && entry.icon) {
                    resolved = entry.icon;
                }
            } catch (e) {}
        }

        if (!resolved) {
            for (var aliasKey in root.aliases) {
                if (lowerName.indexOf(aliasKey) !== -1 || (lowerHint && lowerHint.indexOf(aliasKey) !== -1)) {
                    resolved = root.aliases[aliasKey];
                    break;
                }
            }
        }

        if (!resolved) {
            if (lowerName.indexOf("player") !== -1 || lowerName.indexOf("music") !== -1 || lowerName.indexOf("audio") !== -1) {
                resolved = "audio-player";
            } else if (lowerName.indexOf("browser") !== -1 || lowerName.indexOf("web") !== -1) {
                resolved = "web-browser";
            } else if (lowerName.indexOf("term") !== -1) {
                resolved = "utilities-terminal";
            } else if (lowerName.indexOf("notif") !== -1 || lowerName.indexOf("alert") !== -1) {
                resolved = "preferences-desktop-notification";
            } else {
                resolved = lowerName || "";
            }
        }

        root._cache[cacheKey] = resolved;

        return resolved;
    }

    function getIconPath(iconName, fallback) {
        if (!iconName) return fallback ? root.getIconPath(fallback) : "";
        if (iconName.startsWith("/") || iconName.startsWith("file:")) {
            return iconName.replace("file://", "");
        }

        try {
            if (typeof Quickshell !== "undefined" && typeof Quickshell.iconPath === "function") {
                var path = fallback !== undefined ? Quickshell.iconPath(iconName, fallback) : Quickshell.iconPath(iconName, true);
                if (path && path.length > 0) return path;
            }
        } catch (e) {}

        return "";
    }

    function getIconUrl(iconName, fallback) {
        if (!iconName) return fallback ? root.getIconUrl(fallback) : "";
        if (iconName.startsWith("file:") || iconName.startsWith("image:")) {
            return iconName;
        }
        if (iconName.startsWith("/")) {
            return "file://" + iconName;
        }

        var localPath = root.getIconPath(iconName);
        if (localPath && localPath.length > 0) {
            if (localPath.startsWith("file:") || localPath.startsWith("image:")) {
                return localPath;
            }
            return localPath.startsWith("/") ? ("file://" + localPath) : ("file:///" + localPath);
        }

        return fallback ? root.getIconUrl(fallback) : "";
    }
}
