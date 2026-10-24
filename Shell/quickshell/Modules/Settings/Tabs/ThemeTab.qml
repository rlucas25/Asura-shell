import "../Components"
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Asura
import qs.Services

ColumnLayout {
    id: tabRoot

    required property var settingsRoot
    readonly property var root: settingsRoot

    Layout.fillWidth: true
    spacing: 16
    visible: root.currentTab === "theme"

    SettingSectionHeader {
        icon: "palette"
        title: qsTr("Theme Appearance")
        description: qsTr("Personalize color schemes, theme modes, and manage base16 presets")
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 74
        spacing: 12

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 14
            color: !Config.cfg.isDarkMode ? root.primary : root.surface

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (Config.cfg.isDarkMode) {
                        Config.cfg.isDarkMode = false;
                        Config.save();
                        if (Config.cfg.colorsAutoGenerate && Config.cfg.wallpaper)
                            Colors.generateDynamicColors(Config.cfg.wallpaper, false, Config.cfg.scheme);

                    }
                }
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: "light_mode"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 22
                    color: !Config.cfg.isDarkMode ? root.surfaceContainer : root.textColor
                }

                Text {
                    text: qsTr("Light Mode")
                    font.family: "Google Sans"
                    font.pixelSize: 13
                    font.bold: true
                    color: !Config.cfg.isDarkMode ? root.surfaceContainer : root.textColor
                }

            }

        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 14
            color: Config.cfg.isDarkMode ? root.primary : root.surfaceContainer

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!Config.cfg.isDarkMode) {
                        Config.cfg.isDarkMode = true;
                        Config.save();
                        if (Config.cfg.colorsAutoGenerate && Config.cfg.wallpaper)
                            Colors.generateDynamicColors(Config.cfg.wallpaper, true, Config.cfg.scheme);

                    }
                }
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: "dark_mode"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 22
                    color: Config.cfg.isDarkMode ? root.surfaceContainer : root.textColor
                }

                Text {
                    text: qsTr("Dark Mode")
                    font.family: "Google Sans"
                    font.pixelSize: 13
                    font.bold: true
                    color: Config.cfg.isDarkMode ? root.surfaceContainer : root.textColor
                }

            }

        }

    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 12

        SettingToggle {
            title: qsTr("Wallpaper Auto-Theme")
            description: qsTr("Dynamic Material colors generated from wallpaper")
            checked: Config.cfg.colorsAutoGenerate
            onToggled: (newState) => {
                Config.cfg.colorsAutoGenerate = newState;
                Config.save();
                if (Config.cfg.colorsAutoGenerate && Config.cfg.wallpaper)
                    Colors.generateDynamicColors(Config.cfg.wallpaper, Config.cfg.isDarkMode, Config.cfg.scheme || "tonal-spot");
                else if (!Config.cfg.colorsAutoGenerate && Config.cfg.wallpaper)
                    Colors.suggestPaletteFromWallpaper(Config.cfg.wallpaper, Config.cfg.isDarkMode);
            }
        }

        Rectangle {
            id: schemeCard

            Layout.fillWidth: true
            radius: 14
            color: root.surface
            visible: Config.cfg.colorsAutoGenerate
            Layout.preferredHeight: schemeColumn.implicitHeight + 28

            ColumnLayout {
                id: schemeColumn

                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: qsTr("Color Scheme")
                        font.family: "Google Sans"
                        font.pixelSize: 12
                        font.bold: true
                        color: root.textColor
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        implicitHeight: 22
                        implicitWidth: schemeCurrentText.implicitWidth + 18
                        radius: 11
                        color: Qt.alpha(root.color1, 0.16)
                        border.width: 1
                        border.color: Qt.alpha(root.color1, 0.35)

                        Text {
                            id: schemeCurrentText

                            anchors.centerIn: parent
                            text: (Config.cfg.scheme || "tonal-spot")
                            font.family: "Google Sans"
                            font.pixelSize: 9
                            font.bold: true
                            color: root.color1
                        }

                    }

                }

                Flow {
                    id: schemeFlow

                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: ["tonal-spot", "neutral", "monochrome", "vibrant", "expressive", "fidelity", "content", "rainbow", "fruit-salad"]

                        delegate: Rectangle {
                            id: schemePill

                            required property string modelData
                            readonly property bool isSelected: (Config.cfg.scheme || "tonal-spot") === modelData

                            implicitHeight: 30
                            implicitWidth: schemeLabel.implicitWidth + 22
                            radius: 15
                            color: isSelected ? root.color1 : (schemeMouse.containsMouse ? root.surfaceContainer : root.surface)
                            border.color: isSelected ? root.color1 : Qt.alpha(root.textColor, 0.1)
                            border.width: isSelected ? 0 : 1
                            scale: schemeMouse.pressed ? 0.95 : 1

                            Text {
                                id: schemeLabel

                                anchors.centerIn: parent
                                text: {
                                    switch (modelData) {
                                    case "tonal-spot":
                                        return "Tonal Spot";
                                    case "fruit-salad":
                                        return "Fruit Salad";
                                    default:
                                        return modelData.charAt(0).toUpperCase() + modelData.slice(1);
                                    }
                                }
                                font.family: "Google Sans"
                                font.pixelSize: 10
                                font.bold: schemePill.isSelected
                                color: schemePill.isSelected ? root.foreground : (schemeMouse.containsMouse ? root.textBright : root.textColor)

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }

                                }

                            }

                            MouseArea {
                                id: schemeMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Config.cfg.scheme = schemePill.modelData;
                                    Config.save();
                                    if (Config.cfg.colorsAutoGenerate && Config.cfg.wallpaper)
                                        Colors.generateDynamicColors(Config.cfg.wallpaper, Config.cfg.isDarkMode, schemePill.modelData);

                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }

                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 100
                                    easing.type: Easing.OutQuint
                                }

                            }

                        }

                    }

                }

            }

        }

        SettingCard {
            Layout.fillWidth: true
            visible: Config.cfg.colorsAutoGenerate

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: qsTr("Material You Active Tokens")
                        font.family: "Google Sans"
                        font.pixelSize: 12
                        font.bold: true
                        color: root.textColor
                    }

                    Text {
                        text: qsTr("Current extracted dynamic palette tokens. Click any swatch to copy its HEX value")
                        font.family: "Google Sans"
                        font.pixelSize: 10
                        color: root.textMuted
                    }
                }
            }

            Flow {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: [
                        { "name": "Primary", "color": Colors.cfg.primary },
                        { "name": "On Primary", "color": Colors.cfg.on_primary },
                        { "name": "Secondary", "color": Colors.cfg.secondary },
                        { "name": "Tertiary", "color": Colors.cfg.tertiary },
                        { "name": "Surface", "color": Colors.cfg.surface },
                        { "name": "Container", "color": Colors.cfg.surfaceContainer },
                        { "name": "Error", "color": Colors.cfg.error || "#f38ba8" }
                    ]

                    delegate: Rectangle {
                        id: swatchPill
                        required property var modelData
                        readonly property string hexStr: modelData.color ? modelData.color.toString() : "#000000"

                        implicitHeight: 32
                        implicitWidth: swatchRow.implicitWidth + 16
                        radius: 16
                        color: swatchMa.containsMouse ? root.surfaceContainer : root.surface
                        border.color: swatchMa.containsMouse ? root.color1 : Qt.alpha(root.borderCol, 0.4)
                        border.width: 1
                        scale: swatchMa.pressed ? 0.94 : (swatchMa.containsMouse ? 1.03 : 1.0)

                        RowLayout {
                            id: swatchRow
                            anchors.centerIn: parent
                            spacing: 6

                            Rectangle {
                                implicitWidth: 16
                                implicitHeight: 16
                                radius: 8
                                color: swatchPill.modelData.color
                                border.color: Qt.alpha(root.textColor, 0.2)
                                border.width: 1
                            }

                            Text {
                                text: swatchPill.modelData.name + " "
                                font.family: "Google Sans"
                                font.pixelSize: 10
                                font.bold: true
                                color: root.textColor
                            }

                            Text {
                                text: swatchPill.hexStr.toUpperCase()
                                font.family: "GeistMono Nerd Font Propo"
                                font.pixelSize: 9
                                color: root.textMuted
                            }
                        }

                        MouseArea {
                            id: swatchMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.clipboardText = swatchPill.hexStr;
                                root.showToast(qsTr("Copied %1 (%2)").arg(swatchPill.modelData.name).arg(swatchPill.hexStr), "content_copy");
                            }
                        }
                    }
                }
            }
        }

    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 92
        radius: 14
        color: root.surface

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: qsTr("Primary Accent Color:")
                    font.family: "Google Sans"
                    font.pixelSize: 11
                    font.bold: true
                    color: root.textColor
                    Layout.fillWidth: true
                }

                Text {
                    text: (Colors.primarySlot || "base0D").toUpperCase()
                    font.family: "Google Sans"
                    font.pixelSize: 10
                    font.bold: true
                    color: root.color1
                }

                SettingButton {
                    icon: "restart_alt"
                    text: qsTr("Default")
                    variant: "secondary"
                    compact: true
                    onClicked: Colors.setPrimarySlot("base0D")
                }

            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Repeater {
                    model: ["base0D", "base0E", "base0C", "base0B", "base0A", "base09", "base08", "base0F"]

                    delegate: Rectangle {
                        id: slotItem

                        required property string modelData

                        implicitWidth: 32
                        implicitHeight: 32
                        radius: 16
                        color: (Colors.cfg && Colors.cfg[modelData]) ? Colors.cfg[modelData] : "#89b4fa"
                        border.color: (Colors.primarySlot === modelData) ? "#ffffff" : (slotH.hovered ? Qt.alpha("#ffffff", 0.5) : "transparent")
                        border.width: (Colors.primarySlot === modelData) ? 3 : 1
                        scale: slotH.hovered ? 1.15 : 1

                        Text {
                            anchors.centerIn: parent
                            visible: Colors.primarySlot === slotItem.modelData
                            text: "check"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 14
                            font.bold: true
                            color: "#ffffff"
                        }

                        HoverHandler {
                            id: slotH
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Colors.setPrimarySlot(slotItem.modelData)
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 100
                            }

                        }

                    }

                }

            }

        }

    }

    ColumnLayout {
        property bool isExpanded: true

        Layout.fillWidth: true
        spacing: 12

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            radius: 12
            color: headerMa.containsMouse ? root.surfaceContainer : "transparent"
            border.color: Qt.alpha(root.textColor, 0.05)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Text {
                    text: "palette"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 18
                    color: root.color1
                }

                Text {
                    text: qsTr("Base16 Palettes")
                    font.family: "Google Sans"
                    font.pixelSize: 13
                    font.bold: true
                    color: root.textColor
                    Layout.fillWidth: true
                }

                Text {
                    text: parent.parent.parent.isExpanded ? "expand_more" : "chevron_right"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 20
                    color: root.textMuted
                }

            }

            MouseArea {
                id: headerMa

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: parent.parent.isExpanded = !parent.parent.isExpanded
            }

        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12
            visible: parent.isExpanded

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 12
                color: root.surface

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    Text {
                        text: "search"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 18
                        color: root.color1
                    }

                    TextInput {
                        id: searchField

                        Layout.fillWidth: true
                        font.family: "Google Sans"
                        font.pixelSize: 11
                        color: root.textColor
                        clip: true
                        onTextChanged: root.paletteSearchQuery = text

                        Text {
                            text: qsTr("Search Base16 palettes")
                            font.family: "Google Sans"
                            font.pixelSize: 11
                            color: root.textMuted
                            visible: searchField.text === ""
                        }

                    }

                    Rectangle {
                        implicitWidth: 20
                        implicitHeight: 20
                        radius: 10
                        color: clearSearchH.hovered ? root.surfaceContainer : "transparent"
                        visible: root.paletteSearchQuery !== ""

                        Text {
                            anchors.centerIn: parent
                            text: "close"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 14
                            color: root.textMuted
                        }

                        HoverHandler {
                            id: clearSearchH
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchField.text = "";
                                root.paletteSearchQuery = "";
                            }
                        }

                    }

                }

            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: Colors.availableCategories

                    delegate: Rectangle {
                        id: catPill

                        required property string modelData
                        readonly property bool isSelected: root.selectedCategory === modelData

                        implicitHeight: 28
                        implicitWidth: catLabel.implicitWidth + 20
                        radius: 14
                        color: isSelected ? root.color1 : (catMa.containsMouse ? root.surfaceContainer : root.surface)
                        border.color: isSelected ? root.color1 : Qt.alpha(root.textColor, 0.1)
                        border.width: 1
                        scale: catMa.pressed ? 0.95 : 1

                        Text {
                            id: catLabel

                            anchors.centerIn: parent
                            text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                            font.family: "Google Sans"
                            font.pixelSize: 10
                            font.bold: catPill.isSelected
                            color: catPill.isSelected ? root.foreground : (catMa.containsMouse ? root.textBright : root.textColor)

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }

                            }

                        }

                        MouseArea {
                            id: catMa

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedCategory = modelData
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }

                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutQuint
                            }

                        }

                    }

                }

            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                radius: 12
                color: root.surface
                visible: root.displayedPalettes.length === 0

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "search"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 24
                        color: root.textMuted
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: qsTr("No palettes found matching your search.")
                        font.family: "Google Sans"
                        font.pixelSize: 11
                        color: root.textMuted
                        Layout.alignment: Qt.AlignHCenter
                    }

                }

            }

            GridView {
                id: paletteGrid

                Layout.fillWidth: true
                Layout.preferredHeight: contentHeight
                interactive: false
                flickableDirection: Flickable.VerticalFlick
                clip: true
                cellWidth: Math.floor(width / 3)
                cellHeight: 74
                visible: root.visiblePalettes.length > 0
                model: root.visiblePalettes

                ScrollBar.vertical: ScrollBar {
                    active: true
                    policy: ScrollBar.AsNeeded
                }

                delegate: Rectangle {
                    id: palCard

                    required property var modelData
                    readonly property bool isCurrentTheme: Config.cfg.theme === modelData.id
                    readonly property bool isCardPinned: Colors.isPinned(modelData.id)

                    width: paletteGrid.cellWidth - 10
                    height: 64
                    radius: 12
                    color: isCurrentTheme ? Qt.alpha(modelData.color, 0.18) : root.surface
                    border.color: isCurrentTheme ? modelData.color : (palCardH.hovered ? Qt.alpha(modelData.color, 0.5) : Qt.alpha(root.textColor, 0.08))
                    border.width: isCurrentTheme ? 2 : 1

                    Row {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            anchors.verticalCenter: parent.verticalCenter
                            color: modelData.bg || "#1e1e2e"
                            border.color: modelData.color || "#89b4fa"
                            border.width: 2

                            Text {
                                anchors.centerIn: parent
                                text: "palette"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 16
                                color: modelData.color || "#89b4fa"
                            }

                        }

                        Column {
                            width: Math.max(40, parent.width - 32 - 26 - (palCard.isCurrentTheme ? 20 : 0) - (parent.spacing * 3))
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Text {
                                width: parent.width
                                text: modelData.name || modelData.id
                                font.family: "Google Sans"
                                font.pixelSize: 11
                                font.bold: true
                                color: root.textColor
                                elide: Text.ElideRight
                            }

                            Row {
                                spacing: 4

                                Rectangle {
                                    implicitWidth: badgeText.implicitWidth + 8
                                    implicitHeight: 14
                                    radius: 7
                                    color: modelData.type === "dark" ? Qt.alpha("#000000", 0.4) : Qt.alpha("#ffffff", 0.3)

                                    Text {
                                        id: badgeText

                                        anchors.centerIn: parent
                                        text: modelData.type === "dark" ? qsTr("Dark") : qsTr("Light")
                                        font.family: "Google Sans"
                                        font.pixelSize: 8
                                        font.bold: true
                                        color: root.textMuted
                                    }

                                }

                                Text {
                                    text: "• Base16"
                                    font.family: "Google Sans"
                                    font.pixelSize: 9
                                    color: root.textMuted
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                            }

                        }

                        Text {
                            visible: palCard.isCurrentTheme
                            anchors.verticalCenter: parent.verticalCenter
                            text: "✓"
                            font.family: "Google Sans"
                            font.pixelSize: 14
                            font.bold: true
                            color: modelData.color || root.color1
                        }

                        Rectangle {
                            width: 26
                            height: 26
                            radius: 13
                            anchors.verticalCenter: parent.verticalCenter
                            color: palCard.isCardPinned ? Qt.alpha(root.color1, 0.2) : (pinH.hovered ? root.surfaceContainer : "transparent")
                            border.color: palCard.isCardPinned ? Qt.alpha(root.color1, 0.5) : "transparent"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: palCard.isCardPinned ? "push_pin" : "push_pin"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 14
                                color: palCard.isCardPinned ? root.color1 : (pinH.hovered ? root.textColor : root.textMuted)
                            }

                            HoverHandler {
                                id: pinH
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Colors.togglePin(palCard.modelData.id)
                            }

                        }

                    }

                    HoverHandler {
                        id: palCardH
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        z: -1
                        onClicked: {
                            Config.cfg.theme = palCard.modelData.id;
                            Config.save();
                            Colors.loadPalette(palCard.modelData.id);
                            if (!Config.cfg.colorsAutoGenerate)
                                Colors.updateWallpaperMapping(Config.cfg.wallpaper, palCard.modelData.id, Config.cfg.isDarkMode);

                        }
                    }

                }

            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                radius: 12
                color: loadMoreH.hovered ? root.surfaceContainer : root.surface
                border.color: Qt.alpha(root.textColor, 0.08)
                visible: root.displayedPalettes.length > root.paletteDisplayLimit

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: "expand_more"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 18
                        color: root.color1
                    }

                    Text {
                        text: qsTr("Showing %1 of %2 palettes — click to load more").arg(root.paletteDisplayLimit).arg(root.displayedPalettes.length)
                        font.family: "Google Sans"
                        font.pixelSize: 11
                        font.bold: true
                        color: root.textColor
                    }

                }

                HoverHandler {
                    id: loadMoreH
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.paletteDisplayLimit += 36
                }

            }

        }

    }

}
