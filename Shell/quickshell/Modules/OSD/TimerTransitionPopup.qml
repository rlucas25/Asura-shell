import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Asura

PanelWindow {
    id: root

    property color primary: Colors.cfg.primary
    property color background: Colors.cfg.background
    property color text: Colors.cfg.text

    property string popupIcon: ""
    property string popupMessage: ""
    property bool _active: false

    function show(icon, message) {
        showAnim.stop();
        hideAnim.stop();
        overlayBg.opacity = 0.0;
        popupCard.scale   = 0.0;
        popupCard.opacity = 0.0;

        popupIcon    = icon;
        popupMessage = message;
        _active      = true;

        showAnim.start();
        dismissTimer.restart();
    }

    WlrLayershell.namespace: "TimerTransitionPopup"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    implicitWidth:  screen.width
    implicitHeight: screen.height
    color: "transparent"

    visible: _active

    mask: Region {}

    Timer {
        id: dismissTimer
        interval: 3000
        onTriggered: hideAnim.start()
    }

    ParallelAnimation {
        id: showAnim

        NumberAnimation {
            target: overlayBg
            property: "opacity"
            to: 0.62
            duration: 380
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: popupCard
            property: "opacity"
            to: 1.0
            duration: 320
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: popupCard
            property: "scale"
            to: 1.0
            duration: 560
            easing.type: Easing.OutBack
            easing.overshoot: 1.8
        }
    }

    SequentialAnimation {
        id: hideAnim

        ParallelAnimation {
            NumberAnimation {
                target: overlayBg
                property: "opacity"
                to: 0.0
                duration: 320
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: popupCard
                property: "opacity"
                to: 0.0
                duration: 260
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: popupCard
                property: "scale"
                to: 0.82
                duration: 260
                easing.type: Easing.InCubic
            }
        }

        ScriptAction {
            script: root._active = false
        }
    }

    Rectangle {
        id: overlayBg
        anchors.fill: parent
        color: "#000000"
        opacity: 0.0
    }

    Rectangle {
        id: popupCard
        anchors.centerIn: parent
        width:  370
        height: 210
        radius: Math.round(Config.effectiveMenuRadius * 1.6)

        color: Qt.rgba(root.background.r, root.background.g, root.background.b, 0.93)

        border.color: Qt.alpha(root.primary, 0.40)
        border.width: 1.5

        scale:   0.0
        opacity: 0.0

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.color: Qt.alpha(root.primary, 0.10)
            border.width: 6
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 16

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.popupIcon
                font.pixelSize: 56
                font.family: "Material Symbols Rounded"
                color: root.primary
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr(root.popupMessage)
                font.pixelSize: 22
                font.family:    "Google Sans"
                font.bold: true
                color: root.text
            }
        }
    }
}
