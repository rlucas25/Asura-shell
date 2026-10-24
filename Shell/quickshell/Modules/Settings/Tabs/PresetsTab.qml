
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
    id: presetsTabCol

    required property var settingsRoot
    readonly property var root: settingsRoot
    property bool showSaveCard: false
    property string searchQuery: ""
    property string newPresetName: ""
    property string statusMessage: ""
    property string confirmingActionId: ""
    property string confirmingActionType: "" // "delete" | "overwrite"
    readonly property var defaultTabsList: ["theme", "general", "windows", "bar", "launcher", "apptheming"]
    property var selectedTabsToSave: ["theme", "general", "windows", "bar", "launcher", "apptheming"]
    readonly property var filteredPresets: {
        var list = PresetService.presets || [];
        var q = presetsTabCol.searchQuery.trim().toLowerCase();
        if (!q)
            return list;

        return list.filter(function(item) {
            if (!item)
                return false;

            var nameMatch = item.name && item.name.toLowerCase().indexOf(q) !== -1;
            var themeMatch = item.theme && item.theme.toLowerCase().indexOf(q) !== -1;
            return nameMatch || themeMatch;
        });
    }

    function formatDate(isoStr) {
        if (!isoStr)
            return "";

        try {
            var d = new Date(isoStr);
            if (isNaN(d.getTime()))
                return isoStr.substring(0, 10);

            var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
            var month = months[d.getMonth()] || "Jan";
            var day = d.getDate();
            var year = d.getFullYear();
            var hours = d.getHours();
            var minutes = d.getMinutes();
            var hStr = (hours < 10 ? "0" : "") + hours;
            var mStr = (minutes < 10 ? "0" : "") + minutes;
            return month + " " + day + ", " + year + " " + hStr + ":" + mStr;
        } catch (e) {
            return (isoStr || "").substring(0, 10);
        }
    }

    Layout.fillWidth: true
    spacing: 16
    visible: root.currentTab === "presets"
    onVisibleChanged: {
        if (visible)
            PresetService.loadPresets();

    }

    Timer {
        id: statusClearTimer

        interval: 4000
        repeat: false
        onTriggered: presetsTabCol.statusMessage = ""
    }

    Connections {
        function onPresetSaved(id, name) {
            presetsTabCol.statusMessage = qsTr("Preset '%1' saved successfully!").arg(name);
            statusClearTimer.restart();
            presetsTabCol.showSaveCard = false;
            presetsTabCol.newPresetName = "";
            PresetService.loadPresets();
        }

        function onPresetApplied(id, name) {
            presetsTabCol.statusMessage = qsTr("Applied preset '%1'").arg(name);
            statusClearTimer.restart();
            PresetService.loadPresets();
        }

        function onPresetDeleted(id) {
            presetsTabCol.statusMessage = qsTr("Preset deleted successfully");
            statusClearTimer.restart();
            presetsTabCol.confirmingActionId = "";
            presetsTabCol.confirmingActionType = "";
            PresetService.loadPresets();
        }

        target: PresetService
    }

    SettingSectionHeader {
        title: qsTr("Appearance Presets & Rices")
        description: qsTr("Snapshot and restore your shell style and system settings: Theme, Bar, Windows, Launcher, Monitors, and Input")
        icon: "style"
        extraContent: Rectangle {
            implicitHeight: 26
            implicitWidth: countText.implicitWidth + 18
            radius: 13
            color: Qt.alpha(Colors.cfg.primary, 0.12)
            border.color: Qt.alpha(Colors.cfg.primary, 0.3)
            border.width: 1

            Text {
                id: countText

                anchors.centerIn: parent
                text: (PresetService.presets ? PresetService.presets.length : 0) + " " + qsTr("presets")
                font.family: "Google Sans"
                font.pixelSize: 10
                font.bold: true
                color: Colors.cfg.primary
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 36
        radius: 10
        visible: presetsTabCol.statusMessage !== ""
        color: Qt.alpha(root.color1, 0.18)
        border.color: Qt.alpha(root.color1, 0.4)
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            Text {
                text: "check_circle"
                font.pixelSize: 16
                font.family: "Material Symbols Rounded"
                color: root.color1
            }

            Text {
                Layout.fillWidth: true
                text: presetsTabCol.statusMessage
                font.family: "Google Sans"
                font.pixelSize: 11
                font.bold: true
                color: root.textBright
                elide: Text.ElideRight
            }

            Text {
                text: "close"
                font.pixelSize: 14
                font.family: "Material Symbols Rounded"
                color: root.textMuted

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: presetsTabCol.statusMessage = ""
                }

            }

        }

    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 38
            radius: 10
            color: root.surfaceContainer
            border.color: searchInput.activeFocus ? root.color1 : Qt.alpha(root.borderCol, 0.4)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Text {
                    text: "search"
                    font.pixelSize: 16
                    font.family: "Material Symbols Rounded"
                    color: searchInput.activeFocus ? root.color1 : root.textMuted
                }

                TextInput {
                    id: searchInput

                    Layout.fillWidth: true
                    text: presetsTabCol.searchQuery
                    onTextChanged: presetsTabCol.searchQuery = text
                    color: root.textBright
                    font.family: "Google Sans"
                    font.pixelSize: 12
                    selectByMouse: true
                    verticalAlignment: TextInput.AlignVCenter

                    Text {
                        anchors.fill: parent
                        text: qsTr("Filter presets by name or theme...")
                        color: root.textMuted
                        font.family: "Google Sans"
                        font.pixelSize: 12
                        verticalAlignment: Text.AlignVCenter
                        visible: !parent.text && !parent.activeFocus
                    }

                }

                Text {
                    visible: presetsTabCol.searchQuery !== ""
                    text: "close"
                    font.pixelSize: 14
                    font.family: "Material Symbols Rounded"
                    color: root.textMuted

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: presetsTabCol.searchQuery = ""
                    }

                }

            }

        }

        SettingButton {
            text: presetsTabCol.showSaveCard ? qsTr("Cancel") : qsTr("Save Current Look")
            icon: presetsTabCol.showSaveCard ? "close" : "add"
            variant: presetsTabCol.showSaveCard ? "secondary" : "primary"
            onClicked: {
                presetsTabCol.showSaveCard = !presetsTabCol.showSaveCard;
                if (presetsTabCol.showSaveCard) {
                    presetsTabCol.selectedTabsToSave = presetsTabCol.defaultTabsList.slice();
                    newPresetNameInput.forceActiveFocus();
                }
            }
        }

    }

    Rectangle {
        id: saveCard

        visible: presetsTabCol.showSaveCard
        Layout.fillWidth: true
        radius: 14
        color: root.surfaceContainer
        border.color: Qt.alpha(root.color1, 0.5)
        border.width: 1.5
        implicitHeight: saveCardCol.implicitHeight + 28
        clip: true

        ColumnLayout {
            id: saveCardCol

            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "bookmark_add"
                    font.pixelSize: 18
                    font.family: "Material Symbols Rounded"
                    color: root.color1
                }

                Text {
                    text: qsTr("Save New Preset")
                    font.family: "Google Sans"
                    font.pixelSize: 13
                    font.bold: true
                    color: root.textBright
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: qsTr("Wallpaper will be archived into preset bundle")
                    font.family: "Google Sans"
                    font.pixelSize: 10
                    color: root.textMuted
                }

            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 74
                radius: 10
                color: root.surface
                border.color: Qt.alpha(root.borderCol, 0.4)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 12

                    Rectangle {
                        implicitWidth: 100
                        implicitHeight: 58
                        radius: 8
                        color: root.surfaceContainer
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: Config.cfg.wallpaper ? ("file://" + Config.cfg.wallpaper) : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }

                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        RowLayout {
                            spacing: 8

                            Text {
                                text: (Config.cfg.theme || "Current Theme").toUpperCase()
                                font.family: "Google Sans"
                                font.pixelSize: 11
                                font.bold: true
                                color: root.textBright
                            }

                            Rectangle {
                                implicitHeight: 18
                                implicitWidth: modeText.implicitWidth + 10
                                radius: 4
                                color: Qt.alpha(root.textColor, 0.08)

                                Text {
                                    id: modeText

                                    anchors.centerIn: parent
                                    text: Config.cfg.isDarkMode ? qsTr("Dark") : qsTr("Light")
                                    font.family: "Google Sans"
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: root.color1
                                }

                            }

                            Rectangle {
                                implicitHeight: 18
                                implicitWidth: accentBadgeRow.implicitWidth + 10
                                radius: 4
                                color: Qt.alpha(Colors.cfg.primary, 0.16)
                                border.color: Qt.alpha(Colors.cfg.primary, 0.4)
                                border.width: 1

                                RowLayout {
                                    id: accentBadgeRow

                                    anchors.centerIn: parent
                                    spacing: 4

                                    Rectangle {
                                        implicitWidth: 7
                                        implicitHeight: 7
                                        radius: 3.5
                                        color: Colors.cfg.primary
                                    }

                                    Text {
                                        text: (Colors.primarySlot || "base0D").toUpperCase()
                                        font.family: "Google Sans"
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: root.textBright
                                    }

                                }

                            }

                        }

                        RowLayout {
                            spacing: 6

                            Rectangle {
                                implicitWidth: 14
                                implicitHeight: 14
                                radius: 7
                                color: Colors.cfg.primary
                                border.color: Qt.alpha("#ffffff", 0.2)
                                border.width: 1
                            }

                            Rectangle {
                                implicitWidth: 14
                                implicitHeight: 14
                                radius: 7
                                color: Colors.cfg.secondary
                                border.color: Qt.alpha("#ffffff", 0.2)
                                border.width: 1
                            }

                            Rectangle {
                                implicitWidth: 14
                                implicitHeight: 14
                                radius: 7
                                color: Colors.cfg.surface
                                border.color: Qt.alpha("#ffffff", 0.2)
                                border.width: 1
                            }

                            Rectangle {
                                implicitWidth: 14
                                implicitHeight: 14
                                radius: 7
                                color: Colors.cfg.base00
                                border.color: Qt.alpha("#ffffff", 0.2)
                                border.width: 1
                            }

                            Text {
                                text: qsTr("Palette generated")
                                font.family: "Google Sans"
                                font.pixelSize: 10
                                color: root.textMuted
                            }

                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: presetsTabCol.selectedTabsToSave

                                delegate: RowLayout {
                                    required property var modelData
                                    readonly property var tabInfo: {
                                        var key = String(modelData).toLowerCase();
                                        if (key === "theme")
                                            return {
                                            "icon": "palette",
                                            "name": "Theme"
                                        };

                                        if (key === "general")
                                            return {
                                            "icon": "tune",
                                            "name": "General"
                                        };

                                        if (key === "windows")
                                            return {
                                            "icon": "desktop_windows",
                                            "name": "Windows"
                                        };

                                        if (key === "bar")
                                            return {
                                            "icon": "dock",
                                            "name": "Bar"
                                        };

                                        if (key === "launcher")
                                            return {
                                            "icon": "rocket_launch",
                                            "name": "Launcher"
                                        };

                                        if (key === "apptheming")
                                            return {
                                            "icon": "format_paint",
                                            "name": "App Theming"
                                        };

                                        if (key === "notifications")
                                            return {
                                            "icon": "notifications",
                                            "name": "Notifications"
                                        };

                                        if (key === "defaultapps")
                                            return {
                                            "icon": "apps",
                                            "name": "Apps"
                                        };

                                        if (key === "monitors")
                                            return {
                                            "icon": "monitor",
                                            "name": "Monitors"
                                        };

                                        if (key === "keyboard")
                                            return {
                                            "icon": "keyboard",
                                            "name": "Mouse & Key"
                                        };

                                        if (key === "shortcuts")
                                            return {
                                            "icon": "shortcut",
                                            "name": "Shortcuts"
                                        };

                                        return {
                                            "icon": "style",
                                            "name": String(modelData)
                                        };
                                    }

                                    spacing: 3

                                    Text {
                                        text: tabInfo.icon
                                        font.pixelSize: 12
                                        font.family: "Material Symbols Rounded"
                                        color: root.color1
                                    }

                                    Text {
                                        text: tabInfo.name
                                        font.family: "Google Sans"
                                        font.pixelSize: 9
                                        color: root.textMuted
                                    }

                                }

                            }

                        }

                    }

                }

            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true

                    RowLayout {
                        spacing: 6

                        Text {
                            text: "check_box"
                            font.pixelSize: 15
                            font.family: "Material Symbols Rounded"
                            color: root.color1
                        }

                        Text {
                            text: qsTr("Select Tabs to Include in Preset:")
                            font.family: "Google Sans"
                            font.pixelSize: 11
                            font.bold: true
                            color: root.textBright
                        }

                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        spacing: 6

                        SettingButton {
                            text: qsTr("Defaults")
                            compact: true
                            variant: "secondary"
                            onClicked: {
                                presetsTabCol.selectedTabsToSave = presetsTabCol.defaultTabsList.slice();
                            }
                        }

                        SettingButton {
                            text: qsTr("Select All")
                            compact: true
                            variant: "secondary"
                            onClicked: {
                                presetsTabCol.selectedTabsToSave = ["theme", "general", "windows", "bar", "launcher", "apptheming", "notifications", "defaultapps", "monitors", "keyboard", "shortcuts"];
                            }
                        }

                    }

                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [{
                            "id": "theme",
                            "name": qsTr("Theme"),
                            "icon": "palette",
                            "isDefault": true
                        }, {
                            "id": "general",
                            "name": qsTr("General"),
                            "icon": "tune",
                            "isDefault": true
                        }, {
                            "id": "windows",
                            "name": qsTr("Windows"),
                            "icon": "desktop_windows",
                            "isDefault": true
                        }, {
                            "id": "bar",
                            "name": qsTr("Bar"),
                            "icon": "dock",
                            "isDefault": true
                        }, {
                            "id": "launcher",
                            "name": qsTr("Launcher"),
                            "icon": "rocket_launch",
                            "isDefault": true
                        }, {
                            "id": "apptheming",
                            "name": qsTr("App Theming"),
                            "icon": "format_paint",
                            "isDefault": true
                        }, {
                            "id": "notifications",
                            "name": qsTr("Notifications"),
                            "icon": "notifications",
                            "isDefault": false
                        }, {
                            "id": "defaultapps",
                            "name": qsTr("Apps"),
                            "icon": "apps",
                            "isDefault": false
                        }, {
                            "id": "monitors",
                            "name": qsTr("Monitors"),
                            "icon": "monitor",
                            "isDefault": false
                        }, {
                            "id": "keyboard",
                            "name": qsTr("Mouse & Keyboard"),
                            "icon": "keyboard",
                            "isDefault": false
                        }, {
                            "id": "shortcuts",
                            "name": qsTr("Shortcuts"),
                            "icon": "shortcut",
                            "isDefault": false
                        }]

                        delegate: Rectangle {
                            id: tabCheckItem

                            required property var modelData
                            readonly property bool isChecked: presetsTabCol.selectedTabsToSave.indexOf(modelData.id) !== -1

                            implicitHeight: 32
                            implicitWidth: checkRow.implicitWidth + 20
                            radius: 8
                            color: isChecked ? Qt.alpha(root.color1, 0.18) : (checkItemH.hovered ? root.surface : Qt.alpha(root.surface, 0.5))
                            border.color: isChecked ? root.color1 : Qt.alpha(root.borderCol, 0.4)
                            border.width: isChecked ? 1.5 : 1

                            RowLayout {
                                id: checkRow

                                anchors.centerIn: parent
                                spacing: 6

                                Rectangle {
                                    implicitWidth: 16
                                    implicitHeight: 16
                                    radius: 4
                                    color: tabCheckItem.isChecked ? root.color1 : "transparent"
                                    border.color: tabCheckItem.isChecked ? root.color1 : root.textMuted
                                    border.width: 1.5

                                    Text {
                                        anchors.centerIn: parent
                                        visible: tabCheckItem.isChecked
                                        text: "check"
                                        font.pixelSize: 12
                                        font.family: "Material Symbols Rounded"
                                        color: root.foreground
                                    }

                                }

                                Text {
                                    text: tabCheckItem.modelData.icon
                                    font.pixelSize: 14
                                    font.family: "Material Symbols Rounded"
                                    color: tabCheckItem.isChecked ? root.color1 : root.textMuted
                                }

                                Text {
                                    text: tabCheckItem.modelData.name
                                    font.family: "Google Sans"
                                    font.pixelSize: 11
                                    font.bold: tabCheckItem.isChecked
                                    color: tabCheckItem.isChecked ? root.textBright : root.textColor
                                }

                            }

                            HoverHandler {
                                id: checkItemH
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var current = presetsTabCol.selectedTabsToSave.slice();
                                    var idx = current.indexOf(tabCheckItem.modelData.id);
                                    if (idx !== -1)
                                        current.splice(idx, 1);
                                    else
                                        current.push(tabCheckItem.modelData.id);
                                    presetsTabCol.selectedTabsToSave = current;
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                }

                            }

                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 120
                                }

                            }

                        }

                    }

                }

            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: 10
                    color: root.surface
                    border.color: newPresetNameInput.activeFocus ? root.color1 : Qt.alpha(root.borderCol, 0.4)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Text {
                            text: "edit"
                            font.pixelSize: 16
                            font.family: "Material Symbols Rounded"
                            color: newPresetNameInput.activeFocus ? root.color1 : root.textMuted
                        }

                        TextInput {
                            id: newPresetNameInput

                            Layout.fillWidth: true
                            text: presetsTabCol.newPresetName
                            onTextChanged: presetsTabCol.newPresetName = text
                            color: root.textBright
                            font.family: "Google Sans"
                            font.pixelSize: 12
                            selectByMouse: true
                            verticalAlignment: TextInput.AlignVCenter
                            onAccepted: saveConfirmBtnMa.clicked(null)

                            Text {
                                anchors.fill: parent
                                text: qsTr("Enter a preset name (e.g. Cyberpunk Purple, Minimal Gray)...")
                                color: root.textMuted
                                font.family: "Google Sans"
                                font.pixelSize: 12
                                verticalAlignment: Text.AlignVCenter
                                visible: !parent.text && !parent.activeFocus
                            }

                        }

                    }

                }

                SettingButton {
                    text: qsTr("Save Preset")
                    icon: "save"
                    variant: "primary"
                    enabled: presetsTabCol.selectedTabsToSave.length > 0
                    opacity: presetsTabCol.selectedTabsToSave.length > 0 ? 1 : 0.6
                    onClicked: {
                        if (presetsTabCol.selectedTabsToSave.length === 0) {
                            presetsTabCol.statusMessage = qsTr("Please select at least one tab to include in preset");
                            statusClearTimer.restart();
                            return;
                        }
                        var nameToSave = presetsTabCol.newPresetName.trim();
                        if (!nameToSave)
                            nameToSave = (Config.cfg.theme || "Preset") + " Look";

                        PresetService.saveCurrentPreset(nameToSave, presetsTabCol.selectedTabsToSave);
                    }
                }

            }

        }

        Behavior on implicitHeight {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }

        }

    }

    Rectangle {
        visible: presetsTabCol.filteredPresets.length === 0
        Layout.fillWidth: true
        implicitHeight: 180
        radius: 14
        color: root.surfaceContainer
        border.color: Qt.alpha(root.borderCol, 0.4)
        border.width: 1

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 10

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "style"
                font.pixelSize: 48
                font.family: "Material Symbols Rounded"
                color: root.textMuted
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: (PresetService.presets && PresetService.presets.length > 0) ? qsTr("No presets found matching '%1'").arg(presetsTabCol.searchQuery) : qsTr("No appearance presets saved yet")
                font.family: "Google Sans"
                font.pixelSize: 14
                font.bold: true
                color: root.textBright
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: (PresetService.presets && PresetService.presets.length > 0) ? qsTr("Try clearing your search query") : qsTr("Click '+ Save Current Look' above to save your first preset snapshot")
                font.family: "Google Sans"
                font.pixelSize: 11
                color: root.textMuted
            }

        }

    }

    GridLayout {
        id: presetGrid

        visible: presetsTabCol.filteredPresets.length > 0
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 14
        rowSpacing: 14

        Repeater {
            model: presetsTabCol.filteredPresets

            delegate: Rectangle {
                id: presetCard

                required property var modelData
                required property int index
                readonly property bool isActiveRice: {
                    if (PresetService.activePresetId === modelData.id)
                        return true;

                    if (Config.cfg && Config.cfg.wallpaper && modelData.wallpaperCopyPath && Config.cfg.wallpaper.indexOf(modelData.id) !== -1)
                        return true;

                    return false;
                }
                readonly property bool hasExtraSettings: {
                    if (presetCard.modelData.hasExtraSettings !== undefined)
                        return Boolean(presetCard.modelData.hasExtraSettings);

                    var tabs = presetCard.modelData.tabs || presetCard.modelData.components || [];
                    if (!Array.isArray(tabs))
                        return false;

                    for (var i = 0; i < tabs.length; i++) {
                        if (presetsTabCol.defaultTabsList.indexOf(tabs[i]) === -1)
                            return true;

                    }
                    return false;
                }
                readonly property bool isConfirmingThis: presetsTabCol.confirmingActionId === modelData.id

                Layout.fillWidth: true
                Layout.preferredWidth: (presetGrid.width - presetGrid.columnSpacing) / 2
                Layout.minimumWidth: 320
                implicitHeight: 246
                radius: 14
                color: root.surfaceContainer
                border.color: presetCard.isActiveRice ? root.color1 : (presetCard.hasExtraSettings ? (presetCardH.hovered ? "#e5c890" : Qt.alpha("#e5c890", 0.45)) : (presetCardH.hovered ? Qt.alpha(root.color1, 0.35) : Qt.alpha(root.borderCol, 0.4)))
                border.width: (presetCard.isActiveRice || presetCard.hasExtraSettings) ? 2 : 1
                clip: true

                HoverHandler {
                    id: presetCardH
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 116
                        color: root.surface
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: presetCard.modelData.wallpaperCopyPath ? ("file://" + presetCard.modelData.wallpaperCopyPath) : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize: Qt.size(360, 160)
                        }

                        Rectangle {
                            anchors.fill: parent

                            gradient: Gradient {
                                GradientStop {
                                    position: 0
                                    color: Qt.alpha("#000000", 0.45)
                                }

                                GradientStop {
                                    position: 0.5
                                    color: "transparent"
                                }

                                GradientStop {
                                    position: 1
                                    color: Qt.alpha("#000000", 0.7)
                                }

                            }

                        }

                        RowLayout {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 8
                            spacing: 6

                            Rectangle {
                                visible: presetCard.isActiveRice
                                implicitHeight: 22
                                implicitWidth: activeBadgeText.implicitWidth + 14
                                radius: 11
                                color: root.color1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        text: "check"
                                        font.pixelSize: 11
                                        font.family: "Material Symbols Rounded"
                                        color: root.foreground
                                    }

                                    Text {
                                        id: activeBadgeText

                                        text: qsTr("ACTIVE")
                                        font.family: "Google Sans"
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: root.foreground
                                    }

                                }

                            }

                            Rectangle {
                                visible: presetCard.hasExtraSettings
                                implicitHeight: 22
                                implicitWidth: extraBadgeLayout.implicitWidth + 14
                                radius: 11
                                color: Qt.alpha("#e5c890", 0.95)

                                RowLayout {
                                    id: extraBadgeLayout

                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        text: "tune"
                                        font.pixelSize: 11
                                        font.family: "Material Symbols Rounded"
                                        color: "#1e1e2e"
                                    }

                                    Text {
                                        id: extraBadgeText

                                        text: qsTr("EXTENDED")
                                        font.family: "Google Sans"
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: "#1e1e2e"
                                    }

                                }

                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                implicitHeight: 20
                                implicitWidth: dateBadgeText.implicitWidth + 12
                                radius: 10
                                color: Qt.alpha("#000000", 0.65)

                                Text {
                                    id: dateBadgeText

                                    anchors.centerIn: parent
                                    text: presetsTabCol.formatDate(presetCard.modelData.updatedAt || presetCard.modelData.createdAt)
                                    font.family: "Google Sans"
                                    font.pixelSize: 9
                                    color: "#ffffff"
                                }

                            }

                        }

                        RowLayout {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 8
                            spacing: 6

                            Rectangle {
                                implicitHeight: 20
                                implicitWidth: themePillRow.implicitWidth + 12
                                radius: 6
                                color: Qt.alpha("#000000", 0.75)

                                RowLayout {
                                    id: themePillRow

                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        text: "palette"
                                        font.pixelSize: 11
                                        font.family: "Material Symbols Rounded"
                                        color: presetCard.modelData.primaryColor || root.color1
                                    }

                                    Text {
                                        id: themePillText

                                        text: (presetCard.modelData.theme || "Theme") + (presetCard.modelData.isDarkMode ? " (Dark)" : " (Light)")
                                        font.family: "Google Sans"
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: "#ffffff"
                                    }

                                    Rectangle {
                                        visible: !!presetCard.modelData.primarySlot
                                        implicitHeight: 14
                                        implicitWidth: slotPillText.implicitWidth + 8
                                        radius: 3
                                        color: Qt.alpha(presetCard.modelData.primaryColor || root.color1, 0.35)

                                        Text {
                                            id: slotPillText

                                            anchors.centerIn: parent
                                            text: (presetCard.modelData.primarySlot || "").toUpperCase()
                                            font.family: "Google Sans"
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: "#ffffff"
                                        }

                                    }

                                }

                            }

                        }

                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8
                            visible: !presetCard.isConfirmingThis

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    Layout.fillWidth: true
                                    text: presetCard.modelData.name || "Preset"
                                    font.family: "Google Sans"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.textBright
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    visible: presetCard.hasExtraSettings
                                    implicitHeight: 18
                                    implicitWidth: extraTagRow.implicitWidth + 10
                                    radius: 9
                                    color: Qt.alpha("#e5c890", 0.16)
                                    border.color: Qt.alpha("#e5c890", 0.5)
                                    border.width: 1

                                    RowLayout {
                                        id: extraTagRow

                                        anchors.centerIn: parent
                                        spacing: 3

                                        Text {
                                            text: "extension"
                                            font.pixelSize: 10
                                            font.family: "Material Symbols Rounded"
                                            color: "#e5c890"
                                        }

                                        Text {
                                            text: qsTr("Extended")
                                            font.family: "Google Sans"
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: "#e5c890"
                                        }

                                    }

                                }

                                RowLayout {
                                    spacing: 4

                                    Rectangle {
                                        implicitWidth: 14
                                        implicitHeight: 14
                                        radius: 7
                                        color: presetCard.modelData.primaryColor || root.color1
                                        border.color: Qt.alpha(root.borderCol, 0.5)
                                        border.width: 1
                                    }

                                    Rectangle {
                                        implicitWidth: 14
                                        implicitHeight: 14
                                        radius: 7
                                        color: presetCard.modelData.secondaryColor || root.color2
                                        border.color: Qt.alpha(root.borderCol, 0.5)
                                        border.width: 1
                                    }

                                    Rectangle {
                                        implicitWidth: 14
                                        implicitHeight: 14
                                        radius: 7
                                        color: presetCard.modelData.surfaceColor || root.surface
                                        border.color: Qt.alpha(root.borderCol, 0.5)
                                        border.width: 1
                                    }

                                    Rectangle {
                                        implicitWidth: 14
                                        implicitHeight: 14
                                        radius: 7
                                        color: presetCard.modelData.backgroundColor || root.background
                                        border.color: Qt.alpha(root.borderCol, 0.5)
                                        border.width: 1
                                    }

                                }

                            }

                            Flow {
                                Layout.fillWidth: true
                                spacing: 6

                                Repeater {
                                    model: {
                                        var tabs = presetCard.modelData.tabs;
                                        if (tabs && Array.isArray(tabs) && tabs.length > 0)
                                            return tabs;

                                        var comps = presetCard.modelData.components;
                                        if (comps && Array.isArray(comps) && comps.length > 0)
                                            return comps;

                                        return ["theme", "general", "windows", "bar", "launcher", "apptheming"];
                                    }

                                    delegate: Rectangle {
                                        id: compPill

                                        required property var modelData
                                        readonly property bool isExtraComp: presetsTabCol.defaultTabsList.indexOf(String(modelData).toLowerCase()) === -1
                                        readonly property var tabInfo: {
                                            var key = String(modelData).toLowerCase();
                                            if (key.indexOf("theme") !== -1)
                                                return {
                                                "icon": "palette",
                                                "name": "Theme"
                                            };

                                            if (key.indexOf("gen") !== -1)
                                                return {
                                                "icon": "tune",
                                                "name": "General"
                                            };

                                            if (key.indexOf("win") !== -1)
                                                return {
                                                "icon": "desktop_windows",
                                                "name": "Windows"
                                            };

                                            if (key.indexOf("bar") !== -1)
                                                return {
                                                "icon": "dock",
                                                "name": "Bar"
                                            };

                                            if (key.indexOf("launch") !== -1)
                                                return {
                                                "icon": "rocket_launch",
                                                "name": "Launcher"
                                            };

                                            if (key.indexOf("apptheming") !== -1 || key.indexOf("theming") !== -1)
                                                return {
                                                "icon": "format_paint",
                                                "name": "Theming"
                                            };

                                            if (key.indexOf("app") !== -1)
                                                return {
                                                "icon": "apps",
                                                "name": "Apps"
                                            };

                                            if (key.indexOf("notif") !== -1)
                                                return {
                                                "icon": "notifications",
                                                "name": "Notif"
                                            };

                                            if (key.indexOf("default") !== -1)
                                                return {
                                                "icon": "apps",
                                                "name": "Default"
                                            };

                                            if (key.indexOf("clock") !== -1 || key.indexOf("date") !== -1)
                                                return {
                                                "icon": "schedule",
                                                "name": "Clock"
                                            };

                                            if (key.indexOf("mon") !== -1)
                                                return {
                                                "icon": "monitor",
                                                "name": "Monitors"
                                            };

                                            if (key.indexOf("short") !== -1 || key === "shortcuts")
                                                return {
                                                "icon": "shortcut",
                                                "name": "Shortcuts"
                                            };

                                            if (key.indexOf("key") !== -1 || key.indexOf("mouse") !== -1 || key.indexOf("input") !== -1)
                                                return {
                                                "icon": "keyboard",
                                                "name": "Input"
                                            };

                                            return {
                                                "icon": "style",
                                                "name": String(modelData)
                                            };
                                        }

                                        implicitHeight: 18
                                        implicitWidth: pillRow.implicitWidth + (isExtraComp ? 10 : 6)
                                        radius: 4
                                        color: isExtraComp ? Qt.alpha("#e5c890", 0.16) : Qt.alpha(root.surface, 0.4)
                                        border.color: isExtraComp ? Qt.alpha("#e5c890", 0.55) : Qt.alpha(root.borderCol, 0.25)
                                        border.width: 1

                                        RowLayout {
                                            id: pillRow

                                            anchors.centerIn: parent
                                            spacing: 3

                                            Text {
                                                text: compPill.tabInfo.icon
                                                font.pixelSize: 11
                                                font.family: "Material Symbols Rounded"
                                                color: compPill.isExtraComp ? "#e5c890" : root.color1
                                            }

                                            Text {
                                                text: compPill.tabInfo.name
                                                font.family: "Google Sans"
                                                font.pixelSize: 9
                                                font.bold: compPill.isExtraComp
                                                color: compPill.isExtraComp ? "#e5c890" : root.textMuted
                                            }

                                        }

                                    }

                                }

                            }

                            Item {
                                Layout.fillHeight: true
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                SettingButton {
                                    Layout.fillWidth: true
                                    text: presetCard.isActiveRice ? qsTr("Applied") : qsTr("Apply")
                                    icon: presetCard.isActiveRice ? "check" : "play_arrow"
                                    variant: presetCard.isActiveRice ? "secondary" : "primary"
                                    compact: true
                                    onClicked: {
                                        PresetService.applyPreset(presetCard.modelData.id);
                                    }
                                }

                                SettingButton {
                                    text: qsTr("Update")
                                    icon: "sync"
                                    variant: "secondary"
                                    compact: true
                                    onClicked: {
                                        presetsTabCol.confirmingActionId = presetCard.modelData.id;
                                        presetsTabCol.confirmingActionType = "overwrite";
                                    }
                                }

                                SettingButton {
                                    icon: "delete"
                                    variant: "danger"
                                    compact: true
                                    onClicked: {
                                        presetsTabCol.confirmingActionId = presetCard.modelData.id;
                                        presetsTabCol.confirmingActionType = "delete";
                                    }
                                }
                            }

                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8
                            visible: presetCard.isConfirmingThis

                            Text {
                                Layout.fillWidth: true
                                text: presetsTabCol.confirmingActionType === "delete" ? qsTr("Delete preset '%1'?").arg(presetCard.modelData.name) : qsTr("Overwrite '%1' with current appearance?").arg(presetCard.modelData.name)
                                font.family: "Google Sans"
                                font.pixelSize: 11
                                font.bold: true
                                color: presetsTabCol.confirmingActionType === "delete" ? "#f38ba8" : root.color1
                                wrapMode: Text.Wrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: presetsTabCol.confirmingActionType === "delete" ? qsTr("This will delete the preset snapshot and its stored wallpaper copy.") : qsTr("Your current Bar, Windows, Theme, Launcher & Wallpaper will replace this preset.")
                                font.family: "Google Sans"
                                font.pixelSize: 9
                                color: root.textMuted
                                wrapMode: Text.Wrap
                            }

                            Item {
                                Layout.fillHeight: true
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                SettingButton {
                                    Layout.fillWidth: true
                                    text: presetsTabCol.confirmingActionType === "delete" ? qsTr("Yes, Delete") : qsTr("Yes, Overwrite")
                                    variant: presetsTabCol.confirmingActionType === "delete" ? "danger" : "primary"
                                    compact: true
                                    onClicked: {
                                        if (presetsTabCol.confirmingActionType === "delete") {
                                            PresetService.deletePreset(presetCard.modelData.id);
                                        } else {
                                            PresetService.overwritePreset(presetCard.modelData.id);
                                            presetsTabCol.confirmingActionId = "";
                                            presetsTabCol.confirmingActionType = "";
                                        }
                                    }
                                }

                                SettingButton {
                                    text: qsTr("Cancel")
                                    variant: "ghost"
                                    compact: true
                                    onClicked: {
                                        presetsTabCol.confirmingActionId = "";
                                        presetsTabCol.confirmingActionType = "";
                                    }
                                }
                            }

                        }

                    }

                }

                Behavior on border.color {
                    ColorAnimation {
                        duration: 150
                    }

                }

            }

        }

    }

}
