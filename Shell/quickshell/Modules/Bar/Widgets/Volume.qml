import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Services
import qs.Modules.Bar.Widgets
import qs.Asura

// === AUDIO VOLUME STATUS WIDGET ===

Item {
    id: root

    // Theme color properties
    property color text
    property color color2: Colors.cfg.secondary
    property alias primary: root.text
    property alias secondary: root.color2

    // State properties
    property int volumeLevel: AudioService.masterVolume
    property bool hoverEnabled: true
    property bool showPercent: false
    property bool isMuted: AudioService.masterMuted
    property alias muted: root.isMuted

    readonly property bool isHovered: hoverHandler.hovered
    readonly property bool expanded: isHovered || showPercent
    property alias hovered: root.isHovered
    property alias opened: root.isHovered

    // Dynamic icon based on volume level and mute state
    readonly property string icon: {
        if (isMuted || volumeLevel === 0)
            return "volume_off";

        if (volumeLevel >= 60)
            return "volume_up";

        return "volume_down";
    }

    // Signals
    signal clicked()

    // Geometry and layout
    implicitWidth: volumeLayout.implicitWidth + 12
    implicitHeight: volumeLayout.implicitHeight
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    // Auto-hide percentage label timer
    Timer {
        id: hideTimer

        interval: 1200
        repeat: false
        onTriggered: {
            if (!root.isHovered)
                root.showPercent = false;
        }
    }

    // === VISUAL CAPSULE & CONTROLS ===

    HoverHandler {
        id: hoverHandler

        enabled: root.hoverEnabled
        onHoveredChanged: {
            if (hovered) {
                root.showPercent = true;
                hideTimer.stop();
            } else {
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
            AudioService.setMasterVolume(
                AudioService.masterVolume + (wheel.angleDelta.y > 0 ? 5 : -5)
            );
            root.showPercent = true;
            hideTimer.restart();
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

        anchors.centerIn: parent
        spacing: root.expanded ? 5 : 0

        Icon {
            id: volumeIcon

            name: root.icon
            color: root.isMuted ? root.color2 : root.text
        }

        Text {
            id: volumePercent

            text: root.volumeLevel + "%"
            font.family: "Google Sans"
            font.pixelSize: 14
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
}