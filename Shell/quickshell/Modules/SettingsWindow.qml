import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Asura
import qs.Services
import "Settings/Tabs"
import "Settings/Components"

FloatingWindow {
    id: root

    readonly property var settingsWindowRoot: root

    property color primary: Colors.cfg.primary
    property color secondary: Colors.cfg.secondary
    property color background: Colors.cfg.base00
    property color surface: Colors.cfg.surface
    property color surfaceContainer: Colors.cfg.base02
    property color borderCol: Colors.cfg.base03
    property color textMuted: Colors.cfg.base04
    property color text: Colors.cfg.base05
    property color textBright: Colors.cfg.base06
    property color on_primary: Colors.cfg.on_primary
    property alias color1: root.primary
    property alias color2: root.secondary
    property alias foreground: root.on_primary
    property alias textColor: root.text

    property alias reloadShellProc: reloadShellProc
    property alias playSoundProc: playSoundProc
    property alias nwgLookProc: nwgLookProc
    property alias loadTemplatesProc: loadTemplatesProc
    property alias applyTemplatesProc: applyTemplatesProc
    property alias wpListProc: wpListProc
    property alias importWpProc: importWpProc
    property alias selectFolderProc: selectFolderProc
    property alias selectRecordingsFolderProc: selectRecordingsFolderProc
    property alias focusTimer: focusTimer
    readonly property bool isClosing: closeSequence.running
    property bool isOpen: false
    property real introBase: 0
    property real introSidebar: 0
    property real introTabs: 0
    property real introContent: 0
    readonly property var tabOrder: ["general", "theme", "bar", "windows", "defaultapps", "monitors", "presets", "apptheming", "gtk", "launcher", "notifications", "keyboard", "shortcuts", "about"]
    property string currentTab: "general"

    property string toastMessage: ""
    property string toastIcon: "check_circle"
    property bool showToastNotification: false

    Timer {
        id: toastTimer
        interval: 3200
        repeat: false
        onTriggered: root.showToastNotification = false
    }

    function showToast(msg, icon) {
        root.toastMessage = msg;
        root.toastIcon = icon || "check_circle";
        root.showToastNotification = true;
        toastTimer.restart();
    }

    Connections {
        target: PresetService
        function onPresetSaved(id, name) {
            root.showToast(qsTr("Preset '%1' saved successfully!").arg(name), "style");
        }
    }

    readonly property var activeAppsTab: (appsTabLoader && appsTabLoader.item) ? appsTabLoader.item : null
    readonly property var activeMonitorsTab: (monitorsTabLoader && monitorsTabLoader.item) ? monitorsTabLoader.item : null

    property string settingsSearchQuery: ""
    property string selectedTabCategory: "all" // "all" | "appearance" | "desktop" | "system"

    readonly property var allSettingsTabs: [
        { "id": "general", "category": "appearance", "name": qsTr("General"), "desc": qsTr("Interface, blur & paths"), "icon": "settings", "keywords": "general blur opacity wallpaper background interface paths clock interval transition geometry radius curvature arredondamento papel de parede plano de fundo transparencia pasta diretorio interface cantos desfoque timer slideshow tempo" },
        { "id": "theme", "category": "appearance", "name": qsTr("Theme"), "desc": qsTr("Colors & themes"), "icon": "palette", "keywords": "theme colors dark light mode material you dynamic palette auto theme accents cores tema escuro claro paleta esquema base16 cor primaria secundaria matugen" },
        { "id": "bar", "category": "desktop", "name": qsTr("Bar"), "desc": qsTr("Layout, widgets & melt"), "icon": "dock", "keywords": "bar widgets layout autohide position cava visualizer capsules spacing melt thickness espessura tamanho size hover text labels tooltip barra esconder ocultar posicao ilha island audio visualizador widgets painel flutuante borda margem" },
        { "id": "windows", "category": "desktop", "name": qsTr("Windows"), "desc": qsTr("Gaps, borders & styling"), "icon": "space_dashboard", "keywords": "windows gaps borders rounding shadow opacity single window layout hyprland janelas bordas sombras arredondamento espacamento divisao master dwindle scrolling paperwm gapsin gapsout inteligente smart split" },
        { "id": "defaultapps", "category": "system", "name": qsTr("Apps"), "desc": qsTr("Defaults & hidden apps"), "icon": "apps", "keywords": "apps default applications browser terminal file manager hidden launcher aplicativos padrao navegador terminal gerenciador arquivos ocultos programas padroes esconder" },
        { "id": "monitors", "category": "system", "name": qsTr("Monitors"), "desc": qsTr("Displays, scale & layout"), "icon": "desktop_windows", "keywords": "monitors displays resolution scale refresh rate vrr position canvas monitor tela telas resolucao taxa atualizacao escala hz freesync gsync rotacao transform espelho" },
        { "id": "presets", "category": "appearance", "name": qsTr("Presets"), "desc": qsTr("Saved appearance rices"), "icon": "style", "keywords": "presets rices appearances backup restore save load predefinicoes aparencias temas salvos exportar importar backup restaurar rice configuracoes prontas customizacoes" },
        { "id": "apptheming", "category": "appearance", "name": qsTr("App Theming"), "desc": qsTr("Template color themes"), "icon": "format_paint", "keywords": "templates app theming kitty terminal vscode btop neovim starship discord sincronizacao editores cores aplicacoes temas programas sincronizar" },
        { "id": "gtk", "category": "appearance", "name": qsTr("GTK Style"), "desc": qsTr("Theme & font config"), "icon": "auto_fix_high", "keywords": "gtk font cursor icons style nwg-look fonte cursor icones tema ponteiro tamanho fonte interface aparencia estilo" },
        { "id": "launcher", "category": "desktop", "name": qsTr("App Launcher"), "desc": qsTr("Position, apps & commands"), "icon": "rocket_launch", "keywords": "launcher apps search compact zen calculator prefix commands inicializador busca pesquisa calculadora prefixos comandos web atalhos busca aplicativos terminal web google" },
        { "id": "notifications", "category": "desktop", "name": qsTr("Notifications"), "desc": qsTr("Sound & toasts"), "icon": "notifications", "keywords": "notifications toasts sound alerts timeout do not disturb dnd som audio volume notificacoes notificacao alertas campainha silencioso aviso toques efeitos sonoros chime bell" },
        { "id": "keyboard", "category": "system", "name": qsTr("Mouse & Keyboard"), "desc": qsTr("Pointers, layouts & typing"), "icon": "keyboard", "keywords": "keyboard mouse touchpad layouts cursor speed acceleration typing mouse teclado sensibilidade pointer touch aceleracao rolagem layout abnt2 idiomas repeticao atraso taxa toque trackpad" },
        { "id": "shortcuts", "category": "system", "name": qsTr("Shortcuts"), "desc": qsTr("Hotkeys & custom keybinds"), "icon": "keyboard_command_key", "keywords": "shortcuts keybinds keys hotkeys hyprland super chords atalhos binds teclas teclado atalho comando binds combinacoes teclas de atalho super mod rebind custom" },
        { "id": "about", "category": "system", "name": qsTr("About"), "desc": qsTr("System, specs & shell info"), "icon": "info", "keywords": "about system specs hardware cpu gpu memory disk kernel distro uptime quickshell asura version sobre sistema informacoes memoria processador placa video versao especificacoes maquina info informacao" }
    ]

    function normalizeSearchText(str) {
        if (!str) return "";
        return String(str)
            .toLowerCase()
            .normalize("NFD")
            .replace(/[\u0300-\u036f]/g, "");
    }

    readonly property var searchSynonyms: ({
        "som": ["sound", "audio", "chime", "bell", "alert", "volume"],
        "audio": ["sound", "audio", "cava", "music", "volume"],
        "volume": ["sound", "audio", "volume"],
        "espessura": ["thickness", "width", "size"],
        "tamanho": ["size", "scale", "thickness"],
        "arredondamento": ["radius", "rounding", "curvature", "geometry"],
        "raio": ["radius", "rounding"],
        "desfoque": ["blur"],
        "transparencia": ["opacity", "transparent"],
        "opacidade": ["opacity"],
        "papel": ["wallpaper"],
        "fundo": ["background", "wallpaper"],
        "barra": ["bar"],
        "esconder": ["autohide", "hide"],
        "ocultar": ["autohide", "hide", "hidden"],
        "janela": ["window", "windows"],
        "janelas": ["window", "windows"],
        "borda": ["border", "borders"],
        "bordas": ["border", "borders"],
        "sombra": ["shadow", "shadows"],
        "sombras": ["shadow", "shadows"],
        "espacamento": ["gaps", "spacing", "padding"],
        "gaps": ["gaps", "spacing"],
        "atalho": ["shortcut", "keybind", "hotkey"],
        "atalhos": ["shortcuts", "keybinds", "hotkeys"],
        "teclado": ["keyboard"],
        "tecla": ["key", "keyboard"],
        "cursor": ["cursor", "pointer"],
        "ponteiro": ["pointer", "cursor"],
        "rolagem": ["scroll", "scrolling"],
        "tela": ["display", "monitor", "screen"],
        "telas": ["displays", "monitors", "screens"],
        "resolucao": ["resolution"],
        "cor": ["color", "palette", "theme"],
        "cores": ["colors", "palette", "theme"],
        "tema": ["theme"],
        "claro": ["light"],
        "escuro": ["dark"],
        "aplicativo": ["app", "apps", "application"],
        "aplicativos": ["apps", "applications"],
        "navegador": ["browser"],
        "pasta": ["path", "directory", "folder"],
        "pastas": ["paths", "directories", "folders"],
        "reiniciar": ["restart", "reload", "sync"]
    })

    function getSearchTerms(query) {
        var qNorm = root.normalizeSearchText(query.trim());
        if (qNorm === "") return [];
        var terms = [qNorm];
        if (root.searchSynonyms[qNorm]) {
            var syns = root.searchSynonyms[qNorm];
            for (var s = 0; s < syns.length; s++) {
                terms.push(syns[s]);
            }
        }
        return terms;
    }

    readonly property var visibleSettingsTabs: {
        var q = root.normalizeSearchText(root.settingsSearchQuery.trim());
        var cat = root.selectedTabCategory;
        return root.allSettingsTabs.filter(function(tab) {
            if (q !== "") {
                var tabName = root.normalizeSearchText(tab.name || "");
                var tabDesc = root.normalizeSearchText(tab.desc || "");
                var tabKw = root.normalizeSearchText(tab.keywords || "");
                var terms = root.getSearchTerms(q);
                for (var t = 0; t < terms.length; t++) {
                    var term = terms[t];
                    if (tabName.indexOf(term) !== -1 || tabDesc.indexOf(term) !== -1 || tabKw.indexOf(term) !== -1) {
                        return true;
                    }
                }
                return false;
            }
            if (cat !== "all" && tab.category !== cat) {
                return false;
            }
            return true;
        });
    }
    readonly property string configDirPath: Quickshell.env("HOME") + "/.config/asura"
    readonly property string configFilePath: configDirPath
    property bool wallpaperListExpanded: false
    property int wallpaperGalleryHeight: 320
    property var availableWallpapers: []
    property string selectedCategory: "all"
    property string paletteSearchQuery: ""
    property bool showAddWidgetModal: false
    property string selectedAddZone: "left"
    property bool showWidgetConfigModal: false
    property var activeConfigWidget: null
    property string activeConfigZone: ""
    property bool showWallpaperPickerModal: false

    function openWidgetConfigModal(widgetData, zoneName) {
        root.activeConfigWidget = widgetData;
        root.activeConfigZone = zoneName;
        root.showWidgetConfigModal = true;
    }

    function closeWidgetConfigModal() {
        root.showWidgetConfigModal = false;
        root.activeConfigWidget = null;
        root.activeConfigZone = "";
    }

    function openWallpaperPicker() {
        root.refreshWallpapers();
        root.showWallpaperPickerModal = true;
    }

    function closeWallpaperPicker() {
        root.showWallpaperPickerModal = false;
    }

    function openKeyRecorder(item) {
        keyRecorderModal.targetItem = item;
        keyRecorderModal.active = true;
    }

    property real firstMatchedCardY: -1
    property bool tabHasNoMatches: false

    onSettingsSearchQueryChanged: {
        var q = root.settingsSearchQuery.trim();
        if (q !== "") {
            var isCurrentVisible = false;
            for (var i = 0; i < root.visibleSettingsTabs.length; i++) {
                if (root.visibleSettingsTabs[i].id === root.currentTab) {
                    isCurrentVisible = true;
                    break;
                }
            }
            if (!isCurrentVisible && root.visibleSettingsTabs.length > 0) {
                root.currentTab = root.visibleSettingsTabs[0].id;
            }
        }
        flashTabTimer.restart();
    }

    Timer {
        id: flashTabTimer
        interval: 100
        repeat: false
        onTriggered: root.applySearchFilter()
    }

    function flashActiveTabHeaders() {
        root.applySearchFilter();
    }

    function itemMatchesSearch(item, terms, depth) {
        if (!item) return false;
        var d = depth || 0;
        if (d > 8) return false;

        var textProps = ["title", "description", "desc", "hint", "text", "label", "name", "caption", "subtitle", "keywords", "customValueText"];
        for (var p = 0; p < textProps.length; p++) {
            var propName = textProps[p];
            if (item[propName] !== undefined && typeof item[propName] === "string" && item[propName].trim() !== "") {
                var normText = root.normalizeSearchText(item[propName]);
                for (var t = 0; t < terms.length; t++) {
                    if (normText.indexOf(terms[t]) !== -1) {
                        return true;
                    }
                }
            }
        }

        if (item.model !== undefined && item.model) {
            if (Array.isArray(item.model)) {
                for (var m = 0; m < item.model.length; m++) {
                    var entry = item.model[m];
                    if (typeof entry === "string") {
                        var normEntry = root.normalizeSearchText(entry);
                        for (var t1 = 0; t1 < terms.length; t1++) {
                            if (normEntry.indexOf(terms[t1]) !== -1) return true;
                        }
                    } else if (entry && typeof entry === "object") {
                        var modelProps = ["label", "name", "title", "desc", "hint", "id"];
                        for (var mp = 0; mp < modelProps.length; mp++) {
                            var k = modelProps[mp];
                            if (entry[k] !== undefined && typeof entry[k] === "string") {
                                var normVal = root.normalizeSearchText(entry[k]);
                                for (var t2 = 0; t2 < terms.length; t2++) {
                                    if (normVal.indexOf(terms[t2]) !== -1) return true;
                                }
                            }
                        }
                    }
                }
            }
        }

        if (item.children && item.children.length > 0) {
            for (var c = 0; c < item.children.length; c++) {
                if (root.itemMatchesSearch(item.children[c], terms, d + 1)) {
                    return true;
                }
            }
        }

        return false;
    }

    function restoreTabItems(tabItem) {
        if (!tabItem) return;
        root.tabHasNoMatches = false;
        if (tabItem.searchQuery !== undefined) {
            tabItem.searchQuery = "";
        }
    }

    function applySearchFilter() {
        var activeLoader = root.getActiveTabLoader();
        if (!activeLoader) return;
        if (activeLoader.status === Loader.Loading) {
            flashTabTimer.restart();
            return;
        }
        if (!activeLoader.item) return;

        var tabItem = activeLoader.item;
        var rawQ = root.settingsSearchQuery.trim();
        if (rawQ === "") {
            root.restoreTabItems(tabItem);
            return;
        }

        var terms = root.getSearchTerms(rawQ);
        if (terms.length === 0) {
            root.restoreTabItems(tabItem);
            return;
        }

        if (tabItem.searchQuery !== undefined) {
            tabItem.searchQuery = rawQ;
        }

        var totalMatches = 0;
        root.firstMatchedCardY = -1;

        var children = tabItem.children || [];
        for (var i = 0; i < children.length; i++) {
            var child = children[i];
            if (!child || child.width === undefined) continue;

            var matches = root.itemMatchesSearch(child, terms);
            if (matches) {
                totalMatches++;
                if (typeof child.flash === "function") {
                    child.flash();
                }
                if (typeof child.collapsible !== "undefined" && child.collapsible && child.collapsed) {
                    child.collapsed = false;
                }
                if (root.firstMatchedCardY < 0 && typeof contentCol !== "undefined" && contentCol) {
                    try {
                        var mapCoord = child.mapToItem(contentCol, 0, 0);
                        if (mapCoord) root.firstMatchedCardY = mapCoord.y;
                    } catch(e) {}
                }
            }
        }

        root.tabHasNoMatches = (totalMatches === 0);

        if (root.firstMatchedCardY >= 0 && typeof contentFlickable !== "undefined" && contentFlickable) {
            var targetY = Math.max(0, Math.min(contentFlickable.contentHeight - contentFlickable.height, root.firstMatchedCardY - 20));
            contentFlickable.contentY = targetY;
        }
    }

    function getActiveTabLoader() {
        switch (root.currentTab) {
            case "general": return generalTabLoader;
            case "theme": return themeTabLoader;
            case "bar": return barTabLoader;
            case "windows": return windowsTabLoader;
            case "defaultapps": return appsTabLoader;
            case "monitors": return monitorsTabLoader;
            case "presets": return presetsTabLoader;
            case "apptheming": return appthemingTabLoader;
            case "gtk": return gtkTabLoader;
            case "launcher": return launcherTabLoader;
            case "notifications": return notificationsTabLoader;
            case "keyboard": return keyboardTabLoader;
            case "shortcuts": return shortcutsTabLoader;
            case "about": return aboutTabLoader;
            default: return null;
        }
    }

    property int paletteDisplayLimit: 36
    onPaletteSearchQueryChanged: paletteDisplayLimit = 36
    onSelectedCategoryChanged: paletteDisplayLimit = 36
    property string launcherAppSearchQuery: ""
    property string launcherAppFilter: "all"

    property string templateSearchQuery: ""
    property string templateCategoryFilter: "all"
    property var loadedTemplatesData: []
    readonly property string templatesJsonPath: (typeof Quickshell.shellPath === "function") ? Quickshell.shellPath("templates/templates.json") : (Quickshell.env("HOME") + "/.config/quickshell/templates/templates.json")

    readonly property var defaultTemplatesCatalog: [
        { "name": "Asura", "title": "Quickshell (Asura)", "desc": qsTr("Dynamic colors for shell bar, windows, and widgets"), "category": "desktop", "icon": "desktop_windows", "input": "quickshell/qs.json", "output": "~/.config/asura/colors.json" },
        { "name": "hyprland", "title": "Hyprland", "desc": qsTr("Color scheme and active/inactive borders for compositor"), "category": "desktop", "icon": "grid_view", "input": "hyprland/hyprland-colors.lua", "output": "~/.config/hypr/scheme/current.lua", "post_hook": "hyprctl reload" },
        { "name": "kitty", "title": "Kitty Terminal", "desc": qsTr("Color theme for Kitty terminal emulator"), "category": "terminal", "icon": "terminal", "input": "kitty/kitty-colors.conf", "output": "~/.config/kitty/themes/Asura.conf", "post_hook": "kitty +kitten themes --reload-in=all Asura" },
        { "name": "btop", "title": "Btop", "desc": qsTr("Resource and process system monitor"), "category": "terminal", "icon": "monitoring", "input": "btop/btop.theme", "output": "~/.config/btop/themes/Asura.theme", "post_hook": "pkill -USR2 btop || true" },
        { "name": "micro", "title": "Micro Editor", "desc": qsTr("Color scheme for Micro terminal text editor"), "category": "editor", "icon": "edit_note", "input": "micro/micro.micro", "output": "~/.config/micro/colorschemes/Asura.micro" },
        { "name": "starship", "title": "Starship Prompt", "desc": qsTr("Color scheme for Starship prompt"), "category": "terminal", "icon": "rocket_launch", "input": "starship/starship-colors.toml", "output": "~/.config/starship.toml" },
        { "name": "fish", "title": "Fish Shell", "desc": qsTr("Syntax and autocomplete colors for Fish shell"), "category": "terminal", "icon": "terminal", "input": "fish/fish-colors.fish", "output": "~/.config/fish/conf.d/material-colors.fish" },
        { "name": "fastfetch", "title": "Fastfetch", "desc": qsTr("Visual configuration for system overview"), "category": "terminal", "icon": "info", "input": "fastfetch/fastfetch.jsonc", "output": "~/.config/fastfetch/config.jsonc" },
        { "name": "flameshot", "title": "Flameshot", "desc": qsTr("Interface colors for screenshot capture tool"), "category": "apps", "icon": "photo_camera", "input": "flameshot/flameshot.ini", "output": "~/.config/flameshot/flameshot.ini" },
        { "name": "gtk3", "title": "GTK 3 (CSS)", "desc": qsTr("Global CSS styling for GTK 3 applications"), "category": "desktop", "icon": "palette", "input": "gtk/gtk-colors.css", "output": "~/.config/gtk-3.0/gtk.css", "post_hook": "gsettings set org.gnome.desktop.interface gtk-theme \"\"; gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-{{mode}}" },
        { "name": "gtk4", "title": "GTK 4 / Libadwaita", "desc": qsTr("Global CSS styling for GTK 4 / Libadwaita applications"), "category": "desktop", "icon": "palette", "input": "gtk/gtk-colors.css", "output": "~/.config/gtk-4.0/gtk.css", "post_hook": "{{script_dir}}/gtk-themes-reload.sh" },
        { "name": "vivaldi", "title": "Vivaldi Browser", "desc": qsTr("UI colors and CSS mods for Vivaldi browser"), "category": "apps", "icon": "language", "input": "vivaldi/vivaldi.css", "output": "~/.config/asura/vivaldi/vivaldi.css" },
        { "name": "vivaldi-compat", "title": "Vivaldi (Compat)", "desc": qsTr("Compatibility theme copy for Material extensions"), "category": "apps", "icon": "language", "input": "vivaldi/vivaldi.css", "output": "~/.config/matugen/vivaldi/vivaldi.css" },
        { "name": "vscode-raw", "title": "VS Code (Tokens)", "desc": qsTr("Raw color definitions for Visual Studio Code"), "category": "editor", "icon": "code", "input": "vscode/vscode-colors", "output": "~/.local/state/quickshell/user/generated/vscode-colors" },
        { "name": "vscode-json", "title": "VS Code (JSON)", "desc": qsTr("JSON theme scheme generated for Visual Studio Code"), "category": "editor", "icon": "code", "input": "vscode/vscode-colors.json", "output": "~/.local/state/quickshell/user/generated/vscode-colors.json" },
        { "name": "vscode-raw-compat", "title": "VS Code Raw (Cache)", "desc": qsTr("Compatibility tokens for Material extensions"), "category": "editor", "icon": "code", "input": "vscode/vscode-colors", "output": "~/.cache/matugen/vscode-colors" },
        { "name": "vscode-json-compat", "title": "VS Code JSON (Cache)", "desc": qsTr("Compatibility JSON scheme for Material extensions"), "category": "editor", "icon": "code", "input": "vscode/vscode-colors.json", "output": "~/.cache/matugen/vscode-colors.json" },
        { "name": "cava", "title": "Cava Audio", "desc": qsTr("Gradient colors for Cava audio visualizer"), "category": "apps", "icon": "graphic_eq", "input": "cava/cava-colors.ini", "output": "~/.config/cava/config", "post_hook": "pkill -USR2 cava || true" },
        { "name": "nvim", "title": "Neovim", "desc": qsTr("Vimscript/Lua colorscheme for Neovim editor"), "category": "editor", "icon": "code_blocks", "input": "nvim/nvim-colors.vim", "output": "~/.config/nvim/colors/asura.vim" }
    ]

    readonly property var allTemplatesList: {
        if (root.loadedTemplatesData && root.loadedTemplatesData.length > 0)
            return root.loadedTemplatesData;
        return root.defaultTemplatesCatalog;
    }

    readonly property var filteredTemplates: {
        var q = root.templateSearchQuery.trim().toLowerCase();
        var cat = root.templateCategoryFilter;
        return root.allTemplatesList.filter(function(tpl) {
            var disabled = root.isTemplateDisabled(tpl.name);
            var active = root.isTemplateActive(tpl.name);

            if (cat === "active" && !active) return false;
            if (cat === "disabled" && !disabled) return false;
            if (cat !== "all" && cat !== "active" && cat !== "disabled") {
                if ((tpl.category || "other") !== cat) return false;
            }

            if (q === "") return true;
            if (tpl.name && tpl.name.toLowerCase().indexOf(q) !== -1) return true;
            if (tpl.title && tpl.title.toLowerCase().indexOf(q) !== -1) return true;
            if (tpl.desc && tpl.desc.toLowerCase().indexOf(q) !== -1) return true;
            if (tpl.output && tpl.output.toLowerCase().indexOf(q) !== -1) return true;
            if (tpl.input && tpl.input.toLowerCase().indexOf(q) !== -1) return true;
            return false;
        });
    }

    readonly property int totalTemplatesCount: root.allTemplatesList.length
    readonly property int activeTemplatesCount: {
        var count = 0;
        for (var i = 0; i < root.allTemplatesList.length; i++) {
            if (root.isTemplateActive(root.allTemplatesList[i].name))
                count++;
        }
        return count;
    }
    readonly property int disabledTemplatesCount: totalTemplatesCount - activeTemplatesCount

    property var windowRootItem: windowContentWrapper
    property var widgetDragData: null
    property string widgetDragHoverZone: ""
    property int widgetDragHoverIndex: -1
    property real widgetDragX: 0
    property real widgetDragY: 0
    readonly property bool isDraggingWidget: widgetDragData !== null
    property var registeredZones: ({})

    function registerZoneCol(name, col) {
        var r = Object.assign({}, registeredZones);
        r[name] = col;
        registeredZones = r;
    }

    function startWidgetDrag(zone, index, id, name, icon, hasBackground, startX, startY) {
        widgetDragData = {
            "zone": zone,
            "index": index,
            "id": id,
            "name": name,
            "icon": icon,
            "hasBackground": hasBackground
        };
        widgetDragHoverZone = zone;
        widgetDragHoverIndex = index;
        widgetDragX = startX;
        widgetDragY = startY;
    }

    function updateWidgetDrag(posX, posY, targetZone, targetIndex) {
        if (!isDraggingWidget) return;
        widgetDragX = posX;
        widgetDragY = posY;
        if (targetZone !== undefined && targetZone !== "") {
            widgetDragHoverZone = targetZone;
        }
        if (targetIndex !== undefined && targetIndex >= 0) {
            widgetDragHoverIndex = targetIndex;
        }
    }

    function finishWidgetDrag() {
        if (isDraggingWidget && widgetDragHoverZone !== "" && widgetDragHoverIndex >= 0) {
            BarWidgetService.dropMove(
                widgetDragData.zone,
                widgetDragData.index,
                widgetDragData.id,
                widgetDragHoverZone,
                widgetDragHoverIndex
            );
        }
        widgetDragData = null;
        widgetDragHoverZone = "";
        widgetDragHoverIndex = -1;
    }

    function cancelWidgetDrag() {
        widgetDragData = null;
        widgetDragHoverZone = "";
        widgetDragHoverIndex = -1;
    }

    readonly property var displayedPalettes: {
        var base = (Colors.categories && Colors.categories[root.selectedCategory]) ? Colors.categories[root.selectedCategory] : Colors.availablePalettes;
        if (!base || !Array.isArray(base))
            return [];

        var query = root.paletteSearchQuery.trim().toLowerCase();
        var active = [];
        var pinned = [];
        var unpinned = [];
        var curTheme = (Config.cfg && Config.cfg.theme) ? Config.cfg.theme : "";
        var pinnedList = Colors.pinnedPalettes || [];
        for (var i = 0; i < base.length; i++) {
            var item = base[i];
            if (!item)
                continue;

            if (query !== "") {
                var nameMatch = item.name && item.name.toLowerCase().indexOf(query) !== -1;
                var idMatch = item.id && item.id.toLowerCase().indexOf(query) !== -1;
                if (!nameMatch && !idMatch)
                    continue;
            }
            if (item.id === curTheme)
                active.push(item);
            else if (Colors.isPinned(item.id))
                pinned.push(item);
            else
                unpinned.push(item);
        }
        return active.concat(pinned).concat(unpinned);
    }

    readonly property var visiblePalettes: displayedPalettes.slice(0, paletteDisplayLimit)

    function getTabProgress(idx) {
        if (introTabs >= 1)
            return 1;

        if (introTabs <= 0)
            return 0;

        let start = idx * 0.06;
        let p = Math.min(1, Math.max(0, (introTabs - start) / 0.42));
        if (p <= 0)
            return 0;

        if (p >= 1)
            return 1;

        let c1 = 0.85;
        let c3 = c1 + 1;
        return 1 + c3 * Math.pow(p - 1, 3) + c1 * Math.pow(p - 1, 2);
    }

    function getTabOpacity(idx) {
        if (introTabs >= 1)
            return 1;

        if (introTabs <= 0)
            return 0;

        let start = idx * 0.06;
        let p = Math.min(1, Math.max(0, (introTabs - start) / 0.28));
        return p;
    }

    function resetAndPlayIntro() {
        introBase = 0;
        introSidebar = 0;
        introTabs = 0;
        introContent = 0;
        startupSequence.restart();
    }

    function openWindow() {
        if (closeSequence.running)
            closeSequence.stop();

        // If isOpen got out of sync (e.g. killed externally via compositor WIN+Q),
        // reset the state so visibility and intro animations fire cleanly.
        if (root.isOpen && !root.visible) {
            root.isOpen = false;
        }

        root.visible = true;
        root.isOpen = true;
        focusTimer.restart();
        resetAndPlayIntro();
    }

    function closeWindow() {
        if (root.activeMonitorsTab && root.activeMonitorsTab.confirmationActive)
            root.activeMonitorsTab.revertToPreviousConfig();

        if (root.isOpen && !closeSequence.running)
            closeSequence.restart();

    }

    function openTab(tabName) {
        if (tabName && typeof tabName === "string" && tabName.length > 0) {
            root.currentTab = tabName;
        }
        openWindow();
    }

    function scrollTo(y) {
        if (typeof contentFlickable !== "undefined" && contentFlickable) {
            contentFlickable.contentY = y;
            contentFlickable.scrollTargetY = y;
        }
    }

    function setSearchQuery(q) {
        root.settingsSearchQuery = q || "";
        if (typeof settingsSearchInput !== "undefined" && settingsSearchInput) {
            settingsSearchInput.text = q || "";
        }
    }

    function openNwgLook() {
        nwgLookProc.running = false;
        nwgLookProc.running = true;
    }

    function refreshWallpapers() {
        if (!wpListProc.running)
            wpListProc.running = true;

    }

    function playTestSound() {
        var sound = Config.cfg.notificationSound || "message.oga";
        var soundPath = sound.startsWith("/") ? sound : ("/usr/share/sounds/freedesktop/stereo/" + sound);
        playSoundProc.command = ["paplay", soundPath];
        playSoundProc.running = false;
        playSoundProc.running = true;
    }

    property int launcherHiddenRevision: 0
    property int launcherAppsRevision: 0

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() {
            root.launcherAppsRevision++;
        }
    }

    function normalizeAppId(appId) {
        if (!appId)
            return "";
        return String(appId).trim().replace(/\.desktop$/i, "");
    }

    function isAppHidden(appId) {
        var _rev = root.launcherHiddenRevision;
        if (!appId)
            return false;
        var norm = root.normalizeAppId(appId);
        var list = (Config.cfg && Config.cfg.launcherHiddenApps && Array.isArray(Config.cfg.launcherHiddenApps))
            ? Config.cfg.launcherHiddenApps
            : [];
        for (var i = 0; i < list.length; i++) {
            if (root.normalizeAppId(list[i]) === norm)
                return true;
        }
        return false;
    }

    function toggleAppHidden(appId) {
        if (!appId)
            return;
        var norm = root.normalizeAppId(appId);
        var list = (Config.cfg && Config.cfg.launcherHiddenApps && Array.isArray(Config.cfg.launcherHiddenApps))
            ? Config.cfg.launcherHiddenApps.slice()
            : [];
        var exists = false;
        var newList = [];
        for (var i = 0; i < list.length; i++) {
            if (root.normalizeAppId(list[i]) === norm) {
                exists = true;
            } else {
                newList.push(list[i]);
            }
        }
        if (!exists) {
            newList.push(norm);
        }
        Config.cfg.launcherHiddenApps = newList;
        Config.save();
        root.launcherHiddenRevision++;
    }

    function unhideAllApps() {
        if (Config.cfg) {
            Config.cfg.launcherHiddenApps = [];
            Config.save();
            root.launcherHiddenRevision++;
        }
    }

    function getAppInfo(appId) {
        if (!appId)
            return { id: "", name: "", icon: "", genericName: "" };

        var norm = root.normalizeAppId(appId);

        if (typeof DesktopEntries !== "undefined" && DesktopEntries.byId) {
            var e1 = DesktopEntries.byId(appId);
            if (e1 && e1.name)
                return e1;
            var e1Norm = DesktopEntries.byId(norm);
            if (e1Norm && e1Norm.name)
                return e1Norm;
            var e1Desk = DesktopEntries.byId(norm + ".desktop");
            if (e1Desk && e1Desk.name)
                return e1Desk;
        }

        var all = root.launcherAllApps;
        if (all && all.length) {
            for (var i = 0; i < all.length; i++) {
                if (all[i].id === appId || root.normalizeAppId(all[i].id) === norm)
                    return all[i];
            }
        }

        if (typeof DesktopEntries !== "undefined" && DesktopEntries.heuristicLookup) {
            var e2 = DesktopEntries.heuristicLookup(appId) || DesktopEntries.heuristicLookup(norm);
            if (e2 && e2.name)
                return e2;
        }

        var niceName = norm.replace(/[-_.]/g, " ");
        niceName = niceName.charAt(0).toUpperCase() + niceName.slice(1);
        return {
            id: norm,
            name: niceName,
            icon: norm,
            genericName: norm
        };
    }

    readonly property var launcherAllApps: {
        var _rev = root.launcherAppsRevision;
        var raw = (DesktopEntries.applications && DesktopEntries.applications.values) ? DesktopEntries.applications.values : [];
        var arr = Array.from(raw);
        return arr.sort(function(a, b) {
            return (a.name || "").localeCompare(b.name || "");
        });
    }

    readonly property var launcherHiddenAppsList: {
        var _rev = root.launcherHiddenRevision;
        var _appsRev = root.launcherAppsRevision;
        var hiddenIds = (Config.cfg && Config.cfg.launcherHiddenApps && Array.isArray(Config.cfg.launcherHiddenApps))
            ? Config.cfg.launcherHiddenApps
            : [];
        var result = [];
        var seen = {};
        for (var i = 0; i < hiddenIds.length; i++) {
            var rawId = hiddenIds[i];
            var norm = root.normalizeAppId(rawId);
            if (!norm || seen[norm])
                continue;
            seen[norm] = true;
            var info = root.getAppInfo(rawId);
            result.push({
                id: norm,
                rawId: rawId,
                name: (info && info.name) ? info.name : norm,
                icon: (info && info.icon) ? info.icon : "",
                genericName: (info && info.genericName) ? info.genericName : ""
            });
        }
        result.sort(function(a, b) {
            return (a.name || "").localeCompare(b.name || "");
        });
        return result;
    }

    readonly property var launcherFilteredApps: {
        var _rev = root.launcherHiddenRevision;
        var _appsRev = root.launcherAppsRevision;
        var q = root.launcherAppSearchQuery.trim().toLowerCase();

        if (root.launcherAppFilter === "hidden") {
            return root.launcherHiddenAppsList.filter(function(app) {
                if (q === "")
                    return true;
                if ((app.name || "").toLowerCase().indexOf(q) !== -1)
                    return true;
                if (app.genericName && app.genericName.toLowerCase().indexOf(q) !== -1)
                    return true;
                if (app.id && app.id.toLowerCase().indexOf(q) !== -1)
                    return true;
                return false;
            });
        }

        return root.launcherAllApps.filter(function(app) {
            var isHidden = root.isAppHidden(app.id);
            if (root.launcherAppFilter === "visible" && isHidden)
                return false;
            if (q === "")
                return true;
            if ((app.name || "").toLowerCase().indexOf(q) !== -1)
                return true;
            if (app.genericName && app.genericName.toLowerCase().indexOf(q) !== -1)
                return true;
            if (app.id && app.id.toLowerCase().indexOf(q) !== -1)
                return true;
            return false;
        });
    }

    function isTemplateDisabled(tplName) {
        var list = (Config.cfg && Config.cfg.disabledTemplates && Array.isArray(Config.cfg.disabledTemplates))
            ? Config.cfg.disabledTemplates
            : [];
        return list.indexOf(tplName) !== -1;
    }

    function isTemplateActive(tplName) {
        if (!Config.cfg || Config.cfg.appThemingEnabled === false)
            return false;
        return !isTemplateDisabled(tplName);
    }

    function toggleTemplate(tplName) {
        var list = (Config.cfg && Config.cfg.disabledTemplates && Array.isArray(Config.cfg.disabledTemplates))
            ? Config.cfg.disabledTemplates.slice()
            : [];
        var idx = list.indexOf(tplName);
        if (idx !== -1) {
            list.splice(idx, 1);
        } else {
            list.push(tplName);
        }
        Config.cfg.disabledTemplates = list;
        Config.save();
    }

    function enableAllTemplates() {
        Config.cfg.disabledTemplates = [];
        Config.cfg.appThemingEnabled = true;
        Config.save();
    }

    function disableAllTemplates() {
        var all = [];
        for (var i = 0; i < root.allTemplatesList.length; i++) {
            all.push(root.allTemplatesList[i].name);
        }
        Config.cfg.disabledTemplates = all;
        Config.save();
    }

    function resetTemplatesDefault() {
        Config.cfg.disabledTemplates = [];
        Config.cfg.appThemingEnabled = true;
        Config.save();
    }

    function applyTemplatesNow() {
        applyTemplatesProc.running = false;
        applyTemplatesProc.running = true;
        if (Config.cfg && Config.cfg.theme) {
            Colors.loadPalette(Config.cfg.theme);
        }
    }

    function resetDefaults() {
        Config.cfg.theme = "primer-dark-dimmed";
        Config.cfg.colorsAutoGenerate = true;
        Config.cfg.isDarkMode = true;
        Config.cfg.appThemingEnabled = true;
        Config.cfg.disabledTemplates = [];
        Config.cfg.barMode = 0;
        Config.cfg.exclusiveMode = true;
        Config.cfg.autoHide = false;
        Config.cfg.opacity = 0.85;
        Config.cfg.widthS = 0.85;
        Config.cfg.wallpaperFolder = "/Pictures/Wallpapers";
        Config.cfg.soundEffects = true;
        Config.cfg.alertsPopups = true;
        Config.cfg.notificationSound = "message.oga";
        Config.cfg.workspacesCount = 3;
        Config.cfg.workspacesShowNumbers = true;
        Config.cfg.workspacesNumberStyle = "roman";
        Config.cfg.barEdgeSpacing = 10;
        Config.cfg.barCapsulePadding = 6;
        Config.cfg.barWidgetSpacing = 4;
        Config.cfg.barCapsuleWidgetSpacing = 2;
        Config.cfg.recordingsFolder = "~/Videos/Recordings";
        Config.save();
        Colors.loadPalette("primer-dark-dimmed");
    }

    title: "Shell Settings"
    implicitWidth: 1200
    implicitHeight: 700
    color: Colors.cfg.base00
    visible: isOpen

    onClosed: {
        root.isOpen = false;
        root.visible = false;
        SettingsService.forceClose();
    }

    onVisibleChanged: {
        if (!visible && root.isOpen) {
            root.isOpen = false;
            SettingsService.forceClose();
        }
    }

    Component.onCompleted: {
        root.isOpen = true;
        root.visible = true;
        SettingsService.activeWindow = root;
        if (SettingsService.currentTab) {
            root.currentTab = SettingsService.currentTab;
        }
        if (SettingsService.pendingKeyRecorder) {
            SettingsService.pendingKeyRecorder = false;
            root.openKeyRecorder({
                id: "new",
                label: "Custom Hotkey",
                chord: "SUPER + ALT + K",
                action: "exec",
                value: "kitty",
                isCustom: true
            });
        }
        refreshWallpapers();
        loadTemplatesProc.running = true;
        focusTimer.restart();
        resetAndPlayIntro();
    }

    Component.onDestruction: {
        if (SettingsService.activeWindow === root) {
            SettingsService.activeWindow = null;
        }
        SettingsService.forceClose();
        wpListProc.running = false;
        reloadShellProc.running = false;
        nwgLookProc.running = false;
        importWpProc.running = false;
        selectFolderProc.running = false;
        selectRecordingsFolderProc.running = false;
        loadTemplatesProc.running = false;
        applyTemplatesProc.running = false;
    }

    onIsOpenChanged: {
        root.visible = root.isOpen;
        if (isOpen) {
            focusTimer.restart();
            resetAndPlayIntro();
        } else {
            startupSequence.stop();
            closeSequence.stop();
            introBase = 0;
            introSidebar = 0;
            introTabs = 0;
            introContent = 0;
        }
    }
    onCurrentTabChanged: {
        if (typeof contentFlickable !== "undefined" && contentFlickable)
            contentFlickable.contentY = 0;

        if (typeof tabSwitchAnim !== "undefined" && tabSwitchAnim)
            tabSwitchAnim.restart();

        if (typeof tabSlideAnim !== "undefined" && tabSlideAnim)
            tabSlideAnim.restart();

        if (typeof navRailFlickable !== "undefined" && navRailFlickable && typeof activeHighlight !== "undefined" && activeHighlight && activeHighlight.activeIndex >= 0) {
            var targetItemY = activeHighlight.activeIndex * (52 + tabsCol.spacing);
            if (targetItemY < navRailFlickable.contentY) {
                navRailFlickable.contentY = targetItemY;
            } else if (targetItemY + 52 > navRailFlickable.contentY + navRailFlickable.height) {
                navRailFlickable.contentY = Math.max(0, targetItemY + 52 - navRailFlickable.height);
            }
        }

        if (root.settingsSearchQuery.trim() !== "") {
            flashTabTimer.restart();
        } else {
            root.tabHasNoMatches = false;
            var activeL = root.getActiveTabLoader();
            if (activeL && activeL.item && activeL.item.searchQuery !== undefined) {
                activeL.item.searchQuery = "";
            }
        }
    }

    Timer {
        id: focusTimer

        interval: 50
        repeat: false
        onTriggered: {
            if (typeof windowContentWrapper !== "undefined" && windowContentWrapper)
                windowContentWrapper.forceActiveFocus();

        }
    }

    ParallelAnimation {
        id: startupSequence

        running: false

        NumberAnimation {
            target: root
            property: "introBase"
            from: 0
            to: 1
            duration: 650
            easing.type: Easing.OutExpo
        }

        SequentialAnimation {
            PauseAnimation {
                duration: 60
            }

            NumberAnimation {
                target: root
                property: "introSidebar"
                from: 0
                to: 1
                duration: 400
                easing.type: Easing.OutCubic
            }

        }

        SequentialAnimation {
            PauseAnimation {
                duration: 100
            }

            NumberAnimation {
                target: root
                property: "introTabs"
                from: 0
                to: 1
                duration: 550
                easing.type: Easing.Linear
            }

        }

        SequentialAnimation {
            PauseAnimation {
                duration: 180
            }

            NumberAnimation {
                target: root
                property: "introContent"
                from: 0
                to: 1
                duration: 650
                easing.type: Easing.OutCubic
            }

        }

    }

    SequentialAnimation {
        id: closeSequence

        running: false

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "introContent"
                to: 0
                duration: 150
                easing.type: Easing.InExpo
            }

            NumberAnimation {
                target: root
                property: "introSidebar"
                to: 0
                duration: 150
                easing.type: Easing.InExpo
            }

            NumberAnimation {
                target: root
                property: "introTabs"
                to: 0
                duration: 120
                easing.type: Easing.InQuad
            }

        }

        NumberAnimation {
            target: root
            property: "introBase"
            to: 0
            duration: 200
            easing.type: Easing.InQuart
        }

        ScriptAction {
            script: {
                root.isOpen = false;
                root.visible = false;
                SettingsService.forceClose();
            }
        }

    }

    WallpaperService {
        id: wallpaperService
    }

    Process {
        id: reloadShellProc

        command: ["quickshell", "ipc", "call", "settings", "reload"]
        onExited: (exitCode) => {
            root.showToast(qsTr("Quickshell reloaded"), "refresh");
        }
    }

    Process {
        id: playSoundProc

        command: []
    }

    Process {
        id: nwgLookProc

        command: ["nwg-look"]
    }

    Process {
        id: loadTemplatesProc

        command: ["cat", root.templatesJsonPath]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "")
                    return;
                try {
                    var data = JSON.parse(text.trim());
                    if (data && Array.isArray(data.templates))
                        root.loadedTemplatesData = data.templates;
                } catch (e) {
                    console.warn("SettingsWindow: Error parsing templates.json:", e);
                }
            }
        }
    }

    Process {
        id: applyTemplatesProc

        property bool feedbackActive: false
        command: ["/usr/bin/bash", (typeof Quickshell.shellPath === "function") ? Quickshell.shellPath("scripts/colors/switchwall.sh") : (Quickshell.env("HOME") + "/.config/quickshell/scripts/colors/switchwall.sh")]
        running: false

        onExited: (code) => {
            applyTemplatesProc.feedbackActive = true;
            applyFeedbackTimer.restart();
        }
    }

    Timer {
        id: applyFeedbackTimer

        interval: 2500
        repeat: false
        onTriggered: applyTemplatesProc.feedbackActive = false
    }

    Process {
        id: wpListProc

        command: ["python3", Quickshell.shellPath ? Quickshell.shellPath("Services/wallpaper_list.py") : (Quickshell.env("HOME") + "/.config/quickshell/Services/wallpaper_list.py"), Config.cfg.wallpaperFolder]

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "")
                    return ;

                try {
                    var data = JSON.parse(text.trim());
                    if (Array.isArray(data.wallpapers))
                        root.availableWallpapers = data.wallpapers;

                } catch (e) {
                    console.warn("Error parsing wallpapers:", e);
                }
            }
        }

    }

    Process {
        id: importWpProc

        command: ["zenity", "--file-selection", "--title=Select Wallpaper", "--file-filter=Images | *.jpg *.jpeg *.png *.webp *.bmp *.svg"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "")
                    return ;

                var chosenPath = text.trim();
                Config.cfg.wallpaper = chosenPath;
                Config.save();
                if (Config.cfg.colorsAutoGenerate)
                    Colors.generateDynamicColors(chosenPath, Config.cfg.isDarkMode, Config.cfg.scheme);

                root.refreshWallpapers();
            }
        }

    }

    Process {
        id: selectFolderProc

        command: ["zenity", "--file-selection", "--directory", "--title=Select Wallpaper Folder"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "")
                    return ;

                var folderPath = text.trim();
                var home = Quickshell.env("HOME");
                if (folderPath.startsWith(home))
                    folderPath = folderPath.substring(home.length);

                Config.cfg.wallpaperFolder = folderPath;
                Config.save();
                root.refreshWallpapers();
            }
        }

    }

    Process {
        id: selectRecordingsFolderProc

        command: ["zenity", "--file-selection", "--directory", "--title=Select Screen Recordings Folder"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "")
                    return ;

                var folderPath = text.trim();
                var home = Quickshell.env("HOME");
                if (folderPath.startsWith(home))
                    folderPath = "~" + folderPath.substring(home.length);

                Config.cfg.recordingsFolder = folderPath;
                Config.save();
            }
        }

    }

    Item {
        id: windowContentWrapper

        anchors.fill: parent
        focus: true
        opacity: root.introBase
        scale: 0.95 + (0.05 * root.introBase)
        Keys.onEscapePressed: (event) => {
            if (root.activeMonitorsTab && root.activeMonitorsTab.confirmationActive) {
                root.activeMonitorsTab.revertToPreviousConfig();
                event.accepted = true;
                return;
            }
            if (root.showWidgetConfigModal) {
                root.closeWidgetConfigModal();
                event.accepted = true;
                return;
            }
            if (root.showWallpaperPickerModal) {
                root.closeWallpaperPicker();
                event.accepted = true;
                return;
            }
            if (root.activeAppsTab && root.activeAppsTab.activePickerCategory !== null) {
                root.activeAppsTab.closeAppPicker();
                event.accepted = true;
                return;
            }
            root.closeWindow();
            event.accepted = true;
        }
        Keys.onPressed: (event) => {
            if (root.activeMonitorsTab && root.activeMonitorsTab.confirmationActive) {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.activeMonitorsTab.confirmChanges();
                    event.accepted = true;
                    return;
                }
            }
            if (event.modifiers === Qt.ControlModifier) {
                if (event.key === Qt.Key_F) {
                    settingsSearchInput.forceActiveFocus();
                    settingsSearchInput.selectAll();
                    event.accepted = true;
                    return;
                }

                var currIdx = root.tabOrder.indexOf(root.currentTab);
                if (currIdx === -1)
                    currIdx = 0;

                if (event.key === Qt.Key_PageDown || event.key === Qt.Key_Tab) {
                    root.currentTab = root.tabOrder[(currIdx + 1) % root.tabOrder.length];
                    event.accepted = true;
                } else if (event.key === Qt.Key_PageUp || event.key === Qt.Key_Backtab) {
                    root.currentTab = root.tabOrder[(currIdx - 1 + root.tabOrder.length) % root.tabOrder.length];
                    event.accepted = true;
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: root.background

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        spacing: 12

                        Rectangle {
                            implicitWidth: 36
                            implicitHeight: 36
                            radius: 10
                            color: Qt.alpha(root.color1, 0.15)
                            border.color: Qt.alpha(root.color1, 0.35)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "settings"
                                font.pixelSize: 22
                                font.family: "Material Symbols Rounded"
                                color: root.color1
                            }
                        }

                        ColumnLayout {
                            spacing: 1

                            Text {
                                text: qsTr("Settings")
                                font.pixelSize: 16
                                font.bold: true
                                font.family: "Google Sans"
                                color: root.textBright
                            }

                            Text {
                                text: qsTr("Asura Shell Configuration")
                                font.pixelSize: 12
                                font.family: "Google Sans"
                                color: root.textMuted
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            implicitWidth: 36
                            implicitHeight: 36
                            radius: 18
                            color: winCloseH.hovered ? Qt.alpha(Colors.cfg.warning, 0.22) : (winCloseMa.pressed ? Qt.alpha(root.textColor, 0.12) : Qt.alpha(root.textColor, 0.06))
                            border.color: winCloseH.hovered ? Qt.alpha(Colors.cfg.warning, 0.4) : Qt.alpha(root.borderCol, 0.3)
                            border.width: 1
                            scale: winCloseMa.pressed ? 0.90 : (winCloseH.hovered ? 1.08 : 1)

                            Text {
                                anchors.centerIn: parent
                                text: "close"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 18
                                color: winCloseH.hovered ? Colors.cfg.warning : root.textBright
                                rotation: winCloseH.hovered ? 90 : 0

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }

                                Behavior on rotation {
                                    NumberAnimation {
                                        duration: 240
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            HoverHandler {
                                id: winCloseH
                            }

                            MouseArea {
                                id: winCloseMa

                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.closeWindow()
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }

                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                    }

                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 10

                    Rectangle {
                        id: navRailCard

                        Layout.fillHeight: true
                        Layout.preferredWidth: 240
                        radius: 18
                        color: root.surface
                        border.color: Qt.alpha(root.borderCol, 0.35)
                        border.width: 1
                        clip: true
                        opacity: root.introSidebar

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            Rectangle {
                                id: fabConfig

                                property bool justCopied: false

                                Layout.fillWidth: true
                                Layout.preferredHeight: 56
                                radius: 14
                                color: fabH.hovered ? Qt.alpha(root.color1, 0.18) : Qt.alpha(root.color1, 0.1)
                                border.color: fabConfig.justCopied ? Colors.cfg.success : Qt.alpha(root.color1, fabH.hovered ? 0.4 : 0.22)
                                border.width: 1
                                scale: fabMa.pressed ? 0.96 : (fabH.hovered ? 1.02 : 1.0)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 10

                                    Rectangle {
                                        implicitWidth: 36
                                        implicitHeight: 36
                                        radius: 10
                                        color: root.color1
                                        scale: fabH.hovered ? 1.08 : 1.0

                                        Behavior on scale {
                                            NumberAnimation {
                                                duration: 180
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: fabConfig.justCopied ? "check" : "folder"
                                            font.pixelSize: 20
                                            font.family: "Material Symbols Rounded"
                                            color: root.foreground
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            text: fabConfig.justCopied ? qsTr("Path Copied!") : qsTr("Config files")
                                            font.pixelSize: 13
                                            font.bold: true
                                            font.family: "Google Sans"
                                            color: root.textBright
                                        }

                                        Text {
                                            text: fabConfig.justCopied ? qsTr("Path in clipboard") : qsTr("Left: open | Right: copy")
                                            font.pixelSize: 11
                                            font.family: "Google Sans"
                                            color: root.textMuted
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }
                                }

                                Timer {
                                    id: revertFabTimer

                                    interval: 1600
                                    onTriggered: fabConfig.justCopied = false
                                }

                                HoverHandler {
                                    id: fabH
                                }

                                MouseArea {
                                    id: fabMa

                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.RightButton) {
                                            Quickshell.clipboardText = root.configDirPath;
                                            fabConfig.justCopied = true;
                                            revertFabTimer.restart();
                                        } else {
                                            Qt.openUrlExternally("file://" + root.configDirPath);
                                        }
                                    }
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }

                                }

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 150
                                    }

                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 150
                                        easing.type: Easing.OutCubic
                                    }

                                }

                            }

                            SettingDivider {}

                            Rectangle {
                                id: searchBoxRect
                                Layout.fillWidth: true
                                implicitHeight: 38
                                radius: 10
                                color: root.surfaceContainer
                                border.color: settingsSearchInput.activeFocus ? root.color1 : Qt.alpha(root.borderCol, 0.3)
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Text {
                                        text: "search"
                                        font.pixelSize: 18
                                        font.family: "Material Symbols Rounded"
                                        color: settingsSearchInput.activeFocus ? root.color1 : root.textMuted
                                    }

                                    TextInput {
                                        id: settingsSearchInput
                                        Layout.fillWidth: true
                                        font.pixelSize: 13
                                        font.family: "Google Sans"
                                        color: root.textColor
                                        clip: true
                                        selectByMouse: true
                                        text: root.settingsSearchQuery
                                        onTextChanged: root.settingsSearchQuery = text
                                        onAccepted: {
                                            if (root.visibleSettingsTabs.length > 0) {
                                                root.currentTab = root.visibleSettingsTabs[0].id;
                                                flashTabTimer.restart();
                                            }
                                        }

                                        Text {
                                            text: qsTr("Search settings (Ctrl+F)...")
                                            font.pixelSize: 13
                                            font.family: "Google Sans"
                                            color: Qt.alpha(root.textMuted, 0.65)
                                            visible: parent.text === "" && !parent.activeFocus
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    Rectangle {
                                        visible: root.settingsSearchQuery !== ""
                                        implicitWidth: 18
                                        implicitHeight: 18
                                        radius: 9
                                        color: searchClearMa.containsMouse ? Qt.alpha(root.textColor, 0.22) : Qt.alpha(root.textColor, 0.12)
                                        scale: searchClearMa.pressed ? 0.88 : (searchClearMa.containsMouse ? 1.1 : 1.0)

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 150
                                            }
                                        }

                                        Behavior on scale {
                                            NumberAnimation {
                                                duration: 150
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "close"
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 12
                                            color: searchClearMa.containsMouse ? root.textBright : root.textMuted
                                        }

                                        MouseArea {
                                            id: searchClearMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.settingsSearchQuery = "";
                                                settingsSearchInput.text = "";
                                            }
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Repeater {
                                    model: [
                                        { "id": "all", "label": qsTr("All") },
                                        { "id": "appearance", "label": qsTr("Look") },
                                        { "id": "desktop", "label": qsTr("Desk") },
                                        { "id": "system", "label": qsTr("Sys") }
                                    ]

                                    Rectangle {
                                        id: catChip
                                        required property var modelData
                                        readonly property bool isSelected: root.selectedTabCategory === modelData.id
                                        Layout.fillWidth: true
                                        implicitHeight: 28
                                        radius: 9
                                        color: isSelected ? Qt.alpha(root.color1, catChipMa.containsMouse ? 0.30 : 0.22) : (catChipMa.containsMouse ? Qt.alpha(root.textColor, 0.10) : root.surfaceContainer)
                                        border.color: isSelected ? root.color1 : (catChipMa.containsMouse ? Qt.alpha(root.borderCol, 0.5) : Qt.alpha(root.borderCol, 0.25))
                                        border.width: 1
                                        scale: catChipMa.pressed ? 0.94 : (catChipMa.containsMouse ? 1.04 : 1.0)

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 160
                                            }
                                        }

                                        Behavior on border.color {
                                            ColorAnimation {
                                                duration: 160
                                            }
                                        }

                                        Behavior on scale {
                                            NumberAnimation {
                                                duration: 150
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: catChip.modelData.label
                                            font.pixelSize: 11
                                            font.bold: catChip.isSelected
                                            font.family: "Google Sans"
                                            color: catChip.isSelected ? root.color1 : (catChipMa.containsMouse ? root.textBright : root.textMuted)

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 160
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: catChipMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.selectedTabCategory = catChip.modelData.id;
                                            }
                                        }
                                    }
                                }
                            }

                            Flickable {
                                id: navRailFlickable
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                contentHeight: tabsColContainer.implicitHeight
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds
                                maximumFlickVelocity: 4000
                                flickDeceleration: 1500

                                property real scrollTargetY: contentY

                                Behavior on contentY {
                                    NumberAnimation {
                                        id: navScrollAnim
                                        duration: 180
                                        easing.type: Easing.OutQuad
                                    }
                                }

                                WheelHandler {
                                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                    onWheel: (event) => {
                                        var delta = event.angleDelta.y;
                                        if (delta === 0)
                                            return;
                                        var step = (delta / 120) * 100;
                                        var maxY = Math.max(0, navRailFlickable.contentHeight - navRailFlickable.height);
                                        var base = navScrollAnim.running ? navRailFlickable.scrollTargetY : navRailFlickable.contentY;
                                        var target = Math.max(0, Math.min(maxY, base - step));
                                        navRailFlickable.scrollTargetY = target;
                                        navRailFlickable.contentY = target;
                                    }
                                }

                                onContentYChanged: {
                                    if (!navScrollAnim.running)
                                        scrollTargetY = contentY;
                                }

                                Item {
                                    id: tabsColContainer
                                    width: navRailFlickable.width
                                    implicitHeight: tabsCol.implicitHeight

                                    Rectangle {
                                        id: activeHighlight

                                        readonly property int activeIndex: {
                                            for (var i = 0; i < root.visibleSettingsTabs.length; ++i) {
                                                if (root.visibleSettingsTabs[i].id === root.currentTab)
                                                    return i;
                                            }
                                            return -1;
                                        }

                                        z: 0
                                        radius: 14
                                        color: root.color1
                                        width: parent.width
                                        height: 52
                                        y: activeIndex >= 0 ? activeIndex * (52 + tabsCol.spacing) : -100
                                        visible: activeIndex >= 0
                                        opacity: (root.introTabs > 0.05 && activeIndex >= 0) ? 1 : 0

                                        transform: Translate {
                                            x: -24 * (1 - root.getTabProgress(activeHighlight.activeIndex >= 0 ? activeHighlight.activeIndex : 0))
                                        }

                                        Behavior on y {
                                            NumberAnimation {
                                                duration: 280
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 180
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        id: tabsCol

                                        anchors.fill: parent
                                        spacing: 8
                                        z: 1

                                        Repeater {
                                            model: root.visibleSettingsTabs

                                            Rectangle {
                                                id: tabItemDelegate

                                                required property var modelData
                                                required property int index
                                                readonly property bool isActive: root.currentTab === modelData.id

                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 52
                                                radius: 14
                                                opacity: root.getTabOpacity(index)
                                                color: tabMaItem.containsMouse && !isActive ? Qt.alpha(root.textColor, 0.06) : "transparent"
                                                scale: tabMaItem.pressed ? 0.96 : (tabMaItem.containsMouse && !isActive ? 1.01 : 1)

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 12
                                                    anchors.rightMargin: 12
                                                    spacing: 12

                                                    Rectangle {
                                                        implicitWidth: 34
                                                        implicitHeight: 34
                                                        radius: 10
                                                        color: tabItemDelegate.isActive ? Qt.alpha(root.foreground, 0.18) : (tabMaItem.containsMouse ? Qt.alpha(root.color1, 0.15) : Qt.alpha(root.textColor, 0.06))

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: tabItemDelegate.modelData.icon
                                                            font.pixelSize: 20
                                                            font.family: "Material Symbols Rounded"
                                                            color: tabItemDelegate.isActive ? root.foreground : (tabMaItem.containsMouse ? root.color1 : root.textBright)

                                                            Behavior on color {
                                                                ColorAnimation { duration: 150 }
                                                            }
                                                        }

                                                        Behavior on color {
                                                            ColorAnimation { duration: 150 }
                                                        }
                                                    }

                                                    ColumnLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 1

                                                        Text {
                                                            text: tabItemDelegate.modelData.name
                                                            font.pixelSize: 14
                                                            font.bold: true
                                                            font.family: "Google Sans"
                                                            color: tabItemDelegate.isActive ? root.foreground : (tabMaItem.containsMouse ? root.textBright : root.textColor)

                                                            Behavior on color {
                                                                ColorAnimation { duration: 150 }
                                                            }
                                                        }

                                                        Text {
                                                            text: tabItemDelegate.modelData.desc
                                                            font.pixelSize: 11
                                                            font.family: "Google Sans"
                                                            color: tabItemDelegate.isActive ? Qt.alpha(root.foreground, 0.75) : root.textMuted
                                                            Layout.fillWidth: true
                                                            elide: Text.ElideRight

                                                            Behavior on color {
                                                                ColorAnimation { duration: 150 }
                                                            }
                                                        }
                                                    }
                                                }

                                                MouseArea {
                                                    id: tabMaItem

                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        root.currentTab = tabItemDelegate.modelData.id;
                                                        if (root.settingsSearchQuery.trim() !== "") {
                                                            flashTabTimer.restart();
                                                        }
                                                    }
                                                }

                                                transform: Translate {
                                                    x: -24 * (1 - root.getTabProgress(tabItemDelegate.index))
                                                }

                                                Behavior on color {
                                                    ColorAnimation { duration: 150 }
                                                }

                                                Behavior on scale {
                                                    NumberAnimation { duration: 200; easing.type: Easing.OutQuint }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        transform: Translate {
                            x: -30 * (1 - root.introSidebar)
                        }

                    }

                    Rectangle {
                        id: contentContainerCard

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 18
                        color: root.surfaceContainer
                        border.color: Qt.alpha(root.borderCol, 0.35)
                        border.width: 1
                        clip: true
                        opacity: root.introContent
                        scale: 0.98 + (0.02 * root.introContent)

                        Flickable {
                            id: contentFlickable

                            anchors.fill: parent
                            anchors.margins: 20
                            contentHeight: contentCol.implicitHeight
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            maximumFlickVelocity: 4000
                            flickDeceleration: 1500

                            property real scrollTargetY: contentY

                            Behavior on contentY {
                                NumberAnimation {
                                    id: scrollAnim
                                    duration: 180
                                    easing.type: Easing.OutQuad
                                }
                            }

                            WheelHandler {
                                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                onWheel: (event) => {
                                    var delta = event.angleDelta.y;
                                    if (delta === 0)
                                        return;
                                    var step = (delta / 120) * 120;
                                    var maxY = Math.max(0, contentFlickable.contentHeight - contentFlickable.height);
                                    var base = scrollAnim.running ? contentFlickable.scrollTargetY : contentFlickable.contentY;
                                    var target = Math.max(0, Math.min(maxY, base - step));
                                    contentFlickable.scrollTargetY = target;
                                    contentFlickable.contentY = target;
                                }
                            }

                            onContentYChanged: {
                                if (!scrollAnim.running)
                                    scrollTargetY = contentY;
                                if (root.currentTab === "theme" && contentY + height >= contentHeight - 400) {
                                    if (root.paletteDisplayLimit < root.displayedPalettes.length) {
                                        root.paletteDisplayLimit += 36;
                                    }
                                }
                            }

                            ColumnLayout {

                                id: contentCol

                                width: parent.width
                                spacing: 20
                                opacity: 1

                                NumberAnimation {
                                    id: tabSwitchAnim

                                    target: contentCol
                                    property: "opacity"
                                    from: 0
                                    to: 1
                                    duration: 240
                                    easing.type: Easing.OutCubic
                                }

                                NumberAnimation {
                                    id: tabSlideAnim

                                    target: tabTranslate
                                    property: "y"
                                    from: 14
                                    to: 0
                                    duration: 250
                                    easing.type: Easing.OutCubic
                                }

                                Component { id: generalTabComp; GeneralTab { settingsRoot: settingsWindowRoot } }
                                Component { id: themeTabComp; ThemeTab { settingsRoot: settingsWindowRoot } }
                                Component { id: barTabComp; BarTab { settingsRoot: settingsWindowRoot } }
                                Component { id: windowsTabComp; WindowsTab { settingsRoot: settingsWindowRoot } }
                                Component { id: appsTabComp; AppsTab { settingsRoot: settingsWindowRoot } }
                                Component { id: monitorsTabComp; MonitorsTab { settingsRoot: settingsWindowRoot } }
                                Component { id: presetsTabComp; PresetsTab { settingsRoot: settingsWindowRoot } }
                                Component { id: appthemingTabComp; AppThemingTab { settingsRoot: settingsWindowRoot } }
                                Component { id: gtkTabComp; GtkTab { settingsRoot: settingsWindowRoot } }
                                Component { id: launcherTabComp; LauncherTab { settingsRoot: settingsWindowRoot } }
                                Component { id: notificationsTabComp; NotificationsTab { settingsRoot: settingsWindowRoot } }
                                Component { id: keyboardTabComp; KeyboardTab { settingsRoot: settingsWindowRoot } }
                                Component { id: shortcutsTabComp; ShortcutsTab { settingsRoot: settingsWindowRoot } }
                                Component { id: aboutTabComp; AboutTab { settingsRoot: settingsWindowRoot } }

                                Loader {
                                    id: generalTabLoader
                                    Layout.fillWidth: true
                                    active: root.currentTab === "general" || loadedOnce
                                    property bool loadedOnce: root.currentTab === "general"
                                    onActiveChanged: if (active) loadedOnce = true
                                    visible: root.currentTab === "general"
                                    sourceComponent: (active ? generalTabComp : null)
                                    onLoaded: {
                                        if (visible && root.settingsSearchQuery.trim() !== "") {
                                            flashTabTimer.restart();
                                        }
                                    }
                                }

                                Loader {
                                    id: themeTabLoader
                                    Layout.fillWidth: true
                                    active: root.currentTab === "theme" || loadedOnce
                                    property bool loadedOnce: false
                                    onActiveChanged: if (active) loadedOnce = true
                                    visible: root.currentTab === "theme"
                                    sourceComponent: (active ? themeTabComp : null)
                                    onLoaded: {
                                        if (visible && root.settingsSearchQuery.trim() !== "") {
                                            flashTabTimer.restart();
                                        }
                                    }
                                }

                                Loader {
                                    id: barTabLoader
                                    Layout.fillWidth: true
                                    active: root.currentTab === "bar" || loadedOnce
                                    property bool loadedOnce: false
                                    onActiveChanged: if (active) loadedOnce = true
                                    visible: root.currentTab === "bar"
                                    sourceComponent: (active ? barTabComp : null)
                                    onLoaded: {
                                        if (visible && root.settingsSearchQuery.trim() !== "") {
                                            flashTabTimer.restart();
                                        }
                                    }
                                }

                                Loader {
                                    id: windowsTabLoader
                                    Layout.fillWidth: true
                                    active: root.currentTab === "windows" || loadedOnce
                                    property bool loadedOnce: false
                                    onActiveChanged: if (active) loadedOnce = true
                                    visible: root.currentTab === "windows"
                                    sourceComponent: (active ? windowsTabComp : null)
                                    onLoaded: {
                                        if (visible && root.settingsSearchQuery.trim() !== "") {
                                            flashTabTimer.restart();
                                        }
                                    }
                                }

                                Loader {
                                    id: appsTabLoader
                                    Layout.fillWidth: true
                                    active: root.currentTab === "defaultapps" || loadedOnce
                                    property bool loadedOnce: false
                                    onActiveChanged: if (active) loadedOnce = true
                                    visible: root.currentTab === "defaultapps"
                                    sourceComponent: (active ? appsTabComp : null)
                                    onLoaded: {
                                        if (visible && root.settingsSearchQuery.trim() !== "") {
                                            flashTabTimer.restart();
                                        }
                                    }
                                }

                                Loader {
                                    id: monitorsTabLoader
                                    Layout.fillWidth: true
                                    active: root.currentTab === "monitors" || loadedOnce
                                    property bool loadedOnce: false
                                    onActiveChanged: if (active) loadedOnce = true
                                    visible: root.currentTab === "monitors"
                                    sourceComponent: (active ? monitorsTabComp : null)
                                    onLoaded: {
                                        if (visible && root.settingsSearchQuery.trim() !== "") {
                                            flashTabTimer.restart();
                                        }
                                    }
                                }

                                Loader {
                                    id: presetsTabLoader
                                    Layout.fillWidth: true
                                    active: root.currentTab === "presets" || loadedOnce
                                    property bool loadedOnce: false
                                    onActiveChanged: if (active) loadedOnce = true
                                    visible: root.currentTab === "presets"
                                    sourceComponent: (active ? presetsTabComp : null)
                                    onLoaded: {
                                        if (visible && root.settingsSearchQuery.trim() !== "") {
                                            flashTabTimer.restart();
                                        }
                                    }
                                }

                                Loader {
                                    id: appthemingTabLoader
                                    Layout.fillWidth: true
                                    active: root.currentTab === "apptheming" || loadedOnce
                                    property bool loadedOnce: false
                                    onActiveChanged: if (active) loadedOnce = true
                                    visible: root.currentTab === "apptheming"
                                    sourceComponent: (active ? appthemingTabComp : null)
                                    onLoaded: {
                                        if (visible && root.settingsSearchQuery.trim() !== "") {
                                            flashTabTimer.restart();
                                        }
                                    }
                                }

                                Loader {
                                    id: gtkTabLoader
                                    Layout.fillWidth: true
                                    active: root.currentTab === "gtk" || loadedOnce
                                    property bool loadedOnce: false
                                    onActiveChanged: if (active) loadedOnce = true
                                    visible: root.currentTab === "gtk"
                                    sourceComponent: (active ? gtkTabComp : null)
                                    onLoaded: {
                                        if (visible && root.settingsSearchQuery.trim() !== "") {
                                            flashTabTimer.restart();
                                        }
                                    }
                                }

                                Loader {
                                    id: launcherTabLoader
                                    Layout.fillWidth: true
                                    active: root.currentTab === "launcher" || loadedOnce
                                    property bool loadedOnce: false
                                    onActiveChanged: if (active) loadedOnce = true
                                    visible: root.currentTab === "launcher"
                                    sourceComponent: (active ? launcherTabComp : null)
                                    onLoaded: {
                                        if (visible && root.settingsSearchQuery.trim() !== "") {
                                            flashTabTimer.restart();
                                        }
                                    }
                                }

                                Loader {
                                    id: notificationsTabLoader
                                    Layout.fillWidth: true
                                    active: root.currentTab === "notifications" || loadedOnce
                                    property bool loadedOnce: false
                                    onActiveChanged: if (active) loadedOnce = true
                                    visible: root.currentTab === "notifications"
                                    sourceComponent: (active ? notificationsTabComp : null)
                                    onLoaded: {
                                        if (visible && root.settingsSearchQuery.trim() !== "") {
                                            flashTabTimer.restart();
                                        }
                                    }
                                }

                                Loader {
                                    id: keyboardTabLoader
                                    Layout.fillWidth: true
                                    active: root.currentTab === "keyboard" || loadedOnce
                                    property bool loadedOnce: false
                                    onActiveChanged: if (active) loadedOnce = true
                                    visible: root.currentTab === "keyboard"
                                    sourceComponent: (active ? keyboardTabComp : null)
                                    onLoaded: {
                                        if (visible && root.settingsSearchQuery.trim() !== "") {
                                            flashTabTimer.restart();
                                        }
                                    }
                                }

                                Loader {
                                    id: shortcutsTabLoader
                                    Layout.fillWidth: true
                                    active: root.currentTab === "shortcuts" || loadedOnce
                                    property bool loadedOnce: false
                                    onActiveChanged: if (active) loadedOnce = true
                                    visible: root.currentTab === "shortcuts"
                                    sourceComponent: (active ? shortcutsTabComp : null)
                                    onLoaded: {
                                        if (visible && root.settingsSearchQuery.trim() !== "") {
                                            flashTabTimer.restart();
                                        }
                                    }
                                }

                                Loader {
                                    id: aboutTabLoader
                                    Layout.fillWidth: true
                                    active: root.currentTab === "about" || loadedOnce
                                    property bool loadedOnce: false
                                    onActiveChanged: if (active) loadedOnce = true
                                    visible: root.currentTab === "about"
                                    sourceComponent: (active ? aboutTabComp : null)
                                    onLoaded: {
                                        if (visible && root.settingsSearchQuery.trim() !== "") {
                                            flashTabTimer.restart();
                                        }
                                    }
                                }

                                Item {
                                    id: noResultsPlaceholder
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 260
                                    visible: root.settingsSearchQuery.trim() !== "" && root.tabHasNoMatches

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 12

                                        Rectangle {
                                            Layout.alignment: Qt.AlignHCenter
                                            implicitWidth: 56
                                            implicitHeight: 56
                                            radius: 28
                                            color: Qt.alpha(Colors.cfg.base03, 0.4)

                                            Text {
                                                anchors.centerIn: parent
                                                text: "search_off"
                                                font.family: "Material Symbols Rounded"
                                                font.pixelSize: 28
                                                color: Colors.cfg.base04
                                            }
                                        }

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: qsTr("No matching settings found in this tab")
                                            font.family: "Google Sans"
                                            font.pixelSize: 15
                                            font.bold: true
                                            color: Colors.cfg.base06
                                        }

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: qsTr("Try searching other suggested tabs on the left or clear the search query")
                                            font.family: "Google Sans"
                                            font.pixelSize: 12
                                            color: Colors.cfg.base04
                                        }

                                        Rectangle {
                                            Layout.alignment: Qt.AlignHCenter
                                            Layout.topMargin: 8
                                            implicitWidth: clearSearchBtnText.implicitWidth + 24
                                            implicitHeight: 32
                                            radius: 16
                                            color: clearSearchBtnMa.containsMouse ? Qt.alpha(Colors.cfg.primary, 0.25) : Qt.alpha(Colors.cfg.base03, 0.5)
                                            border.color: Qt.alpha(Colors.cfg.primary, 0.4)
                                            border.width: 1

                                            Text {
                                                id: clearSearchBtnText
                                                anchors.centerIn: parent
                                                text: qsTr("Clear Search")
                                                font.family: "Google Sans"
                                                font.pixelSize: 12
                                                font.bold: true
                                                color: Colors.cfg.primary
                                            }

                                            MouseArea {
                                                id: clearSearchBtnMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    root.settingsSearchQuery = "";
                                                    if (typeof settingsSearchInput !== "undefined" && settingsSearchInput) {
                                                        settingsSearchInput.text = "";
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                transform: Translate {
                                    id: tabTranslate

                                    y: 0
                                }

                            }

                            ScrollBar.vertical: ScrollBar {
                                id: vScrollBar

                                policy: ScrollBar.AsNeeded
                                active: vScrollBar.hovered || vScrollBar.pressed

                                contentItem: Rectangle {
                                    implicitWidth: 3
                                    radius: 1.5
                                    color: vScrollBar.pressed ? root.color1 : (vScrollBar.hovered ? Qt.alpha(root.color1, 0.8) : Qt.alpha(root.textColor, 0.2))
                                }

                                background: Item {
                                    implicitWidth: 3
                                }

                            }

                        }

                        transform: Translate {
                            y: 20 * (1 - root.introContent)
                        }

                    }

                }

            }

        }

    }

    WidgetConfigModal {
        id: widgetConfigModal
        settingsRoot: settingsWindowRoot
    }

    Rectangle {
        id: floatingWidgetDrag
        visible: root.isDraggingWidget
        z: 99999
        width: 250
        height: 44
        radius: 8
        x: Math.max(10, Math.min(root.width - width - 10, root.widgetDragX - 30))
        y: Math.max(10, Math.min(root.height - height - 10, root.widgetDragY - 22))
        color: root.surfaceContainer
        border.color: root.color1
        border.width: 2
        opacity: 0.95

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            Text {
                text: "drag_indicator"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 18
                color: root.color1
            }

            Rectangle {
                implicitWidth: 26
                implicitHeight: 26
                radius: 6
                color: Qt.alpha(root.color1, 0.2)

                Text {
                    anchors.centerIn: parent
                    text: root.widgetDragData ? root.widgetDragData.icon : ""
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 16
                    color: root.color1
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: root.widgetDragData ? root.widgetDragData.name : ""
                    font.pixelSize: 10
                    font.bold: true
                    font.family: "Google Sans"
                    color: root.textColor
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: root.widgetDragHoverZone !== ""
                        ? (qsTr("Moving to ") + root.widgetDragHoverZone + " [" + root.widgetDragHoverIndex + "]")
                        : qsTr("Dragging...")
                    font.pixelSize: 8
                    font.family: "Google Sans"
                    color: root.color1
                }
            }

            Rectangle {
                implicitWidth: dragBgBadge.implicitWidth + 8
                implicitHeight: 20
                radius: 4
                color: (root.widgetDragData && root.widgetDragData.hasBackground) ? Qt.alpha(root.color1, 0.2) : root.surface
                border.color: (root.widgetDragData && root.widgetDragData.hasBackground) ? root.color1 : root.borderCol
                border.width: 1

                Text {
                    id: dragBgBadge
                    anchors.centerIn: parent
                    text: (root.widgetDragData && root.widgetDragData.hasBackground) ? qsTr("Capsule") : qsTr("No Bg")
                    font.pixelSize: 8
                    font.bold: true
                    font.family: "Google Sans"
                    color: (root.widgetDragData && root.widgetDragData.hasBackground) ? root.color1 : root.textMuted
                }
            }
        }
    }

    Rectangle {
        id: toastCard
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        anchors.horizontalCenter: parent.horizontalCenter
        z: 999999
        visible: opacity > 0
        opacity: root.showToastNotification ? 1 : 0
        scale: root.showToastNotification ? 1 : 0.92
        implicitWidth: toastRow.implicitWidth + 28
        implicitHeight: 38
        radius: 19
        color: root.surface
        border.color: Qt.alpha(root.color1, 0.6)
        border.width: 1.5

        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }

        RowLayout {
            id: toastRow
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: root.toastIcon
                font.pixelSize: 18
                font.family: "Material Symbols Rounded"
                color: root.color1
            }

            Text {
                text: root.toastMessage
                font.pixelSize: 11
                font.bold: true
                font.family: "Google Sans"
                color: root.textBright
            }
        }
    }

    Rectangle {
        id: monitorConfirmCard

        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        anchors.horizontalCenter: parent.horizontalCenter
        z: 999998
        visible: opacity > 0
        opacity: (root.activeMonitorsTab && root.activeMonitorsTab.confirmationActive) ? 1 : 0
        scale: (root.activeMonitorsTab && root.activeMonitorsTab.confirmationActive) ? 1 : 0.94

        readonly property int countdown: (root.activeMonitorsTab ? root.activeMonitorsTab.revertCountdown : 15)

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: 240
                easing.type: Easing.OutBack
            }

        }

        implicitWidth: Math.min(parent.width - 48, Math.max(720, monitorConfirmRow.implicitWidth + 36))
        width: implicitWidth
        implicitHeight: monitorConfirmRow.implicitHeight + 24
        height: implicitHeight
        radius: 18
        color: root.surface
        border.color: (countdown <= 5) ? Colors.cfg.error : Qt.alpha(root.color1, 0.6)
        border.width: 1.5
        clip: true

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            height: 3
            width: parent.width * Math.max(0, Math.min(1.0, monitorConfirmCard.countdown / 15.0))
            color: (monitorConfirmCard.countdown <= 5) ? Colors.cfg.error : root.color1

            Behavior on width {
                NumberAnimation {
                    duration: 950
                    easing.type: Easing.Linear
                }

            }

            Behavior on color {
                ColorAnimation {
                    duration: 200
                }

            }

        }

        RowLayout {
            id: monitorConfirmRow

            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            anchors.topMargin: 12
            anchors.bottomMargin: 12
            spacing: 14

            Rectangle {
                implicitWidth: 38
                implicitHeight: 38
                radius: 19
                color: (monitorConfirmCard.countdown <= 5) ? Qt.alpha(Colors.cfg.error, 0.22) : Qt.alpha(root.color1, 0.18)
                border.color: (monitorConfirmCard.countdown <= 5) ? Colors.cfg.error : Qt.alpha(root.color1, 0.4)
                border.width: 1.5

                Text {
                    anchors.centerIn: parent
                    text: monitorConfirmCard.countdown + "s"
                    font.family: "Google Sans"
                    font.pixelSize: 12
                    font.bold: true
                    color: (monitorConfirmCard.countdown <= 5) ? Colors.cfg.error : root.color1
                }

            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 160
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Keep these display settings?")
                    font.family: "Google Sans"
                    font.pixelSize: 13
                    font.bold: true
                    color: root.textBright
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Reverting in %1s if not confirmed • Press Enter to keep, Esc to revert").arg(monitorConfirmCard.countdown)
                    font.family: "Google Sans"
                    font.pixelSize: 10
                    color: root.textMuted
                    elide: Text.ElideRight
                }

            }

            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 8

                SettingButton {
                    text: qsTr("Revert Now")
                    icon: "undo"
                    variant: "danger"
                    compact: true
                    Layout.minimumWidth: implicitWidth
                    onClicked: {
                        if (root.activeMonitorsTab)
                            root.activeMonitorsTab.revertToPreviousConfig();

                    }
                }

                SettingButton {
                    text: qsTr("Keep Changes")
                    icon: "check"
                    variant: "primary"
                    compact: true
                    Layout.minimumWidth: implicitWidth
                    onClicked: {
                        if (root.activeMonitorsTab)
                            root.activeMonitorsTab.confirmChanges();

                    }
                }

            }

        }

    }

    DefaultAppPickerModal {
        id: defaultAppPickerModal
        settingsRoot: settingsWindowRoot
        defaultAppsTab: root.activeAppsTab
    }

    WallpaperPickerModal {
        id: wallpaperPickerModal
        settingsRoot: settingsWindowRoot
    }

    KeyRecorderModal {
        id: keyRecorderModal
    }
}
