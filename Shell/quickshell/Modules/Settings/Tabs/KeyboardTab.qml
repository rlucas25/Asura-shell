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
    id: keyboardTabCol

    required property var settingsRoot
    readonly property var root: settingsRoot
    Layout.fillWidth: true
    spacing: 16
    visible: root.currentTab === "keyboard"

    property string activeSubSection: "all"

    property bool showAddLayoutPopup: false
    property string searchQuery: ""
    property string testInputText: ""

    readonly property var switchShortcuts: [
        { "id": "grp:win_space_toggle", "name": "Super + Space", "desc": "Windows and macOS default switcher" },
        { "id": "grp:alt_shift_toggle", "name": "Alt + Shift", "desc": "Classic Windows and Linux switcher" },
        { "id": "grp:ctrl_shift_toggle", "name": "Ctrl + Shift", "desc": "Quick terminal-friendly toggle" },
        { "id": "grp:caps_toggle", "name": "Caps Lock", "desc": "Toggle layout with single Caps Lock press" },
        { "id": "grp:alt_space_toggle", "name": "Alt + Space", "desc": "Emacs & spotlight style shortcut" },
        { "id": "grp:shift_caps_toggle", "name": "Shift + Caps Lock", "desc": "Safe toggle preserving standard Caps Lock" }
    ]

    SettingSectionHeader {
        icon: "keyboard"
        title: qsTr("Mouse & Keyboard Configuration")
        description: qsTr("Fine-tune pointer tracking, acceleration, touchpad gestures, input layouts & typing parameters")
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 38
        radius: 10
        color: root.surfaceContainer
        border.color: Qt.alpha(root.borderCol, 0.3)
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 6

            Repeater {
                model: [
                    { "id": "all", "label": qsTr("All Settings"), "icon": "select_all" },
                    { "id": "mouse", "label": qsTr("Mouse & Pointer"), "icon": "mouse" },
                    { "id": "touchpad", "label": qsTr("Touchpad"), "icon": "touch_app" },
                    { "id": "keyboard", "label": qsTr("Keyboard & Layouts"), "icon": "keyboard" }
                ]

                Rectangle {
                    id: subPillItem
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 7
                    readonly property bool isSelected: keyboardTabCol.activeSubSection === modelData.id
                    color: isSelected ? root.color1 : (subPillH.hovered ? Qt.alpha(root.textColor, 0.07) : "transparent")

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: subPillItem.modelData.icon
                            font.pixelSize: 12
                            font.family: "Material Symbols Rounded"
                            color: subPillItem.isSelected ? root.foreground : root.textColor
                        }

                        Text {
                            text: subPillItem.modelData.label
                            font.family: "Google Sans"
                            font.pixelSize: 10
                            font.bold: subPillItem.isSelected
                            color: subPillItem.isSelected ? root.foreground : root.textColor
                        }
                    }

                    HoverHandler { id: subPillH }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: keyboardTabCol.activeSubSection = subPillItem.modelData.id
                    }
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 12
        visible: keyboardTabCol.activeSubSection === "all" || keyboardTabCol.activeSubSection === "mouse"

        SettingSectionHeader {
            icon: "mouse"
            title: qsTr("Mouse & Pointer Configuration")
            description: qsTr("Pointer tracking speed, acceleration curve, scroll multipliers, and button orientations")
        }

        SettingCard {
                SettingSlider {
                    title: qsTr("Pointer Speed (Sensitivity)")
                    description: qsTr("Controls pointer movement speed across all screens (-1.0 to +1.0, default: 0.0)")
                    from: -1.0
                    to: 1.0
                    stepSize: 0.05
                    value: KeyboardService.mouseSensitivity
                    showReset: true
                    resetValue: 0.0
                    customValueText: (KeyboardService.mouseSensitivity > 0 ? "+" : "") + KeyboardService.mouseSensitivity.toFixed(2)
                    onValueModified: (val) => KeyboardService.setMouseSensitivity(val)
                    onValueCommitted: (val) => KeyboardService.setMouseSensitivity(val)
                }

                SettingDivider {}

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: qsTr("Acceleration Profile")
                        font.family: "Google Sans"
                        font.pixelSize: 11
                        font.bold: true
                        color: root.textColor
                    }

                    Text {
                        text: qsTr("Determines if pointer tracking speed dynamically adapts to physical mouse motion speed")
                        font.family: "Google Sans"
                        font.pixelSize: 9
                        color: root.textMuted
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: [
                                { "id": "", "title": qsTr("Default"), "desc": qsTr("Standard system curve"), "icon": "tune" },
                                { "id": "flat", "title": qsTr("Flat (Raw 1:1)"), "desc": qsTr("Linear input, gaming precision"), "icon": "straighten" },
                                { "id": "adaptive", "title": qsTr("Adaptive"), "desc": qsTr("Scales up on rapid flicks"), "icon": "speed" }
                            ]

                            Rectangle {
                                id: accelChipItem
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 46
                                radius: 10
                                readonly property bool isSelected: KeyboardService.mouseAccelProfile === modelData.id
                                color: isSelected ? Qt.alpha(root.color1, 0.16) : root.surface
                                border.color: isSelected ? root.color1 : Qt.alpha(root.borderCol, 0.3)
                                border.width: isSelected ? 1.5 : 1

                                Behavior on color {
                                    ColorAnimation { duration: 120 }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 8

                                    Text {
                                        text: accelChipItem.modelData.icon
                                        font.pixelSize: 14
                                        font.family: "Material Symbols Rounded"
                                        color: accelChipItem.isSelected ? root.color1 : root.textMuted
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            text: accelChipItem.modelData.title
                                            font.family: "Google Sans"
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: accelChipItem.isSelected ? root.textBright : root.textColor
                                        }

                                        Text {
                                            text: accelChipItem.modelData.desc
                                            font.family: "Google Sans"
                                            font.pixelSize: 9
                                            color: root.textMuted
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Text {
                                        visible: accelChipItem.isSelected
                                        text: "check"
                                        font.pixelSize: 12
                                        font.family: "Material Symbols Rounded"
                                        color: root.color1
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: KeyboardService.setMouseAccelProfile(accelChipItem.modelData.id)
                                }
                            }
                        }
                    }
                }

                SettingDivider {}

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    SettingCard {
                        Layout.fillWidth: true
                        SettingToggle {
                            title: qsTr("Natural Scrolling")
                            description: qsTr("Invert mouse scroll wheel direction")
                            checked: KeyboardService.mouseNaturalScroll
                            onToggled: (newState) => KeyboardService.setMouseNaturalScroll(newState)
                        }
                    }

                    SettingCard {
                        Layout.fillWidth: true
                        SettingToggle {
                            title: qsTr("Left-Handed Mode")
                            description: qsTr("Swap primary left and right buttons")
                            checked: KeyboardService.mouseLeftHanded
                            onToggled: (newState) => KeyboardService.setMouseLeftHanded(newState)
                        }
                    }
                }

                SettingDivider {}

                SettingSlider {
                    title: qsTr("Mouse Scroll Multiplier")
                    description: qsTr("Speed multiplier for vertical mouse scroll wheel ticks (recommended: 1.0x)")
                    from: 0.2
                    to: 3.0
                    stepSize: 0.1
                    value: KeyboardService.mouseScrollFactor
                    showReset: true
                    resetValue: 1.0
                    customValueText: KeyboardService.mouseScrollFactor.toFixed(1) + "x"
                    onValueModified: (val) => KeyboardService.setMouseScrollFactor(val)
                    onValueCommitted: (val) => KeyboardService.setMouseScrollFactor(val)
                }

                SettingDivider {}

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: qsTr("Window Focus on Mouse Hover")
                        font.family: "Google Sans"
                        font.pixelSize: 11
                        font.bold: true
                        color: root.textColor
                    }

                    Text {
                        text: qsTr("Determines if hovering over a window transfers active focus immediately or requires a click")
                        font.family: "Google Sans"
                        font.pixelSize: 9
                        color: root.textMuted
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: [
                                { "id": 1, "title": qsTr("Follow Cursor"), "desc": qsTr("Focus switches upon hovering"), "icon": "mouse" },
                                { "id": 0, "title": qsTr("Click to Focus"), "desc": qsTr("Requires mouse click to focus"), "icon": "touch_app" },
                                { "id": 2, "title": qsTr("Detached"), "desc": qsTr("Hover focus with floating cursor"), "icon": "pan_tool" }
                            ]

                            Rectangle {
                                id: focusChipItem
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 46
                                radius: 10
                                readonly property bool isSelected: KeyboardService.mouseFollowFocus === modelData.id
                                color: isSelected ? Qt.alpha(root.color1, 0.16) : root.surface
                                border.color: isSelected ? root.color1 : Qt.alpha(root.borderCol, 0.3)
                                border.width: isSelected ? 1.5 : 1

                                Behavior on color { ColorAnimation { duration: 120 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 8

                                    Text {
                                        text: focusChipItem.modelData.icon
                                        font.pixelSize: 14
                                        font.family: "Material Symbols Rounded"
                                        color: focusChipItem.isSelected ? root.color1 : root.textMuted
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            text: focusChipItem.modelData.title
                                            font.family: "Google Sans"
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: focusChipItem.isSelected ? root.textBright : root.textColor
                                        }

                                        Text {
                                            text: focusChipItem.modelData.desc
                                            font.family: "Google Sans"
                                            font.pixelSize: 9
                                            color: root.textMuted
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Text {
                                        visible: focusChipItem.isSelected
                                        text: "check"
                                        font.pixelSize: 12
                                        font.family: "Material Symbols Rounded"
                                        color: root.color1
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: KeyboardService.setMouseFollowFocus(focusChipItem.modelData.id)
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Qt.alpha(root.borderCol, 0.2)
                }

                SettingToggle {
                    title: qsTr("Disable Cursor Warping")
                    description: qsTr("Prevents mouse cursor from snapping to newly focused windows on workspace switch")
                    checked: KeyboardService.cursorNoWarps
                    onToggled: (newState) => KeyboardService.setCursorNoWarps(newState)
                }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 12
        visible: keyboardTabCol.activeSubSection === "all" || keyboardTabCol.activeSubSection === "touchpad"

        SettingSectionHeader {
            icon: "touch_app"
            title: qsTr("Touchpad Configuration")
            description: qsTr("Two-finger gestures, tap clicking, scroll multipliers, and palm rejection typing protection")
        }

        SettingCard {
            SettingToggle {
                    title: qsTr("Touchpad Natural Scrolling")
                    description: qsTr("Invert two-finger swipe direction to track content motion")
                    checked: KeyboardService.touchpadNaturalScroll
                    onToggled: (newState) => KeyboardService.setTouchpadNaturalScroll(newState)
                }

                SettingDivider {}

                SettingToggle {
                    title: qsTr("Disable While Typing")
                    description: qsTr("Temporarily ignore touchpad movements and taps during active keyboard typing")
                    checked: KeyboardService.touchpadDisableWhileTyping
                    onToggled: (newState) => KeyboardService.setTouchpadDisableWhileTyping(newState)
                }

                SettingDivider {}

                SettingToggle {
                    title: qsTr("Tap to Click")
                    description: qsTr("Tap surface with 1 finger for left click, 2 fingers for right click")
                    checked: KeyboardService.touchpadTapToClick
                    onToggled: (newState) => KeyboardService.setTouchpadTapToClick(newState)
                }

                SettingDivider {}

                SettingSlider {
                    title: qsTr("Touchpad Scroll Speed")
                    description: qsTr("Velocity multiplier for two-finger gesture scrolling (recommended: 0.5x)")
                    from: 0.1
                    to: 2.0
                    stepSize: 0.1
                    value: KeyboardService.touchpadScrollFactor
                    showReset: true
                    resetValue: 0.5
                    customValueText: KeyboardService.touchpadScrollFactor.toFixed(1) + "x"
                    onValueModified: (val) => KeyboardService.setTouchpadScrollFactor(val)
                    onValueCommitted: (val) => KeyboardService.setTouchpadScrollFactor(val)
                }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 12
        visible: keyboardTabCol.activeSubSection === "all" || keyboardTabCol.activeSubSection === "keyboard"

        SettingSectionHeader {
            icon: "keyboard"
            title: qsTr("Active Layouts")
            description: qsTr("Ordered by priority. The topmost layout (#1) is your primary default in Hyprland.")

            SettingButton {
                icon: keyboardTabCol.showAddLayoutPopup ? "close" : "add"
                text: keyboardTabCol.showAddLayoutPopup ? qsTr("Close") : qsTr("Add Layout")
                variant: keyboardTabCol.showAddLayoutPopup ? "secondary" : "primary"
                onClicked: {
                    keyboardTabCol.showAddLayoutPopup = !keyboardTabCol.showAddLayoutPopup;
                    if (keyboardTabCol.showAddLayoutPopup) {
                        keyboardTabCol.searchQuery = "";
                    }
                }
            }
        }

        Rectangle {
            id: addLayoutPopupCard
            visible: keyboardTabCol.showAddLayoutPopup
            Layout.fillWidth: true
            radius: 14
            color: root.surfaceContainer
            border.color: Qt.alpha(root.color1, 0.45)
            border.width: 1.5
            implicitHeight: keyboardTabCol.showAddLayoutPopup ? (popupContentCol.implicitHeight + 24) : 0
            opacity: keyboardTabCol.showAddLayoutPopup ? 1.0 : 0.0
            clip: true

            Behavior on implicitHeight {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }
            Behavior on opacity {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            ColumnLayout {
                id: popupContentCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "search"
                        font.pixelSize: 14
                        font.family: "Material Symbols Rounded"
                        color: root.color1
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        radius: 8
                        color: root.surface
                        border.color: searchInput.activeFocus ? root.color1 : Qt.alpha(root.borderCol, 0.4)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true
                                text: keyboardTabCol.searchQuery
                                color: root.textBright
                                font.family: "Google Sans"
                                font.pixelSize: 12
                                selectByMouse: true
                                verticalAlignment: TextInput.AlignVCenter
                                onTextChanged: keyboardTabCol.searchQuery = text

                                Text {
                                    visible: !searchInput.text && !searchInput.activeFocus
                                    text: qsTr("Search layouts by language, code, or country (e.g. Portuguese, br, us, French)...")
                                    color: root.textMuted
                                    font.family: "Google Sans"
                                    font.pixelSize: 11
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Rectangle {
                                visible: searchInput.text !== ""
                                implicitWidth: 18
                                implicitHeight: 18
                                radius: 9
                                color: Qt.alpha(root.textColor, 0.1)

                                Text {
                                    anchors.centerIn: parent
                                    text: "close"
                                    font.pixelSize: 10
                                    font.family: "Material Symbols Rounded"
                                    color: root.textMuted
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        searchInput.text = "";
                                        keyboardTabCol.searchQuery = "";
                                    }
                                }
                            }
                        }
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    implicitHeight: Math.min(260, popupListCol.implicitHeight)
                    contentHeight: popupListCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: popupListCol
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: {
                                var q = keyboardTabCol.searchQuery.toLowerCase().trim();
                                var list = KeyboardService.allAvailableLayouts || [];
                                if (!q) return list;
                                return list.filter(function(item) {
                                    return (item.name && item.name.toLowerCase().indexOf(q) !== -1) ||
                                           (item.code && item.code.toLowerCase().indexOf(q) !== -1);
                                });
                            }

                            Rectangle {
                                id: popupRowDelegate
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                implicitHeight: 40
                                radius: 8
                                readonly property bool isAdded: KeyboardService.isLayoutActive(modelData.code)
                                color: popupRowH.hovered ? (isAdded ? Qt.alpha(root.borderCol, 0.15) : Qt.alpha(root.color1, 0.18)) : (isAdded ? Qt.alpha(root.surface, 0.4) : root.surface)
                                border.color: isAdded ? Qt.alpha(root.borderCol, 0.25) : (popupRowH.hovered ? Qt.alpha(root.color1, 0.4) : Qt.alpha(root.borderCol, 0.3))
                                border.width: 1

                                HoverHandler { id: popupRowH }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 10

                                    Text {
                                        text: popupRowDelegate.modelData.flag || "🌐"
                                        font.pixelSize: 16
                                    }

                                    Rectangle {
                                        implicitWidth: 32
                                        implicitHeight: 20
                                        radius: 4
                                        color: Qt.alpha(root.color1, 0.15)
                                        border.color: Qt.alpha(root.color1, 0.3)
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: popupRowDelegate.modelData.code.toUpperCase()
                                            font.pixelSize: 10
                                            font.bold: true
                                            font.family: "Google Sans"
                                            color: root.color1
                                        }
                                    }

                                    Text {
                                        text: popupRowDelegate.modelData.name || popupRowDelegate.modelData.code
                                        font.family: "Google Sans"
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: popupRowDelegate.isAdded ? root.textMuted : root.textBright
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        implicitWidth: 78
                                        implicitHeight: 24
                                        radius: 6
                                        color: popupRowDelegate.isAdded ? "transparent" : (addBtnH.hovered ? root.color1 : Qt.alpha(root.color1, 0.2))
                                        border.color: popupRowDelegate.isAdded ? Qt.alpha(root.borderCol, 0.4) : root.color1
                                        border.width: 1

                                        HoverHandler { id: addBtnH }

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 4

                                            Text {
                                                text: popupRowDelegate.isAdded ? "check" : "add"
                                                font.pixelSize: 10
                                                font.family: "Material Symbols Rounded"
                                                color: popupRowDelegate.isAdded ? root.textMuted : (addBtnH.hovered ? root.foreground : root.color1)
                                            }

                                            Text {
                                                text: popupRowDelegate.isAdded ? qsTr("Added") : qsTr("Add")
                                                font.family: "Google Sans"
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: popupRowDelegate.isAdded ? root.textMuted : (addBtnH.hovered ? root.foreground : root.color1)
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: popupRowDelegate.isAdded ? Qt.ArrowCursor : Qt.PointingHandCursor
                                            enabled: !popupRowDelegate.isAdded
                                            onClicked: {
                                                KeyboardService.addLayout(popupRowDelegate.modelData.code);
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    z: -1
                                    cursorShape: popupRowDelegate.isAdded ? Qt.ArrowCursor : Qt.PointingHandCursor
                                    enabled: !popupRowDelegate.isAdded
                                    onClicked: {
                                        KeyboardService.addLayout(popupRowDelegate.modelData.code);
                                    }
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

            Repeater {
                model: KeyboardService.activeLayouts

                Rectangle {
                    id: layoutCard
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: 52
                    radius: 12
                    readonly property bool isPrimary: index === 0
                    readonly property int totalCount: KeyboardService.activeLayouts.length
                    readonly property string layoutName: KeyboardService.getLayoutName(modelData)
                    readonly property string layoutFlag: KeyboardService.getLayoutFlag(modelData)

                    color: isPrimary ? Qt.alpha(root.color1, 0.12) : root.surfaceContainer
                    border.color: isPrimary ? root.color1 : Qt.alpha(root.borderCol, 0.35)
                    border.width: isPrimary ? 1.5 : 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Rectangle {
                            implicitWidth: 26
                            implicitHeight: 26
                            radius: 13
                            color: layoutCard.isPrimary ? root.color1 : root.surface
                            border.color: layoutCard.isPrimary ? root.color1 : Qt.alpha(root.borderCol, 0.4)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "#" + (layoutCard.index + 1)
                                font.family: "Google Sans"
                                font.pixelSize: 10
                                font.bold: true
                                color: layoutCard.isPrimary ? root.foreground : root.textMuted
                            }
                        }

                        Text {
                            text: layoutCard.layoutFlag
                            font.pixelSize: 18
                        }

                        Rectangle {
                            implicitWidth: 36
                            implicitHeight: 22
                            radius: 5
                            color: layoutCard.isPrimary ? Qt.alpha(root.color1, 0.25) : root.surface
                            border.color: layoutCard.isPrimary ? root.color1 : Qt.alpha(root.borderCol, 0.4)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: layoutCard.modelData.toUpperCase()
                                font.pixelSize: 10
                                font.bold: true
                                font.family: "Google Sans"
                                color: layoutCard.isPrimary ? root.color1 : root.textColor
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            RowLayout {
                                spacing: 6

                                Text {
                                    text: layoutCard.layoutName
                                    font.family: "Google Sans"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: root.textBright
                                }

                                Rectangle {
                                    visible: layoutCard.isPrimary
                                    implicitWidth: 62
                                    implicitHeight: 18
                                    radius: 9
                                    color: root.color1

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 3

                                        Text {
                                            text: "check"
                                            font.pixelSize: 9
                                            font.family: "Material Symbols Rounded"
                                            color: root.foreground
                                        }

                                        Text {
                                            text: qsTr("PRIMARY")
                                            font.family: "Google Sans"
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: root.foreground
                                        }
                                    }
                                }
                            }

                            Text {
                                text: layoutCard.isPrimary
                                    ? qsTr("Hyprland default active layout upon startup & window resets")
                                    : qsTr("Alternative layout — switchable dynamically with keyboard shortcut")
                                font.family: "Google Sans"
                                font.pixelSize: 9
                                color: root.textMuted
                            }
                        }

                        RowLayout {
                            spacing: 6

                            Rectangle {
                                visible: !layoutCard.isPrimary
                                implicitWidth: 88
                                implicitHeight: 28
                                radius: 6
                                color: makePrimH.hovered ? Qt.alpha(root.color1, 0.25) : root.surface
                                border.color: makePrimH.hovered ? root.color1 : Qt.alpha(root.borderCol, 0.4)
                                border.width: 1

                                HoverHandler { id: makePrimH }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        text: "star"
                                        font.pixelSize: 10
                                        font.family: "Material Symbols Rounded"
                                        color: root.color1
                                    }

                                    Text {
                                        text: qsTr("Set Primary")
                                        font.family: "Google Sans"
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: root.textColor
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: KeyboardService.makePrimary(layoutCard.modelData)
                                }
                            }

                            Rectangle {
                                visible: layoutCard.index > 0
                                implicitWidth: 28
                                implicitHeight: 28
                                radius: 6
                                color: moveUpH.hovered ? Qt.alpha(root.color1, 0.25) : root.surface
                                border.color: moveUpH.hovered ? root.color1 : Qt.alpha(root.borderCol, 0.4)
                                border.width: 1

                            HoverHandler { id: moveUpH }

                                Text {
                                    anchors.centerIn: parent
                                    text: "arrow_upward"
                                    font.pixelSize: 12
                                    font.family: "Material Symbols Rounded"
                                    color: moveUpH.hovered ? root.color1 : root.textColor
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: KeyboardService.moveUp(layoutCard.index)
                                }
                            }

                            Rectangle {
                                visible: layoutCard.index < layoutCard.totalCount - 1
                                implicitWidth: 28
                                implicitHeight: 28
                                radius: 6
                                color: moveDownH.hovered ? Qt.alpha(root.color1, 0.25) : root.surface
                                border.color: moveDownH.hovered ? root.color1 : Qt.alpha(root.borderCol, 0.4)
                                border.width: 1

                                HoverHandler { id: moveDownH }

                                Text {
                                    anchors.centerIn: parent
                                    text: "arrow_downward"
                                    font.pixelSize: 12
                                    font.family: "Material Symbols Rounded"
                                    color: moveDownH.hovered ? root.color1 : root.textColor
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: KeyboardService.moveDown(layoutCard.index)
                                }
                            }

                            Rectangle {
                                visible: layoutCard.totalCount > 1
                                implicitWidth: 28
                                implicitHeight: 28
                                radius: 6
                                color: removeH.hovered ? Qt.alpha(Colors.cfg.error || "#ff5555", 0.2) : root.surface
                                border.color: removeH.hovered ? (Colors.cfg.error || "#ff5555") : Qt.alpha(root.borderCol, 0.4)
                                border.width: 1

                                HoverHandler { id: removeH }

                                Text {
                                    anchors.centerIn: parent
                                    text: "delete"
                                    font.pixelSize: 11
                                    font.family: "Material Symbols Rounded"
                                    color: removeH.hovered ? (Colors.cfg.error || "#ff5555") : root.textMuted
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: KeyboardService.removeLayout(layoutCard.modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 12
        visible: keyboardTabCol.activeSubSection === "all" || keyboardTabCol.activeSubSection === "keyboard"

        SettingSectionHeader {
            icon: "keyboard"
            title: qsTr("Layout Switching Shortcut")
            description: qsTr("Key combinations to quickly switch between configured layouts in Hyprland (kb_options)")
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 8
            columnSpacing: 8

            Repeater {
                model: keyboardTabCol.switchShortcuts

                Rectangle {
                    id: shortcutCard
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 52
                    radius: 10
                    readonly property bool isSelected: KeyboardService.kbOptions === modelData.id
                    color: isSelected ? Qt.alpha(root.color1, 0.16) : root.surfaceContainer
                    border.color: isSelected ? root.color1 : Qt.alpha(root.borderCol, 0.35)
                    border.width: isSelected ? 1.5 : 1

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Rectangle {
                            implicitWidth: 16
                            implicitHeight: 16
                            radius: 8
                            color: "transparent"
                            border.color: shortcutCard.isSelected ? root.color1 : Qt.alpha(root.textColor, 0.4)
                            border.width: 1.5

                            Rectangle {
                                anchors.centerIn: parent
                                width: 8
                                height: 8
                                radius: 4
                                color: root.color1
                                visible: shortcutCard.isSelected
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: shortcutCard.modelData.name
                                font.family: "Google Sans"
                                font.pixelSize: 11
                                font.bold: true
                                color: shortcutCard.isSelected ? root.textBright : root.textColor
                            }

                            Text {
                                text: shortcutCard.modelData.desc
                                font.family: "Google Sans"
                                font.pixelSize: 9
                                color: root.textMuted
                            }
                        }

                        Rectangle {
                            implicitWidth: 32
                            implicitHeight: 20
                            radius: 4
                            color: root.surface
                            border.color: Qt.alpha(root.borderCol, 0.3)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "keyboard"
                                font.pixelSize: 10
                                font.family: "Material Symbols Rounded"
                                color: shortcutCard.isSelected ? root.color1 : root.textMuted
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: KeyboardService.setKbOption(shortcutCard.modelData.id)
                    }
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 12
        visible: keyboardTabCol.activeSubSection === "all" || keyboardTabCol.activeSubSection === "keyboard"

        SettingSectionHeader {
            icon: "keyboard"
            title: qsTr("Typing & Repeat Parameters")
            description: qsTr("NumLock state, key repeat delay, repeat speed, and character generation rate")
        }

        SettingCard {
                SettingToggle {
                    title: qsTr("NumLock by Default")
                    description: qsTr("Automatically enable the numeric keypad NumLock state when Hyprland launches")
                    checked: KeyboardService.numlockByDefault
                    onToggled: (newState) => KeyboardService.setNumlock(newState)
                }

                SettingDivider {}

                SettingSlider {
                    title: qsTr("Key Repeat Delay")
                    description: qsTr("Time before a held key begins repeating (lower is faster, recommended: 250ms)")
                    from: 150
                    to: 600
                    stepSize: 10
                    value: KeyboardService.repeatDelay
                    unit: " ms"
                    onValueModified: (val) => KeyboardService.setRepeat(KeyboardService.repeatRate, Math.round(val))
                    onValueCommitted: (val) => KeyboardService.setRepeat(KeyboardService.repeatRate, Math.round(val))
                }

                SettingDivider {}

                SettingSlider {
                    title: qsTr("Key Repeat Rate")
                    description: qsTr("Speed of repeated key events per second while held down (recommended: 35 Hz)")
                    from: 15
                    to: 60
                    stepSize: 1
                    value: KeyboardService.repeatRate
                    unit: " Hz"
                    onValueModified: (val) => KeyboardService.setRepeat(Math.round(val), KeyboardService.repeatDelay)
                    onValueCommitted: (val) => KeyboardService.setRepeat(Math.round(val), KeyboardService.repeatDelay)
                }
        }

        Rectangle {
            Layout.fillWidth: true
            radius: 14
            color: root.surfaceContainer
            border.color: Qt.alpha(root.borderCol, 0.35)
            border.width: 1
            implicitHeight: testAreaCol.implicitHeight + 28

            ColumnLayout {
                id: testAreaCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        implicitWidth: liveIndicatorRow.implicitWidth + 14
                        implicitHeight: 26
                        radius: 7
                        color: Qt.alpha(root.color1, 0.18)
                        border.color: Qt.alpha(root.color1, 0.4)
                        border.width: 1

                        RowLayout {
                            id: liveIndicatorRow
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: KeyboardLayoutService.shortLayout || "EN"
                                font.pixelSize: 11
                                font.bold: true
                                font.family: "Google Sans"
                                color: root.color1
                            }

                            Text {
                                text: "•"
                                color: root.textMuted
                            }

                            Text {
                                text: KeyboardLayoutService.currentLayout || "Standard"
                                font.family: "Google Sans"
                                font.pixelSize: 10
                                color: root.textBright
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        implicitWidth: 120
                        implicitHeight: 26
                        radius: 7
                        color: switchBtnH.hovered ? root.color1 : Qt.alpha(root.color1, 0.15)
                        border.color: Qt.alpha(root.color1, 0.4)
                        border.width: 1

                        HoverHandler { id: switchBtnH }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: "sync"
                                font.pixelSize: 11
                                font.family: "Material Symbols Rounded"
                                color: switchBtnH.hovered ? root.foreground : root.color1
                            }

                            Text {
                                text: qsTr("Cycle Layout")
                                font.family: "Google Sans"
                                font.pixelSize: 10
                                font.bold: true
                                color: switchBtnH.hovered ? root.foreground : root.color1
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: KeyboardLayoutService.nextLayout()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 44
                    radius: 10
                    color: root.surface
                    border.color: testInput.activeFocus ? root.color1 : Qt.alpha(root.borderCol, 0.4)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        TextInput {
                            id: testInput
                            Layout.fillWidth: true
                            color: root.textBright
                            font.pixelSize: 13
                            font.family: "Google Sans"
                            selectByMouse: true
                            verticalAlignment: TextInput.AlignVCenter

                            Text {
                                visible: !testInput.text && !testInput.activeFocus
                                text: qsTr("Click here and type to test layout accents (e.g. ç, ~, á, ñ, @, /)...")
                                color: root.textMuted
                                font.family: "Google Sans"
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Rectangle {
                            visible: testInput.text !== ""
                            implicitWidth: 20
                            implicitHeight: 20
                            radius: 10
                            color: clearTestH.hovered ? Qt.alpha(Colors.cfg.error || "#ff5555", 0.2) : Qt.alpha(root.textColor, 0.1)

                            HoverHandler { id: clearTestH }

                            Text {
                                anchors.centerIn: parent
                                text: "close"
                                font.pixelSize: 10
                                font.family: "Material Symbols Rounded"
                                color: clearTestH.hovered ? (Colors.cfg.error || "#ff5555") : root.textMuted
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: testInput.text = ""
                            }
                        }
                    }
                }
            }
        }
    }
}
