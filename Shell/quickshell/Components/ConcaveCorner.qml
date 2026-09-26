import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property color color: "black"
    property int cornerRadius: 50
    
    property string position: "topRight" 

    Item {
        id: solidContainer
        anchors.fill: parent
        visible: false
        Rectangle {
            anchors.fill: parent
            color: root.color
        }
    }

    Item {
        id: maskContainer
        anchors.fill: parent
        visible: false
        Rectangle {
            anchors.fill: parent
            color: "black"
            
            topLeftRadius: root.position === "topLeft" ? root.cornerRadius : 0
            topRightRadius: root.position === "topRight" ? root.cornerRadius : 0
            bottomLeftRadius: root.position === "bottomLeft" ? root.cornerRadius : 0
            bottomRightRadius: root.position === "bottomRight" ? root.cornerRadius : 0
        }
    }

    OpacityMask {
        anchors.fill: parent
        source: solidContainer
        maskSource: maskContainer
        invert: true
    }
}