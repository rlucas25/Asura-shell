import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property real value: 0.0
    property color color: "white"

    property real lineWidth: 8

    property real trackOpacity: 0.12

    // Quanto a forma "respira"
    property real organicAmount: 1.8

    readonly property real progress:
        Math.max(0.0, Math.min(1.0, root.value))

    // Valor usado visualmente.
    // Evita que o indicador pule de um valor para outro.
    property real animatedProgress: 0.0

    implicitWidth: 100
    implicitHeight: 100

    Behavior on animatedProgress {
        NumberAnimation {
            duration: 450
            easing.type: Easing.OutCubic
        }
    }

    onProgressChanged: {
        animatedProgress = progress
    }

    Component.onCompleted: {
                animatedProgress = progress

        entranceAnimation.start()
    }

    // Pequena animação de entrada
    scale: 0.92
    opacity: 0


    ParallelAnimation {
        id: entranceAnimation

        NumberAnimation {
            target: root
            property: "scale"
            from: 0.92
            to: 1.0
            duration: 500
            easing.type: Easing.OutBack
        }

        NumberAnimation {
            target: root
            property: "opacity"
            from: 0
            to: 1
            duration: 350
            easing.type: Easing.OutCubic
        }
    }

    Shape {
        id: indicator

        anchors.fill: parent

        preferredRendererType: Shape.CurveRenderer

        // ---------------------------------------------------------
        // TRACK
        // ---------------------------------------------------------

        ShapePath {
            strokeColor: Qt.alpha(
                root.color,
                root.trackOpacity
            )

            strokeWidth: root.lineWidth
            fillColor: "transparent"

            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2

                radiusX: Math.max(
                    0,
                    Math.min(root.width, root.height) / 2
                    - root.lineWidth / 2
                )

                radiusY: Math.max(
                    0,
                    Math.min(root.width, root.height) / 2
                    - root.lineWidth / 2
                )

                startAngle: 0
                sweepAngle: 360
            }
        }

        // ---------------------------------------------------------
        // ACTIVE ARC
        // ---------------------------------------------------------

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.lineWidth
                + Math.sin(root.animatedProgress * Math.PI) * root.organicAmount

            fillColor: "transparent"

            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2

                radiusX: Math.max(
                    0,
                    Math.min(root.width, root.height) / 2
                    - root.lineWidth / 2
                )

                radiusY: Math.max(
                    0,
                    Math.min(root.width, root.height) / 2
                    - root.lineWidth / 2
                )

                startAngle: -90

                sweepAngle:
                    root.animatedProgress * 360
            }
        }
    }

    // -------------------------------------------------------------
    // ORGANIC END CAP
    //
    // Um pequeno "blob" acompanha o final do progresso.
    // Isso quebra a aparência excessivamente geométrica do arco.
    // -------------------------------------------------------------

    Item {
        id: endBlob

        visible: root.animatedProgress > 0.002

        readonly property real angle:
            (-90 + root.animatedProgress * 360)
            * Math.PI / 180

        readonly property real radius:
            Math.max(
                0,
                Math.min(root.width, root.height) / 2
                - root.lineWidth / 2
            )

        readonly property real centerX:
            root.width / 2
            + Math.cos(angle) * radius

        readonly property real centerY:
            root.height / 2
            + Math.sin(angle) * radius

        x: centerX - width / 2
        y: centerY - height / 2

        width:
            root.lineWidth
            + Math.sin(root.animatedProgress * Math.PI) * 3

        height:
            width * 0.92

        rotation:
            root.animatedProgress * 360

        opacity:
            root.animatedProgress > 0.995
            ? 0
            : 1

        Rectangle {
            anchors.fill: parent

            radius: width / 2
            color: root.color

            transformOrigin: Item.Center

            scale: 1.0
        }

        Behavior on width {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }
    }
}