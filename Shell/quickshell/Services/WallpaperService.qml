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
            "export PATH=\"$HOME/.local/bin:/usr/local/bin:$PATH\"",
            "cmd=''",
            "if command -v awww >/dev/null 2>&1; then cmd='awww'; elif command -v swww >/dev/null 2>&1; then cmd='swww'; fi",
            "if [ -z \"$cmd\" ]; then echo 'Neither awww nor swww is installed!' >&2; exit 1; fi",
            "daemon=\"${cmd}-daemon\"",
            "if ! pgrep -x \"$daemon\" >/dev/null 2>&1; then",
            "  if command -v \"$daemon\" >/dev/null 2>&1; then \"$daemon\" &",
            "  elif [ \"$cmd\" = 'swww' ] && command -v swww >/dev/null 2>&1; then swww init & fi",
            "  for i in $(seq 1 30); do \"$cmd\" query >/dev/null 2>&1 && break; sleep 0.1; done",
            "fi",
            "img=\"" + cleanWall + "\"",
            "[ -f \"$img\" ] || img=\"" + defaultWall + "\"",
            "\"$cmd\" img \"$img\" --transition-type " + anim + " --transition-duration " + dur
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

