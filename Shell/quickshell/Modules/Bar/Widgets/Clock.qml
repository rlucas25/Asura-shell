import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Asura
import qs.Modules.Bar.Widgets

Text {
    id: root

    property color textColor: Colors.cfg.textBright
    property alias color1: root.textColor
    property string formattedClock: ""
    readonly property bool isVertical: Config.isBarVertical
    readonly property string clockFormat: (Config.cfg && Config.cfg.clockFormat) ? Config.cfg.clockFormat : "time_calendar"
    readonly property bool clock24h: (Config.cfg && Config.cfg.clock24h !== undefined) ? Config.cfg.clock24h : false

    function updateTime() {
        var now = new Date();
        if (root.isVertical) {
            root.formattedClock = Qt.formatTime(now, root.clock24h ? "HH\nmm" : "hh\nmm");
            return ;
        }
        var timeStr = Qt.formatTime(now, root.clock24h ? "HH:mm" : "hh:mm AP");
        switch (root.clockFormat) {
        case "time_only":
            root.formattedClock = timeStr;
            break;
        case "time_day":
            root.formattedClock = timeStr + " • " + Qt.formatDate(now, "ddd");
            break;
        case "time_day_month":
            root.formattedClock = timeStr + " • " + Qt.formatDate(now, "dd MMM");
            break;
        case "time_full":
            root.formattedClock = timeStr + " • " + Qt.formatDate(now, "dddd, dd MMM");
            break;
        case "time_calendar":
        default:
            root.formattedClock = timeStr + " • " + Qt.formatDate(now, "ddd, dd/MM");
            break;
        }
    }

    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.alignment: root.isVertical ? Qt.AlignHCenter : Qt.AlignVCenter
    font.family: "Google Sans"
    font.pixelSize: Math.round(15 * ((typeof Config !== "undefined" && Config.barIconScale !== undefined) ? Config.barIconScale : 1))
    font.weight: root.isVertical ? 700 : 500
    lineHeight: root.isVertical ? 0.9 : 1
    horizontalAlignment: root.isVertical ? Text.AlignHCenter : Text.AlignLeft
    verticalAlignment: Text.AlignVCenter
    text: root.isVertical ? formattedClock : ("    " + formattedClock + "  ")
    color: root.textColor

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateTime()
    }

    Connections {
        function onClockFormatChanged() {
            root.updateTime();
        }

        function onClock24hChanged() {
            root.updateTime();
        }

        target: Config.cfg
    }

}
