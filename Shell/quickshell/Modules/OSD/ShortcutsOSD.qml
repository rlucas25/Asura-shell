import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.Asura
import qs.Components
import qs.Services

PanelWindow {
    id: root

    WlrLayershell.namespace: "asura-shortcuts-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: (root.isOpen && root.animProgress > 0.05) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    property bool isOpen: false
    property real animProgress: 0.0
    property string searchQuery: ""
    property string selectedCategory: "all"

    readonly property real scaleFactor: (typeof Config !== "undefined" && Config.uiScale !== undefined) ? Config.uiScale : 1.0

    readonly property string focusedMonitorName: (Hyprland.focusedMonitor && Hyprland.focusedMonitor.name) ? Hyprland.focusedMonitor.name : ""

    screen: {
        if (root.focusedMonitorName && Quickshell.screens) {
            var target = Quickshell.screens.find(s => s.name === root.focusedMonitorName);
            if (target) return target;
        }
        return (Quickshell.screens && Quickshell.screens.length > 0) ? Quickshell.screens[0] : null;
    }

    visible: root.isOpen || root.animProgress > 0.01

    Behavior on animProgress {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    readonly property var categoryList: [
        { "id": "all", "label": "All", "icon": "󰌌" },
        { "id": "custom", "label": "Custom", "icon": "󰓹" },
        { "id": "windows", "label": "Windows", "icon": "󱂬" },
        { "id": "workspaces", "label": "Workspaces", "icon": "󱂪" },
        { "id": "menus", "label": "Menus", "icon": "󱗼" },
        { "id": "apps", "label": "Apps", "icon": "󰵆" },
        { "id": "media", "label": "Media", "icon": "󰎆" },
        { "id": "system", "label": "System", "icon": "󰒓" }
    ]

    function getCategoryCount(catId) {
        if (catId === "all") return root.allItems.length;
        var count = 0;
        var list = root.allItems;
        for (var i = 0; i < list.length; i++) {
            if (list[i].category === catId) count++;
        }
        return count;
    }

    function getCategoryIcon(cat) {
        switch (cat) {
            case "windows": return "󱂬";
            case "workspaces": return "󱂪";
            case "menus": return "󱗼";
            case "apps": return "󰵆";
            case "media": return "󰎆";
            case "system": return "󰒓";
            case "custom": return "󰓹";
            default: return "󰌌";
        }
    }

    readonly property var allItems: {
        var list = [];
        var cust = ShortcutsService.customShortcuts || [];
        for (var j = 0; j < cust.length; j++) {
            var c = cust[j];
            list.push({
                "id": c.id,
                "category": "custom",
                "label": c.label || "Custom Shortcut",
                "hint": c.value ? ("Exec: " + c.value) : (c.hint || "Custom Action"),
                "default": c.chord,
                "chord": c.chord,
                "normalized": c.normalized || ShortcutsService.normalizeChord(c.chord),
                "isCustom": true,
                "enabled": c.enabled !== false
            });
        }
        var sys = ShortcutsService.shortcuts || [];
        for (var i = 0; i < sys.length; i++) {
            list.push(sys[i]);
        }
        return list;
    }

    readonly property var filteredItems: {
        var raw = root.allItems;
        var cat = root.selectedCategory;
        var q = root.searchQuery.trim().toLowerCase();

        return raw.filter(function(item) {
            if (!item) return false;
            if (cat !== "all" && item.category !== cat) return false;
            if (q === "") return true;

            var matchLabel = item.label && item.label.toLowerCase().indexOf(q) !== -1;
            var matchHint = item.hint && item.hint.toLowerCase().indexOf(q) !== -1;
            var matchChord = item.chord && item.chord.toLowerCase().indexOf(q) !== -1;
            var matchCat = item.category && item.category.toLowerCase().indexOf(q) !== -1;
            return matchLabel || matchHint || matchChord || matchCat;
        });
    }

    function open(monitorName) {
        root.isOpen = true;
    }

    function close() {
        root.isOpen = false;
        root.searchQuery = "";
    }

    function toggle(monitorName) {
        if (root.isOpen) {
            root.close();
        } else {
            root.open(monitorName);
        }
    }

    onIsOpenChanged: {
        if (root.isOpen) {
            root.animProgress = 1.0;
            ShortcutsService.reload();
            MenuService.registerMenuOpen(root);
            focusTimer.restart();
        } else {
            root.animProgress = 0.0;
            MenuService.unregisterMenuOpen(root);
        }
    }

    Timer {
        id: focusTimer
        interval: 60
        repeat: false
        onTriggered: {
            if (searchInput)
                searchInput.forceActiveFocus();
        }
    }

    Connections {
        target: MenuService

        function onToggleShortcutsOverlayRequested(monitorName) {
            root.toggle(monitorName);
        }

        function onOpenShortcutsOverlayRequested(monitorName) {
            root.open(monitorName);
        }

        function onCloseShortcutsOverlayRequested() {
            root.close();
        }

        function onCloseAllRequested() {
            root.close();
        }
    }

    Item {
        id: emptyMask
        width: 0
        height: 0
    }

    mask: Region {
        item: (root.isOpen || root.animProgress > 0.01) ? backdropArea : emptyMask
    }

    Rectangle {
        id: backdropArea
        anchors.fill: parent
        color: Qt.alpha(Colors.cfg.background, 0.65 * root.animProgress)

        MouseArea {
            anchors.fill: parent
            enabled: root.isOpen
            onClicked: root.close()
        }
    }

    Rectangle {
        id: mainCard
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, Math.max(680, Math.round(920 * root.scaleFactor)))
        height: Math.min(parent.height - 48, Math.round(660 * root.scaleFactor))
        radius: Config.effectiveMenuRadius
        color: Colors.cfg.surfaceContainer
        border.width: 1
        border.color: Qt.alpha(Colors.cfg.primary, 0.35)
        opacity: root.animProgress
        scale: 0.94 + 0.06 * root.animProgress
        clip: true

        focus: true
        Keys.onEscapePressed: root.close()

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(64 * root.scaleFactor)
                Layout.leftMargin: Math.round(20 * root.scaleFactor)
                Layout.rightMargin: Math.round(20 * root.scaleFactor)
                spacing: Math.round(14 * root.scaleFactor)

                Rectangle {
                    Layout.preferredWidth: Math.round(38 * root.scaleFactor)
                    Layout.preferredHeight: Math.round(38 * root.scaleFactor)
                    Layout.alignment: Qt.AlignVCenter
                    radius: Math.round(10 * root.scaleFactor)
                    color: Qt.alpha(Colors.cfg.primary, 0.14)
                    border.width: 1
                    border.color: Qt.alpha(Colors.cfg.primary, 0.35)

                    Text {
                        anchors.centerIn: parent
                        text: "󰌌"
                        font.family: "GeistMono Nerd Font Propo"
                        font.pixelSize: Math.round(18 * root.scaleFactor)
                        color: Colors.cfg.primary
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: Math.round(2 * root.scaleFactor)

                    Text {
                        text: "Shortcuts & Keybinds"
                        font.family: "GeistMono Nerd Font Propo"
                        font.pixelSize: Math.round(15 * root.scaleFactor)
                        font.weight: Font.DemiBold
                        color: Colors.cfg.textBright
                    }

                    Text {
                        text: "Desktop Cheatsheet HUD • " + root.filteredItems.length + " keybindings"
                        font.family: "GeistMono Nerd Font Propo"
                        font.pixelSize: Math.round(11 * root.scaleFactor)
                        color: Colors.cfg.textSecondary
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: Math.round(280 * root.scaleFactor)
                    Layout.preferredHeight: Math.round(36 * root.scaleFactor)
                    Layout.alignment: Qt.AlignVCenter
                    radius: Config.effectiveGeneralRadius
                    color: Qt.alpha(Colors.cfg.surfaceContainerHigh, 0.7)
                    border.width: 1
                    border.color: searchInput.activeFocus ? Colors.cfg.primary : Qt.alpha(Colors.cfg.border, 0.35)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Math.round(10 * root.scaleFactor)
                        anchors.rightMargin: Math.round(10 * root.scaleFactor)
                        spacing: Math.round(8 * root.scaleFactor)

                        Text {
                            text: "󰍉"
                            font.family: "GeistMono Nerd Font Propo"
                            font.pixelSize: Math.round(13 * root.scaleFactor)
                            color: searchInput.activeFocus ? Colors.cfg.primary : Colors.cfg.textSecondary
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            font.family: "GeistMono Nerd Font Propo"
                            font.pixelSize: Math.round(12 * root.scaleFactor)
                            color: Colors.cfg.textBright
                            clip: true
                            selectByMouse: true
                            text: root.searchQuery
                            onTextChanged: root.searchQuery = text

                            Text {
                                anchors.fill: parent
                                text: "Search shortcut or key..."
                                font.family: parent.font.family
                                font.pixelSize: parent.font.pixelSize
                                color: Qt.alpha(Colors.cfg.textSecondary, 0.6)
                                visible: !parent.text && !parent.activeFocus
                            }

                            Keys.onEscapePressed: {
                                if (text.length > 0) {
                                    text = "";
                                } else {
                                    root.close();
                                }
                            }
                        }

                        Text {
                            visible: searchInput.text.length > 0
                            text: "󰅖"
                            font.family: "GeistMono Nerd Font Propo"
                            font.pixelSize: Math.round(12 * root.scaleFactor)
                            color: clearMouse.containsMouse ? Colors.cfg.primary : Colors.cfg.textSecondary

                            MouseArea {
                                id: clearMouse
                                anchors.fill: parent
                                anchors.margins: -4
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    searchInput.text = "";
                                    searchInput.forceActiveFocus();
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: Math.round(36 * root.scaleFactor)
                    Layout.preferredHeight: Math.round(36 * root.scaleFactor)
                    Layout.alignment: Qt.AlignVCenter
                    radius: Math.round(8 * root.scaleFactor)
                    color: closeMouse.containsMouse ? Qt.alpha(Colors.cfg.error, 0.15) : Qt.alpha(Colors.cfg.surfaceContainerHigh, 0.6)
                    border.width: 1
                    border.color: closeMouse.containsMouse ? Qt.alpha(Colors.cfg.error, 0.4) : Qt.alpha(Colors.cfg.border, 0.3)

                    scale: closeMouse.containsPress ? 0.94 : (closeMouse.containsMouse ? 1.04 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 100 } }
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: "GeistMono Nerd Font Propo"
                        font.pixelSize: Math.round(14 * root.scaleFactor)
                        color: closeMouse.containsMouse ? Colors.cfg.error : Colors.cfg.textSecondary
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.alpha(Colors.cfg.border, 0.35)
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(44 * root.scaleFactor)

                Flickable {
                    anchors.fill: parent
                    anchors.leftMargin: Math.round(20 * root.scaleFactor)
                    anchors.rightMargin: Math.round(20 * root.scaleFactor)
                    contentWidth: categoryRow.implicitWidth
                    contentHeight: height
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.HorizontalFlick
                    clip: true

                    Row {
                        id: categoryRow
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Math.round(8 * root.scaleFactor)

                        Repeater {
                            model: root.categoryList

                            Rectangle {
                                id: pillRect
                                readonly property bool isSelected: root.selectedCategory === modelData.id
                                readonly property int count: root.getCategoryCount(modelData.id)

                                implicitHeight: Math.round(28 * root.scaleFactor)
                                implicitWidth: pillRow.implicitWidth + Math.round(20 * root.scaleFactor)
                                radius: Math.round(7 * root.scaleFactor)
                                color: isSelected ? Colors.cfg.primary : (pillMouse.containsMouse ? Qt.alpha(Colors.cfg.surfaceContainerHigh, 0.9) : Qt.alpha(Colors.cfg.surfaceContainerHigh, 0.4))
                                border.width: 1
                                border.color: isSelected ? Colors.cfg.primary : (pillMouse.containsMouse ? Qt.alpha(Colors.cfg.primary, 0.3) : Qt.alpha(Colors.cfg.border, 0.2))

                                scale: pillMouse.containsPress ? 0.96 : (pillMouse.containsMouse ? 1.02 : 1.0)
                                Behavior on scale { NumberAnimation { duration: 120 } }
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Row {
                                    id: pillRow
                                    anchors.centerIn: parent
                                    spacing: Math.round(6 * root.scaleFactor)

                                    Text {
                                        text: modelData.icon
                                        font.family: "GeistMono Nerd Font Propo"
                                        font.pixelSize: Math.round(11 * root.scaleFactor)
                                        color: pillRect.isSelected ? Colors.cfg.on_primary : Colors.cfg.primary
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: modelData.label
                                        font.family: "GeistMono Nerd Font Propo"
                                        font.pixelSize: Math.round(11 * root.scaleFactor)
                                        font.weight: pillRect.isSelected ? Font.DemiBold : Font.Normal
                                        color: pillRect.isSelected ? Colors.cfg.on_primary : Colors.cfg.text
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Rectangle {
                                        implicitHeight: Math.round(16 * root.scaleFactor)
                                        implicitWidth: countText.implicitWidth + Math.round(8 * root.scaleFactor)
                                        radius: Math.round(8 * root.scaleFactor)
                                        color: pillRect.isSelected ? Qt.alpha(Colors.cfg.on_primary, 0.22) : Qt.alpha(Colors.cfg.surfaceContainerHighest, 0.6)
                                        anchors.verticalCenter: parent.verticalCenter

                                        Text {
                                            id: countText
                                            anchors.centerIn: parent
                                            text: pillRect.count.toString()
                                            font.family: "GeistMono Nerd Font Propo"
                                            font.pixelSize: Math.round(9 * root.scaleFactor)
                                            font.weight: Font.DemiBold
                                            color: pillRect.isSelected ? Colors.cfg.on_primary : Colors.cfg.textSecondary
                                        }
                                    }
                                }

                                MouseArea {
                                    id: pillMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.selectedCategory = modelData.id
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.alpha(Colors.cfg.border, 0.2)
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.centerIn: parent
                    visible: root.filteredItems.length === 0
                    spacing: Math.round(8 * root.scaleFactor)

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰍉"
                        font.family: "GeistMono Nerd Font Propo"
                        font.pixelSize: Math.round(38 * root.scaleFactor)
                        color: Qt.alpha(Colors.cfg.textSecondary, 0.4)
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "No shortcuts found"
                        font.family: "GeistMono Nerd Font Propo"
                        font.pixelSize: Math.round(14 * root.scaleFactor)
                        font.weight: Font.DemiBold
                        color: Colors.cfg.textSecondary
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.searchQuery ? ("No results matching \"" + root.searchQuery + "\"") : "No keybindings in this category"
                        font.family: "GeistMono Nerd Font Propo"
                        font.pixelSize: Math.round(11 * root.scaleFactor)
                        color: Qt.alpha(Colors.cfg.textSecondary, 0.7)
                    }
                }

                GridView {
                    id: shortcutsGrid
                    anchors.fill: parent
                    anchors.leftMargin: Math.round(16 * root.scaleFactor)
                    anchors.rightMargin: Math.round(16 * root.scaleFactor)
                    anchors.topMargin: Math.round(8 * root.scaleFactor)
                    anchors.bottomMargin: Math.round(8 * root.scaleFactor)
                    clip: true
                    visible: root.filteredItems.length > 0

                    readonly property int numCols: width < 660 ? 1 : 2
                    cellWidth: Math.floor(width / numCols)
                    cellHeight: Math.round(62 * root.scaleFactor)

                    model: root.filteredItems

                    ScrollBar.vertical: ScrollBar {
                        id: vertScrollBar
                        policy: shortcutsGrid.contentHeight > shortcutsGrid.height ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
                        contentItem: Rectangle {
                            implicitWidth: Math.round(4 * root.scaleFactor)
                            radius: Math.round(2 * root.scaleFactor)
                            color: vertScrollBar.hovered || vertScrollBar.pressed ? Colors.cfg.primary : Qt.alpha(Colors.cfg.border, 0.4)
                        }
                    }

                    delegate: Item {
                        width: shortcutsGrid.cellWidth
                        height: shortcutsGrid.cellHeight

                        readonly property var itemData: modelData
                        readonly property bool isConflicting: {
                            var norm = itemData.normalized || ShortcutsService.normalizeChord(itemData.chord);
                            return Boolean(ShortcutsService.conflicts && ShortcutsService.conflicts.indexOf(norm) !== -1);
                        }

                        Rectangle {
                            id: cardInner
                            anchors.fill: parent
                            anchors.margins: Math.round(4 * root.scaleFactor)
                            radius: Math.round(8 * root.scaleFactor)
                            color: itemMouse.containsMouse
                                ? Qt.alpha(Colors.cfg.primary, 0.08)
                                : Qt.alpha(Colors.cfg.surfaceContainerHigh, 0.45)
                            border.width: 1
                            border.color: isConflicting
                                ? Qt.alpha(Colors.cfg.error, 0.65)
                                : (itemMouse.containsMouse ? Qt.alpha(Colors.cfg.primary, 0.35) : Qt.alpha(Colors.cfg.border, 0.2))

                            Behavior on color { ColorAnimation { duration: 100 } }
                            Behavior on border.color { ColorAnimation { duration: 100 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Math.round(10 * root.scaleFactor)
                                anchors.rightMargin: Math.round(10 * root.scaleFactor)
                                spacing: Math.round(10 * root.scaleFactor)

                                Rectangle {
                                    Layout.preferredWidth: Math.round(30 * root.scaleFactor)
                                    Layout.preferredHeight: Math.round(30 * root.scaleFactor)
                                    Layout.alignment: Qt.AlignVCenter
                                    radius: Math.round(6 * root.scaleFactor)
                                    color: Qt.alpha(Colors.cfg.primary, 0.1)
                                    border.width: 1
                                    border.color: Qt.alpha(Colors.cfg.primary, 0.2)

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.getCategoryIcon(itemData.category)
                                        font.family: "GeistMono Nerd Font Propo"
                                        font.pixelSize: Math.round(13 * root.scaleFactor)
                                        color: Colors.cfg.primary
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: Math.round(2 * root.scaleFactor)

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Math.round(6 * root.scaleFactor)

                                        Text {
                                            Layout.fillWidth: true
                                            text: itemData.label || ""
                                            font.family: "GeistMono Nerd Font Propo"
                                            font.pixelSize: Math.round(12 * root.scaleFactor)
                                            font.weight: Font.DemiBold
                                            color: Colors.cfg.textBright
                                            elide: Text.ElideRight
                                        }

                                        Rectangle {
                                            visible: Boolean(itemData.isCustom)
                                            implicitHeight: Math.round(16 * root.scaleFactor)
                                            implicitWidth: custRow.implicitWidth + Math.round(8 * root.scaleFactor)
                                            radius: Math.round(4 * root.scaleFactor)
                                            color: Qt.alpha(Colors.cfg.primary, 0.15)
                                            border.width: 1
                                            border.color: Qt.alpha(Colors.cfg.primary, 0.4)

                                            Row {
                                                id: custRow
                                                anchors.centerIn: parent
                                                spacing: Math.round(3 * root.scaleFactor)
                                                Text {
                                                    text: "󰓹"
                                                    font.family: "GeistMono Nerd Font Propo"
                                                    font.pixelSize: Math.round(9 * root.scaleFactor)
                                                    color: Colors.cfg.primary
                                                }
                                                Text {
                                                    text: "Custom"
                                                    font.family: "GeistMono Nerd Font Propo"
                                                    font.pixelSize: Math.round(8 * root.scaleFactor)
                                                    font.weight: Font.DemiBold
                                                    color: Colors.cfg.primary
                                                }
                                            }
                                        }

                                        Rectangle {
                                            visible: isConflicting
                                            implicitHeight: Math.round(16 * root.scaleFactor)
                                            implicitWidth: confRow.implicitWidth + Math.round(8 * root.scaleFactor)
                                            radius: Math.round(4 * root.scaleFactor)
                                            color: Qt.alpha(Colors.cfg.error, 0.15)
                                            border.width: 1
                                            border.color: Qt.alpha(Colors.cfg.error, 0.4)

                                            Row {
                                                id: confRow
                                                anchors.centerIn: parent
                                                spacing: Math.round(3 * root.scaleFactor)
                                                Text {
                                                    text: "󰀦"
                                                    font.family: "GeistMono Nerd Font Propo"
                                                    font.pixelSize: Math.round(9 * root.scaleFactor)
                                                    color: Colors.cfg.error
                                                }
                                                Text {
                                                    text: "Conflict"
                                                    font.family: "GeistMono Nerd Font Propo"
                                                    font.pixelSize: Math.round(8 * root.scaleFactor)
                                                    font.weight: Font.DemiBold
                                                    color: Colors.cfg.error
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: itemData.hint || (itemData.category ? itemData.category.toUpperCase() : "")
                                        font.family: "GeistMono Nerd Font Propo"
                                        font.pixelSize: Math.round(10 * root.scaleFactor)
                                        color: Colors.cfg.textSecondary
                                        elide: Text.ElideRight
                                    }
                                }

                                Item {
                                    Layout.alignment: Qt.AlignVCenter
                                    implicitWidth: comboView.implicitWidth
                                    implicitHeight: comboView.implicitHeight

                                    KeyComboView {
                                        id: comboView
                                        chord: itemData.chord || ""
                                    }
                                }
                            }

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.alpha(Colors.cfg.border, 0.25)
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(44 * root.scaleFactor)
                Layout.leftMargin: Math.round(20 * root.scaleFactor)
                Layout.rightMargin: Math.round(20 * root.scaleFactor)
                spacing: Math.round(12 * root.scaleFactor)

                Row {
                    spacing: Math.round(6 * root.scaleFactor)
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        implicitHeight: Math.round(20 * root.scaleFactor)
                        implicitWidth: escText.implicitWidth + Math.round(10 * root.scaleFactor)
                        radius: Math.round(4 * root.scaleFactor)
                        color: Qt.alpha(Colors.cfg.surfaceContainerHighest, 0.7)
                        border.width: 1
                        border.color: Qt.alpha(Colors.cfg.border, 0.35)
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            id: escText
                            anchors.centerIn: parent
                            text: "ESC"
                            font.family: "GeistMono Nerd Font Propo"
                            font.pixelSize: Math.round(9 * root.scaleFactor)
                            font.weight: Font.DemiBold
                            color: Colors.cfg.textBright
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "to close"
                        font.family: "GeistMono Nerd Font Propo"
                        font.pixelSize: Math.round(11 * root.scaleFactor)
                        color: Colors.cfg.textSecondary
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: root.filteredItems.length + " of " + root.allItems.length + " keybinds"
                    font.family: "GeistMono Nerd Font Propo"
                    font.pixelSize: Math.round(11 * root.scaleFactor)
                    color: Qt.alpha(Colors.cfg.textSecondary, 0.8)
                }

                Rectangle {
                    id: settingsBtn
                    Layout.alignment: Qt.AlignVCenter
                    implicitHeight: Math.round(28 * root.scaleFactor)
                    implicitWidth: settingsBtnRow.implicitWidth + Math.round(16 * root.scaleFactor)
                    radius: Math.round(6 * root.scaleFactor)
                    color: setBtnMouse.containsMouse ? Qt.alpha(Colors.cfg.primary, 0.15) : Qt.alpha(Colors.cfg.surfaceContainerHigh, 0.6)
                    border.width: 1
                    border.color: setBtnMouse.containsMouse ? Colors.cfg.primary : Qt.alpha(Colors.cfg.border, 0.3)

                    scale: setBtnMouse.containsPress ? 0.96 : (setBtnMouse.containsMouse ? 1.02 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 100 } }
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Row {
                        id: settingsBtnRow
                        anchors.centerIn: parent
                        spacing: Math.round(5 * root.scaleFactor)

                        Text {
                            text: "󰒓"
                            font.family: "GeistMono Nerd Font Propo"
                            font.pixelSize: Math.round(11 * root.scaleFactor)
                            color: Colors.cfg.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Customize in Settings"
                            font.family: "GeistMono Nerd Font Propo"
                            font.pixelSize: Math.round(10.5 * root.scaleFactor)
                            font.weight: Font.DemiBold
                            color: Colors.cfg.textBright
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: setBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.close();
                            MenuService.openSettingsTab("shortcuts");
                        }
                    }
                }
            }
        }
    }
}
