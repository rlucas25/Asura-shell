import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import qs.Asura
import qs.Services

PanelWindow {
    id: root
    WlrLayershell.namespace: "lockscreen"

    visible: LockScreenService.isLocked || root.isUnlocking
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: (root.visible && !root.isUnlocking) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    color: "transparent"

    // === ANIMATION & REVEAL PROPERTIES ===
    property real panelReveal: 0.0
    property real contentReveal: 0.0
    property bool isUnlocking: false

    // === STATE & CREDENTIAL DATA ===
    property string typedPassword: ""
    property string authError: ""
    property string currentTime: ""
    property string currentDate: ""

    // === CLOCK TIMER ===
    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var now = new Date();
            root.currentTime = Qt.formatTime(now, "hh:mm");
            
            root.currentDate = Qt.formatDate(now, "dddd, MMMM d"); 
        }
    }

    // === HELPER METHODS ===
    function clearInput() {
        hiddenInput.text = "";
        root.typedPassword = "";
    }

    function submitPassword() {
        if (root.typedPassword.length > 0 && !LockScreenService.isAuthenticating && !root.isUnlocking) {
            var pwd = root.typedPassword;
            root.clearInput();
            LockScreenService.tryUnlock(pwd);
        }
    }

    // === TRANSITIONS ===
    SequentialAnimation {
        id: introSequence

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "panelReveal"
                from: 0.0
                to: 1.0
                duration: 550
                easing.type: Easing.OutCubic
            }

            SequentialAnimation {
                PauseAnimation { duration: 120 }
                NumberAnimation {
                    target: root
                    property: "contentReveal"
                    from: 0.0
                    to: 1.0
                    duration: 1400
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.15
                }
            }
        }
    }

    // Exit sequence when authentication succeeds
    SequentialAnimation {
        id: unlockSequence

        ScriptAction {
            script: {
                root.isUnlocking = true;
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "contentReveal"
                to: 0.0
                duration: 220
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: root
                property: "panelReveal"
                to: 0.0
                duration: 300
                easing.type: Easing.InOutCubic
            }
        }

        ScriptAction {
            script: {
                root.isUnlocking = false;
            }
        }
    }

    // === WINDOW LIFECYCLE & INPUT FOCUS ===
    onVisibleChanged: {
        if (visible && !isUnlocking) {
            root.clearInput();
            root.authError = "";
            root.panelReveal = 0.0;
            root.contentReveal = 0.0;
            introSequence.restart();
            Qt.callLater(function() {
                hiddenInput.forceActiveFocus();
            });
        }
    }

    Connections {
        target: LockScreenService

        function onAuthFailed() {
            root.authError = "Incorrect password";
            root.clearInput();
            shakeAnim.restart();
            hiddenInput.forceActiveFocus();
        }

        function onAuthSuccess() {
            root.clearInput();
            root.authError = "";
            unlockSequence.restart();
        }
    }

    // === BACKDROP & BLURRED WALLPAPER ===
    Item {
        anchors.fill: parent
        Image {
            id: bgWallpaper
            anchors.fill: parent
            source: {
                var wp = Config.cfg.wallpaper;
                return (wp && wp.startsWith("/")) ? "file://" + wp : (wp || "");
            }
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: true
        }


        MultiEffect {
            id: blurEffect
            anchors.fill: bgWallpaper
            source: bgWallpaper
            blurEnabled: true
            blurMax: 24
            blur: 1.0

            opacity: root.panelReveal
        }

        Item {
            anchors.fill: parent
            opacity: root.panelReveal

            // Dark frosted tint layer
            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Colors.cfg.background, 0.55)
            }

            // Subtle primary gradient vignette
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.alpha(Colors.cfg.primary, 0.12) }
                    GradientStop { position: 1.0; color: Qt.alpha(Colors.cfg.background, 0.35) }
                }
            }
        }
    }

    // Intercept clicks to maintain focus on password field
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        onClicked: hiddenInput.forceActiveFocus()
    }

    // Invisible text input to intercept keys reliably
    TextInput {
        id: hiddenInput
        focus: root.visible && !root.isUnlocking
        echoMode: TextInput.Normal
        opacity: 0
        width: 1
        height: 1
        clip: true

        onTextChanged: {
            root.typedPassword = text;
            if (root.authError) root.authError = "";
        }

        onAccepted: root.submitPassword()

        Keys.onEscapePressed: {
            root.clearInput();
            root.authError = "";
        }
    }

    // === MAIN LOCKSCREEN CONTENT CONTAINER ===
    ColumnLayout {
        id: mainContentCol
        anchors.centerIn: parent
        spacing: 36
        width: Math.min(480, root.width - 40)

        opacity: root.contentReveal
        scale: 0.90 + 0.10 * root.contentReveal
        transform: Translate {
            y: 24 * (1.0 - root.contentReveal)
        }

        // === TIME & DATE ===
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.currentTime
                font.pixelSize: 84
                font.bold: true
                font.family: "GeistMono Nerd Font Propo Propo ExtraBold"
                color: Colors.cfg.textBright
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.currentDate
                font.pixelSize: 17
                font.bold: true
                font.family: "GeistMono Nerd Font Propo Propo"
                color: Colors.cfg.primary
            }
        }

        // === USER & INTERACTIVE AUTHENTICATION CARD ===
        Item {
            id: authContainer
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 380
            Layout.preferredHeight: 240

            // Shake Animation on Authentication Error
            transform: Translate { id: shakeTranslate }

            SequentialAnimation {
                id: shakeAnim
                NumberAnimation { target: shakeTranslate; property: "x"; to: -16; duration: 50; easing.type: Easing.OutQuad }
                NumberAnimation { target: shakeTranslate; property: "x"; to: 16; duration: 50; easing.type: Easing.OutQuad }
                NumberAnimation { target: shakeTranslate; property: "x"; to: -12; duration: 50; easing.type: Easing.OutQuad }
                NumberAnimation { target: shakeTranslate; property: "x"; to: 12; duration: 50; easing.type: Easing.OutQuad }
                NumberAnimation { target: shakeTranslate; property: "x"; to: -6; duration: 40; easing.type: Easing.OutQuad }
                NumberAnimation { target: shakeTranslate; property: "x"; to: 6; duration: 40; easing.type: Easing.OutQuad }
                NumberAnimation { target: shakeTranslate; property: "x"; to: 0; duration: 40; easing.type: Easing.OutQuad }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 16

                // User Avatar
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 100
                    implicitHeight: 100

                    Image {
                        id: profilePic
                        anchors.fill: parent
                        source: "file://" + Quickshell.env("HOME") + "/.face.icon"
                        fillMode: Image.PreserveAspectCrop
                        visible: false
                    }

                    Rectangle {
                        id: avatarMask
                        anchors.fill: parent
                        radius: 100
                        color: Colors.cfg.surfaceContainer
                        border.color: Qt.alpha(Colors.cfg.primary, 0.45)
                        border.width: 2
                        
                        Text {
                            anchors.centerIn: parent
                            visible: profilePic.status !== Image.Ready
                            text: "󰀉"
                            font.pixelSize: 42
                            font.family: "GeistMono Nerd Font Propo Propo"
                            color: Colors.cfg.primary
                        }
                    }

                    OpacityMask {
                        anchors.fill: parent
                        source: profilePic
                        maskSource: avatarMask
                        visible: profilePic.status === Image.Ready
                    }
                }

                // Username
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: LockScreenService.username
                    font.pixelSize: 18
                    font.bold: true
                    font.capitalization: Font.Capitalize
                    color: Colors.cfg.text
                }

                // Password Input Pill
                Rectangle {
                    id: passwordPill
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 320
                    implicitHeight: 46
                    radius: 14
                    clip: true
                    color: Qt.alpha(Colors.cfg.surfaceContainer, 0.85)
                    border.color: root.authError !== "" 
                        ? Colors.cfg.error 
                        : (LockScreenService.isAuthenticating ? Colors.cfg.primary : Qt.alpha(Colors.cfg.border, 0.4))
                    border.width: 1.5

                    Behavior on border.color {
                        ColorAnimation { duration: 200 }
                    }

                    property int charCount: root.typedPassword.length
                    property real capsuleWidth: {
                        if (charCount <= 8) return 12;
                        if (charCount <= 14) return 9;
                        if (charCount <= 22) return 6;
                        return 4;
                    }
                    property real capsuleSpacing: {
                        if (charCount <= 8) return 6;
                        if (charCount <= 14) return 4;
                        if (charCount <= 22) return 3;
                        return 2;
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 10
                        text: "󰌾"
                        font.pixelSize: 15
                        font.family: "GeistMono Nerd Font Propo Propo"
                        color: Colors.cfg.primary
                    }

                    // Content Viewport with margin for unlock button
                    Item {
                        id: pillContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 20
                        anchors.rightMargin: (root.typedPassword.length > 0 && !LockScreenService.isAuthenticating) ? 44 : 20
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        clip: true

                        // Placeholder when empty
                        Text {
                            anchors.centerIn: parent
                            visible: root.typedPassword.length === 0 && !LockScreenService.isAuthenticating
                            text: "Enter password"
                            font.pixelSize: 13
                            color: Colors.cfg.textSecondary
                        }

                        // Authenticating spinner text
                        RowLayout {
                            anchors.centerIn: parent
                            visible: LockScreenService.isAuthenticating
                            spacing: 8
                            Text {
                                text: "󰑐"
                                font.pixelSize: 15
                                font.family: "GeistMono Nerd Font Propo Propo"
                                color: Colors.cfg.primary
                                RotationAnimation on rotation {
                                    from: 0; to: 360; duration: 900; loops: Animation.Infinite; running: LockScreenService.isAuthenticating
                                }
                            }
                            Text {
                                text: "Verifying..."
                                font.pixelSize: 13
                                font.bold: true
                                color: Colors.cfg.primary
                            }
                        }

                        // Rounded Geometric Capsule Dots (One per character)
                        Row {
                            anchors.centerIn: parent
                            visible: root.typedPassword.length > 0 && !LockScreenService.isAuthenticating
                            spacing: passwordPill.capsuleSpacing

                            Repeater {
                                model: LockScreenService.isAuthenticating ? 0 : Math.min(root.typedPassword.length, 32)
                                delegate: Rectangle {
                                    required property int index
                                    width: passwordPill.capsuleWidth
                                    height: passwordPill.capsuleWidth
                                    radius: 3
                                    color: Colors.cfg.primary

                                    scale: 0.2
                                    opacity: 0

                                    Component.onCompleted: {
                                        scale = 1.0;
                                        opacity = 1.0;
                                    }

                                    Behavior on scale {
                                        NumberAnimation { duration: 160; easing.type: Easing.OutBack }
                                    }
                                    Behavior on opacity {
                                        NumberAnimation { duration: 120 }
                                    }
                                    Behavior on width {
                                        NumberAnimation { duration: 150 }
                                    }
                                    Behavior on height {
                                        NumberAnimation { duration: 150 }
                                    }
                                }
                            }
                        }
                    }

                    // Unlock Arrow Button
                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 34
                        implicitHeight: 34
                        radius: 10
                        visible: root.typedPassword.length > 0 && !LockScreenService.isAuthenticating
                        color: enterH.hovered ? Colors.cfg.primary : Qt.alpha(Colors.cfg.primary, 0.2)

                        Text {
                            anchors.centerIn: parent
                            text: "󰁕"
                            font.pixelSize: 15
                            font.family: "GeistMono Nerd Font Propo Propo"
                            color: enterH.hovered ? Colors.cfg.on_primary : Colors.cfg.primary
                        }

                        HoverHandler { id: enterH }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.submitPassword()
                        }
                    }
                }

                // Error Message
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    visible: root.authError !== ""
                    text: "󰅙 " + root.authError
                    font.pixelSize: 12
                    font.bold: true
                    color: Colors.cfg.error
                }
            }
        }
    }

    // === FOOTER HINT ===
    Text {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Press Enter to unlock"
        font.pixelSize: 11
        color: Qt.alpha(Colors.cfg.textSecondary, 0.65)
        opacity: Math.max(0.0, (root.contentReveal - 0.3) / 0.7)
    }
}
