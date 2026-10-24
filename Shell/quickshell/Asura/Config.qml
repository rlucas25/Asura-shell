pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services

Singleton {
    id: root

    readonly property alias cfg: adapter
    readonly property bool ready: file.loaded
    property bool reloading: false

    readonly property real effectiveGeneralOpacity: (adapter.generalOpacity !== undefined && adapter.generalOpacity >= 0)
        ? Math.max(0, Math.min(1, adapter.generalOpacity))
        : 1.0

    readonly property real effectiveBarOpacity: (adapter.barFollowsGeneralOpacity !== false)
        ? effectiveGeneralOpacity
        : ((adapter.opacity !== undefined && adapter.opacity >= 0) ? Math.max(0, Math.min(1, adapter.opacity)) : 1.0)

    readonly property string effectiveBlurStrength: (adapter.blurStrength !== undefined)
        ? adapter.blurStrength
        : "balanced"

    readonly property bool effectiveBarMeltEnabled: (adapter.barMeltEnabled !== undefined)
        ? adapter.barMeltEnabled
        : true

    readonly property int effectiveBarMeltRadius: (adapter.barMeltRadius !== undefined && adapter.barMeltRadius > 0)
        ? adapter.barMeltRadius
        : 16

    readonly property string effectiveBarMeltStyle: (adapter.barMeltStyle !== undefined)
        ? adapter.barMeltStyle
        : "organic"

    readonly property int effectiveGeneralRadius: (adapter.generalRadius !== undefined && adapter.generalRadius >= 0)
        ? adapter.generalRadius
        : 20

    readonly property int effectiveMenuRadius: effectiveGeneralRadius

    readonly property int effectiveBarCapsuleRadius: (adapter.barFollowsGeneralRadius !== false)
        ? Math.round(effectiveGeneralRadius * 0.75)
        : ((adapter.barCapsuleRadius !== undefined && adapter.barCapsuleRadius >= 0) ? adapter.barCapsuleRadius : 15)

    readonly property int effectiveControlPanelRadius: Math.round(effectiveGeneralRadius * 1.3)

    readonly property string barPosition: (adapter.barPosition && adapter.barPosition !== "")
        ? adapter.barPosition
        : "top"
    readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
    readonly property bool isBarHorizontal: !isBarVertical
    readonly property int effectiveBarThickness: (adapter.barThickness !== undefined && adapter.barThickness > 0)
        ? adapter.barThickness
        : 30
    readonly property real barScale: effectiveBarThickness / 30.0
    readonly property real effectiveBarIconScale: (adapter.barIconScale !== undefined && adapter.barIconScale > 0)
        ? Math.max(0.6, Math.min(1.6, adapter.barIconScale))
        : 1.0
    readonly property real barIconScale: effectiveBarIconScale

    readonly property int effectiveBarEdgeSpacing: (adapter.barEdgeSpacing !== undefined && adapter.barEdgeSpacing >= 0)
        ? adapter.barEdgeSpacing
        : 10

    readonly property int effectiveBarCapsulePadding: (adapter.barCapsulePadding !== undefined && adapter.barCapsulePadding >= 0)
        ? adapter.barCapsulePadding
        : 6

    readonly property int effectiveBarWidgetSpacing: (adapter.barWidgetSpacing !== undefined && adapter.barWidgetSpacing >= 0)
        ? adapter.barWidgetSpacing
        : 4

    readonly property int effectiveBarCapsuleWidgetSpacing: (adapter.barCapsuleWidgetSpacing !== undefined && adapter.barCapsuleWidgetSpacing >= 0)
        ? adapter.barCapsuleWidgetSpacing
        : 2

    readonly property bool effectiveBarWidgetHoverTextEnabled: (adapter.barWidgetHoverTextEnabled !== undefined)
        ? adapter.barWidgetHoverTextEnabled
        : true
    readonly property bool barWidgetHoverTextEnabled: effectiveBarWidgetHoverTextEnabled

    readonly property bool effectiveBarHoverMenusEnabled: (adapter.barHoverMenusEnabled !== undefined)
        ? adapter.barHoverMenusEnabled
        : false
    readonly property bool barHoverMenusEnabled: effectiveBarHoverMenusEnabled

    WallpaperService {
        id: wallpaperService
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/asura/config.json"
        watchChanges: true
        preload: true
        blockLoading: true

        onFileChanged: reload()
        onLoadFailed: (error) => {
            if (error === FileViewError.FileNotFound)
                file.writeAdapter()
            else
                reload()
        }

        JsonAdapter {
            id: adapter
            property string barPosition: "top"
            property int barThickness: 30
            property real barIconScale: 1.0
            property int barMode: 1
            property bool exclusiveMode: true
            property bool autoHide: false
            property real opacity: 1.0
            property real generalOpacity: 1.0
            property bool barFollowsGeneralOpacity: true
            property bool blurEnabled: true
            property string blurStrength: "balanced"
            property bool barMeltEnabled: true
            property int barMeltRadius: 16
            property string barMeltStyle: "organic"
            property int generalRadius: 20
            property bool barFollowsGeneralRadius: true
            property int barCapsuleRadius: 15
            property int barEdgeSpacing: 10
            property int barCapsulePadding: 6
            property int barWidgetSpacing: 4
            property int barCapsuleWidgetSpacing: 2
            property real widthS: 0.85
            property string theme: "sandcastle"
            property string primarySlot: "base0D"
            property string launcherPosition: "default"
            property var launcherHiddenApps: []
            property bool launcherCommandsNoPrefix: false
            property bool launcherCalculatorNoPrefix: false
            property bool launcherWebSearchNoPrefix: false
            property bool colorsAutoGenerate: false
            property bool isDarkMode: true
            property bool appThemingEnabled: true
            property var disabledTemplates: []
            property var defaultApps: ({})
            property string clockFormat: "time_calendar"
            property bool clock24h: false
            property bool weekStartsOnMonday: false
            property bool hardwareHidePercent: false
            property bool hardwareShowAbsolute: false
            property bool barWidgetHoverTextEnabled: true
            property bool barHoverMenusEnabled: false
            property bool barVisualizerEnabled: true
            property string barVisualizerType: "bars"
            property real barVisualizerHeight: 0.75
            property real barVisualizerOpacity: 0.45
            property string barVisualizerBarsOrigin: "bottom"
            property int barVisualizerDensity: 10
            property int barVisualizerGap: 2
            property int barVisualizerSmoothing: 2
            property string wallpaperFolder: "/Pictures/Wallpapers"
            property string wallpaper: Quickshell.env("HOME") + "/.config/quickshell/Assets/default_wallpaper.jpg"
            property var favoriteWallpapers: []
            property var favoritePresets: []
            property string wallpaperAnimation: "random"
            property real wallpaperAnimationDuration: 1
            property string scheme: "tonal-spot"
            property int pomodoroWork: 25
            property int pomodoroShortBreak: 5
            property int pomodoroLongBreak: 15
            property bool soundEffects: true
            property bool alertsPopups: true
            property string notificationSound: "message.oga"
            property int notificationTimeout: 4500
            property string notificationPosition: "top_right"
            property bool notificationPrivacy: false
            property bool ecoMode: false
            property int workspacesCount: 3
            property bool workspacesShowNumbers: true
            property string workspacesNumberStyle: "roman"
            property string recordingsFolder: "~/Videos/Recordings"
            property var customKeybinds: []

            onIsDarkModeChanged: {
                if (root.ready && adapter.colorsAutoGenerate && adapter.wallpaper) {
                    Colors.generateDynamicColors(adapter.wallpaper, adapter.isDarkMode, adapter.scheme);
                }
            }

            onSchemeChanged: {
                if (root.ready && adapter.colorsAutoGenerate && adapter.wallpaper) {
                    Colors.generateDynamicColors(adapter.wallpaper, adapter.isDarkMode, adapter.scheme);
                }
            }

            onThemeChanged: {
                if (root.ready && !root.reloading && adapter.theme && !adapter.colorsAutoGenerate) {
                    Colors.loadPalette(adapter.theme);
                }
            }

            onPrimarySlotChanged: {
                if (root.ready && adapter.primarySlot) {
                    if (typeof Colors !== "undefined" && Colors.primarySlot !== adapter.primarySlot) {
                        Colors.setPrimarySlot(adapter.primarySlot);
                    }
                }
            }

            onWallpaperChanged: {
                if (root.ready && !root.reloading) {
                    if (adapter.colorsAutoGenerate && adapter.wallpaper) {
                        Colors.generateDynamicColors(adapter.wallpaper, adapter.isDarkMode, adapter.scheme);
                    }
                    Qt.callLater(function() {
                        wallpaperService.applyWallpaper();
                    });
                }
            }

            onLauncherHiddenAppsChanged: {
            }

            onEcoModeChanged: {
                if (root.ready && !root.reloading) {
                    root.applyEcoMode(adapter.ecoMode);
                }
            }
        }
    }

    // Debounce timer for continuous inputs (sliders, position updates)
    Timer {
        id: saveDebounceTimer
        interval: 100
        repeat: false
        onTriggered: {
            if (root.ready) {
                file.writeAdapter();
            }
        }
    }

    Process {
        id: ecoGameModeProc
        running: false
        onExited: running = false
    }

    function applyEcoMode(enabled) {
        var isEnabled = (enabled !== undefined) ? (enabled === true) : (adapter.ecoMode === true);
        if (ecoGameModeProc.running) {
            ecoGameModeProc.running = false;
        }
        var cmd = isEnabled
            ? "if [ ! -f /tmp/gamemode_on ]; then bash ~/.config/hypr/scripts/gamemode.sh; fi"
            : "if [ -f /tmp/gamemode_on ]; then bash ~/.config/hypr/scripts/gamemode.sh; fi";
        ecoGameModeProc.command = ["bash", "-c", cmd];
        ecoGameModeProc.running = true;
    }

    function save() {
        if (saveDebounceTimer.running) {
            saveDebounceTimer.stop();
        }
        if (root.ready) {
            file.writeAdapter();
        }
    }

    function saveDebounced(delay) {
        if (delay !== undefined && delay > 0) {
            saveDebounceTimer.interval = delay;
        } else {
            saveDebounceTimer.interval = 100;
        }
        saveDebounceTimer.restart();
    }

    function reload() {
        if (saveDebounceTimer.running) {
            saveDebounceTimer.stop();
        }
        root.reloading = true;
        file.reload();
        Qt.callLater(function() {
            root.reloading = false;
        });
    }

    Component.onCompleted: {
        if (!file.text()) {
            file.writeAdapter();
        }
    }
}
