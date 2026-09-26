import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Asura
import qs.Modules.Bar.Widgets

Text {
    id: root

    property color textColor: Colors.cfg.text
    property alias color1: root.textColor
    property string currentTime: ""
    property string currentDate: ""

    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    font.family: "Google Sans"
    font.pixelSize: 15
    font.weight: 500
    verticalAlignment: Text.AlignVCenter
    text: "      " + currentTime + " • " + currentDate + "  "
    color: root.textColor

    // === CLOCK TIMER ===
    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var now = new Date();
            root.currentTime = Qt.formatTime(now, "hh:mm AP");
            root.currentDate = Qt.formatDate(now, "ddd, dd/MM");
        }
    }

}
