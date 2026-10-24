import QtQuick
import QtQuick.Layouts
import qs.Asura

Item {
    id: root

    property string barPosition: "top"
    property int barMode: 1 // 0: island, 1: full, 2: capsules
    property var activeCapsules: ({ "left": true, "center": true, "right": true })
    property color barBackground: Colors.cfg.surfaceContainer
    property color primaryColor: Colors.cfg.primary
    property color secondaryColor: Colors.cfg.secondary
    property color textColor: Colors.cfg.text
    property bool isHighlighted: false

    readonly property bool isVertical: barPosition === "left" || barPosition === "right"
    readonly property bool hasLeft: activeCapsules ? (activeCapsules.left !== false) : true
    readonly property bool hasCenter: activeCapsules ? (activeCapsules.center !== false) : true
    readonly property bool hasRight: activeCapsules ? (activeCapsules.right !== false) : true

    anchors.fill: parent

    Rectangle {
        id: fullBar
        visible: root.barMode === 1

        color: Qt.alpha(root.barBackground, 0.96)
        border.color: root.isHighlighted ? root.primaryColor : Qt.alpha(root.primaryColor, 0.55)
        border.width: 1.5

        anchors.top: (root.barPosition === "bottom") ? undefined : parent.top
        anchors.bottom: (root.barPosition === "top") ? undefined : parent.bottom
        anchors.left: (root.barPosition === "right") ? undefined : parent.left
        anchors.right: (root.barPosition === "left") ? undefined : parent.right

        width: root.isVertical ? 16 : parent.width
        height: root.isVertical ? parent.height : 16

        Item {
            anchors.fill: parent
            visible: !root.isVertical

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Rectangle {
                    width: 8
                    height: 8
                    radius: 2.5
                    color: root.primaryColor
                }

                Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Qt.alpha(root.textColor, 0.75)
                }

                Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Qt.alpha(root.textColor, 0.45)
                }

                Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Qt.alpha(root.textColor, 0.45)
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 28
                height: 7
                radius: 3.5
                color: Qt.alpha(root.secondaryColor, 0.75)
                border.color: Qt.alpha("white", 0.25)
                border.width: 0.5
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Qt.alpha(root.textColor, 0.75)
                }

                Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Qt.alpha(root.textColor, 0.75)
                }

                Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Qt.alpha(root.textColor, 0.75)
                }

                Rectangle {
                    width: 7
                    height: 7
                    radius: 2.5
                    color: root.primaryColor
                }
            }
        }

        Item {
            anchors.fill: parent
            visible: root.isVertical

            Column {
                anchors.top: parent.top
                anchors.topMargin: 24
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4

                Rectangle {
                    width: 8
                    height: 8
                    radius: 2.5
                    color: root.primaryColor
                }

                Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Qt.alpha(root.textColor, 0.75)
                }

                Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Qt.alpha(root.textColor, 0.45)
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 7
                height: 28
                radius: 3.5
                color: Qt.alpha(root.secondaryColor, 0.75)
                border.color: Qt.alpha("white", 0.25)
                border.width: 0.5
            }

            Column {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 24
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4

                Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Qt.alpha(root.textColor, 0.75)
                }

                Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Qt.alpha(root.textColor, 0.75)
                }

                Rectangle {
                    width: 7
                    height: 7
                    radius: 2.5
                    color: root.primaryColor
                }
            }
        }
    }

    Rectangle {
        id: islandShadow
        visible: root.barMode === 0

        anchors.fill: islandBar
        anchors.topMargin: (root.barPosition === "top") ? 1 : 0
        anchors.bottomMargin: (root.barPosition === "bottom") ? -1 : 0
        anchors.leftMargin: (root.barPosition === "left") ? 1 : 0
        anchors.rightMargin: (root.barPosition === "right") ? -1 : 0
        radius: 8
        color: Qt.rgba(0, 0, 0, 0.45)
        z: 1
    }

    Rectangle {
        id: islandBar
        visible: root.barMode === 0
        z: 2

        color: Qt.alpha(root.barBackground, 0.96)
        border.color: root.isHighlighted ? root.primaryColor : Qt.alpha(root.primaryColor, 0.6)
        border.width: 1.5
        radius: 8

        anchors.top: (root.barPosition === "top") ? parent.top : undefined
        anchors.topMargin: (root.barPosition === "top") ? 7 : 0

        anchors.bottom: (root.barPosition === "bottom") ? parent.bottom : undefined
        anchors.bottomMargin: (root.barPosition === "bottom") ? 7 : 0

        anchors.left: (root.barPosition === "left") ? parent.left : undefined
        anchors.leftMargin: (root.barPosition === "left") ? 7 : 0

        anchors.right: (root.barPosition === "right") ? parent.right : undefined
        anchors.rightMargin: (root.barPosition === "right") ? 7 : 0

        anchors.horizontalCenter: !root.isVertical ? parent.horizontalCenter : undefined
        anchors.verticalCenter: root.isVertical ? parent.verticalCenter : undefined

        width: root.isVertical ? 16 : (parent.width * 0.75)
        height: root.isVertical ? (parent.height * 0.72) : 16

        Item {
            anchors.fill: parent
            visible: !root.isVertical

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Rectangle {
                    width: 7
                    height: 7
                    radius: 2
                    color: root.primaryColor
                }

                Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Qt.alpha(root.textColor, 0.7)
                }

                Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Qt.alpha(root.textColor, 0.45)
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 24
                height: 7
                radius: 3.5
                color: Qt.alpha(root.secondaryColor, 0.75)
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Qt.alpha(root.textColor, 0.75)
                }

                Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Qt.alpha(root.textColor, 0.75)
                }

                Rectangle {
                    width: 7
                    height: 7
                    radius: 2
                    color: root.primaryColor
                }
            }
        }

        Item {
            anchors.fill: parent
            visible: root.isVertical

            Column {
                anchors.top: parent.top
                anchors.topMargin: 10
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4

                Rectangle {
                    width: 7
                    height: 7
                    radius: 2
                    color: root.primaryColor
                }

                Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Qt.alpha(root.textColor, 0.7)
                }

                Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Qt.alpha(root.textColor, 0.45)
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 7
                height: 24
                radius: 3.5
                color: Qt.alpha(root.secondaryColor, 0.75)
            }

            Column {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4

                Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Qt.alpha(root.textColor, 0.75)
                }

                Rectangle {
                    width: 7
                    height: 7
                    radius: 2
                    color: root.primaryColor
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: root.barMode === 2 && !root.isVertical

        Rectangle {
            id: hCapLeft
            visible: root.hasLeft
            width: 74
            height: 16
            radius: 8
            color: Qt.alpha(root.barBackground, 0.96)
            border.color: root.isHighlighted ? root.primaryColor : Qt.alpha(root.primaryColor, 0.7)
            border.width: 1.5

            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.top: (root.barPosition === "bottom") ? undefined : parent.top
            anchors.topMargin: (root.barPosition === "bottom") ? 0 : 7
            anchors.bottom: (root.barPosition === "bottom") ? parent.bottom : undefined
            anchors.bottomMargin: (root.barPosition === "bottom") ? 7 : 0

            Row {
                anchors.centerIn: parent
                spacing: 4

                Rectangle {
                    width: 8
                    height: 8
                    radius: 2.5
                    color: root.primaryColor
                }

                Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Qt.alpha(root.textColor, 0.75)
                }

                Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Qt.alpha(root.textColor, 0.45)
                }
            }
        }

        Rectangle {
            id: hCapCenter
            visible: root.hasCenter
            width: 62
            height: 16
            radius: 8
            color: Qt.alpha(root.barBackground, 0.96)
            border.color: root.isHighlighted ? root.secondaryColor : Qt.alpha(root.secondaryColor, 0.65)
            border.width: 1.5

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: (root.barPosition === "bottom") ? undefined : parent.top
            anchors.topMargin: (root.barPosition === "bottom") ? 0 : 7
            anchors.bottom: (root.barPosition === "bottom") ? parent.bottom : undefined
            anchors.bottomMargin: (root.barPosition === "bottom") ? 7 : 0

            Row {
                anchors.centerIn: parent
                spacing: 3

                Rectangle {
                    width: 24
                    height: 6
                    radius: 3
                    color: Qt.alpha(root.secondaryColor, 0.85)
                }
            }
        }

        Rectangle {
            id: hCapRight
            visible: root.hasRight
            width: 92
            height: 16
            radius: 8
            color: Qt.alpha(root.barBackground, 0.96)
            border.color: root.isHighlighted ? root.primaryColor : Qt.alpha(root.primaryColor, 0.65)
            border.width: 1.5

            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.top: (root.barPosition === "bottom") ? undefined : parent.top
            anchors.topMargin: (root.barPosition === "bottom") ? 0 : 7
            anchors.bottom: (root.barPosition === "bottom") ? parent.bottom : undefined
            anchors.bottomMargin: (root.barPosition === "bottom") ? 7 : 0

            Row {
                anchors.centerIn: parent
                spacing: 4

                Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Qt.alpha(root.textColor, 0.75)
                }

                Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Qt.alpha(root.textColor, 0.75)
                }

                Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Qt.alpha(root.textColor, 0.75)
                }

                Rectangle {
                    width: 7
                    height: 7
                    radius: 2.5
                    color: root.primaryColor
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: root.barMode === 2 && root.isVertical

        Rectangle {
            id: vCapTop
            visible: root.hasLeft
            width: 16
            height: 68
            radius: 8
            color: Qt.alpha(root.barBackground, 0.96)
            border.color: root.isHighlighted ? root.primaryColor : Qt.alpha(root.primaryColor, 0.7)
            border.width: 1.5

            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.left: (root.barPosition === "right") ? undefined : parent.left
            anchors.leftMargin: (root.barPosition === "right") ? 0 : 7
            anchors.right: (root.barPosition === "right") ? parent.right : undefined
            anchors.rightMargin: (root.barPosition === "right") ? 7 : 0

            Column {
                anchors.centerIn: parent
                spacing: 4

                Rectangle {
                    width: 8
                    height: 8
                    radius: 2.5
                    color: root.primaryColor
                }

                Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Qt.alpha(root.textColor, 0.75)
                }

                Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Qt.alpha(root.textColor, 0.45)
                }
            }
        }

        Rectangle {
            id: vCapCenter
            visible: root.hasCenter
            width: 16
            height: 52
            radius: 8
            color: Qt.alpha(root.barBackground, 0.96)
            border.color: root.isHighlighted ? root.secondaryColor : Qt.alpha(root.secondaryColor, 0.65)
            border.width: 1.5

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: (root.barPosition === "right") ? undefined : parent.left
            anchors.leftMargin: (root.barPosition === "right") ? 0 : 7
            anchors.right: (root.barPosition === "right") ? parent.right : undefined
            anchors.rightMargin: (root.barPosition === "right") ? 7 : 0

            Column {
                anchors.centerIn: parent
                spacing: 3

                Rectangle {
                    width: 6
                    height: 24
                    radius: 3
                    color: Qt.alpha(root.secondaryColor, 0.85)
                }
            }
        }

        Rectangle {
            id: vCapBottom
            visible: root.hasRight
            width: 16
            height: 84
            radius: 8
            color: Qt.alpha(root.barBackground, 0.96)
            border.color: root.isHighlighted ? root.primaryColor : Qt.alpha(root.primaryColor, 0.65)
            border.width: 1.5

            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            anchors.left: (root.barPosition === "right") ? undefined : parent.left
            anchors.leftMargin: (root.barPosition === "right") ? 0 : 7
            anchors.right: (root.barPosition === "right") ? parent.right : undefined
            anchors.rightMargin: (root.barPosition === "right") ? 7 : 0

            Column {
                anchors.centerIn: parent
                spacing: 4

                Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Qt.alpha(root.textColor, 0.75)
                }

                Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Qt.alpha(root.textColor, 0.75)
                }

                Rectangle {
                    width: 7
                    height: 7
                    radius: 2.5
                    color: root.primaryColor
                }
            }
        }
    }
}
