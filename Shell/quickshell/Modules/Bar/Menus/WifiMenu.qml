import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.Asura
import qs.Services
import qs.Animations

Item {
    id: root

    MenuEntrance {
        id: wifiEntrance
        active: root.visible
        duration: 320
        startOffsetY: 14
    }

    property color background: Colors.cfg.background
    property color surfaceContainer: Colors.cfg.background
    property color primary: Colors.cfg.primary
    property color on_primary: Colors.cfg.on_primary
    property color textColor: Colors.cfg.text
    property color secondary: Colors.cfg.secondary
    property color warning: Colors.cfg.warning
    property color success: Colors.cfg.success

    implicitWidth: 360
    implicitHeight: 440
    clip: true

    property string expandingSsid: ""
    property string currentPassword: ""
    property bool showHiddenConnect: false
    property string hiddenSsid: ""
    property string hiddenPassword: ""

    // Pause periodic polling when user is interacting with an input field
    Binding {
        target: WifiService
        property: "paused"
        value: (root.expandingSsid !== "" || root.showHiddenConnect)
    }

    onVisibleChanged: {
        if (!visible) {
            root.expandingSsid = "";
            root.currentPassword = "";
            root.showHiddenConnect = false;
            root.hiddenSsid = "";
            root.hiddenPassword = "";
        }
    }

    function getSignalColor(signal) {
        if (signal >= 70)
            return Colors.cfg.success;
        if (signal >= 40)
            return Colors.cfg.primary;
        if (signal >= 20)
            return Colors.cfg.secondary;
        return Colors.cfg.warning;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10
        opacity: wifiEntrance.opacity
        transform: Translate {
            y: wifiEntrance.offsetY
        }

        // 1. HEADER
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            spacing: 8

            // Wireless Title
            Row {
                Layout.fillWidth: true
                spacing: 8
                Layout.alignment: Qt.AlignVCenter

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        text: "Wireless"
                        color: root.textColor
                        font {
                            family: "Goggle Sans"
                            pixelSize: 16
                            bold: true
                        }
                    }

                    Text {
                        text: !WifiService.wifiEnabled ? "Disabled" : ("Enabled")
                        color: root.primary
                        font {
                            family: "Google Sans"
                            pixelSize: 12
                        }
                        elide: Text.ElideRight
                        width: 140
                    }
                }
            }

            // Rescan Button
            Rectangle {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                radius: 15
                color: rescanArea.containsMouse ? Qt.alpha(root.primary, 0.18) : "transparent"
                visible: WifiService.wifiEnabled

                Text {
                    id: scanIcon
                    anchors.centerIn: parent
                    text: "󰑐"
                    color: root.primary
                    font {
                        family: "GeistMono Nerd Font Propo"
                        pixelSize: 15
                    }

                    RotationAnimator {
                        target: scanIcon
                        from: 0
                        to: 360
                        duration: 800
                        loops: Animation.Infinite
                        running: WifiService.isScanning
                    }
                }

                MouseArea {
                    id: rescanArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WifiService.rescan()
                }
            }

            // Master Toggle Switch
            Rectangle {
                id: toggleBg
                Layout.preferredWidth: 46
                Layout.preferredHeight: 24
                radius: 12
                color: WifiService.wifiEnabled ? root.primary : Qt.alpha(root.primary, 0.3)

                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }

                Rectangle {
                    id: toggleKnob
                    width: 18
                    height: 18
                    radius: 9
                    anchors.verticalCenter: parent.verticalCenter
                    x: WifiService.wifiEnabled ? parent.width - width - 3 : 3
                    color: WifiService.wifiEnabled ? root.on_primary : root.textColor

                    Behavior on x {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WifiService.toggleWifi(!WifiService.wifiEnabled)
                }
            }
        }

        // ETHERNET (WIRED) CONNECTION CARD
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: ethCardCol.implicitHeight + 16
            visible: WifiService.ethernetConnected
            radius: 14
            color: Qt.alpha(root.primary, 0.12)
            border.color: Qt.alpha(root.primary, 0.35)
            border.width: 1

            ColumnLayout {
                id: ethCardCol
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: ""
                        color: root.primary
                        font {
                            family: "GeistMono Nerd Font Propo Propo"
                            pixelSize: 22
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: WifiService.ethernetName || "Wired Connection"
                                color: root.textColor
                                font {
                                    family: "GeistMono Nerd Font Propo"
                                    pixelSize: 13
                                    bold: true
                                }
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Rectangle {
                                implicitWidth: 72
                                implicitHeight: 18
                                radius: 9
                                color: Qt.alpha(Colors.cfg.success, 0.2)
                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 3
                                    Text {
                                        text: "●"
                                        font.pixelSize: 7
                                        color: Colors.cfg.success
                                    }
                                    Text {
                                        text: "Connected"
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: Colors.cfg.success
                                    }
                                }
                            }
                        }

                        RowLayout {
                            spacing: 8
                            Text {
                                text: "Interface: " + WifiService.ethernetIface
                                color: Qt.alpha(root.textColor, 0.6)
                                font {
                                    family: "GeistMono Nerd Font Propo"
                                    pixelSize: 10
                                }
                            }
                            Text {
                                visible: WifiService.ethernetIp !== ""
                                text: "•  IP: " + WifiService.ethernetIp
                                color: Qt.alpha(root.textColor, 0.6)
                                font {
                                    family: "GeistMono Nerd Font Propo"
                                    pixelSize: 10
                                }
                            }
                        }
                    }
                }
            }
        }

        // 2. ACTIVE CONNECTION CARD
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: activeCardCol.implicitHeight + 16
            visible: WifiService.wifiEnabled && WifiService.connected
            radius: 14
            color: Qt.alpha(root.surfaceContainer, 0.7)
            border.color: Qt.alpha(root.primary, 0.3)
            border.width: 1

            ColumnLayout {
                id: activeCardCol
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: WifiService.getSignalIcon(WifiService.activeSignal, true)
                        color: root.getSignalColor(WifiService.activeSignal)
                        font {
                            family: "Material Symbols Rounded"
                            pixelSize: 25
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: WifiService.activeSsid
                            color: root.textColor
                            font {
                                family: "GeistMono Nerd Font Propo"
                                pixelSize: 13
                                bold: true
                            }
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Row {
                            spacing: 6
                            Text {
                                text: WifiService.activeSignal + "%"
                                color: root.getSignalColor(WifiService.activeSignal)
                                font {
                                    family: "GeistMono Nerd Font Propo"
                                    pixelSize: 10
                                    bold: true
                                }
                            }
                            Text {
                                text: "•"
                                color: root.primary
                                font.pixelSize: 10
                            }
                            Text {
                                text: WifiService.activeBand !== "" ? WifiService.activeBand : "Wi-Fi"
                                color: root.primary
                                font {
                                    family: "GeistMono Nerd Font Propo"
                                    pixelSize: 10
                                }
                            }
                            Text {
                                text: WifiService.activeIp !== "" ? "• " + WifiService.activeIp : ""
                                color: root.primary
                                font {
                                    family: "GeistMono Nerd Font Propo"
                                    pixelSize: 10
                                }
                                visible: WifiService.activeIp !== ""
                            }
                        }
                    }

                    // Disconnect Button
                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 8
                        color: disconnArea.containsMouse ? Qt.alpha(root.warning, 0.25) : Qt.alpha(root.warning, 0.1)

                        Text {
                            anchors.centerIn: parent
                            text: "󰅙"
                            color: root.warning
                            font {
                                family: "GeistMono Nerd Font Propo"
                                pixelSize: 14
                            }
                        }

                        MouseArea {
                            id: disconnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WifiService.disconnect()
                        }
                    }
                }
            }
        }

        // 3. STATUS / FEEDBACK BANNER
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: WifiService.statusMessage !== "" ? 28 : 0
            visible: WifiService.statusMessage !== ""
            radius: 8
            color: WifiService.isError ? Qt.alpha(root.warning, 0.2) : Qt.alpha(root.primary, 0.2)
            clip: true

            Behavior on Layout.preferredHeight {
                NumberAnimation {
                    duration: 200
                }
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: WifiService.isError ? "󰅚" : (WifiService.connectingSsid !== "" ? "󰑐" : "󰄬")
                    color: WifiService.isError ? root.warning : root.primary
                    font {
                        family: "GeistMono Nerd Font Propo"
                        pixelSize: 12
                    }
                }

                Text {
                    text: WifiService.statusMessage
                    color: WifiService.isError ? root.warning : root.textColor
                    font {
                        family: "GeistMono Nerd Font Propo"
                        pixelSize: 11
                    }
                }
            }
        }

        // 4. AVAILABLE NETWORKS LIST
        RowLayout {
            Layout.fillWidth: true
            visible: WifiService.wifiEnabled

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: WifiService.networks.length + " found"
                color: root.primary
                font {
                    family: "GeistMono Nerd Font Propo"
                    pixelSize: 10
                }
            }
        }

        // Wi-Fi Disabled State
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !WifiService.wifiEnabled
            color: "transparent"

            Column {
                anchors.centerIn: parent
                spacing: 12

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "󰤮"
                    color: root.primary
                    font {
                        family: "GeistMono Nerd Font Propo Propo"
                        pixelSize: 42
                    }
                    opacity: 0.5
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Wi-Fi is disabled"
                    color: root.textColor
                    font {
                        family: "GeistMono Nerd Font Propo"
                        pixelSize: 13
                        bold: true
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 110
                    height: 32
                    radius: 16
                    color: enableArea.containsMouse ? root.primary : Qt.alpha(root.primary, 0.8)

                    Text {
                        anchors.centerIn: parent
                        text: "Active Wi-fi"
                        color: root.on_primary
                        font {
                            family: "GeistMono Nerd Font Propo"
                            pixelSize: 12
                            bold: true
                        }
                    }

                    MouseArea {
                        id: enableArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WifiService.toggleWifi(true)
                    }
                }
            }
        }

        // Networks List
        Flickable {
            id: netFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: netCol.implicitHeight
            clip: true
            visible: WifiService.wifiEnabled

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            ColumnLayout {
                id: netCol
                width: netFlick.width
                spacing: 6

                // Empty / Searching state
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 20
                    visible: WifiService.networks.length === 0
                    text: WifiService.isScanning ? "Searching for Wi-Fi networks..." : "No networks found"
                    color: root.primary
                    font {
                        family: "GeistMono Nerd Font Propo"
                        pixelSize: 12
                    }
                }

                // Networks Repeater
                Repeater {
                    model: WifiService.networks

                    delegate: Rectangle {
                        id: itemCard
                        Layout.fillWidth: true
                        Layout.preferredHeight: itemInnerCol.implicitHeight + 10
                        radius: 12
                        color: {
                            if (modelData.active)
                                return Qt.alpha(root.primary, 0.15);
                            if (netMouse.containsMouse || root.expandingSsid === modelData.ssid)
                                return Qt.alpha(root.surfaceContainer, 0.9);
                            return Qt.alpha(root.surfaceContainer, 0.45);
                        }
                        border.color: modelData.active ? Qt.alpha(root.primary, 0.4) : (root.expandingSsid === modelData.ssid ? Qt.alpha(root.primary, 0.3) : "transparent")
                        border.width: 1

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }

                        // Background mouse area for whole item
                        MouseArea {
                            id: netMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.active) {
                                    return;
                                }
                                if (modelData.saved || !modelData.secure) {
                                    // Connect directly
                                    root.expandingSsid = "";
                                    root.currentPassword = "";
                                    WifiService.connect(modelData.ssid, "");
                                } else {
                                    // Toggle password expansion
                                    if (root.expandingSsid === modelData.ssid) {
                                        root.expandingSsid = "";
                                        root.currentPassword = "";
                                    } else {
                                        root.expandingSsid = modelData.ssid;
                                        root.currentPassword = "";
                                        root.showHiddenConnect = false;
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            id: itemInnerCol
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: 8
                            }
                            spacing: 6

                            // Main row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                // Signal Icon
                                Text {
                                    text: WifiService.getSignalIcon(modelData.signal, true)
                                    color: root.getSignalColor(modelData.signal)
                                    font {
                                        family: "Material Symbols Rounded"
                                        pixelSize: 25
                                    }
                                }

                                // SSID & Info
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    RowLayout {
                                        spacing: 6

                                        Text {
                                            text: modelData.ssid
                                            color: root.textColor
                                            font {
                                                family: "GeistMono Nerd Font Propo"
                                                pixelSize: 12
                                                bold: modelData.active || modelData.saved
                                            }
                                            elide: Text.ElideRight
                                            Layout.maximumWidth: 160
                                        }

                                        Rectangle {
                                            Layout.preferredHeight: 14
                                            Layout.preferredWidth: savedTxt.implicitWidth + 8
                                            radius: 7
                                            color: Qt.alpha(root.primary, 0.2)
                                            visible: modelData.saved && !modelData.active

                                            Text {
                                                id: savedTxt
                                                anchors.centerIn: parent
                                                text: "Saved"
                                                color: root.primary
                                                font {
                                                    family: "GeistMono Nerd Font Propo"
                                                    pixelSize: 9
                                                }
                                            }
                                        }
                                    }

                                    Row {
                                        spacing: 4
                                        Text {
                                            text: modelData.signal + "%"
                                            color: root.primary
                                            font {
                                                family: "GeistMono Nerd Font Propo"
                                                pixelSize: 10
                                            }
                                        }
                                        Text {
                                            text: "• " + modelData.band
                                            color: root.primary
                                            font {
                                                family: "GeistMono Nerd Font Propo"
                                                pixelSize: 10
                                            }
                                        }
                                    }
                                }

                                // Right Icons / Badges
                                RowLayout {
                                    spacing: 6

                                    // Lock Icon
                                    Text {
                                        text: "󰌾"
                                        color: root.primary
                                        font {
                                            family: "GeistMono Nerd Font Propo"
                                            pixelSize: 12
                                        }
                                        visible: modelData.secure && !modelData.active
                                    }

                                    // Forget saved network button
                                    Rectangle {
                                        Layout.preferredWidth: 22
                                        Layout.preferredHeight: 22
                                        radius: 6
                                        color: forgetArea.containsMouse ? Qt.alpha(root.warning, 0.2) : "transparent"
                                        visible: modelData.saved && !modelData.active

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰩺"
                                            color: forgetArea.containsMouse ? root.warning : root.primary
                                            font {
                                                family: "GeistMono Nerd Font Propo"
                                                pixelSize: 12
                                            }
                                        }

                                        MouseArea {
                                            id: forgetArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: WifiService.forget(modelData.ssid)
                                        }
                                    }
                                }
                            }

                            // ── Inline Password Entry ─────────────────────────
                            Rectangle {
                                id: pwdBox
                                Layout.fillWidth: true
                                Layout.preferredHeight: (root.expandingSsid === modelData.ssid) ? pwdBoxCol.implicitHeight + 10 : 0
                                visible: root.expandingSsid === modelData.ssid
                                radius: 8
                                color: Qt.alpha(root.background, 0.6)
                                clip: true

                                Behavior on Layout.preferredHeight {
                                    NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                property bool showPass: false

                                ColumnLayout {
                                    id: pwdBoxCol
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        top: parent.top
                                        margins: 6
                                    }
                                    spacing: 6

                                    // Input row
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 32
                                        radius: 8
                                        color: Qt.alpha(root.surfaceContainer, 0.9)
                                        border.color: pwdInput.activeFocus ? root.primary : Qt.alpha(root.primary, 0.3)
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            spacing: 6

                                            TextInput {
                                                id: pwdInput
                                                Layout.fillWidth: true
                                                echoMode: pwdBox.showPass ? TextInput.Normal : TextInput.Password
                                                color: root.textColor
                                                font {
                                                    family: "GeistMono Nerd Font Propo"
                                                    pixelSize: 12
                                                }
                                                clip: true
                                                verticalAlignment: TextInput.AlignVCenter

                                                text: (root.expandingSsid === modelData.ssid) ? root.currentPassword : ""
                                                onTextChanged: {
                                                    if (root.expandingSsid === modelData.ssid) {
                                                        root.currentPassword = text;
                                                    }
                                                }

                                                Text {
                                                    text: "Password..."
                                                    color: root.primary
                                                    font: parent.font
                                                    visible: parent.text === ""
                                                    anchors.fill: parent
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                Keys.onReturnPressed: {
                                                    if (root.currentPassword !== "") {
                                                        const pass = root.currentPassword;
                                                        root.expandingSsid = "";
                                                        root.currentPassword = "";
                                                        WifiService.connect(modelData.ssid, pass);
                                                    }
                                                }
                                                Keys.onEscapePressed: {
                                                    root.expandingSsid = "";
                                                    root.currentPassword = "";
                                                }
                                            }

                                            // Show / Hide Password toggle
                                            Text {
                                                text: pwdBox.showPass ? "󰈈" : "󰈉"
                                                color: root.primary
                                                font {
                                                    family: "GeistMono Nerd Font Propo"
                                                    pixelSize: 14
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: pwdBox.showPass = !pwdBox.showPass
                                                }
                                            }
                                        }
                                    }

                                    // Buttons: Connect / Cancel
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 26
                                            radius: 6
                                            color: cancelArea.containsMouse ? Qt.alpha(root.primary, 0.2) : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Cancel"
                                                color: root.primary
                                                font {
                                                    family: "GeistMono Nerd Font Propo"
                                                    pixelSize: 11
                                                }
                                            }

                                            MouseArea {
                                                id: cancelArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    root.expandingSsid = "";
                                                    root.currentPassword = "";
                                                }
                                            }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 26
                                            radius: 6
                                            color: connBtnArea.containsMouse ? root.primary : Qt.alpha(root.primary, 0.85)

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Connect"
                                                color: root.on_primary
                                                font {
                                                    family: "GeistMono Nerd Font Propo"
                                                    pixelSize: 11
                                                    bold: true
                                                }
                                            }

                                            MouseArea {
                                                id: connBtnArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (root.currentPassword !== "") {
                                                        const pass = root.currentPassword;
                                                        root.expandingSsid = "";
                                                        root.currentPassword = "";
                                                        WifiService.connect(modelData.ssid, pass);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // 5. HIDDEN NETWORK CONNECTION
                Rectangle {
                    id: hiddenCard
                    Layout.fillWidth: true
                    Layout.preferredHeight: hiddenCol.implicitHeight + 12
                    radius: 12
                    color: Qt.alpha(root.surfaceContainer, 0.4)
                    border.color: root.showHiddenConnect ? Qt.alpha(root.primary, 0.3) : "transparent"
                    border.width: 1

                    ColumnLayout {
                        id: hiddenCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 8

                        // Toggle button row
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 22

                            RowLayout {
                                anchors.fill: parent
                                spacing: 8

                                Text {
                                    text: "󰤫"
                                    color: root.primary
                                    font {
                                        family: "GeistMono Nerd Font Propo Propo"
                                        pixelSize: 15
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Connect to hidden network..."
                                    color: root.textColor
                                    font {
                                        family: "GeistMono Nerd Font Propo"
                                        pixelSize: 12
                                    }
                                }

                                Text {
                                    text: root.showHiddenConnect ? "󰅃" : "󰅀"
                                    color: root.primary
                                    font {
                                        family: "GeistMono Nerd Font Propo"
                                        pixelSize: 13
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.showHiddenConnect = !root.showHiddenConnect;
                                    if (root.showHiddenConnect) {
                                        root.expandingSsid = "";
                                        root.currentPassword = "";
                                    }
                                }
                            }
                        }

                        // Hidden Network Form
                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: root.showHiddenConnect
                            spacing: 6

                            // SSID Input
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                radius: 6
                                color: Qt.alpha(root.surfaceContainer, 0.9)
                                border.color: hiddenSsidInput.activeFocus ? root.primary : Qt.alpha(root.primary, 0.3)
                                border.width: 1

                                TextInput {
                                    id: hiddenSsidInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    color: root.textColor
                                    font {
                                        family: "GeistMono Nerd Font Propo"
                                        pixelSize: 12
                                    }
                                    clip: true
                                    verticalAlignment: TextInput.AlignVCenter
                                    text: root.hiddenSsid
                                    onTextChanged: root.hiddenSsid = text

                                    Text {
                                        text: "Network Name (SSID)..."
                                        color: root.primary
                                        font: parent.font
                                        visible: parent.text === ""
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }

                            // Password Input
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                radius: 6
                                color: Qt.alpha(root.surfaceContainer, 0.9)
                                border.color: hiddenPassInput.activeFocus ? root.primary : Qt.alpha(root.primary, 0.3)
                                border.width: 1

                                TextInput {
                                    id: hiddenPassInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    echoMode: TextInput.Password
                                    color: root.textColor
                                    font {
                                        family: "GeistMono Nerd Font Propo"
                                        pixelSize: 12
                                    }
                                    clip: true
                                    verticalAlignment: TextInput.AlignVCenter
                                    text: root.hiddenPassword
                                    onTextChanged: root.hiddenPassword = text

                                    Text {
                                        text: "Password (leave empty if open)..."
                                        color: root.primary
                                        font: parent.font
                                        visible: parent.text === ""
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }

                            // Connect Button
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 28
                                radius: 6
                                color: hiddenConnArea.containsMouse ? root.primary : Qt.alpha(root.primary, 0.85)

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰄬 Connect to Hidden Network"
                                    color: root.on_primary
                                    font {
                                        family: "GeistMono Nerd Font Propo"
                                        pixelSize: 11
                                        bold: true
                                    }
                                }

                                MouseArea {
                                    id: hiddenConnArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.hiddenSsid.trim() !== "") {
                                            const ssid = root.hiddenSsid.trim();
                                            const pass = root.hiddenPassword;
                                            root.showHiddenConnect = false;
                                            root.hiddenSsid = "";
                                            root.hiddenPassword = "";
                                            WifiService.connect(ssid, pass, true);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
