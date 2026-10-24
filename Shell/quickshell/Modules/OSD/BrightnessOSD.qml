import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Animations as ANIM
import qs.Asura
import qs.Services
import qs.Components
import Quickshell.Wayland

Scope {
    id: root

    property bool verticalMode
    property color color1
    property color color2
    property color background
    property bool shouldShowOsd: false
    property bool isInteracting: false

    Connections {
        target: BrightnessService
        function onBrightnessChanged() {
            root.shouldShowOsd = true;
            if (!root.isInteracting) {
                hideTimer.restart();
            }
        }
    }

    Timer {
        id: hideTimer

        interval: 2000
        onTriggered: {
            if (!root.isInteracting) {
                root.shouldShowOsd = false;
            }
        }
    }

    LazyLoader {
        active: shouldShowOsd

        PanelWindow {
            id: panelWindow
            WlrLayershell.namespace: "brightnessOSD"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            mask: Region {
                item: content
            }
            
            property real brightnessPercent: BrightnessService.brightness / 100.0
            
            property string icon: {
                if (brightnessPercent < 0.3) return "brightness_empty";
                if (brightnessPercent < 0.7) return "brightness_6";
                return "brightness_7";
            }

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
                    var userR = (typeof Config !== "undefined" && Config.effectiveGeneralRadius !== undefined)
                        ? Config.effectiveGeneralRadius
                        : 20;
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
                scale: root.isInteracting ? (osdSlider.pressed ? 0.98 : 1.02) : 1.0

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
                    from: 1
                    to: 100
                    stepSize: 1
                    value: BrightnessService.brightness
                    activeColor: root.color1
                    trackColor: "transparent"
                    trackBorderColor: "transparent"
                    radius: content.effectiveRadius
                    thumbWidth: 10
                    showFloatingTooltip: false

                    onInteractionStarted: {
                        root.isInteracting = true;
                        hideTimer.stop();
                    }

                    onInteractionEnded: {
                        root.isInteracting = false;
                        hideTimer.restart();
                    }

                    onMoved: (val) => {
                        BrightnessService.setBrightness(Math.round(val));
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
                        color: osdSlider.fraction > 0.15 ? root.background : root.color1

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
                            var target = (BrightnessService.brightness > 50) ? 30 : 100;
                            BrightnessService.setBrightness(target);
                            hideTimer.restart();
                        }
                    }
                }

            }

        }

    }

}