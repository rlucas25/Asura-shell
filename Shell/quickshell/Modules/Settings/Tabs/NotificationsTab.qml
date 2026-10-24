import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Asura
import qs.Services
import "../Components"

ColumnLayout {
    id: tabRoot

    required property var settingsRoot
    readonly property var root: settingsRoot
    Layout.fillWidth: true
    spacing: 16
    visible: root.currentTab === "notifications"

    SettingSectionHeader {
        icon: "notifications"
        title: qsTr("Notifications & Sound Alerts")
        description: qsTr("Manage notification toasts, system sound triggers, and sound volume profiles")
    }

    SettingCard {
        SettingToggle {
            title: qsTr("Sound Effect (Enabled by Default)")
            description: qsTr("Plays an audio alert when receiving system notifications and timer events")
            checked: Config.cfg.soundEffects
            onToggled: (newState) => {
                Config.cfg.soundEffects = newState;
                Config.save();
            }
        }
    }

    SettingCard {
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
                    font.family: "Google Sans"
                    color: Colors.cfg.text
                }

                Text {
                    text: qsTr("Choose the audio chime for incoming messages and alerts")
                    font.pixelSize: 10
                    font.family: "Google Sans"
                    color: Colors.cfg.textSecondary
                }
            }

            SettingButton {
                icon: "restart_alt"
                text: qsTr("Default")
                compact: true
                onClicked: {
                    Config.cfg.notificationSound = "message.oga";
                    Config.save();
                }
            }
        }

        SettingPills {
            Layout.fillWidth: true
            fillWidth: true
            currentValue: Config.cfg.notificationSound || "message.oga"
            model: [
                { "id": "message.oga", "label": qsTr("Message (Default)") },
                { "id": "complete.oga", "label": qsTr("Chime") },
                { "id": "bell.oga", "label": qsTr("Bell") },
                { "id": "dialog-information.oga", "label": qsTr("Information") },
                { "id": "dialog-warning.oga", "label": qsTr("Warning") }
            ]
            onSelected: (val) => {
                Config.cfg.notificationSound = val;
                Config.save();
                root.playTestSound();
            }
        }

        SettingDivider {}

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            SettingButton {
                icon: "volume_up"
                text: qsTr("Test Current Sound")
                onClicked: root.playTestSound()
            }

            Text {
                text: qsTr("Active sound: ") + (Config.cfg.notificationSound || "message.oga")
                font.pixelSize: 10
                font.family: "Google Sans"
                color: Colors.cfg.textSecondary
            }
        }
    }

    SettingCard {
        SettingToggle {
            title: qsTr("Alerts Popups (Enabled by Default)")
            description: qsTr("Display floating toast popups on the desktop when a notification is triggered")
            checked: Config.cfg.alertsPopups
            onToggled: (newState) => {
                Config.cfg.alertsPopups = newState;
                Config.save();
            }
        }

        SettingDivider {
            visible: Config.cfg.alertsPopups
        }

        SettingSlider {
            visible: Config.cfg.alertsPopups
            title: qsTr("Popup Duration (Timeout)")
            hint: qsTr("Controls how long notification popups stay visible before automatically fading out")
            from: 1500
            to: 12000
            stepSize: 500
            value: (Config.cfg && Config.cfg.notificationTimeout !== undefined) ? Config.cfg.notificationTimeout : 4500
            customValueText: (((Config.cfg && Config.cfg.notificationTimeout !== undefined) ? Config.cfg.notificationTimeout : 4500) / 1000).toFixed(1) + "s"
            showReset: true
            resetValue: 4500
            onValueModified: (val) => {
                Config.cfg.notificationTimeout = Math.round(val);
                Config.saveDebounced(100);
            }
            onValueCommitted: (val) => {
                Config.cfg.notificationTimeout = Math.round(val);
                Config.save();
            }
        }

        SettingDivider {
            visible: Config.cfg.alertsPopups
        }

        SettingPills {
            visible: Config.cfg.alertsPopups
            icon: "aspect_ratio"
            title: qsTr("Popup Screen Position")
            hint: qsTr("Anchor position on screen where toast notification banners appear")
            currentValue: (Config.cfg && Config.cfg.notificationPosition) ? Config.cfg.notificationPosition : "top_right"
            model: [
                { id: "top_right", label: qsTr("Top Right (Default)") },
                { id: "top_center", label: qsTr("Top Center") },
                { id: "top_left", label: qsTr("Top Left") },
                { id: "bottom_right", label: qsTr("Bottom Right") },
                { id: "bottom_center", label: qsTr("Bottom Center") },
                { id: "bottom_left", label: qsTr("Bottom Left") }
            ]
            onSelected: (val) => {
                Config.cfg.notificationPosition = val;
                Config.save();
            }
        }

        SettingDivider {}

        SettingToggle {
            icon: "visibility_off"
            title: qsTr("Privacy Mode")
            hint: qsTr("Hides sensitive message body text from toast popups")
            description: qsTr("Conceal notification preview body text for privacy when sharing screen or recording")
            checked: (Config.cfg && Config.cfg.notificationPrivacy !== undefined) ? Config.cfg.notificationPrivacy : false
            onToggled: (newState) => {
                Config.cfg.notificationPrivacy = newState;
                Config.save();
            }
        }
    }

    SettingCard {
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: qsTr("Notification History") + " (" + NotificationService.notifications.length + ")"
                    font.pixelSize: 12
                    font.bold: true
                    font.family: "Google Sans"
                    color: Colors.cfg.text
                }

                Text {
                    text: qsTr("Trigger a test desktop notification banner or clear active history")
                    font.pixelSize: 10
                    font.family: "Google Sans"
                    color: Colors.cfg.textSecondary
                }
            }

            SettingButton {
                variant: "primary"
                icon: "notifications"
                text: qsTr("Send Test")
                onClicked: NotificationService.addNotification("Quickshell", "Notification Center & Sound Alert", "Popups and audio are working seamlessly!", "notifications")
            }

            SettingButton {
                variant: "danger"
                icon: "close"
                text: qsTr("Clear")
                onClicked: NotificationService.clearAll()
            }
        }
    }
}
