import QtQuick

QtObject {
    id: root

    // Controls whether entrance animation should run
    property bool active: true

    // Configuration parameters
    property int duration: 320
    property int delay: 0
    property real startOffsetY: 14
    property real startScale: 0.98

    // Animated values for consumers to bind to:
    // opacity: binds to Item.opacity
    // offsetY: binds to transform Translate.y
    // scale: binds to Item.scale
    readonly property real progress: animProgress.value
    readonly property real opacity: Math.max(0.0, Math.min(1.0, progress))
    readonly property real offsetY: startOffsetY * (1.0 - progress)
    readonly property real scale: startScale + (1.0 - startScale) * progress
    readonly property bool running: animSeq.running

    // Stagger helper: calculates delay for a given index (in ms)
    function staggerDelay(index, stepMs) {
        var step = stepMs !== undefined ? stepMs : 35;
        return delay + (index * step);
    }

    // Explicit controls
    function restart() {
        animSeq.stop();
        animProgress.value = 0.0;
        if (active) {
            animSeq.restart();
        }
    }

    function reset() {
        animSeq.stop();
        animProgress.value = active ? 1.0 : 0.0;
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
            easing.type: Easing.OutCubic
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
