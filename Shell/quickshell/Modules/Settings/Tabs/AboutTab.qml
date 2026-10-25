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
    visible: root.currentTab === "about"

    Component.onCompleted: {
        SystemMonitorService.subscribe();
        SystemMonitorService.refresh();
        if (UpdateService.lastCheckTimestamp === 0) {
            UpdateService.checkForUpdates(false);
        }
    }

    Component.onDestruction: {
        SystemMonitorService.unsubscribe();
    }

    function copyAllSpecs() {
        const text = [
            `OS: ${SystemMonitorService.distroName} ${SystemMonitorService.arch}`,
            `Host: ${SystemMonitorService.hostName}`,
            `Kernel: ${SystemMonitorService.kernelVersion}`,
            `Uptime: ${SystemMonitorService.uptimeStr}`,
            `Packages: ${SystemMonitorService.packageCount}`,
            `Shell: ${SystemMonitorService.userShell}`,
            `WM: ${SystemMonitorService.wmVersion}`,
            `CPU: ${SystemMonitorService.cpuModel} (${SystemMonitorService.cpuCores} cores)`,
            `GPU: ${SystemMonitorService.gpuName}`,
            `Memory: ${SystemMonitorService.memUsedGb} GB / ${SystemMonitorService.memTotalGb} GB`,
            `Disk: ${SystemMonitorService.diskUsedGb} GB / ${SystemMonitorService.diskTotalGb} GB`
        ].join("\n");
        Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | wl-copy", "_", text]);
        root.showToast(qsTr("System specifications copied to clipboard!"), "content_copy");
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: heroContentRow.implicitHeight + 36
        radius: 18
        color: root.surface
        border.color: root.borderCol
        border.width: 1

        RowLayout {
            id: heroContentRow
            anchors.fill: parent
            anchors.margins: 18
            spacing: 20

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 92
                implicitHeight: 92
                radius: 18
                color: Qt.alpha(Colors.cfg.primary, 0.12)
                border.color: Qt.alpha(Colors.cfg.primary, 0.35)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "desktop_windows"
                    font.pixelSize: 46
                    font.family: "Material Symbols Rounded"
                    color: Colors.cfg.primary
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 4

                RowLayout {
                    spacing: 8

                    Text {
                        text: SystemMonitorService.distroName || "Linux"
                        font.pixelSize: 22
                        font.bold: true
                        font.family: "Google Sans"
                        color: root.textBright
                    }

                    Rectangle {
                        implicitWidth: archText.implicitWidth + 10
                        implicitHeight: 18
                        radius: 9
                        color: Qt.alpha(Colors.cfg.primary, 0.15)
                        border.color: Qt.alpha(Colors.cfg.primary, 0.35)
                        border.width: 1

                        Text {
                            id: archText
                            anchors.centerIn: parent
                            text: SystemMonitorService.arch || "x86_64"
                            font.pixelSize: 9
                            font.bold: true
                            font.family: "Google Sans"
                            color: Colors.cfg.primary
                        }
                    }
                }

                Text {
                    text: "Kernel " + (SystemMonitorService.kernelVersion || "Loading...") + " • Host: " + (SystemMonitorService.hostName || "localhost")
                    font.pixelSize: 11
                    font.family: "Google Sans"
                    color: root.textMuted
                }

                Text {
                    text: (SystemMonitorService.wmVersion || "Hyprland") + " • Shell: " + (SystemMonitorService.userShell || "bash")
                    font.pixelSize: 11
                    font.family: "Google Sans"
                    color: root.textMuted
                }

                Row {
                    Layout.topMargin: 4
                    spacing: -6

                    readonly property var paletteColors: [
                        { color: Colors.cfg.primary, name: "Primary" },
                        { color: Colors.cfg.secondary, name: "Secondary" },
                        { color: Colors.cfg.tertiary, name: "Tertiary" },
                        { color: Colors.cfg.surfaceContainer, name: "Surface" },
                        { color: Colors.cfg.warning, name: "Warning" },
                        { color: Colors.cfg.error, name: "Error" }
                    ]

                    Repeater {
                        model: parent.paletteColors

                        Rectangle {
                            id: dotRect
                            required property var modelData
                            required property int index

                            width: 24
                            height: 24
                            radius: 12
                            color: modelData.color
                            z: 10 - index
                            border.width: 2
                            border.color: root.surface

                            scale: dotMa.containsMouse ? 1.25 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                            MouseArea {
                                id: dotMa
                                anchors.fill: parent
                                hoverEnabled: true
                            }

                            ToolTip.visible: dotMa.containsMouse
                            ToolTip.text: modelData.name + ": " + modelData.color
                            ToolTip.delay: 200
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                spacing: 8

                SettingButton {
                    text: qsTr("Copy Specs")
                    icon: "content_copy"
                    variant: "secondary"
                    compact: true
                    onClicked: tabRoot.copyAllSpecs()
                }

                SettingButton {
                    text: qsTr("Reload Shell")
                    icon: "refresh"
                    variant: "primary"
                    compact: true
                    onClicked: {
                        if (root && root.reloadShellProc) {
                            root.reloadShellProc.running = true;
                        } else {
                            Quickshell.reload(true);
                        }
                    }
                }
            }
        }
    }

    SettingSectionHeader {
        id: hwHeader
        icon: "memory"
        title: qsTr("Hardware & Specifications")
        description: qsTr("Live telemetry for processor, graphics, memory, and storage")
        collapsible: true
        hint: qsTr("Displays live hardware usage percentages, temperatures, and storage metrics")
        targetContent: hwGrid
    }

    GridLayout {
        id: hwGrid
        columns: 2
        columnSpacing: 12
        rowSpacing: 12
        Layout.fillWidth: true

        AboutCard {
            icon: "memory"
            label: qsTr("Processor (CPU)")
            value: SystemMonitorService.cpuModel
            subtitle: SystemMonitorService.cpuCores + " Cores • " + SystemMonitorService.cpuTemp + "°C • " + Math.round(SystemMonitorService.cpuPercent) + "% load"
            progress: SystemMonitorService.cpuPercent / 100.0
            copyText: SystemMonitorService.cpuModel
            accentColor: Colors.cfg.primary
            onCopied: (t) => root.showToast(qsTr("CPU model copied"), "content_copy")
        }

        AboutCard {
            icon: "videogame_asset"
            label: qsTr("Graphics (GPU)")
            value: SystemMonitorService.gpuName
            subtitle: (SystemMonitorService.gpuTemp > 0 ? (SystemMonitorService.gpuTemp + "°C • ") : "") + Math.round(SystemMonitorService.gpuPercent) + "% load" + (SystemMonitorService.gpuTotalGb > 0 ? (" • " + SystemMonitorService.gpuUsedGb + "/" + SystemMonitorService.gpuTotalGb + " GB") : "")
            progress: SystemMonitorService.gpuPercent / 100.0
            copyText: SystemMonitorService.gpuName
            accentColor: Colors.cfg.secondary
            onCopied: (t) => root.showToast(qsTr("GPU model copied"), "content_copy")
        }

        AboutCard {
            icon: "memory"
            label: qsTr("System Memory")
            value: SystemMonitorService.memUsedGb + " GB / " + SystemMonitorService.memTotalGb + " GB"
            subtitle: Math.round(SystemMonitorService.memPercent) + "% used" + (SystemMonitorService.swapPercent > 0 ? (" • Swap " + Math.round(SystemMonitorService.swapPercent) + "%") : "")
            progress: SystemMonitorService.memPercent / 100.0
            copyText: SystemMonitorService.memUsedGb + " GB / " + SystemMonitorService.memTotalGb + " GB"
            accentColor: Colors.cfg.primary
            onCopied: (t) => root.showToast(qsTr("Memory info copied"), "content_copy")
        }

        AboutCard {
            icon: "hard_drive"
            label: qsTr("Root Storage (/)")
            value: SystemMonitorService.diskUsedGb + " GB / " + SystemMonitorService.diskTotalGb + " GB"
            subtitle: SystemMonitorService.diskFreeGb + " GB free (" + Math.round(SystemMonitorService.diskPercent) + "% used)"
            progress: SystemMonitorService.diskPercent / 100.0
            copyText: SystemMonitorService.diskUsedGb + " GB / " + SystemMonitorService.diskTotalGb + " GB"
            accentColor: Colors.cfg.tertiary
            onCopied: (t) => root.showToast(qsTr("Storage info copied"), "content_copy")
        }
    }

    SettingSectionHeader {
        id: swHeader
        icon: "terminal"
        title: qsTr("Software & Desktop Environment")
        description: qsTr("Compositor, kernel build, user shell, and package manager")
        collapsible: true
        hint: qsTr("Software environment and package management details")
        targetContent: swGrid
    }

    GridLayout {
        id: swGrid
        columns: 2
        columnSpacing: 12
        rowSpacing: 12
        Layout.fillWidth: true

        AboutCard {
            icon: "laptop"
            label: qsTr("Operating System")
            value: SystemMonitorService.distroName
            subtitle: (SystemMonitorService.arch || "x86_64") + " • Host: " + (SystemMonitorService.hostName || "localhost")
            copyText: SystemMonitorService.distroName
            accentColor: Colors.cfg.primary
            onCopied: (t) => root.showToast(qsTr("OS info copied"), "content_copy")
        }

        AboutCard {
            icon: "desktop_windows"
            label: qsTr("Window Manager")
            value: SystemMonitorService.wmVersion || "Hyprland"
            subtitle: qsTr("Wayland display server compositor")
            copyText: SystemMonitorService.wmVersion || "Hyprland"
            accentColor: Colors.cfg.secondary
            onCopied: (t) => root.showToast(qsTr("WM version copied"), "content_copy")
        }

        AboutCard {
            icon: "terminal"
            label: qsTr("Linux Kernel")
            value: SystemMonitorService.kernelVersion || "Loading..."
            subtitle: qsTr("Core system kernel build")
            copyText: SystemMonitorService.kernelVersion
            accentColor: Colors.cfg.tertiary
            onCopied: (t) => root.showToast(qsTr("Kernel version copied"), "content_copy")
        }

        AboutCard {
            icon: "widgets"
            label: qsTr("Packages")
            value: SystemMonitorService.packageCount || "Loading..."
            subtitle: qsTr("Installed packages in package manager")
            copyText: SystemMonitorService.packageCount
            accentColor: Colors.cfg.primary
            onCopied: (t) => root.showToast(qsTr("Packages count copied"), "content_copy")
        }

        AboutCard {
            icon: "terminal"
            label: qsTr("Default Shell")
            value: SystemMonitorService.userShell || "bash"
            subtitle: qsTr("Interactive command interpreter")
            copyText: SystemMonitorService.userShell
            accentColor: Colors.cfg.secondary
            onCopied: (t) => root.showToast(qsTr("Shell name copied"), "content_copy")
        }

        AboutCard {
            icon: "schedule"
            label: qsTr("System Uptime")
            value: SystemMonitorService.uptimeStr || "Loading..."
            subtitle: qsTr("Time elapsed since system startup")
            copyText: SystemMonitorService.uptimeStr
            accentColor: Colors.cfg.tertiary
            onCopied: (t) => root.showToast(qsTr("Uptime copied"), "content_copy")
        }
    }

    SettingSectionHeader {
        id: updateHeader
        icon: "system_update"
        title: qsTr("Software Updates")
        description: qsTr("System releases, update channel and automatic update preferences")
        collapsible: true
        hint: qsTr("Check for Asura Shell updates and configure automatic background updates")
        targetContent: updateCard
    }

    Rectangle {
        id: updateCard
        Layout.fillWidth: true
        implicitHeight: updateCol.implicitHeight + 32
        radius: 14
        color: root.surface
        border.color: root.borderCol
        border.width: 1

        ColumnLayout {
            id: updateCol
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                Rectangle {
                    implicitWidth: 46
                    implicitHeight: 46
                    radius: 12
                    color: Qt.alpha(UpdateService.updateAvailable ? Colors.cfg.warning : Colors.cfg.primary, 0.15)
                    border.color: Qt.alpha(UpdateService.updateAvailable ? Colors.cfg.warning : Colors.cfg.primary, 0.35)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: UpdateService.updating ? "sync" : (UpdateService.updateAvailable ? "system_update" : "verified")
                        font.pixelSize: 24
                        font.family: "Material Symbols Rounded"
                        color: UpdateService.updateAvailable ? Colors.cfg.warning : Colors.cfg.primary

                        RotationAnimation on rotation {
                            running: UpdateService.checking || UpdateService.updating
                            from: 0
                            to: 360
                            loops: Animation.Infinite
                            duration: 1200
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        spacing: 8

                        Text {
                            text: qsTr("Asura Shell Updates")
                            font.pixelSize: 15
                            font.bold: true
                            font.family: "Google Sans"
                            color: root.textBright
                        }

                        Rectangle {
                            implicitWidth: badgeText.implicitWidth + 12
                            implicitHeight: 20
                            radius: 10
                            color: {
                                if (UpdateService.updating) return Qt.alpha(Colors.cfg.primary, 0.2);
                                if (UpdateService.checking) return Qt.alpha(Colors.cfg.tertiary, 0.2);
                                if (UpdateService.updateAvailable) return Qt.alpha(Colors.cfg.warning, 0.2);
                                return Qt.alpha(Colors.cfg.secondary, 0.2);
                            }
                            border.color: {
                                if (UpdateService.updating) return Qt.alpha(Colors.cfg.primary, 0.5);
                                if (UpdateService.checking) return Qt.alpha(Colors.cfg.tertiary, 0.5);
                                if (UpdateService.updateAvailable) return Qt.alpha(Colors.cfg.warning, 0.5);
                                return Qt.alpha(Colors.cfg.secondary, 0.5);
                            }
                            border.width: 1

                            Text {
                                id: badgeText
                                anchors.centerIn: parent
                                text: {
                                    if (UpdateService.updating) return qsTr("Updating...");
                                    if (UpdateService.checking) return qsTr("Checking...");
                                    if (UpdateService.updateAvailable) return qsTr("Update Available");
                                    return qsTr("Up to Date");
                                }
                                font.pixelSize: 10
                                font.bold: true
                                font.family: "Google Sans"
                                color: {
                                    if (UpdateService.updating) return Colors.cfg.primary;
                                    if (UpdateService.checking) return Colors.cfg.tertiary;
                                    if (UpdateService.updateAvailable) return Colors.cfg.warning;
                                    return Colors.cfg.secondary;
                                }
                            }
                        }
                    }

                    Text {
                        text: UpdateService.statusMessage + (UpdateService.lastCheckStr !== "" ? (" • " + qsTr("Last checked at %1").arg(UpdateService.lastCheckStr)) : "")
                        font.pixelSize: 11
                        font.family: "Google Sans"
                        color: root.textMuted
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 12
                rowSpacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 68
                    radius: 12
                    color: Qt.alpha(Colors.cfg.surfaceContainer, 0.6)
                    border.color: Qt.alpha(Colors.cfg.base03, 0.4)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Rectangle {
                            implicitWidth: 36
                            implicitHeight: 36
                            radius: 10
                            color: Qt.alpha(Colors.cfg.primary, 0.15)

                            Text {
                                anchors.centerIn: parent
                                text: "check_circle"
                                font.pixelSize: 20
                                font.family: "Material Symbols Rounded"
                                color: Colors.cfg.primary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: qsTr("INSTALLED VERSION")
                                font.pixelSize: 10
                                font.bold: true
                                font.family: "Google Sans"
                                color: Colors.cfg.textSecondary
                            }

                            Text {
                                text: UpdateService.currentVersion
                                font.pixelSize: 15
                                font.bold: true
                                font.family: "Google Sans"
                                color: root.textBright
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 68
                    radius: 12
                    color: UpdateService.updateAvailable ? Qt.alpha(Colors.cfg.primary, 0.08) : Qt.alpha(Colors.cfg.surfaceContainer, 0.6)
                    border.color: UpdateService.updateAvailable ? Qt.alpha(Colors.cfg.primary, 0.45) : Qt.alpha(Colors.cfg.base03, 0.4)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Rectangle {
                            implicitWidth: 36
                            implicitHeight: 36
                            radius: 10
                            color: Qt.alpha(UpdateService.updateAvailable ? Colors.cfg.primary : Colors.cfg.secondary, 0.15)

                            Text {
                                anchors.centerIn: parent
                                text: UpdateService.updateAvailable ? "upgrade" : "task_alt"
                                font.pixelSize: 20
                                font.family: "Material Symbols Rounded"
                                color: UpdateService.updateAvailable ? Colors.cfg.primary : Colors.cfg.secondary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: qsTr("LATEST VERSION")
                                font.pixelSize: 10
                                font.bold: true
                                font.family: "Google Sans"
                                color: Colors.cfg.textSecondary
                            }

                            Text {
                                text: UpdateService.latestVersion
                                font.pixelSize: 15
                                font.bold: true
                                font.family: "Google Sans"
                                color: UpdateService.updateAvailable ? Colors.cfg.primary : root.textBright
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                SettingButton {
                    text: UpdateService.checking ? qsTr("Checking...") : qsTr("Check for Updates")
                    icon: "refresh"
                    variant: "secondary"
                    compact: true
                    disabled: UpdateService.checking || UpdateService.updating
                    onClicked: {
                        UpdateService.checkForUpdates(true);
                    }
                }

                SettingButton {
                    text: UpdateService.updating ? qsTr("Updating...") : qsTr("Update Now")
                    icon: "system_update"
                    variant: "primary"
                    compact: true
                    disabled: UpdateService.updating || (!UpdateService.updateAvailable && !UpdateService.checking)
                    onClicked: {
                        root.showToast(qsTr("Starting update process..."), "system_update");
                        UpdateService.applyUpdate();
                    }
                }

                Item { Layout.fillWidth: true }
            }

            SettingDivider {}

            SettingToggle {
                icon: "autorenew"
                title: qsTr("Automatic Updates")
                description: qsTr("Periodically check for updates in background and automatically apply new releases")
                hint: qsTr("Checks every 12-24h using a low-overhead cached probe and automatically pulls improvements")
                checked: Config.cfg.autoUpdate
                onToggled: (newState) => {
                    Config.cfg.autoUpdate = newState;
                    Config.save();
                    root.showToast(newState ? qsTr("Automatic updates enabled") : qsTr("Automatic updates disabled"), "autorenew");
                }
            }
        }
    }

    SettingSectionHeader {
        id: asuraHeader
        icon: "info"
        title: qsTr("About Asura Shell")
        description: qsTr("Reactive Wayland shell engine powered by Quickshell & Qt 6")
        collapsible: true
        hint: qsTr("Quick links to configuration files, directories, and documentation")
        targetContent: asuraCard
    }

    Rectangle {
        id: asuraCard
        Layout.fillWidth: true
        implicitHeight: asuraCol.implicitHeight + 32
        radius: 14
        color: root.surface
        border.color: root.borderCol
        border.width: 1

        ColumnLayout {
            id: asuraCol
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                Rectangle {
                    implicitWidth: 46
                    implicitHeight: 46
                    radius: 12
                    color: Qt.alpha(Colors.cfg.primary, 0.15)
                    border.color: Qt.alpha(Colors.cfg.primary, 0.35)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "info"
                        font.pixelSize: 22
                        font.family: "Material Symbols Rounded"
                        color: Colors.cfg.primary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Asura Shell"
                        font.pixelSize: 15
                        font.bold: true
                        font.family: "Google Sans"
                        color: root.textBright
                    }

                    Text {
                        text: qsTr("Modern, reactive desktop shell for Hyprland • Quickshell & Qt 6")
                        font.pixelSize: 10
                        font.family: "Google Sans"
                        color: root.textMuted
                    }
                }
            }

            SettingDivider {}

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                SettingButton {
                    text: qsTr("Config Directory")
                    icon: "folder"
                    variant: "secondary"
                    compact: true
                    onClicked: {
                        Quickshell.execDetached(["xdg-open", Quickshell.env("HOME") + "/.config/asura"]);
                    }
                }

                SettingButton {
                    text: qsTr("Shell Source")
                    icon: "code"
                    variant: "secondary"
                    compact: true
                    onClicked: {
                        Quickshell.execDetached(["xdg-open", Quickshell.shellPath("")]);
                    }
                }

                Item { Layout.fillWidth: true }

                SettingButton {
                    text: qsTr("View Keybinds")
                    icon: "keyboard"
                    variant: "primary"
                    compact: true
                    onClicked: {
                        root.currentTab = "shortcuts";
                    }
                }
            }
        }
    }
}
