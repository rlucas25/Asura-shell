import QtQuick
import Quickshell
import Quickshell.Io
import qs.Asura

Item {
    id: root

    property bool colorsAutoGenerate: Config.cfg.colorsAutoGenerate
    property string wallpaper: Config.cfg.wallpaper
    property string wallpaperAnimation: Config.cfg.wallpaperAnimation
    property real wallpaperAnimationDuration: Config.cfg.wallpaperAnimationDuration

    function applyWallpaper() {
        if (!root.wallpaper)
            return ;
        wallpaperProcess.running = false;
        wallpaperProcess.command = ["sh", "-c", "awww img \"" + root.wallpaper + "\" --transition-type " + root.wallpaperAnimation + " --transition-duration " + root.wallpaperAnimationDuration];
        wallpaperProcess.running = true;
    }

    Process {
        id: wallpaperProcess
        stdout: SplitParser {
            onRead: data => console.log("AWWW: " + data)
        }
        stderr: SplitParser {
            onRead: data => console.warn("AWWW Error: " + data)
        }
    }
}

