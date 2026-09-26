import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    anchors.top: true
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    width: screen.width
    height: screen.height
    color: "transparent"
    mask: Region {
        Region {
            width: screen.width
            height: 30
        }
    }
    MouseArea {
        anchors.fill: parent
        enabled: false
    }
    anchors {
        top: true
    }
    Item {
        width: parent.width
        height: parent.height

        Item {
            id: solidContainer
            anchors.fill: parent
            visible: false

            Rectangle {
                width: root.width
                height: root.height
                color: "black"
                radius: 0
            }
        }

        Item {
            id: maskContainer
            anchors.fill: parent
            visible: false

            Rectangle {
                width: root.width
                height: root.height
                color: "black"
                radius: 12
            }
        }

        OpacityMask {
            anchors.fill: parent
            source: solidContainer
            maskSource: maskContainer
            invert: true
        }
    }
}
