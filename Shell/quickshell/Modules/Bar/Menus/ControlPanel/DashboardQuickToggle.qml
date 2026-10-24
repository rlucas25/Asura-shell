import QtQuick
import QtQuick.Layouts
import qs.Asura

Item {
    id: root

    property bool active: false
    property string icon: ""
    property color activeBgColor: Colors.cfg.primary
    property color activeFgColor: Colors.cfg.on_primary
    property color inactiveBgColor: Qt.alpha(Colors.cfg.surface, Config.effectiveGeneralOpacity)
    property color hoverBgColor: Qt.alpha(Colors.cfg.surfaceContainer, Config.effectiveGeneralOpacity)
    property color inactiveFgColor: Colors.cfg.textSecondary
    property color hoverFgColor: Colors.cfg.text
    property color normalBorderColor: Qt.alpha(Colors.cfg.text, mouseArea.containsMouse ? 0.16 : 0.08)
    property color borderColor: active ? activeBgColor : normalBorderColor

    property real inactiveRadius: height / 2
    property real activeRadius: 12
    property real pressedRadius: 8

    signal clicked()

    implicitHeight: 46
    implicitWidth: 60
    height: 46

    readonly property var toggleRow: parent && parent.parent && parent.parent.isToggleRow ? parent.parent : null
    readonly property bool isCurrent: toggleRow ? (toggleRow.activeButton === root) : false

    width: toggleRow ? Math.max(16, toggleRow.baseWidth + (isCurrent ? toggleRow.activeExpansion : (-toggleRow.activeExpansion / Math.max(1, toggleRow.buttonCount - 1)))) : implicitWidth

    property bool suppressExternalBounce: false

    Timer {
        id: bounceSuppressTimer

        interval: 400
        repeat: false
        onTriggered: root.suppressExternalBounce = false
    }

    Rectangle {
        id: bgRect

        anchors.fill: parent

        radius: mouseArea.pressed ? root.pressedRadius : (root.active ? root.activeRadius : root.inactiveRadius)
        color: root.active ? root.activeBgColor : (mouseArea.containsMouse ? root.hoverBgColor : root.inactiveBgColor)
        border.color: root.borderColor
        border.width: 1

        Behavior on radius {
            NumberAnimation {
                duration: 350
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.42, 1.67, 0.21, 0.9, 1, 1]
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Text {
            anchors.centerIn: parent
            text: root.icon
            font.pixelSize: 20
            font.family: "Material Symbols Rounded"
            color: root.active ? root.activeFgColor : (mouseArea.containsMouse ? root.hoverFgColor : root.inactiveFgColor)

            scale: root.active ? 1.15 : (mouseArea.containsMouse ? 1.05 : 1.0)
            Behavior on scale {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.42, 1.67, 0.21, 0.9, 1, 1]
                }
            }
            Behavior on color {
                ColorAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
        }

        MouseArea {
            id: mouseArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onPressed: {
                if (toggleRow) {
                    toggleRow.pressButton(root);
                }
            }

            onReleased: {
                if (toggleRow) {
                    toggleRow.releaseButton();
                }
            }

            onCanceled: {
                if (toggleRow) {
                    toggleRow.releaseButton();
                }
            }

            onClicked: {
                root.suppressExternalBounce = true;
                bounceSuppressTimer.restart();
                if (toggleRow) {
                    toggleRow.triggerBounce(root);
                }
                root.clicked();
            }
        }
    }

    property bool ready: false
    Component.onCompleted: ready = true
    onActiveChanged: {
        if (ready && !suppressExternalBounce && toggleRow && !toggleRow.animRunning) {
            toggleRow.triggerBounce(root);
        }
    }
}
