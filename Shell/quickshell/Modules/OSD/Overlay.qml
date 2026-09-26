import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import qs.Asura

PanelWindow {
    id: root
    property color background: Colors.cfg.background
    property alias color1: root.background
    property real _opacity

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    mask: Region {}

    anchors {
        top: true
        left: true
        bottom: true
        right: true
    }

    Item {
        id: container
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            color: root.color1
            opacity: _opacity
            
            layer.enabled: true
            layer.effect: MultiEffect {
                maskSource: mask
                maskEnabled: true
                maskInverted: true
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1
            }
        }

        Item {
            id: mask
            anchors.fill: parent
            layer.enabled: true
            visible: false

            Rectangle {
                anchors.fill: parent
                radius: 18
            }
        }
    }
}