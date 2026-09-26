import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.Animations as ANIM
import qs.Asura

Scope {
    id: root

    property bool verticalMode
    property color color1
    property color color2
    property color background
    property bool shouldShowOsd: false

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        function onVolumeChanged() {
            root.shouldShowOsd = true;
            hideTimer.restart();
        }

        target: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) ? Pipewire.defaultAudioSink.audio : null
    }

    Timer {
        id: hideTimer

        interval: 2000
        onTriggered: root.shouldShowOsd = false
    }

    LazyLoader {
        active: shouldShowOsd

        PanelWindow {
            id: panelWindow

            property bool muted: {
                if (!Pipewire.defaultAudioSink || Pipewire.defaultAudioSink.audio.muted)
                    return true;

                return false;
            }
            property int volumeLevel: Pipewire.defaultAudioSink ? Math.round(Pipewire.defaultAudioSink.audio.volume * 100) : 0
            property string icon: {
                if (muted || volumeLevel === 0)
                    return "volume_off";

                if (volumeLevel >= 60)
                    return "volume_up";

                return "volume_down";
            }

            implicitWidth: verticalMode ? 50 : 300
            implicitHeight: verticalMode ? 300 : 50
            color: "transparent"
            exclusiveZone: 0
            anchors.right: verticalMode
            anchors.bottom: !verticalMode
            margins.right: verticalMode ? implicitWidth : 0
            margins.bottom: verticalMode ? 0 : implicitHeight

            Rectangle {
                id: content

                implicitHeight: verticalMode ? 250 : 35
                anchors.margins: 0
                anchors.centerIn: parent
  
                color: root.background
                clip: false
                state: ""
                width: 0
                opacity: 0
                radius: 6
                Component.onCompleted: content.state = "show"
                states: [
                    State {
                        name: "show"

                        PropertyChanges {
                            target: content
                            width: parent.width
                            opacity: 1
                            radius: 6
                        }

                    }
                ]
                transitions: [
                    Transition {
                        from: ""
                        to: "show"

                        NumberAnimation {
                            properties: "width,opacity,radius"
                            duration: 100
                            easing.type: Easing.OutCirc
                        }

                    }
                ]

             Item {
                    id: progressLayer
                    anchors.fill: parent

                    property real currentVol: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) ? Pipewire.defaultAudioSink.audio.volume : 0
                    property real animatedVol: currentVol
                    property real progressPx: verticalMode ? (height * animatedVol) : (width * animatedVol)

                    property real thumbPresence: animatedVol > 0.95 ? 0 : 1
                    Behavior on thumbPresence { NumberAnimation { duration: 150 } }

                    readonly property real gap: 6 * thumbPresence
                    readonly property real thumbReservedSpace: 4 * thumbPresence

                    Rectangle {
                        id: filledTrack
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left

                        width: verticalMode ? parent.width : Math.max(0, progressLayer.progressPx - progressLayer.thumbReservedSpace - progressLayer.gap)
                        height: verticalMode ? Math.max(0, progressLayer.progressPx - progressLayer.thumbReservedSpace - progressLayer.gap) : parent.height
                        
                        color: root.color1
                        radius: content.radius
                    }

                    Rectangle {
                        id: thumb
                        opacity: progressLayer.thumbPresence
                        color: root.color1
                        radius: 2
                        
                        anchors.verticalCenter: verticalMode ? undefined : parent.verticalCenter
                        anchors.horizontalCenter: verticalMode ? parent.horizontalCenter : undefined
                        
                        anchors.left: verticalMode ? undefined : filledTrack.right
                        anchors.leftMargin: verticalMode ? 0 : progressLayer.gap
                        
                        anchors.bottom: verticalMode ? filledTrack.top : undefined
                        anchors.bottomMargin: verticalMode ? progressLayer.gap : 0

                        width: verticalMode ? parent.width : 5
                        height: verticalMode ? 4 : parent.height * 1.2
                    }

                    Behavior on animatedVol {
                        ANIM.Bezier {}
                    }
                }

                Item {
                    id: maskItem

                    anchors.fill: parent
                    layer.enabled: true
                    visible: false

                    Rectangle {
                        anchors.fill: parent
                        radius: content.radius
                    }

                }

                Text {
                    anchors.bottom: verticalMode ? parent.bottom : undefined
                    anchors.horizontalCenter: verticalMode ? parent.horizontalCenter : undefined
                    anchors.left: verticalMode ? undefined : parent.left
                    anchors.verticalCenter: verticalMode ? undefined : parent.verticalCenter
                    anchors.margins: 20
                    text: icon
                    color: muted ? color2 : background

                    font {
                        pixelSize: 20
                        family: "Material Symbols Rounded"
                    }

                }

            }

        }

    }

}
