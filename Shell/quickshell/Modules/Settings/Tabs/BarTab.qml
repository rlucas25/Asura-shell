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
    spacing: 16
    visible: root.currentTab === "bar"

    SettingSectionHeader {
        id: sec1Header
        icon: "dock"
        title: qsTr("Bar Layout & Positioning")
        description: qsTr("Edge anchor, display mode, thickness, and desktop space")
        collapsible: true
        hint: qsTr("Position the bar on your display edge, adjust thickness, and configure desktop space reservations")
        targetContent: sec1Content
    }

    ColumnLayout {
        id: sec1Content
        Layout.fillWidth: true
        spacing: 12

        SettingCard {
            SettingPills {
                icon: "desktop_windows"
                title: qsTr("Screen Edge Position")
                hint: qsTr("Anchors the bar to top, bottom, left or right edge of your monitor")
                currentValue: Config.barPosition
                model: [
                    { id: "top", label: qsTr("Top (Default)"), icon: "arrow_upward" },
                    { id: "bottom", label: qsTr("Bottom"), icon: "arrow_downward" },
                    { id: "left", label: qsTr("Left"), icon: "arrow_back" },
                    { id: "right", label: qsTr("Right"), icon: "arrow_forward" }
                ]
                onSelected: (val) => {
                    Config.cfg.barPosition = val;
                    Config.save();
                }
            }

            SettingDivider {}

            SettingPills {
                icon: "dock"
                title: qsTr("Bar Display Style")
                hint: qsTr("Switch between single continuous bar, floating island or individual widget capsules")
                currentValue: Config.cfg ? Config.cfg.barMode : 1
                model: [
                    { id: 1, label: qsTr("Full Screen"), icon: "fullscreen" },
                    { id: 0, label: qsTr("Island"), icon: "crop_landscape" },
                    { id: 2, label: qsTr("Capsules"), icon: "view_column" }
                ]
                onSelected: (val) => {
                    Config.cfg.barMode = val;
                    Config.save();
                }
            }

            SettingDivider {}

            SettingSlider {
                title: qsTr("Bar Thickness")
                hint: qsTr("Controls overall bar thickness in pixels")
                from: 24
                to: 54
                stepSize: 2
                value: Config.effectiveBarThickness
                unit: "px"
                showReset: true
                resetValue: 36
                onValueModified: (val) => {
                    Config.cfg.barThickness = Math.round(val);
                    Config.saveDebounced(80);
                }
                onValueCommitted: (val) => {
                    Config.cfg.barThickness = Math.round(val);
                    Config.save();
                }
            }

            SettingDivider {}

            SettingSlider {
                title: qsTr("Bar Icon Scale")
                hint: qsTr("Scales widget glyphs and icons without altering the bar outer dimensions")
                from: 0.70
                to: 1.40
                stepSize: 0.05
                value: Config.effectiveBarIconScale
                customValueText: Math.round(Config.effectiveBarIconScale * 100) + "%"
                showReset: true
                resetValue: 1.0
                onValueModified: (val) => {
                    Config.cfg.barIconScale = Math.round(val * 100) / 100;
                    Config.saveDebounced(80);
                }
                onValueCommitted: (val) => {
                    Config.cfg.barIconScale = Math.round(val * 100) / 100;
                    Config.save();
                }
            }

            SettingDivider {
                visible: Config.cfg && Config.cfg.barMode === 0
            }

            SettingSlider {
                visible: Config.cfg && Config.cfg.barMode === 0
                title: qsTr("Island Width Proportion")
                hint: qsTr("Proportion of screen width occupied by the floating island")
                from: 0.40
                to: 1.00
                stepSize: 0.01
                value: (Config.cfg && Config.cfg.widthS !== undefined) ? Config.cfg.widthS : 0.85
                customValueText: Math.round(((Config.cfg && Config.cfg.widthS !== undefined) ? Config.cfg.widthS : 0.85) * 100) + "%"
                showReset: true
                resetValue: 0.85
                onValueModified: (val) => {
                    Config.cfg.widthS = Math.round(val * 100) / 100;
                    Config.saveDebounced(80);
                }
                onValueCommitted: (val) => {
                    Config.cfg.widthS = Math.round(val * 100) / 100;
                    Config.save();
                }
            }
        }

        SettingRow {
            SettingCard {
                Layout.fillWidth: true
                SettingToggle {
                    icon: "desktop_windows"
                    title: qsTr("Exclusive Mode")
                    hint: qsTr("When enabled, windows will not cover the bar when maximized or tiled")
                    checked: Config.cfg ? Config.cfg.exclusiveMode : false
                    onToggled: (val) => {
                        Config.cfg.exclusiveMode = val;
                        Config.save();
                    }
                }
            }

            SettingCard {
                Layout.fillWidth: true
                SettingToggle {
                    icon: "visibility_off"
                    title: qsTr("Auto-Hide Bar")
                    hint: qsTr("Bar hides until you move your cursor to the anchored screen edge")
                    checked: Config.cfg ? Config.cfg.autoHide : false
                    onToggled: (val) => {
                        Config.cfg.autoHide = val;
                        Config.save();
                    }
                }
            }
        }
    }

    SettingSectionHeader {
        id: sec2Header
        icon: "rounded_corner"
        title: qsTr("Geometry & Spacing")
        description: qsTr("Corner curvature, outer margins, paddings, and widget gaps")
        collapsible: true
        hint: qsTr("Configure capsule corner rounding, screen edge gaps, and widget spacing")
        targetContent: sec2Content
    }

    ColumnLayout {
        id: sec2Content
        Layout.fillWidth: true
        spacing: 12

        SettingCard {
        SettingToggle {
            title: qsTr("Sync Bar Curvature with General Setting")
            checked: (Config.cfg && Config.cfg.barFollowsGeneralRadius !== undefined) ? Config.cfg.barFollowsGeneralRadius : true
            onToggled: (val) => {
                Config.cfg.barFollowsGeneralRadius = val;
                Config.save();
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12
            visible: Config.cfg && Config.cfg.barFollowsGeneralRadius !== undefined && !Config.cfg.barFollowsGeneralRadius

            SettingDivider {}

            SettingSlider {
                title: qsTr("Bar Capsule Corner Radius")
                from: 0
                to: 24
                stepSize: 1
                value: Config.effectiveBarCapsuleRadius
                unit: "px"
                showReset: true
                resetValue: 15
                onValueModified: (val) => {
                    Config.cfg.barCapsuleRadius = Math.round(val);
                    Config.saveDebounced(80);
                }
                onValueCommitted: (val) => {
                    Config.cfg.barCapsuleRadius = Math.round(val);
                    Config.save();
                }
            }

            SettingPills {
                currentValue: Config.effectiveBarCapsuleRadius
                model: [
                    { label: qsTr("Square"), val: 0 },
                    { label: qsTr("Subtle"), val: 6 },
                    { label: qsTr("Standard"), val: 15 },
                    { label: qsTr("Pill"), val: 24 }
                ]
                onSelected: (val) => {
                    Config.cfg.barCapsuleRadius = val;
                    Config.save();
                }
            }
        }
    }

    SettingCard {
        SettingSlider {
            title: qsTr("Bar Edge Spacing")
            from: 0
            to: 32
            stepSize: 1
            value: Config.effectiveBarEdgeSpacing
            unit: "px"
            showReset: true
            resetValue: 16
            onValueModified: (val) => {
                Config.cfg.barEdgeSpacing = Math.round(val);
                Config.saveDebounced(80);
            }
            onValueCommitted: (val) => {
                Config.cfg.barEdgeSpacing = Math.round(val);
                Config.save();
            }
        }

        SettingPills {
            currentValue: Config.effectiveBarEdgeSpacing
            model: [
                { label: qsTr("Flush"), val: 0 },
                { label: qsTr("Compact"), val: 6 },
                { label: qsTr("Standard"), val: 10 },
                { label: qsTr("Spacious"), val: 16 },
                { label: qsTr("Wide"), val: 24 }
            ]
            onSelected: (val) => {
                Config.cfg.barEdgeSpacing = val;
                Config.save();
            }
        }

        SettingDivider {}

        SettingSlider {
            title: qsTr("Capsule Corner Padding")
            from: 0
            to: 20
            stepSize: 1
            value: Config.effectiveBarCapsulePadding
            unit: "px"
            showReset: true
            resetValue: 6
            onValueModified: (val) => {
                Config.cfg.barCapsulePadding = Math.round(val);
                Config.saveDebounced(80);
            }
            onValueCommitted: (val) => {
                Config.cfg.barCapsulePadding = Math.round(val);
                Config.save();
            }
        }

        SettingPills {
            currentValue: Config.effectiveBarCapsulePadding
            model: [
                { label: qsTr("Flush"), val: 0 },
                { label: qsTr("Snug"), val: 4 },
                { label: qsTr("Standard"), val: 6 },
                { label: qsTr("Relaxed"), val: 10 },
                { label: qsTr("Padded"), val: 14 }
            ]
            onSelected: (val) => {
                Config.cfg.barCapsulePadding = val;
                Config.save();
            }
        }

        SettingDivider {}

        SettingSlider {
            title: qsTr("Bar Widget Spacing")
            from: 0
            to: 24
            stepSize: 1
            value: Config.effectiveBarWidgetSpacing
            unit: "px"
            showReset: true
            resetValue: 8
            onValueModified: (val) => {
                Config.cfg.barWidgetSpacing = Math.round(val);
                Config.saveDebounced(80);
            }
            onValueCommitted: (val) => {
                Config.cfg.barWidgetSpacing = Math.round(val);
                Config.save();
            }
        }

        SettingPills {
            currentValue: Config.effectiveBarWidgetSpacing
            model: [
                { label: qsTr("Flush"), val: 0 },
                { label: qsTr("Compact"), val: 2 },
                { label: qsTr("Standard"), val: 4 },
                { label: qsTr("Comfortable"), val: 8 },
                { label: qsTr("Spacious"), val: 12 },
                { label: qsTr("Wide"), val: 16 }
            ]
            onSelected: (val) => {
                Config.cfg.barWidgetSpacing = val;
                Config.save();
            }
        }

        SettingDivider {}

        SettingSlider {
            title: qsTr("Capsule Widget Spacing")
            from: 0
            to: 16
            stepSize: 1
            value: Config.effectiveBarCapsuleWidgetSpacing
            unit: "px"
            showReset: true
            resetValue: 4
            onValueModified: (val) => {
                Config.cfg.barCapsuleWidgetSpacing = Math.round(val);
                Config.saveDebounced(80);
            }
            onValueCommitted: (val) => {
                Config.cfg.barCapsuleWidgetSpacing = Math.round(val);
                Config.save();
            }
        }

        SettingPills {
            currentValue: Config.effectiveBarCapsuleWidgetSpacing
            model: [
                { label: qsTr("Flush"), val: 0 },
                { label: qsTr("Tight"), val: 2 },
                { label: qsTr("Standard"), val: 4 },
                { label: qsTr("Relaxed"), val: 6 },
                { label: qsTr("Spacious"), val: 8 }
            ]
            onSelected: (val) => {
                Config.cfg.barCapsuleWidgetSpacing = val;
                Config.save();
            }
        }
    }
    }

    SettingSectionHeader {
        id: sec3Header
        icon: "opacity"
        title: qsTr("Appearance & Visual Effects")
        description: qsTr("Translucency and organic edge fillets")
        collapsible: true
        hint: qsTr("Tune translucency, blur effects, and organic corner fillets")
        targetContent: sec3Content
    }

    ColumnLayout {
        id: sec3Content
        Layout.fillWidth: true
        spacing: 12

        SettingCard {
        SettingToggle {
            title: qsTr("Sync Bar with General Opacity")
            checked: (Config.cfg && Config.cfg.barFollowsGeneralOpacity !== undefined) ? Config.cfg.barFollowsGeneralOpacity : true
            onToggled: (val) => {
                Config.cfg.barFollowsGeneralOpacity = val;
                Config.save();
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12
            visible: Config.cfg && Config.cfg.barFollowsGeneralOpacity !== undefined && !Config.cfg.barFollowsGeneralOpacity

            SettingDivider {}

            SettingSlider {
                title: qsTr("Bar Background Opacity")
                from: 0.10
                to: 1.00
                stepSize: 0.01
                value: (Config.cfg && Config.cfg.opacity !== undefined) ? Config.cfg.opacity : 1.0
                customValueText: Math.round(((Config.cfg && Config.cfg.opacity !== undefined) ? Config.cfg.opacity : 1.0) * 100) + "%"
                showReset: true
                resetValue: 1.0
                onValueModified: (val) => {
                    Config.cfg.opacity = Math.round(val * 100) / 100;
                    Config.saveDebounced(80);
                }
                onValueCommitted: (val) => {
                    Config.cfg.opacity = Math.round(val * 100) / 100;
                    Config.save();
                }
            }
        }
    }

    SettingCard {
        SettingToggle {
            title: qsTr("Bar Edge Melt (Organic Fillet)")
            checked: (Config.cfg && Config.cfg.barMeltEnabled !== undefined) ? Config.cfg.barMeltEnabled : true
            onToggled: (val) => {
                Config.cfg.barMeltEnabled = val;
                Config.save();
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12
            visible: Config.cfg && (Config.cfg.barMeltEnabled === undefined || Config.cfg.barMeltEnabled)

            SettingDivider {}

            SettingSlider {
                title: qsTr("Melt Fillet Radius")
                from: 8
                to: 48
                stepSize: 1
                value: Config.effectiveBarMeltRadius
                unit: "px"
                showReset: true
                resetValue: 16
                onValueModified: (val) => {
                    Config.cfg.barMeltRadius = Math.round(val);
                    Config.saveDebounced(80);
                }
                onValueCommitted: (val) => {
                    Config.cfg.barMeltRadius = Math.round(val);
                    Config.save();
                }
            }

            SettingDivider {}

            SettingPills {
                title: qsTr("Melt Curve Profile")
                currentValue: Config.effectiveBarMeltStyle
                model: [
                    { id: "organic", label: qsTr("Organic (Liquid Bézier)") },
                    { id: "circular", label: qsTr("Circular (True Arc)") }
                ]
                onSelected: (val) => {
                    Config.cfg.barMeltStyle = val;
                    Config.save();
                }
            }
        }
    }
    }

    SettingSectionHeader {
        id: sec4Header
        icon: "widgets"
        title: qsTr("Bar Widgets & Capsules")
        description: qsTr("Capsule arrangement, zone placement, and widget catalog")
        collapsible: true
        hint: qsTr("Add, configure, and reorder widgets across the left, center, and right capsules")
        targetContent: sec4Content
    }

    ColumnLayout {
        id: sec4Content
        Layout.fillWidth: true
        spacing: 12

        SettingRow {
            SettingCard {
                Layout.fillWidth: true
                SettingToggle {
                    icon: "label"
                    title: qsTr("Hover Labels & Values")
                    hint: qsTr("Reveals descriptive names and numeric stats when mouse hovers over bar items")
                    checked: Config.barWidgetHoverTextEnabled
                    onToggled: (val) => {
                        Config.cfg.barWidgetHoverTextEnabled = val;
                        Config.save();
                    }
                }
            }

            SettingCard {
                Layout.fillWidth: true
                SettingToggle {
                    icon: "touch_app"
                    title: qsTr("Open Menus on Hover")
                    hint: qsTr("Opens Control Panel, Launcher, or widget popups simply by hovering them without clicking")
                    checked: Config.barHoverMenusEnabled
                    onToggled: (val) => {
                        Config.cfg.barHoverMenusEnabled = val;
                        Config.save();
                    }
                }
            }
        }

    Rectangle {
        Layout.fillWidth: true
        radius: 14
        color: root.surface
        border.color: root.borderCol
        border.width: 1
        implicitHeight: widgetManagerCol.implicitHeight + 28

        ColumnLayout {
            id: widgetManagerCol

            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: qsTr("Bar Widgets Management")
                        font.family: "Google Sans"
                        font.pixelSize: 13
                        font.bold: true
                        color: root.textColor
                    }

                    Text {
                        text: qsTr("Add, reorder, move between capsules, and customize icon visibility")
                        font.family: "Google Sans"
                        font.pixelSize: 10
                        color: root.textMuted
                    }

                }

                SettingButton {
                    text: qsTr("Reset Defaults")
                    icon: "restart_alt"
                    variant: "secondary"
                    compact: true
                    onClicked: {
                        BarWidgetService.resetToDefaults();
                    }
                }

                SettingButton {
                    text: root.showAddWidgetModal ? qsTr("Close") : qsTr("Add Widget")
                    icon: root.showAddWidgetModal ? "close" : "add"
                    variant: root.showAddWidgetModal ? "secondary" : "primary"
                    compact: true
                    onClicked: {
                        root.showAddWidgetModal = !root.showAddWidgetModal;
                    }
                }

            }

            Rectangle {
                visible: root.showAddWidgetModal
                Layout.fillWidth: true
                radius: 12
                color: root.surfaceContainer
                border.color: Qt.alpha(root.color1, 0.5)
                border.width: 1
                implicitHeight: addPanelContent.implicitHeight + 24

                ColumnLayout {
                    id: addPanelContent

                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: qsTr("Select Widget to Add")
                            font.family: "Google Sans"
                            font.pixelSize: 11
                            font.bold: true
                            color: root.textColor
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            text: qsTr("Target Zone:")
                            font.family: "Google Sans"
                            font.pixelSize: 10
                            font.bold: true
                            color: root.textMuted
                        }

                        SettingPills {
                            Layout.fillWidth: false
                            currentValue: root.selectedAddZone
                            model: [
                                { id: "left", label: qsTr("Left"), icon: "\uf7e5" },
                                { id: "center", label: qsTr("Center"), icon: "\ue00f" },
                                { id: "right", label: qsTr("Right"), icon: "\uf7e4" }
                            ]
                            onSelected: (val) => root.selectedAddZone = val
                        }

                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        RowLayout {
                            spacing: 6

                            Text {
                                text: "view_column"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 15
                                color: root.color1
                            }

                            Text {
                                text: qsTr("Status Capsule Widgets")
                                font.family: "Google Sans"
                                font.pixelSize: 10
                                font.bold: true
                                color: root.textColor
                            }

                            Text {
                                text: qsTr("(Groupable into pill capsules)")
                                font.family: "Google Sans"
                                font.pixelSize: 9
                                color: root.textMuted
                            }

                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: BarWidgetService.availableWidgets.filter((w) => {
                                    return w.category === "status_capsule";
                                })

                                delegate: Rectangle {
                                    implicitWidth: 155
                                    implicitHeight: 38
                                    radius: 8
                                    color: addStatusH.hovered ? Qt.alpha(root.color1, 0.2) : root.surface
                                    border.color: addStatusH.hovered ? root.color1 : root.borderCol
                                    border.width: 1

                                    HoverHandler {
                                        id: addStatusH
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        spacing: 8

                                        Rectangle {
                                            implicitWidth: 26
                                            implicitHeight: 26
                                            radius: 6
                                            color: Qt.alpha(root.color1, 0.15)

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.icon
                                                font.family: "Material Symbols Rounded"
                                                font.pixelSize: 15
                                                color: root.color1
                                            }

                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1

                                            Text {
                                                text: modelData.name
                                                font.family: "Google Sans"
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: root.textColor
                                            }

                                            Text {
                                                text: qsTr("+ Add Instance")
                                                font.family: "Google Sans"
                                                font.pixelSize: 8
                                                color: root.textMuted
                                            }

                                        }

                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            BarWidgetService.addWidget(root.selectedAddZone, modelData.type, "status_capsule");
                                        }
                                    }

                                }

                            }

                        }

                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        RowLayout {
                            spacing: 6

                            Text {
                                text: "widgets"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 15
                                color: root.color2
                            }

                            Text {
                                text: qsTr("General Icons")
                                font.family: "Google Sans"
                                font.pixelSize: 10
                                font.bold: true
                                color: root.textColor
                            }

                            Text {
                                text: qsTr("(Standard bar controls)")
                                font.family: "Google Sans"
                                font.pixelSize: 9
                                color: root.textMuted
                            }

                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: BarWidgetService.availableWidgets.filter((w) => {
                                    return w.category === "general_icons";
                                })

                                delegate: Rectangle {
                                    implicitWidth: 155
                                    implicitHeight: 38
                                    radius: 8
                                    color: addGenH.hovered ? Qt.alpha(root.color2, 0.2) : root.surface
                                    border.color: addGenH.hovered ? root.color2 : root.borderCol
                                    border.width: 1

                                    HoverHandler {
                                        id: addGenH
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        spacing: 8

                                        Rectangle {
                                            implicitWidth: 26
                                            implicitHeight: 26
                                            radius: 6
                                            color: Qt.alpha(root.color2, 0.15)

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.icon
                                                font.family: "Material Symbols Rounded"
                                                font.pixelSize: 15
                                                color: root.color2
                                            }

                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1

                                            Text {
                                                text: modelData.name
                                                font.family: "Google Sans"
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: root.textColor
                                            }

                                            Text {
                                                text: qsTr("+ Add Instance")
                                                font.family: "Google Sans"
                                                font.pixelSize: 8
                                                color: root.textMuted
                                            }

                                        }

                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            BarWidgetService.addWidget(root.selectedAddZone, modelData.type, "general_icons");
                                        }
                                    }

                                }

                            }

                        }

                    }

                }

            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ZoneWidgetsColumn {
                    id: leftZoneCol
                    zoneName: "left"
                    zoneTitle: qsTr("Left Capsule")
                    zoneIcon: "\uf7e5"
                    widgetsList: BarWidgetService.leftWidgets
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                }

                ZoneWidgetsColumn {
                    id: centerZoneCol
                    zoneName: "center"
                    zoneTitle: qsTr("Center Capsule")
                    zoneIcon: "\ue00f"
                    widgetsList: BarWidgetService.centerWidgets
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                }

                ZoneWidgetsColumn {
                    id: rightZoneCol
                    zoneName: "right"
                    zoneTitle: qsTr("Right Capsule")
                    zoneIcon: "\uf7e4"
                    widgetsList: BarWidgetService.rightWidgets
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                }

            }

        }

    }

    component ZoneWidgetsColumn: Rectangle {
        id: zwc

        required property string zoneName
        required property string zoneTitle
        required property string zoneIcon
        required property var widgetsList

        readonly property bool isDropTarget: root.isDraggingWidget && root.widgetDragHoverZone === zwc.zoneName

        radius: 12
        color: isDropTarget ? Qt.alpha(root.color1, 0.08) : root.surfaceContainer
        border.color: isDropTarget ? root.color1 : root.borderCol
        border.width: isDropTarget ? 2 : 1
        implicitHeight: columnLayout.implicitHeight + 24

        Component.onCompleted: {
            root.registerZoneCol(zwc.zoneName, zwc);
        }

        Component.onDestruction: {
            if (root && typeof root.registerZoneCol === "function") {
                root.registerZoneCol(zwc.zoneName, null);
            }
        }

        function calculateInsertIndex(localY) {
            if (!widgetsList || widgetsList.length === 0) return 0;
            var listY = localY - 42;
            if (listY <= 0) return 0;
            var rowPitch = 54;
            var idx = Math.floor((listY + rowPitch / 2) / rowPitch);
            return Math.max(0, Math.min(idx, widgetsList.length));
        }

        ColumnLayout {
            id: columnLayout

            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: zwc.zoneIcon
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 13
                    color: root.color1
                }

                Text {
                    text: zwc.zoneTitle
                    font.family: "Google Sans"
                    font.pixelSize: 12
                    font.bold: true
                    color: root.textColor
                }

                Rectangle {
                    implicitWidth: countBadge.implicitWidth + 8
                    implicitHeight: 18
                    radius: 9
                    color: Qt.alpha(root.color1, 0.2)

                    Text {
                        id: countBadge

                        anchors.centerIn: parent
                        text: (zwc.widgetsList ? zwc.widgetsList.length : 0).toString()
                        font.family: "Google Sans"
                        font.pixelSize: 9
                        font.bold: true
                        color: root.color1
                    }

                }

                Item {
                    Layout.fillWidth: true
                }

                Rectangle {
                    implicitWidth: 24
                    implicitHeight: 24
                    radius: 6
                    color: addZoneBtnH.hovered ? root.color1 : root.surface
                    border.color: root.borderCol
                    border.width: 1

                    HoverHandler {
                        id: addZoneBtnH
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "add"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 15
                        color: addZoneBtnH.hovered ? root.foreground : root.textColor
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedAddZone = zwc.zoneName;
                            root.showAddWidgetModal = true;
                        }
                    }

                }

            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: root.borderCol
            }

            Text {
                visible: !zwc.widgetsList || zwc.widgetsList.length === 0
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                text: (root.isDraggingWidget && root.widgetDragHoverZone === zwc.zoneName) ? qsTr("Drop widget here") : qsTr("No widgets. Click + to add.")
                font.family: "Google Sans"
                font.pixelSize: 10
                color: (root.isDraggingWidget && root.widgetDragHoverZone === zwc.zoneName) ? root.color1 : root.textMuted
            }

            Repeater {
                model: zwc.widgetsList

                delegate: ColumnLayout {
                    id: itemRowWrap
                    Layout.fillWidth: true
                    spacing: 3

                    required property var modelData
                    required property int index

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 3
                        radius: 1.5
                        color: root.color1
                        visible: root.isDraggingWidget && root.widgetDragHoverZone === zwc.zoneName && root.widgetDragHoverIndex === index
                    }

                    Rectangle {
                        id: itemCard

                        readonly property bool isCapsule: BarWidgetService.itemHasBackground(modelData)

                        Layout.fillWidth: true
                        implicitHeight: 46
                        radius: 8
                        color: modelData.visible !== false ? (isCapsule ? Qt.alpha(root.color1, 0.16) : root.surface) : (isCapsule ? Qt.alpha(root.color1, 0.08) : Qt.alpha(root.surface, 0.3))
                        border.color: cardDragMa.pressed ? root.color1 : (isCapsule ? Qt.alpha(root.color1, 0.75) : (itemCardH.hovered ? root.color1 : root.borderCol))
                        border.width: cardDragMa.pressed ? 2 : (isCapsule ? 1.5 : 1)
                        opacity: (root.isDraggingWidget && root.widgetDragData && root.widgetDragData.id === modelData.id) ? 0.35 : 1.0

                        HoverHandler {
                            id: itemCardH
                        }

                        MouseArea {
                            id: cardDragMa
                            anchors.fill: parent
                            z: 0
                            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                            preventStealing: true

                            onPressed: (mouse) => {
                                var glob = cardDragMa.mapToItem(root.windowRootItem, mouse.x, mouse.y);
                                var hasBg = BarWidgetService.itemHasBackground(modelData);
                                root.startWidgetDrag(
                                    zwc.zoneName,
                                    index,
                                    modelData.id,
                                    BarWidgetService.getWidgetInfo(modelData.type).name,
                                    BarWidgetService.getWidgetInfo(modelData.type).icon,
                                    hasBg,
                                    glob.x,
                                    glob.y
                                );
                            }

                            onPositionChanged: (mouse) => {
                                if (!root.isDraggingWidget) return;
                                var glob = cardDragMa.mapToItem(root.windowRootItem, mouse.x, mouse.y);
                                var foundZone = "";
                                var foundIdx = -1;
                                var zoneTargets = [
                                    { name: "left", col: (typeof leftZoneCol !== "undefined" ? leftZoneCol : root.registeredZones["left"]) },
                                    { name: "center", col: (typeof centerZoneCol !== "undefined" ? centerZoneCol : root.registeredZones["center"]) },
                                    { name: "right", col: (typeof rightZoneCol !== "undefined" ? rightZoneCol : root.registeredZones["right"]) }
                                ];
                                for (var i = 0; i < zoneTargets.length; i++) {
                                    var zt = zoneTargets[i];
                                    if (!zt.col) continue;
                                    var pt = cardDragMa.mapToItem(zt.col, mouse.x, mouse.y);
                                    if (pt.x >= -20 && pt.x <= zt.col.width + 20 && pt.y >= 0 && pt.y <= zt.col.height + 30) {
                                        foundZone = zt.name;
                                        foundIdx = zt.col.calculateInsertIndex(pt.y);
                                        break;
                                    }
                                }
                                root.updateWidgetDrag(glob.x, glob.y, foundZone, foundIdx);
                            }

                            onReleased: {
                                root.finishWidgetDrag();
                            }

                            onCanceled: {
                                root.cancelWidgetDrag();
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 6
                            z: 1

                            Rectangle {
                                z: 2
                                implicitWidth: 20
                                implicitHeight: 20
                                radius: 5
                                color: modelData.visible !== false ? root.color1 : root.surfaceContainer
                                border.color: modelData.visible !== false ? root.color1 : root.borderCol
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.visible !== false ? "check_box" : "check_box_outline_blank"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 16
                                    color: modelData.visible !== false ? root.foreground : root.textMuted
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        BarWidgetService.toggleVisibility(zwc.zoneName, modelData.id);
                                    }
                                }

                            }

                            Rectangle {
                                implicitWidth: 26
                                implicitHeight: 26
                                radius: 6
                                color: BarWidgetService.itemHasBackground(modelData) ? Qt.alpha(root.color1, 0.15) : Qt.alpha(root.color2, 0.15)

                                Text {
                                    anchors.centerIn: parent
                                    text: BarWidgetService.getWidgetInfo(modelData.type).icon
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 15
                                    color: BarWidgetService.itemHasBackground(modelData) ? root.color1 : root.color2
                                }

                            }

                            Text {
                                text: BarWidgetService.getWidgetInfo(modelData.type).name
                                font.family: "Google Sans"
                                font.pixelSize: 13
                                font.bold: true
                                color: modelData.visible !== false ? root.textColor : root.textMuted
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                verticalAlignment: Text.AlignVCenter
                            }

                            Rectangle {
                                id: widgetConfigBtn
                                z: 2
                                implicitWidth: 26
                                implicitHeight: 26
                                radius: 6
                                color: widgetConfigH.hovered ? Qt.alpha(root.color1, 0.25) : root.surfaceContainer
                                border.color: widgetConfigH.hovered ? root.color1 : root.borderCol
                                border.width: 1

                                HoverHandler {
                                    id: widgetConfigH
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "tune"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 15
                                    color: widgetConfigH.hovered ? root.color1 : root.textColor
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.openWidgetConfigModal(modelData, zwc.zoneName);
                                    }
                                }
                            }

                            Rectangle {
                                id: delBtn
                                z: 2
                                implicitWidth: 26
                                implicitHeight: 26
                                radius: 6
                                color: delBtnH.hovered ? Qt.alpha(Colors.cfg.error || "#ff5555", 0.25) : "transparent"
                                border.color: delBtnH.hovered ? (Colors.cfg.error || "#ff5555") : "transparent"
                                border.width: 1

                                HoverHandler {
                                    id: delBtnH
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "delete"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 15
                                    color: delBtnH.hovered ? (Colors.cfg.error || "#ff5555") : root.textMuted
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        BarWidgetService.removeWidget(zwc.zoneName, modelData.id);
                                    }
                                }
                            }

                        }

                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 3
                        radius: 1.5
                        color: root.color1
                        visible: root.isDraggingWidget && root.widgetDragHoverZone === zwc.zoneName && root.widgetDragHoverIndex === zwc.widgetsList.length && index === zwc.widgetsList.length - 1
                    }

                }

            }

        }

    }
    }

    SettingSectionHeader {
        id: visualizerHeader
        icon: "graphic_eq"
        title: qsTr("Bar Audio Visualizer (in test)")
        description: qsTr("Paints real-time audio spectrum across the bar background when music plays")
        collapsible: true
        hint: qsTr("Configure Cava audio visualizer styles, height, opacity, and band density")
        targetContent: visualizerContent
    }

    ColumnLayout {
        id: visualizerContent
        Layout.fillWidth: true
        spacing: 12

        SettingCard {
            SettingToggle {
                icon: "graphic_eq"
                title: qsTr("Bar Audio Visualizer (in test)")
                description: qsTr("Paints real-time audio spectrum across the bar background when music plays")
                checked: Config.cfg ? Config.cfg.barVisualizerEnabled : false
                onToggled: (val) => {
                    Config.cfg.barVisualizerEnabled = val;
                    Config.save();
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12
                visible: Config.cfg && Config.cfg.barVisualizerEnabled

                SettingDivider {}

                SettingPills {
                    title: qsTr("Visualizer Style")
                    currentValue: Config.cfg ? Config.cfg.barVisualizerType : "bars"
                    model: [
                        { id: "bars", label: qsTr("Bars (Dynamic bands)") },
                        { id: "wave", label: qsTr("Wave (Spline wave)") }
                    ]
                    onSelected: (val) => {
                        Config.cfg.barVisualizerType = val;
                        Config.save();
                    }
                }

                SettingPills {
                    title: qsTr("Spectrum Origin & Alignment")
                    currentValue: Config.cfg ? Config.cfg.barVisualizerBarsOrigin : "bottom"
                    model: [
                        { id: "bottom", label: qsTr("Bottom") },
                        { id: "center", label: qsTr("Center") },
                        { id: "mirror", label: qsTr("Mirrored") },
                        { id: "top", label: qsTr("Top") }
                    ]
                    onSelected: (val) => {
                        Config.cfg.barVisualizerBarsOrigin = val;
                        Config.save();
                    }
                }

                SettingSlider {
                    title: qsTr("Visualizer Height")
                    from: 0.10
                    to: 1.00
                    stepSize: 0.05
                    value: Config.cfg ? Config.cfg.barVisualizerHeight : 0.6
                    customValueText: Math.round((Config.cfg ? Config.cfg.barVisualizerHeight : 0.6) * 100) + "%"
                    onValueModified: (val) => {
                        Config.cfg.barVisualizerHeight = Math.round(val * 100) / 100;
                        Config.saveDebounced(80);
                    }
                    onValueCommitted: (val) => {
                        Config.cfg.barVisualizerHeight = Math.round(val * 100) / 100;
                        Config.save();
                    }
                }

                SettingSlider {
                    title: qsTr("Visualizer Opacity")
                    from: 0.05
                    to: 1.00
                    stepSize: 0.05
                    value: Config.cfg ? Config.cfg.barVisualizerOpacity : 0.8
                    customValueText: Math.round((Config.cfg ? Config.cfg.barVisualizerOpacity : 0.8) * 100) + "%"
                    onValueModified: (val) => {
                        Config.cfg.barVisualizerOpacity = Math.round(val * 100) / 100;
                        Config.saveDebounced(80);
                    }
                    onValueCommitted: (val) => {
                        Config.cfg.barVisualizerOpacity = Math.round(val * 100) / 100;
                        Config.save();
                    }
                }

                SettingSlider {
                    title: qsTr("Band Density / Step")
                    from: 4
                    to: 28
                    stepSize: 1
                    value: Config.cfg ? Config.cfg.barVisualizerDensity : 12
                    unit: "px"
                    onValueModified: (val) => {
                        Config.cfg.barVisualizerDensity = Math.round(val);
                        Config.saveDebounced(80);
                    }
                    onValueCommitted: (val) => {
                        Config.cfg.barVisualizerDensity = Math.round(val);
                        Config.save();
                    }
                }
            }
        }
    }
}

