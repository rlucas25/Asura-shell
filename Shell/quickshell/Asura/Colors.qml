pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property alias cfg: adapter
    property bool ready: false
    property bool isDarkMode: Config.ready ? Config.cfg.isDarkMode : true

    property var allPalettes: ({})
    property var categories: ({})
    property var darkList: []
    property var lightList: []
    property var allPalettesList: []
    property var wallpaperMap: ({})
    property string primarySlot: "base0D"

    readonly property string palettesJsonPath: (typeof Quickshell.shellPath === "function")
        ? Quickshell.shellPath("Asura/palettes/palettes.json")
        : (Quickshell.env("HOME") + "/.config/quickshell/Asura/palettes/palettes.json")

    readonly property string wallpaperMapPath: (typeof Quickshell.shellPath === "function")
        ? Quickshell.shellPath("Asura/wallpaper_map.json")
        : (Quickshell.env("HOME") + "/.config/quickshell/Asura/wallpaper_map.json")

    readonly property string mapperScriptPath: (typeof Quickshell.shellPath === "function")
        ? Quickshell.shellPath("Services/AutoTheme/main.py")
        : (Quickshell.env("HOME") + "/.config/quickshell/Services/AutoTheme/main.py")

    readonly property var availableCategories: [
        "all", "blue", "cyan", "purple", "green", "red", "yellow", "orange", "monochrome"
    ]

    readonly property var availablePalettes: root.allPalettesList

    function getContrastColor(hexColor) {
        if (!hexColor) return "#ffffff";
        var str = hexColor.toString().replace("#", "");
        if (str.length === 3) {
            str = str.split("").map(c => c + c).join("");
        }
        if (str.length < 6) return "#ffffff";
        var r = parseInt(str.substring(0, 2), 16) || 0;
        var g = parseInt(str.substring(2, 4), 16) || 0;
        var b = parseInt(str.substring(4, 6), 16) || 0;
        var lum = 0.2126 * r + 0.7152 * g + 0.0722 * b;
        return lum > 135 ? "#11111b" : "#ffffff";
    }

    FileView {
        id: file
        path: (typeof Quickshell.shellPath === "function")
            ? Quickshell.shellPath("Asura/config/colors.json")
            : (Quickshell.env("HOME") + "/.config/quickshell/Asura/config/colors.json")
        watchChanges: false

        onLoaded: {
            root.ready = true;
            if (adapter.primarySlot && adapter.primarySlot !== "") {
                root.primarySlot = adapter.primarySlot;
            }
        }
        onLoadFailed: (error) => {
            if (error === FileViewError.FileNotFound)
                writeAdapter()
            else
                reload()
        }

        JsonAdapter {
            id: adapter

            // Active Accent Slot (base08 through base0F)
            property string primarySlot: "base0D"

            // Base16 Standard Slots
            property string base00: "#1e1e2e" // Default Background
            property string base01: "#181825" // Lighter Background / Surface
            property string base02: "#313244" // Selection Background / Container
            property string base03: "#45475a" // Comments, Invisibles, Borders
            property string base04: "#a6adc8" // Dark Foreground / Secondary Text
            property string base05: "#cdd6f4" // Default Foreground / Text
            property string base06: "#f5e0dc" // Light Foreground
            property string base07: "#ffffff" // Light Background
            property string base08: "#f38ba8" // Red / Error / Warning
            property string base09: "#fab387" // Orange
            property string base0A: "#f9e2af" // Yellow
            property string base0B: "#a6e3a1" // Green / Success
            property string base0C: "#94e2d5" // Aqua / Cyan / Tertiary
            property string base0D: "#89b4fa" // Blue / Primary
            property string base0E: "#cba6f7" // Purple / Secondary
            property string base0F: "#f2cdcd" // Brown / Accent

            // Semantic Aliases Mapped to Base16 with High Contrast
            property string background: base00
            property string surface: base01
            property string surfaceContainer: base02
            property string surfaceVariant: base03
            property string border: base03
            property string text: base05
            property string textSecondary: base04
            property string textBright: base06
            property string on_primary: "#11111b"
            property string primary: base0D
            property string secondary: base0E
            property string tertiary: base0C
            property string warning: base08
            property string error: base08
            property string success: base0B
            property string shadow: "#000000"
        }
    }

    Timer {
        id: saveTimer
        interval: 60
        repeat: false
        onTriggered: file.writeAdapter()
    }

    // Process to load all Base16 palettes from Asura/palettes/palettes.json
    Process {
        id: loadAllPalettesProc
        command: ["cat", root.palettesJsonPath]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!this.text || this.text.trim() === "") return;
                try {
                    var data = JSON.parse(this.text.trim());
                    if (data.palettes) {
                        root.allPalettes = data.palettes;
                        root.categories = data.categories || {};
                        root.darkList = data.dark_list || [];
                        root.lightList = data.light_list || [];
                        root.allPalettesList = (data.categories && data.categories.all) ? data.categories.all : [];
                    } else {
                        root.allPalettes = data;
                        var list = [];
                        var keys = Object.keys(data);
                        for (var i = 0; i < keys.length; i++) {
                            var k = keys[i];
                            var p = data[k];
                            list.push({
                                id: k,
                                name: k.replace(/-/g, ' ').replace(/\b\w/g, c => c.toUpperCase()),
                                color: p.base0D || p.base08 || "#89b4fa",
                                bg: p.base00 || "#1e1e2e",
                                fg: p.base05 || "#cdd6f4",
                                colors: p
                            });
                        }
                        list.sort((a, b) => a.name.localeCompare(b.name));
                        root.allPalettesList = list;
                        root.categories = { "all": list };
                    }
                } catch (e) {
                    console.warn("Colors: Failed to parse palettes.json:", e);
                }
            }
        }
    }

    // Process to load wallpaper_map.json
    Process {
        id: loadWallpaperMapProc
        command: ["cat", root.wallpaperMapPath]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!this.text || this.text.trim() === "") return;
                try {
                    root.wallpaperMap = JSON.parse(this.text.trim());
                } catch (e) {
                    console.warn("Colors: Failed to parse wallpaper_map.json:", e);
                }
            }
        }
    }

    readonly property string pinnedPalettesPath: (typeof Quickshell.shellPath === "function")
        ? Quickshell.shellPath("Asura/pinned_palettes.json")
        : (Quickshell.env("HOME") + "/.config/quickshell/Asura/pinned_palettes.json")

    property var pinnedPalettes: []

    // Process to load pinned_palettes.json
    Process {
        id: loadPinnedProc
        command: ["cat", root.pinnedPalettesPath]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!this.text || this.text.trim() === "") return;
                try {
                    var data = JSON.parse(this.text.trim());
                    if (Array.isArray(data)) {
                        root.pinnedPalettes = data;
                    }
                } catch (e) {
                    console.warn("Colors: Failed to parse pinned_palettes.json:", e);
                }
            }
        }
    }

    Process {
        id: savePinnedProc
        command: []
        running: false
    }

    function isPinned(paletteId) {
        if (!paletteId || !root.pinnedPalettes || !Array.isArray(root.pinnedPalettes)) return false;
        return root.pinnedPalettes.indexOf(paletteId) !== -1;
    }

    function togglePin(paletteId) {
        if (!paletteId) return;
        var list = (root.pinnedPalettes && Array.isArray(root.pinnedPalettes)) ? root.pinnedPalettes.slice() : [];
        var idx = list.indexOf(paletteId);
        if (idx !== -1) {
            list.splice(idx, 1);
        } else {
            list.unshift(paletteId);
        }
        root.pinnedPalettes = list;
        savePinnedPalettes();
    }

    function savePinnedPalettes() {
        var jsonStr = JSON.stringify(root.pinnedPalettes || [], null, 2);
        savePinnedProc.command = ["python3", "-c", "import sys; open(sys.argv[1], 'w', encoding='utf-8').write(sys.argv[2])", root.pinnedPalettesPath, jsonStr];
        savePinnedProc.running = false;
        savePinnedProc.running = true;
    }

    Process {
        id: matugenProc
        command: []
        running: false
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                file.reload();
            }
        }
    }

    Process {
        id: updateMappingProc
        command: []
        running: false
    }

    Process {
        id: fallbackThemeProc
        command: []
        property string pendingWallpaper: ""
        property bool isDark: true
        stdout: StdioCollector {
            onStreamFinished: {
                var raw = this.text ? this.text.trim() : "";
                if (!raw) return;
                try {
                    var res = JSON.parse(raw);
                    var themeName = "";
                    var currentIsDark = (typeof fallbackThemeProc.isDark === "boolean")
                        ? fallbackThemeProc.isDark
                        : ((Config.ready && Config.cfg) ? Config.cfg.isDarkMode : root.isDarkMode);
                    if (typeof res === "object" && res !== null) {
                        themeName = (currentIsDark ? res.dark : res.light) || res.dark || res.light;
                        if (fallbackThemeProc.pendingWallpaper) {
                            root.wallpaperMap[fallbackThemeProc.pendingWallpaper] = res;
                        }
                    } else if (typeof res === "string") {
                        themeName = res;
                        if (fallbackThemeProc.pendingWallpaper) {
                            root.wallpaperMap[fallbackThemeProc.pendingWallpaper] = res;
                        }
                    }
                    if (themeName) {
                        if (Config.ready && Config.cfg) {
                            Config.cfg.theme = themeName;
                            Config.save();
                        }
                        root.loadPalette(themeName);
                    }
                } catch(e) {
                    var strTheme = raw.trim();
                    if (strTheme) {
                        if (fallbackThemeProc.pendingWallpaper) {
                            root.wallpaperMap[fallbackThemeProc.pendingWallpaper] = strTheme;
                        }
                        if (Config.ready && Config.cfg) {
                            Config.cfg.theme = strTheme;
                            Config.save();
                        }
                        root.loadPalette(strTheme);
                    }
                }
            }
        }
    }

    function setPrimarySlot(slotKey) {
        if (!slotKey) return;
        root.primarySlot = slotKey;
        adapter.primarySlot = slotKey;
        if (adapter[slotKey] !== undefined) {
            adapter.primary = adapter[slotKey];
            adapter.on_primary = getContrastColor(adapter[slotKey]);
        }
        saveTimer.restart();
    }

    function applyBase16(pal) {
        if (!pal) return;
        adapter.base00 = pal.base00 || adapter.base00;
        adapter.base01 = pal.base01 || adapter.base01;
        adapter.base02 = pal.base02 || adapter.base02;
        adapter.base03 = pal.base03 || adapter.base03;
        adapter.base04 = pal.base04 || adapter.base04;
        adapter.base05 = pal.base05 || adapter.base05;
        adapter.base06 = pal.base06 || adapter.base06;
        adapter.base07 = pal.base07 || adapter.base07;
        adapter.base08 = pal.base08 || adapter.base08;
        adapter.base09 = pal.base09 || adapter.base09;
        adapter.base0A = pal.base0A || adapter.base0A;
        adapter.base0B = pal.base0B || adapter.base0B;
        adapter.base0C = pal.base0C || adapter.base0C;
        adapter.base0D = pal.base0D || adapter.base0D;
        adapter.base0E = pal.base0E || adapter.base0E;
        adapter.base0F = pal.base0F || adapter.base0F;

        adapter.background = adapter.base00;
        adapter.surface = adapter.base01;
        adapter.surfaceContainer = adapter.base02;
        adapter.surfaceVariant = adapter.base03;
        adapter.border = adapter.base03;
        adapter.text = adapter.base05;
        adapter.textSecondary = adapter.base04;
        adapter.textBright = adapter.base06;

        var activeSlot = root.primarySlot || adapter.primarySlot || "base0D";
        adapter.primarySlot = activeSlot;
        adapter.primary = adapter[activeSlot] || pal[activeSlot] || adapter.base0D;
        adapter.on_primary = getContrastColor(adapter.primary);

        adapter.secondary = adapter.base0E;
        adapter.tertiary = adapter.base0C;
        adapter.warning = adapter.base08;
        adapter.error = adapter.base08;
        adapter.success = adapter.base0B;

        saveTimer.restart();
    }

    function loadPalette(paletteId) {
        if (!paletteId) return;
        if (root.allPalettes && root.allPalettes[paletteId]) {
            applyBase16(root.allPalettes[paletteId]);
            return;
        }
        var filePath = (typeof Quickshell.shellPath === "function" ? Quickshell.shellPath("Asura/palettes") : (Quickshell.env("HOME") + "/.config/quickshell/Asura/palettes")) + "/" + paletteId + ".json";
        var p = Qt.createQmlObject('import Quickshell.Io; Process { command: ["cat", "' + filePath + '"]; stdout: StdioCollector { onStreamFinished: { if (text) { try { var d = JSON.parse(text.trim()); if (d) Colors.applyBase16(d.palette || d); } catch(e){} } } } }', root);
        p.running = true;
    }

    function generateMatugenColors(wallpaperPath, isDark, schemeType) {
        if (!wallpaperPath) return;
        var cleanPath = wallpaperPath.toString().replace("file://", "");
        var isDarkVal = (typeof isDark === "boolean")
            ? isDark
            : ((Config.ready && Config.cfg) ? Config.cfg.isDarkMode : root.isDarkMode);
        var modeArg = isDarkVal ? "dark" : "light";
        var selectedScheme = schemeType || ((Config.ready && Config.cfg) ? Config.cfg.scheme : "smart") || "smart";
        var schemeArg = selectedScheme.indexOf("scheme-") === 0 ? selectedScheme : ("scheme-" + selectedScheme);

        matugenProc.command = ["matugen", "image", cleanPath, "-m", modeArg, "-t", schemeArg, "--source-color-index", "0"];
        matugenProc.running = false;
        matugenProc.running = true;
    }

    function updateWallpaperMapping(wallpaperPath, paletteId, isDark) {
        if (!wallpaperPath || !paletteId) return;
        var filename = wallpaperPath.toString();
        var lastSlash = filename.lastIndexOf("/");
        if (lastSlash !== -1) {
            filename = filename.substring(lastSlash + 1);
        }

        var darkMode = (typeof isDark === "boolean")
            ? isDark
            : ((Config.ready && Config.cfg) ? Config.cfg.isDarkMode : root.isDarkMode);

        var existingEntry = root.wallpaperMap[filename];
        if (typeof existingEntry === "object" && existingEntry !== null) {
            if (darkMode) {
                existingEntry.dark = paletteId;
            } else {
                existingEntry.light = paletteId;
            }
        } else {
            root.wallpaperMap[filename] = {
                dark: paletteId,
                light: paletteId
            };
        }

        var fullPath = wallpaperPath.toString().replace("file://", "");
        updateMappingProc.command = [
            "python3",
            root.mapperScriptPath,
            "set",
            fullPath,
            paletteId,
            "--mode",
            darkMode ? "dark" : "light"
        ];
        updateMappingProc.running = false;
        updateMappingProc.running = true;
    }

    function suggestPaletteFromWallpaper(wallpaperPath, isDark) {
        if (!wallpaperPath) return;
        var filename = wallpaperPath.toString();
        var lastSlash = filename.lastIndexOf("/");
        if (lastSlash !== -1) {
            filename = filename.substring(lastSlash + 1);
        }

        var darkMode = (typeof isDark === "boolean")
            ? isDark
            : ((Config.ready && Config.cfg) ? Config.cfg.isDarkMode : root.isDarkMode);

        if (root.wallpaperMap && root.wallpaperMap[filename]) {
            var entry = root.wallpaperMap[filename];
            var themeId = "";
            if (typeof entry === "object" && entry !== null) {
                themeId = (darkMode ? entry.dark : entry.light) || entry.dark || entry.light;
            } else if (typeof entry === "string") {
                themeId = entry;
            }
            if (themeId) {
                if (Config.ready && Config.cfg) {
                    Config.cfg.theme = themeId;
                    Config.save();
                }
                root.loadPalette(themeId);
                return;
            }
        }

        var fullPath = wallpaperPath.toString().replace("file://", "");
        fallbackThemeProc.pendingWallpaper = filename;
        fallbackThemeProc.isDark = darkMode;
        fallbackThemeProc.command = ["python3", root.mapperScriptPath, "single", fullPath];
        fallbackThemeProc.running = false;
        fallbackThemeProc.running = true;
    }

    function applyThemeFromWallpaper(wallpaperPath, isDark) {
        suggestPaletteFromWallpaper(wallpaperPath, isDark);
    }

    Component.onCompleted: {
        loadAllPalettesProc.running = true;
        loadWallpaperMapProc.running = true;
        loadPinnedProc.running = true;
    }
}

