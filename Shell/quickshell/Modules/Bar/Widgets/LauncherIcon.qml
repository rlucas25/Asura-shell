import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.Asura
import qs.Modules.Bar.Widgets

Text {
    id: root
    property color textColor
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    font {
        pixelSize: 20
        family: "GeistMono Nerd Font Propo Propo"
    }

    text: " 󰣇 "
    color: root.textColor

}
