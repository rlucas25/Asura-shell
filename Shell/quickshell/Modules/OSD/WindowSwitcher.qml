import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Io

import Quickshell.Wayland
import Quickshell.Hyprland

import qs.Asura
import qs.Services

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

property var pendingToplevel: null
property var retryToplevel: null

property int previewQueueIndex: 0
property bool previewQueueBusy: false
property int previewRetryDelay: 120
property int previewMaxRetries: 3
property int previewCaptureTimeout: 1200

property int calcCols: Math.min(6, Math.max(1, root.windowList.length))
property int calcRows: Math.max(1, Math.ceil(root.windowList.length / Math.max(1, calcCols)))
property real maxAllowedWidth: (screen.width - 128 - (calcCols - 1) * 16) / Math.max(1, calcCols)
property real maxAllowedHeight: (screen.height - 180 - (calcRows - 1) * 16) / Math.max(1, calcRows)
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
visible: root.isOpen

mask: Region {
    item: root.isOpen ? backdropArea : null
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
    id: previewQueueTimer
    interval: 45
    repeat: false
    onTriggered: {
        root.captureNextPreview()
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
            Hyprland.dispatch("focuswindow", "address:" + target.address)
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
        Hyprland.dispatch("focuswindow", "address:" + target.address)
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
    var workspaces = [...Hyprland.workspaces.values]

    for (var i = 0; i < workspaces.length; i++) {
        var workspace = workspaces[i]
        if (!workspace) continue
        var toplevels = [...workspace.toplevels.values]

        for (var j = 0; j < toplevels.length; j++) {
            var toplevel = toplevels[j]
            if (!toplevel || !toplevel.address || seen[toplevel.address]) continue
            seen[toplevel.address] = true
            result.push(toplevel)
        }
    }
    return result
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
        if (!toplevel.title || toplevel.title.trim().length === 0) return false
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

    root.windowList = list

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

function resetPreviewQueue() {
    root.previewQueueIndex = 0
    root.previewQueueBusy = false
    for (var i = 0; i < previewRepeater.count; i++) {
        var item = previewRepeater.itemAt(i)
        if (item) item.resetPreview()
    }
}

function startPreviewQueue() {
    if (!root.isOpen) return
    root.previewQueueIndex = 0
    root.previewQueueBusy = false
    Qt.callLater(function() {
        if (root.isOpen) root.captureNextPreview()
    })
}

function captureNextPreview() {
    if (!root.isOpen || root.previewQueueBusy) return
    var count = previewRepeater.count
    if (count === 0) return

    for (var offset = 0; offset < count; offset++) {
        var index = (root.previewQueueIndex + offset) % count
        var item = previewRepeater.itemAt(index)

        if (!item || item.previewReady || item.previewBusy) continue

        root.previewQueueIndex = index + 1
        root.previewQueueBusy = true
        item.startPreviewCapture()
        return
    }
    root.previewQueueBusy = false
}

function previewFinished(item) {
    if (!item) return
    root.previewQueueBusy = false
    if (root.isOpen) previewQueueTimer.restart()
}

function previewRetry(item) {
    if (!item) return
    root.previewQueueBusy = true
    item.previewBusy = true
    retryPreviewTimer.itemToRetry = item
    retryPreviewTimer.restart()
}

Timer {
    id: retryPreviewTimer
    property var itemToRetry: null
    interval: root.previewRetryDelay
    repeat: false
    onTriggered: {
        var item = itemToRetry
        itemToRetry = null
        if (!root.isOpen) {
            root.previewQueueBusy = false
            return
        }
        if (!item) {
            root.previewQueueBusy = false
            root.previewQueueTimer.restart()
            return
        }
        item.startPreviewCapture()
    }
}

function openSwitcher() {
    root.pendingToplevel = null
    root.retryToplevel = null
    root.isOpen = true
    Hyprland.refreshToplevels()
    root.refreshWindowList(false)
    keyItem.forceActiveFocus()
    root.resetPreviewQueue()
    initialRefreshTimer.restart()
    Qt.callLater(function() {
        if (root.isOpen) root.startPreviewQueue()
    })
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
        previewQueueTimer.stop()
        retryPreviewTimer.stop()
        root.previewQueueBusy = false
        for (var i = 0; i < previewRepeater.count; i++) {
            var item = previewRepeater.itemAt(i)
            if (item) item.resetPreview()
        }
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
    onClicked: {
        root.isOpen = false
        root.pendingToplevel = null
    }
}

Rectangle {
    id: switcherCard
    anchors.centerIn: parent

    width: Math.min(screen.width - 80, Math.max(20, cardRow.implicitWidth + 48))
    height: Math.min(screen.height - 100, Math.max(240, cardRow.implicitHeight + 72))

    color: "transparent"
    border.width: 0
    clip: true

    scale: root.isOpen ? 1.0 : 0.95
    opacity: root.isOpen ? 1.0 : 0.0

    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 150 } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Item { Layout.fillWidth: true }
            Text {
                text: root.windowList.length < 2 ? "" : root.windowList.length + " Open Windows"
                font.pixelSize: 11
                font.family: "Google Sans"

                color: Qt.alpha(root.textColor, 0.5)
            }
        }

        Flickable {
            id: flickContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: cardRow.implicitWidth
            clip: false
            boundsBehavior: Flickable.StopAtBounds

            Grid {
                id: cardRow
                columns: root.calcCols
                spacing: 16
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    id: previewRepeater
                    model: root.windowList

                    delegate: Rectangle {
                        id: winItemRoot
                        required property HyprlandToplevel modelData
                        required property int index

                        property bool previewBusy: false
                        property bool previewReady: false
                        property int previewRetries: 0
                        property var previewGrabResult: null
                        property string previewImageSource: ""

                        readonly property bool isSelected: index === root.selectedIndex
                        readonly property var ipcData: modelData.lastIpcObject
                        readonly property string appClass: ipcData && ipcData.class ? ipcData.class : ""

                        readonly property bool isSpecialWorkspace: {
                            var ws = modelData.workspace
                            if (!ws) return false
                            return (ws.id < 0 || (ws.name && ws.name.indexOf("special") !== -1))
                        }

                        function resetPreview() {
                            previewView.captureSource = null
                            captureTimeout.stop()
                            previewBusy = false
                            previewReady = false
                            previewRetries = 0
                            previewGrabResult = null
                            previewImageSource = ""
                        }

                        function previewFailed() {
                            captureTimeout.stop()
                            previewView.captureSource = null
                            if (!root.isOpen) {
                                previewBusy = false
                                root.previewQueueBusy = false
                                return
                            }
                            if (previewRetries < root.previewMaxRetries) {
                                previewRetries++
                                root.previewRetry(winItemRoot)
                                return
                            }
                            previewBusy = false
                            root.previewFinished(winItemRoot)
                        }

                        function startPreviewCapture() {
                            if (!root.isOpen) {
                                root.previewQueueBusy = false
                                return
                            }
                            if (previewReady) {
                                previewBusy = false
                                root.previewFinished(winItemRoot)
                                return
                            }
                            if (previewBusy) return
                            if (!modelData || !modelData.wayland) {
                                previewFailed()
                                return
                            }
                            previewBusy = true
                            captureTimeout.restart()
                            previewView.captureSource = modelData.wayland
                        }

                        implicitWidth: root.dynItemWidth
                        implicitHeight: root.dynItemHeight
                        radius: Math.max(4, 8 * root.scaleFactor)

                        color: isSelected ? Qt.alpha(root.color1, 0.1) : (itemHover.hovered ? Qt.alpha(root.textColor, 0.05) : Qt.alpha(root.background, 0.4))
                        border.color: isSelected ? root.color1 : "transparent"
                        border.width: isSelected ? 2 : 0

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Math.max(4, 10 * root.scaleFactor)
                            spacing: Math.max(4, 10 * root.scaleFactor)

                            Rectangle {
                                id: previewBox
                                Layout.fillWidth: true
                                Layout.preferredHeight: width
                                radius: Math.max(2, 6 * root.scaleFactor)
                                color: Qt.alpha(root.background, 0.8)
                                border.color: Qt.alpha(root.textColor, 0.08)
                                border.width: 1
                                clip: true

                                Image {
                                    id: previewImage
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: false
                                    source: winItemRoot.previewImageSource
                                    visible: status === Image.Ready
                                }

                                Item {
                                    id: captureContainer
                                    anchors.fill: parent
                                    clip: true
                                    visible: !winItemRoot.previewReady

                                    ScreencopyView {
                                        id: previewView
                                        width: parent.height * (16 / 9)
                                        height: parent.height
                                        anchors.centerIn: parent
                                        captureSource: null
                                        live: false
                                        paintCursor: false
                                        visible: !winItemRoot.previewReady

                                        Timer {
                                            id: captureTimeout
                                            interval: root.previewCaptureTimeout
                                            repeat: false
                                            onTriggered: {
                                                if (winItemRoot.previewBusy && !previewView.hasContent) {
                                                    winItemRoot.previewFailed()
                                                }
                                            }
                                        }

                                        onHasContentChanged: {
                                            if (!hasContent || !winItemRoot.previewBusy) return
                                            captureTimeout.stop()
                                            var targetWidth = Math.max(1, Math.round(previewView.width))
                                            var targetHeight = Math.max(1, Math.round(previewView.height))
                                            var started = previewView.grabToImage(function(result) {
                                                if (!root.isOpen || !winItemRoot.previewBusy) return
                                                if (!result || !result.url || result.url.toString().length === 0) {
                                                    winItemRoot.previewFailed()
                                                    return
                                                }
                                                winItemRoot.previewGrabResult = result
                                                winItemRoot.previewImageSource = result.url.toString()
                                                winItemRoot.previewReady = true
                                                winItemRoot.previewBusy = false
                                                previewView.captureSource = null
                                                root.previewFinished(winItemRoot)
                                            }, Qt.size(targetWidth, targetHeight))

                                            if (!started) winItemRoot.previewFailed()
                                        }

                                        onStopped: {
                                            if (winItemRoot.previewBusy && !hasContent) winItemRoot.previewFailed()
                                        }
                                    }
                                }

                                Item {
                                    anchors.fill: parent
                                    visible: !previewImage.visible
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: Math.max(16, 48 * root.scaleFactor)
                                        height: Math.max(16, 48 * root.scaleFactor)
                                        radius: width / 2
                                        color: Qt.alpha(root.color1, 0.15)
                                        Text {
                                            anchors.centerIn: parent
                                            text: ActiveWindowService.getAppIcon(winItemRoot.appClass, winItemRoot.modelData.title)
                                            font.pixelSize: Math.max(10, Math.floor(24 * root.scaleFactor))
                                            font.family: "GeistMono Nerd Font Propo Propo"
                                            color: root.color1
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
                                    visible: winItemRoot.isSpecialWorkspace || (winItemRoot.modelData.workspace && winItemRoot.modelData.workspace.id > 1)
                                    Text {
                                        anchors.centerIn: parent
                                        text: winItemRoot.isSpecialWorkspace ? "S" : (winItemRoot.modelData.workspace ? winItemRoot.modelData.workspace.id : "")
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
                                        onClicked: root.closeWindow(winItemRoot.modelData)
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Math.max(2, 8 * root.scaleFactor)

                                Text {
                                    text: ActiveWindowService.getAppIcon(winItemRoot.appClass, winItemRoot.modelData.title)
                                    font.pixelSize: Math.max(9, Math.floor(16 * root.scaleFactor))
                                    font.family: "GeistMono Nerd Font Propo Propo"
                                    color: winItemRoot.isSelected ? root.color1 : root.textColor
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    Text {
                                        text: ActiveWindowService.getAppFriendlyName(winItemRoot.appClass, winItemRoot.modelData.title)
                                        font.pixelSize: Math.max(9, Math.floor(13 * root.scaleFactor))
                                        font.bold: true
                                        color: root.text
                                        font.family: "Google Sans"
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        text: winItemRoot.modelData.title || ""
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
                            onClicked: root.focusWindow(winItemRoot.modelData)
                        }
                    }
                }

                Text {
                    visible: root.windowList.length === 0
                    text: "No open windows"
                    font.pixelSize: 14
                    font.family: "Google Sans"
                    color: Qt.alpha(root.textColor, 0.5)
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}
}