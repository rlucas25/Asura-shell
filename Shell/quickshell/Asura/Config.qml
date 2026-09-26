pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services

Singleton {
    id: root

    readonly property alias cfg: adapter
    property bool ready: false

    WallpaperService {
        id: wallpaperService
    }

    FileView {
        id: file
        path: Quickshell.shellRoot + "/config.json"
        watchChanges: false

        onAdapterUpdated: writeAdapter()
        onLoaded: {
            root.ready = true;
        }
        onLoadFailed: (error) => {
            if (error === FileViewError.FileNotFound)
                writeAdapter()
            else
                reload()
        }

        JsonAdapter {
            id: adapter
            property int barMode: 1
            property bool exclusiveMode: true
            property bool autoHide: false
            property real opacity: 1.0
            property real widthS: 0.85
            property string theme: "sandcastle"
            property bool colorsAutoGenerate: false
            property bool isDarkMode: true
            property string wallpaperFolder: "/Pictures/Wallpapers"
            property string wallpaper: Quickshell.env("HOME") + "/.config/quickshell/Assets/default_wallpaper.jpg"
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
            property int workspacesCount: 3
            property bool workspacesShowNumbers: true
            property string workspacesNumberStyle: "roman"
            property string recordingsFolder: "~/Videos/Recordings"

            onIsDarkModeChanged: {
                if (root.ready && adapter.colorsAutoGenerate && adapter.wallpaper) {
                    Colors.generateMatugenColors(adapter.wallpaper, adapter.isDarkMode, adapter.scheme);
                }
            }

            onSchemeChanged: {
                if (root.ready && adapter.colorsAutoGenerate && adapter.wallpaper) {
                    Colors.generateMatugenColors(adapter.wallpaper, adapter.isDarkMode, adapter.scheme);
                }
            }

            onThemeChanged: {
                if (root.ready && adapter.theme) {
                    Colors.loadPalette(adapter.theme);
                }
            }

            onWallpaperChanged: {
                if (root.ready) {
                    file.writeAdapter();
                    if (adapter.colorsAutoGenerate && adapter.wallpaper) {
                        Colors.generateMatugenColors(adapter.wallpaper, adapter.isDarkMode, adapter.scheme);
                    }
                    Qt.callLater(function() {
                        wallpaperService.applyWallpaper();
                    });
                }
            }
        }
    }

    function save() {
        if (root.ready) {
            file.writeAdapter();
        }
    }
}
