import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Asura
import qs.Modules.Bar.Widgets

Text {
    id: root

    property color textColor

    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    text: " 󰣇 "
    color: root.textColor

    font {
        pixelSize: 20
        family: "GeistMono Nerd Font Propo Propo"
    }

}
