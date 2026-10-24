import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var screen
    readonly property int cornerRadius: 20
    readonly property color cornerColor: "#000000"

    WlrLayershell.namespace: "asura-screen-corners-" + (screen ? screen.name : "default")
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Item {
        anchors.top: parent.top
        anchors.left: parent.left
        width: root.cornerRadius
        height: root.cornerRadius

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            layer.enabled: true
            layer.smooth: true

            ShapePath {
                strokeWidth: 0
                fillColor: root.cornerColor
                pathHints: ShapePath.PathSolid & ShapePath.PathNonIntersecting
                startX: 0
                startY: 0

                PathLine {
                    x: 0
                    y: root.cornerRadius
                }

                PathAngleArc {
                    moveToStart: false
                    centerX: root.cornerRadius
                    centerY: root.cornerRadius
                    radiusX: root.cornerRadius
                    radiusY: root.cornerRadius
                    startAngle: 180
                    sweepAngle: 90
                }

                PathLine {
                    x: 0
                    y: 0
                }

            }

        }

    }

    Item {
        anchors.top: parent.top
        anchors.right: parent.right
        width: root.cornerRadius
        height: root.cornerRadius

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            layer.enabled: true
            layer.smooth: true

            ShapePath {
                strokeWidth: 0
                fillColor: root.cornerColor
                pathHints: ShapePath.PathSolid & ShapePath.PathNonIntersecting
                startX: root.cornerRadius
                startY: 0

                PathLine {
                    x: 0
                    y: 0
                }

                PathAngleArc {
                    moveToStart: false
                    centerX: 0
                    centerY: root.cornerRadius
                    radiusX: root.cornerRadius
                    radiusY: root.cornerRadius
                    startAngle: 270
                    sweepAngle: 90
                }

                PathLine {
                    x: root.cornerRadius
                    y: 0
                }

            }

        }

    }

    Item {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: root.cornerRadius
        height: root.cornerRadius

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            layer.enabled: true
            layer.smooth: true

            ShapePath {
                strokeWidth: 0
                fillColor: root.cornerColor
                pathHints: ShapePath.PathSolid & ShapePath.PathNonIntersecting
                startX: 0
                startY: root.cornerRadius

                PathLine {
                    x: root.cornerRadius
                    y: root.cornerRadius
                }

                PathAngleArc {
                    moveToStart: false
                    centerX: root.cornerRadius
                    centerY: 0
                    radiusX: root.cornerRadius
                    radiusY: root.cornerRadius
                    startAngle: 90
                    sweepAngle: 90
                }

                PathLine {
                    x: 0
                    y: root.cornerRadius
                }

            }

        }

    }

    Item {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: root.cornerRadius
        height: root.cornerRadius

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            layer.enabled: true
            layer.smooth: true

            ShapePath {
                strokeWidth: 0
                fillColor: root.cornerColor
                pathHints: ShapePath.PathSolid & ShapePath.PathNonIntersecting
                startX: root.cornerRadius
                startY: root.cornerRadius

                PathLine {
                    x: 0
                    y: root.cornerRadius
                }

                PathAngleArc {
                    moveToStart: false
                    centerX: 0
                    centerY: 0
                    radiusX: root.cornerRadius
                    radiusY: root.cornerRadius
                    startAngle: 90
                    sweepAngle: -90
                }

                PathLine {
                    x: root.cornerRadius
                    y: root.cornerRadius
                }

            }

        }

    }

    // Empty input mask guarantees zero pointer interception across the entire surface
    mask: Region {
    }

}
