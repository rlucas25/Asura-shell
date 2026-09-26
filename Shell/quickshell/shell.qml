//@ pragma UseQApplication
//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded
//@ pragma DefaultEnv QS_DROP_EXPENSIVE_FONTS=1

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Asura
import qs.Components
import qs.Modules
import qs.Modules.Bar
import qs.Modules.Launcher
import qs.Modules.LockScreen


import qs.Modules.OSD
import qs.Services
import qs.Modules.Clipboard
ShellRoot {
    //OverlayScreenFormat{}
    /*
    FloatingWindow{
        width: 500
        height: 500
        StyledRectangle{
        }
    }
*/
    /*
    ConfigMenu {
        background: root.backgroundColor
        surfaceContainer: root.surfaceContainer
        primary: root.primary
        on_primary: root.on_primary
        text: root.textColor
        secondary: root.secondary
    }
    */

    id: root

    property bool verticalMode: false // comming soon
    property real opacity: Config.cfg.opacity
    property real widthS: Config.cfg.widthS
    // 0: float mode | 1: capsule mode  | 2: full mode
    property int barMode: Config.cfg.barMode
    property bool exclusiveMode: Config.cfg.exclusiveMode
    property bool autoHide: Config.cfg.autoHide
    property bool colorsAutoGenerate: Config.cfg.colorsAutoGenerate
    property color background: Colors.cfg.background
    property color surface: Colors.cfg.surface
    property color surfaceVariant: Colors.cfg.surfaceVariant
    property color surfaceContainer: Colors.cfg.surfaceContainer
    property color primary: Colors.cfg.primary
    property color on_primary: Colors.cfg.on_primary
    property color text: Colors.cfg.text
    property color textSecondary: Colors.cfg.textSecondary
    property color secondary: Colors.cfg.secondary
    property color tertiary: Colors.cfg.tertiary
    property color shadow: Colors.cfg.shadow
    property color success: Colors.cfg.success
    property color warning: Colors.cfg.warning
    property color error: Colors.cfg.error
    // Compatibility aliases
    property alias backgroundColor: root.background
    property alias textColor: root.text


    // PlayerMenu {}
    Variants {
        // A lista de todos os monitores atualmente conectados
        model: Quickshell.screens

        Bar {
            required property var modelData

            screen: modelData
            WlrLayershell.namespace: "asura-bar-" + modelData.name
            mode: root.barMode
            bgOpacity: root.opacity
            on_primary: root.on_primary
            primary: root.primary
            secondary: root.secondary
            widthStages: root.widthS
            exclusiveMode: root.exclusiveMode
            autoHide: root.autoHide
        }

    }

    /*
    Overlay {
        visible: root.barMode !== 0 && (barMode >= 1)
        background: root.background
        _opacity: root.opacity
    }
*/
    VolumeOSD {
        verticalMode: root.verticalMode
        background: root.background
        color1: root.primary
        color2: root.warning
    }

    BrightnessOSD {
        verticalMode: root.verticalMode
        background: root.background
        color1: root.primary
        color2: root.warning
    }

    Variants {
        model: Quickshell.screens

        NotificationToast {
            required property var modelData

            screen: modelData
            primary: root.primary
            secondary: root.secondary
            background: root.background
            surfaceContainer: root.surfaceContainer
            on_primary: root.on_primary
            text: root.text
            onNotificationClicked: {
                bar.mainMenuOpen = true;
            }
        }

    }

    // ── Pomodoro / Timer state-transition overlay ─────────────────────────────
    // Listens to TimerService.stateTransitionOccurred and shows a full-screen
    // popup with blur backdrop for 3 seconds on every phase change.
    TimerTransitionPopup {
        id: timerTransitionPopup

        primary: root.primary
        background: root.background
        text: root.text
    }

    Connections {
        function onStateTransitionOccurred(icon, message) {
            timerTransitionPopup.show(icon, message);
        }

        target: TimerService
    }

    WindowSwitcher {
        primary: root.primary
        secondary: root.secondary
        background: root.background
        surfaceContainer: root.surfaceContainer
        on_primary: root.on_primary
        text: root.text
    }

    SettingsWindow {
        primary: root.primary
        secondary: root.secondary
        background: root.background
        surfaceContainer: root.surfaceContainer
        on_primary: root.on_primary
        text: root.text
    }

    Variants {
        model: Quickshell.screens

        // Native Lock Screen
        LockScreen {
            required property var modelData

            screen: modelData
        }

    }

    IpcHandler {
        function lock() {
            LockScreenService.lock();
        }

        function toggle() {
            LockScreenService.toggle();
        }

        target: "lock"
    }

    ClipboardPanel{}
    //PowerMenu {}

}
