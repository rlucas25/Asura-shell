import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Animations
import qs.Asura
import qs.Services

Item {
    id: root

    property bool isOpen: false
    property real uiScale: 1.1
    property real introItems: 0
    readonly property real charSlotWidth: charMetrics.width > 0 ? charMetrics.width : 11.4 * uiScale
    property real scrollOffset: 0
    property string searchQuery: ""
    property int selectedIndex: 0
    property string shellOutput: ""
    property bool showingShellOutput: false
    property string commandSubMode: ""
    property bool gridMode: false
    readonly property int gridCols: Math.max(3, Math.floor((panelW - Math.round(24 * uiScale)) / Math.round(92 * uiScale)))

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
            return (a.name || "").localeCompare(b.name || "");
        });
    }

    readonly property string trimmedQuery: searchQuery.trim()
    readonly property bool isSearching: trimmedQuery !== ""
    readonly property bool isCommandMode: trimmedQuery.startsWith(">")
    readonly property bool isCalculatorMode: trimmedQuery.startsWith("=")
    readonly property bool isShellMode: trimmedQuery.startsWith("!")
    readonly property bool isWebSearchMode: trimmedQuery.startsWith("?")

    IpcHandler {
        target: "applauncher"
        function search(query: string) {
            root.searchQuery = query;
            searchInput.text = query;
        }
    }
    function getBaseCommands() {
        var cfg = Config.cfg;
        var isDynamic = cfg ? cfg.colorsAutoGenerate : false;
        var currentScheme = cfg ? cfg.scheme : "";
        var currentTheme = cfg ? cfg.theme : "";
        var menus = [];
        menus.push({
            "isCommand": true,
            "customIcon": true,
            "id": "cmd_wallpaper",
            "name": "Wallpaper",
            "icon": "󰸉",
            "badge": "",
            "execute": function() {
                root.requestWallpaper();
            }
        });
        menus.push({
            "isCommand": true,
            "customIcon": true,
            "id": "cmd_presets",
            "name": "Presets",
            "icon": "󰸌",
            "badge": "",
            "execute": function() {
                root.requestPresets();
            }
        });
        menus.push({
            "isCommand": true,
            "customIcon": true,
            "id": "cmd_lock",
            "name": "Lock Screen",
            "icon": "󰌾",
            "badge": "",
            "execute": function() {
                root.hideLauncher();
                LockScreenService.lock();
            }
        });
        menus.push({
            "isCommand": true,
            "customIcon": true,
            "id": "cmd_config",
            "name": "Settings",
            "icon": "󰒓",
            "badge": "",
            "execute": function() {
                root.hideLauncher();
                root.requestOpenMenu("controlpanel", "system");
            }
        });
        menus.push({
            "isCommand": true,
            "customIcon": true,
            "id": "cmd_shortcuts_keybinds_atalhos",
            "name": "Shortcuts & Keybinds",
            "icon": "󰌌",
            "badge": "OSD",
            "execute": function() {
                root.hideLauncher();
                MenuService.openShortcutsOverlay(root.focusedMonitorName);
            }
        });
        menus.push({
            "isCommand": true,
            "customIcon": true,
            "id": "cmd_dark",
            "name": "Dark Mode",
            "icon": "󰖔",
            "badge": cfg && cfg.isDarkMode ? "on" : "off",
            "execute": function() {
                if (Config.cfg) {
                    Config.cfg.isDarkMode = true;
                    Config.save();
                }
            }
        });
        menus.push({
            "isCommand": true,
            "customIcon": true,
            "id": "cmd_light",
            "name": "Light Mode",
            "icon": "󰖙",
            "badge": cfg && !cfg.isDarkMode ? "on" : "off",
            "execute": function() {
                if (Config.cfg) {
                    Config.cfg.isDarkMode = false;
                    Config.save();
                }
            }
        });
        menus.push({
            "isCommand": true,
            "customIcon": true,
            "stayOpen": true,
            "id": "cmd_palette",
            "name": "Palette",
            "icon": "󰏘",
            "badge": isDynamic ? "dynamic" : currentTheme,
            "execute": function() {
                root.commandSubMode = "palette";
            }
        });
        menus.push({
            "isCommand": true,
            "customIcon": true,
            "stayOpen": true,
            "id": "cmd_scheme",
            "name": "Scheme",
            "icon": "󰸌",
            "badge": isDynamic ? currentScheme : "",
            "execute": function() {
                root.commandSubMode = "scheme";
            }
        });
        menus.push({
            "isCommand": true,
            "customIcon": true,
            "id": "cmd_tasks_todo_tarefas",
            "name": "Open Tasks (TODO.md)",
            "icon": "󰄲",
            "badge": "TASKS",
            "execute": function() {
                root.hideLauncher();
                TaskService.openTodoFile();
            }
        });
        menus.push({
            "isCommand": true,
            "customIcon": true,
            "stayOpen": true,
            "id": "cmd_power_menu_desligar",
            "name": "Power Menu",
            "icon": "󰐥",
            "badge": "POWER",
            "execute": function() {
                root.commandSubMode = "power";
            }
        });
        menus.push({
            "isCommand": true,
            "customIcon": true,
            "id": "cmd_suspend",
            "name": "Suspend",
            "icon": "󰤄",
            "badge": "POWER",
            "execute": function() {
                root.hideLauncher();
                Quickshell.execDetached(["systemctl", "suspend"]);
            }
        });
        menus.push({
            "isCommand": true,
            "customIcon": true,
            "id": "cmd_hibernate",
            "name": "Hibernate",
            "icon": "󰒲",
            "badge": "POWER",
            "execute": function() {
                root.hideLauncher();
                Quickshell.execDetached(["systemctl", "hibernate"]);
            }
        });
        menus.push({
            "isCommand": true,
            "customIcon": true,
            "id": "cmd_logout",
            "name": "Log Out",
            "icon": "󰍃",
            "badge": "SESSION",
            "execute": function() {
                root.hideLauncher();
                Quickshell.execDetached(["killall", "Hyprland"]);
            }
        });
        menus.push({
            "isCommand": true,
            "customIcon": true,
            "id": "cmd_reboot",
            "name": "Reboot",
            "icon": "󰜉",
            "badge": "POWER",
            "execute": function() {
                root.hideLauncher();
                Quickshell.execDetached(["systemctl", "reboot"]);
            }
        });
        menus.push({
            "isCommand": true,
            "customIcon": true,
            "id": "cmd_shutdown",
            "name": "Shut Down",
            "icon": "󰐥",
            "badge": "POWER",
            "execute": function() {
                root.hideLauncher();
                Quickshell.execDetached(["systemctl", "poweroff"]);
            }
        });
        menus.push({
            "isCommand": true,
            "customIcon": true,
            "id": "cmd_reload",
            "name": "Reload Asura",
            "icon": "󰑓",
            "badge": "",
            "execute": function() {
                Quickshell.reload(true);
            }
        });
        return menus;
    }

    readonly property var filteredApps: {
        var q = searchQuery.trim();
        if (isShellMode) {
            var shellCommand = q.substring(1).trim();
            return [{
                "isShell": true,
                "isCommand": false,
                "isCalculator": false,
                "customIcon": true,
                "id": "shell_command",
                "name": shellCommand !== "" ? shellCommand : "Digite um comando...",
                "icon": "",
                "execute": function() {
                    root.executeShellCommand(shellCommand);
                }
            }];
        }
        if (isWebSearchMode) {
            var webQuery = q.substring(1).trim();
            return [{
                "isWebSearch": true,
                "customIcon": true,
                "isCommand": false,
                "isCalculator": false,
                "id": "web_search",
                "name": webQuery !== "" ? qsTr("Search web for \"%1\"").arg(webQuery) : qsTr("Type to search the web..."),
                "expression": webQuery,
                "badge": "WEB",
                "icon": "󰖟",
                "execute": function() {
                    if (webQuery !== "") {
                        root.executeWebSearch(webQuery);
                    }
                }
            }];
        }
        if (isCalculatorMode) {
            var calculation = root.calculateExpression(q);
            return [{
                "isCalculator": true,
                "customIcon": true,
                "isCommand": false,
                "id": "calculator_result",
                "name": calculation,
                "expression": q.substring(1).trim(),
                "badge": q.substring(1).trim(),
                "icon": "󰃬",
                "execute": function() {
                    if (calculation && calculation !== "Erro" && typeof Quickshell.clipboardText !== "undefined") {
                        Quickshell.clipboardText = calculation;
                    }
                }
            }];
        }
        if (isCommandMode || root.commandSubMode === "palette" || root.commandSubMode === "scheme" || root.commandSubMode === "power") {
            var cmdQuery = isCommandMode ? q.substring(1).trim().toLowerCase() : q.toLowerCase();
            var schemes = ["tonal-spot", "content", "expressive", "fidelity", "fruit-salad", "monochrome", "neutral", "rainbow", "vibrant"];
            var cfg = Config.cfg;
            var pinnedList = (Colors.pinnedPalettes && Array.isArray(Colors.pinnedPalettes)) ? Colors.pinnedPalettes : [];
            var isDynamic = cfg ? cfg.colorsAutoGenerate : false;
            var currentScheme = cfg ? cfg.scheme : "";
            var currentTheme = cfg ? cfg.theme : "";
            var allPals = Colors.allPalettes || {
            };
            var backItem = {
                "isCommand": true,
                "customIcon": true,
                "stayOpen": true,
                "id": "cmd_back",
                "name": "Back",
                "icon": "󰁍",
                "badge": "",
                "execute": function() {
                    root.commandSubMode = "";
                }
            };
            if (root.commandSubMode === "palette") {
                var palItems = [backItem];
                palItems.push({
                    "isCommand": true,
                    "customIcon": true,
                    "stayOpen": true,
                    "id": "cmd_palette_dynamic",
                    "name": "Dynamic Palette",
                    "icon": "󰏘",
                    "badge": isDynamic ? "on" : "off",
                    "execute": function() {
                        if (!Config.cfg)
                            return ;

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
                        var pal = allPals[pid] || {
                        };
                        var palColor = pal.base0D || pal.base08 || "#89b4fa";
                        var palBg = pal.base00 || "#1e1e2e";
                        var palColors = [pal.base08, pal.base0B, pal.base0D, pal.base0E].filter(Boolean);
                        var isActive = !isDynamic && currentTheme === pid;
                        palItems.push({
                            "isCommand": true,
                            "customIcon": false,
                            "id": "cmd_palette_" + pid,
                            "name": pid.charAt(0).toUpperCase() + pid.slice(1).replace(/-/g, " "),
                            "icon": "",
                            "badge": isActive ? "active" : "",
                            "paletteData": {
                                "color": palColor,
                                "bg": palBg,
                                "swatches": palColors
                            },
                            "execute": function() {
                                if (!Config.cfg)
                                    return ;

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
                if (cmdQuery === "")
                    return palItems;

                return palItems.filter(function(c) {
                    return (c.id === "cmd_back" || c.name.toLowerCase().indexOf(cmdQuery) !== -1);
                });
            }
            if (root.commandSubMode === "scheme") {
                var schItems = [backItem];
                for (var si = 0; si < schemes.length; si++) {
                    (function(sc) {
                        var isActive = isDynamic && currentScheme === sc;
                        schItems.push({
                            "isCommand": true,
                            "customIcon": true,
                            "id": "cmd_scheme_" + sc,
                            "name": sc.charAt(0).toUpperCase() + sc.slice(1).replace(/-/g, " "),
                            "icon": "󰸌",
                            "badge": isActive ? "active" : "",
                            "execute": function() {
                                if (Config.cfg) {
                                    Config.cfg.scheme = sc;
                                    Config.cfg.colorsAutoGenerate = true;
                                    Config.save();
                                }
                            }
                        });
                    })(schemes[si]);
                }
                if (cmdQuery === "")
                    return schItems;

                return schItems.filter(function(c) {
                    return (c.id === "cmd_back" || c.name.toLowerCase().indexOf(cmdQuery) !== -1);
                });
            }
            if (root.commandSubMode === "power") {
                var powerItems = [backItem];
                powerItems.push({
                    "isCommand": true,
                    "customIcon": true,
                    "id": "cmd_power_lock",
                    "name": "Lock",
                    "icon": "󰌾",
                    "badge": "SECURITY",
                    "execute": function() {
                        root.hideLauncher();
                        LockScreenService.lock();
                    }
                });
                powerItems.push({
                    "isCommand": true,
                    "customIcon": true,
                    "id": "cmd_power_suspend",
                    "name": "Suspend",
                    "icon": "󰤄",
                    "badge": "POWER",
                    "execute": function() {
                        root.hideLauncher();
                        Quickshell.execDetached(["systemctl", "suspend"]);
                    }
                });
                powerItems.push({
                    "isCommand": true,
                    "customIcon": true,
                    "id": "cmd_power_hibernate",
                    "name": "Hibernate",
                    "icon": "󰒲",
                    "badge": "POWER",
                    "execute": function() {
                        root.hideLauncher();
                        Quickshell.execDetached(["systemctl", "hibernate"]);
                    }
                });
                powerItems.push({
                    "isCommand": true,
                    "customIcon": true,
                    "id": "cmd_power_logout",
                    "name": "Log Out",
                    "icon": "󰍃",
                    "badge": "SESSION",
                    "execute": function() {
                        root.hideLauncher();
                        Quickshell.execDetached(["killall", "Hyprland"]);
                    }
                });
                powerItems.push({
                    "isCommand": true,
                    "customIcon": true,
                    "id": "cmd_power_reboot",
                    "name": "Reboot",
                    "icon": "󰜉",
                    "badge": "POWER",
                    "execute": function() {
                        root.hideLauncher();
                        Quickshell.execDetached(["systemctl", "reboot"]);
                    }
                });
                powerItems.push({
                    "isCommand": true,
                    "customIcon": true,
                    "id": "cmd_power_shutdown",
                    "name": "Shut Down",
                    "icon": "󰐥",
                    "badge": "POWER",
                    "execute": function() {
                        root.hideLauncher();
                        Quickshell.execDetached(["systemctl", "poweroff"]);
                    }
                });
                powerItems.push({
                    "isCommand": true,
                    "customIcon": true,
                    "id": "cmd_power_menu_widget",
                    "name": "Open Bar Power Menu",
                    "icon": "󰐥",
                    "badge": "BAR",
                    "execute": function() {
                        root.hideLauncher();
                        MenuService.toggleRightMenuRequested("power", MenuService.getFocusedMonitorName());
                    }
                });
                if (cmdQuery === "")
                    return powerItems;

                return powerItems.filter(function(c) {
                    return (c.id === "cmd_back" || c.name.toLowerCase().indexOf(cmdQuery) !== -1 || c.id.toLowerCase().indexOf(cmdQuery) !== -1);
                });
            }
            var menus = root.getBaseCommands();
            if (cmdQuery === "")
                return menus;

            return menus.filter(function(c) {
                return (c.name.toLowerCase().indexOf(cmdQuery) !== -1 || c.id.toLowerCase().indexOf(cmdQuery) !== -1);
            });
        }
        var qLower = q.toLowerCase();
        var hiddenList = (Config.cfg && Config.cfg.launcherHiddenApps && Array.isArray(Config.cfg.launcherHiddenApps))
            ? Config.cfg.launcherHiddenApps
            : [];
        var vals = DesktopEntries.applications.values.filter(function(e) {
            if (!e || !e.id)
                return false;
            var normId = e.id.replace(/\.desktop$/i, "");
            for (var i = 0; i < hiddenList.length; i++) {
                var normHidden = String(hiddenList[i] || "").replace(/\.desktop$/i, "");
                if (normHidden === normId)
                    return false;
            }
            return true;
        });
        if (qLower === "") {
            var recent = AppLauncherState.recentIds;
            return vals.slice().sort(function(a, b) {
                var ai = recent.indexOf(a.id);
                var bi = recent.indexOf(b.id);
                if (ai !== -1 && bi !== -1)
                    return ai - bi;

                if (ai !== -1)
                    return -1;

                if (bi !== -1)
                    return 1;

                return a.name.localeCompare(b.name);
            });
        }
        var matchingApps = vals.filter(function(e) {
            if (e.name.toLowerCase().indexOf(qLower) !== -1)
                return true;

            if (e.genericName && e.genericName.toLowerCase().indexOf(qLower) !== -1)
                return true;

            for (var i = 0; i < e.keywords.length; i++) {
                if (e.keywords[i].toLowerCase().indexOf(qLower) !== -1)
                    return true;

            }
            return false;
        }).sort(function(a, b) {
            return a.name.localeCompare(b.name);
        });

        var matchingCommands = [];
        if (Config.cfg && Config.cfg.launcherCommandsNoPrefix) {
            var baseCmds = root.getBaseCommands();
            matchingCommands = baseCmds.filter(function(c) {
                return (c.name.toLowerCase().indexOf(qLower) !== -1 || c.id.toLowerCase().indexOf(qLower) !== -1);
            });
        }

        var calcItems = [];
        if (Config.cfg && Config.cfg.launcherCalculatorNoPrefix) {
            var hasMathOp = /[+\-*\/%^]|(sqrt|sin|cos|tan|abs|ceil|floor|round|log|pi)\b/i.test(q);
            if (hasMathOp) {
                var calcVal = root.calculateExpression(q);
                if (calcVal !== "" && calcVal !== "Erro") {
                    calcItems.push({
                        "isCalculator": true,
                        "customIcon": true,
                        "isCommand": false,
                        "id": "calculator_result",
                        "name": calcVal,
                        "expression": q,
                        "badge": q,
                        "icon": "󰃬",
                        "execute": function() {
                            if (typeof Quickshell.clipboardText !== "undefined") {
                                Quickshell.clipboardText = calcVal;
                            }
                        }
                    });
                }
            }
        }

        var webItems = [];
        if (Config.cfg && Config.cfg.launcherWebSearchNoPrefix && q !== "") {
            webItems.push({
                "isWebSearch": true,
                "customIcon": true,
                "isCommand": false,
                "isCalculator": false,
                "id": "web_search_direct",
                "name": qsTr("Search web for \"%1\"").arg(q),
                "expression": q,
                "badge": "WEB",
                "icon": "󰖟",
                "execute": function() {
                    root.executeWebSearch(q);
                }
            });
        }

        return calcItems.concat(matchingCommands).concat(matchingApps).concat(webItems);
    }
    readonly property color background: Colors.cfg.background
    readonly property color primary: Colors.cfg.primary
    readonly property color text: Colors.cfg.text
    property int maxVisible: 7
    readonly property int itemH: Math.round(42 * uiScale)
    property int panelW: Math.round(440 * uiScale)
    readonly property int panelH: showingShellOutput
        ? Math.round((96 + 300) * uiScale)
        : (root.gridMode
            ? Math.round((88 + 340) * uiScale)
            : Math.round(88 * uiScale + Math.min(filteredApps.length, maxVisible) * itemH))

    signal requestWallpaper()
    signal requestPresets()
    signal hideLauncher()
    signal requestOpenMenu(string name, string tab)

    function executeShellCommand(command) {
        command = command.trim();
        if (command === "")
            return ;

        shellOutput = "Executando: " + command + "\n\n";
        showingShellOutput = true;
        shellProcess.shellCommand = command;
        shellProcess.running = true;
    }

    function getItemProgress(idx) {
        if (introItems >= 1)
            return 1;

        if (introItems <= 0)
            return 0;

        let start = Math.min(idx, 10) * 0.04;
        let p = Math.min(1, Math.max(0, (introItems - start) / 0.42));
        if (p <= 0)
            return 0;

        if (p >= 1)
            return 1;

        let c1 = 0.85;
        let c3 = c1 + 1;
        return (1 + c3 * Math.pow(p - 1, 3) + c1 * Math.pow(p - 1, 2));
    }

    function getItemOpacity(idx) {
        if (introItems >= 1)
            return 1;

        if (introItems <= 0)
            return 0;

        let start = Math.min(idx, 10) * 0.04;
        let p = Math.min(1, Math.max(0, (introItems - start) / 0.28));
        return p;
    }

    function restartItemsIntro() {
        introItems = 0;
        itemsIntroSequence.restart();
    }

    function updateScroll() {
        if (typeof fieldArea === "undefined" || !fieldArea)
            return ;

        let visibleW = fieldArea.width;
        if (visibleW <= 0)
            return ;

        let totalW = searchInput.text.length * charSlotWidth;
        let curX = searchInput.cursorPosition * charSlotWidth;
        let curScreenX = curX + scrollOffset;
        let margin = Math.round(20 * uiScale);
        if (curScreenX < margin)
            scrollOffset = Math.min(0, margin - curX);
        else if (curScreenX > visibleW - margin)
            scrollOffset = Math.min(0, visibleW - margin - curX);
        else if (totalW + scrollOffset < visibleW && scrollOffset < 0)
            scrollOffset = Math.min(0, visibleW - totalW);
    }

    function syncCharModel() {
        let str = searchInput.text;
        let oldCount = charModel.count;
        let newCount = str.length;
        let prefix = 0;
        while (prefix < oldCount && prefix < newCount && charModel.get(prefix).char === str[prefix])
            prefix++;

        let suffix = 0;
        while (suffix < (oldCount - prefix) && suffix < (newCount - prefix) && charModel.get(oldCount - 1 - suffix).char === str[newCount - 1 - suffix])
            suffix++;

        let deleteCount = oldCount - prefix - suffix;
        if (deleteCount > 0)
            charModel.remove(prefix, deleteCount);

        let insertStr = str.slice(prefix, newCount - suffix);
        for (let i = 0; i < insertStr.length; i++) {
            charModel.insert(prefix + i, {
                "char": insertStr[i]
            });
        }
    }

    function calculateExpression(expression) {
        var expr = expression.trim();
        if (expr.startsWith("="))
            expr = expr.substring(1).trim();

        if (expr === "")
            return "";

        if (!/^[0-9+\-\*\/%().,\s^a-zA-Z]+$/.test(expr))
            return "Erro";

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
        var remaining = expr.replace(/Math\.(sqrt|sin|cos|tan|abs|ceil|floor|round|log|PI|E)/g, "").replace(/[\d+\-\*\/%().\s]/g, "");
        if (remaining !== "")
            return "Erro";

        try {
            var result = Function('"use strict"; return (' + expr + ')')();
            if (!isFinite(result))
                return "Erro";

            if (Math.abs(result - Math.round(result)) < 1e-09)
                return String(Math.round(result));

            return String(Number(result.toFixed(10)));
        } catch (e) {
            return "Erro";
        }
    }

    function executeWebSearch(query) {
        query = (query || "").trim();
        if (query === "")
            return ;

        var searchUrl = "https://www.google.com/search?q=" + encodeURIComponent(query);
        Qt.openUrlExternally(searchUrl);
    }

    function launchEntry(entry) {
        if (!entry)
            return ;

        if (entry.isWebSearch) {
            entry.execute();
            root.searchQuery = "";
            searchInput.text = "";
            charModel.clear();
            scrollOffset = 0;
            hideLauncher();
            AppLauncherState.hide();
            return ;
        }

        if (entry.isCalculator) {
            if (entry.name && entry.name !== "Erro" && typeof Quickshell.clipboardText !== "undefined") {
                Quickshell.clipboardText = entry.name;
            }
            root.searchQuery = "";
            searchInput.text = "";
            charModel.clear();
            scrollOffset = 0;
            hideLauncher();
            AppLauncherState.hide();
            return ;
        }

        if (entry.isShell) {
            entry.execute();
            root.searchQuery = "";
            searchInput.text = "";
            charModel.clear();
            scrollOffset = 0;
            return ;
        }
        if (entry.isCommand) {
            entry.execute();
            if (entry.stayOpen) {
                root.selectedIndex = 0;
                return ;
            }
            root.searchQuery = "";
            searchInput.text = "";
            charModel.clear();
            scrollOffset = 0;
            AppLauncherState.hide();
            hideLauncher();
            return ;
        }
        AppLauncherState.recordLaunch(entry.id);
        entry.execute();
        root.searchQuery = "";
        searchInput.text = "";
        charModel.clear();
        scrollOffset = 0;
        hideLauncher();
        AppLauncherState.hide();
    }

    NumberAnimation {
        id: gridScrollAnim
        target: gridFlickable
        property: "contentY"
        duration: 160
        easing.type: Easing.OutCubic
    }

    function ensureGridIndexVisible(idx, animated) {
        if (!gridFlickable || idx < 0)
            return ;

        var total = root.allApps.length;
        if (total === 0)
            return ;

        var row = Math.floor(idx / root.gridCols);
        var tileH = Math.round(76 * root.uiScale);
        var spacing = Math.round(6 * root.uiScale);
        var rowTop = row * (tileH + spacing);
        var rowBottom = rowTop + tileH;
        var viewH = gridFlickable.height > 0 ? gridFlickable.height : Math.round(340 * root.uiScale);
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

    function navigate(delta) {
        if (root.gridMode) {
            var total = root.allApps.length;
            if (total === 0)
                return ;

            var next = root.selectedIndex + delta;
            root.selectedIndex = Math.max(0, Math.min(total - 1, next));
            root.ensureGridIndexVisible(root.selectedIndex);
        } else {
            if (filteredApps.length === 0)
                return ;

            selectedIndex = (selectedIndex + delta + filteredApps.length) % filteredApps.length;
            listView.positionViewAtIndex(selectedIndex, ListView.Contain);
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

    onSelectedIndexChanged: {
        if (root.gridMode && gridFlickable && gridFlickable.visible) {
            root.ensureGridIndexVisible(root.selectedIndex);
        }
    }

    Component.onCompleted: {
        Qt.callLater(function() {
            searchInput.forceActiveFocus();
        });
    }
    onIsOpenChanged: {
        if (isOpen) {
            searchInput.text = "";
            root.searchQuery = "";
            root.selectedIndex = 0;
            root.gridMode = false;
            root.commandSubMode = "";
            charModel.clear();
            scrollOffset = 0;
            restartItemsIntro();
            Qt.callLater(function() {
                searchInput.forceActiveFocus();
            });
        } else {
            root.commandSubMode = "";
            root.gridMode = false;
        }
    }
    implicitWidth: panelW
    implicitHeight: panelH
    width: panelW
    height: panelH
    enabled: isOpen
    onFilteredAppsChanged: {
        if (!root.gridMode) {
            selectedIndex = 0;
            restartItemsIntro();
        }
    }

    Process {
        id: shellProcess

        property string shellCommand: ""

        command: ["sh", "-c", shellCommand]
        onExited: function(exitCode, exitStatus) {
            root.shellOutput += "\n\nExit code: " + exitCode;
            console.log("Command finished:", exitCode);
        }

        stdout: StdioCollector {
            onStreamFinished: {
                root.shellOutput += text;
                console.log("Command output:", text);
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                root.shellOutput += text;
                console.log("Command error:", text);
            }
        }

    }

    MenuEntrance {
        id: launcherEntrance

        active: root.isOpen && root.visible
        duration: 300
        startOffsetY: Math.round(12 * uiScale)
    }

    SequentialAnimation {
        id: itemsIntroSequence

        running: false

        PauseAnimation {
            duration: 30
        }

        NumberAnimation {
            target: root
            property: "introItems"
            from: 0
            to: 1
            duration: 480
            easing.type: Easing.Linear
        }

    }

    TextMetrics {
        id: charMetrics

        font.pixelSize: Math.round(15 * uiScale)
        font.family: "GeistMono Nerd Font Propo"
        text: "M"
    }

    ListModel {
        id: charModel
    }

    Rectangle {
        id: panel

        anchors.fill: parent
        color: "transparent"
        clip: true

        Column {
            spacing: Math.round(4 * uiScale)
            opacity: launcherEntrance.opacity

            anchors {
                top: parent.top
                left: parent.left
                leftMargin: Math.round(12 * uiScale)
                right: parent.right
                rightMargin: Math.round(12 * uiScale)
            }

            Item {
                width: 1
                height: Math.round(8 * uiScale)
            }

            Rectangle {
                id: searchBox

                property real focusPop: 1

                width: parent.width
                height: Math.round(45 * uiScale)
                radius: Math.round(20 * uiScale)
                color: Qt.alpha(Colors.cfg.surfaceContainer, 0.5)
                scale: focusPop

                SequentialAnimation {
                    id: focusPopAnim

                    NumberAnimation {
                        target: searchBox
                        property: "focusPop"
                        to: 1.02
                        duration: 110
                        easing.type: Easing.OutQuad
                    }

                    NumberAnimation {
                        target: searchBox
                        property: "focusPop"
                        to: 1
                        duration: 320
                        easing.type: Easing.OutQuint
                    }

                }

                Rectangle {
                    anchors.fill: parent
                    radius: Math.round(20 * uiScale)
                    color: "transparent"
                    border.color: root.primary
                    border.width: 1
                    opacity: searchInput.activeFocus ? 0.6 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }

                    }

                }

                RowLayout {
                    spacing: Math.round(8 * uiScale)

                    anchors {
                        fill: parent
                        leftMargin: Math.round(14 * uiScale)
                        rightMargin: Math.round(10 * uiScale)
                    }

                    Text {
                        text: root.isCalculatorMode ? "calculate" : root.isShellMode ? "terminal" : root.isCommandMode ? "keyboard_command_key" : root.isWebSearchMode ? "public" : (root.gridMode ? "apps" : "search")
                        font.pixelSize: Math.round(16 * uiScale)
                        font.family: "Material Symbols Rounded"
                        color: root.primary
                        opacity: searchInput.activeFocus ? 0.85 : 0.5
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                            }

                        }

                    }

                    Item {
                        id: fieldArea

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        onWidthChanged: root.updateScroll()

                        Text {
                            anchors.fill: parent
                            text: root.gridMode ? "All Applications" : (root.isSearching ? "" : "Search apps…")
                            color: root.primary
                            opacity: (searchInput.text.length === 0 && charModel.count === 0) ? (root.gridMode ? 0.6 : 0.35) : 0
                            font.pixelSize: Math.round(15 * uiScale)
                            font.family: "GeistMono Nerd Font Propo"
                            verticalAlignment: Text.AlignVCenter
                            visible: opacity > 0.001

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 150
                                }

                            }

                        }

                        ListView {
                            id: charRow

                            height: parent.height
                            anchors.verticalCenter: parent.verticalCenter
                            orientation: ListView.Horizontal
                            interactive: false
                            boundsBehavior: Flickable.StopAtBounds
                            spacing: 0
                            width: contentWidth
                            x: root.scrollOffset
                            model: charModel

                            Behavior on x {
                                NumberAnimation {
                                    duration: 160
                                    easing.type: Easing.OutQuad
                                }

                            }

                            add: Transition {
                                ParallelAnimation {
                                    NumberAnimation {
                                        property: "scale"
                                        from: 0.3
                                        to: 1
                                        duration: 380
                                        easing.type: Easing.OutBack
                                        easing.overshoot: 2.5
                                    }

                                    NumberAnimation {
                                        property: "y"
                                        from: Math.round(10 * uiScale)
                                        to: 0
                                        duration: 380
                                        easing.type: Easing.OutBack
                                        easing.overshoot: 2
                                    }

                                    NumberAnimation {
                                        property: "opacity"
                                        from: 0
                                        to: 1
                                        duration: 120
                                        easing.type: Easing.OutCubic
                                    }

                                }

                            }

                            remove: Transition {
                                ParallelAnimation {
                                    NumberAnimation {
                                        property: "scale"
                                        to: 0.3
                                        duration: 160
                                        easing.type: Easing.InBack
                                    }

                                    NumberAnimation {
                                        property: "y"
                                        to: Math.round(-8 * uiScale)
                                        duration: 160
                                        easing.type: Easing.InCubic
                                    }

                                    NumberAnimation {
                                        property: "opacity"
                                        to: 0
                                        duration: 140
                                        easing.type: Easing.InCubic
                                    }

                                }

                            }

                            displaced: Transition {
                                NumberAnimation {
                                    properties: "x,y"
                                    duration: 220
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.5
                                }

                            }

                            delegate: Item {
                                id: slot

                                width: root.charSlotWidth
                                height: charRow.height
                                transformOrigin: Item.Center

                                Text {
                                    anchors.centerIn: parent
                                    text: model.char
                                    color: root.primary
                                    font.pixelSize: Math.round(15 * uiScale)
                                    font.family: "Google Sans"
                                }

                            }

                        }

                        Rectangle {
                            id: caretRect

                            width: Math.max(2, Math.round(2 * uiScale))
                            height: Math.round(18 * uiScale)
                            color: root.primary
                            visible: searchInput.activeFocus && root.isOpen
                            anchors.verticalCenter: parent.verticalCenter
                            x: root.scrollOffset + (searchInput.cursorPosition * root.charSlotWidth)

                            Behavior on x {
                                NumberAnimation {
                                    duration: 160
                                    easing.type: Easing.OutQuad
                                }

                            }

                            SequentialAnimation on opacity {
                                running: searchInput.activeFocus && root.isOpen
                                loops: Animation.Infinite

                                NumberAnimation {
                                    to: 0
                                    duration: 120
                                    easing.type: Easing.InQuad
                                }

                                PauseAnimation {
                                    duration: 350
                                }

                                NumberAnimation {
                                    to: 1
                                    duration: 120
                                    easing.type: Easing.OutQuad
                                }

                                PauseAnimation {
                                    duration: 350
                                }

                            }

                        }

                        TextInput {
                            id: searchInput

                            focus: true
                            anchors.fill: parent
                            color: "transparent"
                            selectionColor: "transparent"
                            selectedTextColor: "transparent"
                            font.pixelSize: Math.round(15 * uiScale)
                            font.family: "GeistMono Nerd Font Propo"
                            verticalAlignment: TextInput.AlignVCenter
                            clip: true
                            cursorVisible: false
                            onActiveFocusChanged: {
                                if (activeFocus)
                                    focusPopAnim.restart();

                            }
                            onCursorPositionChanged: root.updateScroll()
                            onTextChanged: {
                                root.searchQuery = text;
                                if (text.length > 0) {
                                    root.showingShellOutput = false;
                                    root.gridMode = false;
                                }

                                root.syncCharModel();
                                root.updateScroll();
                            }
                            Keys.onPressed: function(event) {
                                if (event.key === Qt.Key_Up) {
                                    root.navigate(root.gridMode ? -root.gridCols : -1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Down) {
                                    root.navigate(root.gridMode ? root.gridCols : 1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Left) {
                                    if (root.gridMode) {
                                        root.navigate(-1);
                                        event.accepted = true;
                                    }
                                } else if (event.key === Qt.Key_Right) {
                                    if (root.gridMode) {
                                        root.navigate(1);
                                        event.accepted = true;
                                    }
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    if (root.gridMode) {
                                        if (root.allApps.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.allApps.length) {
                                            root.launchEntry(root.allApps[root.selectedIndex]);
                                        }
                                    } else if (root.filteredApps.length > 0) {
                                        root.launchEntry(root.filteredApps[root.selectedIndex]);
                                    }

                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Escape) {
                                    if (root.showingShellOutput) {
                                        root.showingShellOutput = false;
                                    } else if (root.commandSubMode !== "") {
                                        root.commandSubMode = "";
                                    } else if (root.gridMode) {
                                        root.gridMode = false;
                                    } else {
                                        AppLauncherState.hide();
                                        root.hideLauncher();
                                        MenuService.closeAll();
                                    }
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_A && (event.modifiers & Qt.ControlModifier)) {
                                    root.gridMode = !root.gridMode;
                                    if (root.gridMode) {
                                        if (searchInput.text.length > 0) {
                                            searchInput.text = "";
                                            root.searchQuery = "";
                                            charModel.clear();
                                            root.scrollOffset = 0;
                                        }
                                        root.showingShellOutput = false;
                                        root.selectedIndex = 0;
                                        if (gridFlickable) {
                                            gridScrollAnim.stop();
                                            gridFlickable.contentY = 0;
                                        }
                                    }
                                    event.accepted = true;
                                }
                            }
                        }

                    }

                    Item {
                        id: clearBtn

                        Layout.preferredWidth: Math.round(28 * uiScale)
                        Layout.preferredHeight: Math.round(28 * uiScale)
                        visible: searchInput.text.length > 0
                        opacity: searchInput.text.length > 0 ? 1 : 0
                        scale: clearMa.pressed ? 0.88 : (clearMa.containsMouse ? 1.08 : 1)

                        Rectangle {
                            anchors.fill: parent
                            radius: Math.round(14 * uiScale)
                            color: clearMa.containsMouse ? Qt.alpha(root.primary, 0.15) : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "close"
                                font.pixelSize: Math.round(13 * uiScale)
                                font.family: "Material Symbols Rounded"
                                color: root.primary
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }

                            }

                        }

                        MouseArea {
                            id: clearMa

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchInput.text = "";
                                root.searchQuery = "";
                                charModel.clear();
                                root.scrollOffset = 0;
                                searchInput.forceActiveFocus();
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                            }

                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutBack
                            }

                        }

                    }

                    Rectangle {
                        id: gridToggleBtn

                        Layout.preferredWidth: Math.round(28 * uiScale)
                        Layout.preferredHeight: Math.round(28 * uiScale)
                        radius: Math.round(7 * uiScale)
                        color: (gridToggleMa.containsMouse || root.gridMode) ? Qt.alpha(root.primary, 0.2) : "transparent"
                        scale: gridToggleMa.pressed ? 0.88 : (gridToggleMa.containsMouse ? 1.08 : 1)

                        Grid {
                            anchors.centerIn: parent
                            columns: 3
                            rowSpacing: Math.max(1, Math.round(2 * uiScale))
                            columnSpacing: Math.max(1, Math.round(2 * uiScale))

                            Repeater {
                                model: 9

                                Rectangle {
                                    width: Math.max(2, Math.round(3 * uiScale))
                                    height: Math.max(2, Math.round(3 * uiScale))
                                    radius: 1
                                    color: (gridToggleMa.containsMouse || root.gridMode) ? root.primary : Qt.alpha(root.text, 0.45)

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: gridToggleMa

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.gridMode = !root.gridMode;
                                if (root.gridMode) {
                                    if (searchInput.text.length > 0) {
                                        searchInput.text = "";
                                        root.searchQuery = "";
                                        charModel.clear();
                                        root.scrollOffset = 0;
                                    }
                                    root.showingShellOutput = false;
                                    root.selectedIndex = 0;
                                    if (gridFlickable) {
                                        gridScrollAnim.stop();
                                        gridFlickable.contentY = 0;
                                    }
                                }
                                searchInput.forceActiveFocus();
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutBack
                            }
                        }
                    }

                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutQuint
                    }

                }

            }

            Item {
                width: 1
                height: Math.round(8 * uiScale)
            }

            Rectangle {
                id: shellOutputBox

                visible: root.showingShellOutput
                width: parent.width
                height: Math.round(300 * uiScale)
                radius: Math.round(18 * uiScale)
                color: Qt.alpha(Colors.cfg.surfaceContainer, 0.5)
                clip: true

                Flickable {
                    anchors.fill: parent
                    anchors.margins: Math.round(14 * uiScale)
                    clip: true
                    contentWidth: width
                    contentHeight: outputText.height
                    interactive: true

                    Text {
                        id: outputText

                        width: parent.width
                        text: root.shellOutput
                        color: root.text
                        font.pixelSize: Math.round(12 * uiScale)
                        font.family: "Google Sans"
                        wrapMode: Text.Wrap
                        textFormat: Text.PlainText
                    }

                }

            }

            ListView {
                id: listView

                visible: !root.showingShellOutput && !root.gridMode
                width: parent.width
                height: Math.min(root.filteredApps.length, root.maxVisible) * root.itemH
                model: root.filteredApps
                clip: true
                interactive: false

                Rectangle {
                    id: morphHighlight

                    property real targetY: (root.selectedIndex >= 0 && root.filteredApps.length > 0) ? (root.selectedIndex * root.itemH + Math.round(2 * uiScale)) : Math.round(2 * uiScale)

                    parent: listView.contentItem
                    z: 0
                    visible: opacity > 0.001
                    opacity: (listView.count > 0 && root.selectedIndex >= 0) ? 1 : 0
                    x: 0
                    width: listView.width
                    height: root.itemH - Math.round(4 * uiScale)
                    radius: Math.round(20 * uiScale)
                    color: root.primary
                    y: targetY

                    Behavior on y {
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.OutCubic
                        }

                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }

                    }

                }

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onWheel: function(wheel) {
                        if (wheel.angleDelta.y < 0)
                            root.navigate(1);
                        else
                            root.navigate(-1);
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: opacity > 0.001
                    opacity: root.filteredApps.length === 0 ? 0.35 : 0
                    text: "No apps found"
                    color: root.text

                    font {
                        pixelSize: Math.round(15 * uiScale)
                        family: "Google Sans"
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }

                    }

                }

                delegate: Item {
                    id: appRow

                    readonly property bool sel: root.selectedIndex === index
                    readonly property bool isRecent: !root.isSearching && AppLauncherState.recentIds.indexOf(modelData.id) !== -1 && AppLauncherState.recentIds.indexOf(modelData.id) < 5

                    width: listView.width
                    height: root.itemH
                    z: 1
                    opacity: root.getItemOpacity(index)

                    Item {
                        id: appRowContent

                        anchors.fill: parent
                        scale: rowMa.pressed ? 0.98 : 1

                        Rectangle {
                            radius: Math.round(20 * uiScale)
                            color: Qt.alpha(Colors.cfg.surfaceContainer, 0.4)
                            opacity: rowMa.containsMouse && !appRow.sel ? 1 : 0

                            anchors {
                                fill: parent
                                topMargin: Math.round(2 * uiScale)
                                bottomMargin: Math.round(2 * uiScale)
                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 120
                                }

                            }

                        }

                        Row {
                            spacing: Math.round(12 * uiScale)

                            anchors {
                                fill: parent
                                leftMargin: Math.round(8 * uiScale) + (appRow.sel ? Math.round(4 * uiScale) : 0)
                                rightMargin: Math.round(8 * uiScale)
                            }

                            Rectangle {
                                width: Math.round(36 * uiScale)
                                height: Math.round(36 * uiScale)
                                radius: Math.round(18 * uiScale)
                                anchors.verticalCenter: parent.verticalCenter
                                color: modelData.paletteData ? (modelData.paletteData.bg || "#1e1e2e") : "transparent"
                                border.color: modelData.paletteData ? (modelData.paletteData.color || "#89b4fa") : "transparent"
                                border.width: modelData.paletteData ? Math.round(2 * uiScale) : 0
                                scale: appRow.sel ? 1.06 : 1

                                Text {
                                    anchors.centerIn: parent
                                    visible: modelData.customIcon === true && !modelData.paletteData
                                    text: modelData.icon || ""
                                    color: appRow.sel ? root.background : root.primary

                                    font {
                                        pixelSize: Math.round(19 * uiScale)
                                        family: "Material Symbols Rounded"
                                    }

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 120
                                        }

                                    }

                                }

                                Row {
                                    anchors.centerIn: parent
                                    spacing: Math.round(3 * uiScale)
                                    visible: !!modelData.paletteData

                                    Repeater {
                                        model: modelData.paletteData ? (modelData.paletteData.swatches || []) : []

                                        delegate: Rectangle {
                                            required property var modelData

                                            width: Math.round(6 * uiScale)
                                            height: Math.round(6 * uiScale)
                                            radius: Math.round(3 * uiScale)
                                            color: modelData || "transparent"
                                        }

                                    }

                                }

                                Image {
                                    id: appIcon

                                    anchors.centerIn: parent
                                    visible: modelData.customIcon !== true && !modelData.paletteData
                                    width: Math.round(32 * uiScale)
                                    height: Math.round(32 * uiScale)
                                    source: modelData.icon !== "" ? ("image://icon/" + modelData.icon) : ""
                                    smooth: true
                                    mipmap: true
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: modelData.customIcon !== true && !modelData.paletteData && appIcon.status !== Image.Ready
                                    text: modelData.name.charAt(0).toUpperCase()
                                    color: appRow.sel ? root.background : root.primary

                                    font {
                                        pixelSize: Math.round(15 * uiScale)
                                        family: "Google Sans"
                                        weight: Font.Bold
                                    }

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 120
                                        }

                                    }

                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutBack
                                    }

                                }

                            }

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Math.round(8 * uiScale)

                                Text {
                                    text: modelData.name
                                    color: appRow.sel ? root.background : root.text
                                    anchors.verticalCenter: parent.verticalCenter

                                    font {
                                        pixelSize: Math.round(13 * uiScale)
                                        family: "Google Sans"
                                        weight: appRow.sel ? Font.Medium : Font.Normal
                                    }

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 120
                                        }

                                    }

                                }

                                Rectangle {

                                    visible:typeof modelData.badge === "string" && modelData.badge.length > 0
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: Math.round(16 * uiScale)
                                    width: badgeText.implicitWidth + Math.round(10 * uiScale)
                                    radius: Math.round(8 * uiScale)
                                    color: {
                                        var b = modelData.badge || "";
                                        if (b === "on" || b === "active" || b === "WEB")
                                            return Qt.alpha(root.primary, appRow.sel ? 0.35 : 0.22);

                                        return Qt.alpha(Colors.cfg.surfaceContainer, appRow.sel ? 0.4 : 0.6);
                                    }

                                    Text {
                                        id: badgeText

                                        anchors.centerIn: parent
                                        text: modelData.badge || ""
                                        font.pixelSize: Math.round(9 * uiScale)
                                        font.bold: true
                                        color: {
                                            var b = modelData.badge || "";
                                            if (b === "on" || b === "active" || b === "WEB")
                                                return appRow.sel ? root.background : root.primary;

                                            return appRow.sel ? Qt.alpha(root.background, 0.7) : Qt.alpha(root.text, 0.5);
                                        }
                                    }

                                }

                            }

                            Behavior on anchors.leftMargin {
                                NumberAnimation {
                                    duration: 220
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.15
                                }

                            }

                        }

                        MouseArea {
                            id: rowMa

                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: root.selectedIndex = index
                            onClicked: root.launchEntry(modelData)
                            onWheel: function(wheel) {
                                if (wheel.angleDelta.y < 0)
                                    root.navigate(1);
                                else
                                    root.navigate(-1);
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 180
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.2
                            }

                        }

                    }

                    transform: Translate {
                        x: -20 * root.uiScale * (1 - root.getItemProgress(index))
                    }

                }

            }

            Flickable {
                id: gridFlickable

                visible: !root.showingShellOutput && root.gridMode
                width: parent.width
                height: Math.round(340 * uiScale)
                clip: true
                contentWidth: width
                contentHeight: gridFlow.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Flow {
                    id: gridFlow

                    width: parent.width
                    spacing: Math.round(6 * uiScale)

                    Repeater {
                        model: root.allApps

                        delegate: Rectangle {
                            id: gridTile

                            required property int index
                            required property var modelData

                            readonly property bool isSelected: index === root.selectedIndex

                            width: gridFlow.width > 0 ? Math.floor((gridFlow.width - (root.gridCols - 1) * gridFlow.spacing) / root.gridCols) : Math.round(80 * uiScale)
                            height: Math.round(76 * uiScale)
                            radius: Math.round(12 * uiScale)
                            color: isSelected ? Qt.alpha(root.primary, 0.2) : (tileArea.containsMouse ? Qt.alpha(root.primary, 0.1) : Qt.alpha(Colors.cfg.surfaceContainer, 0.4))
                            border.color: isSelected ? root.primary : Qt.alpha(root.primary, 0.12)
                            border.width: isSelected ? 1.5 : 1

                            Column {
                                anchors.centerIn: parent
                                spacing: Math.round(4 * uiScale)
                                width: parent.width - Math.round(8 * uiScale)

                                Image {
                                    id: tileAppIcon

                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: Math.round(30 * uiScale)
                                    height: Math.round(30 * uiScale)
                                    source: (modelData && modelData.icon) ? ("image://icon/" + modelData.icon) : ""
                                    smooth: true
                                    mipmap: true
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    visible: tileAppIcon.status !== Image.Ready
                                    text: (modelData && modelData.name) ? modelData.name.charAt(0).toUpperCase() : "?"
                                    font.family: "Google Sans"
                                    font.pixelSize: Math.round(16 * uiScale)
                                    font.bold: true
                                    color: root.primary
                                }

                                Text {
                                    width: parent.width
                                    text: (modelData && modelData.name) || ""
                                    font.family: "Google Sans"
                                    font.pixelSize: Math.round(10 * uiScale)
                                    font.weight: gridTile.isSelected ? Font.Medium : Font.Normal
                                    color: gridTile.isSelected ? root.primary : root.text
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
                                    root.launchEntry(modelData);
                                }
                            }

                        }

                    }

                }

            }

            Item {
                width: 1
                height: Math.round(4 * uiScale)
            }

            transform: Translate {
                y: launcherEntrance.offsetY
            }

        }

        Behavior on height {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutCubic
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 500
                easing.type: Easing.InOutQuad
            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutBack
            }

        }

    }

}
