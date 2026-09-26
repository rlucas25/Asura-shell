import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.Asura
import qs.Services
import qs.Animations

Item {
    id: root

    implicitWidth: 360
    implicitHeight: 480

    MenuEntrance {
        id: clipEntrance
        active: root.visible
        duration: 320
        startOffsetY: 14
    }

    property color primary: Colors.cfg.primary
    property color secondary: Colors.cfg.secondary
    property color background: Colors.cfg.background
    property color surface: Colors.cfg.surface
    property color surfaceContainer: Colors.cfg.surfaceContainer
    property color on_primary: Colors.cfg.on_primary
    property color text: Colors.cfg.text
    property color textSecondary: Colors.cfg.textSecondary
    property color warning: Colors.cfg.warning
    property color error: Colors.cfg.error

    // Compatibility aliases
    property alias color1: root.primary
    property alias color2: root.secondary
    property alias foreground: root.on_primary
    property alias textColor: root.text
    property alias textMuted: root.textSecondary

    property string searchQuery: ""
    property int selectedIndex: 0

    signal hideMenu()

    readonly property var allItems: ClipboardService.items || []
    readonly property var filteredItems: {
        var query = root.searchQuery.trim().toLowerCase();
        if (!query || query === "") {
            return root.allItems;
        }
        return root.allItems.filter(function(item) {
            if (item.type === "text") {
                return (item.content || "").toLowerCase().indexOf(query) !== -1;
            } else if (item.type === "image") {
                return (item.size || "").toLowerCase().indexOf(query) !== -1 || query === "image" || query === "img";
            }
            return false;
        });
    }

    onFilteredItemsChanged: {
        if (selectedIndex >= filteredItems.length) {
            selectedIndex = Math.max(0, filteredItems.length - 1);
        }
    }

    function selectAndPaste(index) {
        if (index >= 0 && index < filteredItems.length) {
            var item = filteredItems[index];
            if (item && item.id) {
                ClipboardService.pasteItem(item.id);
                root.hideMenu();
            }
        }
    }

    // Refresh when menu is opened / active
    Timer {
        id: menuRefreshTimer
        interval: 1500
        running: root.visible
        repeat: true
        onTriggered: {
            ClipboardService.refresh();
        }
    }

    focus: true
    Keys.forwardTo: [searchInput]

    Keys.onDownPressed: event => {
        if (filteredItems.length > 0) {
            selectedIndex = (selectedIndex + 1) % filteredItems.length;
            clipList.positionViewAtIndex(selectedIndex, ListView.Contain);
        }
        event.accepted = true;
    }

    Keys.onUpPressed: event => {
        if (filteredItems.length > 0) {
            selectedIndex = (selectedIndex - 1 + filteredItems.length) % filteredItems.length;
            clipList.positionViewAtIndex(selectedIndex, ListView.Contain);
        }
        event.accepted = true;
    }

    Keys.onReturnPressed: event => {
        selectAndPaste(selectedIndex);
        event.accepted = true;
    }

    Keys.onEnterPressed: event => {
        selectAndPaste(selectedIndex);
        event.accepted = true;
    }

    Keys.onEscapePressed: event => {
        root.hideMenu();
        event.accepted = true;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        opacity: clipEntrance.opacity
        transform: Translate {
            y: clipEntrance.offsetY
        }

        // ── Top Header ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Clipboard"
                font.pixelSize: 18
                font.bold: true
                color: root.textColor
            }

            // Count Badge
            Rectangle {
                implicitHeight: 20
                implicitWidth: countText.implicitWidth + 12
                radius: 100
                color: Qt.alpha(root.color1, 0.2)

                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: root.filteredItems.length
                    font.pixelSize: 9
                    font.bold: true
                    color: root.color1
                }
            }

            Item { Layout.fillWidth: true }

            // Clear All Button
            Rectangle {
                implicitWidth: clearRow.implicitWidth + 14
                implicitHeight: 30
                radius: 10
                color: clearMouse.hovered ? Qt.alpha(root.error, 0.2) : Qt.alpha(root.textColor, 0.05)
                border.color: clearMouse.hovered ? Qt.alpha(root.error, 0.4) : Qt.alpha(root.textColor, 0.1)
                border.width: 1
                visible: root.allItems.length > 0

                RowLayout {
                    id: clearRow
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "Clear"
                        font.pixelSize: 10
                        font.bold: true
                        color: clearMouse.hovered ? root.error : root.textMuted
                    }
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        ClipboardService.clearAll();
                    }
                }
            }
        }

        // ── Search Input Field ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 30
            color: root.surfaceContainer
            border.color: searchInput.activeFocus ? root.color1 : Qt.alpha(root.textColor, 0.1)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: "󰍉"
                    font.pixelSize: 13
                    font.family: "GeistMono Nerd Font Propo Propo"
                    color: searchInput.activeFocus ? root.color1 : root.textMuted
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    font.pixelSize: 11
                    color: root.textColor
                    clip: true
                    selectByMouse: true
                    activeFocusOnTab: true
                    text: root.searchQuery
                    onTextChanged: {
                        root.searchQuery = text;
                        root.selectedIndex = 0;
                    }

                    Text {
                        anchors.fill: parent
                        text: "Search"
                        font.pixelSize: 11
                        color: Qt.alpha(root.textMuted, 0.6)
                        visible: !searchInput.text && !searchInput.activeFocus
                    }

                    Keys.onDownPressed: event => {
                        if (root.filteredItems.length > 0) {
                            root.selectedIndex = (root.selectedIndex + 1) % root.filteredItems.length;
                            clipList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                        }
                        event.accepted = true;
                    }

                    Keys.onUpPressed: event => {
                        if (root.filteredItems.length > 0) {
                            root.selectedIndex = (root.selectedIndex - 1 + root.filteredItems.length) % root.filteredItems.length;
                            clipList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                        }
                        event.accepted = true;
                    }

                    Keys.onReturnPressed: event => {
                        root.selectAndPaste(root.selectedIndex);
                        event.accepted = true;
                    }

                    Keys.onEnterPressed: event => {
                        root.selectAndPaste(root.selectedIndex);
                        event.accepted = true;
                    }

                    Keys.onEscapePressed: event => {
                        root.hideMenu();
                        event.accepted = true;
                    }
                }

                Text {
                    text: "󰅖"
                    font.pixelSize: 12
                    font.family: "GeistMono Nerd Font Propo Propo"
                    color: root.textMuted
                    visible: root.searchQuery.length > 0
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            searchInput.text = "";
                            root.searchQuery = "";
                        }
                    }
                }
            }
        }

        // ── Main Content: List of Items or Empty State ──
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Empty State
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8
                visible: root.filteredItems.length === 0

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.allItems.length === 0 ? "󰅍" : "󰍉"
                    font.pixelSize: 32
                    font.family: "GeistMono Nerd Font Propo Propo"
                    color: Qt.alpha(root.textMuted, 0.4)
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.allItems.length === 0 ? "Clipboard is empty" : "No matching items found"
                    font.pixelSize: 12
                    font.bold: true
                    color: root.textMuted
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.allItems.length === 0 ? "Copy text or images to see them here" : "Try searching with different keywords"
                    font.pixelSize: 10
                    color: Qt.alpha(root.textMuted, 0.7)
                }
            }

            // Clipboard Items ListView
            ListView {
                id: clipList
                anchors.fill: parent
                visible: root.filteredItems.length > 0
                clip: true
                spacing: 6
                model: root.filteredItems
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    id: delegateItem
                    required property var modelData
                    required property int index

                    readonly property bool isSelected: root.selectedIndex === index
                    readonly property bool isImage: modelData.type === "image"

                    width: clipList.width
                    implicitHeight: isImage ? 126 : Math.min(80, Math.max(54, textPreviewCol.implicitHeight + 16))
                    radius: 10
                    color: isSelected ? Qt.alpha(root.color1, 0.15) : (itemMouse.hovered ? root.surfaceContainer : Qt.alpha(root.surfaceContainer, 0.6))

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedIndex = delegateItem.index;
                            root.selectAndPaste(delegateItem.index);
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        // Type Icon / Indicator
                        Rectangle {
                            Layout.preferredWidth: 3
                            Layout.preferredHeight: 30
                            radius: 7
                            color: delegateItem.isImage ? root.secondary : root.color1
                        }

                        // Image Thumbnail
                        Rectangle {
                            visible: delegateItem.isImage
                            Layout.preferredWidth: 100
                            Layout.preferredHeight: 100
                            radius: 10
                            color: Qt.alpha(root.textColor, 0)
                            clip: true

                            Image {
                                id: image
                                anchors.fill: parent
                                anchors.centerIn: parent
                                source: delegateItem.isImage && delegateItem.modelData.content ? "file://" + delegateItem.modelData.content : ""
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                smooth: true
                            }
                        }

                        // Content Details
                        ColumnLayout {
                            id: textPreviewCol
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                visible: !delegateItem.isImage
                                Layout.fillWidth: true
                                text:  (delegateItem.modelData.preview || "")
                                font.pixelSize: 11
                                font.bold: delegateItem.isImage
                                font.family: delegateItem.isImage ? "Inter" : "GeistMono Nerd Font Propo Propo"
                                color: root.textColor
                                wrapMode: Text.WrapAnywhere
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: delegateItem.modelData.size || ""
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: root.textMuted
                                }

                                Text {
                                    text: "•"
                                    font.pixelSize: 9
                                    color: Qt.alpha(root.textMuted, 0.5)
                                }

                                Text {
                                    text: delegateItem.modelData.time || ""
                                    font.pixelSize: 9
                                    color: root.textMuted
                                }

                                Item { Layout.fillWidth: true }
                            }
                        }

                        // Quick Action Buttons
                        RowLayout {
                            spacing: 4
                            z: 5

                            // Copy Button
                            Rectangle {
                                implicitWidth: 30
                                implicitHeight: 30
                                radius: 10
                                color: copyBtnMouse.hovered ? Qt.alpha(root.color1, 0.25) : Qt.alpha(root.textColor, 0.06)
                                border.color: copyBtnMouse.hovered ? root.color1 : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰆏"
                                    font.pixelSize: 12
                                    font.family: "GeistMono Nerd Font Propo Propo"
                                    color: copyBtnMouse.hovered ? root.color1 : root.textMuted
                                }

                                MouseArea {
                                    id: copyBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        ClipboardService.copyItem(delegateItem.modelData.id);
                                        root.hideMenu();
                                    }
                                }
                            }

                            // Delete Button
                            Rectangle {
                                implicitWidth: 30
                                implicitHeight: 30
                                radius: 10
                                color: delBtnMouse.hovered ? Qt.alpha(root.error, 0.25) : Qt.alpha(root.textColor, 0.06)
                                border.color: delBtnMouse.hovered ? root.error : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰆴"
                                    font.pixelSize: 12
                                    font.family: "GeistMono Nerd Font Propo Propo"
                                    color: delBtnMouse.hovered ? root.error : root.textMuted
                                }

                                MouseArea {
                                    id: delBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        ClipboardService.deleteItem(delegateItem.modelData.id);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Keyboard Hint Footer ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "󰌌 ↑ / ↓ navigate • Enter / Click to paste • Esc to close"
                font.family: "GeistMono Nerd Font Propo Propo"
                font.pixelSize: 9
                color: Qt.alpha(root.textMuted, 0.6)
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    Component.onCompleted: {
        ClipboardService.refresh();
        searchInput.forceActiveFocus();
    }
}