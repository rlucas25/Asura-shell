import Qt5Compat.GraphicalEffects
import QtQuick
import qs.Asura

Item {
    id: root

    property real value: 0
    property color color: Colors.cfg.primary
    property color trackColor: Qt.alpha(Colors.cfg.text, 0.2)
    property real radius: height / 2
    property bool animated: true
    property int animationDuration: 250
    property bool hasBar: true
    property real targetWidth: 100
    property string text: ""
    property color textColor: Colors.cfg.background
    property font font: Qt.font({
        "pixelSize": 11,
        "family": "Google Sans",
        "bold": true
    })
    readonly property real progress: Math.max(0, Math.min(1, isNaN(value) ? 0 : value))

    implicitWidth: hasBar ? targetWidth : labelText.implicitWidth
    implicitHeight: 15

    Item {
        id: barWrapper

        anchors.fill: parent
        visible: root.hasBar
        opacity: root.hasBar ? 1 : 0

        Rectangle {
            id: maskShape

            anchors.fill: parent
            radius: root.radius
            color: "black"
            visible: false
        }

        Item {
            id: barContent

            anchors.fill: parent
            visible: false

            Rectangle {
                anchors.fill: parent
                color: root.trackColor

                Behavior on color {
                    ColorAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }

                }

            }

            Rectangle {
                id: fillerRect

                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.max(0, Math.min(parent.width, parent.width * root.progress))
                color: root.color

                Rectangle {
                    anchors.fill: parent

                    gradient: Gradient {
                        orientation: Gradient.Horizontal

                        GradientStop {
                            position: 0
                            color: "transparent"
                        }

                        GradientStop {
                            position: 0.85
                            color: Qt.alpha(Colors.cfg.textBright, 0.08)
                        }

                        GradientStop {
                            position: 1
                            color: Qt.alpha(Colors.cfg.textBright, 0.2)
                        }

                    }

                }

                Behavior on width {
                    enabled: root.animated

                    NumberAnimation {
                        duration: root.animationDuration
                        easing.type: Easing.OutCubic
                    }

                }

                Behavior on color {
                    ColorAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }

                }

            }

        }

        // OpacityMask clips barContent to maskShape, preventing any corner leaking
        OpacityMask {
            anchors.fill: parent
            source: barContent
            maskSource: maskShape
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }

        }

    }

    Text {
        id: labelText

        anchors.centerIn: parent
        text: root.text
        font: root.font
        color: root.hasBar ? root.textColor : Colors.cfg.text
        visible: root.text.length > 0

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.OutCubic
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
