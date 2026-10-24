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
    id: defaultAppsTabCol

    required property var settingsRoot
    readonly property var root: settingsRoot
    Layout.fillWidth: true
    spacing: 16
    visible: root.currentTab === "defaultapps"

    property string statusMessage: ""
    property string activeLaunchKey: ""
    property var activePickerCategory: null

    function openAppPicker(cat) {
        activePickerCategory = cat;
    }

    function closeAppPicker() {
        activePickerCategory = null;
    }

    function getSelectedAppInfo(cat) {
        if (!cat) return { name: qsTr("Not configured"), icon: "", cmd: "" };
        var cur = (DefaultAppsService.currentApps && DefaultAppsService.currentApps[cat.key] !== undefined)
            ? DefaultAppsService.currentApps[cat.key]
            : (cat.current || "");
        cur = String(cur).trim();
        if (!cur) {
            return { name: qsTr("Not configured"), icon: "", cmd: "" };
        }

        var curLower = cur.toLowerCase();
        var curBase = curLower.split(" ")[0].split("/").pop();

        if (cat.options && cat.options.length > 0) {
            for (var i = 0; i < cat.options.length; i++) {
                var opt = cat.options[i];
                var optCmd = String(opt.cmd || "").trim().toLowerCase();
                var optBase = optCmd.split(" ")[0].split("/").pop();
                if (curLower === optCmd || curBase === optBase) {
                    return {
                        name: opt.name || optBase,
                        icon: opt.icon || "",
                        cmd: opt.cmd || cur
                    };
                }
            }
        }

        var baseName = cur.split(" ")[0].split("/").pop();
        var formatted = baseName.charAt(0).toUpperCase() + baseName.slice(1);
        return {
            name: formatted,
            icon: baseName,
            cmd: cur
        };
    }

    onVisibleChanged: {
        if (visible) {
            DefaultAppsService.loadSettings();
        } else {
            closeAppPicker();
        }
    }

    Timer {
        id: statusClearTimer
        interval: 3500
        repeat: false
        onTriggered: defaultAppsTabCol.statusMessage = ""
    }

    Connections {
        target: DefaultAppsService
        function onSettingsApplied() {
            defaultAppsTabCol.statusMessage = qsTr("Hyprland variables and default applications synchronized!");
            statusClearTimer.restart();
        }
    }

    SettingSectionHeader {
        title: qsTr("Applications")
        description: qsTr("Configure default system applications and manage hidden launcher apps")
        icon: "apps"
        extraContent: Rectangle {
            implicitHeight: 26
            implicitWidth: syncBadgeRow.implicitWidth + 18
            radius: 13
            color: Qt.alpha(Colors.cfg.primary, 0.12)
            border.color: Qt.alpha(Colors.cfg.primary, 0.3)
            border.width: 1

            RowLayout {
                id: syncBadgeRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "check"
                    font.pixelSize: 14
                    font.family: "Material Symbols Rounded"
                    color: Colors.cfg.primary
                }

                Text {
                    text: qsTr("Hyprland Live Sync")
                    font.family: "Google Sans"
                    font.pixelSize: 10
                    font.bold: true
                    color: Colors.cfg.primary
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 36
        radius: 10
        visible: defaultAppsTabCol.statusMessage !== ""
        color: Qt.alpha(root.color1, 0.18)
        border.color: Qt.alpha(root.color1, 0.4)
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            Text {
                text: "check"
                font.pixelSize: 18
                font.family: "Material Symbols Rounded"
                color: root.color1
            }

            Text {
                Layout.fillWidth: true
                text: defaultAppsTabCol.statusMessage
                font.family: "Google Sans"
                font.pixelSize: 11
                font.bold: true
                color: root.textBright
                elide: Text.ElideRight
            }

            Text {
                text: "close"
                font.pixelSize: 14
                font.family: "Material Symbols Rounded"
                color: root.textMuted

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: defaultAppsTabCol.statusMessage = ""
                }
            }
        }
    }

    SettingSectionHeader {
        title: qsTr("Default Applications")
        icon: "apps"
        extraContent: Text {
            text: qsTr("Click to choose application")
            font.family: "Google Sans"
            font.pixelSize: 10
            color: root.textMuted
        }
    }

    Repeater {
        model: DefaultAppsService.categories

        delegate: Rectangle {
            id: categoryCard

            required property var modelData
            required property int index

            readonly property var selApp: defaultAppsTabCol.getSelectedAppInfo(modelData)

            Layout.fillWidth: true
            implicitHeight: 52
            radius: 12
            color: cardHover.hovered ? Qt.alpha(root.color1, 0.08) : root.surfaceContainer
            border.color: cardHover.hovered ? Qt.alpha(root.color1, 0.4) : Qt.alpha(root.borderCol, 0.35)
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                RowLayout {
                    Layout.preferredWidth: 210
                    Layout.fillWidth: false
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 10

                    Rectangle {
                        implicitWidth: 32
                        implicitHeight: 32
                        radius: 8
                        color: Qt.alpha(root.color1, 0.12)
                        border.color: Qt.alpha(root.color1, 0.25)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: categoryCard.modelData.icon || "apps"
                            font.pixelSize: 18
                            font.family: "Material Symbols Rounded"
                            color: root.color1
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: categoryCard.modelData.title
                            font.family: "Google Sans"
                            font.pixelSize: 11
                            font.bold: true
                            color: root.textBright
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: categoryCard.modelData.keybind || ("vars." + categoryCard.modelData.hyprVar)
                            font.family: "Google Sans"
                            font.pixelSize: 9
                            color: root.textMuted
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 24
                    Layout.alignment: Qt.AlignVCenter
                    color: Qt.alpha(root.borderCol, 0.35)
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 10

                    Rectangle {
                        implicitWidth: 28
                        implicitHeight: 28
                        radius: 7
                        color: Qt.alpha(root.textColor, 0.06)

                        Image {
                            id: activeAppIconImg
                            anchors.centerIn: parent
                            width: 20
                            height: 20
                            source: categoryCard.selApp.icon ? ("image://icon/" + categoryCard.selApp.icon) : ""
                            smooth: true
                            mipmap: true
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !categoryCard.selApp.icon || activeAppIconImg.status !== Image.Ready
                            text: categoryCard.selApp.name ? categoryCard.selApp.name.charAt(0).toUpperCase() : "?"
                            font.family: "Google Sans"
                            font.pixelSize: 11
                            font.bold: true
                            color: root.color1
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: categoryCard.selApp.name
                            font.family: "Google Sans"
                            font.pixelSize: 11
                            font.bold: true
                            color: root.textColor
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: categoryCard.selApp.cmd
                            font.family: "Google Sans"
                            font.pixelSize: 9
                            color: root.textMuted
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }

                SettingButton {
                    Layout.alignment: Qt.AlignVCenter
                    text: qsTr("Change")
                    icon: "edit"
                    compact: true
                    variant: "secondary"
                    onClicked: {
                        defaultAppsTabCol.openAppPicker(categoryCard.modelData);
                    }
                }
            }

            HoverHandler { id: cardHover }

            MouseArea {
                anchors.fill: parent
                z: -1
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    defaultAppsTabCol.openAppPicker(categoryCard.modelData);
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        radius: 14
        color: root.surface
        implicitHeight: appVisibilityCol.implicitHeight + 28

        ColumnLayout {
            id: appVisibilityCol

            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        spacing: 8

                        Text {
                            text: qsTr("Hidden Applications")
                            font.family: "Google Sans"
                            font.pixelSize: 12
                            font.bold: true
                            color: root.textColor
                        }

                        Rectangle {
                            implicitWidth: hiddenCountText.implicitWidth + 12
                            implicitHeight: 18
                            radius: 9
                            color: (root.launcherHiddenAppsList && root.launcherHiddenAppsList.length > 0) ? Qt.alpha(root.color1, 0.2) : Qt.alpha(root.textColor, 0.08)

                            Text {
                                id: hiddenCountText

                                anchors.centerIn: parent
                                text: ((root.launcherHiddenAppsList) ? root.launcherHiddenAppsList.length : 0) + " " + qsTr("hidden")
                                font.family: "Google Sans"
                                font.pixelSize: 9
                                font.bold: true
                                color: (root.launcherHiddenAppsList && root.launcherHiddenAppsList.length > 0) ? root.color1 : root.textMuted
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.launcherAppFilter = (root.launcherAppFilter === "hidden") ? "all" : "hidden";
                                }
                            }
                        }
                    }

                    Text {
                        text: qsTr("Toggle applications to hide them from the launcher search and application list")
                        font.family: "Google Sans"
                        font.pixelSize: 9
                        color: root.textMuted
                    }
                }

                SettingButton {
                    text: qsTr("Unhide All")
                    icon: "visibility"
                    compact: true
                    variant: "secondary"
                    visible: root.launcherHiddenAppsList && root.launcherHiddenAppsList.length > 0
                    onClicked: root.unhideAllApps()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                radius: 12
                color: root.surfaceContainer
                border.color: Qt.alpha(root.borderCol, 0.35)
                border.width: 1
                implicitHeight: hiddenSectionCol.implicitHeight + 24

                ColumnLayout {
                    id: hiddenSectionCol

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "visibility_off"
                            font.pixelSize: 16
                            font.family: "Material Symbols Rounded"
                            color: root.color1
                        }

                        Text {
                            text: qsTr("Currently Hidden")
                            font.family: "Google Sans"
                            font.pixelSize: 11
                            font.bold: true
                            color: root.textColor
                        }

                        Rectangle {
                            implicitWidth: hiddenSectionBadgeText.implicitWidth + 10
                            implicitHeight: 18
                            radius: 9
                            color: (root.launcherHiddenAppsList && root.launcherHiddenAppsList.length > 0) ? Qt.alpha(root.color1, 0.2) : Qt.alpha(root.textColor, 0.08)

                            Text {
                                id: hiddenSectionBadgeText

                                anchors.centerIn: parent
                                text: (root.launcherHiddenAppsList ? root.launcherHiddenAppsList.length : 0).toString()
                                font.family: "Google Sans"
                                font.pixelSize: 9
                                font.bold: true
                                color: (root.launcherHiddenAppsList && root.launcherHiddenAppsList.length > 0) ? root.color1 : root.textMuted
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            text: qsTr("Click any app chip to make it visible again")
                            font.family: "Google Sans"
                            font.pixelSize: 9
                            color: root.textMuted
                            visible: root.launcherHiddenAppsList && root.launcherHiddenAppsList.length > 0
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        visible: !root.launcherHiddenAppsList || root.launcherHiddenAppsList.length === 0
                        Layout.topMargin: 4
                        Layout.bottomMargin: 4

                        Text {
                            text: "check_circle"
                            font.pixelSize: 18
                            font.family: "Material Symbols Rounded"
                            color: root.color1
                        }

                        Text {
                            text: qsTr("No applications are currently hidden. All installed apps appear in the launcher.")
                            font.family: "Google Sans"
                            font.pixelSize: 10
                            color: root.textMuted
                        }
                    }

                    Flow {
                        id: hiddenAppsFlow

                        width: hiddenSectionCol.width
                        spacing: 8
                        visible: root.launcherHiddenAppsList && root.launcherHiddenAppsList.length > 0

                        Repeater {
                            model: root.launcherHiddenAppsList

                            Rectangle {
                                id: hiddenChipItem

                                required property var modelData

                                implicitWidth: hiddenChipRow.implicitWidth + 16
                                implicitHeight: 32
                                radius: 8
                                color: hiddenChipMa.containsMouse ? Qt.alpha(root.color1, 0.16) : Qt.alpha(root.surface, 0.8)
                                border.color: hiddenChipMa.containsMouse ? root.color1 : Qt.alpha(root.borderCol, 0.4)
                                border.width: 1

                                RowLayout {
                                    id: hiddenChipRow

                                    anchors.centerIn: parent
                                    spacing: 7

                                    Rectangle {
                                        implicitWidth: 20
                                        implicitHeight: 20
                                        radius: 5
                                        color: Qt.alpha(root.textColor, 0.08)

                                        Image {
                                            id: hiddenChipIcon

                                            anchors.centerIn: parent
                                            width: 16
                                            height: 16
                                            source: hiddenChipItem.modelData.icon ? ("image://icon/" + hiddenChipItem.modelData.icon) : ""
                                            smooth: true
                                            mipmap: true
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            visible: !hiddenChipItem.modelData.icon || hiddenChipIcon.status !== Image.Ready
                                            text: (hiddenChipItem.modelData.name && hiddenChipItem.modelData.name.length > 0) ? hiddenChipItem.modelData.name.charAt(0).toUpperCase() : "?"
                                            font.family: "Google Sans"
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: root.color1
                                        }
                                    }

                                    Text {
                                        text: hiddenChipItem.modelData.name || hiddenChipItem.modelData.id
                                        font.family: "Google Sans"
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: hiddenChipMa.containsMouse ? root.textBright : root.textColor
                                        elide: Text.ElideRight
                                        Layout.maximumWidth: 160
                                    }

                                    Rectangle {
                                        implicitWidth: 18
                                        implicitHeight: 18
                                        radius: 9
                                        color: hiddenChipMa.containsMouse ? Qt.alpha(root.color1, 0.35) : Qt.alpha(root.textColor, 0.08)

                                        Text {
                                            anchors.centerIn: parent
                                            text: "close"
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 12
                                            color: hiddenChipMa.containsMouse ? root.color1 : root.textMuted
                                        }
                                    }
                                }

                                MouseArea {
                                    id: hiddenChipMa

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.toggleAppHidden(hiddenChipItem.modelData.id)
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: 10
                    color: root.surfaceContainer

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: "search"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 16
                            color: root.color1
                        }

                        TextInput {
                            id: launcherAppSearchInput

                            Layout.fillWidth: true
                            font.family: "Google Sans"
                            font.pixelSize: 11
                            color: root.textColor
                            clip: true
                            text: root.launcherAppSearchQuery
                            onTextChanged: root.launcherAppSearchQuery = text

                            Text {
                                text: qsTr("Search applications to hide...")
                                font.family: "Google Sans"
                                font.pixelSize: 11
                                color: root.textMuted
                                visible: launcherAppSearchInput.text === ""
                            }
                        }

                        Rectangle {
                            implicitWidth: 18
                            implicitHeight: 18
                            radius: 9
                            color: clearAppSearchMa.containsMouse ? Qt.alpha(root.textColor, 0.15) : "transparent"
                            visible: root.launcherAppSearchQuery !== ""

                            Text {
                                anchors.centerIn: parent
                                text: "close"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 14
                                color: root.textMuted
                            }

                            MouseArea {
                                id: clearAppSearchMa

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.launcherAppSearchQuery = "";
                                    launcherAppSearchInput.text = "";
                                }
                            }
                        }
                    }
                }

                SettingPills {
                    currentValue: root.launcherAppFilter
                    model: [
                        { id: "all", label: qsTr("All") },
                        { id: "hidden", label: qsTr("Hidden") + (root.launcherHiddenAppsList && root.launcherHiddenAppsList.length > 0 ? (" (" + root.launcherHiddenAppsList.length + ")") : "") },
                        { id: "visible", label: qsTr("Visible") }
                    ]
                    onSelected: (val) => root.launcherAppFilter = val
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 380
                radius: 10
                color: root.surfaceContainer
                clip: true

                ListView {
                    id: launcherAppsListView

                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 3
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    maximumFlickVelocity: 4000
                    flickDeceleration: 1500
                    model: root.launcherFilteredApps

                    WheelHandler {
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: (event) => {
                            var delta = event.angleDelta.y;
                            if (delta === 0)
                                return ;

                            var step = (delta / 120) * 80;
                            var maxY = Math.max(0, launcherAppsListView.contentHeight - launcherAppsListView.height);
                            launcherAppsListView.contentY = Math.max(0, Math.min(maxY, launcherAppsListView.contentY - step));
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded

                        contentItem: Rectangle {
                            implicitWidth: 4
                            radius: 2
                            color: Qt.alpha(root.color1, 0.4)
                        }
                    }

                    delegate: Rectangle {
                        id: appRowDelegate

                        required property var modelData
                        readonly property bool appHidden: {
                            var _rev = root.launcherHiddenRevision;
                            return root.isAppHidden(modelData.id);
                        }

                        width: launcherAppsListView.width - (launcherAppsListView.ScrollBar.vertical.visible ? 10 : 0)
                        height: 44
                        radius: 8
                        color: appRowMa.containsMouse ? Qt.alpha(root.textColor, 0.06) : (appHidden ? Qt.alpha(root.textColor, 0.02) : "transparent")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 10

                            Rectangle {
                                implicitWidth: 30
                                implicitHeight: 30
                                radius: 8
                                color: Qt.alpha(root.textColor, 0.06)
                                opacity: appHidden ? 0.45 : 1

                                Image {
                                    id: listAppIcon

                                    anchors.centerIn: parent
                                    width: 22
                                    height: 22
                                    source: modelData.icon ? ("image://icon/" + modelData.icon) : ""
                                    smooth: true
                                    mipmap: true
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: !modelData.icon || listAppIcon.status !== Image.Ready
                                    text: (modelData.name && modelData.name.length > 0) ? modelData.name.charAt(0).toUpperCase() : "?"
                                    font.family: "Google Sans"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.color1
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name || ""
                                    font.family: "Google Sans"
                                    font.pixelSize: 11
                                    font.bold: !appHidden
                                    color: appHidden ? root.textMuted : root.textColor
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.genericName || modelData.id || ""
                                    font.family: "Google Sans"
                                    font.pixelSize: 9
                                    color: root.textMuted
                                    opacity: 0.75
                                    elide: Text.ElideRight
                                }
                            }

                            Rectangle {
                                implicitWidth: toggleBadgeRow.implicitWidth + 14
                                implicitHeight: 24
                                radius: 6
                                color: appHidden ? Qt.alpha(root.textColor, 0.08) : Qt.alpha(root.color1, 0.15)
                                border.color: appHidden ? Qt.alpha(root.borderCol, 0.4) : Qt.alpha(root.color1, 0.35)
                                border.width: 1

                                RowLayout {
                                    id: toggleBadgeRow

                                    anchors.centerIn: parent
                                    spacing: 5

                                    Text {
                                        text: appHidden ? "visibility_off" : "visibility"
                                        font.pixelSize: 14
                                        font.family: "Material Symbols Rounded"
                                        color: appHidden ? root.textMuted : root.color1
                                    }

                                    Text {
                                        text: appHidden ? qsTr("Hidden") : qsTr("Visible")
                                        font.family: "Google Sans"
                                        font.pixelSize: 9
                                        font.bold: !appHidden
                                        color: appHidden ? root.textMuted : root.color1
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: appRowMa

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleAppHidden(modelData.id)
                        }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    visible: launcherAppsListView.count === 0

                    Text {
                        text: "search_off"
                        font.pixelSize: 24
                        font.family: "Material Symbols Rounded"
                        color: root.textMuted
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: qsTr("No applications found")
                        font.family: "Google Sans"
                        font.pixelSize: 11
                        color: root.textMuted
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }
}
