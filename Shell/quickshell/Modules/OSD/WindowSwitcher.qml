import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Io

import Quickshell.Wayland
import Quickshell.Hyprland

import qs.Asura
import qs.Services
import qs.Components

PanelWindow {
    id: root

    WlrLayershell.namespace: "window-switcher"

    property color primary: Colors.cfg.primary
    property color secondary: Colors.cfg.secondary
    property color background: Colors.cfg.background
    property color surfaceContainer: Colors.cfg.surfaceContainer
    property color on_primary: Colors.cfg.on_primary
    property color text: Colors.cfg.text

    property alias color1: root.primary
    property alias color2: root.secondary
    property alias foreground: root.on_primary
    property alias textColor: root.text

    property bool isOpen: false

    property var windowList: []
    property int selectedIndex: 0
    property string initialAddress: ""

    property real cacheVersion: Date.now()

    property var pendingToplevel: null
    property var retryToplevel: null

    readonly property string focusedMonitorName: (Hyprland.focusedMonitor && Hyprland.focusedMonitor.name) ? Hyprland.focusedMonitor.name : ""

    screen: {
        if (root.focusedMonitorName && Quickshell.screens) {
            var target = Quickshell.screens.find(s => s.name === root.focusedMonitorName)
            if (target) return target
        }
        return (Quickshell.screens && Quickshell.screens.length > 0) ? Quickshell.screens[0] : null
    }

    // Guarded screen dimensions to avoid null references during monitor transitions
    property real screenWidth: (root.screen && root.screen.width) ? root.screen.width : 1920
    property real screenHeight: (root.screen && root.screen.height) ? root.screen.height : 1080

    property int calcCols: Math.min(6, Math.max(1, root.windowList.length))
    property int calcRows: Math.max(1, Math.ceil(root.windowList.length / Math.max(1, calcCols)))
    property real maxAllowedWidth: (root.screenWidth - 128 - (calcCols - 1) * 16) / Math.max(1, calcCols)
    property real maxAllowedHeight: (root.screenHeight - 180 - (calcRows - 1) * 16) / Math.max(1, calcRows)
    property real dynItemWidth: Math.floor(Math.max(120, Math.min(320, Math.min(maxAllowedWidth, maxAllowedHeight * (320.0 / 380.0)))))
    property real dynItemHeight: Math.floor(dynItemWidth * (380.0 / 320.0))
    property real scaleFactor: dynItemWidth / 320.0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: root.isOpen || (switcherCard && switcherCard.opacity > 0.001)

    Item {
        id: emptyMask
        width: 0
        height: 0
    }

    mask: Region {
        item: (root.isOpen || (switcherCard && switcherCard.opacity > 0.001)) ? backdropArea : emptyMask
    }

    Timer {
        id: refreshTimer
        interval: 100
        repeat: false
        onTriggered: {
            if (root.isOpen)
                root.refreshWindowList(true)
        }
    }

    Timer {
        id: initialRefreshTimer
        interval: 120
        repeat: false
        onTriggered: {
            if (!root.isOpen) return
            Hyprland.refreshToplevels()
            root.refreshWindowList(true)
        }
    }

    Timer {
        id: focusTimer
        interval: 70
        repeat: false
        onTriggered: {
            var target = root.pendingToplevel
            root.pendingToplevel = null
            if (!target || !target.address) return

            Qt.callLater(function() {
                if (target.wayland) target.wayland.activate()
                var rawAddr = target.address.toString().replace(/^0x/, "")
                var addr = "0x" + rawAddr
                Hyprland.dispatch('hl.dsp.focus({window = "address:' + addr + '"})')
                root.retryToplevel = target
                focusRetryTimer.restart()
            })
        }
    }

    Timer {
        id: focusRetryTimer
        interval: 180
        repeat: false
        onTriggered: {
            var target = root.retryToplevel
            root.retryToplevel = null
            if (!target || !target.address) return
            if (target.activated) return
            if (target.wayland) target.wayland.activate()
            var rawAddr = target.address.toString().replace(/^0x/, "")
            var addr = "0x" + rawAddr
            Hyprland.dispatch('hl.dsp.focus({window = "address:' + addr + '"})')
        }
    }

    IpcHandler {
        target: "switcher"

        function toggle() {
            if (root.isOpen) root.next()
            else root.openSwitcher()
        }
        function open() { root.openSwitcher() }
        function close() { root.isOpen = false }
        function next() {
            if (!root.isOpen) { root.openSwitcher(); return }
            if (root.windowList.length <= 0) return
            root.selectedIndex = (root.selectedIndex + 1) % root.windowList.length
        }
        function prev() {
            if (!root.isOpen) { root.openSwitcher(); return }
            if (root.windowList.length <= 0) return
            root.selectedIndex = (root.selectedIndex - 1 + root.windowList.length) % root.windowList.length
        }
        function select() { root.focusCurrent() }
    }

    function collectToplevels() {
        var result = []
        var seen = {}

        if (Hyprland.toplevels && Hyprland.toplevels.values) {
            var allTls = [...Hyprland.toplevels.values]
            for (var k = 0; k < allTls.length; k++) {
                var tl = allTls[k]
                if (!tl || !tl.address || seen[tl.address]) continue
                seen[tl.address] = true
                result.push(tl)
            }
        }

        if (Hyprland.workspaces && Hyprland.workspaces.values) {
            var workspaces = [...Hyprland.workspaces.values]
            for (var i = 0; i < workspaces.length; i++) {
                var workspace = workspaces[i]
                if (!workspace || !workspace.toplevels) continue
                var toplevels = [...workspace.toplevels.values]

                for (var j = 0; j < toplevels.length; j++) {
                    var toplevel = toplevels[j]
                    if (!toplevel || !toplevel.address || seen[toplevel.address]) continue
                    seen[toplevel.address] = true
                    result.push(toplevel)
                }
            }
        }
        return result
    }

    function areListsEqual(a, b) {
        if (!a || !b || a.length !== b.length) return false
        for (var i = 0; i < a.length; i++) {
            if (!a[i] || !b[i] || a[i].address !== b[i].address) return false
        }
        return true
    }

    function refreshWindowList(preserveSelection) {
        var previousAddress = ""
        if (preserveSelection && root.windowList.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.windowList.length) {
            var previous = root.windowList[root.selectedIndex]
            if (previous) previousAddress = previous.address || ""
        }

        var list = root.collectToplevels()
        list = list.filter(toplevel => {
            if (!toplevel || !toplevel.address) return false
            if (!toplevel.workspace) return false
            if (!toplevel.title || toplevel.title.trim().length === 0) return false

            var ipc = toplevel.lastIpcObject
            if (!ipc || ipc.mapped !== true) return false
            if (ipc.size && ipc.size[0] <= 0 && ipc.size[1] <= 0) return false

            var appClass = (ipc && ipc.class) ? ipc.class : (toplevel.wayland ? (toplevel.wayland.appId || "") : "")
            if (!appClass || appClass.trim().length === 0) return false
            if (appClass === "org.quickshell" || appClass === "quickshell") return false
            if (toplevel.title === "Shell Settings") return false

            return true
        })

        list.sort((a, b) => {
            if (a.activated && !b.activated) return -1
            if (!a.activated && b.activated) return 1
            var aIpc = a.lastIpcObject
            var bIpc = b.lastIpcObject
            var fa = aIpc && typeof aIpc.focusHistoryID === "number" ? aIpc.focusHistoryID : 9999
            var fb = bIpc && typeof bIpc.focusHistoryID === "number" ? bIpc.focusHistoryID : 9999
            return fa - fb
        })

        // Avoid reassigning windowList if the list has not changed to prevent resetting delegates
        var listChanged = !areListsEqual(list, root.windowList)
        if (listChanged) {
            root.windowList = list
        }

        if (list.length === 0) {
            root.selectedIndex = 0
            root.initialAddress = ""
            return
        }

        if (preserveSelection && previousAddress) {
            for (var i = 0; i < list.length; i++) {
                if (list[i].address === previousAddress) {
                    root.selectedIndex = i
                    return
                }
            }
        }

        if (listChanged || !preserveSelection) {
            var activeIndex = -1
            for (var j = 0; j < list.length; j++) {
                if (list[j].activated) {
                    activeIndex = j
                    break
                }
            }

            if (list.length > 1) {
                root.selectedIndex = activeIndex >= 0 ? (activeIndex + 1) % list.length : 1
            } else {
                root.selectedIndex = 0
            }

            root.initialAddress = activeIndex >= 0 ? list[activeIndex].address : list[0].address
        }
    }

    function openSwitcher() {
        root.pendingToplevel = null
        root.retryToplevel = null
        root.isOpen = true
        root.cacheVersion = Date.now()
        Hyprland.refreshToplevels()
        root.refreshWindowList(false)
        keyItem.forceActiveFocus()
        initialRefreshTimer.restart()
    }

    function focusWindow(toplevel) {
        if (!toplevel || !toplevel.address) return
        root.pendingToplevel = toplevel
        root.isOpen = false
        focusTimer.restart()
    }

    function closeWindow(toplevel) {
        if (!toplevel || !toplevel.address) return
        if (toplevel.wayland) toplevel.wayland.close()
        var rawAddr = toplevel.address.toString().replace(/^0x/, "")
        var addr = "0x" + rawAddr
        Hyprland.dispatch('hl.dsp.window.close({window = "address:' + addr + '"})')
        refreshTimer.restart()
    }

    function focusCurrent() {
        if (root.windowList.length === 0 || root.selectedIndex < 0 || root.selectedIndex >= root.windowList.length) {
            root.isOpen = false
            return
        }
        var target = root.windowList[root.selectedIndex]
        if (target) root.focusWindow(target)
    }

    onIsOpenChanged: {
        if (!root.isOpen) {
            refreshTimer.stop()
            initialRefreshTimer.stop()
        }
    }


    Item {
        id: keyItem
        anchors.fill: parent
        focus: root.isOpen

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Tab) {
                if (event.modifiers & Qt.ShiftModifier) root.prev()
                else root.next()
                event.accepted = true
                return
            }
            if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
                root.next()
                event.accepted = true
                return
            }
            if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                root.prev()
                event.accepted = true
                return
            }
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                root.focusCurrent()
                event.accepted = true
                return
            }
            if (event.key === Qt.Key_Escape) {
                root.isOpen = false
                root.pendingToplevel = null
                root.retryToplevel = null
                event.accepted = true
            }
        }

        Keys.onReleased: function(event) {
            if (event.key === Qt.Key_Alt) {
                root.focusCurrent()
                event.accepted = true
            }
        }
    }

    MouseArea {
        id: backdropArea
        anchors.fill: parent
        enabled: root.isOpen
        onClicked: {
            root.isOpen = false
            root.pendingToplevel = null
        }
    }

    Item {
        id: switcherCard
        anchors.centerIn: parent

        width: Math.min(root.screenWidth - 80, Math.max(20, cardRow.implicitWidth))
        height: Math.min(root.screenHeight - 100, Math.max(120, cardRow.implicitHeight))

        visible: root.isOpen || opacity > 0.001
        scale: root.isOpen ? 1.0 : 0.95
        opacity: root.isOpen ? 1.0 : 0.0

        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Flickable {
            id: flickContainer
            anchors.fill: parent
            contentWidth: cardRow.implicitWidth
            contentHeight: cardRow.implicitHeight
            clip: false
            boundsBehavior: Flickable.StopAtBounds

            Grid {
                id: cardRow
                columns: root.calcCols
                spacing: 16
                anchors.horizontalCenter: (width < parent.width) ? parent.horizontalCenter : undefined
                anchors.verticalCenter: (height < parent.height) ? parent.verticalCenter : undefined

                Repeater {
                    id: previewRepeater
                    model: root.windowList

                        delegate: Rectangle {
                            id: winItemRoot
                            required property HyprlandToplevel modelData
                            required property int index

                            readonly property HyprlandToplevel targetToplevel: modelData
                            readonly property string targetAddress: (targetToplevel && targetToplevel.address) ? targetToplevel.address : ""
                            readonly property string cleanAddress: targetAddress ? targetAddress.toString().replace(/^0x/, "") : ""
                            readonly property string targetTitle: (targetToplevel && targetToplevel.title) ? targetToplevel.title : ""
                            readonly property var ipcData: targetToplevel ? targetToplevel.lastIpcObject : null
                            readonly property string appClass: (ipcData && ipcData.class) ? ipcData.class : (targetToplevel && targetToplevel.wayland ? (targetToplevel.wayland.appId || "") : "")

                            readonly property bool isSelected: index === root.selectedIndex
                            readonly property bool isSpecialWorkspace: {
                                if (!targetToplevel || !targetToplevel.workspace) return false
                                var ws = targetToplevel.workspace
                                return (ws.id < 0 || (ws.name && ws.name.indexOf("special") !== -1))
                            }


                            implicitWidth: root.dynItemWidth
                            implicitHeight: root.dynItemHeight
                            radius: Math.max(4, 8 * root.scaleFactor)

                            color: isSelected
                                ? Qt.alpha(root.color1, 0.18)
                                : (itemHover.hovered
                                    ? Qt.alpha(root.surfaceContainer, 0.9 * Config.effectiveGeneralOpacity)
                                    : Qt.alpha(root.surfaceContainer, 0.75 * Config.effectiveGeneralOpacity))
                            border.color: isSelected ? root.color1 : Qt.alpha(root.textColor, 0.1)
                            border.width: isSelected ? 2 : 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Math.max(4, 10 * root.scaleFactor)
                                spacing: Math.max(4, 10 * root.scaleFactor)

                                Rectangle {
                                    id: previewBox
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: width
                                    radius: Math.max(2, 6 * root.scaleFactor)
                                    color: winItemRoot.isSelected ? Qt.alpha(root.color1, 0.12) : Qt.alpha(root.background, 0.8)
                                    border.color: winItemRoot.isSelected ? Qt.alpha(root.color1, 0.3) : Qt.alpha(root.textColor, 0.08)
                                    border.width: 1
                                    clip: true

                                    Image {
                                        id: cachedPreviewImage
                                        anchors.fill: parent
                                        fillMode: Image.PreserveAspectCrop
                                        cache: true
                                        asynchronous: true
                                        source: winItemRoot.cleanAddress !== "" ? ("file:///tmp/qs_preview_" + winItemRoot.cleanAddress + ".png") : ""
                                        visible: status === Image.Ready
                                    }

                                    Item {
                                        anchors.fill: parent
                                        visible: !cachedPreviewImage.visible

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: Math.max(36, 64 * root.scaleFactor)
                                            height: Math.max(36, 64 * root.scaleFactor)
                                            radius: width / 2
                                            color: winItemRoot.isSelected ? Qt.alpha(root.color1, 0.25) : Qt.alpha(root.color1, 0.12)
                                            border.color: winItemRoot.isSelected ? root.color1 : "transparent"
                                            border.width: 1

                                            ThemedIcon {
                                                anchors.centerIn: parent
                                                size: Math.max(20, Math.floor(32 * root.scaleFactor))
                                                source: ActiveWindowService.getAppIcon(winItemRoot.appClass, winItemRoot.targetTitle)
                                                color: winItemRoot.isSelected ? root.color1 : root.textColor
                                            }
                                        }
                                    }

                                    Rectangle {
                                        anchors.top: parent.top
                                        anchors.left: parent.left
                                        anchors.margins: Math.max(2, 6 * root.scaleFactor)
                                        width: Math.max(16, 24 * root.scaleFactor)
                                        height: Math.max(12, 18 * root.scaleFactor)
                                        radius: Math.max(2, 4 * root.scaleFactor)
                                        color: winItemRoot.isSpecialWorkspace ? Qt.alpha(Colors.cfg.secondary, 0.8) : Qt.alpha(root.background, 0.8)
                                        border.color: Qt.alpha(root.textColor, 0.1)
                                        border.width: 1
                                        visible: winItemRoot.isSpecialWorkspace || (winItemRoot.targetToplevel && winItemRoot.targetToplevel.workspace && winItemRoot.targetToplevel.workspace.id > 1)
                                        Text {
                                            anchors.centerIn: parent
                                            text: winItemRoot.isSpecialWorkspace ? "S" : (winItemRoot.targetToplevel && winItemRoot.targetToplevel.workspace ? winItemRoot.targetToplevel.workspace.id : "")
                                            font.pixelSize: Math.max(8, Math.floor(10 * root.scaleFactor))
                                            font.bold: true
                                            color: winItemRoot.isSpecialWorkspace ? Colors.cfg.secondary : root.textColor
                                        }
                                    }

                                    Rectangle {
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: Math.max(2, 6 * root.scaleFactor)
                                        width: Math.max(16, 24 * root.scaleFactor)
                                        height: Math.max(16, 24 * root.scaleFactor)
                                        radius: width / 2
                                        color: closeWinH.hovered ? Colors.cfg.warning : Qt.alpha(root.background, 0.85)
                                        border.color: Qt.alpha(root.textColor, 0.1)
                                        border.width: 1
                                        visible: itemHover.hovered
                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰅖"
                                            font.pixelSize: Math.max(8, Math.floor(12 * root.scaleFactor))
                                            color: closeWinH.hovered ? root.background : root.textColor
                                        }
                                        HoverHandler { id: closeWinH }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.closeWindow(winItemRoot.targetToplevel)
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Math.max(2, 8 * root.scaleFactor)

                                    ThemedIcon {
                                        size: Math.max(10, Math.floor(16 * root.scaleFactor))
                                        source: ActiveWindowService.getAppIcon(winItemRoot.appClass, winItemRoot.targetTitle)
                                        color: winItemRoot.isSelected ? root.color1 : root.textColor
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        Text {
                                            text: ActiveWindowService.getAppFriendlyName(winItemRoot.appClass, winItemRoot.targetTitle)
                                            font.pixelSize: Math.max(9, Math.floor(13 * root.scaleFactor))
                                            font.bold: true
                                            color: root.text
                                            font.family: "Google Sans"
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: winItemRoot.targetTitle
                                            font.pixelSize: Math.max(8, Math.floor(11 * root.scaleFactor))
                                            color: Qt.alpha(root.textColor, 0.6)
                                            font.family: "Google Sans"
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }

                            HoverHandler { id: itemHover }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onEntered: root.selectedIndex = winItemRoot.index
                                onClicked: root.focusWindow(winItemRoot.targetToplevel)
                            }
                        }
                    }

                    Text {
                        visible: root.windowList.length === 0
                        text: "No open windows"
                        font.pixelSize: 14
                        font.family: "Google Sans"
                        color: Qt.alpha(root.textColor, 0.5)
                    }
                }
            }
        }
    }