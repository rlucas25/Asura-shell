import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Asura
import qs.Services

Item {
    id: root

    property string source: ""
    property color color: (typeof Colors !== "undefined" && Colors.cfg && Colors.cfg.primary) ? Colors.cfg.primary : "#ffffff"
    property real size: 20
    property bool colorize: true
    property string fallbackGlyph: ""

    implicitWidth: size
    implicitHeight: size
    width: size
    height: size

    readonly property bool isGlyphString: {
        if (!root.source || root.source.length === 0) return true;
        if (root.source.startsWith("/") || root.source.startsWith("file:") || root.source.startsWith("image:")) return false;
        if (root.source.endsWith(".png") || root.source.endsWith(".svg") || root.source.endsWith(".xpm")) return false;
        if (typeof IconService !== "undefined" && typeof IconService.isGlyph === "function") {
            return IconService.isGlyph(root.source);
        }
        return root.source.length <= 2 || root.source.charCodeAt(0) > 255;
    }

    readonly property string iconSourceUrl: {
        if (root.isGlyphString || !root.source) return "";
        if (root.source.startsWith("file://")) return root.source;
        if (root.source.startsWith("/")) return "file://" + root.source;

        if (typeof IconService !== "undefined" && typeof IconService.getIconPath === "function") {
            var path = IconService.getIconPath(root.source);
            if (path && path.length > 0) {
                return path.startsWith("/") ? ("file://" + path) : path;
            }
        }

        try {
            if (typeof Quickshell !== "undefined" && typeof Quickshell.iconPath === "function") {
                var qPath = Quickshell.iconPath(root.source, true);
                if (qPath && qPath.length > 0) {
                    return qPath.startsWith("/") ? ("file://" + qPath) : qPath;
                }
            }
        } catch (e) {}

        if (root.source.startsWith("image://")) return root.source;

        return "";
    }

    readonly property string effectiveGlyph: {
        if (root.fallbackGlyph && root.fallbackGlyph.length > 0) return root.fallbackGlyph;
        if (root.isGlyphString && root.source) return root.source;
        if (typeof IconService !== "undefined" && typeof IconService.getFallbackGlyph === "function") {
            return IconService.getFallbackGlyph(root.source);
        }
        return "music_note";
    }

    readonly property bool isNerdGlyph: effectiveGlyph.length <= 2 || effectiveGlyph.charCodeAt(0) > 255

    Image {
        id: img
        anchors.fill: parent
        source: root.iconSourceUrl
        sourceSize.width: Math.max(16, Math.round(root.width * 2))
        sourceSize.height: Math.max(16, Math.round(root.height * 2))
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        mipmap: true
        visible: !root.isGlyphString && root.iconSourceUrl !== "" && img.status === Image.Ready

        layer.enabled: root.colorize && visible
        layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: root.color
        }
    }

    Text {
        id: glyphText
        anchors.centerIn: parent
        visible: root.isGlyphString || root.iconSourceUrl === "" || img.status !== Image.Ready
        text: root.effectiveGlyph
        font.pixelSize: Math.round(root.size * 0.9)
        font.family: root.isNerdGlyph ? "GeistMono Nerd Font Propo" : "Material Symbols Rounded"
        color: root.color
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
