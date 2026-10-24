import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Asura
import qs.Components
import qs.Services
import "../Components"

ColumnLayout {
    id: shortcutsTabCol

    required property var settingsRoot
    readonly property var root: settingsRoot
    Layout.fillWidth: true
    spacing: 16
    visible: root.currentTab === "shortcuts"

    property string activeSubSection: "all"
    property string searchQuery: ""

    readonly property real scaleFactor: (typeof Config !== "undefined" && Config.uiScale !== undefined) ? Config.uiScale : 1.0

    readonly property var filteredShortcuts: {
        var q = shortcutsTabCol.searchQuery.trim().toLowerCase();
        var sec = shortcutsTabCol.activeSubSection;
        var list = [];

        if (sec === "all" || sec === "custom") {
            for (var j = 0; j < ShortcutsService.customShortcuts.length; j++) {
                var c = ShortcutsService.customShortcuts[j];
                if (q !== "") {
                    var cMatch = (c.label && c.label.toLowerCase().indexOf(q) !== -1) ||
                                 (c.hint && c.hint.toLowerCase().indexOf(q) !== -1) ||
                                 (c.chord && c.chord.toLowerCase().indexOf(q) !== -1);
                    if (!cMatch) continue;
                }
                list.push(c);
            }
        }

        if (sec !== "custom") {
            for (var i = 0; i < ShortcutsService.shortcuts.length; i++) {
                var it = ShortcutsService.shortcuts[i];
                if (sec !== "all" && it.category !== sec) continue;
                if (q !== "") {
                    var match = (it.label && it.label.toLowerCase().indexOf(q) !== -1) ||
                                (it.hint && it.hint.toLowerCase().indexOf(q) !== -1) ||
                                (it.chord && it.chord.toLowerCase().indexOf(q) !== -1);
                    if (!match) continue;
                }
                list.push(it);
            }
        }

        return list;
    }

    SettingSectionHeader {
        icon: "keyboard"
        title: qsTr("Shortcuts & Keybinds")
        description: qsTr("Browse active hotkeys, modify shortcuts, and create custom keybindings")

        SettingButton {
            icon: "add"
            text: qsTr("Add Shortcut")
            variant: "primary"
            onClicked: {
                root.openKeyRecorder({
                    id: "new",
                    label: "New Shortcut",
                    chord: "SUPER + ALT + X",
                    action: "exec",
                    value: "",
                    isCustom: true
                });
            }
        }

        SettingButton {
            icon: "restart_alt"
            text: qsTr("Restore Defaults")
            variant: "danger"
            onClicked: ShortcutsService.resetAllDefaults()
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 42
        radius: 10
        color: Qt.alpha(Colors.cfg.surfaceContainer, 0.5)
        border.color: Qt.alpha(Colors.cfg.border, 0.3)
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 16

            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 6
                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: "keyboard"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 16
                    color: Colors.cfg.primary
                }
                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: qsTr("Total: %1").arg(ShortcutsService.totalCount)
                    font.family: "Google Sans"
                    font.pixelSize: 11
                    color: Colors.cfg.textBright
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 1
                implicitHeight: 16
                color: Qt.alpha(Colors.cfg.border, 0.4)
            }

            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 6
                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: "tune"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 16
                    color: Colors.cfg.secondary
                }
                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: qsTr("Custom: %1").arg(ShortcutsService.customShortcuts.length)
                    font.family: "Google Sans"
                    font.pixelSize: 11
                    color: Colors.cfg.textBright
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 1
                implicitHeight: 16
                color: Qt.alpha(Colors.cfg.border, 0.4)
            }

            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 6
                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: ShortcutsService.conflictCount > 0 ? "warning" : "check"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 16
                    color: ShortcutsService.conflictCount > 0 ? Colors.cfg.warning : Colors.cfg.success
                }
                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: ShortcutsService.conflictCount > 0 ? qsTr("Conflicts: %1").arg(ShortcutsService.conflictCount) : qsTr("No Conflicts")
                    font.family: "Google Sans"
                    font.pixelSize: 11
                    color: ShortcutsService.conflictCount > 0 ? Colors.cfg.warning : Colors.cfg.success
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 220
                implicitHeight: 28
                radius: 7
                color: Qt.alpha(Colors.cfg.surfaceContainerHigh, 0.6)
                border.color: searchInput.activeFocus ? Colors.cfg.primary : Qt.alpha(Colors.cfg.border, 0.3)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: "search"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 16
                        color: Qt.alpha(Colors.cfg.textSecondary, 0.7)
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        font.family: "Google Sans"
                        font.pixelSize: 11
                        color: Colors.cfg.textBright
                        selectByMouse: true
                        clip: true

                        Text {
                            visible: !searchInput.text && !searchInput.activeFocus
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Filter hotkeys...")
                            font.family: "Google Sans"
                            font.pixelSize: 11
                            color: Qt.alpha(Colors.cfg.textSecondary, 0.5)
                        }

                        onTextChanged: shortcutsTabCol.searchQuery = text
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 38
        radius: 10
        color: Qt.alpha(Colors.cfg.surfaceContainer, 0.4)
        border.color: Qt.alpha(Colors.cfg.border, 0.25)
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 6

            Repeater {
                model: [
                    { id: "all", name: qsTr("All"), icon: "select_all" },
                    { id: "custom", name: qsTr("Custom"), icon: "tune" },
                    { id: "windows", name: qsTr("Windows"), icon: "space_dashboard" },
                    { id: "workspaces", name: qsTr("Workspaces"), icon: "view_timeline" },
                    { id: "menus", name: qsTr("Menus & Shell"), icon: "menu" },
                    { id: "apps", name: qsTr("Apps"), icon: "apps" }
                ]

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 7
                    color: shortcutsTabCol.activeSubSection === modelData.id ? Qt.alpha(Colors.cfg.primary, 0.18) : "transparent"
                    border.color: shortcutsTabCol.activeSubSection === modelData.id ? Qt.alpha(Colors.cfg.primary, 0.4) : "transparent"
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            text: modelData.icon
                            font.pixelSize: 16
                            font.family: "Material Symbols Rounded"
                            color: shortcutsTabCol.activeSubSection === modelData.id ? Colors.cfg.primary : Qt.alpha(Colors.cfg.textSecondary, 0.7)
                        }

                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            text: modelData.name
                            font.family: "Google Sans"
                            font.pixelSize: 11
                            font.bold: shortcutsTabCol.activeSubSection === modelData.id
                            color: shortcutsTabCol.activeSubSection === modelData.id ? Colors.cfg.primary : Colors.cfg.textBright
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: shortcutsTabCol.activeSubSection = modelData.id
                    }
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        Repeater {
            model: shortcutsTabCol.filteredShortcuts

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 56
                radius: 12
                color: cardHover.hovered ? Qt.alpha(Colors.cfg.surfaceContainerHigh, 0.45) : Qt.alpha(Colors.cfg.surface, 0.8)
                border.color: modelData.isOverridden ? Qt.alpha(Colors.cfg.primary, 0.35) : Qt.alpha(Colors.cfg.border, 0.25)
                border.width: 1

                HoverHandler { id: cardHover }

                RowLayout {
                    id: cardRow
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 12

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 32
                        implicitHeight: 32
                        radius: 8
                        color: modelData.isCustom ? Qt.alpha(Colors.cfg.secondary, 0.15) : Qt.alpha(Colors.cfg.primary, 0.1)

                        Text {
                            anchors.centerIn: parent
                            text: {
                                if (modelData.isCustom) return "tune";
                                if (modelData.category === "windows") return "space_dashboard";
                                if (modelData.category === "workspaces") return "view_timeline";
                                if (modelData.category === "menus") return "menu";
                                if (modelData.category === "apps") return "apps";
                                if (modelData.category === "media") return "volume_up";
                                return "keyboard";
                            }
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 18
                            color: modelData.isCustom ? Colors.cfg.secondary : Colors.cfg.primary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        RowLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 8

                            Text {
                                Layout.alignment: Qt.AlignVCenter
                                text: modelData.label
                                font.family: "Google Sans"
                                font.pixelSize: 12
                                font.bold: true
                                color: Colors.cfg.textBright
                            }

                            Rectangle {
                                visible: !!modelData.isOverridden
                                Layout.alignment: Qt.AlignVCenter
                                implicitWidth: modText.implicitWidth + 8
                                implicitHeight: 16
                                radius: 4
                                color: Qt.alpha(Colors.cfg.primary, 0.15)

                                Text {
                                    id: modText
                                    anchors.centerIn: parent
                                    text: qsTr("Modified")
                                    font.family: "Google Sans"
                                    font.pixelSize: 9
                                    color: Colors.cfg.primary
                                }
                            }

                            Rectangle {
                                visible: !!modelData.isCustom
                                Layout.alignment: Qt.AlignVCenter
                                implicitWidth: customBadgeText.implicitWidth + 8
                                implicitHeight: 16
                                radius: 4
                                color: Qt.alpha(Colors.cfg.secondary, 0.15)

                                Text {
                                    id: customBadgeText
                                    anchors.centerIn: parent
                                    text: qsTr("Custom")
                                    font.family: "Google Sans"
                                    font.pixelSize: 9
                                    color: Colors.cfg.secondary
                                }
                            }

                            Rectangle {
                                visible: !!(modelData.normalized && ShortcutsService.conflicts.indexOf(modelData.normalized) !== -1)
                                Layout.alignment: Qt.AlignVCenter
                                implicitWidth: conflictBadgeText.implicitWidth + 8
                                implicitHeight: 16
                                radius: 4
                                color: Qt.alpha(Colors.cfg.warning, 0.15)

                                Text {
                                    id: conflictBadgeText
                                    anchors.centerIn: parent
                                    text: qsTr("Conflict")
                                    font.family: "Google Sans"
                                    font.pixelSize: 9
                                    color: Colors.cfg.warning
                                }
                            }
                        }

                        Text {
                            visible: !!(modelData.hint && modelData.hint.trim() !== "")
                            Layout.fillWidth: true
                            text: modelData.hint || ""
                            font.family: "Google Sans"
                            font.pixelSize: 10
                            color: Qt.alpha(Colors.cfg.textSecondary, 0.75)
                            elide: Text.ElideRight
                        }
                    }

                    Item {
                        implicitWidth: Math.round(220 * shortcutsTabCol.scaleFactor)
                        Layout.preferredWidth: implicitWidth
                        Layout.minimumWidth: implicitWidth
                        Layout.maximumWidth: implicitWidth
                        Layout.fillWidth: false
                        Layout.alignment: Qt.AlignVCenter
                        implicitHeight: Math.round(26 * shortcutsTabCol.scaleFactor)

                        KeyComboView {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            chord: modelData.chord
                        }
                    }

                    RowLayout {
                        implicitWidth: Math.round(62 * shortcutsTabCol.scaleFactor)
                        Layout.preferredWidth: implicitWidth
                        Layout.minimumWidth: implicitWidth
                        Layout.maximumWidth: implicitWidth
                        Layout.fillWidth: false
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        spacing: 6

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: 28
                            implicitHeight: 28
                            radius: 6
                            color: editHover.hovered ? Qt.alpha(Colors.cfg.primary, 0.25) : Qt.alpha(Colors.cfg.surfaceContainerHigh, 0.6)
                            border.color: Qt.alpha(Colors.cfg.border, 0.3)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "edit"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 16
                                color: editHover.hovered ? Colors.cfg.primary : Colors.cfg.textBright
                            }

                            HoverHandler { id: editHover }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.openKeyRecorder(modelData)
                            }
                        }

                        Rectangle {
                            visible: !!modelData.isCustom
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: 28
                            implicitHeight: 28
                            radius: 6
                            color: delHover.hovered ? Qt.alpha(Colors.cfg.error, 0.25) : Qt.alpha(Colors.cfg.surfaceContainerHigh, 0.6)
                            border.color: Qt.alpha(Colors.cfg.border, 0.3)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "delete"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 16
                                color: delHover.hovered ? Colors.cfg.error : Colors.cfg.textSecondary
                            }

                            HoverHandler { id: delHover }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ShortcutsService.deleteCustomShortcut(modelData.id)
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            visible: shortcutsTabCol.filteredShortcuts.length === 0
            Layout.fillWidth: true
            implicitHeight: 120
            radius: 12
            color: Qt.alpha(Colors.cfg.surface, 0.5)

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "keyboard"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 32
                    color: Qt.alpha(Colors.cfg.textSecondary, 0.4)
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("No matching shortcuts found")
                    font.family: "Google Sans"
                    font.pixelSize: 12
                    color: Qt.alpha(Colors.cfg.textSecondary, 0.7)
                }
            }
        }
    }
}
