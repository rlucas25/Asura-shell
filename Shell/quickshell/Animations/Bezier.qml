import QtQuick


NumberAnimation {
    id: bezier
    duration: 700
    easing.type: Easing.Bezier
    easing.bezierCurve: [0.38, 1.21, 0.22, 1, 1, 1]
}
