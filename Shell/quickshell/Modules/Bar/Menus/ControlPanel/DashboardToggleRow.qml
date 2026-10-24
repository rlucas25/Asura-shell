import QtQuick

Item {
    id: root

    readonly property bool isToggleRow: true
    default property alias content: row.data
    property real spacing: 8

    implicitHeight: 46
    implicitWidth: 260

    property var activeButton: null
    property real activeExpansion: 0
    readonly property bool animRunning: rowBounceAnim.running

    readonly property int buttonCount: row.children.length > 0 ? row.children.length : 4
    readonly property real availableWidth: Math.max(10, width - spacing * (buttonCount - 1))
    readonly property real baseWidth: availableWidth / buttonCount

    ParallelAnimation {
        id: pressExpandAnim

        NumberAnimation {
            target: root
            property: "activeExpansion"
            to: 22
            duration: 120
            easing.type: Easing.OutQuad
        }
    }

    ParallelAnimation {
        id: releaseCollapseAnim

        NumberAnimation {
            target: root
            property: "activeExpansion"
            to: 0
            duration: 180
            easing.type: Easing.OutCubic
        }
        onFinished: {
            if (!rowBounceAnim.running)
                root.activeButton = null;
        }
    }

    SequentialAnimation {
        id: rowBounceAnim
        alwaysRunToEnd: true

        NumberAnimation {
            target: root
            property: "activeExpansion"
            to: 24
            duration: Math.max(30, 90 - (root.activeExpansion / 24) * 70)
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root
            property: "activeExpansion"
            to: -8
            duration: 160
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.42, 1.67, 0.21, 0.9, 1, 1]
        }
        NumberAnimation {
            target: root
            property: "activeExpansion"
            to: 0
            duration: 100
            easing.type: Easing.OutCubic
        }
        onFinished: {
            root.activeButton = null;
        }
    }

    function pressButton(btn) {
        if (rowBounceAnim.running)
            return ;

        activeButton = btn;
        releaseCollapseAnim.stop();
        pressExpandAnim.restart();
    }

    function releaseButton() {
        if (rowBounceAnim.running)
            return ;

        pressExpandAnim.stop();
        releaseCollapseAnim.restart();
    }

    function triggerBounce(btn) {
        activeButton = btn;
        pressExpandAnim.stop();
        releaseCollapseAnim.stop();
        rowBounceAnim.restart();
    }

    Row {
        id: row

        anchors.fill: parent
        spacing: root.spacing
    }
}
