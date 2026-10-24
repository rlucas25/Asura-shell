import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Asura
import qs.Modules.Bar.Widgets

Text {
    id: root

    property color textColor: Colors.cfg.text

    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.alignment: Qt.AlignVCenter
    text: "󰣇"
    color: root.textColor
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter

    font {
        pixelSize: Math.round(20 * ((typeof Config !== "undefined" && Config.barIconScale !== undefined) ? Config.barIconScale : 1.0))
        family: "GeistMono Nerd Font Propo"
    }

}
