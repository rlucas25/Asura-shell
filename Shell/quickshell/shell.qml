//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Asura
import qs.Components
import qs.Modules
import qs.Modules.Bar
import qs.Modules.Clipboard
import qs.Modules.Launcher
import qs.Modules.LockScreen
import qs.Modules.OSD
import qs.Services

ShellRoot {
    id: root

    property string barPosition: Config.barPosition
    property bool verticalMode: Config.isBarVertical
    property real opacity: Config.effectiveBarOpacity
    property real generalOpacity: Config.effectiveGeneralOpacity
    property real widthS: Config.cfg.widthS
    property int barMode: Config.cfg.barMode
    property bool exclusiveMode: Config.ready ? (Config.cfg && Config.cfg.exclusiveMode !== false) : ((Config.cfg && Config.cfg.exclusiveMode !== undefined) ? Config.cfg.exclusiveMode : true)
    property bool autoHide: Config.ready ? (Config.cfg && Config.cfg.autoHide === true) : ((Config.cfg && Config.cfg.autoHide !== undefined) ? Config.cfg.autoHide : false)
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
    property alias backgroundColor: root.background
    property alias textColor: root.text

    Variants {
        model: !root.verticalMode ? Quickshell.screens : []

        Bar {
            required property var modelData

            screen: modelData
            WlrLayershell.namespace: "asura-bar-" + modelData.name
            barPosition: root.barPosition
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

    Variants {
        model: root.verticalMode ? Quickshell.screens : []

        VerticalBar {
            required property var modelData

            screen: modelData
            WlrLayershell.namespace: "asura-bar-vertical-" + modelData.name
            barPosition: root.barPosition
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
                MenuService.toggleControlPanelRequested(modelData.name);
            }
        }

    }

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

    ShortcutsOSD {
        id: shortcutsOSD
    }

    Loader {
        id: settingsWindowLoader
        active: SettingsService.isOpen
        sourceComponent: Component {
            SettingsWindow {
                primary: root.primary
                secondary: root.secondary
                background: root.background
                surfaceContainer: root.surfaceContainer
                on_primary: root.on_primary
                text: root.text
            }
        }
    }

    Variants {
        model: Quickshell.screens

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

    ClipboardPanel {
    }

    Variants {
        model: Quickshell.screens

        CenterLauncher {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        ZenLauncher {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        ScreenCorners {
            required property var modelData

            screen: modelData
        }
    }

    Component.onCompleted: {
        BlurService.applyBlur(Config.cfg.blurEnabled !== false, Config.effectiveBlurStrength);
    }
}

