import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import qs.Animations as ANIM
import qs.Asura
import qs.Components

Scope {
    id: root

    property bool verticalMode
    property color color1
    property color color2
    property color background
    property bool shouldShowOsd: false
    property bool isInteracting: false

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        function onVolumeChanged() {
            root.shouldShowOsd = true;
            if (!root.isInteracting)
                hideTimer.restart();

        }

        function onMutedChanged() {
            root.shouldShowOsd = true;
            if (!root.isInteracting)
                hideTimer.restart();

        }

        target: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) ? Pipewire.defaultAudioSink.audio : null
    }

    Timer {
        id: hideTimer

        interval: 2000
        onTriggered: {
            if (!root.isInteracting)
                root.shouldShowOsd = false;

        }
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

            WlrLayershell.namespace: "volumeOSD"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            implicitWidth: verticalMode ? 50 : 340
            implicitHeight: verticalMode ? 300 : 54
            color: "transparent"
            exclusiveZone: 0
            anchors.right: verticalMode
            anchors.bottom: !verticalMode
            margins.right: verticalMode ? implicitWidth : 0
            margins.bottom: verticalMode ? 0 : implicitHeight

            Rectangle {
                id: content

                readonly property real effectiveRadius: {
                    var maxR = (verticalMode ? (parent ? parent.width : 50) : height) / 2;
                    var userR = (typeof Config !== "undefined" && Config.effectiveGeneralRadius !== undefined) ? Config.effectiveGeneralRadius : 20;
                    return Math.max(0, Math.min(maxR, userR));
                }

                implicitHeight: verticalMode ? 250 : 44
                height: implicitHeight
                anchors.margins: 0
                anchors.centerIn: parent
                color: root.background
                clip: false
                state: ""
                width: 0
                opacity: 0
                radius: effectiveRadius
                scale: root.isInteracting ? (osdSlider.pressed ? 0.98 : 1.02) : 1
                Component.onCompleted: content.state = "show"
                states: [
                    State {
                        name: "show"

                        PropertyChanges {
                            target: content
                            width: parent.width
                            opacity: 1
                        }

                    }
                ]
                transitions: [
                    Transition {
                        from: ""
                        to: "show"

                        NumberAnimation {
                            properties: "width,opacity"
                            duration: 100
                            easing.type: Easing.OutCirc
                        }

                    }
                ]

                SettingSlider {
                    id: osdSlider

                    anchors.fill: parent
                    compact: true
                    fillHeight: true
                    vertical: root.verticalMode
                    from: 0
                    to: 100
                    stepSize: 1
                    value: Pipewire.defaultAudioSink ? Math.round(Pipewire.defaultAudioSink.audio.volume * 100) : 0
                    activeColor: (panelWindow.muted || panelWindow.volumeLevel === 0) ? root.color2 : root.color1
                    trackColor: "transparent"
                    trackBorderColor: "transparent"
                    radius: content.effectiveRadius
                    thumbWidth: 10
                    thumbHeight: root.verticalMode ? (content.width > 0 ? content.width : panelWindow.width) : content.height
                    hideThumbAtMax: true
                    showFloatingTooltip: false
                    onInteractionStarted: {
                        root.isInteracting = true;
                        hideTimer.stop();
                    }
                    onInteractionEnded: {
                        root.isInteracting = false;
                        hideTimer.restart();
                    }
                    onRightClicked: {
                        if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                            Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
                            hideTimer.restart();
                        }
                    }
                    onMoved: (val) => {
                        if (!Pipewire.defaultAudioSink || !Pipewire.defaultAudioSink.audio)
                            return ;

                        var fraction = Math.max(0, Math.min(1, val / 100));
                        if (Pipewire.defaultAudioSink.audio.muted && fraction > 0)
                            Pipewire.defaultAudioSink.audio.muted = false;

                        Pipewire.defaultAudioSink.audio.volume = fraction;
                    }
                }

                Item {
                    id: iconArea

                    z: 3
                    anchors.bottom: verticalMode ? parent.bottom : undefined
                    anchors.horizontalCenter: verticalMode ? parent.horizontalCenter : undefined
                    anchors.left: verticalMode ? undefined : parent.left
                    anchors.verticalCenter: verticalMode ? undefined : parent.verticalCenter
                    width: verticalMode ? parent.width : 48
                    height: verticalMode ? 48 : parent.height

                    Text {
                        anchors.centerIn: parent
                        text: panelWindow.icon
                        color: (panelWindow.muted || panelWindow.volumeLevel === 0) ? root.color2 : (osdSlider.fraction > 0.15 ? root.background : root.color1)

                        font {
                            pixelSize: 22
                            family: "Material Symbols Rounded"
                        }

                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onEntered: {
                            root.isInteracting = true;
                            hideTimer.stop();
                        }
                        onExited: {
                            root.isInteracting = false;
                            hideTimer.restart();
                        }
                        onClicked: {
                            if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                                Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
                                hideTimer.restart();
                            }
                        }
                    }

                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }

                }

                Behavior on radius {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.OutCubic
                    }

                }

            }

            mask: Region {
                item: content
            }

        }

    }

}
