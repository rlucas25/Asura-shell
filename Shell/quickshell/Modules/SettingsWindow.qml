import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Asura
import qs.Services

FloatingWindow {
    id: root

    // === SEMANTIC THEME PROPERTIES ===
    property color primary: Colors.cfg.primary
    property color secondary: Colors.cfg.secondary
    property color background: Colors.cfg.base00
    property color surface: Colors.cfg.surface
    property color surfaceContainer: Colors.cfg.base02
    property color borderCol: Colors.cfg.base03
    property color textMuted: Colors.cfg.base04
    property color text: Colors.cfg.base05
    property color textBright: Colors.cfg.base06
    property color on_primary: Colors.cfg.on_primary
    // Compatibility aliases
    property alias color1: root.primary
    property alias color2: root.secondary
    property alias foreground: root.on_primary
    property alias textColor: root.text
    // === STATE PROPERTIES & FLAGS ===
    property bool isOpen: false
    // Animation Properties (GuidePopup inspired)
    property real introBase: 0
    property real introSidebar: 0
    property real introTabs: 0
    property real introContent: 0
    // Navigation tabs: "general" | "theme" | "notifications" | "gtk"
    property string currentTab: "theme"
    // Wallpaper Gallery State
    property bool wallpaperListExpanded: false
    property int wallpaperGalleryHeight: 320
    property var availableWallpapers: []
    // Palette Search & Filtering State
    property string selectedCategory: "all"
    property string paletteSearchQuery: ""
    property bool showAddWidgetModal: false
    property string selectedAddZone: "left"
    // === REACTIVE BASE16 PALETTES COMPUTATION ===
    readonly property var displayedPalettes: {
        var base = (Colors.categories && Colors.categories[root.selectedCategory]) ? Colors.categories[root.selectedCategory] : Colors.availablePalettes;
        if (!base || !Array.isArray(base))
            return [];

        var query = root.paletteSearchQuery.trim().toLowerCase();
        var pinned = [];
        var unpinned = [];
        // Reference pinnedPalettes to ensure reactivity
        var pinnedList = Colors.pinnedPalettes || [];
        for (var i = 0; i < base.length; i++) {
            var item = base[i];
            if (!item)
                continue;

            if (query !== "") {
                var nameMatch = item.name && item.name.toLowerCase().indexOf(query) !== -1;
                var idMatch = item.id && item.id.toLowerCase().indexOf(query) !== -1;
                if (!nameMatch && !idMatch)
                    continue;

            }
            if (Colors.isPinned(item.id))
                pinned.push(item);
            else
                unpinned.push(item);
        }
        return pinned.concat(unpinned);
    }

    function getTabProgress(idx) {
        if (introTabs >= 1)
            return 1;

        if (introTabs <= 0)
            return 0;

        let start = idx * 0.06;
        let p = Math.min(1, Math.max(0, (introTabs - start) / 0.42));
        if (p <= 0)
            return 0;

        if (p >= 1)
            return 1;

        let c1 = 0.85;
        let c3 = c1 + 1;
        return 1 + c3 * Math.pow(p - 1, 3) + c1 * Math.pow(p - 1, 2);
    }

    function getTabOpacity(idx) {
        if (introTabs >= 1)
            return 1;

        if (introTabs <= 0)
            return 0;

        let start = idx * 0.06;
        let p = Math.min(1, Math.max(0, (introTabs - start) / 0.28));
        return p;
    }

    function resetAndPlayIntro() {
        introBase = 0;
        introSidebar = 0;
        introTabs = 0;
        introContent = 0;
        startupSequence.restart();
    }

    function openWindow() {
        if (closeSequence.running)
            closeSequence.stop();

        root.isOpen = true;
        focusTimer.restart();
        resetAndPlayIntro();
    }

    function closeWindow() {
        if (root.isOpen && !closeSequence.running)
            closeSequence.restart();

    }

    // === HELPER METHODS ===
    function openNwgLook() {
        nwgLookProc.running = false;
        nwgLookProc.running = true;
    }

    function refreshWallpapers() {
        if (!wpListProc.running)
            wpListProc.running = true;

    }

    function playTestSound() {
        var sound = Config.cfg.notificationSound || "message.oga";
        var soundPath = sound.startsWith("/") ? sound : ("/usr/share/sounds/freedesktop/stereo/" + sound);
        playSoundProc.command = ["paplay", soundPath];
        playSoundProc.running = false;
        playSoundProc.running = true;
    }

    function resetDefaults() {
        Config.cfg.theme = "primer-dark-dimmed";
        Config.cfg.colorsAutoGenerate = true;
        Config.cfg.isDarkMode = true;
        Config.cfg.barMode = 0;
        Config.cfg.exclusiveMode = true;
        Config.cfg.autoHide = false;
        Config.cfg.opacity = 0.85;
        Config.cfg.widthS = 0.85;
        Config.cfg.wallpaperFolder = "/Pictures/Wallpapers";
        Config.cfg.soundEffects = true;
        Config.cfg.alertsPopups = true;
        Config.cfg.notificationSound = "message.oga";
        Config.cfg.workspacesCount = 3;
        Config.cfg.workspacesShowNumbers = true;
        Config.cfg.workspacesNumberStyle = "roman";
        Config.cfg.recordingsFolder = "~/Videos/Recordings";
        Config.save();
        Colors.loadPalette("primer-dark-dimmed");
    }

    // === OBJECT GEOMETRY & WINDOW SETUP ===
    title: "Shell Settings"
    implicitWidth: 1200
    implicitHeight: 700
    color: Colors.cfg.base00
    visible: isOpen
    onIsOpenChanged: {
        if (isOpen) {
            focusTimer.restart();
            resetAndPlayIntro();
        } else {
            startupSequence.stop();
            closeSequence.stop();
            introBase = 0;
            introSidebar = 0;
            introTabs = 0;
            introContent = 0;
        }
    }
    onCurrentTabChanged: {
        if (typeof contentFlickable !== "undefined" && contentFlickable)
            contentFlickable.contentY = 0;

        if (typeof tabSwitchAnim !== "undefined" && tabSwitchAnim)
            tabSwitchAnim.restart();

        if (typeof tabSlideAnim !== "undefined" && tabSlideAnim)
            tabSlideAnim.restart();

    }
    Component.onCompleted: {
        refreshWallpapers();
    }
    Component.onDestruction: {
        wpListProc.running = false;
        reloadShellProc.running = false;
        nwgLookProc.running = false;
        importWpProc.running = false;
        selectFolderProc.running = false;
        selectRecordingsFolderProc.running = false;
    }

    Timer {
        id: focusTimer

        interval: 50
        repeat: false
        onTriggered: {
            if (typeof windowContentWrapper !== "undefined" && windowContentWrapper)
                windowContentWrapper.forceActiveFocus();

        }
    }

    ParallelAnimation {
        id: startupSequence

        running: false

        NumberAnimation {
            target: root
            property: "introBase"
            from: 0
            to: 1
            duration: 650
            easing.type: Easing.OutExpo
        }

        SequentialAnimation {
            PauseAnimation {
                duration: 60
            }

            NumberAnimation {
                target: root
                property: "introSidebar"
                from: 0
                to: 1
                duration: 400
                easing.type: Easing.OutCubic
            }

        }

        SequentialAnimation {
            PauseAnimation {
                duration: 100
            }

            NumberAnimation {
                target: root
                property: "introTabs"
                from: 0
                to: 1
                duration: 550
                easing.type: Easing.Linear
            }

        }

        SequentialAnimation {
            PauseAnimation {
                duration: 180
            }

            NumberAnimation {
                target: root
                property: "introContent"
                from: 0
                to: 1
                duration: 650
                easing.type: Easing.OutCubic
            }

        }

    }

    SequentialAnimation {
        id: closeSequence

        running: false

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "introContent"
                to: 0
                duration: 150
                easing.type: Easing.InExpo
            }

            NumberAnimation {
                target: root
                property: "introSidebar"
                to: 0
                duration: 150
                easing.type: Easing.InExpo
            }

            NumberAnimation {
                target: root
                property: "introTabs"
                to: 0
                duration: 120
                easing.type: Easing.InQuad
            }

        }

        NumberAnimation {
            target: root
            property: "introBase"
            to: 0
            duration: 200
            easing.type: Easing.InQuart
        }

        ScriptAction {
            script: {
                root.isOpen = false;
            }
        }

    }

    // === IPC & SERVICES ===
    IpcHandler {
        function toggle() {
            if (root.isOpen)
                root.closeWindow();
            else
                root.openWindow();
        }

        function open() {
            root.openWindow();
        }

        function close() {
            root.closeWindow();
        }

        target: "settings"
    }

    WallpaperService {
        id: wallpaperService
    }

    // External process launchers
    Process {
        id: reloadShellProc

        command: ["sh", "-c", "quickshell kill && quickshell -d"]
    }

    Process {
        id: playSoundProc

        command: []
    }

    Process {
        id: nwgLookProc

        command: ["nwg-look"]
    }

    // Wallpaper list scanner process
    Process {
        id: wpListProc

        command: ["python3", Quickshell.shellPath ? Quickshell.shellPath("Services/wallpaper_list.py") : (Quickshell.env("HOME") + "/.config/quickshell/Services/wallpaper_list.py"), Config.cfg.wallpaperFolder]

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "")
                    return ;

                try {
                    var data = JSON.parse(text.trim());
                    if (Array.isArray(data.wallpapers))
                        root.availableWallpapers = data.wallpapers;

                } catch (e) {
                    console.warn("Error parsing wallpapers:", e);
                }
            }
        }

    }

    // Manual wallpaper file picker process (zenity)
    Process {
        id: importWpProc

        command: ["zenity", "--file-selection", "--title=Select Wallpaper", "--file-filter=Images | *.jpg *.jpeg *.png *.webp *.bmp *.svg"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "")
                    return ;

                var chosenPath = text.trim();
                Config.cfg.wallpaper = chosenPath;
                Config.save();
                if (Config.cfg.colorsAutoGenerate)
                    Colors.generateMatugenColors(chosenPath, Config.cfg.isDarkMode, Config.cfg.scheme);

                root.refreshWallpapers();
            }
        }

    }

    // Wallpaper folder picker process (zenity)
    Process {
        id: selectFolderProc

        command: ["zenity", "--file-selection", "--directory", "--title=Select Wallpaper Folder"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "")
                    return ;

                var folderPath = text.trim();
                var home = Quickshell.env("HOME");
                if (folderPath.startsWith(home))
                    folderPath = folderPath.substring(home.length);

                Config.cfg.wallpaperFolder = folderPath;
                Config.save();
                root.refreshWallpapers();
            }
        }

    }

    Process {
        id: selectRecordingsFolderProc

        command: ["zenity", "--file-selection", "--directory", "--title=Select Screen Recordings Folder"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "")
                    return ;

                var folderPath = text.trim();
                var home = Quickshell.env("HOME");
                if (folderPath.startsWith(home))
                    folderPath = "~" + folderPath.substring(home.length);

                Config.cfg.recordingsFolder = folderPath;
                Config.save();
            }
        }

    }

    // === VISUAL CONTAINER & LAYOUT ===
    Item {
        id: windowContentWrapper

        anchors.fill: parent
        focus: true
        opacity: root.introBase
        scale: 0.95 + (0.05 * root.introBase)
        Keys.onEscapePressed: (event) => {
            root.closeWindow();
            event.accepted = true;
        }

        Rectangle {
            anchors.fill: parent
            color: root.background

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Top titlebar
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    color: root.surface

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        spacing: 12

                        Rectangle {
                            implicitWidth: 32
                            implicitHeight: 32
                            radius: 16
                            color: Qt.alpha(root.color1, 0.2)

                            Text {
                                anchors.centerIn: parent
                                text: "󰒓"
                                font.pixelSize: 16
                                font.family: "GeistMono Nerd Font Propo Propo"
                                color: root.color1
                            }

                        }

                        ColumnLayout {
                            spacing: 1

                            Text {
                                text: qsTr("Shell Settings")
                                font.pixelSize: 13
                                font.bold: true
                                color: root.textColor
                            }

                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        // Close Window Button
                        Rectangle {
                            implicitWidth: 30
                            implicitHeight: 30
                            radius: 15
                            color: winCloseH.hovered ? Qt.alpha(Colors.cfg.warning, 0.25) : Qt.alpha(root.textColor, 0.06)
                            scale: winCloseMa.pressed ? 0.92 : 1

                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                font.pixelSize: 14
                                color: winCloseH.hovered ? Colors.cfg.warning : root.textColor

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }

                                }

                            }

                            HoverHandler {
                                id: winCloseH
                            }

                            MouseArea {
                                id: winCloseMa

                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.closeWindow()
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

                // Main body: Sidebar navigation + scrollable content area
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    // === SIDEBAR NAVIGATION ===
                    Rectangle {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 240
                        color: root.surface
                        opacity: root.introSidebar

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            // Container for tabs with animated highlight pill
                            Item {
                                Layout.fillWidth: true
                                implicitHeight: tabsCol.implicitHeight

                                // Active indicator pill (GuidePopup style)
                                Rectangle {
                                    id: activeHighlight

                                    readonly property int activeIndex: {
                                        if (root.currentTab === "theme")
                                            return 0;

                                        if (root.currentTab === "general")
                                            return 1;

                                        if (root.currentTab === "notifications")
                                            return 2;

                                        if (root.currentTab === "gtk")
                                            return 3;

                                        return 0;
                                    }

                                    z: 0
                                    radius: 24
                                    color: root.color1
                                    width: parent.width
                                    height: 48
                                    y: activeIndex * (48 + tabsCol.spacing)
                                    opacity: root.introTabs > 0.05 ? 1 : 0

                                    transform: Translate {
                                        x: -24 * (1 - root.getTabProgress(activeHighlight.activeIndex))
                                    }

                                    Behavior on y {
                                        NumberAnimation {
                                            duration: 320
                                            easing.type: Easing.OutQuint
                                        }

                                    }

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 200
                                        }

                                    }

                                }

                                ColumnLayout {
                                    id: tabsCol

                                    anchors.fill: parent
                                    spacing: 12
                                    z: 1

                                    // Nav 1: Theme
                                    Rectangle {
                                        id: tabTheme

                                        readonly property bool isActive: root.currentTab === "theme"

                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 48
                                        radius: 24
                                        opacity: root.getTabOpacity(1)
                                        color: tabTMa.containsMouse && !isActive ? root.surfaceContainer : "transparent"
                                        scale: tabTMa.pressed ? 0.98 : 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16
                                            anchors.rightMargin: 16
                                            spacing: 16

                                            Text {
                                                text: "󰏘"
                                                font.pixelSize: 17
                                                color: tabTheme.isActive ? root.foreground : root.color1

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 150
                                                    }

                                                }

                                            }

                                            Text {
                                                text: qsTr("Theme")
                                                font.pixelSize: 13
                                                font.bold: tabTheme.isActive
                                                color: tabTheme.isActive ? root.foreground : (tabTMa.containsMouse ? root.textBright : root.textColor)
                                                Layout.fillWidth: true

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 150
                                                    }

                                                }

                                            }

                                        }

                                        MouseArea {
                                            id: tabTMa

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.currentTab = "theme"
                                        }

                                        transform: Translate {
                                            x: -24 * (1 - root.getTabProgress(1))
                                        }

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 150
                                            }

                                        }

                                        Behavior on scale {
                                            NumberAnimation {
                                                duration: 250
                                                easing.type: Easing.OutQuint
                                            }

                                        }

                                    }

                                    // Nav 2: General & Bar
                                    Rectangle {
                                        id: tabGeneral

                                        readonly property bool isActive: root.currentTab === "general"

                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 48
                                        radius: 24
                                        opacity: root.getTabOpacity(0)
                                        color: tabGMa.containsMouse && !isActive ? root.surfaceContainer : "transparent"
                                        scale: tabGMa.pressed ? 0.98 : 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16
                                            anchors.rightMargin: 16
                                            spacing: 16

                                            Text {
                                                text: "󱔓"
                                                font.pixelSize: 17
                                                color: tabGeneral.isActive ? root.foreground : root.color1

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 150
                                                    }

                                                }

                                            }

                                            Text {
                                                text: qsTr("Bar")
                                                font.pixelSize: 13
                                                font.bold: tabGeneral.isActive
                                                color: tabGeneral.isActive ? root.foreground : (tabGMa.containsMouse ? root.textBright : root.textColor)
                                                Layout.fillWidth: true

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 150
                                                    }

                                                }

                                            }

                                        }

                                        MouseArea {
                                            id: tabGMa

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.currentTab = "general"
                                        }

                                        transform: Translate {
                                            x: -24 * (1 - root.getTabProgress(0))
                                        }

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 150
                                            }

                                        }

                                        Behavior on scale {
                                            NumberAnimation {
                                                duration: 250
                                                easing.type: Easing.OutQuint
                                            }

                                        }

                                    }

                                    // Nav 3: Notifications & Sound
                                    Rectangle {
                                        id: tabNotifications

                                        readonly property bool isActive: root.currentTab === "notifications"

                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 48
                                        radius: 24
                                        opacity: root.getTabOpacity(2)
                                        color: tabNMa.containsMouse && !isActive ? root.surfaceContainer : "transparent"
                                        scale: tabNMa.pressed ? 0.98 : 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16
                                            anchors.rightMargin: 16
                                            spacing: 16

                                            Text {
                                                text: "󰂚"
                                                font.pixelSize: 17
                                                color: tabNotifications.isActive ? root.foreground : root.color1

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 150
                                                    }

                                                }

                                            }

                                            Text {
                                                text: qsTr("Notifications & Sound")
                                                font.pixelSize: 13
                                                font.bold: tabNotifications.isActive
                                                color: tabNotifications.isActive ? root.foreground : (tabNMa.containsMouse ? root.textBright : root.textColor)
                                                Layout.fillWidth: true

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 150
                                                    }

                                                }

                                            }

                                        }

                                        MouseArea {
                                            id: tabNMa

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.currentTab = "notifications"
                                        }

                                        transform: Translate {
                                            x: -24 * (1 - root.getTabProgress(2))
                                        }

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 150
                                            }

                                        }

                                        Behavior on scale {
                                            NumberAnimation {
                                                duration: 250
                                                easing.type: Easing.OutQuint
                                            }

                                        }

                                    }

                                    // Nav 4: GTK Settings
                                    Rectangle {
                                        id: tabGtk

                                        readonly property bool isActive: root.currentTab === "gtk"

                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 48
                                        radius: 24
                                        opacity: root.getTabOpacity(3)
                                        color: tabKMa.containsMouse && !isActive ? root.surfaceContainer : "transparent"
                                        scale: tabKMa.pressed ? 0.98 : 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16
                                            anchors.rightMargin: 16
                                            spacing: 16

                                            Text {
                                                text: "󰒓"
                                                font.pixelSize: 17
                                                color: tabGtk.isActive ? root.foreground : root.color1

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 150
                                                    }

                                                }

                                            }

                                            Text {
                                                text: qsTr("GTK Settings")
                                                font.pixelSize: 13
                                                font.bold: tabGtk.isActive
                                                color: tabGtk.isActive ? root.foreground : (tabKMa.containsMouse ? root.textBright : root.textColor)
                                                Layout.fillWidth: true

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 150
                                                    }

                                                }

                                            }

                                            Text {
                                                text: "󰌹"
                                                font.pixelSize: 14
                                                color: tabGtk.isActive ? root.foreground : Qt.alpha(root.textColor, 0.4)

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 150
                                                    }

                                                }

                                            }

                                        }

                                        MouseArea {
                                            id: tabKMa

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.currentTab = "gtk"
                                        }

                                        transform: Translate {
                                            x: -24 * (1 - root.getTabProgress(3))
                                        }

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 150
                                            }

                                        }

                                        Behavior on scale {
                                            NumberAnimation {
                                                duration: 250
                                                easing.type: Easing.OutQuint
                                            }

                                        }

                                    }

                                }

                            }

                            Item {
                                Layout.fillHeight: true
                            }

                            // Quick Reload Button
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                radius: 20
                                color: relMa.containsMouse ? root.surfaceContainer : "transparent"
                                opacity: root.getTabOpacity(4)
                                scale: relMa.pressed ? 0.98 : 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Text {
                                        text: "󰑐"
                                        font.pixelSize: 15
                                        color: root.color1
                                    }

                                    Text {
                                        text: qsTr("Reload Shell")
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: relMa.containsMouse ? root.textBright : root.textColor
                                    }

                                }

                                MouseArea {
                                    id: relMa

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: reloadShellProc.running = true
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }

                                }

                                transform: Translate {
                                    x: -24 * (1 - root.getTabProgress(4))
                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 200
                                    }

                                }

                            }

                        }

                        transform: Translate {
                            x: -30 * (1 - root.introSidebar)
                        }

                    }

                    // === SCROLLABLE CONTENT AREA ===
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "transparent"
                        opacity: root.introContent
                        scale: 0.97 + (0.03 * root.introContent)

                        Flickable {
                            id: contentFlickable

                            anchors.fill: parent
                            anchors.margins: 20
                            contentHeight: contentCol.implicitHeight
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            ColumnLayout {
                                // === TAB 1: THEME ===
                                // === TAB 2: GENERAL & BAR ===
                                // === TAB 3: NOTIFICATIONS & SOUND ===
                                // === TAB 4: GTK SETTINGS ===

                                id: contentCol

                                width: parent.width
                                spacing: 16
                                opacity: 1

                                NumberAnimation {
                                    id: tabSwitchAnim

                                    target: contentCol
                                    property: "opacity"
                                    from: 0
                                    to: 1
                                    duration: 300
                                    easing.type: Easing.OutCubic
                                }

                                NumberAnimation {
                                    id: tabSlideAnim

                                    target: tabTranslate
                                    property: "y"
                                    from: 16
                                    to: 0
                                    duration: 320
                                    easing.type: Easing.OutCubic
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 14
                                    visible: root.currentTab === "theme"

                                    Text {
                                        text: qsTr("Theme & Wallpaper Appearance")
                                        font.pixelSize: 15
                                        font.bold: true
                                        color: root.textColor
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 12

                                        // Current wallpaper preview thumbnail
                                        Item {
                                            Layout.preferredWidth: parent.width * (2 / 3)
                                            Layout.preferredHeight: Layout.preferredWidth * (9 / 16)
                                            Layout.alignment: Qt.AlignLeft

                                            Rectangle {
                                                anchors.fill: parent
                                                radius: 20
                                                color: root.surfaceContainer
                                            }

                                            Image {
                                                id: wallpaperThumbnail

                                                anchors.fill: parent
                                                source: Config.cfg.wallpaper ? ("file://" + Config.cfg.wallpaper) : ""
                                                fillMode: Image.PreserveAspectCrop
                                                asynchronous: true
                                                visible: false
                                            }

                                            OpacityMask {
                                                anchors.fill: wallpaperThumbnail
                                                source: wallpaperThumbnail

                                                maskSource: Rectangle {
                                                    width: wallpaperThumbnail.width
                                                    height: wallpaperThumbnail.height
                                                    radius: 20
                                                }

                                            }

                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Layout.alignment: Qt.AlignTop
                                            spacing: 8

                                            RowLayout {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 80
                                                spacing: 8

                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    radius: 16
                                                    color: !Config.cfg.isDarkMode ? root.primary : root.surface

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            if (Config.cfg.isDarkMode) {
                                                                Config.cfg.isDarkMode = false;
                                                                Config.save();
                                                                if (Config.cfg.colorsAutoGenerate && Config.cfg.wallpaper)
                                                                    Colors.generateMatugenColors(Config.cfg.wallpaper, false, Config.cfg.scheme);

                                                            }
                                                        }
                                                    }

                                                    ColumnLayout {
                                                        anchors.centerIn: parent
                                                        spacing: 4

                                                        Text {
                                                            text: ""
                                                            Layout.alignment: Qt.AlignHCenter
                                                            color: !Config.cfg.isDarkMode ? root.surfaceContainer : root.textColor
                                                        }

                                                        Text {
                                                            text: "Light"
                                                            Layout.alignment: Qt.AlignHCenter
                                                            color: !Config.cfg.isDarkMode ? root.surfaceContainer : root.textColor
                                                            font.pixelSize: 12
                                                        }

                                                    }

                                                }

                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    radius: 16
                                                    color: Config.cfg.isDarkMode ? root.primary : root.surfaceContainer

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            if (!Config.cfg.isDarkMode) {
                                                                Config.cfg.isDarkMode = true;
                                                                Config.save();
                                                                if (Config.cfg.colorsAutoGenerate && Config.cfg.wallpaper)
                                                                    Colors.generateMatugenColors(Config.cfg.wallpaper, true, Config.cfg.scheme);

                                                            }
                                                        }
                                                    }

                                                    ColumnLayout {
                                                        anchors.centerIn: parent
                                                        spacing: 4

                                                        Text {
                                                            text: ""
                                                            Layout.alignment: Qt.AlignHCenter
                                                            color: Config.cfg.isDarkMode ? root.surfaceContainer : root.textColor
                                                        }

                                                        Text {
                                                            text: "Dark"
                                                            Layout.alignment: Qt.AlignHCenter
                                                            color: Config.cfg.isDarkMode ? root.surfaceContainer : root.textColor
                                                            font.pixelSize: 12
                                                        }

                                                    }

                                                }

                                            }

                                            Item {
                                                Layout.fillHeight: true
                                            }

                                        }

                                    }

                                    // === WALLPAPER SELECTOR (ACCORDION) ===
                                    Rectangle {
                                        Layout.fillWidth: true
                                        radius: 14
                                        color: root.surface
                                        border.color: root.wallpaperListExpanded ? root.color1 : Qt.alpha(root.textColor, 0.08)
                                        border.width: root.wallpaperListExpanded ? 2 : 1
                                        clip: true
                                        implicitHeight: wpSelectorCol.implicitHeight

                                        ColumnLayout {
                                            id: wpSelectorCol

                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            spacing: 0

                                            // Header Row (Clickable Accordion Trigger)
                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 74
                                                color: "transparent"

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.margins: 12
                                                    spacing: 12

                                                    ColumnLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 2

                                                        RowLayout {
                                                            spacing: 6

                                                            Text {
                                                                text: qsTr("Wallpaper Selector")
                                                                font.pixelSize: 12
                                                                font.bold: true
                                                                color: root.textColor
                                                            }

                                                            Rectangle {
                                                                implicitWidth: wpCountBadge.implicitWidth + 8
                                                                implicitHeight: 16
                                                                radius: 8
                                                                color: Qt.alpha(root.color1, 0.2)

                                                                Text {
                                                                    id: wpCountBadge

                                                                    anchors.centerIn: parent
                                                                    text: root.availableWallpapers.length + " files"
                                                                    font.pixelSize: 9
                                                                    color: root.color1
                                                                }

                                                            }

                                                        }

                                                        Text {
                                                            text: Config.cfg.wallpaper ? Config.cfg.wallpaper.split('/').pop() : qsTr("No wallpaper selected")
                                                            font.pixelSize: 10
                                                            color: root.textMuted
                                                            elide: Text.ElideMiddle
                                                        }

                                                    }

                                                    // Import Wallpaper manually button (direct shortcut in header)
                                                    Rectangle {
                                                        implicitWidth: 140
                                                        implicitHeight: 30
                                                        radius: 8
                                                        color: wpImportH.hovered ? Qt.alpha(root.color1, 0.25) : root.surfaceContainer

                                                        RowLayout {
                                                            anchors.centerIn: parent
                                                            spacing: 6

                                                            Text {
                                                                text: "󰋩"
                                                                font.pixelSize: 12
                                                                color: root.color1
                                                            }

                                                            Text {
                                                                text: qsTr("Import Manually")
                                                                font.pixelSize: 10
                                                                font.bold: true
                                                                color: root.textColor
                                                            }

                                                        }

                                                        HoverHandler {
                                                            id: wpImportH
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: importWpProc.running = true
                                                        }

                                                    }

                                                    // Expand / Collapse Chevron Indicator
                                                    Rectangle {
                                                        implicitWidth: 32
                                                        implicitHeight: 32
                                                        radius: 16
                                                        color: expandChevH.hovered ? root.surfaceContainer : "transparent"

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: root.wallpaperListExpanded ? "󰅃" : "󰅀"
                                                            font.pixelSize: 16
                                                            color: root.wallpaperListExpanded ? root.color1 : root.textColor
                                                        }

                                                        HoverHandler {
                                                            id: expandChevH
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: root.wallpaperListExpanded = !root.wallpaperListExpanded
                                                        }

                                                    }

                                                }

                                                // Clickable background to expand/collapse
                                                MouseArea {
                                                    anchors.fill: parent
                                                    z: -1
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.wallpaperListExpanded = !root.wallpaperListExpanded
                                                }

                                            }

                                            // Expandable Wallpapers Gallery Body
                                            Item {
                                                Layout.fillWidth: true
                                                visible: root.wallpaperListExpanded
                                                implicitHeight: root.wallpaperListExpanded ? (root.height / 2) : 0
                                                clip: true

                                                ColumnLayout {
                                                    anchors.fill: parent
                                                    anchors.margins: 12
                                                    spacing: 10

                                                    // Gallery Controls Bar
                                                    RowLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 8

                                                        Text {
                                                            text: qsTr("Wallpapers List:")
                                                            font.pixelSize: 11
                                                            font.bold: true
                                                            color: root.textColor
                                                            Layout.fillWidth: true
                                                        }

                                                        // Refresh list button
                                                        Rectangle {
                                                            implicitWidth: 80
                                                            implicitHeight: 26
                                                            radius: 6
                                                            color: wpRefH.hovered ? Qt.alpha(root.color1, 0.25) : root.surfaceContainer

                                                            RowLayout {
                                                                anchors.centerIn: parent
                                                                spacing: 4

                                                                Text {
                                                                    text: "󰑐"
                                                                    font.pixelSize: 10
                                                                    color: root.color1
                                                                }

                                                                Text {
                                                                    text: qsTr("Refresh")
                                                                    font.pixelSize: 10
                                                                    font.bold: true
                                                                    color: root.textColor
                                                                }

                                                            }

                                                            HoverHandler {
                                                                id: wpRefH
                                                            }

                                                            MouseArea {
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: root.refreshWallpapers()
                                                            }

                                                        }

                                                    }

                                                    // Scrollable Grid of Wallpapers
                                                    Flickable {
                                                        Layout.fillWidth: true
                                                        Layout.preferredHeight: 460
                                                        contentHeight: wpGrid.implicitHeight
                                                        clip: true
                                                        boundsBehavior: Flickable.StopAtBounds

                                                        GridLayout {
                                                            id: wpGrid

                                                            property int minItemWidth: 200
                                                            property int maxColumns: 6

                                                            width: parent.width
                                                            columns: Math.min(maxColumns, Math.max(1, Math.floor((width + columnSpacing) / (minItemWidth + columnSpacing))))
                                                            columnSpacing: 10
                                                            rowSpacing: 10

                                                            Repeater {
                                                                model: root.availableWallpapers

                                                                delegate: Rectangle {
                                                                    id: wpItemCard

                                                                    required property var modelData

                                                                    Layout.fillWidth: true
                                                                    Layout.preferredHeight: width / 1.8
                                                                    radius: 10
                                                                    color: root.surfaceContainer
                                                                    clip: true

                                                                    Image {
                                                                        anchors.fill: parent
                                                                        source: "file://" + wpItemCard.modelData.path
                                                                        fillMode: Image.PreserveAspectCrop
                                                                        sourceSize: Qt.size(240, 140)
                                                                        asynchronous: true
                                                                    }

                                                                    // Selection badge
                                                                    Rectangle {
                                                                        visible: Config.cfg.wallpaper === modelData.path
                                                                        anchors.top: parent.top
                                                                        anchors.right: parent.right
                                                                        anchors.margins: 6
                                                                        implicitWidth: 20
                                                                        implicitHeight: 20
                                                                        radius: 10
                                                                        color: root.color1

                                                                        Text {
                                                                            anchors.centerIn: parent
                                                                            text: "✓"
                                                                            font.pixelSize: 11
                                                                            font.bold: true
                                                                            color: root.foreground
                                                                        }

                                                                    }

                                                                    // Caption overlay
                                                                    Rectangle {
                                                                        anchors.left: parent.left
                                                                        anchors.right: parent.right
                                                                        anchors.bottom: parent.bottom
                                                                        height: 24
                                                                        color: Qt.alpha("#000000", 0.72)

                                                                        Text {
                                                                            anchors.fill: parent
                                                                            anchors.leftMargin: 6
                                                                            anchors.rightMargin: 6
                                                                            text: wpItemCard.modelData.name
                                                                            font.pixelSize: 9
                                                                            font.bold: true
                                                                            color: "#ffffff"
                                                                            elide: Text.ElideRight
                                                                            verticalAlignment: Text.AlignVCenter
                                                                        }

                                                                    }

                                                                    HoverHandler {
                                                                        id: wpCardH
                                                                    }

                                                                    MouseArea {
                                                                        anchors.fill: parent
                                                                        cursorShape: Qt.PointingHandCursor
                                                                        onClicked: {
                                                                            Config.cfg.wallpaper = wpItemCard.modelData.path;
                                                                            Config.save();
                                                                            if (Config.cfg.colorsAutoGenerate)
                                                                                Colors.generateMatugenColors(wpItemCard.modelData.path, Config.cfg.isDarkMode, Config.cfg.scheme);

                                                                        }
                                                                    }

                                                                }

                                                            }

                                                        }

                                                    }

                                                }

                                            }

                                        }

                                    }

                                    // Wallpaper Folder Configuration
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
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: root.textColor
                                                }

                                                Text {
                                                    text: Quickshell.env("HOME") + (Config.cfg.wallpaperFolder || "/Pictures/Wallpapers")
                                                    font.pixelSize: 10
                                                    color: root.textMuted
                                                    elide: Text.ElideMiddle
                                                }

                                            }

                                            // Browse folder button
                                            Rectangle {
                                                implicitWidth: 90
                                                implicitHeight: 30
                                                radius: 8
                                                color: browseFolH.hovered ? Qt.alpha(root.color1, 0.25) : root.surfaceContainer

                                                RowLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 4

                                                    Text {
                                                        text: "󰉋"
                                                        font.pixelSize: 12
                                                        color: root.color1
                                                    }

                                                    Text {
                                                        text: qsTr("Browse")
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
                                                    onClicked: selectFolderProc.running = true
                                                }

                                            }

                                            // Reset folder button
                                            Rectangle {
                                                implicitWidth: 80
                                                implicitHeight: 30
                                                radius: 8
                                                color: resFolH.hovered ? Qt.alpha(root.color1, 0.25) : root.surfaceContainer

                                                RowLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 4

                                                    Text {
                                                        text: "󰑐"
                                                        font.pixelSize: 10
                                                        color: root.color1
                                                    }

                                                    Text {
                                                        text: qsTr("Default")
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

                                    // Wallpaper Transition Animation
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
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                    color: root.textColor
                                                    Layout.fillWidth: true
                                                }

                                                Text {
                                                    text: (Config.cfg.wallpaperAnimation || "wave").toUpperCase()
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

                                        }

                                    }

                                    // Wallpaper Auto-Theme & Theme Mode
ColumnLayout {
    Layout.fillWidth: true
    spacing: 12

    // Wallpaper Auto-Theme
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 74

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
                    text: qsTr("Wallpaper Auto-Theme")

                    font.pixelSize: 12
                    font.bold: true

                    color: root.textColor
                }

                Text {
                    text: qsTr(
                        "Dynamic Material colors generated from wallpaper"
                    )

                    font.pixelSize: 10

                    color: root.textMuted
                }
            }

            Rectangle {
                id: autoThemeSwitch

                implicitWidth: 52
                implicitHeight: 28

                radius: 14

                color:
                    Config.cfg.colorsAutoGenerate
                        ? root.color1
                        : root.surfaceContainer

                border.width: 1

                border.color:
                    Config.cfg.colorsAutoGenerate
                        ? Qt.alpha(
                            root.color1,
                            0.8
                        )
                        : Qt.alpha(
                            root.textColor,
                            0.12
                        )

                Rectangle {
                    id: autoThemeThumb

                    width: 22
                    height: 22

                    radius: 11

                    anchors.verticalCenter:
                        parent.verticalCenter

                    x:
                        Config.cfg.colorsAutoGenerate
                            ? parent.width -
                              width -
                              3
                            : 3

                    color:
                        Config.cfg.colorsAutoGenerate
                            ? root.foreground
                            : root.textColor

                    Behavior on x {
                        NumberAnimation {
                            duration: 180
                            easing.type:
                                Easing.OutCubic
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent

                    cursorShape:
                        Qt.PointingHandCursor

                    onClicked: {
                        Config.cfg.colorsAutoGenerate =
                            !Config.cfg.colorsAutoGenerate

                        Config.save()

                        if (
                            Config.cfg.colorsAutoGenerate &&
                            Config.cfg.wallpaper
                        ) {
                            Colors.generateMatugenColors(
                                Config.cfg.wallpaper,
                                Config.cfg.isDarkMode,
                                Config.cfg.scheme ||
                                "tonal-spot"
                            )
                        } else if (
                            !Config.cfg.colorsAutoGenerate &&
                            Config.cfg.wallpaper
                        ) {
                            Colors.suggestPaletteFromWallpaper(
                                Config.cfg.wallpaper,
                                Config.cfg.isDarkMode
                            )
                        }
                    }
                }
            }
        }
    }

    // Color Scheme
    Rectangle {
        id: schemeCard

        Layout.fillWidth: true

        radius: 14

        color: root.surface

        visible:
            Config.cfg.colorsAutoGenerate

        Layout.preferredHeight:
            schemeColumn.implicitHeight + 28

        ColumnLayout {
            id: schemeColumn

            anchors.fill: parent
            anchors.margins: 14

            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text:
                        qsTr(
                            "Color Scheme (Matugen)"
                        )

                    font.pixelSize: 12
                    font.bold: true

                    color: root.textColor

                    Layout.fillWidth: true
                }

                Rectangle {
                    implicitHeight: 22

                    implicitWidth:
                        schemeCurrentText.implicitWidth +
                        18

                    radius: 11

                    color:
                        Qt.alpha(
                            root.color1,
                            0.16
                        )

                    border.width: 1

                    border.color:
                        Qt.alpha(
                            root.color1,
                            0.35
                        )

                    Text {
                        id: schemeCurrentText

                        anchors.centerIn: parent

                        text:
                            (
                                Config.cfg.scheme ||
                                "tonal-spot"
                            )

                        font.pixelSize: 9
                        font.bold: true

                        color:
                            root.color1
                    }
                }
            }

            Flow {
                id: schemeFlow

                Layout.fillWidth: true

                spacing: 6

                Repeater {
                    model: [
                        "tonal-spot",
                        "neutral",
                        "monochrome",
                        "vibrant",
                        "expressive",
                        "fidelity",
                        "content",
                        "rainbow",
                        "fruit-salad"
                    ]

                    delegate: Rectangle {
                        id: schemePill

                        required property string modelData

                        readonly property bool isSelected:
                            (
                                Config.cfg.scheme ||
                                "tonal-spot"
                            ) === modelData

                        implicitHeight: 30

                        implicitWidth:
                            schemeLabel.implicitWidth +
                            22

                        radius: 15

                        color:
                            isSelected
                                ? root.color1
                                : (
                                    schemeMouse.containsMouse
                                        ? root.surfaceContainer
                                        : root.surface
                                )

                        border.color:
                            isSelected
                                ? root.color1
                                : Qt.alpha(
                                    root.textColor,
                                    0.1
                                )

                        border.width:
                            isSelected
                                ? 0
                                : 1

                        scale:
                            schemeMouse.pressed
                                ? 0.95
                                : 1.0

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 100

                                easing.type:
                                    Easing.OutQuint
                            }
                        }

                        Text {
                            id: schemeLabel

                            anchors.centerIn: parent

                            text: {
                                switch (modelData) {
                                case "tonal-spot":
                                    return "Tonal Spot"
                                case "fruit-salad":
                                    return "Fruit Salad"
                                default:
                                    return modelData
                                        .charAt(0)
                                        .toUpperCase() +
                                        modelData.slice(1)
                                }
                            }

                            font.pixelSize: 10

                            font.bold:
                                schemePill.isSelected

                            color:
                                schemePill.isSelected
                                    ? root.foreground
                                    : (
                                        schemeMouse.containsMouse
                                            ? root.textBright
                                            : root.textColor
                                    )

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

                            cursorShape:
                                Qt.PointingHandCursor

                            onClicked: {
                                Config.cfg.scheme =
                                    schemePill.modelData

                                Config.save()

                                if (
                                    Config.cfg.colorsAutoGenerate &&
                                    Config.cfg.wallpaper
                                ) {
                                    Colors.generateMatugenColors(
                                        Config.cfg.wallpaper,
                                        Config.cfg.isDarkMode,
                                        schemePill.modelData
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

                                    // Primary Accent Color (Base16 Palette Variations)
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
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: root.textColor
                                                    Layout.fillWidth: true
                                                }

                                                Text {
                                                    text: (Colors.primarySlot || "base0D").toUpperCase()
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                    color: root.color1
                                                }

                                                // Reset Accent Color Button
                                                Rectangle {
                                                    implicitWidth: 80
                                                    implicitHeight: 22
                                                    radius: 5
                                                    color: resAccH.hovered ? Qt.alpha(root.color1, 0.25) : root.surfaceContainer

                                                    RowLayout {
                                                        anchors.centerIn: parent
                                                        spacing: 4

                                                        Text {
                                                            text: "󰑐"
                                                            font.pixelSize: 9
                                                            color: root.color1
                                                        }

                                                        Text {
                                                            text: qsTr("Default")
                                                            font.pixelSize: 9
                                                            font.bold: true
                                                            color: root.textColor
                                                        }

                                                    }

                                                    HoverHandler {
                                                        id: resAccH
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: Colors.setPrimarySlot("base0D")
                                                    }

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
                                                            text: "✓"
                                                            font.pixelSize: 12
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

                                    // Palletes Container
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
                                                    text: "󰏘"
                                                    font.pixelSize: 16
                                                    color: root.color1
                                                }

                                                Text {
                                                    text: qsTr("Base16 Palettes")
                                                    font.pixelSize: 13
                                                    font.bold: true
                                                    color: root.textColor
                                                    Layout.fillWidth: true
                                                }

                                                Text {
                                                    text: parent.parent.parent.isExpanded ? "󰅀" : "󰅂"
                                                    font.pixelSize: 18
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

                                            // Base16 Palettes Search Bar
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
                                                        text: "󰍉"
                                                        font.pixelSize: 14
                                                        color: root.color1
                                                    }

                                                    TextInput {
                                                        id: searchField

                                                        Layout.fillWidth: true
                                                        font.pixelSize: 11
                                                        color: root.textColor
                                                        clip: true
                                                        onTextChanged: root.paletteSearchQuery = text

                                                        Text {
                                                            text: qsTr("Search Base16 palettes")
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
                                                            text: "󰅖"
                                                            font.pixelSize: 11
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

                                            // Category Filter Tabs
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

                                            // Empty State Feedback
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
                                                        text: "󰍉"
                                                        font.pixelSize: 18
                                                        color: root.textMuted
                                                        Layout.alignment: Qt.AlignHCenter
                                                    }

                                                    Text {
                                                        text: qsTr("No palettes found matching your search.")
                                                        font.pixelSize: 11
                                                        color: root.textMuted
                                                        Layout.alignment: Qt.AlignHCenter
                                                    }

                                                }

                                            }

                                            // Palettes Grid
                                            GridView {
                                                id: paletteGrid

                                                Layout.fillWidth: true
                                                Layout.preferredHeight: contentHeight
                                                interactive: false
                                                flickableDirection: Flickable.VerticalFlick
                                                clip: true
                                                cellWidth: Math.floor(width / 3)
                                                cellHeight: 74
                                                visible: root.displayedPalettes.length > 0
                                                model: {
                                                    var currentTheme = Config.cfg.theme;
                                                    var arr = [];
                                                    for (var i = 0; i < root.displayedPalettes.length; i++) {
                                                        arr.push(root.displayedPalettes[i]);
                                                    }
                                                    arr.sort(function(a, b) {
                                                        var aActive = (a.id === currentTheme);
                                                        var bActive = (b.id === currentTheme);
                                                        if (aActive && !bActive)
                                                            return -1;

                                                        if (!aActive && bActive)
                                                            return 1;

                                                        var aPinned = Colors.isPinned(a.id);
                                                        var bPinned = Colors.isPinned(b.id);
                                                        if (aPinned && !bPinned)
                                                            return -1;

                                                        if (!aPinned && bPinned)
                                                            return 1;

                                                        return 0;
                                                    });
                                                    return arr;
                                                }

                                                ScrollBar.vertical: ScrollBar {
                                                    active: true
                                                    policy: ScrollBar.AsNeeded
                                                }

                                                delegate: Rectangle {
                                                    id: palCard

                                                    required property var modelData
                                                    readonly property bool isCardPinned: Colors.isPinned(modelData.id)

                                                    width: paletteGrid.cellWidth - 10
                                                    height: 64
                                                    radius: 12
                                                    color: Config.cfg.theme === modelData.id ? Qt.alpha(modelData.color, 0.18) : root.surface
                                                    border.color: Config.cfg.theme === modelData.id ? modelData.color : (palCardH.hovered ? Qt.alpha(modelData.color, 0.5) : Qt.alpha(root.textColor, 0.08))
                                                    border.width: Config.cfg.theme === modelData.id ? 2 : 1

                                                    RowLayout {
                                                        anchors.fill: parent
                                                        anchors.margins: 10
                                                        spacing: 8

                                                        Rectangle {
                                                            implicitWidth: 32
                                                            implicitHeight: 32
                                                            radius: 16
                                                            color: modelData.bg || "#1e1e2e"
                                                            border.color: modelData.color || "#89b4fa"
                                                            border.width: 2

                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: "󰏘"
                                                                font.pixelSize: 14
                                                                color: modelData.color || "#89b4fa"
                                                            }

                                                        }

                                                        ColumnLayout {
                                                            Layout.fillWidth: true
                                                            spacing: 2

                                                            Text {
                                                                Layout.fillWidth: true
                                                                text: modelData.name || modelData.id
                                                                font.pixelSize: 11
                                                                font.bold: true
                                                                color: root.textColor
                                                                elide: Text.ElideRight
                                                            }

                                                            RowLayout {
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
                                                                        font.pixelSize: 8
                                                                        font.bold: true
                                                                        color: root.textMuted
                                                                    }

                                                                }

                                                                Text {
                                                                    text: "• Base16"
                                                                    font.pixelSize: 9
                                                                    color: root.textMuted
                                                                }

                                                            }

                                                        }

                                                        // Pin Button
                                                        Rectangle {
                                                            implicitWidth: 26
                                                            implicitHeight: 26
                                                            radius: 13
                                                            color: palCard.isCardPinned ? Qt.alpha(root.color1, 0.2) : (pinH.hovered ? root.surfaceContainer : "transparent")
                                                            border.color: palCard.isCardPinned ? Qt.alpha(root.color1, 0.5) : "transparent"
                                                            border.width: 1

                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: palCard.isCardPinned ? "󰐃" : "󰤱"
                                                                font.pixelSize: 12
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

                                                        // Active Checkmark
                                                        Text {
                                                            visible: Config.cfg.theme === modelData.id
                                                            text: "✓"
                                                            font.pixelSize: 14
                                                            font.bold: true
                                                            color: modelData.color || root.color1
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

                                        }

                                    }

                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 14
                                    visible: root.currentTab === "general"

                                    Text {
                                        text: qsTr("General & Bar Configuration")
                                        font.pixelSize: 15
                                        font.bold: true
                                        color: root.textColor
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 110
                                        radius: 14
                                        color: root.surface

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 14
                                            spacing: 10

                                            Text {
                                                text: qsTr("Bar Mode:")
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: root.textColor
                                            }

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 10

                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 48
                                                    radius: 10
                                                    color: Config.cfg.barMode === 0 ? root.color1 : root.surfaceContainer

                                                    ColumnLayout {
                                                        anchors.centerIn: parent
                                                        spacing: 1

                                                        Text {
                                                            text: qsTr("Floating")
                                                            font.pixelSize: 11
                                                            font.bold: true
                                                            color: Config.cfg.barMode === 0 ? root.foreground : root.textColor
                                                            Layout.alignment: Qt.AlignHCenter
                                                        }

                                                        Text {
                                                            text: qsTr("Bar with custom width")
                                                            font.pixelSize: 9
                                                            color: Config.cfg.barMode === 0 ? root.foreground : root.textMuted
                                                            Layout.alignment: Qt.AlignHCenter
                                                        }

                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            Config.cfg.barMode = 0;
                                                            Config.save();
                                                        }
                                                    }

                                                }

                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 48
                                                    radius: 10
                                                    color: Config.cfg.barMode === 1 ? root.color1 : root.surfaceContainer

                                                    ColumnLayout {
                                                        anchors.centerIn: parent
                                                        spacing: 1

                                                        Text {
                                                            text: qsTr("Full Screen (Default)")
                                                            font.pixelSize: 11
                                                            font.bold: true
                                                            color: Config.cfg.barMode === 1 ? root.foreground : root.textColor
                                                            Layout.alignment: Qt.AlignHCenter
                                                        }

                                                        Text {
                                                            text: qsTr("Continuous Bar 100%")
                                                            font.pixelSize: 9
                                                            color: Config.cfg.barMode === 1 ? root.foreground : root.textMuted
                                                            Layout.alignment: Qt.AlignHCenter
                                                        }

                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            Config.cfg.barMode = 1;
                                                            Config.save();
                                                        }
                                                    }

                                                }

                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 48
                                                    radius: 10
                                                    color: Config.cfg.barMode === 2 ? root.color1 : root.surfaceContainer

                                                    ColumnLayout {
                                                        anchors.centerIn: parent
                                                        spacing: 1

                                                        Text {
                                                            text: qsTr("Capsule")
                                                            font.pixelSize: 11
                                                            font.bold: true
                                                            color: Config.cfg.barMode === 2 ? root.foreground : root.textColor
                                                            Layout.alignment: Qt.AlignHCenter
                                                        }

                                                        Text {
                                                            text: qsTr("3 Separate Capsules")
                                                            font.pixelSize: 9
                                                            color: Config.cfg.barMode === 2 ? root.foreground : root.textMuted
                                                            Layout.alignment: Qt.AlignHCenter
                                                        }

                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            Config.cfg.barMode = 2;
                                                            Config.save();
                                                        }
                                                    }

                                                }

                                            }

                                        }

                                    }

                                    // Exclusive Mode
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 68
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
                                                    text: qsTr("Exclusive Mode")
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: root.textColor
                                                }

                                                Text {
                                                    text: qsTr("Reserves a 30px margin at the top of the screen so windows do not overlap the bar")
                                                    font.pixelSize: 10
                                                    color: root.textMuted
                                                }

                                            }

                                            Rectangle {
                                                implicitWidth: 48
                                                implicitHeight: 26
                                                radius: 13
                                                color: Config.cfg.exclusiveMode ? root.color1 : root.surfaceContainer

                                                Rectangle {
                                                    width: 20
                                                    height: 20
                                                    radius: 10
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    x: Config.cfg.exclusiveMode ? parent.width - width - 3 : 3
                                                    color: Config.cfg.exclusiveMode ? root.foreground : root.textColor

                                                    Behavior on x {
                                                        NumberAnimation {
                                                            duration: 150
                                                        }

                                                    }

                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        Config.cfg.exclusiveMode = !Config.cfg.exclusiveMode;
                                                        Config.save();
                                                    }
                                                }

                                            }

                                        }

                                    }

                                    // Auto-Hide Mode
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 68
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
                                                    text: qsTr("Auto-Hide Bar")
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: root.textColor
                                                }

                                                Text {
                                                    text: qsTr("Automatically hides the bar and reveals it when moving cursor to the top edge")
                                                    font.pixelSize: 10
                                                    color: root.textMuted
                                                }

                                            }

                                            Rectangle {
                                                implicitWidth: 48
                                                implicitHeight: 26
                                                radius: 13
                                                color: Config.cfg.autoHide ? root.color1 : root.surfaceContainer

                                                Rectangle {
                                                    width: 20
                                                    height: 20
                                                    radius: 10
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    x: Config.cfg.autoHide ? parent.width - width - 3 : 3
                                                    color: Config.cfg.autoHide ? root.foreground : root.textColor

                                                    Behavior on x {
                                                        NumberAnimation {
                                                            duration: 150
                                                        }

                                                    }

                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        Config.cfg.autoHide = !Config.cfg.autoHide;
                                                        Config.save();
                                                    }
                                                }

                                            }

                                        }

                                    }

                                    // Bar Width (Floating bar mode) (default 85%)
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 82
                                        radius: 14
                                        color: root.surface

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 14
                                            spacing: 8

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 8

                                                Text {
                                                    text: qsTr("Bar Width (Floating bar mode):")
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: root.textColor
                                                    Layout.fillWidth: true
                                                }

                                                Text {
                                                    text: Math.round(Config.cfg.widthS * 100) + "%"
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: root.color1
                                                }

                                                // Quick Reset to Default (85%) Button
                                                Rectangle {
                                                    implicitWidth: 92
                                                    implicitHeight: 24
                                                    radius: 6
                                                    color: resetWidthH.hovered ? Qt.alpha(root.color1, 0.25) : root.surfaceContainer

                                                    RowLayout {
                                                        anchors.centerIn: parent
                                                        spacing: 4

                                                        Text {
                                                            text: "󰑐"
                                                            font.pixelSize: 10
                                                            color: root.color1
                                                        }

                                                        Text {
                                                            text: qsTr("Reset (85%)")
                                                            font.pixelSize: 9
                                                            font.bold: true
                                                            color: root.textColor
                                                        }

                                                    }

                                                    HoverHandler {
                                                        id: resetWidthH
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            Config.cfg.widthS = 0.85;
                                                            Config.save();
                                                        }
                                                    }

                                                }

                                            }

                                            // Interactive Width Slider
                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 16
                                                radius: 8
                                                color: root.surfaceContainer
                                                clip: true

                                                Rectangle {
                                                    anchors.left: parent.left
                                                    anchors.top: parent.top
                                                    anchors.bottom: parent.bottom
                                                    width: parent.width * Math.max(0.4, Math.min(1, Config.cfg.widthS))
                                                    radius: 8
                                                    color: root.color1
                                                }

                                                MouseArea {
                                                    function updateWidth(mx) {
                                                        var v = Math.max(0.4, Math.min(1, mx / width));
                                                        Config.cfg.widthS = Math.round(v * 100) / 100;
                                                        Config.save();
                                                    }

                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: (mouse) => {
                                                        return updateWidth(mouse.x);
                                                    }
                                                    onPositionChanged: (mouse) => {
                                                        if (pressed)
                                                            updateWidth(mouse.x);

                                                    }
                                                }

                                            }

                                        }

                                    }

                                    // Bar Background Opacity
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 82
                                        radius: 14
                                        color: root.surface

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 14
                                            spacing: 8

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 8

                                                Text {
                                                    text: qsTr("Bar Background Opacity:")
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: root.textColor
                                                    Layout.fillWidth: true
                                                }

                                                Text {
                                                    text: Math.round(Config.cfg.opacity * 100) + "%"
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: root.color1
                                                }

                                                // Quick Reset to Default (100%) Button
                                                Rectangle {
                                                    implicitWidth: 92
                                                    implicitHeight: 24
                                                    radius: 6
                                                    color: resetOpH.hovered ? Qt.alpha(root.color1, 0.25) : root.surfaceContainer

                                                    RowLayout {
                                                        anchors.centerIn: parent
                                                        spacing: 4

                                                        Text {
                                                            text: "󰑐"
                                                            font.pixelSize: 10
                                                            color: root.color1
                                                        }

                                                        Text {
                                                            text: qsTr("Reset (100%)")
                                                            font.pixelSize: 9
                                                            font.bold: true
                                                            color: root.textColor
                                                        }

                                                    }

                                                    HoverHandler {
                                                        id: resetOpH
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            Config.cfg.opacity = 1;
                                                            Config.save();
                                                        }
                                                    }

                                                }

                                            }

                                            // Interactive Opacity Slider
                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 16
                                                radius: 8
                                                color: root.surfaceContainer
                                                clip: true

                                                Rectangle {
                                                    anchors.left: parent.left
                                                    anchors.top: parent.top
                                                    anchors.bottom: parent.bottom
                                                    width: parent.width * Math.max(0, Math.min(1, Config.cfg.opacity))
                                                    radius: 8
                                                    color: root.color1
                                                }

                                                MouseArea {
                                                    function updateOp(mx) {
                                                        var v = Math.max(0, Math.min(1, mx / width));
                                                        Config.cfg.opacity = Math.round(v * 100) / 100;
                                                        Config.save();
                                                    }

                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: (mouse) => {
                                                        return updateOp(mouse.x);
                                                    }
                                                    onPositionChanged: (mouse) => {
                                                        if (pressed)
                                                            updateOp(mouse.x);

                                                    }
                                                }

                                            }

                                        }

                                    }

                                    // Widgets Manager
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
                                                        font.pixelSize: 13
                                                        font.bold: true
                                                        color: root.textColor
                                                    }

                                                    Text {
                                                        text: qsTr("Add, reorder, move between capsules, and customize icon visibility")
                                                        font.pixelSize: 10
                                                        color: root.textMuted
                                                    }

                                                }

                                                Rectangle {
                                                    implicitWidth: 140
                                                    implicitHeight: 28
                                                    radius: 8
                                                    color: resetWidgetsH.hovered ? Qt.alpha(root.color1, 0.25) : root.surfaceContainer
                                                    border.color: root.borderCol
                                                    border.width: 1

                                                    RowLayout {
                                                        anchors.centerIn: parent
                                                        spacing: 6

                                                        Text {
                                                            text: "󰑐"
                                                            font.pixelSize: 11
                                                            color: root.color1
                                                        }

                                                        Text {
                                                            text: qsTr("Reset Defaults")
                                                            font.pixelSize: 10
                                                            font.bold: true
                                                            color: root.textColor
                                                        }

                                                    }

                                                    HoverHandler {
                                                        id: resetWidgetsH
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            BarWidgetService.resetToDefaults();
                                                        }
                                                    }

                                                }

                                                Rectangle {
                                                    implicitWidth: 120
                                                    implicitHeight: 28
                                                    radius: 8
                                                    color: root.showAddWidgetModal ? root.color2 : root.color1

                                                    RowLayout {
                                                        anchors.centerIn: parent
                                                        spacing: 6

                                                        Text {
                                                            text: root.showAddWidgetModal ? "󰅖" : "󰐕"
                                                            font.pixelSize: 12
                                                            color: root.foreground
                                                        }

                                                        Text {
                                                            text: root.showAddWidgetModal ? qsTr("Close") : qsTr("Add Widget")
                                                            font.pixelSize: 10
                                                            font.bold: true
                                                            color: root.foreground
                                                        }

                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            root.showAddWidgetModal = !root.showAddWidgetModal;
                                                        }
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
                                                            font.pixelSize: 11
                                                            font.bold: true
                                                            color: root.textColor
                                                        }

                                                        Item {
                                                            Layout.fillWidth: true
                                                        }

                                                        Text {
                                                            text: qsTr("Target Zone:")
                                                            font.pixelSize: 10
                                                            font.bold: true
                                                            color: root.textMuted
                                                        }

                                                        RowLayout {
                                                            spacing: 6

                                                            Rectangle {
                                                                implicitWidth: 70
                                                                implicitHeight: 24
                                                                radius: 6
                                                                color: root.selectedAddZone === "left" ? root.color1 : root.surface
                                                                border.color: root.selectedAddZone === "left" ? root.color1 : root.borderCol
                                                                border.width: 1

                                                                Text {
                                                                    anchors.centerIn: parent
                                                                    text: qsTr("󰁍 Left")
                                                                    font.pixelSize: 9
                                                                    font.bold: true
                                                                    color: root.selectedAddZone === "left" ? root.foreground : root.textColor
                                                                }

                                                                MouseArea {
                                                                    anchors.fill: parent
                                                                    cursorShape: Qt.PointingHandCursor
                                                                    onClicked: root.selectedAddZone = "left"
                                                                }

                                                            }

                                                            Rectangle {
                                                                implicitWidth: 80
                                                                implicitHeight: 24
                                                                radius: 6
                                                                color: root.selectedAddZone === "center" ? root.color1 : root.surface
                                                                border.color: root.selectedAddZone === "center" ? root.color1 : root.borderCol
                                                                border.width: 1

                                                                Text {
                                                                    anchors.centerIn: parent
                                                                    text: qsTr("󰘔 Center")
                                                                    font.pixelSize: 9
                                                                    font.bold: true
                                                                    color: root.selectedAddZone === "center" ? root.foreground : root.textColor
                                                                }

                                                                MouseArea {
                                                                    anchors.fill: parent
                                                                    cursorShape: Qt.PointingHandCursor
                                                                    onClicked: root.selectedAddZone = "center"
                                                                }

                                                            }

                                                            Rectangle {
                                                                implicitWidth: 74
                                                                implicitHeight: 24
                                                                radius: 6
                                                                color: root.selectedAddZone === "right" ? root.color1 : root.surface
                                                                border.color: root.selectedAddZone === "right" ? root.color1 : root.borderCol
                                                                border.width: 1

                                                                Text {
                                                                    anchors.centerIn: parent
                                                                    text: qsTr("󰁔 Right")
                                                                    font.pixelSize: 9
                                                                    font.bold: true
                                                                    color: root.selectedAddZone === "right" ? root.foreground : root.textColor
                                                                }

                                                                MouseArea {
                                                                    anchors.fill: parent
                                                                    cursorShape: Qt.PointingHandCursor
                                                                    onClicked: root.selectedAddZone = "right"
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
                                                                text: "󱊖"
                                                                font.pixelSize: 11
                                                                color: root.color1
                                                            }

                                                            Text {
                                                                text: qsTr("Status Capsule Widgets")
                                                                font.pixelSize: 10
                                                                font.bold: true
                                                                color: root.textColor
                                                            }

                                                            Text {
                                                                text: qsTr("(Groupable into pill capsules)")
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
                                                                                font.pixelSize: 12
                                                                                color: root.color1
                                                                            }

                                                                        }

                                                                        ColumnLayout {
                                                                            Layout.fillWidth: true
                                                                            spacing: 1

                                                                            Text {
                                                                                text: modelData.name
                                                                                font.pixelSize: 10
                                                                                font.bold: true
                                                                                color: root.textColor
                                                                            }

                                                                            Text {
                                                                                text: qsTr("+ Add Instance")
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
                                                                text: "󰘔"
                                                                font.pixelSize: 11
                                                                color: root.color2
                                                            }

                                                            Text {
                                                                text: qsTr("General Icons")
                                                                font.pixelSize: 10
                                                                font.bold: true
                                                                color: root.textColor
                                                            }

                                                            Text {
                                                                text: qsTr("(Standard bar controls)")
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
                                                                                font.pixelSize: 12
                                                                                color: root.color2
                                                                            }

                                                                        }

                                                                        ColumnLayout {
                                                                            Layout.fillWidth: true
                                                                            spacing: 1

                                                                            Text {
                                                                                text: modelData.name
                                                                                font.pixelSize: 10
                                                                                font.bold: true
                                                                                color: root.textColor
                                                                            }

                                                                            Text {
                                                                                text: qsTr("+ Add Instance")
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
                                                    zoneName: "left"
                                                    zoneTitle: qsTr("Left Capsule")
                                                    zoneIcon: "󰁍"
                                                    widgetsList: BarWidgetService.leftWidgets
                                                    Layout.fillWidth: true
                                                    Layout.preferredWidth: 1
                                                    Layout.alignment: Qt.AlignTop
                                                }

                                                ZoneWidgetsColumn {
                                                    zoneName: "center"
                                                    zoneTitle: qsTr("Center Capsule")
                                                    zoneIcon: "󰘔"
                                                    widgetsList: BarWidgetService.centerWidgets
                                                    Layout.fillWidth: true
                                                    Layout.preferredWidth: 1
                                                    Layout.alignment: Qt.AlignTop
                                                }

                                                ZoneWidgetsColumn {
                                                    zoneName: "right"
                                                    zoneTitle: qsTr("Right Capsule")
                                                    zoneIcon: "󰁔"
                                                    widgetsList: BarWidgetService.rightWidgets
                                                    Layout.fillWidth: true
                                                    Layout.preferredWidth: 1
                                                    Layout.alignment: Qt.AlignTop
                                                }

                                            }

                                        }

                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: wsCol.implicitHeight + 28
                                        radius: 14
                                        color: root.surface

                                        ColumnLayout {
                                            id: wsCol

                                            anchors.fill: parent
                                            anchors.margins: 14
                                            spacing: 14

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 8

                                                Text {
                                                    text: "󰮯"
                                                    font.pixelSize: 15
                                                    color: root.color1
                                                }

                                                Text {
                                                    text: qsTr("Workspaces")
                                                    font.pixelSize: 13
                                                    font.bold: true
                                                    color: root.textColor
                                                }

                                                Item {
                                                    Layout.fillWidth: true
                                                }

                                            }

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 8

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 2

                                                    Text {
                                                        text: qsTr("Default Workspaces Count")
                                                        font.pixelSize: 11
                                                        font.bold: true
                                                        color: root.textColor
                                                    }

                                                    Text {
                                                        text: qsTr("Number of default visible workspaces on the bar")
                                                        font.pixelSize: 10
                                                        color: root.textMuted
                                                    }

                                                }

                                                RowLayout {
                                                    spacing: 6

                                                    Rectangle {
                                                        implicitWidth: 28
                                                        implicitHeight: 28
                                                        radius: 6
                                                        color: decWsH.hovered ? Qt.alpha(root.color1, 0.25) : root.surfaceContainer

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: "−"
                                                            font.pixelSize: 14
                                                            font.bold: true
                                                            color: root.textColor
                                                        }

                                                        HoverHandler {
                                                            id: decWsH
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                var current = (Config.cfg && Config.cfg.workspacesCount !== undefined) ? Config.cfg.workspacesCount : 3;
                                                                if (current > 1) {
                                                                    Config.cfg.workspacesCount = current - 1;
                                                                    Config.save();
                                                                }
                                                            }
                                                        }

                                                    }

                                                    Rectangle {
                                                        implicitWidth: 36
                                                        implicitHeight: 28
                                                        radius: 6
                                                        color: root.surfaceContainer

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: ((Config.cfg && Config.cfg.workspacesCount !== undefined) ? Config.cfg.workspacesCount : 3).toString()
                                                            font.pixelSize: 12
                                                            font.bold: true
                                                            color: root.color1
                                                        }

                                                    }

                                                    Rectangle {
                                                        implicitWidth: 28
                                                        implicitHeight: 28
                                                        radius: 6
                                                        color: incWsH.hovered ? Qt.alpha(root.color1, 0.25) : root.surfaceContainer

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: "+"
                                                            font.pixelSize: 14
                                                            font.bold: true
                                                            color: root.textColor
                                                        }

                                                        HoverHandler {
                                                            id: incWsH
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                var current = (Config.cfg && Config.cfg.workspacesCount !== undefined) ? Config.cfg.workspacesCount : 3;
                                                                if (current < 10) {
                                                                    Config.cfg.workspacesCount = current + 1;
                                                                    Config.save();
                                                                }
                                                            }
                                                        }

                                                    }

                                                }

                                            }

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 8

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 2

                                                    Text {
                                                        text: qsTr("Workspace Numbering")
                                                        font.pixelSize: 11
                                                        font.bold: true
                                                        color: root.textColor
                                                    }

                                                    Text {
                                                        text: qsTr("Display numbers inside the active and hovered workspace nodes")
                                                        font.pixelSize: 10
                                                        color: root.textMuted
                                                    }

                                                }

                                                Rectangle {
                                                    implicitWidth: 48
                                                    implicitHeight: 26
                                                    radius: 13
                                                    color: (Config.cfg && Config.cfg.workspacesShowNumbers) ? root.color1 : root.surfaceContainer

                                                    Rectangle {
                                                        width: 20
                                                        height: 20
                                                        radius: 10
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        x: (Config.cfg && Config.cfg.workspacesShowNumbers) ? parent.width - width - 3 : 3
                                                        color: (Config.cfg && Config.cfg.workspacesShowNumbers) ? root.foreground : root.textColor

                                                        Behavior on x {
                                                            NumberAnimation {
                                                                duration: 150
                                                            }

                                                        }

                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            Config.cfg.workspacesShowNumbers = !Config.cfg.workspacesShowNumbers;
                                                            Config.save();
                                                        }
                                                    }

                                                }

                                            }

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 8
                                                visible: Config.cfg && Config.cfg.workspacesShowNumbers

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 2

                                                    Text {
                                                        text: qsTr("Numbering Format")
                                                        font.pixelSize: 11
                                                        font.bold: true
                                                        color: root.textColor
                                                    }

                                                    Text {
                                                        text: qsTr("Choose Roman numerals (I, II, III) or Common numbers (1, 2, 3)")
                                                        font.pixelSize: 10
                                                        color: root.textMuted
                                                    }

                                                }

                                                RowLayout {
                                                    spacing: 6

                                                    Rectangle {
                                                        implicitWidth: 88
                                                        implicitHeight: 28
                                                        radius: 6
                                                        color: (Config.cfg && Config.cfg.workspacesNumberStyle === "roman") ? root.color1 : root.surfaceContainer

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: qsTr("Roman (I, II)")
                                                            font.pixelSize: 10
                                                            font.bold: true
                                                            color: (Config.cfg && Config.cfg.workspacesNumberStyle === "roman") ? root.foreground : root.textColor
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                Config.cfg.workspacesNumberStyle = "roman";
                                                                Config.save();
                                                            }
                                                        }

                                                    }

                                                    Rectangle {
                                                        implicitWidth: 92
                                                        implicitHeight: 28
                                                        radius: 6
                                                        color: (Config.cfg && Config.cfg.workspacesNumberStyle === "common") ? root.color1 : root.surfaceContainer

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: qsTr("Common (1, 2)")
                                                            font.pixelSize: 10
                                                            font.bold: true
                                                            color: (Config.cfg && Config.cfg.workspacesNumberStyle === "common") ? root.foreground : root.textColor
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                Config.cfg.workspacesNumberStyle = "common";
                                                                Config.save();
                                                            }
                                                        }

                                                    }

                                                }

                                            }

                                        }

                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 74
                                        radius: 14
                                        color: root.surface

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 14
                                            spacing: 12

                                            Text {
                                                text: ""
                                                font.pixelSize: 18
                                                font.family: "GeistMono Nerd Font Propo Propo"
                                                color: root.color1
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2

                                                Text {
                                                    text: qsTr("Screen Recordings Folder")
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                    color: root.textColor
                                                }

                                                Text {
                                                    text: (Config.cfg && Config.cfg.recordingsFolder) ? Config.cfg.recordingsFolder : "~/Videos/Recordings"
                                                    font.pixelSize: 10
                                                    color: root.textMuted
                                                    elide: Text.ElideMiddle
                                                    Layout.fillWidth: true
                                                }

                                            }

                                            Rectangle {
                                                implicitWidth: 90
                                                implicitHeight: 30
                                                radius: 8
                                                color: browseRecFolH.hovered ? Qt.alpha(root.color1, 0.25) : root.surfaceContainer

                                                RowLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 4

                                                    Text {
                                                        text: "󰉋"
                                                        font.pixelSize: 12
                                                        color: root.color1
                                                    }

                                                    Text {
                                                        text: qsTr("Browse")
                                                        font.pixelSize: 10
                                                        font.bold: true
                                                        color: root.textColor
                                                    }

                                                }

                                                HoverHandler {
                                                    id: browseRecFolH
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: selectRecordingsFolderProc.running = true
                                                }

                                            }

                                            Rectangle {
                                                implicitWidth: 80
                                                implicitHeight: 30
                                                radius: 8
                                                color: resRecFolH.hovered ? Qt.alpha(root.color1, 0.25) : root.surfaceContainer

                                                RowLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 4

                                                    Text {
                                                        text: "󰑐"
                                                        font.pixelSize: 10
                                                        color: root.color1
                                                    }

                                                    Text {
                                                        text: qsTr("Default")
                                                        font.pixelSize: 10
                                                        font.bold: true
                                                        color: root.textColor
                                                    }

                                                }

                                                HoverHandler {
                                                    id: resRecFolH
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        Config.cfg.recordingsFolder = "~/Videos/Recordings";
                                                        Config.save();
                                                    }
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

                                        radius: 12
                                        color: root.surfaceContainer
                                        border.color: root.borderCol
                                        border.width: 1
                                        implicitHeight: columnLayout.implicitHeight + 24

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
                                                    font.pixelSize: 13
                                                    color: root.color1
                                                }

                                                Text {
                                                    text: zwc.zoneTitle
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
                                                        text: "󰐕"
                                                        font.pixelSize: 11
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
                                                text: qsTr("No widgets. Click + to add.")
                                                font.pixelSize: 10
                                                color: root.textMuted
                                            }

                                            Repeater {
                                                model: zwc.widgetsList

                                                delegate: Rectangle {
                                                    id: itemCard

                                                    required property var modelData
                                                    required property int index

                                                    Layout.fillWidth: true
                                                    implicitHeight: 46
                                                    radius: 8
                                                    color: modelData.visible !== false ? root.surface : Qt.alpha(root.surface, 0.3)
                                                    border.color: itemCardH.hovered ? root.color1 : root.borderCol
                                                    border.width: 1

                                                    HoverHandler {
                                                        id: itemCardH
                                                    }

                                                    RowLayout {
                                                        anchors.fill: parent
                                                        anchors.margins: 6
                                                        spacing: 6

                                                        Rectangle {
                                                            implicitWidth: 20
                                                            implicitHeight: 20
                                                            radius: 5
                                                            color: modelData.visible !== false ? root.color1 : root.surfaceContainer
                                                            border.color: modelData.visible !== false ? root.color1 : root.borderCol
                                                            border.width: 1

                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: modelData.visible !== false ? "󰄲" : "󰄱"
                                                                font.pixelSize: 12
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
                                                            color: modelData.category === "status_capsule" ? Qt.alpha(root.color1, 0.15) : Qt.alpha(root.color2, 0.15)

                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: BarWidgetService.getWidgetInfo(modelData.type).icon
                                                                font.pixelSize: 13
                                                                color: modelData.category === "status_capsule" ? root.color1 : root.color2
                                                            }

                                                        }

                                                        ColumnLayout {
                                                            Layout.fillWidth: true
                                                            spacing: 1

                                                            Text {
                                                                text: BarWidgetService.getWidgetInfo(modelData.type).name
                                                                font.pixelSize: 10
                                                                font.bold: true
                                                                color: modelData.visible !== false ? root.textColor : root.textMuted
                                                                elide: Text.ElideRight
                                                                Layout.fillWidth: true
                                                            }

                                                            Text {
                                                                text: modelData.category === "status_capsule" ? qsTr("Status Capsule") : qsTr("General Icon")
                                                                font.pixelSize: 8
                                                                color: root.textMuted
                                                            }

                                                        }

                                                        RowLayout {
                                                            spacing: 2

                                                            Rectangle {
                                                                implicitWidth: 20
                                                                implicitHeight: 20
                                                                radius: 4
                                                                color: upBtnH.hovered ? root.surfaceContainer : "transparent"
                                                                opacity: index > 0 ? 1 : 0.2

                                                                HoverHandler {
                                                                    id: upBtnH
                                                                }

                                                                Text {
                                                                    anchors.centerIn: parent
                                                                    text: "󰁞"
                                                                    font.pixelSize: 10
                                                                    color: root.textColor
                                                                }

                                                                MouseArea {
                                                                    anchors.fill: parent
                                                                    enabled: index > 0
                                                                    cursorShape: index > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                                    onClicked: {
                                                                        BarWidgetService.moveWidgetUp(zwc.zoneName, index);
                                                                    }
                                                                }

                                                            }

                                                            Rectangle {
                                                                implicitWidth: 20
                                                                implicitHeight: 20
                                                                radius: 4
                                                                color: downBtnH.hovered ? root.surfaceContainer : "transparent"
                                                                opacity: index < zwc.widgetsList.length - 1 ? 1 : 0.2

                                                                HoverHandler {
                                                                    id: downBtnH
                                                                }

                                                                Text {
                                                                    anchors.centerIn: parent
                                                                    text: "󰁆"
                                                                    font.pixelSize: 10
                                                                    color: root.textColor
                                                                }

                                                                MouseArea {
                                                                    anchors.fill: parent
                                                                    enabled: index < zwc.widgetsList.length - 1
                                                                    cursorShape: index < zwc.widgetsList.length - 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                                    onClicked: {
                                                                        BarWidgetService.moveWidgetDown(zwc.zoneName, index);
                                                                    }
                                                                }

                                                            }

                                                            Rectangle {
                                                                visible: zwc.zoneName === "left"
                                                                implicitWidth: 20
                                                                implicitHeight: 20
                                                                radius: 4
                                                                color: toCenterBtnH1.hovered ? Qt.alpha(root.color1, 0.2) : "transparent"

                                                                HoverHandler {
                                                                    id: toCenterBtnH1
                                                                }

                                                                Text {
                                                                    anchors.centerIn: parent
                                                                    text: "󰁔"
                                                                    font.pixelSize: 10
                                                                    color: root.textColor
                                                                }

                                                                MouseArea {
                                                                    anchors.fill: parent
                                                                    cursorShape: Qt.PointingHandCursor
                                                                    onClicked: {
                                                                        BarWidgetService.transferWidget(modelData.id, "left", "center");
                                                                    }
                                                                }

                                                            }

                                                            Rectangle {
                                                                visible: zwc.zoneName === "center"
                                                                implicitWidth: 20
                                                                implicitHeight: 20
                                                                radius: 4
                                                                color: toLeftBtnH.hovered ? Qt.alpha(root.color1, 0.2) : "transparent"

                                                                HoverHandler {
                                                                    id: toLeftBtnH
                                                                }

                                                                Text {
                                                                    anchors.centerIn: parent
                                                                    text: "󰁍"
                                                                    font.pixelSize: 10
                                                                    color: root.textColor
                                                                }

                                                                MouseArea {
                                                                    anchors.fill: parent
                                                                    cursorShape: Qt.PointingHandCursor
                                                                    onClicked: {
                                                                        BarWidgetService.transferWidget(modelData.id, "center", "left");
                                                                    }
                                                                }

                                                            }

                                                            Rectangle {
                                                                visible: zwc.zoneName === "center"
                                                                implicitWidth: 20
                                                                implicitHeight: 20
                                                                radius: 4
                                                                color: toRightBtnH.hovered ? Qt.alpha(root.color1, 0.2) : "transparent"

                                                                HoverHandler {
                                                                    id: toRightBtnH
                                                                }

                                                                Text {
                                                                    anchors.centerIn: parent
                                                                    text: "󰁔"
                                                                    font.pixelSize: 10
                                                                    color: root.textColor
                                                                }

                                                                MouseArea {
                                                                    anchors.fill: parent
                                                                    cursorShape: Qt.PointingHandCursor
                                                                    onClicked: {
                                                                        BarWidgetService.transferWidget(modelData.id, "center", "right");
                                                                    }
                                                                }

                                                            }

                                                            Rectangle {
                                                                visible: zwc.zoneName === "right"
                                                                implicitWidth: 20
                                                                implicitHeight: 20
                                                                radius: 4
                                                                color: toCenterBtnH2.hovered ? Qt.alpha(root.color1, 0.2) : "transparent"

                                                                HoverHandler {
                                                                    id: toCenterBtnH2
                                                                }

                                                                Text {
                                                                    anchors.centerIn: parent
                                                                    text: "󰁍"
                                                                    font.pixelSize: 10
                                                                    color: root.textColor
                                                                }

                                                                MouseArea {
                                                                    anchors.fill: parent
                                                                    cursorShape: Qt.PointingHandCursor
                                                                    onClicked: {
                                                                        BarWidgetService.transferWidget(modelData.id, "right", "center");
                                                                    }
                                                                }

                                                            }

                                                            Rectangle {
                                                                implicitWidth: 20
                                                                implicitHeight: 20
                                                                radius: 4
                                                                color: delBtnH.hovered ? Qt.alpha(Colors.cfg.error || "#ff5555", 0.25) : "transparent"

                                                                HoverHandler {
                                                                    id: delBtnH
                                                                }

                                                                Text {
                                                                    anchors.centerIn: parent
                                                                    text: "󰩹"
                                                                    font.pixelSize: 10
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

                                                }

                                            }

                                        }

                                    }
                                    // Bar Mode (3 Cards)

                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 14
                                    visible: root.currentTab === "notifications"

                                    Text {
                                        text: qsTr("Notifications & Sound Alerts")
                                        font.pixelSize: 15
                                        font.bold: true
                                        color: root.textColor
                                    }

                                    // Sound Effects Toggle Card
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 74
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
                                                    text: qsTr("Sound Effect (Enabled by Default)")
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                    color: root.textColor
                                                }

                                                Text {
                                                    text: qsTr("Plays an audio alert when receiving system notifications and timer events")
                                                    font.pixelSize: 10
                                                    color: root.textMuted
                                                }

                                            }

                                            Rectangle {
                                                implicitWidth: 48
                                                implicitHeight: 26
                                                radius: 13
                                                color: Config.cfg.soundEffects ? root.color1 : root.surfaceContainer

                                                Rectangle {
                                                    width: 20
                                                    height: 20
                                                    radius: 10
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    x: Config.cfg.soundEffects ? parent.width - width - 3 : 3
                                                    color: Config.cfg.soundEffects ? root.foreground : root.textColor

                                                    Behavior on x {
                                                        NumberAnimation {
                                                            duration: 150
                                                        }

                                                    }

                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        Config.cfg.soundEffects = !Config.cfg.soundEffects;
                                                        Config.save();
                                                    }
                                                }

                                            }

                                        }

                                    }

                                    // Select Notification Sound & Test Sound Card
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 140
                                        radius: 14
                                        color: root.surface

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 14
                                            spacing: 10

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 8

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 2

                                                    Text {
                                                        text: qsTr("Select Notification Sound")
                                                        font.pixelSize: 12
                                                        font.bold: true
                                                        color: root.textColor
                                                    }

                                                    Text {
                                                        text: qsTr("Choose the audio chime for incoming messages and alerts")
                                                        font.pixelSize: 10
                                                        color: root.textMuted
                                                    }

                                                }

                                                // Quick Reset to Default Sound Button
                                                Rectangle {
                                                    implicitWidth: 80
                                                    implicitHeight: 26
                                                    radius: 6
                                                    color: resSndH.hovered ? Qt.alpha(root.color1, 0.25) : root.surfaceContainer

                                                    RowLayout {
                                                        anchors.centerIn: parent
                                                        spacing: 4

                                                        Text {
                                                            text: "󰑐"
                                                            font.pixelSize: 10
                                                            color: root.color1
                                                        }

                                                        Text {
                                                            text: qsTr("Default")
                                                            font.pixelSize: 10
                                                            font.bold: true
                                                            color: root.textColor
                                                        }

                                                    }

                                                    HoverHandler {
                                                        id: resSndH
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            Config.cfg.notificationSound = "message.oga";
                                                            Config.save();
                                                        }
                                                    }

                                                }

                                            }

                                            // Available Sound Options
                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 8

                                                Repeater {
                                                    model: [{
                                                        "id": "message.oga",
                                                        "label": qsTr("Message (Default)")
                                                    }, {
                                                        "id": "complete.oga",
                                                        "label": qsTr("Chime")
                                                    }, {
                                                        "id": "bell.oga",
                                                        "label": qsTr("Bell")
                                                    }, {
                                                        "id": "dialog-information.oga",
                                                        "label": qsTr("Information")
                                                    }, {
                                                        "id": "dialog-warning.oga",
                                                        "label": qsTr("Warning")
                                                    }]

                                                    delegate: Rectangle {
                                                        id: sndPill

                                                        required property var modelData

                                                        Layout.fillWidth: true
                                                        Layout.preferredHeight: 32
                                                        radius: 8
                                                        color: (Config.cfg.notificationSound === modelData.id) ? root.color1 : (sndPillH.hovered ? root.surfaceContainer : Qt.alpha(root.textColor, 0.05))

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: sndPill.modelData.label
                                                            font.pixelSize: 10
                                                            font.bold: Config.cfg.notificationSound === sndPill.modelData.id
                                                            color: (Config.cfg.notificationSound === sndPill.modelData.id) ? root.foreground : root.textColor
                                                        }

                                                        HoverHandler {
                                                            id: sndPillH
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                Config.cfg.notificationSound = sndPill.modelData.id;
                                                                Config.save();
                                                                root.playTestSound();
                                                            }
                                                        }

                                                    }

                                                }

                                            }

                                            // Test Sound Button Row
                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 12

                                                Rectangle {
                                                    implicitWidth: 160
                                                    implicitHeight: 34
                                                    radius: 8
                                                    color: testSndH.hovered ? Qt.alpha(root.color1, 0.25) : root.surfaceContainer

                                                    RowLayout {
                                                        anchors.centerIn: parent
                                                        spacing: 8

                                                        Text {
                                                            text: ""
                                                            font.pixelSize: 13
                                                            color: root.color1
                                                        }

                                                        Text {
                                                            text: qsTr("Test Current Sound")
                                                            font.pixelSize: 10
                                                            font.bold: true
                                                            color: root.textColor
                                                        }

                                                    }

                                                    HoverHandler {
                                                        id: testSndH
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: root.playTestSound()
                                                    }

                                                }

                                                Text {
                                                    text: qsTr("Active sound: ") + (Config.cfg.notificationSound || "message.oga")
                                                    font.pixelSize: 10
                                                    color: root.textMuted
                                                }

                                            }

                                        }

                                    }

                                    // Alerts Popups (Enabled by Default)
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 74
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
                                                    text: qsTr("Alerts Popups (Enabled by Default)")
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                    color: root.textColor
                                                }

                                                Text {
                                                    text: qsTr("Display floating toast popups on the desktop when a notification is triggered")
                                                    font.pixelSize: 10
                                                    color: root.textMuted
                                                }

                                            }

                                            Rectangle {
                                                implicitWidth: 48
                                                implicitHeight: 26
                                                radius: 13
                                                color: Config.cfg.alertsPopups ? root.color1 : root.surfaceContainer

                                                Rectangle {
                                                    width: 20
                                                    height: 20
                                                    radius: 10
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    x: Config.cfg.alertsPopups ? parent.width - width - 3 : 3
                                                    color: Config.cfg.alertsPopups ? root.foreground : root.textColor

                                                    Behavior on x {
                                                        NumberAnimation {
                                                            duration: 150
                                                        }

                                                    }

                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        Config.cfg.alertsPopups = !Config.cfg.alertsPopups;
                                                        Config.save();
                                                    }
                                                }

                                            }

                                        }

                                    }

                                    // Test Notification Actions Card
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 74
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
                                                    text: qsTr("Notification History") + " (" + NotificationService.notifications.length + ")"
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                    color: root.textColor
                                                }

                                                Text {
                                                    text: qsTr("Trigger a test desktop notification banner or clear active history")
                                                    font.pixelSize: 10
                                                    color: root.textMuted
                                                }

                                            }

                                            Rectangle {
                                                implicitWidth: 120
                                                implicitHeight: 34
                                                radius: 10
                                                color: root.color1

                                                RowLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 6

                                                    Text {
                                                        text: "󰂚"
                                                        font.pixelSize: 13
                                                        color: root.foreground
                                                    }

                                                    Text {
                                                        text: qsTr("Send Test")
                                                        font.pixelSize: 10
                                                        font.bold: true
                                                        color: root.foreground
                                                    }

                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: NotificationService.addNotification("Quickshell", "Notification Center & Sound Alert", "Popups and audio are working seamlessly!", "󰒓")
                                                }

                                            }

                                            Rectangle {
                                                implicitWidth: 80
                                                implicitHeight: 34
                                                radius: 10
                                                color: root.surfaceContainer

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: qsTr("Clear")
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                    color: Colors.cfg.warning
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: NotificationService.clearAll()
                                                }

                                            }

                                        }

                                    }

                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 14
                                    visible: root.currentTab === "gtk"

                                    Text {
                                        text: qsTr("GTK Interface Settings")
                                        font.pixelSize: 15
                                        font.bold: true
                                        color: root.textColor
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 260
                                        radius: 14
                                        color: root.surface

                                        ColumnLayout {
                                            anchors.centerIn: parent
                                            spacing: 16
                                            Layout.alignment: Qt.AlignHCenter

                                            Text {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: "󰒓"
                                                font.pixelSize: 46
                                                color: root.color1
                                            }

                                            ColumnLayout {
                                                spacing: 4
                                                Layout.alignment: Qt.AlignHCenter

                                                Text {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    text: qsTr("External GTK Customization")
                                                    font.pixelSize: 14
                                                    font.bold: true
                                                    color: root.textColor
                                                }

                                                Text {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    text: qsTr("GTK themes, icons, cursors, and system fonts are managed via nwg-look.")
                                                    font.pixelSize: 11
                                                    color: root.textMuted
                                                }

                                            }

                                            // Launch nwg-look button
                                            Rectangle {
                                                Layout.alignment: Qt.AlignHCenter
                                                implicitWidth: 170
                                                implicitHeight: 38
                                                radius: 19
                                                color: nwgBtnH.hovered ? Qt.alpha(root.color1, 0.85) : root.color1

                                                RowLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 8

                                                    Text {
                                                        text: "󰌹"
                                                        font.pixelSize: 14
                                                        color: root.foreground
                                                    }

                                                    Text {
                                                        text: qsTr("Open nwg-look")
                                                        font.pixelSize: 11
                                                        font.bold: true
                                                        color: root.foreground
                                                    }

                                                }

                                                HoverHandler {
                                                    id: nwgBtnH
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.openNwgLook()
                                                }

                                            }

                                        }

                                    }

                                }

                                transform: Translate {
                                    id: tabTranslate

                                    y: 0
                                }

                            }

                            ScrollBar.vertical: ScrollBar {
                                id: vScrollBar

                                policy: ScrollBar.AsNeeded
                                active: true

                                contentItem: Rectangle {
                                    implicitWidth: 6
                                    radius: 3
                                    color: vScrollBar.pressed ? root.color1 : (vScrollBar.hovered ? Qt.alpha(root.color1, 0.8) : Qt.alpha(root.textColor, 0.25))
                                }

                                background: Rectangle {
                                    implicitWidth: 6
                                    radius: 3
                                    color: Qt.alpha(root.surfaceContainer, 0.3)
                                }

                            }

                        }

                        transform: Translate {
                            y: 20 * (1 - root.introContent)
                        }

                    }

                }

            }

        }

    }

}
