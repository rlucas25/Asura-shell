import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.Asura
import qs.Modules
import qs.Modules.Launcher
import qs.Services

PanelWindow {
    id: root

    property bool isOpen: false
    property string currentView: "launcher"
    readonly property var activeContent: currentView === "wallpaper" ? wallpaperLoader.item : (currentView === "presets" ? presetLoader.item : null)
    property real uiScale: 1.05
    property string searchQuery: ""
    property int selectedIndex: 0
    property bool gridMode: false
    property bool helpMode: false
    property var currentTime: new Date()
    property string shellOutput: ""
    property bool showingShellOutput: false
    property string commandSubMode: ""

    WlrLayershell.namespace: "ZenLauncher"
    visible: isOpen
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    onSelectedIndexChanged: {
        if (root.gridMode && gridFlickable && gridFlickable.visible) {
            root.ensureGridIndexVisible(root.selectedIndex);
        } else if (!root.gridMode && resultsListView.visible && root.filteredResults.length > 0) {
            resultsListView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
        }
    }

    onGridModeChanged: {
        if (gridMode) {
            selectedIndex = 0;
            if (gridFlickable) {
                gridScrollAnim.stop();
                gridFlickable.contentY = 0;
            }
        }
    }

    function toggle() {
        if (isOpen) {
            close();
        } else {
            open();
        }
    }

    function open() {
        isOpen = true;
    }

    function close() {
        isOpen = false;
        searchQuery = "";
        if (searchInput) searchInput.text = "";
        gridMode = false;
        helpMode = false;
        showingShellOutput = false;
        shellOutput = "";
        commandSubMode = "";
        selectedIndex = 0;
        currentView = "launcher";
    }

    onIsOpenChanged: {
        if (isOpen) {
            MenuService.registerMenuOpen(root);
            AppLauncherState.show();
            currentTime = new Date();
            searchQuery = "";
            gridMode = false;
            helpMode = false;
            showingShellOutput = false;
            shellOutput = "";
            commandSubMode = "";
            selectedIndex = 0;
            if (root.currentView === "launcher") {
                if (searchInput) {
                    searchInput.text = "";
                    Qt.callLater(function() {
                        if (root.isOpen && root.currentView === "launcher" && searchInput)
                            searchInput.forceActiveFocus();
                    });
                }
            } else if (root.currentView === "presets") {
                Qt.callLater(function() {
                    if (presetLoader.item) {
                        if (typeof presetLoader.item.focusSearchInput === "function")
                            presetLoader.item.focusSearchInput();
                        else
                            presetLoader.item.forceActiveFocus();
                    }
                });
            } else if (root.currentView === "wallpaper") {
                Qt.callLater(function() {
                    if (wallpaperLoader.item)
                        wallpaperLoader.item.forceActiveFocus();
                });
            }
        } else {
            MenuService.unregisterMenuOpen(root);
            AppLauncherState.hide();
            root.currentView = "launcher";
        }
    }

    onCurrentViewChanged: {
        if (!isOpen) return;
        if (currentView === "launcher") {
            if (searchInput) {
                Qt.callLater(function() {
                    if (root.isOpen && root.currentView === "launcher" && searchInput)
                        searchInput.forceActiveFocus();
                });
            }
        } else if (currentView === "presets") {
            Qt.callLater(function() {
                if (presetLoader.item) {
                    if (typeof presetLoader.item.focusSearchInput === "function")
                        presetLoader.item.focusSearchInput();
                    else
                        presetLoader.item.forceActiveFocus();
                }
            });
        } else if (currentView === "wallpaper") {
            Qt.callLater(function() {
                if (wallpaperLoader.item)
                    wallpaperLoader.item.forceActiveFocus();
            });
        }
    }

    Component.onDestruction: {
        MenuService.unregisterMenuOpen(root);
    }

    Connections {
        target: MenuService

        function onCloseAllRequested() {
            root.close();
        }

        function onToggleLauncherRequested(monitorName) {
            if (Config.cfg && Config.cfg.launcherPosition !== "zen" && Config.cfg.launcherPosition !== "zen mode") {
                if (root.isOpen) root.close();
                return;
            }

            var target = (monitorName && monitorName !== "") ? monitorName : (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "");
            if (target === "" && Quickshell.screens && Quickshell.screens.length > 0)
                target = Quickshell.screens[0].name;

            if (root.screen && root.screen.name === target) {
                if (root.isOpen && root.currentView === "launcher") {
                    root.close();
                } else {
                    root.currentView = "launcher";
                    root.open();
                }
            } else {
                root.close();
            }
        }

        function onOpenLauncherRequested(monitorName) {
            if (Config.cfg && Config.cfg.launcherPosition !== "zen" && Config.cfg.launcherPosition !== "zen mode") {
                if (root.isOpen) root.close();
                return;
            }

            var target = (monitorName && monitorName !== "") ? monitorName : (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "");
            if (target === "" && Quickshell.screens && Quickshell.screens.length > 0)
                target = Quickshell.screens[0].name;

            if (root.screen && root.screen.name === target) {
                root.currentView = "launcher";
                root.open();
            } else {
                root.close();
            }
        }

        function onToggleWallpaperRequested(monitorName) {
            if (Config.cfg && Config.cfg.launcherPosition !== "zen" && Config.cfg.launcherPosition !== "zen mode") {
                if (root.isOpen) root.close();
                return;
            }

            var target = (monitorName && monitorName !== "") ? monitorName : (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "");
            if (target === "" && Quickshell.screens && Quickshell.screens.length > 0)
                target = Quickshell.screens[0].name;

            if (root.screen && root.screen.name === target) {
                if (root.isOpen && root.currentView === "wallpaper") {
                    root.close();
                } else {
                    root.currentView = "wallpaper";
                    root.open();
                }
            } else {
                root.close();
            }
        }

        function onTogglePresetsRequested(monitorName) {
            if (Config.cfg && Config.cfg.launcherPosition !== "zen" && Config.cfg.launcherPosition !== "zen mode") {
                if (root.isOpen) root.close();
                return;
            }

            var target = (monitorName && monitorName !== "") ? monitorName : (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "");
            if (target === "" && Quickshell.screens && Quickshell.screens.length > 0)
                target = Quickshell.screens[0].name;

            if (root.screen && root.screen.name === target) {
                if (root.isOpen && root.currentView === "presets") {
                    root.close();
                } else {
                    root.currentView = "presets";
                    root.open();
                }
            } else {
                root.close();
            }
        }
    }

    Process {
        id: shellProcess

        property string shellCommand: ""

        command: ["sh", "-c", shellCommand]

        onExited: function(exitCode, exitStatus) {
            root.shellOutput += "\n\nExit code: " + exitCode;
        }

        stdout: StdioCollector {
            onStreamFinished: {
                root.shellOutput += text;
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                root.shellOutput += text;
            }
        }
    }

    function executeShellCommand(command) {
        command = command.trim();
        if (command === "")
            return;

        shellOutput = "Executing: " + command + "\n\n";
        showingShellOutput = true;
        shellProcess.shellCommand = command;
        shellProcess.running = true;
    }

    Timer {
        interval: 1000
        running: root.isOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.currentTime = new Date();
        }
    }

    function calculateExpression(expression) {
        var expr = expression.trim();
        if (expr.startsWith("=")) expr = expr.substring(1).trim();
        if (expr === "") return "";
        if (!/^[0-9+\-*\/%().,\s^a-zA-Z]+$/.test(expr)) return "Erro";

        expr = expr.replace(/,/g, ".");
        expr = expr.replace(/\^/g, "**");
        expr = expr.replace(/\bsqrt\s*\(/gi, "Math.sqrt(");
        expr = expr.replace(/\bsin\s*\(/gi, "Math.sin(");
        expr = expr.replace(/\bcos\s*\(/gi, "Math.cos(");
        expr = expr.replace(/\btan\s*\(/gi, "Math.tan(");
        expr = expr.replace(/\babs\s*\(/gi, "Math.abs(");
        expr = expr.replace(/\bceil\s*\(/gi, "Math.ceil(");
        expr = expr.replace(/\bfloor\s*\(/gi, "Math.floor(");
        expr = expr.replace(/\bround\s*\(/gi, "Math.round(");
        expr = expr.replace(/\blog\s*\(/gi, "Math.log(");
        expr = expr.replace(/\bpi\b/gi, "Math.PI");
        expr = expr.replace(/\be\b/g, "Math.E");

        var remaining = expr.replace(/Math\.(sqrt|sin|cos|tan|abs|ceil|floor|round|log|PI|E)/g, "").replace(/[\d+\-*\/%().\s]/g, "");
        if (remaining !== "") return "Erro";

        try {
            var result = Function('"use strict"; return (' + expr + ')')();
            if (!isFinite(result)) return "Erro";
            if (Math.abs(result - Math.round(result)) < 1e-09) return String(Math.round(result));
            return String(Number(result.toFixed(4)));
        } catch (e) {
            return "Erro";
        }
    }

    function getSystemCommands(query) {
        var q = query.toLowerCase();
        var cfg = Config.cfg;
        var isDynamic = cfg ? cfg.colorsAutoGenerate : false;
        var currentScheme = cfg ? cfg.scheme : "";
        var currentTheme = cfg ? cfg.theme : "";

        var backItem = {
            id: "cmd_back",
            type: "command",
            stayOpen: true,
            name: "Back",
            subtitle: "Return to commands list",
            icon: "󰁍",
            badge: "BACK",
            execute: function() {
                root.commandSubMode = "";
                if (searchInput) searchInput.text = "> ";
            }
        };

        if (root.commandSubMode === "palette") {
            var pinnedList = (Colors.pinnedPalettes && Array.isArray(Colors.pinnedPalettes)) ? Colors.pinnedPalettes : [];
            var allPals = Colors.allPalettes || {};
            var palItems = [backItem];

            palItems.push({
                id: "cmd_palette_dynamic",
                type: "command",
                stayOpen: true,
                name: "Dynamic Palette",
                subtitle: "Generate colors dynamically from current wallpaper",
                icon: "󰏘",
                badge: isDynamic ? "ON" : "OFF",
                execute: function() {
                    if (!Config.cfg) return;
                    Config.cfg.colorsAutoGenerate = !Config.cfg.colorsAutoGenerate;
                    Config.save();
                    if (Config.cfg.colorsAutoGenerate) {
                        if (Config.cfg.wallpaper)
                            Colors.generateDynamicColors(Config.cfg.wallpaper, Config.cfg.isDarkMode, Config.cfg.scheme);
                    } else {
                        if (Config.cfg.wallpaper)
                            Colors.suggestPaletteFromWallpaper(Config.cfg.wallpaper, Config.cfg.isDarkMode);
                    }
                }
            });

            for (var pi = 0; pi < pinnedList.length; pi++) {
                (function(pid) {
                    var pal = allPals[pid] || {};
                    var palColor = pal.base0D || pal.base08 || "#89b4fa";
                    var palBg = pal.base00 || "#1e1e2e";
                    var palColors = [pal.base08, pal.base0B, pal.base0D, pal.base0E].filter(Boolean);
                    var isActive = !isDynamic && currentTheme === pid;

                    palItems.push({
                        id: "cmd_palette_" + pid,
                        type: "command",
                        stayOpen: false,
                        name: pid.charAt(0).toUpperCase() + pid.slice(1).replace(/-/g, " "),
                        subtitle: "Apply pinned color theme",
                        icon: "󰏘",
                        badge: isActive ? "ACTIVE" : "",
                        paletteData: {
                            color: palColor,
                            bg: palBg,
                            swatches: palColors
                        },
                        execute: function() {
                            if (!Config.cfg) return;
                            Config.cfg.colorsAutoGenerate = false;
                            Config.cfg.theme = pid;
                            Config.save();
                            Colors.loadPalette(pid);
                            if (Config.cfg.wallpaper)
                                Colors.updateWallpaperMapping(Config.cfg.wallpaper, pid, Config.cfg.isDarkMode);
                        }
                    });
                })(pinnedList[pi]);
            }

            if (q === "") return palItems;
            return palItems.filter(function(item) {
                return item.id === "cmd_back" || item.name.toLowerCase().indexOf(q) !== -1 || (item.subtitle && item.subtitle.toLowerCase().indexOf(q) !== -1);
            });
        }

        if (root.commandSubMode === "scheme") {
            var schemes = ["tonal-spot", "content", "expressive", "fidelity", "fruit-salad", "monochrome", "neutral", "rainbow", "vibrant"];
            var schItems = [backItem];

            for (var si = 0; si < schemes.length; si++) {
                (function(sc) {
                    var isActive = isDynamic && currentScheme === sc;
                    schItems.push({
                        id: "cmd_scheme_" + sc,
                        type: "command",
                        stayOpen: false,
                        name: sc.charAt(0).toUpperCase() + sc.slice(1).replace(/-/g, " "),
                        subtitle: "Material You color scheme",
                        icon: "󰸌",
                        badge: isActive ? "ACTIVE" : "",
                        execute: function() {
                            if (Config.cfg) {
                                Config.cfg.scheme = sc;
                                Config.cfg.colorsAutoGenerate = true;
                                Config.save();
                            }
                        }
                    });
                })(schemes[si]);
            }

            if (q === "") return schItems;
            return schItems.filter(function(item) {
                return item.id === "cmd_back" || item.name.toLowerCase().indexOf(q) !== -1 || (item.subtitle && item.subtitle.toLowerCase().indexOf(q) !== -1);
            });
        }

        if (root.commandSubMode === "power") {
            var powerItems = [backItem];

            powerItems.push({
                id: "cmd_power_lock",
                type: "command",
                name: "Lock",
                subtitle: "Lock current session immediately",
                icon: "󰌾",
                badge: "SECURITY",
                execute: function() {
                    root.close();
                    LockScreenService.lock();
                }
            });

            powerItems.push({
                id: "cmd_power_suspend",
                type: "command",
                name: "Suspend",
                subtitle: "Suspend system to RAM (sleep)",
                icon: "󰤄",
                badge: "POWER",
                execute: function() {
                    root.close();
                    Quickshell.execDetached(["systemctl", "suspend"]);
                }
            });

            powerItems.push({
                id: "cmd_power_hibernate",
                type: "command",
                name: "Hibernate",
                subtitle: "Save session state to disk and power off",
                icon: "󰒲",
                badge: "POWER",
                execute: function() {
                    root.close();
                    Quickshell.execDetached(["systemctl", "hibernate"]);
                }
            });

            powerItems.push({
                id: "cmd_power_logout",
                type: "command",
                name: "Log Out",
                subtitle: "Exit current desktop session and close Hyprland",
                icon: "󰍃",
                badge: "SESSION",
                execute: function() {
                    root.close();
                    Quickshell.execDetached(["killall", "Hyprland"]);
                }
            });

            powerItems.push({
                id: "cmd_power_reboot",
                type: "command",
                name: "Reboot",
                subtitle: "Restart the system (systemctl reboot)",
                icon: "󰜉",
                badge: "POWER",
                execute: function() {
                    root.close();
                    Quickshell.execDetached(["systemctl", "reboot"]);
                }
            });

            powerItems.push({
                id: "cmd_power_shutdown",
                type: "command",
                name: "Shut Down",
                subtitle: "Power off the system completely (systemctl poweroff)",
                icon: "󰐥",
                badge: "POWER",
                execute: function() {
                    root.close();
                    Quickshell.execDetached(["systemctl", "poweroff"]);
                }
            });

            powerItems.push({
                id: "cmd_power_menu_widget",
                type: "command",
                name: "Open Bar Power Menu",
                subtitle: "Open the hold-to-confirm power menu bar widget",
                icon: "󰐥",
                badge: "BAR",
                execute: function() {
                    root.close();
                    MenuService.toggleRightMenuRequested("power", root.screen ? root.screen.name : "");
                }
            });

            if (q === "") return powerItems;
            return powerItems.filter(function(item) {
                return item.id === "cmd_back" || item.name.toLowerCase().indexOf(q) !== -1 || (item.subtitle && item.subtitle.toLowerCase().indexOf(q) !== -1) || item.id.toLowerCase().indexOf(q) !== -1;
            });
        }

        var list = [
            {
                id: "cmd_tasks_todo_tarefas",
                type: "command",
                name: "Open Tasks (TODO.md)",
                subtitle: "Open tasks & TODO.md markdown file in editor",
                icon: "󰄲",
                badge: "TASKS",
                execute: function() {
                    root.close();
                    TaskService.openTodoFile();
                }
            },
            {
                id: "cmd_power_menu_desligar",
                type: "command",
                stayOpen: true,
                name: "Power Menu",
                subtitle: "Session controls: Lock, Suspend, Hibernate, Reboot, Shutdown",
                icon: "󰐥",
                badge: "POWER",
                execute: function() {
                    root.commandSubMode = "power";
                    if (searchInput) searchInput.text = "> ";
                }
            },
            {
                id: "cmd_suspend",
                type: "command",
                name: "Suspend",
                subtitle: "Suspend system to RAM (sleep)",
                icon: "󰤄",
                badge: "POWER",
                execute: function() {
                    root.close();
                    Quickshell.execDetached(["systemctl", "suspend"]);
                }
            },
            {
                id: "cmd_hibernate",
                type: "command",
                name: "Hibernate",
                subtitle: "Save session state to disk and power off",
                icon: "󰒲",
                badge: "POWER",
                execute: function() {
                    root.close();
                    Quickshell.execDetached(["systemctl", "hibernate"]);
                }
            },
            {
                id: "cmd_logout",
                type: "command",
                name: "Log Out",
                subtitle: "Exit current desktop session and close Hyprland",
                icon: "󰍃",
                badge: "SESSION",
                execute: function() {
                    root.close();
                    Quickshell.execDetached(["killall", "Hyprland"]);
                }
            },
            {
                id: "cmd_reboot",
                type: "command",
                name: "Reboot",
                subtitle: "Restart the system",
                icon: "󰜉",
                badge: "POWER",
                execute: function() {
                    root.close();
                    Quickshell.execDetached(["systemctl", "reboot"]);
                }
            },
            {
                id: "cmd_shutdown",
                type: "command",
                name: "Shut Down",
                subtitle: "Power off the system completely",
                icon: "󰐥",
                badge: "POWER",
                execute: function() {
                    root.close();
                    Quickshell.execDetached(["systemctl", "poweroff"]);
                }
            },
            {
                id: "cmd_wallpaper",
                type: "command",
                stayOpen: true,
                name: "Wallpaper Picker",
                subtitle: "Browse wallpapers and generate dynamic palettes",
                icon: "󰸉",
                badge: "MEDIA",
                execute: function() {
                    root.currentView = "wallpaper";
                }
            },
            {
                id: "cmd_presets",
                type: "command",
                stayOpen: true,
                name: "Presets",
                subtitle: "Browse and apply appearance presets and themes",
                icon: "󰸌",
                badge: "RICE",
                execute: function() {
                    root.currentView = "presets";
                }
            },
            {
                id: "cmd_lock",
                type: "command",
                name: "Lock Screen",
                subtitle: "Lock current session immediately",
                icon: "󰌾",
                badge: "SECURITY",
                execute: function() {
                    root.close();
                    LockScreenService.lock();
                }
            },
            {
                id: "cmd_settings",
                type: "command",
                name: "Settings & Control Panel",
                subtitle: "Configure Asura shell, bar, wallpaper and widgets",
                icon: "󰒓",
                badge: "SYSTEM",
                execute: function() {
                    root.close();
                    MenuService.toggleControlPanelRequested(root.screen ? root.screen.name : "");
                }
            },
            {
                id: "cmd_shortcuts_keybinds_atalhos",
                type: "command",
                name: "Shortcuts & Keybinds",
                subtitle: "View keyboard shortcuts cheatsheet HUD overlay (atalhos)",
                icon: "󰌌",
                badge: "KEYBINDS",
                execute: function() {
                    root.close();
                    MenuService.openShortcutsOverlay(root.screen ? root.screen.name : "");
                }
            },
            {
                id: "cmd_dark",
                type: "command",
                name: "Dark Mode",
                subtitle: "Switch overall shell theme to dark mode",
                icon: "󰖔",
                badge: (cfg && cfg.isDarkMode) ? "ON" : "OFF",
                execute: function() {
                    if (Config.cfg) {
                        Config.cfg.isDarkMode = true;
                        Config.save();
                    }
                }
            },
            {
                id: "cmd_light",
                type: "command",
                name: "Light Mode",
                subtitle: "Switch overall shell theme to light mode",
                icon: "󰖙",
                badge: (cfg && !cfg.isDarkMode) ? "ON" : "OFF",
                execute: function() {
                    if (Config.cfg) {
                        Config.cfg.isDarkMode = false;
                        Config.save();
                    }
                }
            },
            {
                id: "cmd_palette",
                type: "command",
                stayOpen: true,
                name: "Palette",
                subtitle: "Browse and select color palettes",
                icon: "󰏘",
                badge: isDynamic ? "DYNAMIC" : (currentTheme ? currentTheme.toUpperCase() : "THEME"),
                execute: function() {
                    root.commandSubMode = "palette";
                    if (searchInput) searchInput.text = "> ";
                }
            },
            {
                id: "cmd_scheme",
                type: "command",
                stayOpen: true,
                name: "Scheme",
                subtitle: "Select Material You color scheme",
                icon: "󰸌",
                badge: isDynamic ? currentScheme.toUpperCase() : "SCHEME",
                execute: function() {
                    root.commandSubMode = "scheme";
                    if (searchInput) searchInput.text = "> ";
                }
            },
            {
                id: "cmd_terminal",
                type: "command",
                name: "Open Terminal",
                subtitle: "Launch default terminal emulator",
                icon: "",
                badge: "APPS",
                execute: function() {
                    root.close();
                    shellProcess.shellCommand = "kitty || alacritty || xterm &";
                    shellProcess.running = true;
                }
            },
            {
                id: "cmd_reload",
                type: "command",
                name: "Reload Asura Shell",
                subtitle: "Restart all Quickshell services and UI components",
                icon: "󰑓",
                badge: "SHELL",
                execute: function() {
                    Quickshell.reload(true);
                }
            }
        ];

        if (q === "") return list;
        return list.filter(function(item) {
            return item.name.toLowerCase().indexOf(q) !== -1 || (item.subtitle && item.subtitle.toLowerCase().indexOf(q) !== -1) || item.id.toLowerCase().indexOf(q) !== -1;
        });
    }

    readonly property var allApps: {
        var hiddenList = (Config.cfg && Config.cfg.launcherHiddenApps && Array.isArray(Config.cfg.launcherHiddenApps))
            ? Config.cfg.launcherHiddenApps
            : [];
        return DesktopEntries.applications.values.filter(function(e) {
            if (!e || !e.id)
                return false;
            var normId = e.id.replace(/\.desktop$/i, "");
            for (var i = 0; i < hiddenList.length; i++) {
                var normHidden = String(hiddenList[i] || "").replace(/\.desktop$/i, "");
                if (normHidden === normId)
                    return false;
            }
            return true;
        }).sort(function(a, b) {
            return a.name.localeCompare(b.name);
        });
    }

    readonly property var filteredResults: {
        var q = root.searchQuery.trim();
        var isShell = q.startsWith("!");
        var isCalc = q.startsWith("=");
        var isCmd = q.startsWith(">");
        var isWeb = q.startsWith("?");

        if (isShell) {
            var rawCmd = q.substring(1).trim();
            return [{
                id: "shell_exec",
                type: "shell",
                name: rawCmd !== "" ? rawCmd : "Type shell command...",
                subtitle: "Execute command and show terminal output",
                icon: "",
                badge: "RUN",
                stayOpen: true,
                execute: function() {
                    root.executeShellCommand(rawCmd);
                }
            }];
        }

        if (isWeb) {
            var rawWeb = q.substring(1).trim();
            return [{
                id: "web_search_exec",
                type: "web",
                name: rawWeb !== "" ? qsTr("Search Google for \"%1\"").arg(rawWeb) : qsTr("Type search query..."),
                subtitle: qsTr("Open search in default web browser"),
                icon: "󰖟",
                badge: "WEB",
                execute: function() {
                    if (rawWeb !== "") {
                        root.executeWebSearch(rawWeb);
                    }
                    root.close();
                }
            }];
        }

        if (isCalc) {
            var calculation = root.calculateExpression(q);
            return [{
                id: "calc_res",
                type: "calculator",
                name: calculation !== "" ? calculation : "= ...",
                subtitle: "Math expression: " + (q.substring(1).trim() || "..."),
                icon: "󰃬",
                badge: "COPY",
                execute: function() {
                    if (calculation && calculation !== "Erro" && typeof Quickshell.clipboardText !== "undefined") {
                        Quickshell.clipboardText = calculation;
                    }
                    root.close();
                }
            }];
        }

        if (isCmd || root.commandSubMode !== "") {
            var cmdQuery = isCmd ? q.substring(1).trim().toLowerCase() : q.toLowerCase();
            return root.getSystemCommands(cmdQuery);
        }

        if (q === "") {
            return [];
        }

        var qLower = q.toLowerCase();
        var matchingApps = root.allApps.filter(function(e) {
            if (e.name.toLowerCase().indexOf(qLower) !== -1) return true;
            if (e.genericName && e.genericName.toLowerCase().indexOf(qLower) !== -1) return true;
            if (e.comment && e.comment.toLowerCase().indexOf(qLower) !== -1) return true;
            if (e.keywords) {
                for (var i = 0; i < e.keywords.length; i++) {
                    if (e.keywords[i].toLowerCase().indexOf(qLower) !== -1) return true;
                }
            }
            return false;
        }).sort(function(a, b) {
            var aStart = a.name.toLowerCase().startsWith(qLower);
            var bStart = b.name.toLowerCase().startsWith(qLower);
            if (aStart && !bStart) return -1;
            if (!aStart && bStart) return 1;

            var recents = AppLauncherState.recentIds;
            var ai = recents.indexOf(a.id);
            var bi = recents.indexOf(b.id);
            if (ai !== -1 && bi !== -1) return ai - bi;
            if (ai !== -1) return -1;
            if (bi !== -1) return 1;

            return a.name.localeCompare(b.name);
        });

        var extras = [];
        if (Config.cfg && Config.cfg.launcherCalculatorNoPrefix) {
            var hasMathOp = /[+\-*\/%^]|(sqrt|sin|cos|tan|abs|ceil|floor|round|log|pi)\b/i.test(q);
            if (hasMathOp) {
                var calcVal = root.calculateExpression(q);
                if (calcVal !== "" && calcVal !== "Erro") {
                    extras.push({
                        id: "calc_inline",
                        type: "calculator",
                        name: calcVal,
                        subtitle: "Math expression: " + q,
                        icon: "󰃬",
                        badge: "COPY",
                        execute: function() {
                            if (typeof Quickshell.clipboardText !== "undefined") {
                                Quickshell.clipboardText = calcVal;
                            }
                            root.close();
                        }
                    });
                }
            }
        }

        if (Config.cfg && Config.cfg.launcherCommandsNoPrefix) {
            var cmds = root.getSystemCommands(q);
            extras = extras.concat(cmds);
        }

        var webExtras = [];
        if (Config.cfg && Config.cfg.launcherWebSearchNoPrefix && q !== "") {
            webExtras.push({
                id: "web_search_inline",
                type: "web",
                name: qsTr("Search web for \"%1\"").arg(q),
                subtitle: qsTr("Open search in default web browser"),
                icon: "󰖟",
                badge: "WEB",
                execute: function() {
                    root.executeWebSearch(q);
                    root.close();
                }
            });
        }

        return extras.concat(matchingApps).concat(webExtras);
    }

    readonly property var recentApps: {
        var recents = AppLauncherState.recentIds;
        var apps = root.allApps;
        var list = [];
        for (var i = 0; i < recents.length && list.length < 5; i++) {
            for (var j = 0; j < apps.length; j++) {
                if (apps[j].id === recents[i]) {
                    list.push(apps[j]);
                    break;
                }
            }
        }
        return list;
    }

    function executeWebSearch(query) {
        query = (query || "").trim();
        if (query === "") return;
        var searchUrl = "https://www.google.com/search?q=" + encodeURIComponent(query);
        Qt.openUrlExternally(searchUrl);
    }

    function executeItem(item) {
        if (!item) return;
        if (item.type === "shell") {
            item.execute();
            return;
        }
        if (item.execute) {
            item.execute();
            if (item.stayOpen) {
                root.selectedIndex = 0;
            } else {
                root.close();
            }
        } else if (item.id && typeof item.execute === "function") {
            item.execute();
            AppLauncherState.recordLaunch(item.id);
            if (item.stayOpen) {
                root.selectedIndex = 0;
            } else {
                root.close();
            }
        } else {
            AppLauncherState.recordLaunch(item.id);
            item.execute();
            root.close();
        }
    }

    NumberAnimation {
        id: gridScrollAnim
        target: gridFlickable
        property: "contentY"
        duration: 160
        easing.type: Easing.OutCubic
    }

    function ensureGridIndexVisible(idx, animated) {
        if (!gridFlickable || idx < 0) return;
        var total = root.allApps.length;
        if (total === 0) return;

        var row = Math.floor(idx / 6);
        var tileH = Math.round(76 * root.uiScale);
        var spacing = 6;
        var rowTop = row * (tileH + spacing);
        var rowBottom = rowTop + tileH;
        var viewH = gridFlickable.height > 0 ? gridFlickable.height : 340;
        var contentH = gridFlow ? gridFlow.implicitHeight : 0;
        var maxScroll = Math.max(0, contentH - viewH);

        var targetY = gridFlickable.contentY;
        if (rowTop < gridFlickable.contentY) {
            targetY = Math.max(0, rowTop);
        } else if (rowBottom > gridFlickable.contentY + viewH) {
            var neededY = rowBottom - viewH;
            targetY = maxScroll > 0 ? Math.min(maxScroll, neededY) : neededY;
        }

        if (targetY !== gridFlickable.contentY) {
            if (animated !== false) {
                gridScrollAnim.stop();
                gridScrollAnim.to = targetY;
                gridScrollAnim.restart();
            } else {
                gridScrollAnim.stop();
                gridFlickable.contentY = targetY;
            }
        }
    }

    function moveSelection(delta) {
        if (root.gridMode) {
            var total = root.allApps.length;
            if (total === 0) return;
            var next = root.selectedIndex + delta;
            root.selectedIndex = Math.max(0, Math.min(total - 1, next));
            root.ensureGridIndexVisible(root.selectedIndex);
        } else if (root.filteredResults.length > 0) {
            var count = root.filteredResults.length;
            root.selectedIndex = (root.selectedIndex + delta + count) % count;
            resultsListView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
        }
    }

    Rectangle {
        id: scrim
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.42)
        opacity: root.isOpen ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: (root.currentView === "wallpaper" || root.currentView === "presets") ? Math.round((parent.height - ((root.activeContent && root.activeContent.implicitHeight > 0) ? root.activeContent.implicitHeight : 395)) / 2) : Math.round(parent.height * 0.22)
        width: (root.currentView === "wallpaper" || root.currentView === "presets") ? Math.min(parent.width - 40, (root.activeContent && root.activeContent.implicitWidth > 0) ? root.activeContent.implicitWidth : 1050) : Math.min(parent.width - 40, Math.round(580 * root.uiScale))
        height: (root.currentView === "wallpaper" || root.currentView === "presets") ? Math.min(parent.height - 40, (root.activeContent && root.activeContent.implicitHeight > 0) ? root.activeContent.implicitHeight : 395) : (contentColumn.implicitHeight + 28)
        radius: Config.effectiveMenuRadius
        color: Qt.alpha(Colors.cfg.surfaceContainer, Config.effectiveGeneralOpacity)
        border.color: Qt.alpha(Colors.cfg.primary, 0.28)
        border.width: 1
        clip: true

        scale: root.isOpen ? 1.0 : 0.94
        opacity: root.isOpen ? 1.0 : 0.0

        Behavior on anchors.topMargin {
            NumberAnimation {
                duration: 380
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutBack
                easing.overshoot: 1.05
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: 380
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: 380
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        implicitHeight: height

        Column {
            id: contentColumn
            visible: root.currentView === "launcher"
            enabled: root.currentView === "launcher"
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 14
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12

            RowLayout {
                id: searchRow
                width: parent.width
                height: Math.round(44 * root.uiScale)
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: Math.round(32 * root.uiScale)
                    Layout.preferredHeight: Math.round(32 * root.uiScale)
                    radius: 8
                    color: Qt.alpha(Colors.cfg.primary, 0.15)
                    border.color: Qt.alpha(Colors.cfg.primary, 0.3)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "禅"
                        font.family: "Google Sans"
                        font.pixelSize: Math.round(16 * root.uiScale)
                        font.weight: Font.DemiBold
                        color: Colors.cfg.primary
                    }
                }

                TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    verticalAlignment: TextInput.AlignVCenter
                    background: null
                    padding: 0
                    color: Colors.cfg.text
                    font.family: "Google Sans"
                    font.pixelSize: Math.round(14 * root.uiScale)
                    placeholderText: root.gridMode ? qsTr("Type to search, or browse grid below...") : qsTr("Search apps, > commands, = calc, ? web, ! shell...")
                    placeholderTextColor: Qt.alpha(Colors.cfg.textSecondary, 0.6)
                    selectByMouse: true
                    selectionColor: Qt.alpha(Colors.cfg.primary, 0.35)
                    selectedTextColor: Colors.cfg.text

                    onTextChanged: {
                        root.searchQuery = text;
                        root.selectedIndex = 0;
                        if (text.length > 0) {
                            root.gridMode = false;
                            root.helpMode = false;
                            root.showingShellOutput = false;
                        }
                    }

                    Keys.onUpPressed: {
                        root.moveSelection(root.gridMode ? -6 : -1);
                    }
                    Keys.onDownPressed: {
                        root.moveSelection(root.gridMode ? 6 : 1);
                    }
                    Keys.onLeftPressed: {
                        if (root.gridMode) root.moveSelection(-1);
                    }
                    Keys.onRightPressed: {
                        if (root.gridMode) root.moveSelection(1);
                    }
                    Keys.onReturnPressed: {
                        if (root.gridMode) {
                            if (root.allApps.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.allApps.length) {
                                root.executeItem(root.allApps[root.selectedIndex]);
                            }
                        } else if (root.filteredResults.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.filteredResults.length) {
                            root.executeItem(root.filteredResults[root.selectedIndex]);
                        }
                    }
                    Keys.onEnterPressed: {
                        if (root.gridMode) {
                            if (root.allApps.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.allApps.length) {
                                root.executeItem(root.allApps[root.selectedIndex]);
                            }
                        } else if (root.filteredResults.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.filteredResults.length) {
                            root.executeItem(root.filteredResults[root.selectedIndex]);
                        }
                    }
                    Keys.onEscapePressed: {
                        if (root.showingShellOutput) {
                            root.showingShellOutput = false;
                        } else if (root.commandSubMode !== "") {
                            root.commandSubMode = "";
                        } else if (root.gridMode || root.helpMode) {
                            root.gridMode = false;
                            root.helpMode = false;
                        } else {
                            root.close();
                        }
                    }
                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_A && (event.modifiers & Qt.ControlModifier)) {
                            root.gridMode = !root.gridMode;
                            root.helpMode = false;
                            event.accepted = true;
                        } else if (event.key === Qt.Key_F1) {
                            root.helpMode = !root.helpMode;
                            root.gridMode = false;
                            event.accepted = true;
                        }
                    }
                }

                Rectangle {
                    visible: root.showingShellOutput || root.commandSubMode !== "" || root.searchQuery.startsWith(">") || root.searchQuery.startsWith("=") || root.searchQuery.startsWith("!") || root.searchQuery.startsWith("?") || root.gridMode
                    Layout.preferredHeight: 22
                    Layout.preferredWidth: modeText.implicitWidth + 14
                    radius: 6
                    color: Qt.alpha(Colors.cfg.primary, 0.16)
                    border.color: Qt.alpha(Colors.cfg.primary, 0.35)
                    border.width: 1

                    Text {
                        id: modeText
                        anchors.centerIn: parent
                        text: root.showingShellOutput ? "OUTPUT" : (root.commandSubMode !== "" ? root.commandSubMode.toUpperCase() : (root.gridMode ? "ALL APPS" : (root.searchQuery.startsWith(">") ? "CMD" : (root.searchQuery.startsWith("=") ? "CALC" : (root.searchQuery.startsWith("?") ? "WEB" : "SHELL")))))
                        font.family: "Google Sans"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: Colors.cfg.primary
                    }
                }

                Text {
                    visible: !root.showingShellOutput && (root.searchQuery.trim().length > 0 || root.commandSubMode !== "") && !root.gridMode
                    text: root.filteredResults.length + " / " + root.allApps.length
                    font.family: "Google Sans"
                    font.pixelSize: 11
                    color: Qt.alpha(Colors.cfg.textSecondary, 0.7)
                }

                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: 7
                    color: (helpArea.containsMouse || root.helpMode) ? Qt.alpha(Colors.cfg.primary, 0.2) : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "?"
                        font.family: "Google Sans"
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        color: (helpArea.containsMouse || root.helpMode) ? Colors.cfg.primary : Colors.cfg.textSecondary
                    }

                    MouseArea {
                        id: helpArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.helpMode = !root.helpMode;
                            root.gridMode = false;
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: 7
                    color: (gridArea.containsMouse || root.gridMode) ? Qt.alpha(Colors.cfg.primary, 0.2) : "transparent"

                    Grid {
                        anchors.centerIn: parent
                        columns: 3
                        rowSpacing: 2
                        columnSpacing: 2
                        Repeater {
                            model: 9
                            Rectangle {
                                width: 3
                                height: 3
                                radius: 1
                                color: (gridArea.containsMouse || root.gridMode) ? Colors.cfg.primary : Colors.cfg.textSecondary
                            }
                        }
                    }

                    MouseArea {
                        id: gridArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.gridMode = !root.gridMode;
                            root.helpMode = false;
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Qt.alpha(Colors.cfg.primary, 0.15)
            }

            Rectangle {
                id: shellOutputBox
                visible: root.showingShellOutput
                width: parent.width
                implicitHeight: Math.round(280 * root.uiScale)
                radius: 12
                color: Qt.alpha(Colors.cfg.surface, Math.min(1, Config.effectiveGeneralOpacity * 0.95))
                border.color: Qt.alpha(Colors.cfg.primary, 0.3)
                border.width: 1
                clip: true

                Flickable {
                    id: shellFlickable
                    anchors.fill: parent
                    anchors.margins: Math.round(14 * root.uiScale)
                    clip: true
                    contentWidth: width
                    contentHeight: shellOutputText.height
                    interactive: true
                    boundsBehavior: Flickable.StopAtBounds

                    Connections {
                        target: root
                        function onShellOutputChanged() {
                            Qt.callLater(function() {
                                if (shellFlickable.contentHeight > shellFlickable.height) {
                                    shellFlickable.contentY = shellFlickable.contentHeight - shellFlickable.height;
                                }
                            });
                        }
                    }

                    Text {
                        id: shellOutputText
                        width: parent.width
                        text: root.shellOutput
                        color: Colors.cfg.text
                        font.pixelSize: Math.round(12 * root.uiScale)
                        font.family: "GeistMono Nerd Font Propo"
                        wrapMode: Text.Wrap
                        textFormat: Text.PlainText
                    }
                }
            }

            Item {
                id: restContainer
                visible: !root.showingShellOutput && root.searchQuery.trim() === "" && !root.gridMode && !root.helpMode && root.commandSubMode === ""
                width: parent.width
                implicitHeight: visible ? (restCard.implicitHeight + quickChipsRow.implicitHeight + (recentsContainer.visible ? recentsContainer.implicitHeight + 12 : 0) + 12) : 0

                Column {
                    anchors.fill: parent
                    spacing: 12

                    Rectangle {
                        id: restCard
                        width: parent.width
                        implicitHeight: Math.round(110 * root.uiScale)
                        radius: 14
                        color: Qt.alpha(Colors.cfg.surface, Math.min(1, Config.effectiveGeneralOpacity * 0.9))
                        border.color: Qt.alpha(Colors.cfg.primary, 0.2)
                        border.width: 1
                        clip: true

                        Image {
                            anchors.fill: parent
                            visible: Config.wallpaperUrl !== ""
                            source: Config.wallpaperUrl
                            fillMode: Image.PreserveAspectCrop
                            opacity: 0.22
                            asynchronous: true
                            smooth: true
                        }

                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 14
                            height: 1
                            color: Qt.alpha("#ffffff", 0.12)
                        }

                        Canvas {
                            id: zenWave
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: Math.round(44 * root.uiScale)
                            property real phase: 0
                            property color waveColor: Colors.cfg.primary

                            readonly property real dayFraction: {
                                var d = root.currentTime;
                                return (d.getHours() * 3600 + d.getMinutes() * 60 + d.getSeconds()) / 86400;
                            }
                            readonly property bool isDayTime: {
                                var h = root.currentTime.getHours();
                                return h >= 6 && h < 19;
                            }

                            onPhaseChanged: requestPaint()
                            onWaveColorChanged: requestPaint()

                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                var w = width;
                                var h = height;
                                if (w <= 0 || h <= 0) return;

                                var base = h * 0.72;
                                var amp = 5.5;
                                var steps = 60;

                                function ridge(x) {
                                    var t = x / w;
                                    return base + amp * Math.sin(t * Math.PI * 3 + zenWave.phase)
                                        + amp * 0.35 * Math.sin(t * Math.PI * 6 - zenWave.phase * 0.7);
                                }

                                var nodeX = Math.max(12, Math.min(w - 12, w * zenWave.dayFraction));

                                ctx.beginPath();
                                ctx.moveTo(0, h);
                                for (var i = 0; i <= steps; i++) {
                                    var x = (nodeX * i) / steps;
                                    ctx.lineTo(x, ridge(x));
                                }
                                ctx.lineTo(nodeX, h);
                                ctx.closePath();

                                var gA = ctx.createLinearGradient(0, base - amp * 2, 0, h);
                                var r = Math.round(waveColor.r * 255);
                                var g = Math.round(waveColor.g * 255);
                                var b = Math.round(waveColor.b * 255);
                                gA.addColorStop(0, "rgba(" + r + "," + g + "," + b + ",0.0)");
                                gA.addColorStop(0.5, "rgba(" + r + "," + g + "," + b + ",0.18)");
                                gA.addColorStop(1, "rgba(" + r + "," + g + "," + b + ",0.38)");
                                ctx.fillStyle = gA;
                                ctx.fill();

                                ctx.beginPath();
                                ctx.moveTo(nodeX, h);
                                for (var j = 0; j <= steps; j++) {
                                    var rx = nodeX + ((w - nodeX) * j) / steps;
                                    ctx.lineTo(rx, ridge(rx));
                                }
                                ctx.lineTo(w, h);
                                ctx.closePath();

                                var gF = ctx.createLinearGradient(0, base - amp * 2, 0, h);
                                gF.addColorStop(0, "rgba(255,255,255,0.0)");
                                gF.addColorStop(1, "rgba(255,255,255,0.06)");
                                ctx.fillStyle = gF;
                                ctx.fill();

                                ctx.beginPath();
                                for (var k = 0; k <= steps; k++) {
                                    var sx = (nodeX * k) / steps;
                                    var sy = ridge(sx);
                                    if (k === 0) ctx.moveTo(sx, sy);
                                    else ctx.lineTo(sx, sy);
                                }
                                ctx.lineWidth = 2;
                                ctx.strokeStyle = "rgba(" + r + "," + g + "," + b + ",0.85)";
                                ctx.stroke();

                                ctx.beginPath();
                                for (var m = 0; m <= steps; m++) {
                                    var ex = nodeX + ((w - nodeX) * m) / steps;
                                    var ey = ridge(ex);
                                    if (m === 0) ctx.moveTo(ex, ey);
                                    else ctx.lineTo(ex, ey);
                                }
                                ctx.lineWidth = 1.5;
                                ctx.strokeStyle = "rgba(255,255,255,0.22)";
                                ctx.stroke();

                                var ny = ridge(nodeX);
                                var halo = ctx.createRadialGradient(nodeX, ny, 0, nodeX, ny, 16);
                                halo.addColorStop(0, "rgba(" + r + "," + g + "," + b + ",0.45)");
                                halo.addColorStop(1, "rgba(" + r + "," + g + "," + b + ",0.0)");
                                ctx.fillStyle = halo;
                                ctx.beginPath();
                                ctx.arc(nodeX, ny, 16, 0, 2 * Math.PI);
                                ctx.fill();

                                ctx.fillStyle = zenWave.isDayTime ? "rgba(255, 218, 68, 0.95)" : "rgba(" + r + "," + g + "," + b + ", 0.95)";
                                ctx.beginPath();
                                ctx.arc(nodeX, ny, 5.5, 0, 2 * Math.PI);
                                ctx.fill();

                                if (!zenWave.isDayTime) {
                                    ctx.fillStyle = "rgba(22, 22, 30, 0.95)";
                                    ctx.beginPath();
                                    ctx.arc(nodeX + 3.2, ny - 2.2, 5.5, 0, 2 * Math.PI);
                                    ctx.fill();
                                }
                            }
                        }

                        Timer {
                            interval: 40
                            running: root.isOpen && restContainer.visible
                            repeat: true
                            onTriggered: {
                                zenWave.phase += 0.035;
                            }
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 20
                            anchors.top: parent.top
                            anchors.topMargin: 16
                            spacing: 2

                            Text {
                                text: {
                                    var h = root.currentTime.getHours();
                                    return (h < 5 ? qsTr("GOOD NIGHT") : h < 12 ? qsTr("GOOD MORNING") : h < 18 ? qsTr("GOOD AFTERNOON") : qsTr("GOOD EVENING"));
                                }
                                font.family: "Google Sans"
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                font.letterSpacing: 1.5
                                color: Qt.alpha(Colors.cfg.textSecondary, 0.8)
                            }

                            Row {
                                spacing: 1

                                Text {
                                    text: Qt.formatTime(root.currentTime, "HH")
                                    font.family: "Google Sans"
                                    font.pixelSize: Math.round(36 * root.uiScale)
                                    font.weight: Font.Medium
                                    color: Colors.cfg.text
                                }

                                Text {
                                    text: ":"
                                    font.family: "Google Sans"
                                    font.pixelSize: Math.round(36 * root.uiScale)
                                    font.weight: Font.Medium
                                    color: Colors.cfg.primary

                                    SequentialAnimation on opacity {
                                        loops: Animation.Infinite
                                        running: root.isOpen
                                        NumberAnimation { from: 1.0; to: 0.25; duration: 650; easing.type: Easing.InOutSine }
                                        NumberAnimation { from: 0.25; to: 1.0; duration: 650; easing.type: Easing.InOutSine }
                                    }
                                }

                                Text {
                                    text: Qt.formatTime(root.currentTime, "mm")
                                    font.family: "Google Sans"
                                    font.pixelSize: Math.round(36 * root.uiScale)
                                    font.weight: Font.Medium
                                    color: Colors.cfg.text
                                }
                            }
                        }

                        Column {
                            anchors.right: parent.right
                            anchors.rightMargin: 20
                            anchors.top: parent.top
                            anchors.topMargin: 18
                            spacing: 4

                            Text {
                                anchors.right: parent.right
                                text: Qt.formatDate(root.currentTime, "dddd, MMM d")
                                font.family: "Google Sans"
                                font.pixelSize: Math.round(15 * root.uiScale)
                                font.weight: Font.Medium
                                color: Colors.cfg.text
                            }

                            Rectangle {
                                anchors.right: parent.right
                                width: zenBadgeText.implicitWidth + 14
                                height: 20
                                radius: 10
                                color: Qt.alpha(Colors.cfg.primary, 0.14)
                                border.color: Qt.alpha(Colors.cfg.primary, 0.3)
                                border.width: 1

                                Text {
                                    id: zenBadgeText
                                    anchors.centerIn: parent
                                    text: "ZEN · ASURA"
                                    font.family: "Google Sans"
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1
                                    color: Colors.cfg.primary
                                }
                            }
                        }
                    }

                    RowLayout {
                        id: quickChipsRow
                        width: parent.width
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.round(34 * root.uiScale)
                            radius: 10
                            color: chipSettingsMouse.containsMouse ? Qt.alpha(Colors.cfg.primary, 0.18) : Colors.cfg.surface
                            border.color: Qt.alpha(Colors.cfg.primary, chipSettingsMouse.containsMouse ? 0.4 : 0.15)
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    text: "󰒓"
                                    font.pixelSize: 13
                                    color: chipSettingsMouse.containsMouse ? Colors.cfg.primary : Colors.cfg.textSecondary
                                }
                                Text {
                                    text: qsTr("Settings")
                                    font.family: "Google Sans"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: chipSettingsMouse.containsMouse ? Colors.cfg.text : Colors.cfg.textSecondary
                                }
                            }

                            MouseArea {
                                id: chipSettingsMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.close();
                                    MenuService.toggleControlPanelRequested(root.screen ? root.screen.name : "");
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.round(34 * root.uiScale)
                            radius: 10
                            color: chipWallMouse.containsMouse ? Qt.alpha(Colors.cfg.primary, 0.18) : Colors.cfg.surface
                            border.color: Qt.alpha(Colors.cfg.primary, chipWallMouse.containsMouse ? 0.4 : 0.15)
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    text: "󰸉"
                                    font.pixelSize: 13
                                    color: chipWallMouse.containsMouse ? Colors.cfg.primary : Colors.cfg.textSecondary
                                }
                                Text {
                                    text: qsTr("Wallpaper")
                                    font.family: "Google Sans"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: chipWallMouse.containsMouse ? Colors.cfg.text : Colors.cfg.textSecondary
                                }
                            }

                            MouseArea {
                                id: chipWallMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.close();
                                    MenuService.toggleWallpaperRequested(root.screen ? root.screen.name : "");
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.round(34 * root.uiScale)
                            radius: 10
                            color: chipThemeMouse.containsMouse ? Qt.alpha(Colors.cfg.primary, 0.18) : Colors.cfg.surface
                            border.color: Qt.alpha(Colors.cfg.primary, chipThemeMouse.containsMouse ? 0.4 : 0.15)
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    text: (Config.cfg && Config.cfg.isDarkMode) ? "󰖙" : "󰖔"
                                    font.pixelSize: 13
                                    color: chipThemeMouse.containsMouse ? Colors.cfg.primary : Colors.cfg.textSecondary
                                }
                                Text {
                                    text: (Config.cfg && Config.cfg.isDarkMode) ? qsTr("Light") : qsTr("Dark")
                                    font.family: "Google Sans"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: chipThemeMouse.containsMouse ? Colors.cfg.text : Colors.cfg.textSecondary
                                }
                            }

                            MouseArea {
                                id: chipThemeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (Config.cfg) {
                                        Config.cfg.isDarkMode = !Config.cfg.isDarkMode;
                                        Config.save();
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.round(34 * root.uiScale)
                            radius: 10
                            color: chipTermMouse.containsMouse ? Qt.alpha(Colors.cfg.primary, 0.18) : Colors.cfg.surface
                            border.color: Qt.alpha(Colors.cfg.primary, chipTermMouse.containsMouse ? 0.4 : 0.15)
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    text: ""
                                    font.pixelSize: 13
                                    color: chipTermMouse.containsMouse ? Colors.cfg.primary : Colors.cfg.textSecondary
                                }
                                Text {
                                    text: qsTr("Terminal")
                                    font.family: "Google Sans"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: chipTermMouse.containsMouse ? Colors.cfg.text : Colors.cfg.textSecondary
                                }
                            }

                            MouseArea {
                                id: chipTermMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.close();
                                    shellProcess.shellCommand = "kitty || alacritty || xterm &";
                                    shellProcess.running = true;
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.round(34 * root.uiScale)
                            radius: 10
                            color: chipLockMouse.containsMouse ? Qt.alpha(Colors.cfg.primary, 0.18) : Colors.cfg.surface
                            border.color: Qt.alpha(Colors.cfg.primary, chipLockMouse.containsMouse ? 0.4 : 0.15)
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    text: "󰌾"
                                    font.pixelSize: 13
                                    color: chipLockMouse.containsMouse ? Colors.cfg.primary : Colors.cfg.textSecondary
                                }
                                Text {
                                    text: qsTr("Lock")
                                    font.family: "Google Sans"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: chipLockMouse.containsMouse ? Colors.cfg.text : Colors.cfg.textSecondary
                                }
                            }

                            MouseArea {
                                id: chipLockMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.close();
                                    LockScreenService.lock();
                                }
                            }
                        }
                    }

                    Column {
                        id: recentsContainer
                        visible: root.recentApps.length > 0
                        width: parent.width
                        spacing: 8

                        Text {
                            text: qsTr("RECENT APPLICATIONS")
                            font.family: "Google Sans"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            font.letterSpacing: 1.2
                            color: Qt.alpha(Colors.cfg.textSecondary, 0.7)
                        }

                        RowLayout {
                            width: parent.width
                            spacing: 8

                            Repeater {
                                model: root.recentApps

                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: Math.round(44 * root.uiScale)
                                    radius: 10
                                    color: recentMouse.containsMouse ? Qt.alpha(Colors.cfg.primary, 0.16) : Colors.cfg.surface
                                    border.color: Qt.alpha(Colors.cfg.primary, recentMouse.containsMouse ? 0.35 : 0.12)
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        spacing: 8

                                        Image {
                                            id: recIcon
                                            Layout.preferredWidth: Math.round(24 * root.uiScale)
                                            Layout.preferredHeight: Math.round(24 * root.uiScale)
                                            source: modelData.icon ? ("image://icon/" + modelData.icon) : ""
                                            smooth: true
                                            mipmap: true
                                        }

                                        Text {
                                            visible: recIcon.status !== Image.Ready
                                            text: modelData.name ? modelData.name.charAt(0).toUpperCase() : "?"
                                            font.family: "Google Sans"
                                            font.pixelSize: 14
                                            font.bold: true
                                            color: Colors.cfg.primary
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.name || ""
                                            font.family: "Google Sans"
                                            font.pixelSize: Math.round(11 * root.uiScale)
                                            font.weight: Font.Medium
                                            elide: Text.ElideRight
                                            color: recentMouse.containsMouse ? Colors.cfg.primary : Colors.cfg.text
                                        }
                                    }

                                    MouseArea {
                                        id: recentMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.executeItem(modelData);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            ListView {
                id: resultsListView
                visible: !root.showingShellOutput && (root.searchQuery.trim() !== "" || root.commandSubMode !== "") && !root.gridMode && !root.helpMode
                width: parent.width
                implicitHeight: Math.min(count, 7) * Math.round(48 * root.uiScale)
                clip: true
                spacing: 3
                model: root.filteredResults
                currentIndex: root.selectedIndex

                delegate: Rectangle {
                    id: resultRow
                    required property int index
                    required property var modelData

                    readonly property bool isSelected: index === root.selectedIndex

                    width: resultsListView.width
                    height: Math.round(44 * root.uiScale)
                    radius: 10
                    color: isSelected ? Qt.alpha(Colors.cfg.primary, 0.18) : (rowArea.containsMouse ? Qt.alpha(Colors.cfg.primary, 0.08) : "transparent")
                    border.color: isSelected ? Qt.alpha(Colors.cfg.primary, 0.4) : "transparent"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 12
                        spacing: 12

                        Item {
                            Layout.preferredWidth: Math.round(28 * root.uiScale)
                            Layout.preferredHeight: Math.round(28 * root.uiScale)

                            Rectangle {
                                anchors.fill: parent
                                visible: !!modelData.paletteData
                                radius: 8
                                color: modelData.paletteData ? (modelData.paletteData.bg || "#1e1e2e") : "transparent"
                                border.color: modelData.paletteData ? (modelData.paletteData.color || "#89b4fa") : "transparent"
                                border.width: 1.5

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 2
                                    Repeater {
                                        model: modelData.paletteData ? (modelData.paletteData.swatches || []) : []
                                        delegate: Rectangle {
                                            required property var modelData
                                            width: 5
                                            height: 5
                                            radius: 2.5
                                            color: modelData || "transparent"
                                        }
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: !modelData.paletteData && (modelData.type === "command" || modelData.type === "calculator" || modelData.type === "shell" || modelData.type === "web")
                                text: modelData.icon || ""
                                font.pixelSize: Math.round(18 * root.uiScale)
                                color: resultRow.isSelected ? Colors.cfg.primary : Colors.cfg.textSecondary
                            }

                            Image {
                                id: rowAppIcon
                                anchors.centerIn: parent
                                visible: !modelData.paletteData && modelData.type !== "command" && modelData.type !== "calculator" && modelData.type !== "shell" && modelData.type !== "web"
                                width: Math.round(26 * root.uiScale)
                                height: Math.round(26 * root.uiScale)
                                source: (modelData.icon && modelData.type !== "command" && modelData.type !== "calculator" && modelData.type !== "shell" && modelData.type !== "web") ? ("image://icon/" + modelData.icon) : ""
                                smooth: true
                                mipmap: true
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: rowAppIcon.visible && rowAppIcon.status !== Image.Ready
                                text: modelData.name ? modelData.name.charAt(0).toUpperCase() : "?"
                                font.family: "Google Sans"
                                font.pixelSize: 15
                                font.bold: true
                                color: Colors.cfg.primary
                            }
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: modelData.name || ""
                                font.family: "Google Sans"
                                font.pixelSize: Math.round(13 * root.uiScale)
                                font.weight: resultRow.isSelected ? Font.Medium : Font.Normal
                                color: resultRow.isSelected ? Colors.cfg.primary : Colors.cfg.text
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: modelData.subtitle || modelData.genericName || modelData.comment || ""
                                font.family: "Google Sans"
                                font.pixelSize: Math.round(10.5 * root.uiScale)
                                color: Qt.alpha(Colors.cfg.textSecondary, 0.75)
                                elide: Text.ElideRight
                                width: parent.width
                                visible: text.length > 0
                            }
                        }

                        Rectangle {
                            visible: !!modelData.badge || modelData.type === "calculator" || modelData.type === "shell"
                            Layout.preferredHeight: 20
                            Layout.preferredWidth: actionLabel.implicitWidth + 12
                            radius: 6
                            color: resultRow.isSelected ? Qt.alpha(Colors.cfg.primary, 0.25) : Qt.alpha(Colors.cfg.textSecondary, 0.12)

                            Text {
                                id: actionLabel
                                anchors.centerIn: parent
                                text: modelData.badge ? modelData.badge : (modelData.type === "calculator" ? "COPY" : (modelData.type === "shell" ? "RUN" : "LAUNCH"))
                                font.family: "Google Sans"
                                font.pixelSize: 9
                                font.weight: Font.Bold
                                font.letterSpacing: 0.8
                                color: resultRow.isSelected ? Colors.cfg.primary : Qt.alpha(Colors.cfg.textSecondary, 0.8)
                            }
                        }
                    }

                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: {
                            root.selectedIndex = index;
                        }
                        onClicked: {
                            root.executeItem(modelData);
                        }
                    }
                }
            }

            Item {
                visible: !root.showingShellOutput && (root.searchQuery.trim() !== "" || root.commandSubMode !== "") && root.filteredResults.length === 0 && !root.gridMode && !root.helpMode
                width: parent.width
                height: 70

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰍉"
                        font.pixelSize: 18
                        color: Colors.cfg.textSecondary
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("No matching applications or commands")
                        font.family: "Google Sans"
                        font.pixelSize: 13
                        color: Colors.cfg.textSecondary
                    }
                }
            }

            Flickable {
                id: gridFlickable
                visible: !root.showingShellOutput && root.gridMode
                width: parent.width
                height: 340
                implicitHeight: 340
                clip: true
                contentWidth: width
                contentHeight: gridFlow.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Flow {
                    id: gridFlow
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: root.allApps

                        delegate: Rectangle {
                            id: gridTile
                            required property int index
                            required property var modelData

                            readonly property bool isSelected: index === root.selectedIndex

                            width: Math.floor((gridFlow.width - 30) / 6)
                            height: Math.round(76 * root.uiScale)
                            radius: 12
                            color: isSelected ? Qt.alpha(Colors.cfg.primary, 0.2) : (tileArea.containsMouse ? Qt.alpha(Colors.cfg.primary, 0.1) : Colors.cfg.surface)
                            border.color: isSelected ? Colors.cfg.primary : Qt.alpha(Colors.cfg.primary, 0.12)
                            border.width: isSelected ? 1.5 : 1

                            Column {
                                anchors.centerIn: parent
                                spacing: 4
                                width: parent.width - 8

                                Image {
                                    id: tileAppIcon
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: Math.round(30 * root.uiScale)
                                    height: Math.round(30 * root.uiScale)
                                    source: modelData.icon ? ("image://icon/" + modelData.icon) : ""
                                    smooth: true
                                    mipmap: true
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    visible: tileAppIcon.status !== Image.Ready
                                    text: modelData.name ? modelData.name.charAt(0).toUpperCase() : "?"
                                    font.family: "Google Sans"
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: Colors.cfg.primary
                                }

                                Text {
                                    width: parent.width
                                    text: modelData.name || ""
                                    font.family: "Google Sans"
                                    font.pixelSize: 10
                                    font.weight: gridTile.isSelected ? Font.Medium : Font.Normal
                                    color: gridTile.isSelected ? Colors.cfg.primary : Colors.cfg.text
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }
                            }

                            MouseArea {
                                id: tileArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.executeItem(modelData);
                                }
                            }
                        }
                    }
                }
            }

            Column {
                id: helpContainer
                visible: !root.showingShellOutput && root.helpMode
                width: parent.width
                spacing: 8

                Text {
                    text: qsTr("ZEN COMMAND PALETTE SHORTCUTS")
                    font.family: "Google Sans"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.letterSpacing: 1.2
                    color: Colors.cfg.primary
                }

                GridLayout {
                    width: parent.width
                    columns: 2
                    rowSpacing: 6
                    columnSpacing: 12

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: 8
                        color: Colors.cfg.surface
                        border.color: Qt.alpha(Colors.cfg.primary, 0.15)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            Text { text: ">"; font.family: "monospace"; font.bold: true; color: Colors.cfg.primary }
                            Text { text: qsTr("System Commands & Settings"); font.family: "Google Sans"; font.pixelSize: 11; color: Colors.cfg.text }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: 8
                        color: Colors.cfg.surface
                        border.color: Qt.alpha(Colors.cfg.primary, 0.15)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            Text { text: "="; font.family: "monospace"; font.bold: true; color: Colors.cfg.primary }
                            Text { text: qsTr("Math Calculator (e.g. = 24 * 6)"); font.family: "Google Sans"; font.pixelSize: 11; color: Colors.cfg.text }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: 8
                        color: Colors.cfg.surface
                        border.color: Qt.alpha(Colors.cfg.primary, 0.15)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            Text { text: "!"; font.family: "monospace"; font.bold: true; color: Colors.cfg.primary }
                            Text { text: qsTr("Run Shell Command"); font.family: "Google Sans"; font.pixelSize: 11; color: Colors.cfg.text }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: 8
                        color: Colors.cfg.surface
                        border.color: Qt.alpha(Colors.cfg.primary, 0.15)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            Text { text: "?"; font.family: "monospace"; font.bold: true; color: Colors.cfg.primary }
                            Text { text: qsTr("Web Search in Browser"); font.family: "Google Sans"; font.pixelSize: 11; color: Colors.cfg.text }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: 8
                        color: Colors.cfg.surface
                        border.color: Qt.alpha(Colors.cfg.primary, 0.15)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            Text { text: "Ctrl+A"; font.family: "monospace"; font.bold: true; color: Colors.cfg.primary }
                            Text { text: qsTr("Browse All Apps Grid"); font.family: "Google Sans"; font.pixelSize: 11; color: Colors.cfg.text }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: 8
                        color: Colors.cfg.surface
                        border.color: Qt.alpha(Colors.cfg.primary, 0.15)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            Text { text: "↑ / ↓"; font.family: "monospace"; font.bold: true; color: Colors.cfg.primary }
                            Text { text: qsTr("Navigate Results or Grid"); font.family: "Google Sans"; font.pixelSize: 11; color: Colors.cfg.text }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: 8
                        color: Colors.cfg.surface
                        border.color: Qt.alpha(Colors.cfg.primary, 0.15)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            Text { text: "Esc"; font.family: "monospace"; font.bold: true; color: Colors.cfg.primary }
                            Text { text: qsTr("Close Zen Launcher"); font.family: "Google Sans"; font.pixelSize: 11; color: Colors.cfg.text }
                        }
                    }
                }
            }
        }

        Loader {
            id: wallpaperLoader
            anchors.fill: parent
            active: root.isOpen && root.currentView === "wallpaper"
            visible: active
            onLoaded: {
                if (item)
                    item.forceActiveFocus();
            }
            sourceComponent: Component {
                WallpaperSelector {
                }
            }
        }

        Loader {
            id: presetLoader
            anchors.fill: parent
            active: root.isOpen && root.currentView === "presets"
            visible: active
            onLoaded: {
                if (item) {
                    item.forceActiveFocus();
                    if (typeof item.focusSearchInput === "function")
                        item.focusSearchInput();
                }
            }
            sourceComponent: Component {
                PresetSelector {
                }
            }
        }
    }
}
