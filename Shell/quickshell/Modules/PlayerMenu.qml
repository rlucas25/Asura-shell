import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.Mpris
import qs.Asura
import qs.Services
import qs.Animations
import qs.Components

Item {
    id: root

    MenuEntrance {
        id: playerEntrance
        active: root.visible
        duration: 320
        startOffsetY: 14
    }

    implicitWidth: 410
    implicitHeight: PlayerService.playerCount > 1 ? 275 : 238

    Behavior on implicitHeight {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    property color primary: Colors.cfg.primary
    property color secondary: Colors.cfg.secondary
    property color background: Colors.cfg.background
    property color surfaceContainer: Colors.cfg.surfaceContainer
    property color on_primary: Colors.cfg.on_primary
    property color text: Colors.cfg.text

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
        var h = Math.floor(seconds / 3600);
        var m = Math.floor((seconds % 3600) / 60);
        var s = Math.floor(seconds % 60);
        if (h > 0)
            return h + ":" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
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
        anchors.margins: 16
        spacing: 12
        opacity: playerEntrance.opacity
        transform: Translate {
            y: playerEntrance.offsetY
        }

        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 28

            Rectangle {
                width: 26
                height: 26
                radius: 13
                color: Qt.alpha(root.primary, 0.16)

                ThemedIcon {
                    anchors.centerIn: parent
                    size: 15
                    source: (player && player.identity) ? PlayerService.getAppIcon(player.identity) : ""
                    color: root.primary
                    fallbackGlyph: "music_note"
                }
            }

            Text {
                text: player ? (player.identity || qsTr("Media Player")) : qsTr("No active player")
                font.pixelSize: 12
                font.family: "Google Sans Flex, Google Sans, sans-serif"
                font.weight: Font.DemiBold
                color: Qt.alpha(root.textColor, 0.88)
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Rectangle {
                visible: root.player !== null
                implicitWidth: statusRow.implicitWidth + 14
                implicitHeight: 22
                radius: 11
                color: root.isPlaying ? Qt.alpha(root.primary, 0.18) : Qt.alpha(root.textColor, 0.08)

                RowLayout {
                    id: statusRow
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        visible: root.isPlaying
                        text: "graphic_eq"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 13
                        color: root.primary
                    }

                    Text {
                        text: root.isPlaying ? qsTr("Playing") : qsTr("Paused")
                        font.pixelSize: 11
                        font.family: "Google Sans, sans-serif"
                        font.weight: Font.Medium
                        color: root.isPlaying ? root.primary : Qt.alpha(root.textColor, 0.65)
                    }
                }
            }

            Rectangle {
                implicitWidth: 26
                implicitHeight: 26
                radius: 13
                color: closeHover.hovered ? Qt.alpha(root.textColor, 0.14) : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "close"
                    font.pixelSize: 16
                    font.family: "Material Symbols Rounded"
                    color: Qt.alpha(root.textColor, 0.7)
                }

                HoverHandler {
                    id: closeHover
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        MenuService.closeAll();
                        root.hideMenu();
                    }
                }
            }
        }

        // Multi-player switcher tabs
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
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
                            implicitWidth: Math.max(78, tabContent.implicitWidth + 16)
                            implicitHeight: 26
                            radius: 13
                            color: isSelected ? Qt.alpha(root.primary, 0.22) : (tabHover.hovered ? Qt.alpha(root.textColor, 0.1) : Qt.alpha(root.textColor, 0.05))
                            border.color: isSelected ? Qt.alpha(root.primary, 0.6) : "transparent"
                            border.width: 1

                            RowLayout {
                                id: tabContent
                                anchors.centerIn: parent
                                spacing: 6

                                ThemedIcon {
                                    size: 13
                                    source: PlayerService.getAppIcon(modelData.identity)
                                    color: isSelected ? root.primary : Qt.alpha(root.textColor, 0.7)
                                    fallbackGlyph: "music_note"
                                }

                                Text {
                                    text: modelData.identity || qsTr("Player")
                                    font.pixelSize: 11
                                    font.family: "Google Sans, sans-serif"
                                    font.weight: isSelected ? Font.DemiBold : Font.Normal
                                    color: isSelected ? root.primary : Qt.alpha(root.textColor, 0.8)
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: 90
                                }
                            }

                            HoverHandler { id: tabHover }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: PlayerService.selectPlayer(modelData.identity)
                            }
                        }
                    }
                }
            }
        }

        // Track Information: Album Art on the left + Title/Artist on the right
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 76
            spacing: 14

            // Left: Rounded Square Album Art
            Rectangle {
                id: albumArtWrapper
                Layout.preferredWidth: 76
                Layout.preferredHeight: 76
                radius: 24
                color: Qt.alpha(root.primary, 0.12)
                border.color: Qt.alpha(root.textColor, 0.12)
                border.width: 1

                Image {
                    id: albumArt
                    anchors.fill: parent
                    source: (root.player && root.player.trackArtUrl) ? root.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                }

                Rectangle {
                    id: albumArtMask
                    anchors.fill: parent
                    radius: albumArtWrapper.radius
                    visible: false
                }

                OpacityMask {
                    anchors.fill: parent
                    source: albumArt
                    maskSource: albumArtMask
                    visible: albumArt.status === Image.Ready
                }

                Item {
                    anchors.fill: parent
                    visible: albumArt.status !== Image.Ready

                    Text {
                        anchors.centerIn: parent
                        text: "music_note"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 34
                        color: Qt.alpha(root.primary, 0.75)
                    }
                }
            }

            // Right: Track Title, Artist, and Album
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 3

                Text {
                    text: root.player ? (root.player.trackTitle || qsTr("No title")) : qsTr("No media playing")
                    font.pixelSize: 15
                    font.family: "Google Sans Flex, Google Sans, sans-serif"
                    font.weight: Font.Bold
                    color: root.textColor
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: {
                        if (!root.player) return qsTr("Play a song in your media player");
                        var artist = root.player.trackArtist || "";
                        var album = root.player.trackAlbum || "";
                        if (artist && album && artist !== album)
                            return artist + " • " + album;
                        return artist || album || qsTr("Unknown artist");
                    }
                    font.pixelSize: 12
                    font.family: "Google Sans, sans-serif"
                    color: Qt.alpha(root.textColor, 0.65)
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
        }

        // Horizontal Material Design 3 Wavy Progress Bar
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Item {
                id: horizontalProgress
                Layout.fillWidth: true
                Layout.preferredHeight: 20

                readonly property real wavelength: 26
                readonly property real maxAmp: 3.2
                property real targetAmp: (root.isPlaying && !isDragging) ? maxAmp : 0.0
                property real currentAmp: root.isPlaying ? maxAmp : 0.0

                Behavior on currentAmp {
                    NumberAnimation {
                        duration: 450
                        easing.type: Easing.OutCubic
                    }
                }

                readonly property real fraction: {
                    if (!root.player || !root.player.length || root.player.length <= 0)
                        return 0;
                    return Math.max(0, Math.min(1, root.player.position / root.player.length));
                }
                property real dragFraction: 0
                readonly property bool isDragging: progressMouse.pressed
                readonly property real effectiveFraction: isDragging ? dragFraction : fraction
                property real wavePhase: 0

                NumberAnimation {
                    target: horizontalProgress
                    property: "wavePhase"
                    running: (root.isPlaying || horizontalProgress.currentAmp > 0.05) && root.visible
                    loops: Animation.Infinite
                    from: 0
                    to: Math.PI * 2
                    duration: 1400
                    easing.type: Easing.Linear
                }

                onWavePhaseChanged: waveCanvas.requestPaint()
                onCurrentAmpChanged: waveCanvas.requestPaint()
                onEffectiveFractionChanged: waveCanvas.requestPaint()

                Canvas {
                    id: waveCanvas
                    anchors.fill: parent

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);

                        const midY = height / 2;
                        const w = width;
                        const frac = horizontalProgress.effectiveFraction;
                        const playedWidth = Math.max(0, Math.min(w, w * frac));
                        const lineThickness = 4.0;
                        const halfThick = lineThickness / 2;

                        // 1. Inactive remaining rail (flat line with rounded ends)
                        const inactiveStart = Math.min(w - halfThick, Math.max(playedWidth + (frac > 0 && frac < 1 ? 5 : 0), halfThick));
                        const inactiveEnd = w - halfThick;

                        if (inactiveEnd > inactiveStart) {
                            ctx.lineWidth = lineThickness;
                            ctx.lineCap = "round";
                            ctx.strokeStyle = Qt.alpha(root.textColor, 0.14);
                            ctx.beginPath();
                            ctx.moveTo(inactiveStart, midY);
                            ctx.lineTo(inactiveEnd, midY);
                            ctx.stroke();
                        }

                        // 2. Active played rail (wavy or flat, with rounded ends and smooth envelope taper)
                        if (playedWidth > halfThick) {
                            const startX = halfThick;
                            const endX = Math.max(startX + 0.1, playedWidth - halfThick);
                            const activeLength = endX - startX;

                            ctx.lineWidth = lineThickness;
                            ctx.lineCap = "round";
                            ctx.lineJoin = "round";
                            ctx.strokeStyle = root.primary;
                            ctx.beginPath();

                            const amp = horizontalProgress.currentAmp;
                            if (amp > 0.05) {
                                const k = (2 * Math.PI) / horizontalProgress.wavelength;
                                const phase = horizontalProgress.wavePhase;
                                // Taper envelope: smoothly ease amplitude at both ends of the wave
                                const taperDist = Math.min(22, activeLength * 0.45);

                                let first = true;
                                for (let px = startX; px <= endX; px += 0.8) {
                                    let env = 1.0;
                                    if (taperDist > 0.1) {
                                        if (px - startX < taperDist) {
                                            const t = (px - startX) / taperDist;
                                            env = 0.5 * (1 - Math.cos(Math.PI * t));
                                        } else if (endX - px < taperDist) {
                                            const t = (endX - px) / taperDist;
                                            env = 0.5 * (1 - Math.cos(Math.PI * t));
                                        }
                                    }
                                    const py = midY + amp * env * Math.sin((px - startX) * k - phase);
                                    if (first) {
                                        ctx.moveTo(px, py);
                                        first = false;
                                    } else {
                                        ctx.lineTo(px, py);
                                    }
                                }
                                ctx.lineTo(endX, midY);
                            } else {
                                ctx.moveTo(startX, midY);
                                ctx.lineTo(endX, midY);
                            }
                            ctx.stroke();
                        }
                    }

                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                    Component.onCompleted: requestPaint()

                    Connections {
                        target: root
                        function onPrimaryChanged() { waveCanvas.requestPaint(); }
                    }
                }

                // Thumb handle
                Rectangle {
                    id: thumbHandle
                    x: Math.max(0, Math.min(parent.width - width, parent.width * horizontalProgress.effectiveFraction - width / 2))
                    anchors.verticalCenter: parent.verticalCenter
                    width: 14
                    height: 14
                    radius: 7
                    color: root.primary
                    border.color: root.surfaceContainer
                    border.width: 2.5
                    scale: progressMouse.pressed ? 1.3 : (progressMouse.containsMouse ? 1.15 : 1.0)

                    Behavior on scale {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                }

                MouseArea {
                    id: progressMouse
                    anchors.fill: parent
                    anchors.topMargin: -6
                    anchors.bottomMargin: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    preventStealing: true

                    function seekTo(mx) {
                        if (root.player && root.player.length && root.player.length > 0) {
                            var frac = Math.max(0, Math.min(1, mx / width));
                            horizontalProgress.dragFraction = frac;
                            root.player.position = frac * root.player.length;
                            root.player.positionChanged();
                        }
                    }

                    onPressed: mouse => seekTo(mouse.x)
                    onPositionChanged: mouse => {
                        if (pressed)
                            seekTo(mouse.x);
                    }
                }
            }

            // Timestamps Row
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: {
                        if (horizontalProgress.isDragging)
                            return root.formatTime(horizontalProgress.dragFraction * (root.player ? root.player.length : 0));
                        return root.formatTime(root.player ? root.player.position : 0);
                    }
                    font.pixelSize: 10
                    font.family: "Google Sans Flex, Google Sans, sans-serif"
                    font.weight: Font.DemiBold
                    color: horizontalProgress.isDragging ? root.primary : Qt.alpha(root.textColor, 0.75)
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: root.formatTime(root.player ? root.player.length : 0)
                    font.pixelSize: 10
                    font.family: "Google Sans Flex, Google Sans, sans-serif"
                    font.weight: Font.Medium
                    color: Qt.alpha(root.textColor, 0.55)
                }
            }
        }

        // Centered Playback Controls Row
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            Item {
                Layout.fillWidth: true
            }

            // Previous Player Switcher
            Rectangle {
                visible: PlayerService.playerCount > 1
                implicitWidth: 32
                implicitHeight: 32
                radius: 10
                color: prevAppHover.hovered ? Qt.alpha(root.primary, 0.18) : Qt.alpha(root.textColor, 0.05)
                scale: prevAppHover.hovered ? 1.08 : 1.0

                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "skip_previous"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 16
                    color: Qt.alpha(root.textColor, 0.6)
                }

                HoverHandler { id: prevAppHover }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: PlayerService.cyclePrevPlayer()
                }
            }

            // Previous Track
            Rectangle {
                implicitWidth: 42
                implicitHeight: 42
                radius: 14
                color: prevMa.containsPress ? Qt.alpha(root.primary, 0.25) : (prevMa.containsMouse ? Qt.alpha(root.textColor, 0.12) : Qt.alpha(root.textColor, 0.06))
                border.color: prevMa.containsMouse ? Qt.alpha(root.primary, 0.35) : Qt.alpha(root.textColor, 0.08)
                border.width: 1
                scale: prevMa.containsPress ? 0.92 : (prevMa.containsMouse ? 1.08 : 1.0)

                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "skip_previous"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 22
                    color: (root.player && root.player.canGoPrevious !== false) ? root.textColor : Qt.alpha(root.textColor, 0.35)
                }

                MouseArea {
                    id: prevMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.player) root.player.previous();
                    }
                }
            }

            // Play / Pause Hero Pill
            Rectangle {
                implicitWidth: 64
                implicitHeight: 44
                radius: 18
                color: root.primary
                scale: playMa.containsPress ? 0.92 : (playMa.containsMouse ? 1.06 : 1.0)

                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: root.isPlaying ? "pause" : "play_arrow"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 28
                    color: root.on_primary
                }

                MouseArea {
                    id: playMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.player) root.player.togglePlaying();
                    }
                }
            }

            // Next Track
            Rectangle {
                implicitWidth: 42
                implicitHeight: 42
                radius: 14
                color: nextMa.containsPress ? Qt.alpha(root.primary, 0.25) : (nextMa.containsMouse ? Qt.alpha(root.textColor, 0.12) : Qt.alpha(root.textColor, 0.06))
                border.color: nextMa.containsMouse ? Qt.alpha(root.primary, 0.35) : Qt.alpha(root.textColor, 0.08)
                border.width: 1
                scale: nextMa.containsPress ? 0.92 : (nextMa.containsMouse ? 1.08 : 1.0)

                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "skip_next"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 22
                    color: (root.player && root.player.canGoNext !== false) ? root.textColor : Qt.alpha(root.textColor, 0.35)
                }

                MouseArea {
                    id: nextMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.player) root.player.next();
                    }
                }
            }

            // Next Player Switcher
            Rectangle {
                visible: PlayerService.playerCount > 1
                implicitWidth: 32
                implicitHeight: 32
                radius: 10
                color: nextAppHover.hovered ? Qt.alpha(root.primary, 0.18) : Qt.alpha(root.textColor, 0.05)
                scale: nextAppHover.hovered ? 1.08 : 1.0

                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "skip_next"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 16
                    color: Qt.alpha(root.textColor, 0.6)
                }

                HoverHandler { id: nextAppHover }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: PlayerService.cycleNextPlayer()
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }
    }
}
