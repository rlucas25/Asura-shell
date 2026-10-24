import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Asura

RowLayout {
    id: pillsRoot

    property string icon: ""
    property string title: ""
    property string description: ""
    property string hint: ""
    property string hintIcon: "help"
    property var model: []
    property var currentValue
    property bool fillWidth: false
    property bool textOnlyWhenActive: false

    signal selected(var val)

    Layout.fillWidth: true
    spacing: 14

    Rectangle {
        visible: pillsRoot.icon !== ""
        implicitWidth: 36
        implicitHeight: 36
        radius: 10
        color: Qt.alpha(Colors.cfg.base03, 0.3)

        Text {
            anchors.centerIn: parent
            text: pillsRoot.icon
            font.pixelSize: 18
            font.family: "Material Symbols Rounded"
            color: Colors.cfg.primary
        }

    }

    ColumnLayout {
        visible: pillsRoot.title !== "" || pillsRoot.description !== ""
        Layout.fillWidth: true
        spacing: pillsRoot.description !== "" ? 3 : 0

        RowLayout {
            spacing: 6
            Layout.fillWidth: true

            Text {
                visible: pillsRoot.title !== ""
                text: pillsRoot.title
                font.pixelSize: 14
                font.bold: true
                font.family: "Google Sans"
                color: Colors.cfg.textBright
            }

            Rectangle {
                visible: pillsRoot.hint !== ""
                implicitWidth: 18
                implicitHeight: 18
                radius: 9
                color: hintMa.containsMouse ? Qt.alpha(Colors.cfg.primary, 0.22) : Qt.alpha(Colors.cfg.base03, 0.3)
                border.color: hintMa.containsMouse ? Qt.alpha(Colors.cfg.primary, 0.5) : "transparent"
                border.width: 1
                ToolTip.visible: hintMa.containsMouse
                ToolTip.text: pillsRoot.hint
                ToolTip.delay: 200

                Text {
                    anchors.centerIn: parent
                    text: pillsRoot.hintIcon
                    font.pixelSize: 12
                    font.family: "Material Symbols Rounded"
                    color: hintMa.containsMouse ? Colors.cfg.primary : Colors.cfg.textSecondary
                }

                MouseArea {
                    id: hintMa

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.WhatsThisCursor
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }

                }

            }

            Item {
                Layout.fillWidth: true
            }

        }

        Text {
            visible: pillsRoot.description !== ""
            text: pillsRoot.description
            font.pixelSize: 12
            font.family: "Google Sans"
            color: Colors.cfg.textSecondary
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

    }

    RowLayout {
        id: pillsRowLayout

        spacing: 6
        Layout.alignment: (pillsRoot.title !== "" || pillsRoot.description !== "") ? (Qt.AlignRight | Qt.AlignVCenter) : Qt.AlignVCenter

        Repeater {
            model: pillsRoot.model

            Rectangle {
                id: pillRect

                required property var modelData
                readonly property var pillVal: (typeof modelData === "object" && modelData !== null) ? (modelData.val !== undefined ? modelData.val : (modelData.id !== undefined ? modelData.id : modelData)) : modelData
                readonly property string pillLabel: (typeof modelData === "object" && modelData !== null) ? (modelData.label !== undefined ? modelData.label : (modelData.title !== undefined ? modelData.title : String(modelData))) : String(modelData)
                readonly property string pillIcon: (typeof modelData === "object" && modelData !== null && modelData.icon !== undefined) ? modelData.icon : ""
                readonly property bool isSelected: (pillsRoot.currentValue === pillVal) || (typeof pillsRoot.currentValue === "number" && typeof pillVal === "number" && Math.abs(pillsRoot.currentValue - pillVal) < 0.03) || (String(pillsRoot.currentValue) === String(pillVal))
                readonly property bool showLabel: !pillsRoot.textOnlyWhenActive || pillRect.pillIcon === "" || pillRect.isSelected || pillMa.containsMouse

                Layout.fillWidth: pillsRoot.fillWidth
                implicitWidth: pillsRoot.fillWidth ? 0 : (pillContentRow.implicitWidth + 22)
                implicitHeight: 30
                radius: 15
                clip: true
                color: isSelected ? Qt.alpha(Colors.cfg.primary, pillMa.containsMouse ? 0.32 : 0.22) : (pillMa.containsMouse ? Qt.alpha(Colors.cfg.base03, 0.5) : Colors.cfg.base02)
                border.color: isSelected ? Colors.cfg.primary : (pillMa.containsMouse ? Qt.alpha(Colors.cfg.base04, 0.45) : Qt.alpha(Colors.cfg.base03, 0.3))
                border.width: 1
                scale: pillMa.pressed ? 0.94 : (pillMa.containsMouse ? 1.04 : 1)
                ToolTip.visible: pillsRoot.textOnlyWhenActive && !pillRect.showLabel && pillMa.containsMouse
                ToolTip.text: pillRect.pillLabel
                ToolTip.delay: 250

                RowLayout {
                    id: pillContentRow

                    anchors.centerIn: parent
                    spacing: pillRect.pillIcon !== "" && pillRect.showLabel ? 5 : 0

                    Text {
                        visible: pillRect.pillIcon !== ""
                        text: pillRect.pillIcon
                        font.pixelSize: 15
                        font.family: "Material Symbols Rounded"
                        color: pillRect.isSelected ? Colors.cfg.primary : (pillMa.containsMouse ? Colors.cfg.base05 : Colors.cfg.base04)
                    }

                    Item {
                        implicitWidth: pillRect.showLabel ? pillText.implicitWidth : 0
                        implicitHeight: pillText.implicitHeight
                        clip: true

                        Text {
                            id: pillText

                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: pillRect.pillLabel
                            font.pixelSize: 12
                            font.bold: pillRect.isSelected
                            font.family: "Google Sans"
                            opacity: pillRect.showLabel ? 1 : 0
                            color: pillRect.isSelected ? Colors.cfg.primary : (pillMa.containsMouse ? Colors.cfg.base05 : Colors.cfg.base04)

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 140
                                }

                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 180
                                    easing.type: Easing.OutCubic
                                }

                            }

                        }

                        Behavior on implicitWidth {
                            NumberAnimation {
                                duration: 180
                                easing.type: Easing.OutCubic
                            }

                        }

                    }

                }

                MouseArea {
                    id: pillMa

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pillsRoot.selected(pillRect.pillVal)
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
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

                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }

                }

            }

        }

    }

}
