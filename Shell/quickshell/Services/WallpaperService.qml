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
        var cleanWall = root.wallpaper.toString().replace(/^file:\/\//, "").replace(/^file:/, "");
        if (cleanWall.indexOf("~/") === 0) {
            cleanWall = Quickshell.env("HOME") + cleanWall.substring(1);
        }
        var defaultWall = Quickshell.env("HOME") + "/.local/share/asura/Shell/quickshell/Assets/default_wallpaper.jpg";
        var anim = root.wallpaperAnimation || "wave";
        var dur = root.wallpaperAnimationDuration || 1;

        var cmd = [
            "cmd='awww'",
            "[ -x \"$(which awww 2>/dev/null)\" ] || cmd='swww'",
            "daemon=\"${cmd}-daemon\"",
            "if ! pgrep -x \"$daemon\" >/dev/null 2>&1 && which \"$daemon\" >/dev/null 2>&1; then \"$daemon\" & sleep 0.3; fi",
            "img=\"" + cleanWall + "\"",
            "[ -f \"$img\" ] || img=\"" + defaultWall + "\"",
            "if which \"$cmd\" >/dev/null 2>&1; then",
            "  \"$cmd\" img \"$img\" --transition-type " + anim + " --transition-duration " + dur,
            "else",
            "  echo 'Neither awww nor swww is installed!' >&2",
            "fi"
        ].join("; ");

        wallpaperProcess.running = false;
        wallpaperProcess.command = ["sh", "-c", cmd];
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

