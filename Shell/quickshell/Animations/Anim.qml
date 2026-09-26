import QtQuick

NumberAnimation {
    id: root

    property string type: "emphasized" 

    duration: {
        switch (type) {
            case "effects":
                return 220;
            case "standard":
                return 300;
            case "expressiveFast":
                return 320;
            case "expressive":
            case "emphasized":
            default:
                return 450;
        }
    }

    easing.type: Easing.BezierSpline
    easing.bezierCurve: {
        switch (type) {
            case "expressive":
                return [0.38, 1.21, 0.22, 1.0, 1.0, 1.0];
            case "expressiveFast":
                return [0.42, 1.67, 0.21, 0.9, 1.0, 1.0];
            case "effects":
                return [0.34, 0.8, 0.34, 1.0, 1.0, 1.0];
            case "standard":
                return [0.4, 0.0, 0.2, 1.0, 1.0, 1.0];
            case "emphasized":
            default:
                return [0.2, 0.0, 0.0, 1.0, 1.0, 1.0];
        }
    }
}