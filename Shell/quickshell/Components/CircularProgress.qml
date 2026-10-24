import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property real value: 0.0
    property color color: "white"
    property color trackColor: Qt.alpha(root.color, 0.15)
    property real lineWidth: 7

    readonly property real progress: Math.max(0.0, Math.min(1.0, value))
    property real animatedProgress: progress

    Behavior on animatedProgress {
        NumberAnimation {
            duration: 350
            easing.type: Easing.OutCubic
        }
    }

    implicitWidth: 100
    implicitHeight: 100

    Shape {
        anchors.fill: parent

        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.trackColor
            strokeWidth: root.lineWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2

                radiusX: Math.max(
                    0,
                    Math.min(root.width, root.height) / 2 - root.lineWidth / 2
                )

                radiusY: Math.max(
                    0,
                    Math.min(root.width, root.height) / 2 - root.lineWidth / 2
                )

                startAngle: 0
                sweepAngle: 360
            }
        }

        ShapePath {
            strokeColor: root.progress > 0.001 ? root.color : "transparent"
            strokeWidth: root.lineWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            Behavior on strokeColor {
                ColorAnimation {
                    duration: 200
                }
            }

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2

                radiusX: Math.max(
                    0,
                    Math.min(root.width, root.height) / 2 - root.lineWidth / 2
                )

                radiusY: Math.max(
                    0,
                    Math.min(root.width, root.height) / 2 - root.lineWidth / 2
                )

                startAngle: -90
                sweepAngle: root.animatedProgress * 360
            }
        }
    }
}