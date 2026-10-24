import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Services
import qs.Modules.Bar.Widgets
import qs.Asura

Item {
    id: root

    property color text: Colors.cfg.textBright
    property color color2: Colors.cfg.secondary
    property alias primary: root.text
    property alias secondary: root.color2

    property int brightnessLevel: BrightnessService.brightness
    property bool hoverEnabled: (typeof Config !== "undefined" && Config.barWidgetHoverTextEnabled !== undefined) ? Config.barWidgetHoverTextEnabled : true
    property bool showPercent: false

    onBrightnessLevelChanged: {
        if (root.hoverEnabled) {
            root.showPercent = true;
            hideTimer.restart();
        }
    }

    readonly property bool isHovered: hoverHandler.hovered
    readonly property bool expanded: (isHovered || showPercent) && root.hoverEnabled
    property alias hovered: root.isHovered
    property alias opened: root.isHovered

    readonly property string icon: {
        if (brightnessLevel <= 25)
            return "brightness_low";
        if (brightnessLevel <= 70)
            return "brightness_medium";
        return "brightness_high";
    }

    signal clicked()

    readonly property bool isVertical: Config.isBarVertical
    implicitWidth: isVertical ? Math.round(22 * Config.barIconScale) : (brightnessLayout.implicitWidth + Math.round(12 * Config.barIconScale))
    implicitHeight: isVertical ? Math.round(22 * Config.barIconScale) : brightnessLayout.implicitHeight
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        id: hideTimer

        interval: 1200
        repeat: false
        onTriggered: {
            if (!root.isHovered)
                root.showPercent = false;
        }
    }

    HoverHandler {
        id: hoverHandler

        onHoveredChanged: {
            if (hovered && root.hoverEnabled) {
                root.showPercent = true;
                hideTimer.stop();
            } else if (!hovered) {
                hideTimer.restart();
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.clicked();
        }

        onWheel: wheel => {
            var step = wheel.angleDelta.y > 0 ? 5 : -5;
            BrightnessService.setBrightness(
                BrightnessService.brightness + step
            );
            if (root.hoverEnabled) {
                root.showPercent = true;
                hideTimer.restart();
            }
        }
    }

    Rectangle {
        id: capsuleBackground

        anchors.fill: parent
        radius: height / 2
        color: root.text
        opacity: root.expanded ? 0.2 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }
    }

    RowLayout {
        id: brightnessLayout

        visible: !root.isVertical
        anchors.centerIn: parent
        spacing: root.expanded ? 5 : 0

        Icon {
            id: brightnessIcon

            name: root.icon
            color: root.text
        }

        Text {
            id: brightnessPercent

            text: root.brightnessLevel + "%"
            font.family: "Google Sans"
            font.pixelSize: Math.round(14 * Config.barIconScale)
            font.weight: 500
            color: root.text
            opacity: root.expanded ? 1 : 0
            visible: opacity > 0
            verticalAlignment: Text.AlignVCenter

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    Item {
        id: verticalContent

        visible: root.isVertical
        anchors.centerIn: parent
        width: Math.round(22 * Config.barIconScale)
        height: Math.round(22 * Config.barIconScale)

        Icon {
            id: vBrightnessIcon

            anchors.centerIn: parent
            name: root.icon
            color: root.text
            opacity: root.expanded ? 0 : 1
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
        }

        Text {
            id: vBrightnessPercent

            anchors.centerIn: parent
            text: root.brightnessLevel + "%"
            font.family: "Google Sans"
            font.pixelSize: Math.round((root.brightnessLevel >= 100 ? 8.5 : 9.5) * Config.barIconScale)
            font.weight: 600
            color: root.text
            opacity: root.expanded ? 1 : 0
            visible: opacity > 0
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
