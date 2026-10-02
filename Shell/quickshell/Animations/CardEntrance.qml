import QtQuick

QtObject {
    id: root

    // Controls whether entrance animation should run
    property bool active: true

    // Animation timing and physics parameters
    property int duration: 420
    property int delay: 0
    property real startOffsetY: 20
    property real startScale: 0.94
    property real overshoot: 1.12

    // Computed animated values
    readonly property real progress: animProgress.value
    readonly property real opacity: Math.max(0.0, Math.min(1.0, progress))
    readonly property real offsetY: startOffsetY * (1.0 - progress)
    readonly property real scale: startScale + (1.0 - startScale) * progress
    readonly property bool running: animSeq.running

    function restart() {
        animSeq.stop();
        animProgress.value = 0.0;
        if (active) {
            animSeq.restart();
        }
    }

    onActiveChanged: {
        if (active) {
            restart();
        } else {
            animSeq.stop();
            animProgress.value = 0.0;
        }
    }

    property QtObject _internal: QtObject {
        id: animProgress
        property real value: root.active ? 1.0 : 0.0
    }

    property SequentialAnimation animation: SequentialAnimation {
        id: animSeq

        PauseAnimation {
            duration: Math.max(0, root.delay)
        }

        NumberAnimation {
            target: animProgress
            property: "value"
            from: 0.0
            to: 1.0
            duration: root.duration
            easing.type: Easing.OutBack
            easing.overshoot: root.overshoot
        }
    }

    Component.onCompleted: {
        if (active) {
            restart();
        } else {
            animProgress.value = 0.0;
        }
    }
}
