import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Asura
import qs.Services

PanelWindow {
    id: root

    property real panelReveal: 0
    property real contentReveal: 0
    property bool isUnlocking: false
    property string typedPassword: ""
    property string authError: ""
    property string currentTime: ""
    property string currentDate: ""
    property bool authActive: false
    readonly property bool showAuth: authActive || typedPassword.length > 0 || LockScreenService.isAuthenticating || authError !== ""

    function clearInput() {
        hiddenInput.text = "";
        root.typedPassword = "";
    }

    function submitPassword() {
        if (root.typedPassword.length > 0 && !LockScreenService.isAuthenticating && !root.isUnlocking)
            LockScreenService.tryUnlock(root.typedPassword);

    }

    WlrLayershell.namespace: "lockscreen"
    visible: LockScreenService.isLocked || root.isUnlocking
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: (root.visible && !root.isUnlocking) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    onVisibleChanged: {
        if (visible && !isUnlocking) {
            root.clearInput();
            root.authError = "";
            root.authActive = false;
            root.panelReveal = 0;
            root.contentReveal = 0;
            introSequence.restart();
            Qt.callLater(function() {
                hiddenInput.forceActiveFocus();
            });
        }
    }

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var now = new Date();
            root.currentTime = Qt.formatTime(now, (Config.cfg && Config.cfg.clock24h) ? "HH:mm" : "hh:mm");
            root.currentDate = Qt.formatDate(now, "ddd, MMMM d");
        }
    }

    SequentialAnimation {
        id: introSequence

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "panelReveal"
                from: 0
                to: 1
                duration: 550
                easing.type: Easing.OutCubic
            }

            SequentialAnimation {
                PauseAnimation {
                    duration: 120
                }

                NumberAnimation {
                    target: root
                    property: "contentReveal"
                    from: 0
                    to: 1
                    duration: 1400
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.15
                }

            }

        }

    }

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
                to: 0
                duration: 220
                easing.type: Easing.InQuad
            }

            NumberAnimation {
                target: root
                property: "panelReveal"
                to: 0
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

    Connections {
        function onAuthFailed() {
            root.authError = "Incorrect password";
            root.clearInput();
            shakeAnim.restart();
            hiddenInput.forceActiveFocus();
        }

        function onAuthSuccess() {
            root.clearInput();
            root.authError = "";
            root.authActive = false;
            unlockSequence.restart();
        }

        target: LockScreenService
    }

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
            blur: 1
            opacity: root.panelReveal
        }

        Item {
            anchors.fill: parent
            opacity: root.panelReveal

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Colors.cfg.background, 0.55)
            }

            Rectangle {
                anchors.fill: parent

                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: Qt.alpha(Colors.cfg.primary, 0.12)
                    }

                    GradientStop {
                        position: 1
                        color: Qt.alpha(Colors.cfg.background, 0.35)
                    }

                }

            }

        }

    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        onClicked: {
            root.authActive = true;
            hiddenInput.forceActiveFocus();
        }
    }

    TextInput {
        id: hiddenInput

        focus: root.visible && !root.isUnlocking
        readOnly: LockScreenService.isAuthenticating || root.isUnlocking
        echoMode: TextInput.Normal
        opacity: 0
        width: 1
        height: 1
        clip: true

        onTextChanged: {
            root.typedPassword = text;
            if (text.length > 0)
                root.authActive = true;
            if (root.authError)
                root.authError = "";
        }

        onAccepted: {
            if (!root.showAuth) {
                root.authActive = true;
            } else {
                root.submitPassword();
            }
        }

        Keys.onPressed: event => {
            if (!root.authActive && event.key !== Qt.Key_Escape) {
                root.authActive = true;
            }
        }

        Keys.onEscapePressed: {
            root.clearInput();
            root.authError = "";
            root.authActive = false;
        }
    }

    Timer {
        id: idleAuthTimer
        interval: 10000
        repeat: false
        running: root.authActive && root.typedPassword.length === 0 && !LockScreenService.isAuthenticating && root.authError === ""
        onTriggered: root.authActive = false
    }

    ColumnLayout {
        id: mainContentCol

        anchors.centerIn: parent
        spacing: root.showAuth ? 36 : 0
        opacity: root.contentReveal
        scale: 0.9 + 0.1 * root.contentReveal

        Behavior on spacing {
            NumberAnimation {
                duration: 380
                easing.type: Easing.OutCubic
            }
        }

        ColumnLayout {
            id: clockCol

            Layout.alignment: Qt.AlignHCenter
            spacing: 8
            scale: root.showAuth ? 0.86 : 1.0
            transformOrigin: Item.Center

            Behavior on scale {
                NumberAnimation {
                    duration: 380
                    easing.type: Easing.OutCubic
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                text: root.currentDate
                font.pixelSize: 28
                font.bold: true
                font.family: "Google Sans"
                color: Colors.cfg.primary
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                text: root.currentTime
                font.pixelSize: 156
                font.bold: true
                font.family: "Google Sans"
                color: Colors.cfg.textBright
            }

        }

        Item {
            id: authContainer

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: authContentCol.implicitWidth
            implicitHeight: root.showAuth ? authContentCol.implicitHeight : 0
            clip: true
            opacity: root.showAuth ? 1.0 : 0.0
            visible: opacity > 0.001

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            SequentialAnimation {
                id: shakeAnim

                NumberAnimation {
                    target: shakeTranslate
                    property: "x"
                    to: -24
                    duration: 50
                    easing.type: Easing.OutQuad
                }

                NumberAnimation {
                    target: shakeTranslate
                    property: "x"
                    to: 24
                    duration: 50
                    easing.type: Easing.OutQuad
                }

                NumberAnimation {
                    target: shakeTranslate
                    property: "x"
                    to: -18
                    duration: 50
                    easing.type: Easing.OutQuad
                }

                NumberAnimation {
                    target: shakeTranslate
                    property: "x"
                    to: 18
                    duration: 50
                    easing.type: Easing.OutQuad
                }

                NumberAnimation {
                    target: shakeTranslate
                    property: "x"
                    to: -10
                    duration: 40
                    easing.type: Easing.OutQuad
                }

                NumberAnimation {
                    target: shakeTranslate
                    property: "x"
                    to: 10
                    duration: 40
                    easing.type: Easing.OutQuad
                }

                NumberAnimation {
                    target: shakeTranslate
                    property: "x"
                    to: 0
                    duration: 40
                    easing.type: Easing.OutQuad
                }

            }

            ColumnLayout {
                id: authContentCol

                anchors.centerIn: parent
                spacing: 20

                Item {
                    id: avatarContainer

                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 170
                    implicitHeight: 170
                    scale: root.showAuth ? 1.0 : 0.2
                    opacity: root.showAuth ? 1.0 : 0.0
                    transformOrigin: Item.Center

                    Behavior on scale {
                        NumberAnimation {
                            duration: 450
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.25
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 250
                        }
                    }

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
                        radius: 170
                        color: Colors.cfg.surfaceContainer
                        border.color: Qt.alpha(Colors.cfg.primary, 0.45)
                        border.width: 3

                        Text {
                            anchors.centerIn: parent
                            visible: profilePic.status !== Image.Ready
                            text: "person"
                            font.pixelSize: 84
                            font.family: "Material Symbols Rounded"
                            color: Colors.cfg.primary
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                    }

                    OpacityMask {
                        anchors.fill: parent
                        source: profilePic
                        maskSource: avatarMask
                        visible: profilePic.status === Image.Ready
                    }

                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: LockScreenService.username
                    font.pixelSize: 28
                    font.bold: true
                    font.capitalization: Font.Capitalize
                    font.family: "Google Sans"
                    color: Colors.cfg.text
                    opacity: root.showAuth ? 1.0 : 0.0
                    scale: root.showAuth ? 1.0 : 0.85
                    transformOrigin: Item.Center

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 280
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 350
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Rectangle {
                    id: passwordPill

                    property int charCount: root.typedPassword.length
                    property real capsuleWidth: {
                        if (charCount <= 8)
                            return 18;

                        if (charCount <= 14)
                            return 14;

                        if (charCount <= 22)
                            return 10;

                        return 6;
                    }
                    property real capsuleSpacing: {
                        if (charCount <= 8)
                            return 10;

                        if (charCount <= 14)
                            return 7;

                        if (charCount <= 22)
                            return 5;

                        return 3;
                    }

                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: root.showAuth ? 460 : 64
                    implicitHeight: 64
                    radius: 18
                    clip: true
                    color: Qt.alpha(Colors.cfg.surfaceContainer, 0.85)
                    border.color: root.authError !== "" ? Colors.cfg.error : (LockScreenService.isAuthenticating ? Colors.cfg.primary : Qt.alpha(Colors.cfg.border, 0.4))
                    border.width: 2
                    opacity: root.showAuth ? 1.0 : 0.0
                    scale: root.showAuth ? 1.0 : 0.85
                    transformOrigin: Item.Center

                    Behavior on implicitWidth {
                        NumberAnimation {
                            duration: 420
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.05
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 250
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 350
                            easing.type: Easing.OutCubic
                        }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 16
                        text: "lock"
                        font.pixelSize: 24
                        font.family: "Material Symbols Rounded"
                        color: Colors.cfg.primary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        opacity: passwordPill.implicitWidth > 120 ? 1.0 : 0.0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 160
                            }
                        }
                    }

                    Item {
                        id: pillContent

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 56
                        anchors.rightMargin: 56
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        clip: true
                        opacity: passwordPill.implicitWidth > 200 ? 1.0 : 0.0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: root.typedPassword.length === 0 && !LockScreenService.isAuthenticating
                            text: "Enter password"
                            font.pixelSize: 18
                            font.family: "Google Sans"
                            color: Colors.cfg.textSecondary
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            visible: LockScreenService.isAuthenticating
                            spacing: 12

                            Text {
                                text: "progress_activity"
                                font.pixelSize: 24
                                font.family: "Material Symbols Rounded"
                                color: Colors.cfg.primary
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter

                                RotationAnimation on rotation {
                                    from: 0
                                    to: 360
                                    duration: 900
                                    loops: Animation.Infinite
                                    running: LockScreenService.isAuthenticating
                                }

                            }

                            Text {
                                text: "Verifying..."
                                font.pixelSize: 18
                                font.bold: true
                                font.family: "Google Sans"
                                color: Colors.cfg.primary
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                        }

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
                                    radius: 5
                                    color: Colors.cfg.primary
                                    scale: 0.2
                                    opacity: 0
                                    Component.onCompleted: {
                                        scale = 1;
                                        opacity = 1;
                                    }

                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 160
                                            easing.type: Easing.OutBack
                                        }

                                    }

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 120
                                        }

                                    }

                                    Behavior on width {
                                        NumberAnimation {
                                            duration: 150
                                        }

                                    }

                                    Behavior on height {
                                        NumberAnimation {
                                            duration: 150
                                        }

                                    }

                                }

                            }

                        }

                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 48
                        implicitHeight: 48
                        radius: 14
                        visible: root.typedPassword.length > 0 && !LockScreenService.isAuthenticating
                        color: enterH.hovered ? Colors.cfg.primary : Qt.alpha(Colors.cfg.primary, 0.2)

                        Text {
                            anchors.centerIn: parent
                            text: "arrow_forward"
                            font.pixelSize: 24
                            font.family: "Material Symbols Rounded"
                            color: enterH.hovered ? Colors.cfg.on_primary : Colors.cfg.primary
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        HoverHandler {
                            id: enterH
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.submitPassword()
                        }

                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 200
                        }

                    }

                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    visible: root.authError !== ""
                    spacing: 6

                    Text {
                        text: "error"
                        font.pixelSize: 20
                        font.family: "Material Symbols Rounded"
                        color: Colors.cfg.error
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        text: root.authError
                        font.pixelSize: 16
                        font.bold: true
                        font.family: "Google Sans"
                        color: Colors.cfg.error
                        verticalAlignment: Text.AlignVCenter
                    }

                }

            }

            transform: Translate {
                id: shakeTranslate
            }

        }

        transform: Translate {
            y: 24 * (1 - root.contentReveal)
        }

    }

    Text {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 36
        anchors.horizontalCenter: parent.horizontalCenter
        horizontalAlignment: Text.AlignHCenter
        text: root.showAuth ? "Press Escape to cancel" : "Press any key to unlock"
        font.pixelSize: 15
        font.family: "Google Sans"
        color: Qt.alpha(Colors.cfg.textSecondary, 0.65)
        opacity: Math.max(0, (root.contentReveal - 0.3) / 0.7)
    }

}
