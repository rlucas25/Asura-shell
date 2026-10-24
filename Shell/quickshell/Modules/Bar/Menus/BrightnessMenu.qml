import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Animations
import qs.Asura
import qs.Services
import qs.Components

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

    implicitWidth: 320
    implicitHeight: 210
    clip: true

    MenuEntrance {
        id: menuEntrance

        active: root.visible
        duration: 320
        startOffsetY: 14
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12
        opacity: menuEntrance.opacity

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            spacing: 8

            Rectangle {
                implicitWidth: 32
                implicitHeight: 32
                radius: 16
                color: Qt.alpha(root.primary, 0.15)

                Text {
                    anchors.centerIn: parent
                    text: {
                        var b = BrightnessService.brightness;
                        if (b <= 25) return "brightness_low";
                        if (b <= 70) return "brightness_medium";
                        return "brightness_high";
                    }
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 18
                    color: root.primary
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Display Brightness"
                    font.pixelSize: 15
                    font.bold: true
                    color: root.textColor
                }

                Text {
                    text: "Screen backlight level"
                    font.pixelSize: 11
                    color: Qt.alpha(root.textColor, 0.6)
                }
            }

            Rectangle {
                implicitWidth: percentText.implicitWidth + 14
                implicitHeight: 24
                radius: 12
                color: Qt.alpha(root.primary, 0.15)

                Text {
                    id: percentText
                    anchors.centerIn: parent
                    text: BrightnessService.brightness + "%"
                    font.pixelSize: 11
                    font.bold: true
                    color: root.primary
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            radius: 14
            color: Qt.alpha(root.textColor, 0.04)
            border.color: Qt.alpha(root.textColor, 0.08)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        implicitWidth: 26
                        implicitHeight: 26
                        radius: 13
                        color: Qt.alpha(root.textColor, 0.08)

                        Text {
                            anchors.centerIn: parent
                            text: "brightness_low"
                            font.pixelSize: 16
                            font.family: "Material Symbols Rounded"
                            color: root.textColor
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: BrightnessService.setBrightness(15)
                        }
                    }

                    SettingSlider {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 16
                        compact: true
                        from: 1
                        to: 100
                        stepSize: 1
                        value: BrightnessService.brightness
                        activeColor: root.primary
                        trackColor: Qt.alpha(root.textColor, 0.1)
                        radius: 8
                        showFloatingTooltip: false
                        onMoved: (val) => BrightnessService.setBrightness(Math.round(val))
                        onValueCommitted: (val) => BrightnessService.setBrightness(Math.round(val))
                    }

                    Rectangle {
                        implicitWidth: 26
                        implicitHeight: 26
                        radius: 13
                        color: Qt.alpha(root.textColor, 0.08)

                        Text {
                            anchors.centerIn: parent
                            text: "brightness_high"
                            font.pixelSize: 16
                            font.family: "Material Symbols Rounded"
                            color: root.textColor
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: BrightnessService.setBrightness(100)
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: [25, 50, 75, 100]

                delegate: Rectangle {
                    required property int modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: 8

                    readonly property bool isSelected: Math.abs(BrightnessService.brightness - modelData) <= 5
                    color: isSelected ? Qt.alpha(root.primary, 0.25) : Qt.alpha(root.textColor, 0.05)
                    border.color: isSelected ? root.primary : Qt.alpha(root.textColor, 0.1)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: modelData + "%"
                        font.pixelSize: 11
                        font.bold: isSelected
                        color: isSelected ? root.primary : root.textColor
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: BrightnessService.setBrightness(modelData)
                    }
                }
            }
        }
    }
}
