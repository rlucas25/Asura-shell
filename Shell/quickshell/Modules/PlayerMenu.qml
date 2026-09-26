import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.Mpris
import qs.Asura
import qs.Services
import qs.Animations

Item {
    id: root

    MenuEntrance {
        id: playerEntrance
        active: root.visible
        duration: 320
        startOffsetY: 14
    }

    implicitWidth: 400
    implicitHeight: PlayerService.playerCount > 1 ? 485 : 440

    Behavior on implicitHeight {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    property color primary: Colors.cfg.primary
    property color secondary: Colors.cfg.secondary
    property color background: Colors.cfg.background
    property color surfaceContainer: Colors.cfg.surfaceContainer
    property color on_primary: Colors.cfg.on_primary
    property color text: Colors.cfg.text

    // Compatibility aliases
    property alias color1: root.primary
    property alias color2: root.secondary
    property alias foreground: root.on_primary
    property alias textColor: root.text

    signal hideMenu()

    readonly property var player: PlayerService.activePlayer
    readonly property bool isPlaying: player ? (player.playbackState === MprisPlaybackState.Playing) : false
    property string artUrl: player && player.trackArtUrl ? player.trackArtUrl : ""

    function formatTime(seconds) {
        if (!seconds || isNaN(seconds) || seconds < 0)
            return "00:00";
        var m = Math.floor(seconds / 60);
        var s = Math.floor(seconds % 60);
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
    }

    Timer {
        interval: 500
        running: root.isPlaying
        repeat: true
        onTriggered: {
            if (player) {
                player.positionChanged();
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 10
        opacity: playerEntrance.opacity
        transform: Translate {
            y: playerEntrance.offsetY
        }

        // --- Top Bar: App Identity & Close ---
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 28

            Rectangle {
                width: 26
                height: 26
                radius: 13
                color: Qt.alpha(root.color1, 0.2)

                Text {
                    anchors.centerIn: parent
                    text: PlayerService.getAppIcon(player ? player.identity : "")
                    color: root.color1
                    font.pixelSize: 14
                    font.family: "GeistMono Nerd Font Propo Propo"
                }
            }

            Text {
                text: player ? (player.identity || qsTr("Media Player")) : qsTr("No active player")
                font.pixelSize: 13
                font.family: "GeistMono Nerd Font Propo Propo SemiBold"
                color: Qt.alpha(root.textColor, 0.85)
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Rectangle {
                visible: root.player !== null
                implicitWidth: statusText.implicitWidth + 14
                implicitHeight: 22
                radius: 11
                color: root.isPlaying ? Qt.alpha(root.color1, 0.2) : Qt.alpha(root.textColor, 0.1)

                Text {
                    id: statusText
                    anchors.centerIn: parent
                    text: root.isPlaying ? qsTr("Playing") : qsTr("Paused")
                    font.pixelSize: 11
                    font.family: "GeistMono Nerd Font Propo Propo"
                    color: root.isPlaying ? root.color1 : Qt.alpha(root.textColor, 0.6)
                }
            }

            // Close button
            Rectangle {
                implicitWidth: 26
                implicitHeight: 26
                radius: 13
                color: closeHover.hovered ? Qt.alpha(root.textColor, 0.15) : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    font.pixelSize: 14
                    font.family: "GeistMono Nerd Font Propo Propo"
                    color: Qt.alpha(root.textColor, 0.7)
                }

                HoverHandler {
                    id: closeHover
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.hideMenu()
                }
            }
        }

        // --- Multi-Player Selector Tabs ---
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            visible: PlayerService.playerCount > 1

            Flickable {
                anchors.fill: parent
                contentWidth: playerTabsRow.implicitWidth
                contentHeight: parent.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                RowLayout {
                    id: playerTabsRow
                    spacing: 8

                    Repeater {
                        model: PlayerService.players
                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            readonly property bool isSelected: root.player && root.player.identity === modelData.identity
                            implicitWidth: Math.max(80, tabContent.implicitWidth + 16)
                            implicitHeight: 28
                            radius: 14
                            color: isSelected ? Qt.alpha(root.color1, 0.25) : (tabHover.hovered ? Qt.alpha(root.textColor, 0.1) : Qt.alpha(root.textColor, 0.05))
                            border.color: isSelected ? root.color1 : "transparent"
                            border.width: 1

                            RowLayout {
                                id: tabContent
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: PlayerService.getAppIcon(modelData.identity)
                                    font.pixelSize: 12
                                    font.family: "GeistMono Nerd Font Propo Propo"
                                    color: isSelected ? root.color1 : Qt.alpha(root.textColor, 0.7)
                                }

                                Text {
                                    text: modelData.identity || qsTr("Player")
                                    font.pixelSize: 11
                                    font.family: "GeistMono Nerd Font Propo Propo"
                                    font.bold: isSelected
                                    color: isSelected ? root.foreground : root.textColor
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: 100
                                }
                            }

                            HoverHandler { id: tabHover }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: PlayerService.selectPlayer(modelData)
                            }
                        }
                    }
                }
            }
        }

        // --- Rotating Vinyl Disc ---
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 160
            Layout.preferredHeight: 160
            Layout.topMargin: 4
            Layout.bottomMargin: 4

            // Vinyl Base Disc
            Rectangle {
                id: vinylDisc
                anchors.centerIn: parent
                width: 156
                height: 156
                radius: 78
                color: "#11111b"
                border.color: Qt.alpha(root.textColor, 0.15)
                border.width: 1

                // Grooves Effect
                Repeater {
                    model: [136, 116, 96, 76]
                    delegate: Rectangle {
                        required property int modelData
                        anchors.centerIn: parent
                        width: modelData
                        height: modelData
                        radius: modelData / 2
                        color: "transparent"
                        border.color: Qt.alpha(root.textColor, 0.04)
                        border.width: 1
                    }
                }

                // Center Album Art
                Rectangle {
                    id: albumCoverWrapper
                    anchors.centerIn: parent
                    width: 70
                    height: 70
                    radius: 35
                    color: Qt.alpha(root.color1, 0.2)
                    clip: true

                    Image {
                        id: albumArt
                        anchors.fill: parent
                        source: (root.player && root.player.trackArtUrl) ? root.player.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready
                    }

                    // Fallback Icon
                    Text {
                        anchors.centerIn: parent
                        visible: albumArt.status !== Image.Ready
                        text: "󰎆"
                        font.pixelSize: 28
                        font.family: "GeistMono Nerd Font Propo Propo"
                        color: root.color1
                    }
                }

                // Spindle Hole
                Rectangle {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    radius: 6
                    color: root.background
                    border.color: Qt.alpha(root.textColor, 0.3)
                    border.width: 1
                }

                // Disc Rotation Animation
                RotationAnimator {
                    target: vinylDisc
                    from: 0
                    to: 360
                    duration: 6000
                    loops: Animation.Infinite
                    running: root.isPlaying
                }
            }

            // Stylus / Tone Arm Indicator
            Rectangle {
                id: toneArm
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.topMargin: -4
                width: 4
                height: 52
                radius: 2
                color: Qt.alpha(root.textColor, 0.5)
                transformOrigin: Item.Top
                rotation: root.isPlaying ? 24 : 0

                Behavior on rotation {
                    NumberAnimation { duration: 400; easing.type: Easing.OutBack }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 8
                    height: 10
                    radius: 2
                    color: root.color1
                }
            }
        }

        // --- Track Info ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Layout.topMargin: 2

            Text {
                text: player ? (player.trackTitle || qsTr("No title")) : qsTr("No media playing")
                font.pixelSize: 16
                font.family: "GeistMono Nerd Font Propo Propo ExtraBold"
                color: root.textColor
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            Text {
                text: player ? (player.trackArtist || (player.trackAlbum || qsTr("Unknown artist"))) : qsTr("Play a song in your media player")
                font.pixelSize: 12
                font.family: "GeistMono Nerd Font Propo Propo"
                color: Qt.alpha(root.textColor, 0.65)
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }

        // --- Seek Bar & Timestamps ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            // Interactive Progress Bar
            Item {
                id: progressBarContainer
                Layout.fillWidth: true
                Layout.preferredHeight: 18

                Rectangle {
                    id: progressTrack
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: progressMouse.containsMouse || progressMouse.pressed ? 8 : 5
                    radius: height / 2
                    color: Qt.alpha(root.textColor, 0.15)

                    Behavior on height {
                        NumberAnimation { duration: 150 }
                    }

                    // Filled Portion
                    Rectangle {
                        id: progressFill
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: {
                            if (!root.player || !root.player.length || root.player.length <= 0)
                                return 0;
                            var ratio = Math.max(0, Math.min(1, root.player.position / root.player.length));
                            return parent.width * ratio;
                        }
                        radius: parent.radius
                        color: root.color1

                        Behavior on width {
                            enabled: !progressMouse.pressed
                            NumberAnimation { duration: 250 }
                        }
                    }

                    // Thumb / Handle
                    Rectangle {
                        id: progressHandle
                        width: 14
                        height: 14
                        radius: 7
                        color: root.foreground
                        border.color: root.color1
                        border.width: 2
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: progressFill.right
                        visible: progressMouse.containsMouse || progressMouse.pressed
                    }
                }

                MouseArea {
                    id: progressMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    function seekTo(mouseX) {
                        if (root.player && root.player.length && root.player.length > 0) {
                            var ratio = Math.max(0, Math.min(1, mouseX / width));
                            var newPos = ratio * root.player.length;
                            root.player.position = newPos;
                            root.player.positionChanged();
                        }
                    }

                    onClicked: mouse => seekTo(mouse.x)
                    onPositionChanged: mouse => {
                        if (pressed)
                            seekTo(mouse.x);
                    }
                }
            }

            // Time Labels
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: root.formatTime(root.player ? root.player.position : 0)
                    font.pixelSize: 11
                    font.family: "GeistMono Nerd Font Propo Propo"
                    color: Qt.alpha(root.textColor, 0.6)
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: root.formatTime(root.player ? root.player.length : 0)
                    font.pixelSize: 11
                    font.family: "GeistMono Nerd Font Propo Propo"
                    color: Qt.alpha(root.textColor, 0.6)
                }
            }
        }

        // --- Media Controls ---
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20
            Layout.topMargin: 2
            Layout.bottomMargin: 2

            // Previous Player Switch (Visible if multiple players)
            Rectangle {
                visible: PlayerService.playerCount > 1
                implicitWidth: 32
                implicitHeight: 32
                radius: 16
                color: prevAppHover.hovered ? Qt.alpha(root.color1, 0.2) : Qt.alpha(root.textColor, 0.06)

                Text {
                    anchors.centerIn: parent
                    text: "󰁍"
                    font.pixelSize: 14
                    font.family: "GeistMono Nerd Font Propo Propo"
                    color: Qt.alpha(root.textColor, 0.7)
                }

                HoverHandler {
                    id: prevAppHover
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: PlayerService.cyclePrevPlayer()
                }
            }

            // Previous Track Button
            Rectangle {
                implicitWidth: 42
                implicitHeight: 42
                radius: 21
                color: prevHover.hovered ? Qt.alpha(root.color1, 0.2) : Qt.alpha(root.textColor, 0.08)
                scale: prevHover.hovered ? 1.1 : 1.0

                Behavior on scale {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰒮"
                    font.pixelSize: 20
                    font.family: "GeistMono Nerd Font Propo Propo"
                    color: root.player && root.player.canGoPrevious !== false ? root.color1 : Qt.alpha(root.textColor, 0.3)
                }

                HoverHandler {
                    id: prevHover
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.player) {
                            root.player.previous();
                        }
                    }
                }
            }

            // Play / Pause Main Button
            Rectangle {
                implicitWidth: 56
                implicitHeight: 56
                radius: 28
                color: root.color1
                scale: playHover.hovered ? 1.08 : 1.0

                Behavior on scale {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }

                Text {
                    anchors.centerIn: parent
                    text: root.isPlaying ? "" : ""
                    font.pixelSize: 22
                    font.family: "GeistMono Nerd Font Propo Propo ExtraBold"
                    color: root.foreground
                }

                HoverHandler {
                    id: playHover
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.player) {
                            root.player.togglePlaying();
                        }
                    }
                }
            }

            // Next Track Button
            Rectangle {
                implicitWidth: 42
                implicitHeight: 42
                radius: 21
                color: nextHover.hovered ? Qt.alpha(root.color1, 0.2) : Qt.alpha(root.textColor, 0.08)
                scale: nextHover.hovered ? 1.1 : 1.0

                Behavior on scale {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰒭"
                    font.pixelSize: 20
                    font.family: "GeistMono Nerd Font Propo Propo"
                    color: root.player && root.player.canGoNext !== false ? root.color1 : Qt.alpha(root.textColor, 0.3)
                }

                HoverHandler {
                    id: nextHover
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.player) {
                            root.player.next();
                        }
                    }
                }
            }

            // Next Player Switch (Visible if multiple players)
            Rectangle {
                visible: PlayerService.playerCount > 1
                implicitWidth: 32
                implicitHeight: 32
                radius: 16
                color: nextAppHover.hovered ? Qt.alpha(root.color1, 0.2) : Qt.alpha(root.textColor, 0.06)

                Text {
                    anchors.centerIn: parent
                    text: "󰁔"
                    font.pixelSize: 14
                    font.family: "GeistMono Nerd Font Propo Propo"
                    color: Qt.alpha(root.textColor, 0.7)
                }

                HoverHandler {
                    id: nextAppHover
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: PlayerService.cycleNextPlayer()
                }
            }
        }
    }
}
