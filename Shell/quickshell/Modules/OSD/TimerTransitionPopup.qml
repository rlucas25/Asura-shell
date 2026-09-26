import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Asura

// ── Timer State-Transition Overlay ────────────────────────────────────────────
// Full-screen OSD popup shown on every Pomodoro/Timer state change.
// - Dark backdrop fades in behind a centered card.
// - Card animates in with OutBack spring (scale 0 → 1 + fade).
// - Auto-dismisses after 3 s with a reversed pop-out animation.
// - Input is fully pass-through: mask is empty, so bar interactions work normally.
// - Call show(icon, message) to trigger the overlay from any context.
PanelWindow {
    id: root

    // ── Theme properties (set by parent in shell.qml) ─────────────────────────
    property color primary: Colors.cfg.primary
    property color background: Colors.cfg.background
    property color text: Colors.cfg.text

    // ── Internal state ────────────────────────────────────────────────────────
    property string popupIcon: ""
    property string popupMessage: ""
    property bool _active: false

    // ── Public API ────────────────────────────────────────────────────────────
    // Call this to trigger the popup. Safe to call while already showing.
    function show(icon, message) {
        // Stop any running animations and reset targets for a clean restart
        showAnim.stop();
        hideAnim.stop();
        overlayBg.opacity = 0.0;
        popupCard.scale   = 0.0;
        popupCard.opacity = 0.0;

        popupIcon    = icon;
        popupMessage = message;
        _active      = true;

        showAnim.start();
        dismissTimer.restart();
    }

    // ── Layer / Window configuration ──────────────────────────────────────────
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    implicitWidth:  screen.width
    implicitHeight: screen.height
    color: "transparent"

    visible: _active

    // Empty mask = fully pass-through input.
    // The user must click the play/pause bar button to stop the alarm.
    mask: Region {}

    // ── Auto-dismiss timer ────────────────────────────────────────────────────
    Timer {
        id: dismissTimer
        interval: 3000
        onTriggered: hideAnim.start()
    }

    // ── Pop-in animation (ParallelAnimation: scale + opacity) ─────────────────
    // scale: 0 → 1.0 with OutBack overshoot for a spring feel
    // opacity: 0 → 1.0 for both overlay and card
    ParallelAnimation {
        id: showAnim

        NumberAnimation {
            target: overlayBg
            property: "opacity"
            to: 0.62
            duration: 380
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: popupCard
            property: "opacity"
            to: 1.0
            duration: 320
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: popupCard
            property: "scale"
            to: 1.0
            duration: 560
            easing.type: Easing.OutBack
            easing.overshoot: 1.8
        }
    }

    // ── Pop-out animation (SequentialAnimation: parallel fade → hide) ─────────
    // After the ParallelAnimation completes, ScriptAction hides the window.
    SequentialAnimation {
        id: hideAnim

        ParallelAnimation {
            NumberAnimation {
                target: overlayBg
                property: "opacity"
                to: 0.0
                duration: 320
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: popupCard
                property: "opacity"
                to: 0.0
                duration: 260
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: popupCard
                property: "scale"
                to: 0.82
                duration: 260
                easing.type: Easing.InCubic
            }
        }

        // Unmap the PanelWindow after animation completes
        ScriptAction {
            script: root._active = false
        }
    }

    // ── Dark backdrop ─────────────────────────────────────────────────────────
    Rectangle {
        id: overlayBg
        anchors.fill: parent
        color: "#000000"
        opacity: 0.0
    }

    // ── Popup card ────────────────────────────────────────────────────────────
    Rectangle {
        id: popupCard
        anchors.centerIn: parent
        width:  370
        height: 210
        radius: 32

        // Glassmorphism-style surface
        color: Qt.rgba(root.background.r, root.background.g, root.background.b, 0.93)

        // Glowing border tinted with the accent color
        border.color: Qt.alpha(root.primary, 0.40)
        border.width: 1.5

        // Animation initial state (driven by showAnim / hideAnim)
        scale:   0.0
        opacity: 0.0

        // ── Subtle inner glow ring ────────────────────────────────────────────
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.color: Qt.alpha(root.primary, 0.10)
            border.width: 6
        }

        // ── Icon + Label layout ───────────────────────────────────────────────
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 16

            // Icon
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.popupIcon
                font.pixelSize: 56
                font.family: "Material Symbols Rounded"
                color: root.primary
            }

            // State label (e.g. "Time to focus")
            Text {
                Layout.alignment: Qt.AlignHCenter
                // qsTr() enables translation toolchain support for this string
                text: qsTr(root.popupMessage)
                font.pixelSize: 22
                font.family:    "Google Sans"
                font.bold: true
                color: root.text
            }
        }
    }
}
