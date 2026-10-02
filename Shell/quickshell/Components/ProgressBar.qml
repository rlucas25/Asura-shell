import Qt5Compat.GraphicalEffects
import QtQuick
import qs.Asura

Item {
    id: root

    // Progress value normalized between 0.0 and 1.0
    property real value: 0
    // Visual styling properties
    property color color: Colors.cfg.primary
    property color trackColor: Qt.alpha(Colors.cfg.text, 0.2)
    property real radius: height / 2
    // Animation configuration
    property bool animated: true
    property int animationDuration: 250
    // Visibility and sizing controls
    property bool hasBar: true
    property real targetWidth: 100
    // Centered text label
    property string text: ""
    property color textColor: Colors.cfg.background
    property font font: Qt.font({
        "pixelSize": 11,
        "family": "Google Sans",
        "bold": true
    })
    // Clamped progress value
    readonly property real progress: Math.max(0, Math.min(1, isNaN(value) ? 0 : value))

    implicitWidth: hasBar ? targetWidth : labelText.implicitWidth
    implicitHeight: 15

    // Masked container: strictly clips filler and track within capsule boundaries
    Item {
        id: barWrapper

        anchors.fill: parent
        visible: root.hasBar
        opacity: root.hasBar ? 1 : 0

        // Mask shape defining the capsule boundaries with rounded ends
        Rectangle {
            id: maskShape

            anchors.fill: parent
            radius: root.radius
            color: "black"
            visible: false
        }

        // Content layer containing the track background and expanding filler
        Item {
            id: barContent

            anchors.fill: parent
            visible: false

            // Background track
            Rectangle {
                anchors.fill: parent
                color: root.trackColor
            }

            // Expanding progress filler (guaranteed not to leak outside capsule mask)
            Rectangle {
                id: fillerRect

                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.max(0, Math.min(parent.width, parent.width * root.progress))
                color: root.color

                Behavior on width {
                    enabled: root.animated

                    NumberAnimation {
                        duration: root.animationDuration
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
            }

        }

    }

    // Centered label text on top of the progress bar
    Text {
        id: labelText

        anchors.centerIn: parent
        text: root.text
        font: root.font
        color: root.hasBar ? root.textColor : Colors.cfg.text
        visible: root.text.length > 0
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }

    }

}
