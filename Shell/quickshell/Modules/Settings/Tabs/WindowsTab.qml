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
    visible: root.currentTab === "windows"

    SettingSectionHeader {
        icon: "space_dashboard"
        title: qsTr("Window Styling & Layout")
        description: qsTr("Customize gaps, borders, corner rounding, shadows and tiling behavior")

        SettingButton {
            icon: "sync"
            text: qsTr("Sync")
            compact: true
            onClicked: WindowService.refresh()
        }
    }

    Rectangle {
        id: previewCard
        Layout.fillWidth: true
        Layout.preferredHeight: 220
        radius: 16
        color: root.surface
        border.color: Qt.alpha(root.borderCol, 0.3)
        border.width: 1
        clip: true

        property int focusedWindowId: 0
        property bool showSingleWindow: false

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                RowLayout {
                    spacing: 8
                    Layout.fillWidth: true

                    Text {
                        text: qsTr("Live Preview")
                        font.family: "Google Sans"
                        font.pixelSize: 11
                        font.bold: true
                        color: root.textColor
                    }

                    Text {
                        text: qsTr("• Click windows to switch focus")
                        font.family: "Google Sans"
                        font.pixelSize: 10
                        color: root.textMuted
                    }
                }

                Rectangle {
                    implicitWidth: singleWinToggleRow.implicitWidth + 12
                    implicitHeight: 20
                    radius: 10
                    color: previewCard.showSingleWindow ? Qt.alpha(root.color1, 0.22) : Qt.alpha(root.textColor, 0.08)
                    border.color: previewCard.showSingleWindow ? root.color1 : Qt.alpha(root.borderCol, 0.3)
                    border.width: 1

                    RowLayout {
                        id: singleWinToggleRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: previewCard.showSingleWindow ? "check_box_outline_blank" : "grid_view"
                            font.pixelSize: 13
                            font.family: "Material Symbols Rounded"
                            color: previewCard.showSingleWindow ? root.color1 : root.textMuted
                        }

                        Text {
                            text: previewCard.showSingleWindow ? qsTr("1 Window") : qsTr("Multi-Window")
                            font.family: "Google Sans"
                            font.pixelSize: 9
                            font.bold: true
                            color: previewCard.showSingleWindow ? root.color1 : root.textMuted
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: previewCard.showSingleWindow = !previewCard.showSingleWindow
                    }
                }

                Rectangle {
                    implicitWidth: layoutBadgeRow.implicitWidth + 12
                    implicitHeight: 20
                    radius: 10
                    color: Qt.alpha(root.color1, 0.15)
                    border.color: Qt.alpha(root.color1, 0.3)
                    border.width: 1

                    RowLayout {
                        id: layoutBadgeRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: {
                                if (WindowService.layoutMode === "master") return "view_sidebar";
                                if (WindowService.layoutMode === "scrolling") return "view_column";
                                return "grid_view";
                            }
                            font.pixelSize: 13
                            font.family: "Material Symbols Rounded"
                            color: root.color1
                        }

                        Text {
                            text: WindowService.layoutMode.toUpperCase()
                            font.family: "Google Sans"
                            font.pixelSize: 9
                            font.bold: true
                            color: root.color1
                        }
                    }
                }
            }

            Rectangle {
                id: screenMockup
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 10
                color: root.surfaceContainer
                border.color: Qt.alpha(root.borderCol, 0.25)
                border.width: 1
                clip: true

                readonly property real previewGapsIn: Math.max(0, WindowService.gapsIn * 0.4)
                readonly property real previewGapsOut: Math.max(0, WindowService.gapsOut * 0.4)
                readonly property real previewSingleGapsOut: Math.max(0, WindowService.singleWindowGapsOut * 0.4)
                readonly property real previewRounding: Math.max(0, WindowService.rounding * 0.4)
                readonly property real previewBorder: Math.max(0, WindowService.borderSize)
                readonly property real previewShadowRange: Math.max(1, WindowService.shadowRange * 0.35)

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.alpha(root.color1, 0.12) }
                        GradientStop { position: 1.0; color: Qt.alpha(root.surface, 0.95) }
                    }
                }

                Image {
                    id: screenWallpaper
                    anchors.fill: parent
                    source: (Config.cfg && Config.cfg.wallpaper) ? ("file://" + Config.cfg.wallpaper) : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: 0.4
                    visible: (Config.cfg && Config.cfg.wallpaper !== "")
                }

                Rectangle {
                    id: miniTopBar
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 14
                    color: Qt.alpha(root.surface, 0.8)
                    border.color: Qt.alpha(root.borderCol, 0.2)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8

                        Row {
                            spacing: 3
                            Rectangle { width: 4; height: 4; radius: 2; color: root.color1 }
                            Rectangle { width: 4; height: 4; radius: 2; color: Qt.alpha(root.textColor, 0.3) }
                            Rectangle { width: 4; height: 4; radius: 2; color: Qt.alpha(root.textColor, 0.3) }
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "12:00"
                            font.family: "GeistMono Nerd Font Propo"
                            font.pixelSize: 7
                            color: root.textMuted
                        }

                        Item { Layout.fillWidth: true }

                        Row {
                            spacing: 5
                            Text { text: "wifi"; font.family: "Material Symbols Rounded"; font.pixelSize: 8; color: root.textMuted }
                            Text { text: "volume_up"; font.family: "Material Symbols Rounded"; font.pixelSize: 8; color: root.textMuted }
                            Text { text: "battery_charging_full"; font.family: "Material Symbols Rounded"; font.pixelSize: 8; color: root.textMuted }
                        }
                    }
                }

                Item {
                    id: windowsArea
                    anchors.top: miniTopBar.bottom
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: previewCard.showSingleWindow ? screenMockup.previewSingleGapsOut : screenMockup.previewGapsOut

                    Behavior on anchors.margins {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }

                    WindowMockupItem {
                        anchors.fill: parent
                        root: tabRoot.root
                        screenMockup: screenMockup
                        previewCard: previewCard
                        windowId: 0
                        title: qsTr("Code")
                        icon: "code"
                        visible: previewCard.showSingleWindow
                    }

                    Item {
                        anchors.fill: parent
                        visible: !previewCard.showSingleWindow

                        RowLayout {
                            anchors.fill: parent
                            spacing: screenMockup.previewGapsIn
                            visible: WindowService.layoutMode === "master"

                            WindowMockupItem {
                                root: tabRoot.root
                                screenMockup: screenMockup
                                previewCard: previewCard
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredWidth: 1.2
                                windowId: 0
                                title: qsTr("Code")
                                icon: "code"
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredWidth: 0.8
                                spacing: screenMockup.previewGapsIn

                                WindowMockupItem {
                                    root: tabRoot.root
                                    screenMockup: screenMockup
                                    previewCard: previewCard
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    windowId: 1
                                    title: qsTr("Terminal")
                                    icon: "terminal"
                                }

                                WindowMockupItem {
                                    root: tabRoot.root
                                    screenMockup: screenMockup
                                    previewCard: previewCard
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    windowId: 2
                                    title: qsTr("Browser")
                                    icon: "language"
                                }
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            spacing: screenMockup.previewGapsIn
                            visible: WindowService.layoutMode !== "master" && WindowService.layoutMode !== "scrolling"

                            WindowMockupItem {
                                root: tabRoot.root
                                screenMockup: screenMockup
                                previewCard: previewCard
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredWidth: 1.0
                                windowId: 0
                                title: qsTr("Code")
                                icon: "code"
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredWidth: 1.0
                                spacing: screenMockup.previewGapsIn

                                WindowMockupItem {
                                    root: tabRoot.root
                                    screenMockup: screenMockup
                                    previewCard: previewCard
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredHeight: 1.0
                                    windowId: 1
                                    title: qsTr("Terminal")
                                    icon: "terminal"
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredHeight: 1.0
                                    spacing: screenMockup.previewGapsIn
                                    visible: WindowService.smartSplit

                                    WindowMockupItem {
                                        root: tabRoot.root
                                        screenMockup: screenMockup
                                        previewCard: previewCard
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        windowId: 2
                                        title: qsTr("Browser")
                                        icon: "language"
                                    }

                                    WindowMockupItem {
                                        root: tabRoot.root
                                        screenMockup: screenMockup
                                        previewCard: previewCard
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        windowId: 3
                                        title: qsTr("Files")
                                        icon: "folder"
                                    }
                                }

                                WindowMockupItem {
                                    root: tabRoot.root
                                    screenMockup: screenMockup
                                    previewCard: previewCard
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredHeight: 1.0
                                    windowId: 2
                                    title: qsTr("Browser")
                                    icon: "language"
                                    visible: !WindowService.smartSplit
                                }
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            spacing: screenMockup.previewGapsIn
                            visible: WindowService.layoutMode === "scrolling"

                            WindowMockupItem {
                                root: tabRoot.root
                                screenMockup: screenMockup
                                previewCard: previewCard
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredWidth: 0.65
                                windowId: 1
                                title: qsTr("Terminal")
                                icon: "terminal"
                            }

                            WindowMockupItem {
                                root: tabRoot.root
                                screenMockup: screenMockup
                                previewCard: previewCard
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredWidth: 1.3
                                windowId: 0
                                title: qsTr("Code")
                                icon: "code"
                            }

                            WindowMockupItem {
                                root: tabRoot.root
                                screenMockup: screenMockup
                                previewCard: previewCard
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredWidth: 0.65
                                windowId: 2
                                title: qsTr("Browser")
                                icon: "language"
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: gapsCol.implicitHeight + 28
        radius: 14
        color: root.surface
        border.color: Qt.alpha(root.borderCol, 0.25)
        border.width: 1

        ColumnLayout {
            id: gapsCol
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Text {
                text: qsTr("Gaps & Spacing")
                font.family: "Google Sans"
                font.pixelSize: 12
                font.bold: true
                color: root.textColor
            }

            SettingSlider {
                title: qsTr("Inner Gaps (between windows)")
                value: WindowService.gapsIn
                from: 0
                to: 32
                stepSize: 1
                unit: "px"
                onValueCommitted: (val) => WindowService.updateSetting("windowGapsIn", val)
                onValueModified: (val) => WindowService.updateSetting("windowGapsIn", val)
            }

            SettingPills {
                currentValue: WindowService.gapsIn
                model: [
                    { label: qsTr("0px None"), val: 0 },
                    { label: qsTr("4px Compact"), val: 4 },
                    { label: qsTr("8px Balanced"), val: 8 },
                    { label: qsTr("14px Spacious"), val: 14 }
                ]
                onSelected: (val) => WindowService.updateSetting("windowGapsIn", val)
            }

            SettingDivider {}

            SettingSlider {
                title: qsTr("Outer Gaps (screen edges)")
                value: WindowService.gapsOut
                from: 0
                to: 48
                stepSize: 1
                unit: "px"
                onValueCommitted: (val) => WindowService.updateSetting("windowGapsOut", val)
                onValueModified: (val) => WindowService.updateSetting("windowGapsOut", val)
            }

            SettingPills {
                currentValue: WindowService.gapsOut
                model: [
                    { label: qsTr("0px None"), val: 0 },
                    { label: qsTr("8px Standard"), val: 8 },
                    { label: qsTr("16px Wide"), val: 16 },
                    { label: qsTr("24px Floating"), val: 24 }
                ]
                onSelected: (val) => WindowService.updateSetting("windowGapsOut", val)
            }

            SettingDivider {}

            SettingSlider {
                title: qsTr("Single Window Outer Gaps (only one app open)")
                description: qsTr("Screen edge spacing applied when a single application is visible on workspace")
                value: WindowService.singleWindowGapsOut
                from: 0
                to: 48
                stepSize: 1
                unit: "px"
                onValueCommitted: (val) => WindowService.updateSetting("singleWindowGapsOut", val)
                onValueModified: (val) => WindowService.updateSetting("singleWindowGapsOut", val)
            }

            SettingPills {
                currentValue: WindowService.singleWindowGapsOut
                model: [
                    { label: qsTr("0px Fullscreen"), val: 0 },
                    { label: qsTr("8px Standard"), val: 8 },
                    { label: qsTr("16px Wide"), val: 16 },
                    { label: qsTr("24px Floating"), val: 24 }
                ]
                onSelected: (val) => WindowService.updateSetting("singleWindowGapsOut", val)
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: borderCol.implicitHeight + 28
        radius: 14
        color: root.surface
        border.color: Qt.alpha(root.borderCol, 0.25)
        border.width: 1

        ColumnLayout {
            id: borderCol
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Text {
                text: qsTr("Borders & Corners")
                font.family: "Google Sans"
                font.pixelSize: 12
                font.bold: true
                color: root.textColor
            }

            SettingSlider {
                title: qsTr("Border Thickness")
                value: WindowService.borderSize
                from: 0
                to: 8
                stepSize: 1
                unit: "px"
                onValueCommitted: (val) => WindowService.updateSetting("windowBorderSize", val)
                onValueModified: (val) => WindowService.updateSetting("windowBorderSize", val)
            }

            SettingPills {
                currentValue: WindowService.borderSize
                model: [
                    { label: qsTr("0px Off"), val: 0 },
                    { label: qsTr("1px Thin"), val: 1 },
                    { label: qsTr("2px Classic"), val: 2 },
                    { label: qsTr("4px Bold"), val: 4 }
                ]
                onSelected: (val) => WindowService.updateSetting("windowBorderSize", val)
            }

            SettingDivider {}

            SettingSlider {
                title: qsTr("Corner Rounding Radius")
                value: WindowService.rounding
                from: 0
                to: 32
                stepSize: 1
                unit: "px"
                onValueCommitted: (val) => WindowService.updateSetting("windowRounding", val)
                onValueModified: (val) => WindowService.updateSetting("windowRounding", val)
            }

            SettingPills {
                currentValue: WindowService.rounding
                model: [
                    { label: qsTr("0px Square"), val: 0 },
                    { label: qsTr("8px Subtle"), val: 8 },
                    { label: qsTr("15px Material"), val: 15 },
                    { label: qsTr("24px Deep"), val: 24 }
                ]
                onSelected: (val) => WindowService.updateSetting("windowRounding", val)
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: shCol.implicitHeight + 28
        radius: 14
        color: root.surface
        border.color: Qt.alpha(root.borderCol, 0.25)
        border.width: 1

        ColumnLayout {
            id: shCol
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            SettingToggle {
                title: qsTr("Window Drop Shadows")
                description: qsTr("Enables realistic elevation and depth behind windows")
                checked: WindowService.shadowEnabled
                onToggled: (newState) => WindowService.updateSetting("shadowEnabled", newState)
            }

            SettingSlider {
                visible: WindowService.shadowEnabled
                title: qsTr("Shadow Blur Radius")
                value: WindowService.shadowRange
                from: 0
                to: 60
                stepSize: 1
                unit: "px"
                onValueCommitted: (val) => WindowService.updateSetting("shadowRange", val)
                onValueModified: (val) => WindowService.updateSetting("shadowRange", val)
            }

            SettingDivider {}

            SettingSlider {
                title: qsTr("Active Window Opacity")
                value: WindowService.activeOpacity
                from: 0.4
                to: 1.0
                stepSize: 0.01
                customValueText: Math.round(WindowService.activeOpacity * 100) + "%"
                onValueCommitted: (val) => WindowService.updateSetting("activeOpacity", val)
                onValueModified: (val) => WindowService.updateSetting("activeOpacity", val)
            }

            SettingPills {
                currentValue: WindowService.activeOpacity
                model: [
                    { label: qsTr("100% Solid"), val: 1.0 },
                    { label: qsTr("95% Subtle Translucency"), val: 0.95 },
                    { label: qsTr("90% Glass"), val: 0.90 },
                    { label: qsTr("80% Deep Glass"), val: 0.80 }
                ]
                onSelected: (val) => WindowService.updateSetting("activeOpacity", val)
            }

            SettingDivider {}

            SettingSlider {
                title: qsTr("Inactive Window Opacity")
                value: WindowService.inactiveOpacity
                from: 0.4
                to: 1.0
                stepSize: 0.01
                customValueText: Math.round(WindowService.inactiveOpacity * 100) + "%"
                onValueCommitted: (val) => WindowService.updateSetting("inactiveOpacity", val)
                onValueModified: (val) => WindowService.updateSetting("inactiveOpacity", val)
            }

            SettingPills {
                currentValue: WindowService.inactiveOpacity
                model: [
                    { label: qsTr("100% Solid"), val: 1.0 },
                    { label: qsTr("92% Subtle Translucency"), val: 0.92 },
                    { label: qsTr("85% Glass"), val: 0.85 },
                    { label: qsTr("75% Deep Glass"), val: 0.75 }
                ]
                onSelected: (val) => WindowService.updateSetting("inactiveOpacity", val)
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: layoutCol.implicitHeight + 28
        radius: 14
        color: root.surface
        border.color: Qt.alpha(root.borderCol, 0.25)
        border.width: 1

        ColumnLayout {
            id: layoutCol
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            ColumnLayout {
                spacing: 2
                Text {
                    text: qsTr("Tiling Layout Mode")
                    font.family: "Google Sans"
                    font.pixelSize: 12
                    font.bold: true
                    color: root.textColor
                }

                Text {
                    text: qsTr("Determines how windows are arranged on screen")
                    font.family: "Google Sans"
                    font.pixelSize: 10
                    color: root.textMuted
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: [
                        { id: "dwindle", name: qsTr("Dwindle"), desc: qsTr("Dynamic spiral tree"), icon: "grid_view" },
                        { id: "master", name: qsTr("Master"), desc: qsTr("Master & stack columns"), icon: "view_sidebar" },
                        { id: "scrolling", name: qsTr("Scrolling"), desc: qsTr("PaperWM column strip"), icon: "view_column" }
                    ]

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 46
                        radius: 10
                        color: WindowService.layoutMode === modelData.id ? Qt.alpha(root.color1, 0.22) : root.surfaceContainer
                        border.color: WindowService.layoutMode === modelData.id ? root.color1 : Qt.alpha(root.borderCol, 0.25)
                        border.width: WindowService.layoutMode === modelData.id ? 2 : 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Text {
                                text: modelData.icon
                                font.pixelSize: 18
                                font.family: "Material Symbols Rounded"
                                color: WindowService.layoutMode === modelData.id ? root.color1 : root.textMuted
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    text: modelData.name
                                    font.family: "Google Sans"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: WindowService.layoutMode === modelData.id ? root.textBright : root.textColor
                                }

                                Text {
                                    text: modelData.desc
                                    font.family: "Google Sans"
                                    font.pixelSize: 8
                                    color: root.textMuted
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WindowService.updateSetting("layout", modelData.id)
                        }
                    }
                }
            }

            SettingToggle {
                title: qsTr("Smart Split")
                description: qsTr("Splits window based on cursor placement or aspect ratio")
                checked: WindowService.smartSplit
                onToggled: (newState) => WindowService.updateSetting("smartSplit", newState)
            }
        }
    }
}
