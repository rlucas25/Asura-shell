import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Asura
import qs.Modules.Bar.Widgets
import qs.Services

Item {
    id: root

    property color text: Colors.cfg.textBright
    property color color2: Colors.cfg.secondary
    property alias primary: root.text
    property alias secondary: root.color2
    property int volumeLevel: AudioService.masterVolume
    property bool hoverEnabled: (typeof Config !== "undefined" && Config.barWidgetHoverTextEnabled !== undefined) ? Config.barWidgetHoverTextEnabled : true
    property bool showPercent: false
    property bool isMuted: AudioService.masterMuted
    property alias muted: root.isMuted
    readonly property bool isHovered: hoverHandler.hovered
    readonly property bool expanded: (isHovered || showPercent) && root.hoverEnabled
    property alias hovered: root.isHovered
    property alias opened: root.isHovered
    readonly property string icon: {
        if (isMuted || volumeLevel === 0)
            return "volume_off";

        if (volumeLevel >= 60)
            return "volume_up";

        return "volume_down";
    }
    readonly property bool isVertical: Config.isBarVertical

    signal clicked()

    onVolumeLevelChanged: {
        if (root.hoverEnabled) {
            root.showPercent = true;
            hideTimer.restart();
        }
    }
    implicitWidth: isVertical ? Math.round(22 * Config.barIconScale) : (volumeLayout.implicitWidth + Math.round(12 * Config.barIconScale))
    implicitHeight: isVertical ? Math.round(22 * Config.barIconScale) : volumeLayout.implicitHeight
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

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
        onWheel: (wheel) => {
            AudioService.setMasterVolume(AudioService.masterVolume + (wheel.angleDelta.y > 0 ? 5 : -5));
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
        id: volumeLayout

        visible: !root.isVertical
        anchors.centerIn: parent
        spacing: root.expanded ? 5 : 0

        Icon {
            id: volumeIcon

            fill: 0
            name: root.icon
            color: root.isMuted ? root.color2 : root.text
        }

        Text {
            id: volumePercent

            text: root.volumeLevel + "%"
            font.family: "Google Sans"
            font.pixelSize: Math.round(14 * Config.barIconScale)
            font.weight: 500
            color: root.isMuted ? root.color2 : root.text
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
            id: vVolumeIcon

            anchors.centerIn: parent
            name: root.icon
            color: root.isMuted ? root.color2 : root.text
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
            id: vVolumePercent

            anchors.centerIn: parent
            text: root.volumeLevel + "%"
            font.family: "Google Sans"
            font.pixelSize: Math.round((root.volumeLevel >= 100 ? 8.5 : 9.5) * Config.barIconScale)
            font.weight: 600
            color: root.isMuted ? root.color2 : root.text
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

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }

    }

}
