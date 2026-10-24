import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Asura
import qs.Services
import "../Components"

Item {
    id: pickerModalRoot

    required property var settingsRoot
    readonly property var root: settingsRoot
    property var defaultAppsTab: null
    readonly property var activeCat: defaultAppsTab ? defaultAppsTab.activePickerCategory : null

    anchors.fill: parent
    z: 99995
    visible: activeCat !== null
    opacity: visible ? 1 : 0
    focus: visible

    Behavior on opacity {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    Keys.onEscapePressed: (event) => {
        if (defaultAppsTab) {
            defaultAppsTab.closeAppPicker();
        }
        event.accepted = true;
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.65)

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: if (defaultAppsTab) defaultAppsTab.closeAppPicker()
        }
    }

    Rectangle {
        id: pickerModalCard
        anchors.centerIn: parent
        width: Math.min(520, (root ? root.width : 600) - 40)
        height: Math.min((root ? root.height : 700) - 60, pickerModalContentCol.implicitHeight + 36)
        radius: 16
        color: root.surface
        border.color: Qt.alpha(root.color1, 0.45)
        border.width: 1.5
        clip: true
        scale: pickerModalRoot.visible ? 1 : 0.95

        Behavior on scale {
            NumberAnimation { duration: 200; easing.type: Easing.OutBack }
        }

        MouseArea {
            anchors.fill: parent
        }

        SettingButton {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 14
            anchors.rightMargin: 14
            z: 20
            icon: "close"
            variant: "ghost"
            compact: true
            onClicked: if (defaultAppsTab) defaultAppsTab.closeAppPicker()
        }

        Flickable {
            anchors.fill: parent
            anchors.margins: 18
            contentHeight: pickerModalContentCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: pickerModalContentCol
                width: parent.width
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    Layout.rightMargin: 36 // Reserve space for the pinned corner close button
                    spacing: 12

                    Rectangle {
                        implicitWidth: 38
                        implicitHeight: 38
                        radius: 10
                        color: Qt.alpha(root.color1, 0.15)
                        border.color: Qt.alpha(root.color1, 0.3)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: activeCat ? (activeCat.icon || "apps") : "apps"
                            font.pixelSize: 22
                            font.family: "Material Symbols Rounded"
                            color: root.color1
                        }
                    }

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true

                        Text {
                            text: activeCat ? qsTr("Choose %1").arg(activeCat.title) : qsTr("Choose Application")
                            font.family: "Google Sans"
                            font.pixelSize: 15
                            font.bold: true
                            color: root.textBright
                        }

                        Text {
                            text: activeCat ? (activeCat.desc || qsTr("Select an installed application or type a custom command")) : ""
                            font.family: "Google Sans"
                            font.pixelSize: 11
                            color: root.textMuted
                        }
                    }
                }

                SettingDivider {
                    Layout.fillWidth: true
                }

                Text {
                    text: qsTr("Available Applications:")
                    font.family: "Google Sans"
                    font.pixelSize: 11
                    font.bold: true
                    color: root.textColor
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: (activeCat && activeCat.options) ? activeCat.options : []

                        delegate: Rectangle {
                            id: optionItemCard
                            required property var modelData

                            readonly property bool isCurrent: {
                                if (!activeCat) return false;
                                var cur = (DefaultAppsService.currentApps && DefaultAppsService.currentApps[activeCat.key] !== undefined)
                                    ? DefaultAppsService.currentApps[activeCat.key]
                                    : (activeCat.current || "");
                                var curLower = String(cur).trim().toLowerCase();
                                var optCmd = String(modelData.cmd || "").trim().toLowerCase();
                                if (curLower === optCmd) return true;
                                var curBase = curLower.split(" ")[0].split("/").pop();
                                var optBase = optCmd.split(" ")[0].split("/").pop();
                                return curBase === optBase;
                            }

                            Layout.fillWidth: true
                            implicitHeight: 46
                            radius: 10
                            color: isCurrent
                                ? Qt.alpha(root.color1, 0.16)
                                : (optHover.hovered ? Qt.alpha(root.color1, 0.08) : root.surfaceContainer)
                            border.color: isCurrent
                                ? root.color1
                                : (optHover.hovered ? Qt.alpha(root.color1, 0.35) : Qt.alpha(root.borderCol, 0.4))
                            border.width: isCurrent ? 1.5 : 1

                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Rectangle {
                                    implicitWidth: 30
                                    implicitHeight: 30
                                    radius: 7
                                    color: Qt.alpha(root.textColor, 0.06)

                                    Image {
                                        id: optIconImg
                                        anchors.centerIn: parent
                                        width: 22
                                        height: 22
                                        source: modelData.icon ? ("image://icon/" + modelData.icon) : ""
                                        smooth: true
                                        mipmap: true
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: !modelData.icon || optIconImg.status !== Image.Ready
                                        text: modelData.name ? modelData.name.charAt(0).toUpperCase() : "?"
                                        font.family: "Google Sans"
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: root.color1
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        text: modelData.name
                                        font.family: "Google Sans"
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: optionItemCard.isCurrent ? root.textBright : root.textColor
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: modelData.cmd
                                        font.family: "Google Sans"
                                        font.pixelSize: 9
                                        color: root.textMuted
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                Rectangle {
                                    visible: optionItemCard.isCurrent
                                    implicitHeight: 22
                                    implicitWidth: activeBadgeRow.implicitWidth + 12
                                    radius: 6
                                    color: Qt.alpha(root.color1, 0.2)
                                    border.color: root.color1
                                    border.width: 1

                                    RowLayout {
                                        id: activeBadgeRow
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            text: "check"
                                            font.pixelSize: 13
                                            font.family: "Material Symbols Rounded"
                                            color: root.color1
                                        }

                                        Text {
                                            text: qsTr("Active")
                                            font.family: "Google Sans"
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: root.color1
                                        }
                                    }
                                }

                                Text {
                                    visible: !optionItemCard.isCurrent
                                    text: "chevron_right"
                                    font.pixelSize: 16
                                    font.family: "Material Symbols Rounded"
                                    color: optHover.hovered ? root.color1 : root.textMuted
                                }
                            }

                            HoverHandler { id: optHover }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (activeCat && defaultAppsTab) {
                                        DefaultAppsService.setApp(activeCat.key, modelData.cmd);
                                        defaultAppsTab.statusMessage = qsTr("Default %1 set to %2").arg(activeCat.title).arg(modelData.name);
                                        defaultAppsTab.statusClearTimer.restart();
                                        defaultAppsTab.closeAppPicker();
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        visible: (!activeCat || !activeCat.options || activeCat.options.length === 0)

                        Text {
                            text: qsTr("No detected preset applications for this category.")
                            font.family: "Google Sans"
                            font.pixelSize: 11
                            color: root.textMuted
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Qt.alpha(root.borderCol, 0.35)
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: qsTr("Custom Command or Executable:")
                        font.family: "Google Sans"
                        font.pixelSize: 11
                        font.bold: true
                        color: root.textColor
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 34
                            radius: 8
                            color: root.surfaceContainer
                            border.color: customInput.activeFocus ? root.color1 : Qt.alpha(root.borderCol, 0.4)
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                Text {
                                    text: "terminal"
                                    font.pixelSize: 16
                                    font.family: "Material Symbols Rounded"
                                    color: customInput.activeFocus ? root.color1 : root.textMuted
                                }

                                TextInput {
                                    id: customInput
                                    Layout.fillWidth: true
                                    text: {
                                        if (!activeCat) return "";
                                        if (DefaultAppsService.currentApps && DefaultAppsService.currentApps[activeCat.key] !== undefined) {
                                            return DefaultAppsService.currentApps[activeCat.key];
                                        }
                                        return activeCat.current || "";
                                    }
                                    color: root.textBright
                                    font.family: "Google Sans"
                                    font.pixelSize: 11
                                    selectByMouse: true
                                    verticalAlignment: TextInput.AlignVCenter
                                    onAccepted: applyCustomBtnArea.clicked(null)

                                    Text {
                                        anchors.fill: parent
                                        text: qsTr("Type custom command (e.g. kitty -e yazi)...")
                                        color: root.textMuted
                                        font.family: "Google Sans"
                                        font.pixelSize: 11
                                        verticalAlignment: Text.AlignVCenter
                                        visible: !parent.text && !parent.activeFocus
                                    }
                                }
                            }
                        }

                        SettingButton {
                            text: qsTr("Apply")
                            variant: "primary"
                            compact: true
                            onClicked: {
                                var val = customInput.text.trim();
                                if (val && activeCat && defaultAppsTab) {
                                    DefaultAppsService.setApp(activeCat.key, val);
                                    defaultAppsTab.statusMessage = qsTr("Updated %1 to '%2'").arg(activeCat.title).arg(val);
                                    defaultAppsTab.statusClearTimer.restart();
                                    defaultAppsTab.closeAppPicker();
                                }
                            }
                        }

                        SettingButton {
                            icon: "play_arrow"
                            variant: "secondary"
                            compact: true
                            onClicked: {
                                var val = customInput.text.trim();
                                if (val && defaultAppsTab) {
                                    DefaultAppsService.testLaunch(val);
                                    defaultAppsTab.statusMessage = qsTr("Launched '%1'").arg(val);
                                    defaultAppsTab.statusClearTimer.restart();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
