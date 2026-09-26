import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property real value: 0.0
    property color color: "white"
    property real lineWidth: 7

    readonly property real progress: Math.max(0.0, Math.min(1.0, value))

    implicitWidth: 100
    implicitHeight: 100

    Shape {
        anchors.fill: parent

        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: Qt.alpha(root.color, 0.15)
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
            strokeColor: root.color
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

                startAngle: -90
                sweepAngle: root.progress * 360
            }
        }
    }
}