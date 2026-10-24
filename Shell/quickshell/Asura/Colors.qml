import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Singleton {
    id: root

    readonly property alias cfg: adapter
    property bool ready: false
    property bool reloading: false
    property bool isDarkMode: Config.ready ? Config.cfg.isDarkMode : true
    property var allPalettes: ({
    })
    property var categories: ({
    })
    property var darkList: []
    property var lightList: []
    property var allPalettesList: []
    property var wallpaperMap: ({
    })
    property string primarySlot: "base0D"
    readonly property string palettesJsonPath: (typeof Quickshell.shellPath === "function") ? Quickshell.shellPath("Asura/palettes/palettes.json") : (Quickshell.env("HOME") + "/.config/quickshell/Asura/palettes/palettes.json")
    readonly property string wallpaperMapPath: Quickshell.env("HOME") + "/.config/asura/data/wallpaper_map.json"
    readonly property string mapperScriptPath: (typeof Quickshell.shellPath === "function") ? Quickshell.shellPath("Services/AutoTheme/main.py") : (Quickshell.env("HOME") + "/.config/quickshell/Services/AutoTheme/main.py")
    readonly property string dynamicScriptPath: (typeof Quickshell.shellPath === "function") ? Quickshell.shellPath("scripts/colors/switchwall.sh") : (Quickshell.env("HOME") + "/.config/quickshell/scripts/colors/switchwall.sh")
    readonly property var availableCategories: ["all", "blue", "cyan", "purple", "green", "red", "yellow", "orange", "monochrome"]
    readonly property var availablePalettes: root.allPalettesList
    readonly property string pinnedPalettesPath: Quickshell.env("HOME") + "/.config/asura/data/pinned_palettes.json"
    property var pinnedPalettes: []

    function getContrastColor(hexColor) {
        if (!hexColor)
            return "#ffffff";

        var str = hexColor.toString().replace("#", "");
        if (str.length === 3)
            str = str.split("").map((c) => {
                return c + c;
            }).join("");

        if (str.length < 6)
            return "#ffffff";

        var r = parseInt(str.substring(0, 2), 16) || 0;
        var g = parseInt(str.substring(2, 4), 16) || 0;
        var b = parseInt(str.substring(4, 6), 16) || 0;
        var lum = 0.2126 * r + 0.7152 * g + 0.0722 * b;
        return lum > 135 ? "#11111b" : "#ffffff";
    }

    function isPinned(paletteId) {
        if (!paletteId || !root.pinnedPalettes || !Array.isArray(root.pinnedPalettes))
            return false;

        return root.pinnedPalettes.indexOf(paletteId) !== -1;
    }

    function togglePin(paletteId) {
        if (!paletteId)
            return ;

        var list = (root.pinnedPalettes && Array.isArray(root.pinnedPalettes)) ? root.pinnedPalettes.slice() : [];
        var idx = list.indexOf(paletteId);
        if (idx !== -1)
            list.splice(idx, 1);
        else
            list.unshift(paletteId);
        root.pinnedPalettes = list;
        savePinnedPalettes();
    }

    function savePinnedPalettes() {
        var jsonStr = JSON.stringify(root.pinnedPalettes || [], null, 2);
        savePinnedProc.command = ["python3", "-c", "import sys; open(sys.argv[1], 'w', encoding='utf-8').write(sys.argv[2])", root.pinnedPalettesPath, jsonStr];
        savePinnedProc.running = false;
        savePinnedProc.running = true;
    }

    function reload() {
        if (saveTimer.running) {
            saveTimer.stop();
        }
        root.reloading = true;
        file.reload();
        Qt.callLater(function() {
            root.reloading = false;
        });
    }

    function setPrimarySlot(slotKey) {
        if (!slotKey)
            return ;

        root.primarySlot = slotKey;
        adapter.primarySlot = slotKey;
        if (adapter[slotKey] !== undefined) {
            adapter.primary = adapter[slotKey];
            adapter.on_primary = getContrastColor(adapter[slotKey]);
        }
        if (typeof Config !== "undefined" && Config.ready && Config.cfg && Config.cfg.primarySlot !== slotKey) {
            Config.cfg.primarySlot = slotKey;
            Config.save();
        }
        saveTimer.restart();
        applyTemplatesTimer.restart();
    }

    function applyTemplates() {
        var isAuto = (Config.ready && Config.cfg) ? Config.cfg.colorsAutoGenerate : false;
        var curTheme = (!isAuto && Config.ready && Config.cfg && Config.cfg.theme) ? Config.cfg.theme : "";
        var wall = (Config.ready && Config.cfg && Config.cfg.wallpaper) ? Config.cfg.wallpaper : "";
        var cleanWall = wall ? wall.toString().replace("file://", "") : "";
        var isDarkVal = (Config.ready && Config.cfg) ? Config.cfg.isDarkMode : root.isDarkMode;
        var modeArg = isDarkVal ? "dark" : "light";
        var selectedScheme = ((Config.ready && Config.cfg) ? Config.cfg.scheme : "tonal-spot") || "tonal-spot";
        var schemeArg = selectedScheme.indexOf("scheme-") === 0 ? selectedScheme.replace("scheme-", "") : selectedScheme;
        var slotKey = root.primarySlot || (Config.ready && Config.cfg && Config.cfg.primarySlot) || "base0D";

        var cmd = ["/usr/bin/bash", root.dynamicScriptPath];
        if (curTheme) {
            cmd.push("--palette");
            cmd.push(curTheme);
        } else if (!isAuto) {
            cmd.push("--palette");
            cmd.push(Quickshell.env("HOME") + "/.config/asura/colors.json");
        }
        if (cleanWall) {
            cmd.push("--path");
            cmd.push(cleanWall);
        }
        cmd.push("--mode");
        cmd.push(modeArg);
        cmd.push("--scheme");
        cmd.push(schemeArg);
        cmd.push("--primary-slot");
        cmd.push(slotKey);

        dynamicColorsProc.command = cmd;
        dynamicColorsProc.running = false;
        dynamicColorsProc.running = true;
    }

    function applyBase16(pal) {
        if (!pal)
            return ;

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
        var activeSlot = (typeof Config !== "undefined" && Config.ready && Config.cfg && Config.cfg.primarySlot)
            ? Config.cfg.primarySlot
            : (root.primarySlot || adapter.primarySlot || "base0D");
        root.primarySlot = activeSlot;
        adapter.primarySlot = activeSlot;
        adapter.primary = adapter[activeSlot] || pal[activeSlot] || adapter.base0D;
        adapter.on_primary = getContrastColor(adapter.primary);
        adapter.secondary = adapter.base0E;
        adapter.tertiary = adapter.base0C;
        adapter.warning = adapter.base08;
        adapter.error = adapter.base08;
        adapter.success = adapter.base0B;
        saveTimer.restart();

        var palId = pal.id || (typeof pal === "string" ? pal : "");
        var wall = (Config.ready && Config.cfg && Config.cfg.wallpaper) ? Config.cfg.wallpaper : "";
        var cleanWall = wall ? wall.toString().replace("file://", "") : "";
        var isDarkVal = (typeof pal.type === "string") ? (pal.type === "dark") : ((Config.ready && Config.cfg) ? Config.cfg.isDarkMode : root.isDarkMode);
        var modeArg = isDarkVal ? "dark" : "light";
        var palParam = palId ? palId : JSON.stringify(pal);

        var cmd = ["/usr/bin/bash", root.dynamicScriptPath, "--palette", palParam, "--mode", modeArg, "--primary-slot", activeSlot];
        if (cleanWall) {
            cmd.push("--path");
            cmd.push(cleanWall);
        }
        dynamicColorsProc.command = cmd;
        dynamicColorsProc.running = false;
        dynamicColorsProc.running = true;
    }

    function loadPalette(paletteId) {
        if (!paletteId)
            return ;

        if (root.allPalettes && root.allPalettes[paletteId]) {
            applyBase16(root.allPalettes[paletteId]);
            return ;
        }
        var filePath = (typeof Quickshell.shellPath === "function" ? Quickshell.shellPath("Asura/palettes") : (Quickshell.env("HOME") + "/.config/quickshell/Asura/palettes")) + "/" + paletteId + ".json";
        var p = Qt.createQmlObject('import Quickshell.Io; Process { command: ["cat", "' + filePath + '"]; stdout: StdioCollector { onStreamFinished: { if (text) { try { var d = JSON.parse(text.trim()); if (d) Colors.applyBase16(d.palette || d); } catch(e){} } } } }', root);
        p.running = true;
    }

    function generateDynamicColors(wallpaperPath, isDark, schemeType) {
        if (!wallpaperPath)
            return ;

        var cleanPath = wallpaperPath.toString().replace("file://", "");
        var isDarkVal = (typeof isDark === "boolean") ? isDark : ((Config.ready && Config.cfg) ? Config.cfg.isDarkMode : root.isDarkMode);
        var modeArg = isDarkVal ? "dark" : "light";
        var selectedScheme = schemeType || ((Config.ready && Config.cfg) ? Config.cfg.scheme : "tonal-spot") || "tonal-spot";
        var schemeArg = selectedScheme.indexOf("scheme-") === 0 ? selectedScheme.replace("scheme-", "") : selectedScheme;
        var slotKey = root.primarySlot || (Config.ready && Config.cfg && Config.cfg.primarySlot) || "base0D";
        dynamicColorsProc.command = ["/usr/bin/bash", root.dynamicScriptPath, "--path", cleanPath, "--mode", modeArg, "--scheme", schemeArg, "--primary-slot", slotKey];
        dynamicColorsProc.running = false;
        dynamicColorsProc.running = true;
    }

    function generateColorsFromSeed(seedColor, isDark, schemeType) {
        if (!seedColor) return;
        var cleanColor = seedColor.toString().trim();
        if (cleanColor.indexOf("#") !== 0) {
            cleanColor = "#" + cleanColor;
        }
        var isDarkVal = (typeof isDark === "boolean") ? isDark : ((Config.ready && Config.cfg) ? Config.cfg.isDarkMode : root.isDarkMode);
        var modeArg = isDarkVal ? "dark" : "light";
        var selectedScheme = schemeType || ((Config.ready && Config.cfg) ? Config.cfg.scheme : "tonal-spot") || "tonal-spot";
        var schemeArg = selectedScheme.indexOf("scheme-") === 0 ? selectedScheme.replace("scheme-", "") : selectedScheme;
        var slotKey = root.primarySlot || (Config.ready && Config.cfg && Config.cfg.primarySlot) || "base0D";
        dynamicColorsProc.command = ["/usr/bin/bash", root.dynamicScriptPath, "--color", cleanColor, "--mode", modeArg, "--scheme", schemeArg, "--primary-slot", slotKey];
        dynamicColorsProc.running = false;
        dynamicColorsProc.running = true;
    }

    function generateMatugenColors(wallpaperPath, isDark, schemeType) {
        generateDynamicColors(wallpaperPath, isDark, schemeType);
    }

    function isPresetWallpaperPath(wallpaperPath) {
        if (!wallpaperPath)
            return false;
        var s = wallpaperPath.toString();
        return s.indexOf("/presets/") !== -1 || s.indexOf("/data/presets/") !== -1;
    }

    function updateWallpaperMapping(wallpaperPath, paletteId, isDark) {
        if (!wallpaperPath || !paletteId || isPresetWallpaperPath(wallpaperPath))
            return ;

        var filename = wallpaperPath.toString();
        var lastSlash = filename.lastIndexOf("/");
        if (lastSlash !== -1)
            filename = filename.substring(lastSlash + 1);

        if (filename === "wallpaper.jpg" || filename === "wallpaper.png" || filename === "wallpaper.jpeg")
            return ;

        var darkMode = (typeof isDark === "boolean") ? isDark : ((Config.ready && Config.cfg) ? Config.cfg.isDarkMode : root.isDarkMode);
        var existingEntry = root.wallpaperMap[filename];
        if (typeof existingEntry === "object" && existingEntry !== null) {
            if (darkMode)
                existingEntry.dark = paletteId;
            else
                existingEntry.light = paletteId;
        } else {
            root.wallpaperMap[filename] = {
                "dark": paletteId,
                "light": paletteId
            };
        }
        var fullPath = wallpaperPath.toString().replace("file://", "");
        updateMappingProc.command = ["python3", root.mapperScriptPath, "set", fullPath, paletteId, "--mode", darkMode ? "dark" : "light"];
        updateMappingProc.running = false;
        updateMappingProc.running = true;
    }

    function suggestPaletteFromWallpaper(wallpaperPath, isDark) {
        if (!wallpaperPath || isPresetWallpaperPath(wallpaperPath))
            return ;

        var filename = wallpaperPath.toString();
        var lastSlash = filename.lastIndexOf("/");
        if (lastSlash !== -1)
            filename = filename.substring(lastSlash + 1);

        if (filename === "wallpaper.jpg" || filename === "wallpaper.png" || filename === "wallpaper.jpeg")
            return ;

        var darkMode = (typeof isDark === "boolean") ? isDark : ((Config.ready && Config.cfg) ? Config.cfg.isDarkMode : root.isDarkMode);
        if (root.wallpaperMap && root.wallpaperMap[filename]) {
            var entry = root.wallpaperMap[filename];
            var themeId = "";
            if (typeof entry === "object" && entry !== null)
                themeId = (darkMode ? entry.dark : entry.light) || entry.dark || entry.light;
            else if (typeof entry === "string")
                themeId = entry;
            if (themeId) {
                if (Config.ready && Config.cfg) {
                    Config.cfg.theme = themeId;
                    Config.save();
                }
                root.loadPalette(themeId);
                return ;
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
        if (!wallpaperPath || isPresetWallpaperPath(wallpaperPath))
            return ;
        suggestPaletteFromWallpaper(wallpaperPath, isDark);
    }

    Component.onCompleted: {
        loadAllPalettesProc.running = true;
        loadWallpaperMapProc.running = true;
        loadPinnedProc.running = true;
    }

    FileView {
        id: file

        path: Quickshell.env("HOME") + "/.config/asura/colors.json"
        watchChanges: true
        onFileChanged: {
            reload();
        }
        onLoaded: {
            root.ready = true;
            if (adapter.primarySlot && adapter.primarySlot !== "") {
                root.primarySlot = adapter.primarySlot;
                if (adapter[adapter.primarySlot] !== undefined) {
                    adapter.primary = adapter[adapter.primarySlot];
                    adapter.on_primary = root.getContrastColor(adapter.primary);
                }
            }
        }
        onLoadFailed: (error) => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
            else
                reload();
        }

        JsonAdapter {

            id: adapter

            property string primarySlot: "base0D"
            property string base00: "#1e1e2e"
            property string base01: "#181825"
            property string base02: "#313244"
            property string base03: "#45475a"
            property string base04: "#a6adc8"
            property string base05: "#cdd6f4"
            property string base06: "#f5e0dc"
            property string base07: "#ffffff"
            property string base08: "#f38ba8"
            property string base09: "#fab387"
            property string base0A: "#f9e2af"
            property string base0B: "#a6e3a1"
            property string base0C: "#94e2d5"
            property string base0D: "#89b4fa"
            property string base0E: "#cba6f7"
            property string base0F: "#f2cdcd"
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

            property string primaryContainer: primary
            property string onPrimaryContainer: on_primary
            property string secondaryContainer: secondary
            property string onSecondaryContainer: surface
            property string tertiaryContainer: tertiary
            property string onTertiaryContainer: surface
            property string surfaceContainerLowest: background
            property string surfaceContainerLow: surface
            property string surfaceContainerHigh: surfaceVariant
            property string surfaceContainerHighest: surfaceVariant
            property string surfaceDim: background
            property string surfaceBright: surfaceContainer
            property string outline: border
            property string outlineVariant: border
            property string inverseSurface: textBright
            property string inverseOnSurface: background
            property string inversePrimary: primary
        }

    }

    Timer {
        id: saveTimer

        interval: 60
        repeat: false
        onTriggered: {
            if (!root.reloading) {
                file.writeAdapter();
            }
        }
    }

    Timer {
        id: applyTemplatesTimer

        interval: 200
        repeat: false
        onTriggered: root.applyTemplates()
    }

    Process {
        id: loadAllPalettesProc

        command: ["cat", root.palettesJsonPath]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                if (!this.text || this.text.trim() === "")
                    return ;

                try {
                    var data = JSON.parse(this.text.trim());
                    if (data.palettes) {
                        root.allPalettes = data.palettes;
                        root.categories = data.categories || {
                        };
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
                                "id": k,
                                "name": k.replace(/-/g, ' ').replace(/\b\w/g, (c) => {
                                    return c.toUpperCase();
                                }),
                                "color": p.base0D || p.base08 || "#89b4fa",
                                "bg": p.base00 || "#1e1e2e",
                                "fg": p.base05 || "#cdd6f4",
                                "colors": p
                            });
                        }
                        list.sort((a, b) => {
                            return a.name.localeCompare(b.name);
                        });
                        root.allPalettesList = list;
                        root.categories = {
                            "all": list
                        };
                    }
                } catch (e) {
                    console.warn("Colors: Failed to parse palettes.json:", e);
                }
            }
        }

    }

    Process {
        id: loadWallpaperMapProc

        command: ["cat", root.wallpaperMapPath]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                if (!this.text || this.text.trim() === "")
                    return ;

                try {
                    root.wallpaperMap = JSON.parse(this.text.trim());
                } catch (e) {
                    console.warn("Colors: Failed to parse wallpaper_map.json:", e);
                }
            }
        }

    }

    Process {
        id: loadPinnedProc

        command: ["cat", root.pinnedPalettesPath]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                if (!this.text || this.text.trim() === "")
                    return ;

                try {
                    var data = JSON.parse(this.text.trim());
                    if (Array.isArray(data))
                        root.pinnedPalettes = data;

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

    Process {
        id: dynamicColorsProc

        command: []
        running: false
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                file.reload();

        }
    }

    readonly property alias dynamicProc: dynamicColorsProc
    readonly property alias matugenProc: dynamicColorsProc

    Process {
        id: updateMappingProc

        command: []
        running: false
    }

    Process {
        id: fallbackThemeProc

        property string pendingWallpaper: ""
        property bool isDark: true

        command: []

        stdout: StdioCollector {
            onStreamFinished: {
                var raw = this.text ? this.text.trim() : "";
                if (!raw)
                    return ;

                try {
                    var res = JSON.parse(raw);
                    var themeName = "";
                    var currentIsDark = (typeof fallbackThemeProc.isDark === "boolean") ? fallbackThemeProc.isDark : ((Config.ready && Config.cfg) ? Config.cfg.isDarkMode : root.isDarkMode);
                    if (typeof res === "object" && res !== null) {
                        themeName = (currentIsDark ? res.dark : res.light) || res.dark || res.light;
                        if (fallbackThemeProc.pendingWallpaper)
                            root.wallpaperMap[fallbackThemeProc.pendingWallpaper] = res;

                    } else if (typeof res === "string") {
                        themeName = res;
                        if (fallbackThemeProc.pendingWallpaper)
                            root.wallpaperMap[fallbackThemeProc.pendingWallpaper] = res;

                    }
                    if (themeName) {
                        if (Config.ready && Config.cfg) {
                            Config.cfg.theme = themeName;
                            Config.save();
                        }
                        root.loadPalette(themeName);
                    }
                } catch (e) {
                    var strTheme = raw.trim();
                    if (strTheme) {
                        if (fallbackThemeProc.pendingWallpaper)
                            root.wallpaperMap[fallbackThemeProc.pendingWallpaper] = strTheme;

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

}
