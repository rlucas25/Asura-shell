import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property real value: 0
    property color color: "white"
    property color trackColor: Qt.alpha(root.color, 0.18)
    property color strokeColor: "transparent"
    property real strokeWidth: 0
    property real startAngle: -90
    property bool clockwise: true
    property bool animated: true
    property int animationDuration: 280
    readonly property real targetProgress: Math.max(0, Math.min(1, isNaN(value) ? 0 : value))
    property real animProgress: targetProgress
    readonly property real progress: root.animated ? animProgress : targetProgress
    readonly property real radius: Math.max(0, Math.min(width, height) / 2 - (strokeWidth / 2))
    readonly property real centerX: width / 2
    readonly property real centerY: height / 2

    implicitWidth: 20
    implicitHeight: 20

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.trackColor
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        visible: root.progress > 0.001 && root.progress < 0.999

        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            strokeWidth: 0
            startX: root.centerX
            startY: root.centerY

            PathAngleArc {
                centerX: root.centerX
                centerY: root.centerY
                radiusX: root.radius
                radiusY: root.radius
                startAngle: root.startAngle
                sweepAngle: root.clockwise ? (root.progress * 360) : (-root.progress * 360)
            }

            PathLine {
                x: root.centerX
                y: root.centerY
            }

        }

    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.color
        border.color: root.strokeColor
        border.width: root.strokeWidth
        visible: root.progress >= 0.999
    }

    Behavior on animProgress {
        enabled: root.animated

        NumberAnimation {
            duration: root.animationDuration
            easing.type: Easing.OutCubic
        }

    }

}
