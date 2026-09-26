import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Animations
import qs.Asura
import qs.Services

Item {
    id: root

    property color background: Colors.cfg.background
    property color surfaceContainer: Colors.cfg.surfaceContainer
    property color primary: Colors.cfg.primary
    property color on_primary: Colors.cfg.on_primary
    property color textColor: Colors.cfg.text
    property color secondary: Colors.cfg.secondary
    property color warning: Colors.cfg.warning
    property color success: Colors.cfg.success

    implicitWidth: 360
    implicitHeight: 460
    clip: true

    MenuEntrance {
        id: soundEntrance

        active: root.visible
        duration: 320
        startOffsetY: 14
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12
        opacity: soundEntrance.opacity

        // 1. HEADER
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            spacing: 8

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Audio Control"
                    font.pixelSize: 16
                    font.bold: true
                    color: root.textColor
                }

            }

        }

        // 2. MASTER & MICROPHONE CONTROLS
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: masterCol.implicitHeight + 20
            radius: 14
            color: Qt.alpha(root.textColor, 0.04)
            border.color: Qt.alpha(root.textColor, 0.08)

            ColumnLayout {
                id: masterCol

                anchors.fill: parent
                anchors.margins: 15
                spacing: 10

                // Master Output Slider
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Master Output"
                            font.pixelSize: 10
                            font.bold: true
                            color: root.textColor
                            Layout.fillWidth: true
                        }

                        Text {
                            text: AudioService.masterMuted ? "Mudo" : AudioService.masterVolume + "%"
                            font.pixelSize: 10
                            font.bold: true
                            color: AudioService.masterMuted ? root.secondary : root.primary
                        }

                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // Mute button
                        Rectangle {
                            implicitWidth: 26
                            implicitHeight: 26
                            radius: 13
                            color: AudioService.masterMuted ? Qt.alpha(root.secondary, 0.2) : Qt.alpha(root.textColor, 0.08)

                            Text {
                                anchors.centerIn: parent
                                text: AudioService.masterMuted ? "volume_off" : "volume_up"
                                font.pixelSize: 18
                                font.family: "Material Symbols Rounded"
                                color: AudioService.masterMuted ? root.secondary : root.textColor
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: AudioService.toggleMasterMute()
                            }

                        }

                        // Slider Bar
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 15
                            color: "transparent"

                            Rectangle {
                                id: volumeBarPercent

                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * (Math.max(0, Math.min(1, AudioService.masterVolume / 100)))
                                radius: 5
                                color: AudioService.masterMuted ? root.secondary : root.primary
                            }

                            Rectangle {
                                visible: AudioService.masterVolume < 100
                                anchors.left: volumeBarPercent.right
                                anchors.verticalCenter: parent.verticalCenter
                                height: 25
                                width: 10
                                radius: 5
                                color: volumeBarPercent.color
                                border.width: 3
                                border.color: root.surfaceContainer
                            }

                            MouseArea {
                                function updateVol(mx) {
                                    var pct = Math.round(Math.max(0, Math.min(1, mx / width)) * 100);
                                    AudioService.setMasterVolume(pct);
                                }

                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: (mouse) => {
                                    return updateVol(mouse.x);
                                }
                                onPositionChanged: (mouse) => {
                                    if (pressed)
                                        updateVol(mouse.x);

                                }
                            }

                        }

                    }

                }

                // Microphone Slider
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Input"
                            font.pixelSize: 10
                            font.bold: true
                            color: root.textColor
                            Layout.fillWidth: true
                        }

                        Text {
                            text: AudioService.micMuted ? "Muted" : AudioService.micVolume + "%"
                            font.pixelSize: 10
                            font.bold: true
                            color: AudioService.micMuted ? root.secondary : root.primary
                        }

                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // Mute button
                        Rectangle {
                            implicitWidth: 26
                            implicitHeight: 26
                            radius: 13
                            color: AudioService.micMuted ? Qt.alpha(root.secondary, 0.2) : Qt.alpha(root.textColor, 0.08)

                            Text {
                                anchors.centerIn: parent
                                text: AudioService.micMuted ? "mic_off" : "mic"
                                font.pixelSize: 18
                                font.family: "Material Symbols Rounded"
                                color: AudioService.micMuted ? root.secondary : root.textColor
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: AudioService.toggleMicMute()
                            }

                        }

                        // Slider Bar
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 15
                            radius: 5
                            color: Qt.alpha(root.textColor, 0.08)
                            clip: false

                            Rectangle {
                                id: micBarPercent

                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * (Math.max(0, Math.min(1, AudioService.micVolume / 100)))
                                radius: 5
                                color: AudioService.micMuted ? root.secondary : root.primary
                            }

                            Rectangle {
                                visible: AudioService.micVolume < 100
                                anchors.left: micBarPercent.right
                                anchors.verticalCenter: parent.verticalCenter
                                height: 25
                                width: 10
                                radius: 5
                                color: micBarPercent.color
                                border.width: 3
                                border.color: root.surfaceContainer
                            }

                            MouseArea {
                                function updateVol(mx) {
                                    var pct = Math.round(Math.max(0, Math.min(1, mx / width)) * 100);
                                    AudioService.setMicVolume(pct);
                                }

                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: (mouse) => {
                                    return updateVol(mouse.x);
                                }
                                onPositionChanged: (mouse) => {
                                    if (pressed)
                                        updateVol(mouse.x);

                                }
                            }

                        }

                    }

                }

            }

        }

        // 3. APPS VOLUME MIXER SECTION
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Applications (" + AudioService.appStreams.length + ")"
                font.pixelSize: 11
                font.bold: true
                color: root.textColor
                Layout.fillWidth: true
            }

            Text {
                text: "Individual control"
                font.pixelSize: 9
                color: Qt.alpha(root.textColor, 0.45)
            }

        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: appsCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: appsCol

                width: parent.width
                spacing: 8

                Repeater {
                    model: AudioService.appStreams

                    delegate: Rectangle {
                        id: appCardRoot

                        required property var modelData

                        property int currentVol: appCardRoot.modelData ? (appCardRoot.modelData.volume !== undefined ? appCardRoot.modelData.volume : 100) : 100
                        property bool currentMute: appCardRoot.modelData ? (appCardRoot.modelData.muted !== undefined ? appCardRoot.modelData.muted : false) : false

                        Binding {
                            target: appCardRoot
                            property: "currentVol"
                            value: appCardRoot.modelData ? appCardRoot.modelData.volume : 0
                            when: !appSliderMouse.pressed
                        }

                        Binding {
                            target: appCardRoot
                            property: "currentMute"
                            value: appCardRoot.modelData ? appCardRoot.modelData.muted : false
                        }

                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        radius: 12
                        color: Qt.alpha(root.textColor, 0.04)
                        border.color: Qt.alpha(root.textColor, 0.08)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    text: appCardRoot.modelData.icon || "󰓃"
                                    font.pixelSize: 13
                                    font.family: "GeistMono Nerd Font Propo Propo"
                                    color: root.primary
                                }

                                Text {
                                    text: appCardRoot.modelData.name
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: root.textColor
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: appCardRoot.currentMute ? "Muted" : appCardRoot.currentVol + "%"
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: appCardRoot.currentMute ? root.secondary : root.primary
                                }

                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    implicitWidth: 20
                                    implicitHeight: 20
                                    radius: 10
                                    color: appCardRoot.currentMute ? Qt.alpha(root.secondary, 0.25) : Qt.alpha(root.textColor, 0.08)

                                    Text {
                                        anchors.centerIn: parent
                                        text: appCardRoot.currentMute ? "󰝟" : "󰕾"
                                        font.pixelSize: 10
                                        font.family: "GeistMono Nerd Font Propo Propo"
                                        color: appCardRoot.currentMute ? root.secondary : root.textColor
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            appCardRoot.currentMute = !appCardRoot.currentMute;
                                            AudioService.toggleAppMute(appCardRoot.modelData.id, appCardRoot.modelData.name);
                                        }
                                    }

                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 15
                                    radius: 7
                                    color: "transparent"

                                    Rectangle {
                                        id: volumeCard

                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        width: parent.width * (Math.max(0, Math.min(1, appCardRoot.currentVol / 100)))
                                        radius: 5
                                        color: appCardRoot.currentMute ? root.secondary : root.primary
                                    }

                                    Rectangle {
                                        visible: appCardRoot.currentVol < 100
                                        anchors.left: volumeCard.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: 25
                                        width: 10
                                        radius: 5
                                        color: volumeCard.color
                                        border.width: 3
                                        border.color: root.surfaceContainer
                                    }

                                    MouseArea {
                                        id: appSliderMouse

                                        function updateAppVol(mx) {
                                            var pct = Math.round(Math.max(0, Math.min(1, mx / width)) * 100);
                                            appCardRoot.currentVol = pct;
                                            AudioService.setAppVolume(appCardRoot.modelData.id, pct, appCardRoot.modelData.name);
                                        }

                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: (mouse) => {
                                            return updateAppVol(mouse.x);
                                        }
                                        onPositionChanged: (mouse) => {
                                            if (pressed)
                                                updateAppVol(mouse.x);

                                        }
                                    }

                                }

                            }

                        }

                    }

                }

                // Empty state when no apps are playing
                ColumnLayout {
                    visible: AudioService.appStreams.length === 0
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 20
                    spacing: 6

                    Text {
                        text: "volume_mute"
                        font.pixelSize: 26
                        font.family: "Material Symbols Rounded"
                        color: Qt.alpha(root.textColor, 0.25)
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "No application is currently playing audio"
                        font.pixelSize: 11
                        color: Qt.alpha(root.textColor, 0.45)
                        Layout.alignment: Qt.AlignHCenter
                    }

                }

            }

        }

        transform: Translate {
            y: soundEntrance.offsetY
        }

    }

}
