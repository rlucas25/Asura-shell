import QtQuick
import QtQuick.Shapes
import qs.Asura

Item {
    id: root

    property color color: "black"
    property int cornerRadius: 50
    property string position: "topRight" // "topLeft", "topRight", "bottomLeft", "bottomRight"

    // Melt curvature factor:
    // 0.55228 for geometric circular arc, ~0.48 for refined organic squircle / liquid melt
    property real curvature: (Config.cfg && Config.cfg.barMeltStyle === "circular") ? 0.55228 : 0.48
    readonly property bool meltEnabled: (Config.cfg && Config.cfg.barMeltEnabled !== undefined) ? Config.cfg.barMeltEnabled : true

    visible: meltEnabled

    implicitWidth: 30
    implicitHeight: 30

    Shape {
        id: shape
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        asynchronous: false

        ShapePath {
            strokeWidth: 0
            fillColor: root.color
            pathHints: ShapePath.PathSolid & ShapePath.PathNonIntersecting

            startX: {
                switch (root.position) {
                    case "topLeft": return root.width;
                    case "topRight": return 0;
                    case "bottomLeft": return root.width;
                    case "bottomRight": return 0;
                    default: return 0;
                }
            }
            startY: {
                switch (root.position) {
                    case "topLeft": return 0;
                    case "topRight": return 0;
                    case "bottomLeft": return root.height;
                    case "bottomRight": return root.height;
                    default: return 0;
                }
            }

            PathLine {
                x: {
                    switch (root.position) {
                        case "topLeft": return 0;
                        case "topRight": return root.width;
                        case "bottomLeft": return 0;
                        case "bottomRight": return root.width;
                        default: return root.width;
                    }
                }
                y: {
                    switch (root.position) {
                        case "topLeft": return 0;
                        case "topRight": return 0;
                        case "bottomLeft": return root.height;
                        case "bottomRight": return root.height;
                        default: return 0;
                    }
                }
            }

            PathLine {
                x: {
                    switch (root.position) {
                        case "topLeft": return 0;
                        case "topRight": return root.width;
                        case "bottomLeft": return 0;
                        case "bottomRight": return root.width;
                        default: return root.width;
                    }
                }
                y: {
                    switch (root.position) {
                        case "topLeft": return root.height;
                        case "topRight": return root.height;
                        case "bottomLeft": return 0;
                        case "bottomRight": return 0;
                        default: return root.height;
                    }
                }
            }

            PathCubic {
                x: {
                    switch (root.position) {
                        case "topLeft": return root.width;
                        case "topRight": return 0;
                        case "bottomLeft": return root.width;
                        case "bottomRight": return 0;
                        default: return 0;
                    }
                }
                y: {
                    switch (root.position) {
                        case "topLeft": return 0;
                        case "topRight": return 0;
                        case "bottomLeft": return root.height;
                        case "bottomRight": return root.height;
                        default: return 0;
                    }
                }
                control1X: {
                    var c = root.curvature;
                    switch (root.position) {
                        case "topLeft": return 0;
                        case "topRight": return root.width;
                        case "bottomLeft": return 0;
                        case "bottomRight": return root.width;
                        default: return root.width;
                    }
                }
                control1Y: {
                    var c = root.curvature;
                    switch (root.position) {
                        case "topLeft": return root.height * (1.0 - c);
                        case "topRight": return root.height * (1.0 - c);
                        case "bottomLeft": return root.height * c;
                        case "bottomRight": return root.height * c;
                        default: return root.height * (1.0 - c);
                    }
                }
                control2X: {
                    var c = root.curvature;
                    switch (root.position) {
                        case "topLeft": return root.width * (1.0 - c);
                        case "topRight": return root.width * c;
                        case "bottomLeft": return root.width * (1.0 - c);
                        case "bottomRight": return root.width * c;
                        default: return root.width * c;
                    }
                }
                control2Y: {
                    switch (root.position) {
                        case "topLeft": return 0;
                        case "topRight": return 0;
                        case "bottomLeft": return root.height;
                        case "bottomRight": return root.height;
                        default: return 0;
                    }
                }
            }
        }
    }
}