import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Animations
import qs.Asura
import qs.Services

Item {
    id: root

    // === PROPERTIES ===
    property color background: Colors.cfg.background
    property color surfaceContainer: Colors.cfg.surfaceContainer
    property color primary: Colors.cfg.primary
    property color on_primary: Colors.cfg.on_primary
    property color textColor: Colors.cfg.text
    property color secondary: Colors.cfg.secondary
    property color warning: Colors.cfg.warning
    property color success: Colors.cfg.success

    // === DIMENSIONS ===
    implicitWidth: 360
    implicitHeight: 450
    clip: true

    // === ANIMATIONS ===
    MenuEntrance {
        id: btEntrance

        active: root.visible
        duration: 320
        startOffsetY: 14
    }

    // === UI CONTENT ===
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10
        opacity: btEntrance.opacity

        transform: Translate {
            y: btEntrance.offsetY
        }

        // Header section
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            spacing: 8

            // Bluetooth icon and title
            Row {
                Layout.fillWidth: true
                spacing: 8
                Layout.alignment: Qt.AlignVCenter

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        text: "Bluetooth"
                        color: root.textColor
                        font {
                            family: "Google Sans"
                            pixelSize: 16
                            bold: true
                        }
                    }

                    Text {
                        text: !BluetoothService.bluetoothEnabled ? "Disabled" : (BluetoothService.hasConnectedDevice ? BluetoothService.activeDeviceName : "Disconnected")
                        color: root.secondary
                        font {
                            family: "Google Sans"
                            pixelSize: 12
                        }
                        elide: Text.ElideRight
                        width: 140
                    }
                }
            }

            // Scan / refresh button
            Rectangle {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                radius: 15
                color: scanMouse.containsMouse ? Qt.alpha(root.primary, 0.18) : "transparent"
                visible: BluetoothService.bluetoothEnabled

                Text {
                    id: scanIcon

                    anchors.centerIn: parent
                    text: "refresh"
                    color: root.primary
                    font {
                        family: "Material Symbols Rounded"
                        pixelSize: 15
                    }

                    RotationAnimator {
                        target: scanIcon
                        from: 0
                        to: 360
                        duration: 800
                        loops: Animation.Infinite
                        running: BluetoothService.isScanning
                    }
                }

                MouseArea {
                    id: scanMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: BluetoothService.toggleScan()
                }
            }

            // Master toggle switch
            Rectangle {
                id: toggleBg

                Layout.preferredWidth: 46
                Layout.preferredHeight: 24
                radius: 12
                color: BluetoothService.bluetoothEnabled ? root.primary : Qt.alpha(root.textColor, 0.2)

                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }

                Rectangle {
                    id: toggleThumb

                    width: 18
                    height: 18
                    radius: 9
                    color: BluetoothService.bluetoothEnabled ? root.on_primary : root.textColor
                    anchors.verticalCenter: parent.verticalCenter
                    x: BluetoothService.bluetoothEnabled ? parent.width - width - 3 : 3

                    Behavior on x {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCirc
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: BluetoothService.togglePower()
                }
            }
        }

        // Status message banner
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            radius: 6
            color: Qt.alpha(root.primary, 0.15)
            visible: BluetoothService.statusMessage !== ""

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10

                Text {
                    text: BluetoothService.statusMessage
                    color: root.primary
                    font {
                        family: "Google Sans"
                        pixelSize: 11
                    }
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Qt.alpha(root.textColor, 0.08)
        }

        // === DEVICE LIST VIEW ===
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // State: bluetooth disabled
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12
                visible: !BluetoothService.bluetoothEnabled

                Text {
                    text: "bluetooth_disabled"
                    color: Qt.alpha(root.textColor, 0.3)
                    font {
                        family: "Material Symbols Rounded"
                        pixelSize: 48
                    }
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Bluetooth Disabled"
                    color: Qt.alpha(root.textColor, 0.7)
                    font {
                        family: "Google Sans"
                        pixelSize: 13
                        bold: true
                    }
                    Layout.alignment: Qt.AlignHCenter
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 140
                    implicitHeight: 32
                    radius: 8
                    color: root.primary

                    Text {
                        anchors.centerIn: parent
                        text: "Enable Bluetooth"
                        color: root.on_primary
                        font {
                            family: "Google Sans"
                            pixelSize: 12
                            bold: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: BluetoothService.togglePower()
                    }
                }
            }

            // State: bluetooth enabled device list
            Flickable {
                anchors.fill: parent
                contentHeight: deviceCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                visible: BluetoothService.bluetoothEnabled

                ColumnLayout {
                    id: deviceCol

                    width: parent.width
                    spacing: 10

                    // === CONNECTED DEVICES ===
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: BluetoothService.connectedDevices.length > 0

                        Text {
                            text: "CONNECTED DEVICES"
                            color: root.success
                            font {
                                family: "GeistMono Nerd Font Propo"
                                pixelSize: 10
                                bold: true
                            }
                            Layout.leftMargin: 2
                        }

                        Repeater {
                            model: BluetoothService.connectedDevices

                            delegate: Rectangle {
                                id: connItem

                                required property var modelData

                                Layout.fillWidth: true
                                Layout.preferredHeight: 46
                                radius: 8
                                color: Qt.alpha(root.primary, 0.12)
                                border.color: Qt.alpha(root.primary, 0.3)
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 8

                                    Text {
                                        text: BluetoothService.getDeviceIcon(connItem.modelData.icon, connItem.modelData.name)
                                        color: root.primary
                                        font {
                                            family: "Material Symbols Rounded"
                                            pixelSize: 25
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            text: connItem.modelData.name || "Device"
                                            color: root.textColor
                                            font {
                                                family: "GeistMono Nerd Font Propo"
                                                pixelSize: 12
                                                bold: true
                                            }
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        RowLayout {
                                            spacing: 6

                                            Text {
                                                text: "Connected"
                                                color: root.success
                                                font {
                                                    family: "GeistMono Nerd Font Propo"
                                                    pixelSize: 10
                                                }
                                            }

                                            Text {
                                                visible: connItem.modelData.battery !== undefined && connItem.modelData.battery >= 0
                                                text: "󰁹 " + Math.round((connItem.modelData.battery || 0) * 100) + "%"
                                                color: root.secondary
                                                font {
                                                    family: "GeistMono Nerd Font Propo"
                                                    pixelSize: 10
                                                }
                                            }
                                        }
                                    }

                                    // Disconnect button
                                    Rectangle {
                                        implicitWidth: 28
                                        implicitHeight: 28
                                        radius: 6
                                        color: disconnHover.hovered ? Qt.alpha(root.warning, 0.2) : Qt.alpha(root.textColor, 0.08)

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰅖"
                                             color: root.warning
                                            font {
                                                family: "GeistMono Nerd Font Propo Propo"
                                                pixelSize: 14
                                            }
                                        }

                                        HoverHandler {
                                            id: disconnHover
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: BluetoothService.disconnectDevice(connItem.modelData.address)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // === PAIRED DEVICES ===
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: BluetoothService.pairedDevices.length > 0

                        Text {
                            text: "PAIRED DEVICES"
                            color: Qt.alpha(root.textColor, 0.6)
                            font {
                                family: "GeistMono Nerd Font Propo"
                                pixelSize: 10
                                bold: true
                            }
                            Layout.leftMargin: 2
                        }

                        Repeater {
                            model: BluetoothService.pairedDevices

                            delegate: Rectangle {
                                id: pairedItem

                                required property var modelData

                                Layout.fillWidth: true
                                Layout.preferredHeight: 44
                                radius: 8
                                color: pairedHover.hovered ? Qt.alpha(root.textColor, 0.08) : Qt.alpha(root.textColor, 0.04)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 8

                                    Text {
                                        text: BluetoothService.getDeviceIcon(pairedItem.modelData.icon, pairedItem.modelData.name)
                                        color: Qt.alpha(root.textColor, 0.7)
                                        font {
                                            family: "Material Symbols Rounded"
                                            pixelSize: 25
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            text: pairedItem.modelData.name || "Device"
                                            color: root.textColor
                                            font {
                                                family: "GeistMono Nerd Font Propo"
                                                pixelSize: 12
                                            }
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: pairedItem.modelData.address || ""
                                            color: Qt.alpha(root.textColor, 0.4)
                                            font {
                                                family: "GeistMono Nerd Font Propo"
                                                pixelSize: 9
                                            }
                                        }
                                    }

                                    // Connect action
                                    Rectangle {
                                        implicitWidth: 28
                                        implicitHeight: 28
                                        radius: 6
                                        color: connBtnHover.hovered ? Qt.alpha(root.primary, 0.25) : Qt.alpha(root.primary, 0.1)

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰄬"
                                            color: root.primary
                                            font {
                                                family: "GeistMono Nerd Font Propo Propo"
                                                pixelSize: 14
                                            }
                                        }

                                        HoverHandler {
                                            id: connBtnHover
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: BluetoothService.connectDevice(pairedItem.modelData.address)
                                        }
                                    }

                                    // Remove / unpair action
                                    Rectangle {
                                        implicitWidth: 28
                                        implicitHeight: 28
                                        radius: 6
                                        color: removeBtnHover.hovered ? Qt.alpha(root.warning, 0.2) : Qt.alpha(root.textColor, 0.05)

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰅖"
                                            color: Qt.alpha(root.textColor, 0.5)
                                            font {
                                                family: "GeistMono Nerd Font Propo Propo"
                                                pixelSize: 12
                                            }
                                        }

                                        HoverHandler {
                                            id: removeBtnHover
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: BluetoothService.removeDevice(pairedItem.modelData.address)
                                        }
                                    }
                                }

                                HoverHandler {
                                    id: pairedHover
                                }
                            }
                        }
                    }

                    // === AVAILABLE DISCOVERED DEVICES ===
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: BluetoothService.availableDevices.length > 0

                        Text {
                            text: "NEARBY DEVICES"
                            color: Qt.alpha(root.textColor, 0.6)
                            font {
                                family: "GeistMono Nerd Font Propo"
                                pixelSize: 10
                                bold: true
                            }
                            Layout.leftMargin: 2
                        }

                        Repeater {
                            model: BluetoothService.availableDevices

                            delegate: Rectangle {
                                id: availItem

                                required property var modelData

                                Layout.fillWidth: true
                                Layout.preferredHeight: 44
                                radius: 8
                                color: availHover.hovered ? Qt.alpha(root.textColor, 0.08) : Qt.alpha(root.textColor, 0.03)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 8

                                    Text {
                                        text: BluetoothService.getDeviceIcon(availItem.modelData.icon, availItem.modelData.name)
                                        color: root.primary
                                        font {
                                            family: "GeistMono Nerd Font Propo Propo"
                                            pixelSize: 16
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            text: availItem.modelData.name || "Device"
                                            color: root.textColor
                                            font {
                                                family: "GeistMono Nerd Font Propo"
                                                pixelSize: 12
                                            }
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: availItem.modelData.address || ""
                                            color: Qt.alpha(root.textColor, 0.4)
                                            font {
                                                family: "GeistMono Nerd Font Propo"
                                                pixelSize: 9
                                            }
                                        }
                                    }

                                    // Pair button
                                    Rectangle {
                                        implicitWidth: 64
                                        implicitHeight: 26
                                        radius: 6
                                        color: pairBtnHover.hovered ? root.primary : Qt.alpha(root.primary, 0.15)

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Pair"
                                            color: pairBtnHover.hovered ? root.on_primary : root.primary
                                            font {
                                                family: "GeistMono Nerd Font Propo"
                                                pixelSize: 11
                                                bold: true
                                            }
                                        }

                                        HoverHandler {
                                            id: pairBtnHover
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: BluetoothService.pairDevice(availItem.modelData.address)
                                        }
                                    }
                                }

                                HoverHandler {
                                    id: availHover
                                }
                            }
                        }
                    }

                    // Empty state when no devices are paired or discovered
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 20
                        spacing: 8
                        visible: BluetoothService.connectedDevices.length === 0 && BluetoothService.pairedDevices.length === 0 && BluetoothService.availableDevices.length === 0

                        Text {
                            text: "󰂲"
                            color: Qt.alpha(root.textColor, 0.25)
                            font {
                                family: "GeistMono Nerd Font Propo Propo"
                                pixelSize: 32
                            }
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: BluetoothService.isScanning ? "Searching for nearby devices..." : "No Bluetooth devices found"
                            color: Qt.alpha(root.textColor, 0.5)
                            font {
                                family: "GeistMono Nerd Font Propo"
                                pixelSize: 11
                            }
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }
    }
}
