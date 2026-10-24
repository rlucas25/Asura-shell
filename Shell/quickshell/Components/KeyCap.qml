import QtQuick
import qs.Asura

Rectangle {
    id: root

    property string text: ""
    property bool isModifier: {
        var t = root.text.toUpperCase();
        return t === "SUPER" || t === "SUPER_L" || t === "SUPER_R" || t === "CTRL" || t === "CONTROL" || t === "ALT" || t === "SHIFT" || t === "WIN" || t === "META" || t === "MOD4" || t === "MOD1";
    }
    readonly property real scaleFactor: (typeof Config !== "undefined" && Config.uiScale !== undefined) ? Config.uiScale : 1.0

    implicitHeight: Math.round(24 * scaleFactor)
    implicitWidth: Math.max(implicitHeight, label.implicitWidth + Math.round(14 * scaleFactor))
    radius: Math.round(6 * scaleFactor)
    color: isModifier ? Qt.alpha(Colors.cfg.primary, 0.12) : Qt.alpha(Colors.cfg.surfaceContainerHigh, 0.75)
    border.width: 1
    border.color: isModifier ? Qt.alpha(Colors.cfg.primary, 0.35) : Qt.alpha(Colors.cfg.border, 0.35)

    Text {
        id: label

        anchors.centerIn: parent
        text: root.text
        font.family: "Google Sans"
        font.pixelSize: Math.round(11 * root.scaleFactor)
        font.weight: root.isModifier ? Font.DemiBold : Font.Normal
        color: root.isModifier ? Colors.cfg.primary : Colors.cfg.textBright
    }
}
