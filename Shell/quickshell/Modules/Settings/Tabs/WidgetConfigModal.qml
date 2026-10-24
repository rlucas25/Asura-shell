import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Asura
import qs.Services
import "../Components"

Item {
    id: widgetConfigModalRoot

    required property var settingsRoot
    readonly property var root: settingsRoot

        anchors.fill: parent
        visible: root.showWidgetConfigModal
        z: 99990
        opacity: root.showWidgetConfigModal ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        readonly property bool currentWidgetHasCapsule: {
            if (!root.activeConfigWidget || !root.activeConfigZone) return false;
            var dummy = BarWidgetService.leftWidgets.length + BarWidgetService.centerWidgets.length + BarWidgetService.rightWidgets.length;
            var list = (root.activeConfigZone === "left" ? BarWidgetService.leftWidgets :
                       (root.activeConfigZone === "center" ? BarWidgetService.centerWidgets : BarWidgetService.rightWidgets));
            if (list) {
                for (var i = 0; i < list.length; i++) {
                    if (list[i].id === root.activeConfigWidget.id) {
                        return BarWidgetService.itemHasBackground(list[i]);
                    }
                }
            }
            return BarWidgetService.itemHasBackground(root.activeConfigWidget);
        }

        function toggleCapsule() {
            if (!root.activeConfigWidget || !root.activeConfigZone) return;
            BarWidgetService.toggleBackground(root.activeConfigZone, root.activeConfigWidget.id);
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.65)

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closeWidgetConfigModal()
            }
        }

        Rectangle {
            id: widgetModalCard
            anchors.centerIn: parent
            width: Math.min(520, parent.width - 40)
            height: Math.min(parent.height - 60, modalCol.implicitHeight + 36)
            radius: 16
            color: root.surface
            border.color: Qt.alpha(root.color1, 0.45)
            border.width: 1.5
            clip: true
            scale: root.showWidgetConfigModal ? 1 : 0.95

            Behavior on scale {
                NumberAnimation { duration: 200; easing.type: Easing.OutBack }
            }

            MouseArea {
                anchors.fill: parent
            }

            Flickable {
                anchors.fill: parent
                anchors.margins: 18
                contentHeight: modalCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: modalCol
                    width: parent.width
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Rectangle {
                            implicitWidth: 38
                            implicitHeight: 38
                            radius: 10
                            color: Qt.alpha(root.color1, 0.15)
                            border.color: Qt.alpha(root.color1, 0.35)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: root.activeConfigWidget ? BarWidgetService.getWidgetInfo(root.activeConfigWidget.type).icon : "widgets"
                                font.pixelSize: 18
                                font.family: "Material Symbols Rounded"
                                color: root.color1
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                spacing: 8

                                Text {
                                    text: root.activeConfigWidget ? BarWidgetService.getWidgetInfo(root.activeConfigWidget.type).name : ""
                                    font.pixelSize: 14
                                    font.bold: true
                                    font.family: "Google Sans"
                                    color: root.textColor
                                }

                                Rectangle {
                                    implicitWidth: zoneBadgeText.implicitWidth + 10
                                    implicitHeight: 20
                                    radius: 6
                                    color: Qt.alpha(root.color2, 0.18)
                                    border.color: Qt.alpha(root.color2, 0.4)
                                    border.width: 1

                                    Text {
                                        id: zoneBadgeText
                                        anchors.centerIn: parent
                                        text: {
                                            if (root.activeConfigZone === "left") return qsTr("Left Zone");
                                            if (root.activeConfigZone === "center") return qsTr("Center Zone");
                                            return qsTr("Right Zone");
                                        }
                                        font.pixelSize: 9
                                        font.bold: true
                                        font.family: "Google Sans"
                                        color: root.color2
                                    }
                                }
                            }

                            Text {
                                text: root.activeConfigWidget ? BarWidgetService.getWidgetInfo(root.activeConfigWidget.type).description : ""
                                font.pixelSize: 10
                                font.family: "Google Sans"
                                color: root.textMuted
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }
                        }

                        SettingButton {
                            variant: "ghost"
                            icon: "close"
                            compact: true
                            onClicked: root.closeWidgetConfigModal()
                        }
                    }

                    SettingDivider {
                        Layout.fillWidth: true
                    }

                    SettingCard {
                        Layout.fillWidth: true

                        SettingToggle {
                            icon: widgetConfigModalRoot.currentWidgetHasCapsule ? "crop_din" : "crop_free"
                            title: qsTr("Capsule Background")
                            description: qsTr("Enclose inside status capsule pill. Consecutive capsule widgets merge into sleek connected pills.")
                            checked: widgetConfigModalRoot.currentWidgetHasCapsule
                            onToggled: (val) => widgetConfigModalRoot.toggleCapsule()
                        }
                    }

                    ColumnLayout {
                        visible: root.activeConfigWidget && root.activeConfigWidget.type === "workspaces"
                        Layout.fillWidth: true
                        spacing: 12

                        SettingCard {
                            Layout.fillWidth: true

                            SettingSectionHeader {
                                title: qsTr("Workspace Switcher Configuration")
                                icon: "space_dashboard"
                                extraContent: Rectangle {
                                    implicitWidth: modalWsPreviewRow.implicitWidth + 14
                                    implicitHeight: 24
                                    radius: 6
                                    color: Qt.alpha(Colors.cfg.primary, 0.15)
                                    border.color: Qt.alpha(Colors.cfg.primary, 0.4)
                                    border.width: 1

                                    RowLayout {
                                        id: modalWsPreviewRow
                                        anchors.centerIn: parent
                                        spacing: 5

                                        Text {
                                            text: qsTr("Preview:")
                                            font.pixelSize: 9
                                            font.family: "Google Sans"
                                            color: root.textMuted
                                        }

                                        RowLayout {
                                            spacing: 4

                                            Repeater {
                                                model: Math.min(5, ((Config.cfg && Config.cfg.workspacesCount !== undefined) ? Math.max(1, Config.cfg.workspacesCount) : 3))

                                                Rectangle {
                                                    readonly property int wsNum: index + 1
                                                    implicitWidth: index === 0 ? (Config.cfg && Config.cfg.workspacesShowNumbers ? 22 : 16) : 10
                                                    implicitHeight: 12
                                                    radius: 100
                                                    color: index === 0 ? Colors.cfg.primary : Qt.alpha(Colors.cfg.primary, 0.4)

                                                    Text {
                                                        anchors.centerIn: parent
                                                        visible: index === 0 && Config.cfg && Config.cfg.workspacesShowNumbers
                                                        text: (Config.cfg && Config.cfg.workspacesNumberStyle === "common") ? wsNum.toString() : (wsNum === 1 ? "I" : (wsNum === 2 ? "II" : wsNum.toString()))
                                                        font.pixelSize: 8
                                                        font.bold: true
                                                        font.family: "Google Sans"
                                                        color: Colors.cfg.on_primary
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            SettingDivider { Layout.fillWidth: true }

                            SettingSlider {
                                title: qsTr("Default Workspaces Count")
                                description: qsTr("Number of default visible workspaces on the bar")
                                from: 1
                                to: 10
                                stepSize: 1
                                value: (Config.cfg && Config.cfg.workspacesCount !== undefined) ? Config.cfg.workspacesCount : 3
                                customValueText: Math.round(value).toString()
                                onMoved: (val) => {
                                    Config.cfg.workspacesCount = Math.round(val);
                                    Config.save();
                                }
                            }

                            SettingDivider { Layout.fillWidth: true }

                            SettingToggle {
                                title: qsTr("Workspace Numbering")
                                description: qsTr("Display numbers inside the active and hovered workspace nodes")
                                checked: Boolean(Config.cfg && Config.cfg.workspacesShowNumbers)
                                onToggled: (val) => {
                                    Config.cfg.workspacesShowNumbers = val;
                                    Config.save();
                                }
                            }

                            SettingDivider {
                                Layout.fillWidth: true
                                visible: Config.cfg && Config.cfg.workspacesShowNumbers
                            }

                            SettingPills {
                                visible: Config.cfg && Config.cfg.workspacesShowNumbers
                                model: [
                                    { id: "roman", label: qsTr("Roman (I, II)") },
                                    { id: "common", label: qsTr("Common (1, 2)") }
                                ]
                                currentValue: (Config.cfg && Config.cfg.workspacesNumberStyle) ? Config.cfg.workspacesNumberStyle : "roman"
                                onSelected: (val) => {
                                    Config.cfg.workspacesNumberStyle = val;
                                    Config.save();
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        visible: root.activeConfigWidget && root.activeConfigWidget.type === "clock"
                        Layout.fillWidth: true
                        spacing: 12

                        SettingCard {
                            Layout.fillWidth: true

                            SettingSectionHeader {
                                title: qsTr("Clock Display Format")
                                icon: "schedule"
                                extraContent: Rectangle {
                                    implicitWidth: modalClockPreviewRow.implicitWidth + 14
                                    implicitHeight: 24
                                    radius: 6
                                    color: Qt.alpha(Colors.cfg.primary, 0.15)
                                    border.color: Qt.alpha(Colors.cfg.primary, 0.4)
                                    border.width: 1

                                    RowLayout {
                                        id: modalClockPreviewRow
                                        anchors.centerIn: parent
                                        spacing: 5

                                        Text {
                                            text: qsTr("Preview:")
                                            font.pixelSize: 9
                                            font.family: "Google Sans"
                                            color: root.textMuted
                                        }

                                        Text {
                                            text: {
                                                var now = new Date();
                                                var is24 = (Config.cfg && Config.cfg.clock24h);
                                                var t = Qt.formatTime(now, is24 ? "HH:mm" : "hh:mm AP");
                                                var fmt = (Config.cfg && Config.cfg.clockFormat) ? Config.cfg.clockFormat : "time_calendar";
                                                if (fmt === "time_only") return t;
                                                if (fmt === "time_day") return t + " • " + Qt.formatDate(now, "ddd");
                                                if (fmt === "time_day_month") return t + " • " + Qt.formatDate(now, "dd MMM");
                                                if (fmt === "time_full") return t + " • " + Qt.formatDate(now, "dddd, dd MMM");
                                                return t + " • " + Qt.formatDate(now, "ddd, dd/MM");
                                            }
                                            font.pixelSize: 10
                                            font.bold: true
                                            font.family: "GeistMono Nerd Font Propo"
                                            color: Colors.cfg.primary
                                        }
                                    }
                                }
                            }

                            SettingDivider { Layout.fillWidth: true }

                            SettingPills {
                                model: [
                                    { id: "time_calendar", label: qsTr("Time & Calendar") },
                                    { id: "time_only", label: qsTr("Only Time") },
                                    { id: "time_day", label: qsTr("Time & Day") },
                                    { id: "time_day_month", label: qsTr("Time, Day & Month") },
                                    { id: "time_full", label: qsTr("Full Date") }
                                ]
                                currentValue: (Config.cfg && Config.cfg.clockFormat) ? Config.cfg.clockFormat : "time_calendar"
                                onSelected: (val) => {
                                    Config.cfg.clockFormat = val;
                                    Config.save();
                                }
                            }

                            SettingDivider { Layout.fillWidth: true }

                            SettingToggle {
                                title: qsTr("24-Hour Time Format")
                                description: qsTr("Show 16:30 instead of 04:30 PM")
                                checked: Boolean(Config.cfg && Config.cfg.clock24h)
                                onToggled: (val) => {
                                    Config.cfg.clock24h = val;
                                    Config.save();
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        visible: root.activeConfigWidget && (["cpu", "ram", "gpu", "disk"].indexOf(root.activeConfigWidget.type) !== -1)
                        Layout.fillWidth: true
                        spacing: 12

                        SettingCard {
                            Layout.fillWidth: true

                            SettingSectionHeader {
                                title: qsTr("Resource Display Mode")
                                icon: "memory"
                            }

                            SettingDivider { Layout.fillWidth: true }

                            SettingToggle {
                                title: qsTr("Hide Percentage / Values")
                                description: qsTr("Show only the circular progress ring and icon, hiding numeric labels")
                                checked: Boolean(Config.cfg && Config.cfg.hardwareHidePercent)
                                onToggled: (val) => {
                                    Config.cfg.hardwareHidePercent = val;
                                    Config.save();
                                }
                            }

                            SettingDivider { Layout.fillWidth: true }

                            SettingToggle {
                                title: qsTr("Show Absolute Values instead of Percentages")
                                description: qsTr("Display real units (e.g. GBs used for RAM and Disk, °C/GHz for CPU and GPU)")
                                checked: Boolean(Config.cfg && Config.cfg.hardwareShowAbsolute)
                                onToggled: (val) => {
                                    Config.cfg.hardwareShowAbsolute = val;
                                    Config.save();
                                }
                            }
                        }
                    }

                    SettingCard {
                        visible: root.activeConfigWidget && root.activeConfigWidget.type === "launcher"
                        Layout.fillWidth: true

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Rectangle {
                                implicitWidth: 32
                                implicitHeight: 32
                                radius: 8
                                color: Qt.alpha(Colors.cfg.primary, 0.15)
                                border.color: Qt.alpha(Colors.cfg.primary, 0.35)
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "rocket_launch"
                                    font.pixelSize: 18
                                    font.family: "Material Symbols Rounded"
                                    color: Colors.cfg.primary
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: qsTr("Advanced Launcher Configuration")
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.family: "Google Sans"
                                    color: Colors.cfg.textBright
                                }

                                Text {
                                    text: qsTr("Configure launcher mode (Classic, Compact, Zen) and position in the Launcher tab.")
                                    font.pixelSize: 9
                                    font.family: "Google Sans"
                                    color: Colors.cfg.textSecondary
                                }
                            }

                            SettingButton {
                                text: qsTr("Open Tab")
                                icon: "arrow_forward"
                                variant: "secondary"
                                compact: true
                                onClicked: {
                                    root.currentTab = "launcher";
                                    root.closeWidgetConfigModal();
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Item { Layout.fillWidth: true }

                        SettingButton {
                            text: qsTr("Done")
                            variant: "primary"
                            onClicked: root.closeWidgetConfigModal()
                        }
                    }
                }
            }
        }
    }
