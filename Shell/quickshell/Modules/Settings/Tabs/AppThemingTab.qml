import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Asura
import qs.Services
import "../Components"

ColumnLayout {
    id: tabRoot

    required property var settingsRoot
    readonly property var root: settingsRoot
    Layout.fillWidth: true
    spacing: 14
    visible: root.currentTab === "apptheming"

    SettingSectionHeader {
        icon: "format_paint"
        title: qsTr("App Color Theming")
        description: qsTr("Synchronize color schemes with external applications")

        SettingButton {
            icon: root.applyTemplatesProc.feedbackActive ? "check" : "refresh"
            text: root.applyTemplatesProc.feedbackActive ? qsTr("Applied!") : (root.applyTemplatesProc.running ? qsTr("Applying...") : qsTr("Reapply"))
            variant: "primary"
            onClicked: root.applyTemplatesNow()
        }
    }

    SettingCard {
        ColumnLayout {
            id: masterCol
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            SettingToggle {
                icon: Config.cfg.appThemingEnabled ? "palette" : "format_paint"
                title: qsTr("Global Theming Master")
                description: Config.cfg.appThemingEnabled
                    ? (root.activeTemplatesCount + " " + qsTr("of") + " " + root.totalTemplatesCount + " " + qsTr("apps synchronized"))
                    : qsTr("Theming disabled globally")
                checked: Config.cfg.appThemingEnabled
                onToggled: (newState) => {
                    Config.cfg.appThemingEnabled = newState;
                    Config.save();
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 6
                    radius: 3
                    color: Qt.alpha(root.surfaceContainer, 0.8)
                    clip: true

                    Rectangle {
                        height: parent.height
                        radius: 3
                        width: parent.width * (root.totalTemplatesCount > 0 ? (root.activeTemplatesCount / root.totalTemplatesCount) : 0)
                        color: root.color1

                        Behavior on width {
                            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                        }

                        Behavior on color {
                            ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 0.85; color: Qt.alpha(Colors.cfg.textBright, 0.08) }
                                GradientStop { position: 1.0; color: Qt.alpha(Colors.cfg.textBright, 0.22) }
                            }
                        }
                    }
                }

                SettingButton {
                    text: qsTr("Enable All")
                    variant: "ghost"
                    compact: true
                    onClicked: root.enableAllTemplates()
                }

                SettingButton {
                    text: qsTr("Disable All")
                    variant: "ghost"
                    compact: true
                    onClicked: root.disableAllTemplates()
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: 10
            color: root.surface
            border.color: tplSearchInput.activeFocus ? root.color1 : Qt.alpha(root.borderCol, 0.35)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: "search"
                    font.pixelSize: 16
                    font.family: "Material Symbols Rounded"
                    color: tplSearchInput.activeFocus ? root.color1 : root.textMuted
                }

                TextInput {
                    id: tplSearchInput
                    Layout.fillWidth: true
                    text: root.templateSearchQuery
                    onTextChanged: root.templateSearchQuery = text
                    color: root.textBright
                    font.family: "Google Sans"
                    font.pixelSize: 11
                    selectByMouse: true
                    verticalAlignment: TextInput.AlignVCenter

                    Text {
                        visible: !tplSearchInput.text && !tplSearchInput.activeFocus
                        text: qsTr("Search application (kitty, gtk, nvim)...")
                        color: root.textMuted
                        font.family: "Google Sans"
                        font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle {
                    visible: root.templateSearchQuery !== ""
                    implicitWidth: 18
                    implicitHeight: 18
                    radius: 9
                    color: Qt.alpha(root.textColor, 0.1)

                    Text {
                        anchors.centerIn: parent
                        text: "close"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 12
                        color: root.textBright
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            tplSearchInput.text = "";
                            root.templateSearchQuery = "";
                        }
                    }
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: [
                    { "id": "all", "label": qsTr("All"), "count": root.totalTemplatesCount },
                    { "id": "active", "label": qsTr("Active"), "count": root.activeTemplatesCount },
                    { "id": "disabled", "label": qsTr("Disabled"), "count": root.disabledTemplatesCount },
                    { "id": "terminal", "label": qsTr("Terminals"), "count": 5 },
                    { "id": "editor", "label": qsTr("Editors"), "count": 6 },
                    { "id": "desktop", "label": qsTr("Desktop / WM"), "count": 4 },
                    { "id": "apps", "label": qsTr("Apps"), "count": 4 }
                ]

                Rectangle {
                    id: catPill
                    required property var modelData
                    readonly property bool isSelected: root.templateCategoryFilter === modelData.id

                    implicitWidth: pillRow.implicitWidth + 14
                    implicitHeight: 26
                    radius: 8
                    color: isSelected ? root.color1 : (catPillH.hovered ? Qt.alpha(root.surface, 0.95) : root.surface)
                    border.color: isSelected ? root.color1 : Qt.alpha(root.borderCol, 0.3)
                    border.width: 1

                    HoverHandler { id: catPillH }

                    RowLayout {
                        id: pillRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: catPill.modelData.label
                            font.family: "Google Sans"
                            font.pixelSize: 10
                            font.bold: catPill.isSelected
                            color: catPill.isSelected ? root.foreground : root.textColor
                        }

                        Text {
                            text: "(" + catPill.modelData.count + ")"
                            font.family: "Google Sans"
                            font.pixelSize: 8
                            color: catPill.isSelected ? Qt.alpha(root.foreground, 0.75) : root.textMuted
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.templateCategoryFilter = catPill.modelData.id
                    }
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        Rectangle {
            visible: root.filteredTemplates.length === 0
            Layout.fillWidth: true
            implicitHeight: 110
            radius: 12
            color: root.surface
            border.color: Qt.alpha(root.borderCol, 0.3)
            border.width: 1

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "search"
                    font.pixelSize: 24
                    font.family: "Material Symbols Rounded"
                    color: root.textMuted
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("No templates found")
                    font.family: "Google Sans"
                    font.pixelSize: 11
                    font.bold: true
                    color: root.textColor
                }
            }
        }

        Repeater {
            model: root.filteredTemplates

            Rectangle {
                id: tplCard
                required property var modelData
                readonly property bool isTplDisabled: root.isTemplateDisabled(modelData.name)
                readonly property bool isTplActive: root.isTemplateActive(modelData.name)

                Layout.fillWidth: true
                implicitHeight: 52
                radius: 10
                color: tplCardMa.containsMouse
                    ? Qt.alpha(root.surface, 0.95)
                    : (isTplActive ? root.surface : Qt.alpha(root.surface, 0.6))
                border.color: tplCardMa.containsMouse
                    ? (isTplActive ? Qt.alpha(root.color1, 0.45) : Qt.alpha(root.borderCol, 0.4))
                    : (isTplActive ? Qt.alpha(root.borderCol, 0.3) : Qt.alpha(root.borderCol, 0.18))
                border.width: 1
                opacity: !Config.cfg.appThemingEnabled ? 0.6 : 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    Rectangle {
                        implicitWidth: 32
                        implicitHeight: 32
                        radius: 8
                        color: tplCard.isTplActive
                            ? Qt.alpha(root.color1, 0.15)
                            : Qt.alpha(root.textColor, 0.06)

                        Text {
                            anchors.centerIn: parent
                            text: tplCard.modelData.icon || "format_paint"
                            font.pixelSize: 18
                            font.family: "Material Symbols Rounded"
                            color: tplCard.isTplActive ? root.color1 : root.textMuted
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        RowLayout {
                            spacing: 6
                            Layout.fillWidth: true

                            Text {
                                text: tplCard.modelData.title || tplCard.modelData.name
                                font.family: "Google Sans"
                                font.pixelSize: 12
                                font.bold: true
                                color: tplCard.isTplActive ? root.textBright : root.textMuted
                            }

                            Rectangle {
                                implicitWidth: catTagText.implicitWidth + 8
                                implicitHeight: 16
                                radius: 4
                                color: Qt.alpha(root.color1, 0.08)

                                Text {
                                    id: catTagText
                                    anchors.centerIn: parent
                                    text: tplCard.modelData.category || "app"
                                    font.family: "Google Sans"
                                    font.pixelSize: 8
                                    color: root.color1
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }

                        Text {
                            text: tplCard.modelData.desc || tplCard.modelData.output || ""
                            font.family: "Google Sans"
                            font.pixelSize: 9
                            color: root.textMuted
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Rectangle {
                        implicitWidth: 44
                        implicitHeight: 24
                        radius: 12
                        color: !tplCard.isTplDisabled ? root.color1 : root.surfaceContainer
                        border.color: !tplCard.isTplDisabled ? root.color1 : root.borderCol
                        border.width: 1
                        opacity: Config.cfg.appThemingEnabled ? 1 : 0.45

                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            anchors.verticalCenter: parent.verticalCenter
                            x: !tplCard.isTplDisabled ? parent.width - width - 3 : 3
                            color: !tplCard.isTplDisabled ? root.foreground : root.textColor

                            Behavior on x {
                                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.toggleTemplate(tplCard.modelData.name);
                            }
                        }
                    }
                }

                MouseArea {
                    id: tplCardMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    z: -1
                    onClicked: {
                        root.toggleTemplate(tplCard.modelData.name);
                    }
                }
            }
        }
    }
}
