import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Animations
import qs.Asura
import qs.Components
import qs.Services

Rectangle {
    id: root

    radius: 18
    color: root.surface
    // Semantic colors
    property color primary: Colors.cfg.primary
    property color secondary: Colors.cfg.secondary
    property color tertiary: Colors.cfg.tertiary
    property color background: Colors.cfg.background
    property color surface: Qt.alpha(Colors.cfg.surface, Math.max(0, Math.min(1, Config.cfg.opacity)))
    property color surfaceContainer: Colors.cfg.surfaceContainer
    property color surfaceVariant: Colors.cfg.surfaceVariant
    property color borderCol: Colors.cfg.border
    property color on_primary: Colors.cfg.on_primary
    property color text: Colors.cfg.text
    property color textSecondary: Colors.cfg.textSecondary
    property color textBright: Colors.cfg.textBright
    property color warning: Colors.cfg.warning
    property color error: Colors.cfg.error
    property color success: Colors.cfg.success

    // Compatibility aliases
    property alias color1: root.primary
    property alias color2: root.secondary
    property alias textColor: root.text
    property alias textMuted: root.textSecondary
    property alias foreground: root.on_primary

    // Whether this tab is currently selected and visible
    property bool tabActive: false

    // Staggered entrance animations for system monitor cards
    CardEntrance {
        id: cpuEntrance
        active: root.tabActive
        delay: 20
        startOffsetY: 18
    }

    CardEntrance {
        id: ramEntrance
        active: root.tabActive
        delay: 70
        startOffsetY: 18
    }

    CardEntrance {
        id: gpuEntrance
        active: root.tabActive
        delay: 120
        startOffsetY: 18
    }

    CardEntrance {
        id: procEntrance
        active: root.tabActive
        delay: 170
        startOffsetY: 20
    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        // ── 3 Main Metrics Cards (CPU, RAM, GPU) with Circular Gauges ──
                        RowLayout {
                            // ================================================================
                            // CPU
                            // ================================================================
                            // ================================================================
                            // RAM
                            // ================================================================
                            // ================================================================
                            // GPU
                            // ================================================================

                            Layout.fillWidth: true
                            Layout.preferredHeight: 195
                            spacing: 12

                            Rectangle {
                                id: cpuCard

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 14
                                color: root.surface
                                scale: cpuHover.hovered ? 1.015 : 1
                                opacity: cpuEntrance.opacity

                                transform: [
                                    Scale {
                                        origin.x: cpuCard.width / 2
                                        origin.y: cpuCard.height / 2
                                        xScale: cpuEntrance.scale
                                        yScale: cpuEntrance.scale
                                    },
                                    Translate {
                                        y: cpuEntrance.offsetY
                                    }
                                ]

                                HoverHandler {
                                    id: cpuHover
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 4

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Text {
                                            text: "󰻠  CPU"
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: root.color1
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: SystemMonitorService.cpuTemp + "°C"
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: SystemMonitorService.cpuTemp > 75 ? Colors.cfg.warning : root.textMuted
                                        }

                                    }

                                    Item {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true

                                        OrganicProgress {
                                            anchors.fill: parent
                                            color: root.color1
                                            value: SystemMonitorService.cpuPercent / 100
                                            lineWidth: 8
                                            organicAmount: 2
                                        }

                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 2

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: SystemMonitorService.cpuPercent.toFixed(1) + "%"
                                                font.pixelSize: 15
                                                font.bold: true
                                                color: root.textColor
                                                scale: cpuHover.hovered ? 1.04 : 1

                                                Behavior on scale {
                                                    NumberAnimation {
                                                        duration: 180
                                                        easing.type: Easing.OutCubic
                                                    }

                                                }

                                            }

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: SystemMonitorService.cpuCores + " Cores"
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: root.textMuted
                                            }

                                        }

                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: SystemMonitorService.cpuModel
                                        font.pixelSize: 10
                                        color: root.textMuted
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                    }

                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 180
                                        easing.type: Easing.OutCubic
                                    }

                                }

                            }

                            Rectangle {
                                id: ramCard

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 14
                                color: root.surface
                                scale: ramHover.hovered ? 1.015 : 1
                                opacity: ramEntrance.opacity

                                transform: [
                                    Scale {
                                        origin.x: ramCard.width / 2
                                        origin.y: ramCard.height / 2
                                        xScale: ramEntrance.scale
                                        yScale: ramEntrance.scale
                                    },
                                    Translate {
                                        y: ramEntrance.offsetY
                                    }
                                ]

                                HoverHandler {
                                    id: ramHover
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 4

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Text {
                                            text: "󰘚  RAM"
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: Colors.cfg.secondary
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: SystemMonitorService.swapPercent > 0 ? ("Swap: " + SystemMonitorService.swapPercent.toFixed(0) + "%") : "Normal"
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: root.textMuted
                                        }

                                    }

                                    Item {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true

                                        OrganicProgress {
                                            anchors.fill: parent
                                            color: Colors.cfg.secondary
                                            value: SystemMonitorService.memPercent / 100
                                            lineWidth: 8
                                            organicAmount: 2
                                        }

                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 2

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: SystemMonitorService.memPercent.toFixed(1) + "%"
                                                font.pixelSize: 15
                                                font.bold: true
                                                color: root.textColor
                                                scale: ramHover.hovered ? 1.04 : 1

                                                Behavior on scale {
                                                    NumberAnimation {
                                                        duration: 180
                                                        easing.type: Easing.OutCubic
                                                    }

                                                }

                                            }

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: SystemMonitorService.memUsedGb.toFixed(1) + " / " + SystemMonitorService.memTotalGb.toFixed(1) + " GB"
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: root.textMuted
                                            }

                                        }

                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: (SystemMonitorService.memTotalGb - SystemMonitorService.memUsedGb).toFixed(1) + " GB Free"
                                        font.pixelSize: 10
                                        color: root.textMuted
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                    }

                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 180
                                        easing.type: Easing.OutCubic
                                    }

                                }

                            }

                            Rectangle {
                                id: gpuCard

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 14
                                color: root.surface
                                scale: gpuHover.hovered ? 1.015 : 1
                                opacity: gpuEntrance.opacity

                                transform: [
                                    Scale {
                                        origin.x: gpuCard.width / 2
                                        origin.y: gpuCard.height / 2
                                        xScale: gpuEntrance.scale
                                        yScale: gpuEntrance.scale
                                    },
                                    Translate {
                                        y: gpuEntrance.offsetY
                                    }
                                ]

                                HoverHandler {
                                    id: gpuHover
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 4

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Text {
                                            text: "󰢮  GPU"
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: Colors.cfg.warning
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: SystemMonitorService.gpuAvailable ? (SystemMonitorService.gpuTemp + "°C") : "N/A"
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: (SystemMonitorService.gpuAvailable && SystemMonitorService.gpuTemp > 80) ? Colors.cfg.warning : root.textMuted
                                        }

                                    }

                                    Item {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true

                                        OrganicProgress {
                                            anchors.fill: parent
                                            color: Colors.cfg.warning
                                            value: SystemMonitorService.gpuPercent / 100
                                            lineWidth: 8
                                            organicAmount: 2.2
                                        }

                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 2

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: SystemMonitorService.gpuPercent.toFixed(1) + "%"
                                                font.pixelSize: 15
                                                font.bold: true
                                                color: root.textColor
                                                scale: gpuHover.hovered ? 1.04 : 1

                                                Behavior on scale {
                                                    NumberAnimation {
                                                        duration: 180
                                                        easing.type: Easing.OutCubic
                                                    }

                                                }

                                            }

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: SystemMonitorService.gpuAvailable && SystemMonitorService.gpuTotalGb > 0 ? (SystemMonitorService.gpuUsedGb.toFixed(1) + " / " + SystemMonitorService.gpuTotalGb.toFixed(1) + " GB") : (SystemMonitorService.gpuAvailable ? "Active" : "0.0 / 0.0 GB")
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: root.textMuted
                                            }

                                        }

                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: SystemMonitorService.gpuAvailable ? SystemMonitorService.gpuName : "No dedicated GPU"
                                        font.pixelSize: 10
                                        color: root.textMuted
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                    }

                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 180
                                        easing.type: Easing.OutCubic
                                    }

                                }

                            }

                        }

                        // ── Bottom: Top Active Processes Table ──
                        Rectangle {
                            id: procCard
                            Layout.fillWidth: true
                            height: 145
                            radius: 14
                            clip: true
                            color: root.surfaceContainer
                            opacity: procEntrance.opacity
                            scale: procEntrance.scale
                            transform: Translate {
                                y: procEntrance.offsetY
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 0

                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        text: "Top Active Processes (CPU / Memory)"
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: root.textMuted
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: "PID"
                                        font.pixelSize: 10
                                        color: root.textMuted
                                        Layout.preferredWidth: 60
                                        horizontalAlignment: Text.AlignRight
                                    }

                                    Text {
                                        text: "CPU"
                                        font.pixelSize: 10
                                        color: root.textMuted
                                        Layout.preferredWidth: 65
                                        horizontalAlignment: Text.AlignRight
                                    }

                                    Text {
                                        text: "MEM"
                                        font.pixelSize: 10
                                        color: root.textMuted
                                        Layout.preferredWidth: 65
                                        horizontalAlignment: Text.AlignRight
                                    }

                                }

                                Repeater {
                                    model: SystemMonitorService.topProcs || []

                                    delegate: Rectangle {
                                        id: procItem

                                        required property var modelData
                                        required property int index

                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 22
                                        radius: 6
                                        color: index % 2 === 0 ? Qt.alpha(root.textColor, 0.03) : "transparent"

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 6
                                            anchors.rightMargin: 6
                                            spacing: 8

                                            Text {
                                                text: procItem.modelData.name
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: root.textColor
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                text: String(procItem.modelData.pid)
                                                font.pixelSize: 9
                                                font.family: "GeistMono Nerd Font Propo"
                                                color: root.textMuted
                                                Layout.preferredWidth: 60
                                                horizontalAlignment: Text.AlignRight
                                            }

                                            Rectangle {
                                                Layout.preferredWidth: 55
                                                Layout.preferredHeight: 18
                                                radius: 4
                                                color: Qt.alpha(root.color1, 0.15)

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: procItem.modelData.cpu.toFixed(1) + "%"
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                    color: root.color1
                                                }

                                            }

                                            Rectangle {
                                                Layout.preferredWidth: 55
                                                Layout.preferredHeight: 18
                                                radius: 4
                                                color: Qt.alpha(Colors.cfg.secondary, 0.15)

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: procItem.modelData.mem.toFixed(1) + "%"
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                    color: Colors.cfg.secondary
                                                }

                                            }

                                        }

                                    }

                                }

                                Item {
                                    Layout.fillHeight: true
                                }

                            }

                        }

                    }


}
