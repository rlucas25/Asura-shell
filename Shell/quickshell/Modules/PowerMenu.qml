import Quickshell.Wayland
import QtQuick
import Quickshell
import Quickshell.Io

PanelWindow {
    id: panelWindow

    property bool isOpen: false
    visible: isOpen

    IpcHandler {
        target: "powermenu"
        function toggle() {
            isOpen = !isOpen;
        }
    }

    color: Qt.alpha("black", 0.25)

    mask: Region {
        item: clickContainer
    }

    WlrLayershell.layer: WlrLayer.Overlay
    anchors {
        top: true
        bottom: true
        right: true
        left: true
    }

    Item {
        id: clickContainer
        anchors.centerIn: parent

        width: 700
        height: 170

        Row {
            spacing: 50
            anchors.centerIn: parent

            Rectangle {
                id: btn1
                anchors.verticalCenter: parent.verticalCenter
                HoverHandler {
                    id: hover1
                }

                property int size: {
                    if (hover1.hovered) {
                        return 170;
                    }
                    if (hover2.hovered || hover3.hovered || hover4.hovered) {
                        return 130;
                    } else {
                        return 150;
                    }
                }
                Behavior on size {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.OutCubic
                    }
                }

                height: size
                width: size

                color: "gray"
                radius: 30

                

                Text {
                    text: "1"
                    color: "white"
                    anchors.margins: 10
                    anchors.top: parent.top
                    anchors.left: parent.left
                }

                Text {
                    anchors.centerIn: parent
                    font {
                        family: "GeistMono Nerd Font Propo Propo"
                        pixelSize: {
                            if (hover1.hovered) {
                                return 70;
                            }
                            if (hover2.hovered || hover3.hovered || hover4.hovered) {
                                return 25;
                            } else {
                                return 40;
                            }
                        }
                        Behavior on pixelSize {
                            NumberAnimation {
                                duration: 500
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                    text: "⏻"
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                HoverHandler {
                    id: hover2
                }
                
                property int size: {
                    if (hover2.hovered) {
                        return 170;
                    }
                    if (hover1.hovered || hover3.hovered || hover4.hovered) {
                        return 130;
                    } else {
                        return 150;
                    }
                }
                Behavior on size {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.OutCubic
                    }
                }
                height: size
                width: size
                color: "gray"
                radius: 30

                Text {
                    text: "2"
                    color: "white"
                    anchors.margins: 10
                    anchors.top: parent.top
                    anchors.left: parent.left
                }
                Text {
                    anchors.centerIn: parent

                    font {
                        family: "GeistMono Nerd Font Propo Propo"
                        pixelSize: {
                            if (hover2.hovered) {
                                return 70;
                            }
                            if (hover1.hovered || hover3.hovered || hover4.hovered) {
                                return 25;
                            } else {
                                return 40;
                            }
                        }
                        Behavior on pixelSize {
                            NumberAnimation {
                                duration: 500
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                    text: "↻"
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                HoverHandler {
                    id: hover3
                }

                property int size: {
                    if (hover3.hovered) {
                        return 170;
                    }
                    if (hover1.hovered || hover2.hovered || hover4.hovered) {
                        return 130;
                    } else {
                        return 150;
                    }
                }
                Behavior on size {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.OutCubic
                    }
                }
                height: size
                width: size
                color: "gray"
                radius: 30

                Text {
                    text: "3"
                    color: "white"
                    anchors.margins: 10
                    anchors.top: parent.top
                    anchors.left: parent.left
                }
                Text {
                    anchors.centerIn: parent

                    font {
                        family: "GeistMono Nerd Font Propo Propo"
                        pixelSize: {
                            if (hover3.hovered) {
                                return 70;
                            }
                            if (hover1.hovered || hover2.hovered || hover4.hovered) {
                                return 25;
                            } else {
                                return 40;
                            }
                        }
                        Behavior on pixelSize {
                            NumberAnimation {
                                duration: 500
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                    text: "󰤄"
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                HoverHandler {
                    id: hover4
                }
                property int size: {
                    if (hover4.hovered) {
                        return 170;
                    }
                    if (hover1.hovered || hover2.hovered || hover3.hovered) {
                        return 130;
                    } else {
                        return 150;
                    }
                }
                Behavior on size {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.OutCubic
                    }
                }
                height: size
                width: size
                color: "gray"
                radius: 30

                Text {
                    text: "4"
                    color: "white"
                    anchors.margins: 10
                    anchors.top: parent.top
                    anchors.left: parent.left
                }
                Text {
                    anchors.centerIn: parent

                    font {
                        family: "GeistMono Nerd Font Propo Propo"
                        pixelSize: {
                            if (hover4.hovered) {
                                return 70;
                            }
                            if (hover1.hovered || hover2.hovered || hover3.hovered) {
                                return 25;
                            } else {
                                return 40;
                            }
                        }
                        Behavior on pixelSize {
                            NumberAnimation {
                                duration: 500
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                    text: "󰍃"
                }
            }
        }
    }
}
