import QtQuick
import QtQuick.Layouts
import qs.Asura
import qs.Components

Row {
    id: root

    property string chord: ""
    readonly property var keyTokens: {
        if (!root.chord || root.chord.trim() === "") return [];
        var parts = root.chord.split("+");
        var res = [];
        for (var i = 0; i < parts.length; i++) {
            var s = parts[i].trim();
            if (s !== "") res.push(s);
        }
        return res;
    }
    readonly property real scaleFactor: (typeof Config !== "undefined" && Config.uiScale !== undefined) ? Config.uiScale : 1.0

    spacing: Math.round(5 * scaleFactor)

    Repeater {
        model: root.keyTokens

        Row {
            spacing: Math.round(5 * root.scaleFactor)

            KeyCap {
                text: modelData
            }

            Text {
                visible: index < root.keyTokens.length - 1
                anchors.verticalCenter: parent.verticalCenter
                text: "+"
                font.family: "Google Sans"
                font.pixelSize: Math.round(11 * root.scaleFactor)
                color: Qt.alpha(Colors.cfg.textSecondary, 0.6)
            }
        }
    }
}
