import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Asura

Item {
    id: headerRoot

    property string icon: ""
    property string title: ""
    property string description: ""
    property bool collapsible: false
    property bool collapsed: false
    property Item targetContent: null
    property string hint: ""
    property string hintIcon: "help"
    default property alias extraContent: extraRow.data

    property real flashScan: 0
    property real flashPop: 0
    property real flashTint: 0

    signal toggled(bool isCollapsed)

    Layout.fillWidth: true
    implicitHeight: headerRow.implicitHeight

    onTargetContentChanged: {
        if (headerRoot.targetContent) {
            headerRoot.targetContent.visible = !headerRoot.collapsed;
        }
    }

    onCollapsedChanged: {
        if (headerRoot.targetContent) {
            headerRoot.targetContent.visible = !headerRoot.collapsed;
        }
        headerRoot.toggled(headerRoot.collapsed);
    }

    function flash() {
        titleFlash.restart();
    }

    ParallelAnimation {
        id: titleFlash

        SequentialAnimation {
            NumberAnimation { target: headerRoot; property: "flashTint"; to: 1.0; duration: 150 }
            PauseAnimation { duration: 1600 }
            NumberAnimation { target: headerRoot; property: "flashTint"; to: 0.0; duration: 450 }
        }

        SequentialAnimation {
            PropertyAction { target: headerRoot; property: "flashScan"; value: 0.0 }
            SequentialAnimation {
                loops: 2
                NumberAnimation { target: headerRoot; property: "flashScan"; to: 1.0; duration: 450; easing.type: Easing.InOutSine }
                NumberAnimation { target: headerRoot; property: "flashScan"; to: 0.0; duration: 450; easing.type: Easing.InOutSine }
            }
        }

        SequentialAnimation {
            loops: 2
            NumberAnimation { target: headerRoot; property: "flashPop"; to: 1.0; duration: 180; easing.type: Easing.OutBack }
            NumberAnimation { target: headerRoot; property: "flashPop"; to: 0.0; duration: 320; easing.type: Easing.OutCubic }
        }
    }

    RowLayout {
        id: headerRow
        anchors.fill: parent
        spacing: 14

        Rectangle {
            visible: headerRoot.icon !== ""
            implicitWidth: 40
            implicitHeight: 40
            radius: 12
            color: Qt.alpha(Colors.cfg.primary, 0.15)
            border.color: Qt.alpha(Colors.cfg.primary, 0.3)
            border.width: 1
            scale: 1.0 + (0.12 * headerRoot.flashPop)

            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            Text {
                anchors.centerIn: parent
                text: headerRoot.icon
                font.pixelSize: 22
                font.family: "Material Symbols Rounded"
                color: Colors.cfg.primary
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: headerRoot.description !== "" ? 3 : 0

            RowLayout {
                spacing: 8
                Layout.fillWidth: true

                Item {
                    implicitWidth: titleText.implicitWidth
                    implicitHeight: titleText.implicitHeight

                    Text {
                        id: titleText
                        text: headerRoot.title
                        font.pixelSize: 18
                        font.bold: true
                        font.family: "Google Sans"
                        color: Qt.tint(Colors.cfg.textBright, Qt.rgba(Colors.cfg.primary.r, Colors.cfg.primary.g, Colors.cfg.primary.b, headerRoot.flashTint * 0.85))

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Item {
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -2
                        width: parent.width
                        height: 2
                        clip: true
                        opacity: headerRoot.flashTint

                        Rectangle {
                            width: Math.max(24, parent.width * 0.35)
                            height: parent.height
                            radius: 1
                            x: headerRoot.flashScan * (parent.width - width)
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 0.5; color: Colors.cfg.primary }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }
                    }
                }

                Rectangle {
                    visible: headerRoot.hint !== ""
                    implicitWidth: 22
                    implicitHeight: 22
                    radius: 11
                    color: hintMa.containsMouse ? Qt.alpha(Colors.cfg.primary, 0.22) : Qt.alpha(Colors.cfg.base03, 0.3)
                    border.color: hintMa.containsMouse ? Qt.alpha(Colors.cfg.primary, 0.5) : "transparent"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: headerRoot.hintIcon
                        font.pixelSize: 14
                        font.family: "Material Symbols Rounded"
                        color: hintMa.containsMouse ? Colors.cfg.primary : Colors.cfg.textSecondary
                    }

                    MouseArea {
                        id: hintMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.WhatsThisCursor
                    }

                    ToolTip.visible: hintMa.containsMouse
                    ToolTip.text: headerRoot.hint
                    ToolTip.delay: 200
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            Text {
                visible: headerRoot.description !== ""
                text: headerRoot.description
                font.pixelSize: 13
                font.family: "Google Sans"
                color: Colors.cfg.textSecondary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        RowLayout {
            id: extraRow
            spacing: 8
        }

        Rectangle {
            visible: headerRoot.collapsible
            implicitWidth: 32
            implicitHeight: 32
            radius: 16
            color: headerClickArea.containsMouse ? Qt.alpha(Colors.cfg.primary, 0.16) : Qt.alpha(Colors.cfg.base03, 0.25)
            border.color: headerClickArea.containsMouse ? Qt.alpha(Colors.cfg.primary, 0.4) : Qt.alpha(Colors.cfg.base03, 0.4)
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "expand_more"
                font.pixelSize: 20
                font.family: "Material Symbols Rounded"
                color: headerClickArea.containsMouse ? Colors.cfg.primary : Colors.cfg.textSecondary
                rotation: headerRoot.collapsed ? -90 : 0

                Behavior on rotation {
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }
    }

    MouseArea {
        id: headerClickArea
        anchors.fill: parent
        z: -1
        enabled: headerRoot.collapsible
        hoverEnabled: headerRoot.collapsible
        cursorShape: headerRoot.collapsible ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            headerRoot.collapsed = !headerRoot.collapsed;
        }
    }
}

