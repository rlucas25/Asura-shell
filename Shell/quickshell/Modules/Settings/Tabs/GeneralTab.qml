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

    property var settingsRoot: null
    readonly property var root: settingsRoot ? settingsRoot : ({
        "color1": Colors.cfg.primary,
        "color2": Colors.cfg.secondary,
        "primary": Colors.cfg.primary,
        "secondary": Colors.cfg.secondary,
        "surface": Colors.cfg.surface,
        "surfaceContainer": Colors.cfg.base02,
        "borderCol": Colors.cfg.base03,
        "textMuted": Colors.cfg.base04,
        "textColor": Colors.cfg.base05,
        "textBright": Colors.cfg.base06,
        "foreground": Colors.cfg.on_primary,
        "currentTab": "general",
        "configDirPath": Quickshell.env("HOME") + "/.config/asura"
    })
    property var now: new Date()
    property string avatarReloadToken: ""
    readonly property string avatarSource: "file://" + Quickshell.env("HOME") + "/.face.icon" + (avatarReloadToken !== "" ? ("?t=" + avatarReloadToken) : "")

    Layout.fillWidth: true
    spacing: 16
    visible: root.currentTab === "general"

    Process {
        id: selectAvatarProc

        command: [
            "bash", "-c",
            "FILE=$(zenity --file-selection --title='Select Profile Picture' --file-filter='Images | *.jpg *.jpeg *.png *.webp *.bmp *.svg' 2>/dev/null); " +
            "if [ -n \"$FILE\" ] && [ -f \"$FILE\" ]; then " +
            "  cp -f \"$FILE\" \"$HOME/.face.icon\" && " +
            "  cp -f \"$FILE\" \"$HOME/.face\" && " +
            "  echo \"$FILE\"; " +
            "fi"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length > 0) {
                    tabRoot.avatarReloadToken = Date.now().toString();
                }
            }
        }
    }

    Timer {
        id: liveClockTimer

        interval: 1000
        running: root.visible && root.currentTab === "general"
        repeat: true
        onTriggered: tabRoot.now = new Date()
    }

    SettingSectionHeader {
        icon: "settings"
        title: qsTr("General Settings")
        description: qsTr("Interface opacity, blur, curvature geometry, and desktop paths")
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 8
        spacing: 10

        Rectangle {
            implicitWidth: 30
            implicitHeight: 30
            radius: 8
            color: Qt.alpha(root.color1, 0.15)
            border.color: Qt.alpha(root.color1, 0.3)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "wallpaper"
                font.pixelSize: 18
                font.family: "Material Symbols Rounded"
                color: root.color1
            }

        }

        ColumnLayout {
            spacing: 1

            Text {
                text: qsTr("Wallpaper & Desktop Background")
                font.family: "Google Sans"
                font.pixelSize: 13
                font.bold: true
                color: root.textBright
            }

            Text {
                text: qsTr("Select desktop wallpapers, customize folder directory, and configure transition animations")
                font.family: "Google Sans"
                font.pixelSize: 10
                color: root.textMuted
            }

        }

    }

    Item {
        id: wallpaperPreviewCard
        Layout.fillWidth: true
        Layout.preferredHeight: 180

        Rectangle {
            id: previewBackground
            anchors.fill: parent
            radius: 14
            color: root.surfaceContainer
            border.color: previewMouse.containsMouse ? root.color1 : Qt.alpha(root.textColor, 0.12)
            border.width: previewMouse.containsMouse ? 2 : 1
            clip: true
            scale: previewMouse.pressed ? 0.985 : (previewMouse.containsMouse ? 1.008 : 1.0)

            Behavior on scale {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }
            Behavior on border.color {
                ColorAnimation { duration: 180 }
            }

            Rectangle {
                anchors.fill: parent
                radius: 14
                color: root.surfaceContainer
                visible: wallpaperThumbnail.status !== Image.Ready

                Text {
                    anchors.centerIn: parent
                    text: "wallpaper"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 42
                    color: Qt.alpha(root.color1, 0.4)
                }
            }

            Image {
                id: wallpaperThumbnail
                anchors.fill: parent
                source: Config.wallpaperUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
            }

            OpacityMask {
                anchors.fill: wallpaperThumbnail
                source: wallpaperThumbnail

                maskSource: Rectangle {
                    width: previewBackground.width
                    height: previewBackground.height
                    radius: 14
                }
            }

            // Darkening overlay on hover
            Rectangle {
                anchors.fill: parent
                radius: 14
                color: Qt.rgba(0, 0, 0, 0.42)
                opacity: previewMouse.containsMouse ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }
            }

            // Wallpaper Action Pill (Top Right)
            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 12
                implicitHeight: 30
                implicitWidth: changeWpRow.implicitWidth + 20
                radius: 15
                color: Qt.alpha(root.color1, 0.92)
                opacity: (previewMouse.containsMouse && !avatarMouse.containsMouse) ? 1 : 0
                scale: previewMouse.pressed ? 0.94 : ((previewMouse.containsMouse && !avatarMouse.containsMouse) ? 1.0 : 0.85)

                Behavior on opacity {
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }
                Behavior on scale {
                    NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                }

                RowLayout {
                    id: changeWpRow
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        text: "wallpaper"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 15
                        color: root.foreground
                    }

                    Text {
                        text: qsTr("Change Wallpaper")
                        font.family: "Google Sans Flex, Google Sans, sans-serif"
                        font.pixelSize: 11
                        font.bold: true
                        color: root.foreground
                    }
                }
            }

            // Current Wallpaper Info Badge
            Rectangle {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: 12
                implicitHeight: 28
                implicitWidth: currentWpLabel.implicitWidth + 24
                radius: 14
                color: Qt.alpha("#000000", 0.65)

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "wallpaper"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 15
                        color: root.color1
                    }

                    Text {
                        id: currentWpLabel
                        text: Config.wallpaperCleanPath ? Config.wallpaperCleanPath.split('/').pop() : qsTr("No wallpaper selected")
                        font.family: "Google Sans"
                        font.pixelSize: 11
                        font.bold: true
                        color: "#ffffff"
                        elide: Text.ElideMiddle
                    }
                }
            }

            // Click Handler across the entire card
            MouseArea {
                id: previewMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root && typeof root.openWallpaperPicker === "function") {
                        root.openWallpaperPicker();
                    }
                }
            }

            // Center User Profile Avatar
            Item {
                id: avatarContainer
                anchors.centerIn: parent
                width: 86
                height: 86
                z: 10
                scale: avatarMouse.pressed ? 0.94 : (avatarMouse.containsMouse ? 1.05 : 1.0)

                Behavior on scale {
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }

                // Outer accent ring
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + (avatarMouse.containsMouse ? 8 : 4)
                    height: parent.height + (avatarMouse.containsMouse ? 8 : 4)
                    radius: width / 2
                    color: "transparent"
                    border.color: avatarMouse.containsMouse ? root.color1 : Qt.alpha("#ffffff", 0.35)
                    border.width: avatarMouse.containsMouse ? 2.5 : 1.5
                    opacity: avatarMouse.containsMouse ? 1 : 0.8

                    Behavior on border.color { ColorAnimation { duration: 180 } }
                    Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }

                // Main circular frame
                Rectangle {
                    id: avatarCircle
                    anchors.fill: parent
                    radius: width / 2
                    color: Colors.cfg.surfaceContainer
                    border.color: root.surface
                    border.width: 3
                    clip: true

                    Image {
                        id: avatarImg
                        anchors.fill: parent
                        source: tabRoot.avatarSource
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                        visible: false
                    }

                    Rectangle {
                        id: avatarMask
                        anchors.fill: parent
                        radius: width / 2
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: avatarImg
                        source: avatarImg
                        maskSource: avatarMask
                        visible: avatarImg.status === Image.Ready
                    }

                    // Fallback icon if image not available
                    Item {
                        anchors.fill: parent
                        visible: avatarImg.status !== Image.Ready

                        Text {
                            anchors.centerIn: parent
                            text: "person"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 42
                            color: root.color1
                        }
                    }

                    // Hover dimming + edit overlay
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Qt.rgba(0, 0, 0, 0.48)
                        opacity: avatarMouse.containsMouse ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation { duration: 160 }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "photo_camera"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 22
                                color: "#ffffff"
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: qsTr("Edit")
                                font.family: "Google Sans Flex, Google Sans, sans-serif"
                                font.pixelSize: 10
                                font.bold: true
                                color: "#ffffff"
                            }
                        }
                    }
                }

                // Floating edit badge at bottom-right corner
                Rectangle {
                    id: avatarBadge
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: -1
                    width: 26
                    height: 26
                    radius: 13
                    color: root.color1
                    border.color: root.surface
                    border.width: 2
                    scale: avatarMouse.pressed ? 0.9 : (avatarMouse.containsMouse ? 1.15 : 1.0)

                    Behavior on scale {
                        NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "edit"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 13
                        color: root.foreground
                    }
                }

                // Dedicated MouseArea for Avatar
                MouseArea {
                    id: avatarMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    preventStealing: true

                    onClicked: {
                        if (selectAvatarProc.running) {
                            selectAvatarProc.running = false;
                        }
                        selectAvatarProc.running = true;
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 70
        radius: 14
        color: root.surface

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: qsTr("Wallpaper Folder")
                    font.family: "Google Sans"
                    font.pixelSize: 11
                    font.bold: true
                    color: root.textColor
                }

                Text {
                    text: Quickshell.env("HOME") + (Config.cfg.wallpaperFolder || "/Pictures/Wallpapers")
                    font.family: "Google Sans"
                    font.pixelSize: 10
                    color: root.textMuted
                    elide: Text.ElideMiddle
                }

            }

            Rectangle {
                implicitWidth: 90
                implicitHeight: 30
                radius: 8
                color: browseFolH.hovered ? Qt.alpha(root.color1, 0.25) : root.surfaceContainer

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "folder_open"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 15
                        color: root.color1
                    }

                    Text {
                        text: qsTr("Browse")
                        font.family: "Google Sans"
                        font.pixelSize: 10
                        font.bold: true
                        color: root.textColor
                    }

                }

                HoverHandler {
                    id: browseFolH
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selectFolderProc.running = true
                }

            }

            Rectangle {
                implicitWidth: 80
                implicitHeight: 30
                radius: 8
                color: resFolH.hovered ? Qt.alpha(root.color1, 0.25) : root.surfaceContainer

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "restart_alt"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 15
                        color: root.color1
                    }

                    Text {
                        text: qsTr("Default")
                        font.family: "Google Sans"
                        font.pixelSize: 10
                        font.bold: true
                        color: root.textColor
                    }

                }

                HoverHandler {
                    id: resFolH
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Config.cfg.wallpaperFolder = "/Pictures/Wallpapers";
                        Config.save();
                        root.refreshWallpapers();
                    }
                }

            }

        }

    }

    Rectangle {
        Layout.fillWidth: true
        radius: 14
        color: root.surface
        Layout.preferredHeight: animCol.implicitHeight + 28

        ColumnLayout {
            id: animCol

            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: qsTr("Wallpaper Transition")
                    font.family: "Google Sans"
                    font.pixelSize: 12
                    font.bold: true
                    color: root.textColor
                    Layout.fillWidth: true
                }

                Text {
                    text: (Config.cfg.wallpaperAnimation || "wave").toUpperCase()
                    font.family: "Google Sans"
                    font.pixelSize: 10
                    font.bold: true
                    color: root.color1
                }

            }

            Flow {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: ["fade", "wipe", "wave", "grow", "center", "outer", "left", "right", "top", "bottom", "simple", "random"]

                    delegate: Rectangle {
                        id: animPill

                        required property string modelData
                        readonly property bool isSelected: (Config.cfg.wallpaperAnimation || "wave") === modelData

                        implicitHeight: 28
                        implicitWidth: animLabel.implicitWidth + 20
                        radius: 14
                        color: isSelected ? root.color1 : (animMa.containsMouse ? root.surfaceContainer : root.surface)
                        border.color: isSelected ? root.color1 : Qt.alpha(root.textColor, 0.1)
                        border.width: 1
                        scale: animMa.pressed ? 0.95 : 1

                        Text {
                            id: animLabel

                            anchors.centerIn: parent
                            text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                            font.family: "Google Sans"
                            font.pixelSize: 10
                            font.bold: animPill.isSelected
                            color: animPill.isSelected ? root.foreground : (animMa.containsMouse ? root.textBright : root.textColor)

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }

                            }

                        }

                        MouseArea {
                            id: animMa

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Config.cfg.wallpaperAnimation = modelData;
                                Config.save();
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }

                        }

                    }

                }

            }

            SettingDivider {}

            SettingSlider {
                title: qsTr("Transition Duration")
                hint: qsTr("Controls how long wallpaper change transitions take in seconds")
                from: 0.5
                to: 5.0
                stepSize: 0.25
                value: (Config.cfg && Config.cfg.wallpaperAnimationDuration !== undefined) ? Config.cfg.wallpaperAnimationDuration : 1.0
                customValueText: (((Config.cfg && Config.cfg.wallpaperAnimationDuration !== undefined) ? Config.cfg.wallpaperAnimationDuration : 1.0)).toFixed(2) + "s"
                showReset: true
                resetValue: 1.0
                onValueModified: (val) => {
                    Config.cfg.wallpaperAnimationDuration = Math.round(val * 100) / 100;
                    Config.saveDebounced(100);
                }
                onValueCommitted: (val) => {
                    Config.cfg.wallpaperAnimationDuration = Math.round(val * 100) / 100;
                    Config.save();
                }
            }

        }

    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 10

        Rectangle {
            implicitWidth: 30
            implicitHeight: 30
            radius: 8
            color: Qt.alpha(root.color1, 0.15)
            border.color: Qt.alpha(root.color1, 0.3)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "opacity"
                font.pixelSize: 18
                font.family: "Material Symbols Rounded"
                color: root.color1
            }

        }

        ColumnLayout {
            spacing: 1

            Text {
                text: qsTr("Glassmorphism & Translucency")
                font.family: "Google Sans"
                font.pixelSize: 13
                font.bold: true
                color: root.textBright
            }

            Text {
                text: qsTr("Global interface transparency and GPU background blur depth across all shell surfaces")
                font.family: "Google Sans"
                font.pixelSize: 10
                color: root.textMuted
            }

        }

    }

    SettingCard {
        SettingToggle {
            icon: "energy_savings_leaf"
            title: qsTr("Eco Mode (Battery Saver Profile)")
            hint: qsTr("Engages Hyprland Game Mode and disables blur to minimize GPU/CPU overhead")
            description: qsTr("Maximize battery life and performance by automatically engaging Game Mode and disabling blur")
            checked: (Config.cfg && Config.cfg.ecoMode !== undefined) ? Config.cfg.ecoMode : false
            onToggled: (newState) => {
                Config.cfg.ecoMode = newState;
                if (newState) {
                    Config.cfg.blurEnabled = false;
                } else {
                    Config.cfg.blurEnabled = true;
                }
                Config.save();
                Config.applyEcoMode(newState);
            }
        }
    }

    SettingCard {
        SettingSlider {
            title: qsTr("General Interface Opacity")
            value: Config.effectiveGeneralOpacity
            from: 0.3
            to: 1
            stepSize: 0.01
            showReset: true
            resetValue: 0.85
            customValueText: Math.round(Config.effectiveGeneralOpacity * 100) + "%"
            onValueModified: (val) => {
                Config.cfg.generalOpacity = val;
                Config.saveDebounced(80);
            }
            onValueCommitted: (val) => {
                Config.cfg.generalOpacity = val;
                Config.save();
            }
        }

    }

    SettingCard {
        SettingToggle {
            title: qsTr("Interface Blur (Glassmorphism)")
            checked: (Config.cfg && Config.cfg.blurEnabled !== undefined) ? Config.cfg.blurEnabled : true
            onToggled: (newState) => {
                Config.cfg.blurEnabled = newState;
                Config.save();
                BlurService.applyBlur(newState, Config.effectiveBlurStrength);
            }
        }

    }

    SettingCard {
        id: blurCard

        readonly property int minBlur: 2
        readonly property int maxBlur: 24
        readonly property int currentBlurSize: {
            var st = Config.effectiveBlurStrength;
            if (st === "light")
                return 4;

            if (st === "balanced")
                return 10;

            if (st === "strong")
                return 16;

            if (st === "maximum")
                return 22;

            var num = parseInt(st);
            return (!isNaN(num) && num > 0) ? Math.max(minBlur, Math.min(maxBlur, num)) : 3;
        }

        visible: Config.cfg && (Config.cfg.blurEnabled === undefined || Config.cfg.blurEnabled)

        SettingSlider {
            title: qsTr("Blur Intensity")
            value: blurCard.currentBlurSize
            from: blurCard.minBlur
            to: blurCard.maxBlur
            stepSize: 1
            unit: "px"
            showReset: true
            resetValue: 3
            onValueModified: (val) => {
                Config.cfg.blurStrength = String(Math.round(val));
                Config.saveDebounced(80);
            }
            onValueCommitted: (val) => {
                Config.cfg.blurStrength = String(Math.round(val));
                Config.save();
                BlurService.applyBlur(true, String(Math.round(val)));
            }
        }

    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 8
        spacing: 10

        Rectangle {
            implicitWidth: 30
            implicitHeight: 30
            radius: 8
            color: Qt.alpha(root.color1, 0.15)
            border.color: Qt.alpha(root.color1, 0.3)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "rounded_corner"
                font.pixelSize: 18
                font.family: "Material Symbols Rounded"
                color: root.color1
            }

        }

        ColumnLayout {
            spacing: 1

            Text {
                text: qsTr("Shapes & Curvature Geometry")
                font.family: "Google Sans"
                font.pixelSize: 13
                font.bold: true
                color: root.textBright
            }

            Text {
                text: qsTr("Corner roundness for all shell menus, launchers, notifications, and floating windows")
                font.family: "Google Sans"
                font.pixelSize: 10
                color: root.textMuted
            }

        }

    }

    SettingCard {
        SettingSlider {
            title: qsTr("General Corner Curvature")
            value: Config.effectiveGeneralRadius
            from: 0
            to: 36
            stepSize: 1
            unit: "px"
            showReset: true
            resetValue: 20
            onValueModified: (val) => {
                Config.cfg.generalRadius = Math.round(val);
                Config.saveDebounced(80);
            }
            onValueCommitted: (val) => {
                Config.cfg.generalRadius = Math.round(val);
                Config.save();
            }
        }

        SettingPills {
            currentValue: Config.effectiveGeneralRadius
            model: [{
                "label": qsTr("Sharp"),
                "val": 0
            }, {
                "label": qsTr("Subtle"),
                "val": 10
            }, {
                "label": qsTr("Modern"),
                "val": 20
            }, {
                "label": qsTr("Smooth"),
                "val": 28
            }, {
                "label": qsTr("Pill"),
                "val": 36
            }]
            onSelected: (val) => {
                Config.cfg.generalRadius = val;
                Config.save();
            }
        }

    }

    SettingSectionHeader {
        icon: "schedule"
        title: qsTr("Clock & Time Format")
        description: qsTr("Time standard (12h / 24h) and top bar clock display format")
    }

    SettingCard {
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: (Config.cfg && Config.cfg.clock24h) ? Qt.formatTime(tabRoot.now, "HH:mm:ss") : Qt.formatTime(tabRoot.now, "hh:mm:ss AP")
                    font.pixelSize: 26
                    font.bold: true
                    font.family: "GeistMono Nerd Font Propo"
                    color: root.textBright
                }

                Text {
                    text: Qt.formatDate(tabRoot.now, "dddd, d MMMM yyyy")
                    font.family: "Google Sans"
                    font.pixelSize: 11
                    color: root.textMuted
                }

            }

            Rectangle {
                implicitWidth: clockStandardPill.implicitWidth + 16
                implicitHeight: 26
                radius: 13
                color: Qt.alpha(root.color1, 0.15)
                border.color: Qt.alpha(root.color1, 0.35)
                border.width: 1

                Text {
                    id: clockStandardPill

                    anchors.centerIn: parent
                    text: (Config.cfg && Config.cfg.clock24h) ? qsTr("24-HOUR") : qsTr("12-HOUR")
                    font.family: "Google Sans"
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 0.6
                    color: root.color1
                }

            }

        }

        SettingDivider {
        }

        SettingToggle {
            icon: "schedule"
            title: qsTr("24-Hour Time Format")
            checked: (Config.cfg && Config.cfg.clock24h)
            onToggled: (newState) => {
                Config.cfg.clock24h = newState;
                Config.save();
            }
        }

        SettingDivider {
        }

        SettingToggle {
            icon: "calendar_month"
            title: qsTr("Start Week on Monday")
            checked: (Config.cfg && Config.cfg.weekStartsOnMonday)
            onToggled: (newState) => {
                Config.cfg.weekStartsOnMonday = newState;
                Config.save();
            }
        }

    }

    SettingSectionHeader {
        icon: "videocam"
        title: qsTr("Desktop & System Paths")
        description: qsTr("Directories and file paths for system screen recordings and media captures")
    }

    SettingCard {
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: "videocam"
                font.pixelSize: 22
                font.family: "Material Symbols Rounded"
                color: root.color1
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: qsTr("Screen Recordings Folder")
                    font.family: "Google Sans"
                    font.pixelSize: 12
                    font.bold: true
                    color: root.textColor
                }

                Text {
                    text: (Config.cfg && Config.cfg.recordingsFolder) ? Config.cfg.recordingsFolder : "~/Videos/Recordings"
                    font.family: "Google Sans"
                    font.pixelSize: 10
                    color: root.textMuted
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }

            }

            SettingButton {
                icon: "folder_open"
                text: qsTr("Browse")
                variant: "secondary"
                onClicked: root.selectRecordingsFolderProc.running = true
            }

            SettingButton {
                icon: "restart_alt"
                text: qsTr("Default")
                variant: "secondary"
                onClicked: {
                    Config.cfg.recordingsFolder = "~/Videos/Recordings";
                    Config.save();
                }
            }

        }

    }

}
