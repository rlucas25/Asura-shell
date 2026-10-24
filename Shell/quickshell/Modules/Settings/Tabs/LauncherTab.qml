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
    id: tabRoot

    required property var settingsRoot
    readonly property var root: settingsRoot

    Layout.fillWidth: true
    spacing: 16
    visible: root.currentTab === "launcher"

    SettingSectionHeader {
        icon: "rocket_launch"
        title: qsTr("App Launcher")
        description: qsTr("Configure launcher position and search prefix shortcuts")
        hint: qsTr("Launcher behavior, search prefixes for commands, math calculator, and web search")
    }

    Rectangle {
        id: previewCard

        property int scenarioIndex: 0
        property int charIndex: 0
        property int pauseTicks: 0
        property string simQueryText: ""
        property bool cursorVisible: true
        readonly property var scenarios: [{
            "mode": "app",
            "query": "code",
            "icon": "search",
            "resultIcon": "code",
            "resultTitle": "Visual Studio Code",
            "resultSub": "Development • /usr/bin/code",
            "resultBadge": "APP",
            "secondaryIcon": "public",
            "secondaryTitle": "Firefox",
            "secondarySub": "Web Browser • /usr/bin/firefox",
            "tertiaryIcon": "terminal",
            "tertiaryTitle": "Kitty Terminal",
            "tertiarySub": "System • /usr/bin/kitty",
            "actionHint": qsTr("Press Enter to launch")
        }, {
            "mode": "calc",
            "query": (Config.cfg && Config.cfg.launcherCalculatorNoPrefix) ? "24 * 7" : "= 24 * 7",
            "icon": "calculate",
            "resultIcon": "calculate",
            "resultTitle": "168",
            "resultSub": ((Config.cfg && Config.cfg.launcherCalculatorNoPrefix) ? "24 * 7" : "= 24 * 7") + " • Math Result",
            "resultBadge": "CALC",
            "secondaryIcon": "functions",
            "secondaryTitle": "42 + 58 = 100",
            "secondarySub": "Math • Quick calculation",
            "tertiaryIcon": "calculate",
            "tertiaryTitle": "Calculator",
            "tertiarySub": "Utility • /usr/bin/gnome-calculator",
            "actionHint": qsTr("Press Enter to copy result")
        }, {
            "mode": "cmd",
            "query": (Config.cfg && Config.cfg.launcherCommandsNoPrefix) ? "dark mode" : "> dark mode",
            "icon": "keyboard_command_key",
            "resultIcon": "dark_mode",
            "resultTitle": "Toggle Dark Mode",
            "resultSub": "System Command • Theme Switcher",
            "resultBadge": "CMD",
            "secondaryIcon": "settings",
            "secondaryTitle": "Open Settings",
            "secondarySub": "Preferences • Shell Control Panel",
            "tertiaryIcon": "wallpaper",
            "tertiaryTitle": "Random Wallpaper",
            "tertiarySub": "Desktop • Cycle Background",
            "actionHint": qsTr("Press Enter to execute")
        }, {
            "mode": "web",
            "query": (Config.cfg && Config.cfg.launcherWebSearchNoPrefix) ? "quickshell docs" : "? quickshell docs",
            "icon": "public",
            "resultIcon": "public",
            "resultTitle": "Search web for \"quickshell docs\"",
            "resultSub": "Web Search • Open in default browser",
            "resultBadge": "WEB",
            "secondaryIcon": "travel_explore",
            "secondaryTitle": "Google Search",
            "secondarySub": "Internet • Default search provider",
            "tertiaryIcon": "open_in_browser",
            "tertiaryTitle": "Vivaldi Browser",
            "tertiarySub": "Web Browser • Default application",
            "actionHint": qsTr("Press Enter to search web")
        }]
        readonly property var currentScenario: scenarios[scenarioIndex % scenarios.length]

        function nextScenario() {
            scenarioIndex = (scenarioIndex + 1) % scenarios.length;
            charIndex = 0;
            pauseTicks = 0;
            simQueryText = "";
        }

        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(300, Math.min(380, Math.round(previewCard.width / 2.3)))
        radius: 16
        color: root.surface
        border.color: Qt.alpha(root.borderCol, 0.3)
        border.width: 1
        clip: true

        Timer {
            id: animTimer

            interval: 110
            running: tabRoot.visible && tabRoot.root.currentTab === "launcher"
            repeat: true
            onTriggered: {
                var target = previewCard.currentScenario.query;
                if (previewCard.pauseTicks > 0) {
                    previewCard.pauseTicks--;
                    if (previewCard.pauseTicks <= 7)
                        previewCard.simQueryText = "";

                    if (previewCard.pauseTicks === 0)
                        previewCard.nextScenario();

                } else if (previewCard.charIndex < target.length) {
                    previewCard.charIndex++;
                    previewCard.simQueryText = target.substring(0, previewCard.charIndex);
                    if (previewCard.charIndex >= target.length)
                        previewCard.pauseTicks = 20;

                }
            }
        }

        Timer {
            interval: 450
            running: tabRoot.visible && tabRoot.root.currentTab === "launcher"
            repeat: true
            onTriggered: {
                previewCard.cursorVisible = !previewCard.cursorVisible;
            }
        }

        Connections {
            function onLauncherCalculatorNoPrefixChanged() {
                previewCard.charIndex = 0;
                previewCard.pauseTicks = 0;
                previewCard.simQueryText = "";
            }

            function onLauncherCommandsNoPrefixChanged() {
                previewCard.charIndex = 0;
                previewCard.pauseTicks = 0;
                previewCard.simQueryText = "";
            }

            function onLauncherWebSearchNoPrefixChanged() {
                previewCard.charIndex = 0;
                previewCard.pauseTicks = 0;
                previewCard.simQueryText = "";
            }

            target: Config.cfg ? Config.cfg : null
        }

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
                        font.family: "Google Sans"
                        text: qsTr("Live Preview")
                        font.pixelSize: 11
                        font.bold: true
                        color: root.textColor
                    }

                    Text {
                        font.family: "Google Sans"
                        text: qsTr("• Animated search course & live styling")
                        font.pixelSize: 10
                        color: root.textMuted
                    }

                }

                Rectangle {
                    implicitWidth: positionBadgeRow.implicitWidth + 12
                    implicitHeight: 20
                    radius: 10
                    color: Qt.alpha(root.color1, 0.15)
                    border.color: Qt.alpha(root.color1, 0.3)
                    border.width: 1

                    RowLayout {
                        id: positionBadgeRow

                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: {
                                if (Config.cfg && (Config.cfg.launcherPosition === "zen" || Config.cfg.launcherPosition === "zen mode"))
                                    return "spa";

                                if (Config.cfg && (Config.cfg.launcherPosition === "center" || Config.cfg.launcherPosition === "centralizado"))
                                    return "crop_landscape";

                                return "dock_to_bottom";
                            }
                            font.pixelSize: 12
                            font.family: "Material Symbols Rounded"
                            color: root.color1
                        }

                        Text {
                            font.family: "Google Sans"
                            text: {
                                if (Config.cfg && (Config.cfg.launcherPosition === "zen" || Config.cfg.launcherPosition === "zen mode"))
                                    return qsTr("ZEN MODE");

                                if (Config.cfg && (Config.cfg.launcherPosition === "center" || Config.cfg.launcherPosition === "centralizado"))
                                    return qsTr("CENTRALIZADO");

                                return qsTr("DEFAULT (BAR)");
                            }
                            font.pixelSize: 9
                            font.bold: true
                            color: root.color1
                        }

                    }

                }

                Rectangle {
                    implicitWidth: cmdBadgeText.implicitWidth + 10
                    implicitHeight: 20
                    radius: 10
                    color: (Config.cfg && Config.cfg.launcherCommandsNoPrefix) ? Qt.alpha(root.color1, 0.12) : Qt.alpha(root.textColor, 0.08)
                    border.color: (Config.cfg && Config.cfg.launcherCommandsNoPrefix) ? Qt.alpha(root.color1, 0.28) : Qt.alpha(root.borderCol, 0.3)
                    border.width: 1

                    Text {
                        font.family: "Google Sans"
                        id: cmdBadgeText

                        anchors.centerIn: parent
                        text: (Config.cfg && Config.cfg.launcherCommandsNoPrefix) ? qsTr("CMD: DIRECT") : qsTr("CMD: >")
                        font.pixelSize: 8
                        font.bold: true
                        color: (Config.cfg && Config.cfg.launcherCommandsNoPrefix) ? root.color1 : root.textMuted
                    }

                }

                Rectangle {
                    implicitWidth: calcBadgeText.implicitWidth + 10
                    implicitHeight: 20
                    radius: 10
                    color: (Config.cfg && Config.cfg.launcherCalculatorNoPrefix) ? Qt.alpha(root.color1, 0.12) : Qt.alpha(root.textColor, 0.08)
                    border.color: (Config.cfg && Config.cfg.launcherCalculatorNoPrefix) ? Qt.alpha(root.color1, 0.28) : Qt.alpha(root.borderCol, 0.3)
                    border.width: 1

                    Text {
                        font.family: "Google Sans"
                        id: calcBadgeText

                        anchors.centerIn: parent
                        text: (Config.cfg && Config.cfg.launcherCalculatorNoPrefix) ? qsTr("CALC: DIRECT") : qsTr("CALC: =")
                        font.pixelSize: 8
                        font.bold: true
                        color: (Config.cfg && Config.cfg.launcherCalculatorNoPrefix) ? root.color1 : root.textMuted
                    }

                }

                Rectangle {
                    implicitWidth: webBadgeText.implicitWidth + 10
                    implicitHeight: 20
                    radius: 10
                    color: (Config.cfg && Config.cfg.launcherWebSearchNoPrefix) ? Qt.alpha(root.color1, 0.12) : Qt.alpha(root.textColor, 0.08)
                    border.color: (Config.cfg && Config.cfg.launcherWebSearchNoPrefix) ? Qt.alpha(root.color1, 0.28) : Qt.alpha(root.borderCol, 0.3)
                    border.width: 1

                    Text {
                        font.family: "Google Sans"
                        id: webBadgeText

                        anchors.centerIn: parent
                        text: (Config.cfg && Config.cfg.launcherWebSearchNoPrefix) ? qsTr("WEB: DIRECT") : qsTr("WEB: ?")
                        font.pixelSize: 8
                        font.bold: true
                        color: (Config.cfg && Config.cfg.launcherWebSearchNoPrefix) ? root.color1 : root.textMuted
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

                Rectangle {
                    anchors.fill: parent

                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: Qt.alpha(root.color1, 0.12)
                        }

                        GradientStop {
                            position: 1
                            color: Qt.alpha(root.surface, 0.95)
                        }

                    }

                }

                Image {
                    id: screenWallpaper

                    anchors.fill: parent
                    source: (Config.cfg && Config.cfg.wallpaper) ? ("file://" + Config.cfg.wallpaper) : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: 0.42
                    visible: (Config.cfg && Config.cfg.wallpaper !== "")
                }

                Rectangle {
                    id: miniTopBar

                    anchors.top: parent.top
                    anchors.topMargin: 4
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    height: 18
                    radius: 9
                    color: launcherMockupContainer.isBarAttached ? Qt.alpha(root.surface, 0.96) : Qt.alpha(root.surface, 0.92)
                    border.color: Qt.alpha(root.borderCol, 0.25)
                    border.width: 1
                    z: 5

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 8
                        spacing: 6

                        Rectangle {
                            implicitWidth: 20
                            implicitHeight: 12
                            radius: 5
                            color: (!Config.cfg || (Config.cfg.launcherPosition !== "center" && Config.cfg.launcherPosition !== "centralizado" && Config.cfg.launcherPosition !== "zen" && Config.cfg.launcherPosition !== "zen mode")) ? root.color1 : Qt.alpha(root.textColor, 0.15)

                            Text {
                                anchors.centerIn: parent
                                text: "apps"
                                font.pixelSize: 8
                                font.family: "Material Symbols Rounded"
                                color: (!Config.cfg || (Config.cfg.launcherPosition !== "center" && Config.cfg.launcherPosition !== "centralizado" && Config.cfg.launcherPosition !== "zen" && Config.cfg.launcherPosition !== "zen mode")) ? root.foreground : root.textMuted
                            }

                        }

                        Row {
                            spacing: 3

                            Rectangle {
                                width: 4
                                height: 4
                                radius: 2
                                color: root.color1
                            }

                            Rectangle {
                                width: 4
                                height: 4
                                radius: 2
                                color: Qt.alpha(root.textColor, 0.3)
                            }

                            Rectangle {
                                width: 4
                                height: 4
                                radius: 2
                                color: Qt.alpha(root.textColor, 0.3)
                            }

                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            font.family: "GeistMono Nerd Font Propo"
                            text: "12:00"
                            font.pixelSize: 8
                            font.bold: true
                            color: root.textColor
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Row {
                            spacing: 5

                            Text {
                                text: "wifi"
                                font.pixelSize: 9
                                color: root.textMuted
                                font.family: "Material Symbols Rounded"
                            }

                            Text {
                                text: "volume_up"
                                font.pixelSize: 9
                                color: root.textMuted
                                font.family: "Material Symbols Rounded"
                            }

                            Text {
                                text: "battery_full"
                                font.pixelSize: 9
                                color: root.textMuted
                                font.family: "Material Symbols Rounded"
                            }

                        }

                    }

                }

                Item {
                    id: desktopArea

                    anchors.top: miniTopBar.bottom
                    anchors.topMargin: launcherMockupContainer.isBarAttached ? -1 : 0
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    z: launcherMockupContainer.isBarAttached ? 6 : 0

                    Rectangle {
                        anchors.fill: parent
                        color: {
                            if (!Config.cfg)
                                return "transparent";

                            if (Config.cfg.launcherPosition === "zen" || Config.cfg.launcherPosition === "zen mode")
                                return Qt.rgba(0, 0, 0, 0.55);

                            if (Config.cfg.launcherPosition === "center" || Config.cfg.launcherPosition === "centralizado")
                                return Qt.rgba(0, 0, 0, 0.45);

                            return "transparent";
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 220
                            }

                        }

                    }

                    Item {
                        id: launcherMockupContainer

                        readonly property bool isBarAttached: !Config.cfg || (!Config.cfg.launcherPosition || Config.cfg.launcherPosition === "default" || Config.cfg.launcherPosition === "bar")
                        readonly property bool isCenter: Config.cfg && (Config.cfg.launcherPosition === "center" || Config.cfg.launcherPosition === "centralizado")
                        readonly property bool isZen: Config.cfg && (Config.cfg.launcherPosition === "zen" || Config.cfg.launcherPosition === "zen mode")
                        readonly property bool isResting: isZen && (previewCard.simQueryText === "")

                        width: isZen ? Math.min(385, desktopArea.width - 24) : isCenter ? Math.min(335, desktopArea.width - 32) : Math.min(285, desktopArea.width - 24)
                        height: isZen ? (isResting ? Math.min(235, desktopArea.height - 10) : Math.min(225, desktopArea.height - 10)) : isCenter ? Math.min(215, desktopArea.height - 12) : Math.min(210, desktopArea.height - 8)
                        x: Math.round((desktopArea.width - width) / 2)
                        y: isBarAttached ? 0 : (isZen ? Math.max(6, Math.round((desktopArea.height - height) * 0.18)) : Math.max(6, Math.round((desktopArea.height - height) / 2)))

                        RectangularGlow {
                            anchors.fill: launcherMockupCard
                            anchors.topMargin: launcherMockupContainer.isBarAttached ? 8 : 0
                            glowRadius: launcherMockupContainer.isZen ? 14 : (launcherMockupContainer.isCenter ? 12 : 8)
                            spread: 0.08
                            color: Qt.rgba(0, 0, 0, launcherMockupContainer.isZen ? 0.65 : 0.5)
                            cornerRadius: launcherMockupCard.bottomLeftRadius + 2
                        }

                        Rectangle {
                            id: launcherMockupCard

                            anchors.fill: parent
                            radius: 0
                            topLeftRadius: launcherMockupContainer.isBarAttached ? 0 : (launcherMockupContainer.isZen ? 14 : (launcherMockupContainer.isCenter ? 14 : 12))
                            topRightRadius: launcherMockupContainer.isBarAttached ? 0 : (launcherMockupContainer.isZen ? 14 : (launcherMockupContainer.isCenter ? 14 : 12))
                            bottomLeftRadius: launcherMockupContainer.isZen ? 14 : (launcherMockupContainer.isCenter ? 14 : 12)
                            bottomRightRadius: launcherMockupContainer.isZen ? 14 : (launcherMockupContainer.isCenter ? 14 : 12)
                            color: launcherMockupContainer.isZen ? Qt.alpha(root.surfaceContainer, 0.96) : (launcherMockupContainer.isBarAttached ? miniTopBar.color : Qt.alpha(root.surface, 0.95))
                            border.color: launcherMockupContainer.isBarAttached ? miniTopBar.border.color : (launcherMockupContainer.isCenter ? Qt.alpha(root.color1, 0.45) : Qt.alpha(root.color1, 0.3))
                            border.width: 1
                            clip: true

                            Rectangle {
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.leftMargin: 1
                                anchors.right: parent.right
                                anchors.rightMargin: 1
                                height: 3
                                color: launcherMockupCard.color
                                visible: launcherMockupContainer.isBarAttached
                                z: 10
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 9
                                spacing: 6
                                visible: launcherMockupContainer.isZen

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 26
                                    spacing: 8

                                    Rectangle {
                                        Layout.preferredWidth: 22
                                        Layout.preferredHeight: 22
                                        radius: 6
                                        color: Qt.alpha(root.color1, 0.18)
                                        border.color: Qt.alpha(root.color1, 0.35)
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: "禅"
                                            font.pixelSize: 11
                                            font.family: "Google Sans"
                                            font.weight: Font.DemiBold
                                            color: root.color1
                                        }

                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: {
                                            if (previewCard.simQueryText !== "")
                                                return previewCard.simQueryText + (previewCard.cursorVisible ? "│" : "");

                                            return qsTr("Search apps, > commands, = calc, ? web, ! shell...") + (previewCard.cursorVisible ? "│" : "");
                                        }
                                        font.pixelSize: 9
                                        font.family: "Google Sans"
                                        color: previewCard.simQueryText !== "" ? root.textBright : root.textMuted
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        visible: previewCard.simQueryText !== ""
                                        implicitWidth: zenModeChipText.implicitWidth + 8
                                        implicitHeight: 16
                                        radius: 4
                                        color: Qt.alpha(root.color1, 0.2)
                                        border.color: Qt.alpha(root.color1, 0.4)
                                        border.width: 1

                                        Text {
                                            font.family: "Google Sans"
                                            id: zenModeChipText

                                            anchors.centerIn: parent
                                            text: previewCard.currentScenario.resultBadge
                                            font.pixelSize: 7
                                            font.bold: true
                                            color: root.color1
                                        }

                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 18
                                        Layout.preferredHeight: 18
                                        radius: 4
                                        color: Qt.alpha(root.textColor, 0.08)

                                        Text {
                                            font.family: "Google Sans"
                                            anchors.centerIn: parent
                                            text: "?"
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: root.textMuted
                                        }

                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 18
                                        Layout.preferredHeight: 18
                                        radius: 4
                                        color: Qt.alpha(root.textColor, 0.08)

                                        Grid {
                                            anchors.centerIn: parent
                                            columns: 3
                                            spacing: 1

                                            Repeater {
                                                model: 9

                                                Rectangle {
                                                    width: 2
                                                    height: 2
                                                    radius: 1
                                                    color: root.color1
                                                }

                                            }

                                        }

                                    }

                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 1
                                    color: Qt.alpha(root.color1, 0.18)
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 5
                                    visible: launcherMockupContainer.isResting

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 68
                                        radius: 8
                                        color: Qt.alpha(root.surface, 0.8)
                                        border.color: Qt.alpha(root.color1, 0.2)
                                        border.width: 1
                                        clip: true

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            spacing: 1

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 8

                                                Text {
                                                    text: "12:45"
                                                    font.pixelSize: 18
                                                    font.bold: true
                                                    font.family: "Google Sans"
                                                    color: root.textBright
                                                }

                                                ColumnLayout {
                                                    spacing: 0

                                                    Text {
                                                        font.family: "Google Sans"
                                                        text: qsTr("Zen Living Desktop")
                                                        font.pixelSize: 8
                                                        font.bold: true
                                                        color: root.color1
                                                    }

                                                    Text {
                                                        font.family: "Google Sans"
                                                        text: qsTr("Type anywhere to search apps & commands")
                                                        font.pixelSize: 7
                                                        color: root.textMuted
                                                    }

                                                }

                                                Item {
                                                    Layout.fillWidth: true
                                                }

                                                Rectangle {
                                                    implicitWidth: zenTagTxt.implicitWidth + 8
                                                    implicitHeight: 15
                                                    radius: 4
                                                    color: Qt.alpha(root.color1, 0.18)

                                                    Text {
                                                        font.family: "Google Sans"
                                                        id: zenTagTxt

                                                        anchors.centerIn: parent
                                                        text: "ZEN · ASURA"
                                                        font.pixelSize: 7
                                                        font.bold: true
                                                        color: root.color1
                                                    }

                                                }

                                            }

                                            Canvas {
                                                id: miniZenWave

                                                property real wavePhase: 0

                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 12
                                                onPaint: {
                                                    var ctx = getContext("2d");
                                                    ctx.clearRect(0, 0, width, height);
                                                    ctx.beginPath();
                                                    ctx.moveTo(0, height / 2);
                                                    for (var x = 0; x <= width; x += 4) {
                                                        var y = height / 2 + Math.sin(x * 0.05 + wavePhase) * 4;
                                                        ctx.lineTo(x, y);
                                                    }
                                                    ctx.strokeStyle = root.color1;
                                                    ctx.lineWidth = 1.4;
                                                    ctx.stroke();
                                                }

                                                Timer {
                                                    interval: 50
                                                    running: tabRoot.visible && launcherMockupContainer.isResting
                                                    repeat: true
                                                    onTriggered: {
                                                        miniZenWave.wavePhase += 0.08;
                                                        miniZenWave.requestPaint();
                                                    }
                                                }

                                            }

                                        }

                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 4

                                        Repeater {
                                            model: [{
                                                "name": qsTr("Settings"),
                                                "icon": "settings"
                                            }, {
                                                "name": qsTr("Wallpaper"),
                                                "icon": "wallpaper"
                                            }, {
                                                "name": qsTr("Terminal"),
                                                "icon": "terminal"
                                            }, {
                                                "name": qsTr("Lock"),
                                                "icon": "lock"
                                            }]

                                            Rectangle {
                                                Layout.fillWidth: true
                                                implicitHeight: 18
                                                radius: 4
                                                color: Qt.alpha(root.textColor, 0.06)
                                                border.color: Qt.alpha(root.borderCol, 0.2)
                                                border.width: 1

                                                RowLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 3

                                                    Text {
                                                        text: modelData.icon
                                                        font.pixelSize: 8
                                                        font.family: "Material Symbols Rounded"
                                                        color: root.color1
                                                    }

                                                    Text {
                                                        font.family: "Google Sans"
                                                        text: modelData.name
                                                        font.pixelSize: 7
                                                        color: root.textColor
                                                    }

                                                }

                                            }

                                        }

                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            font.family: "Google Sans"
                                            text: qsTr("RECENT APPLICATIONS")
                                            font.pixelSize: 7
                                            font.bold: true
                                            color: root.textMuted
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 4

                                            Repeater {
                                                model: [{
                                                    "name": "Code",
                                                    "icon": "code"
                                                }, {
                                                    "name": "Firefox",
                                                    "icon": "public"
                                                }, {
                                                    "name": "Kitty",
                                                    "icon": "terminal"
                                                }]

                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    implicitHeight: 22
                                                    radius: 5
                                                    color: Qt.alpha(root.surface, 0.7)
                                                    border.color: Qt.alpha(root.color1, 0.15)
                                                    border.width: 1

                                                    RowLayout {
                                                        anchors.fill: parent
                                                        anchors.margins: 4
                                                        spacing: 4

                                                        Text {
                                                            text: modelData.icon
                                                            font.pixelSize: 9
                                                            font.family: "Material Symbols Rounded"
                                                            color: root.color1
                                                        }

                                                        Text {
                                                            font.family: "Google Sans"
                                                            Layout.fillWidth: true
                                                            text: modelData.name
                                                            font.pixelSize: 7
                                                            font.bold: true
                                                            color: root.textBright
                                                            elide: Text.ElideRight
                                                        }

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
                                        spacing: 4

                                        Text {
                                            font.family: "Google Sans"
                                            text: qsTr("Living dashboard • Start typing to search")
                                            font.pixelSize: 7
                                            color: root.textMuted
                                        }

                                        Item {
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: "grid_view Grid • Esc Close"
                                            font.pixelSize: 7
                                            font.family: "Material Symbols Rounded"
                                            color: root.textMuted
                                        }

                                    }

                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 4
                                    visible: !launcherMockupContainer.isResting

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 38
                                        radius: 6
                                        color: Qt.alpha(root.color1, 0.18)
                                        border.color: Qt.alpha(root.color1, 0.42)
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            spacing: 8

                                            Rectangle {
                                                implicitWidth: 22
                                                implicitHeight: 22
                                                radius: 5
                                                color: Qt.alpha(root.color1, 0.25)

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: previewCard.currentScenario.resultIcon
                                                    font.pixelSize: 12
                                                    font.family: "Material Symbols Rounded"
                                                    color: root.color1
                                                }

                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 1

                                                Text {
                                                    font.family: "Google Sans"
                                                    text: previewCard.currentScenario.resultTitle
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                    color: root.textBright
                                                    elide: Text.ElideRight
                                                }

                                                Text {
                                                    font.family: "Google Sans"
                                                    text: previewCard.currentScenario.resultSub
                                                    font.pixelSize: 7
                                                    color: root.textMuted
                                                    elide: Text.ElideRight
                                                }

                                            }

                                            Rectangle {
                                                implicitWidth: zenActionHintRow.implicitWidth + 8
                                                implicitHeight: 16
                                                radius: 4
                                                color: Qt.alpha(root.color1, 0.2)

                                                RowLayout {
                                                    id: zenActionHintRow

                                                    anchors.centerIn: parent
                                                    spacing: 3

                                                    Text {
                                                        text: "keyboard_return"
                                                        font.pixelSize: 8
                                                        font.family: "Material Symbols Rounded"
                                                        color: root.color1
                                                    }

                                                    Text {
                                                        font.family: "Google Sans"
                                                        text: previewCard.currentScenario.actionHint
                                                        font.pixelSize: 7
                                                        font.bold: true
                                                        color: root.textBright
                                                    }

                                                }

                                            }

                                        }

                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 24
                                        radius: 5
                                        color: Qt.alpha(root.textColor, 0.04)

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            spacing: 8

                                            Text {
                                                text: previewCard.currentScenario.secondaryIcon
                                                font.pixelSize: 10
                                                font.family: "Material Symbols Rounded"
                                                color: root.textMuted
                                            }

                                            Text {
                                                font.family: "Google Sans"
                                                Layout.fillWidth: true
                                                text: previewCard.currentScenario.secondaryTitle
                                                font.pixelSize: 8
                                                color: root.textColor
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                font.family: "Google Sans"
                                                text: previewCard.currentScenario.secondarySub
                                                font.pixelSize: 7
                                                color: root.textMuted
                                                elide: Text.ElideRight
                                            }

                                        }

                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 22
                                        radius: 4
                                        color: Qt.alpha(root.textColor, 0.02)

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            spacing: 8

                                            Text {
                                                text: previewCard.currentScenario.tertiaryIcon
                                                font.pixelSize: 9
                                                font.family: "Material Symbols Rounded"
                                                color: root.textMuted
                                            }

                                            Text {
                                                font.family: "Google Sans"
                                                Layout.fillWidth: true
                                                text: previewCard.currentScenario.tertiaryTitle
                                                font.pixelSize: 8
                                                color: root.textMuted
                                                elide: Text.ElideRight
                                            }

                                        }

                                    }

                                    Item {
                                        Layout.fillHeight: true
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: qsTr("keyboard_return Select   •   grid_view Grid   •   Esc Exit")
                                            font.pixelSize: 7
                                            font.family: "Material Symbols Rounded"
                                            color: root.textMuted
                                        }

                                        Item {
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            font.family: "Google Sans"
                                            text: qsTr("Click to advance demo")
                                            font.pixelSize: 7
                                            color: Qt.alpha(root.color1, 0.7)
                                        }

                                    }

                                }

                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 5
                                visible: !launcherMockupContainer.isZen

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 26
                                    radius: 13
                                    color: Qt.alpha(root.textColor, 0.06)
                                    border.color: launcherMockupContainer.isCenter ? root.color1 : Qt.alpha(root.color1, 0.4)
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 6
                                        spacing: 6

                                        Text {
                                            text: previewCard.currentScenario.icon
                                            font.pixelSize: 11
                                            font.family: "Material Symbols Rounded"
                                            color: root.color1
                                        }

                                        Text {
                                            font.family: "Google Sans"
                                            Layout.fillWidth: true
                                            text: {
                                                if (previewCard.simQueryText !== "")
                                                    return previewCard.simQueryText + (previewCard.cursorVisible ? "│" : "");

                                                return qsTr("Search apps…") + (previewCard.cursorVisible ? "│" : "");
                                            }
                                            font.pixelSize: 9
                                            color: previewCard.simQueryText !== "" ? root.textBright : root.textMuted
                                            elide: Text.ElideRight
                                        }

                                        Rectangle {
                                            implicitWidth: appModePillText.implicitWidth + 8
                                            implicitHeight: 15
                                            radius: 4
                                            color: Qt.alpha(root.color1, 0.2)

                                            Text {
                                                font.family: "Google Sans"
                                                id: appModePillText

                                                anchors.centerIn: parent
                                                text: previewCard.currentScenario.resultBadge
                                                font.pixelSize: 7
                                                font.bold: true
                                                color: root.color1
                                            }

                                        }

                                    }

                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 38
                                    radius: 7
                                    color: Qt.alpha(root.color1, 0.16)
                                    border.color: Qt.alpha(root.color1, 0.42)
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 8

                                        Rectangle {
                                            implicitWidth: 24
                                            implicitHeight: 24
                                            radius: 5
                                            color: Qt.alpha(root.color1, 0.25)

                                            Text {
                                                anchors.centerIn: parent
                                                text: previewCard.currentScenario.resultIcon
                                                font.pixelSize: 13
                                                font.family: "Material Symbols Rounded"
                                                color: root.color1
                                            }

                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1

                                            Text {
                                                font.family: "Google Sans"
                                                text: previewCard.currentScenario.resultTitle
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: root.textBright
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                font.family: "Google Sans"
                                                text: previewCard.currentScenario.resultSub
                                                font.pixelSize: 8
                                                color: root.textMuted
                                                elide: Text.ElideRight
                                            }

                                        }

                                        Rectangle {
                                            implicitWidth: appActionPillRow.implicitWidth + 8
                                            implicitHeight: 18
                                            radius: 4
                                            color: Qt.alpha(root.color1, 0.2)

                                            RowLayout {
                                                id: appActionPillRow

                                                anchors.centerIn: parent
                                                spacing: 3

                                                Text {
                                                    text: "keyboard_return"
                                                    font.pixelSize: 8
                                                    font.family: "Material Symbols Rounded"
                                                    color: root.color1
                                                }

                                                Text {
                                                    font.family: "Google Sans"
                                                    text: previewCard.currentScenario.actionHint
                                                    font.pixelSize: 7
                                                    font.bold: true
                                                    color: root.textBright
                                                }

                                            }

                                        }

                                    }

                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 25
                                    radius: 5
                                    color: Qt.alpha(root.textColor, 0.04)

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 8

                                        Text {
                                            text: previewCard.currentScenario.secondaryIcon
                                            font.pixelSize: 10
                                            font.family: "Material Symbols Rounded"
                                            color: root.textMuted
                                        }

                                        Text {
                                            font.family: "Google Sans"
                                            Layout.fillWidth: true
                                            text: previewCard.currentScenario.secondaryTitle
                                            font.pixelSize: 8
                                            color: root.textColor
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            font.family: "Google Sans"
                                            text: previewCard.currentScenario.secondarySub
                                            font.pixelSize: 7
                                            color: root.textMuted
                                            elide: Text.ElideRight
                                        }

                                    }

                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 22
                                    radius: 4
                                    color: Qt.alpha(root.textColor, 0.02)
                                    visible: launcherMockupContainer.isCenter

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 8

                                        Text {
                                            text: previewCard.currentScenario.tertiaryIcon
                                            font.pixelSize: 9
                                            font.family: "Material Symbols Rounded"
                                            color: root.textMuted
                                        }

                                        Text {
                                            font.family: "Google Sans"
                                            Layout.fillWidth: true
                                            text: previewCard.currentScenario.tertiaryTitle
                                            font.pixelSize: 8
                                            color: root.textMuted
                                            elide: Text.ElideRight
                                        }

                                    }

                                }

                                Item {
                                    Layout.fillHeight: true
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 16
                                    color: "transparent"

                                    RowLayout {
                                        anchors.fill: parent
                                        spacing: 6

                                        Text {
                                            text: launcherMockupContainer.isCenter ? qsTr("keyboard_return Execute   •   Navigate   •   Esc Close") : qsTr("keyboard_return Launch   •   Navigate   •   Esc Close")
                                            font.pixelSize: 7
                                            font.family: "Material Symbols Rounded"
                                            color: root.textMuted
                                        }

                                        Item {
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            font.family: "Google Sans"
                                            text: qsTr("Click to advance demo")
                                            font.pixelSize: 7
                                            color: Qt.alpha(root.color1, 0.7)
                                        }

                                    }

                                }

                            }

                            Behavior on radius {
                                NumberAnimation {
                                    duration: 200
                                }

                            }

                        }

                        Behavior on x {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutCubic
                            }

                        }

                        Behavior on y {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutCubic
                            }

                        }

                        Behavior on width {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutCubic
                            }

                        }

                        Behavior on height {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutCubic
                            }

                        }

                    }

                    ConcaveCorner {
                        id: barMeltCornerLeft

                        visible: opacity > 0
                        opacity: launcherMockupContainer.isBarAttached ? 1 : 0
                        width: 14
                        height: 14
                        anchors.top: parent.top
                        anchors.right: launcherMockupContainer.left
                        anchors.rightMargin: -1
                        color: launcherMockupCard.color
                        position: "topRight"
                        z: 7

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    ConcaveCorner {
                        id: barMeltCornerRight

                        visible: opacity > 0
                        opacity: launcherMockupContainer.isBarAttached ? 1 : 0
                        width: 14
                        height: 14
                        anchors.top: parent.top
                        anchors.left: launcherMockupContainer.right
                        anchors.leftMargin: -1
                        color: launcherMockupCard.color
                        position: "topLeft"
                        z: 7

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: previewCard.nextScenario()
                    }

                }

            }

        }

    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 175
        radius: 14
        color: root.surface

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                spacing: 8
                Layout.fillWidth: true

                Text {
                    text: "dashboard_customize"
                    font.pixelSize: 14
                    font.family: "Material Symbols Rounded"
                    color: root.color1
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    font.family: "Google Sans"
                    text: qsTr("Launcher Position Mode:")
                    font.pixelSize: 11
                    font.bold: true
                    color: root.textColor
                    Layout.alignment: Qt.AlignVCenter
                }

            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    readonly property bool isSelected: !Config.cfg || !Config.cfg.launcherPosition || Config.cfg.launcherPosition === "default" || Config.cfg.launcherPosition === "bar"

                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    radius: 12
                    color: isSelected ? Qt.alpha(root.color1, 0.12) : root.surfaceContainer
                    border.color: isSelected ? root.color1 : Qt.alpha(root.borderCol, 0.25)
                    border.width: isSelected ? 2 : 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            radius: 6
                            color: Qt.alpha("#000000", 0.25)
                            clip: true

                            Rectangle {
                                id: cardMiniBar1

                                anchors.top: parent.top
                                anchors.topMargin: 3
                                anchors.left: parent.left
                                anchors.leftMargin: 6
                                anchors.right: parent.right
                                anchors.rightMargin: 6
                                height: 8
                                radius: 4
                                color: Qt.alpha(root.surface, 0.9)

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 3
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 10
                                    height: 5
                                    radius: 2
                                    color: parent.parent.parent.parent.isSelected ? root.color1 : Qt.alpha(root.textColor, 0.3)
                                }

                            }

                            Rectangle {
                                id: cardMiniLauncher1

                                anchors.top: cardMiniBar1.bottom
                                anchors.topMargin: -1
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 42
                                height: 44
                                radius: 0
                                topLeftRadius: 0
                                topRightRadius: 0
                                bottomLeftRadius: 4
                                bottomRightRadius: 4
                                color: parent.parent.parent.isSelected ? Qt.alpha(root.color1, 0.25) : Qt.alpha(root.surface, 0.95)
                                border.color: parent.parent.parent.isSelected ? root.color1 : Qt.alpha(root.borderCol, 0.4)
                                border.width: 1

                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.leftMargin: 1
                                    anchors.right: parent.right
                                    anchors.rightMargin: 1
                                    height: 2
                                    color: cardMiniLauncher1.color
                                }

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    spacing: 3

                                    Rectangle {
                                        width: parent.width
                                        height: 5
                                        radius: 2
                                        color: Qt.alpha(root.color1, 0.4)
                                    }

                                    Rectangle {
                                        width: parent.width * 0.8
                                        height: 4
                                        radius: 1
                                        color: Qt.alpha(root.textColor, 0.3)
                                    }

                                    Rectangle {
                                        width: parent.width * 0.6
                                        height: 4
                                        radius: 1
                                        color: Qt.alpha(root.textColor, 0.2)
                                    }

                                }

                            }

                            ConcaveCorner {
                                width: 5
                                height: 5
                                anchors.top: cardMiniBar1.bottom
                                anchors.topMargin: -1
                                anchors.right: cardMiniLauncher1.left
                                anchors.rightMargin: -1
                                color: cardMiniLauncher1.color
                                position: "topRight"
                            }

                            ConcaveCorner {
                                width: 5
                                height: 5
                                anchors.top: cardMiniBar1.bottom
                                anchors.topMargin: -1
                                anchors.left: cardMiniLauncher1.right
                                anchors.leftMargin: -1
                                color: cardMiniLauncher1.color
                                position: "topLeft"
                            }

                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            RowLayout {
                                spacing: 4
                                Layout.alignment: Qt.AlignHCenter

                                Text {
                                    text: parent.parent.parent.parent.isSelected ? "check_circle" : "radio_button_unchecked"
                                    font.pixelSize: 11
                                    font.family: "Material Symbols Rounded"
                                    color: parent.parent.parent.parent.isSelected ? root.color1 : root.textMuted
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    font.family: "Google Sans"
                                    text: qsTr("Default")
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: parent.parent.parent.parent.isSelected ? root.color1 : root.textColor
                                    Layout.alignment: Qt.AlignVCenter
                                }

                            }

                            Text {
                                font.family: "Google Sans"
                                text: qsTr("Bar dropdown menu")
                                font.pixelSize: 8
                                color: root.textMuted
                                Layout.alignment: Qt.AlignHCenter
                            }

                        }

                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            MenuService.closeAll();
                            Config.cfg.launcherPosition = "default";
                            Config.save();
                        }
                    }

                }

                Rectangle {
                    readonly property bool isSelected: Config.cfg && (Config.cfg.launcherPosition === "center" || Config.cfg.launcherPosition === "centralizado")

                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    radius: 12
                    color: isSelected ? Qt.alpha(root.color1, 0.12) : root.surfaceContainer
                    border.color: isSelected ? root.color1 : Qt.alpha(root.borderCol, 0.25)
                    border.width: isSelected ? 2 : 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            radius: 6
                            color: Qt.rgba(0, 0, 0, 0.45)
                            clip: true

                            Rectangle {
                                anchors.centerIn: parent
                                width: 48
                                height: 46
                                radius: 5
                                color: parent.parent.parent.isSelected ? Qt.alpha(root.color1, 0.25) : Qt.alpha(root.surface, 0.95)
                                border.color: parent.parent.parent.isSelected ? root.color1 : Qt.alpha(root.borderCol, 0.4)
                                border.width: 1

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    spacing: 3

                                    Rectangle {
                                        width: parent.width
                                        height: 6
                                        radius: 3
                                        color: Qt.alpha(root.color1, 0.4)
                                    }

                                    Rectangle {
                                        width: parent.width * 0.85
                                        height: 4
                                        radius: 1
                                        color: Qt.alpha(root.textColor, 0.3)
                                    }

                                    Rectangle {
                                        width: parent.width * 0.7
                                        height: 4
                                        radius: 1
                                        color: Qt.alpha(root.textColor, 0.2)
                                    }

                                    Rectangle {
                                        width: parent.width * 0.55
                                        height: 4
                                        radius: 1
                                        color: Qt.alpha(root.textColor, 0.2)
                                    }

                                }

                            }

                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            RowLayout {
                                spacing: 4
                                Layout.alignment: Qt.AlignHCenter

                                Text {
                                    text: parent.parent.parent.parent.isSelected ? "check_circle" : "radio_button_unchecked"
                                    font.pixelSize: 11
                                    font.family: "Material Symbols Rounded"
                                    color: parent.parent.parent.parent.isSelected ? root.color1 : root.textMuted
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    font.family: "Google Sans"
                                    text: qsTr("Centralizado")
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: parent.parent.parent.parent.isSelected ? root.color1 : root.textColor
                                    Layout.alignment: Qt.AlignVCenter
                                }

                            }

                            Text {
                                font.family: "Google Sans"
                                text: qsTr("Centered modal dialog")
                                font.pixelSize: 8
                                color: root.textMuted
                                Layout.alignment: Qt.AlignHCenter
                            }

                        }

                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            MenuService.closeAll();
                            Config.cfg.launcherPosition = "centralizado";
                            Config.save();
                        }
                    }

                }

                Rectangle {
                    readonly property bool isSelected: Config.cfg && (Config.cfg.launcherPosition === "zen" || Config.cfg.launcherPosition === "zen mode")

                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    radius: 12
                    color: isSelected ? Qt.alpha(root.color1, 0.12) : root.surfaceContainer
                    border.color: isSelected ? root.color1 : Qt.alpha(root.borderCol, 0.25)
                    border.width: isSelected ? 2 : 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            radius: 6
                            color: Qt.rgba(0, 0, 0, 0.55)
                            clip: true

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.top
                                anchors.topMargin: 8
                                width: 62
                                height: 48
                                radius: 5
                                color: parent.parent.parent.isSelected ? Qt.alpha(root.color1, 0.25) : Qt.alpha(root.surface, 0.95)
                                border.color: parent.parent.parent.isSelected ? root.color1 : Qt.alpha(root.borderCol, 0.4)
                                border.width: 1

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    spacing: 3

                                    Row {
                                        spacing: 2

                                        Rectangle {
                                            width: 4
                                            height: 4
                                            radius: 1
                                            color: root.color1
                                        }

                                        Rectangle {
                                            width: 44
                                            height: 4
                                            radius: 1
                                            color: Qt.alpha(root.textColor, 0.25)
                                        }

                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 1
                                        color: Qt.alpha(root.color1, 0.25)
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 14
                                        radius: 2
                                        color: Qt.alpha(root.color1, 0.15)

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 2

                                            Rectangle {
                                                width: 8
                                                height: 2
                                                color: root.color1
                                            }

                                            Rectangle {
                                                width: 6
                                                height: 2
                                                color: Qt.alpha(root.color1, 0.6)
                                            }

                                        }

                                    }

                                    Row {
                                        spacing: 2

                                        Rectangle {
                                            width: 16
                                            height: 4
                                            radius: 1
                                            color: Qt.alpha(root.textColor, 0.2)
                                        }

                                        Rectangle {
                                            width: 16
                                            height: 4
                                            radius: 1
                                            color: Qt.alpha(root.textColor, 0.2)
                                        }

                                    }

                                }

                            }

                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            RowLayout {
                                spacing: 4
                                Layout.alignment: Qt.AlignHCenter

                                Text {
                                    text: parent.parent.parent.parent.isSelected ? "check_circle" : "radio_button_unchecked"
                                    font.pixelSize: 11
                                    font.family: "Material Symbols Rounded"
                                    color: parent.parent.parent.parent.isSelected ? root.color1 : root.textMuted
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    font.family: "Google Sans"
                                    text: qsTr("Zen Mode")
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: parent.parent.parent.parent.isSelected ? root.color1 : root.textColor
                                    Layout.alignment: Qt.AlignVCenter
                                }

                            }

                            Text {
                                font.family: "Google Sans"
                                text: qsTr("Living palette & dashboard")
                                font.pixelSize: 8
                                color: root.textMuted
                                Layout.alignment: Qt.AlignHCenter
                            }

                        }

                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            MenuService.closeAll();
                            Config.cfg.launcherPosition = "zen mode";
                            Config.save();
                        }
                    }

                }

            }

        }

    }

    SettingCard {
        spacing: 12

        RowLayout {
            spacing: 8
            Layout.fillWidth: true

            Text {
                text: "tune"
                font.pixelSize: 14
                font.family: "Material Symbols Rounded"
                color: root.color1
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                font.family: "Google Sans"
                text: qsTr("Launcher Search & Direct Actions")
                font.pixelSize: 11
                font.bold: true
                color: root.textColor
                Layout.alignment: Qt.AlignVCenter
            }

        }

        SettingToggle {
            icon: "terminal"
            title: qsTr("Show Commands Without Prefix")
            hint: qsTr("Matches system commands automatically as you type without requiring the '>' character")
            checked: !!(Config.cfg && Config.cfg.launcherCommandsNoPrefix)
            onToggled: (newState) => {
                if (Config.cfg) {
                    Config.cfg.launcherCommandsNoPrefix = newState;
                    Config.save();
                }
            }
        }

        SettingDivider {}

        SettingToggle {
            icon: "calculate"
            title: qsTr("Calculator Without Prefix")
            hint: qsTr("Evaluates mathematical formulas directly as you type without requiring the '=' prefix")
            checked: !!(Config.cfg && Config.cfg.launcherCalculatorNoPrefix)
            onToggled: (newState) => {
                if (Config.cfg) {
                    Config.cfg.launcherCalculatorNoPrefix = newState;
                    Config.save();
                }
            }
        }

        SettingDivider {}

        SettingToggle {
            icon: "language"
            title: qsTr("Web Search Without Prefix")
            hint: qsTr("Launches default web browser with query if no applications or commands match, without requiring '?'")
            checked: !!(Config.cfg && Config.cfg.launcherWebSearchNoPrefix)
            onToggled: (newState) => {
                if (Config.cfg) {
                    Config.cfg.launcherWebSearchNoPrefix = newState;
                    Config.save();
                }
            }
        }

    }

}
