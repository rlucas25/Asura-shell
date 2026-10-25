import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Asura
import qs.Services
import "../Components"

Item {
    id: wallpaperPickerModalRoot

    required property var settingsRoot
    readonly property var root: settingsRoot

    anchors.fill: parent
    visible: root.showWallpaperPickerModal
    z: 99992
    opacity: root.showWallpaperPickerModal ? 1 : 0

    Behavior on opacity {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.65)

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.closeWallpaperPicker()
        }
    }

    Rectangle {
        id: modalCard
        anchors.centerIn: parent
        width: Math.min(820, parent.width - 48)
        height: Math.min(parent.height - 64, 640)
        radius: 18
        color: root.surface
        border.color: Qt.alpha(root.color1, 0.45)
        border.width: 1.5
        clip: true
        scale: root.showWallpaperPickerModal ? 1 : 0.95

        Behavior on scale {
            NumberAnimation { duration: 200; easing.type: Easing.OutBack }
        }

        MouseArea {
            anchors.fill: parent
            // Prevent clicks inside card from closing modal
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            // Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    width: 40
                    height: 40
                    radius: 10
                    color: Qt.alpha(root.color1, 0.15)
                    border.color: Qt.alpha(root.color1, 0.35)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "wallpaper"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 22
                        color: root.color1
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        spacing: 8

                        Text {
                            text: qsTr("Wallpaper Selector")
                            font.family: "Google Sans Flex, Google Sans, sans-serif"
                            font.pixelSize: 16
                            font.bold: true
                            color: root.textBright
                        }

                        Rectangle {
                            implicitWidth: countText.implicitWidth + 12
                            implicitHeight: 20
                            radius: 10
                            color: Qt.alpha(root.color1, 0.18)

                            Text {
                                id: countText
                                anchors.centerIn: parent
                                text: (root.availableWallpapers ? root.availableWallpapers.length : 0) + " files"
                                font.family: "Google Sans"
                                font.pixelSize: 10
                                font.bold: true
                                color: root.color1
                            }
                        }
                    }

                    Text {
                        text: Config.cfg.wallpaperFolder ? (Quickshell.env("HOME") + Config.cfg.wallpaperFolder) : (Quickshell.env("HOME") + "/Pictures/Wallpapers")
                        font.family: "Google Sans"
                        font.pixelSize: 11
                        color: root.textMuted
                        elide: Text.ElideMiddle
                        Layout.maximumWidth: 380
                    }
                }

                // Top Actions: Import Manually, Refresh, Close
                RowLayout {
                    spacing: 8

                    SettingButton {
                        text: qsTr("Import Manually")
                        icon: "add_photo_alternate"
                        variant: "primary"
                        compact: true
                        onClicked: {
                            if (root.importWpProc) {
                                root.importWpProc.running = true;
                            }
                        }
                    }

                    SettingButton {
                        text: qsTr("Refresh")
                        icon: "refresh"
                        variant: "secondary"
                        compact: true
                        onClicked: root.refreshWallpapers()
                    }

                    Rectangle {
                        implicitWidth: 32
                        implicitHeight: 32
                        radius: 16
                        color: closeHover.hovered ? Qt.alpha(root.textColor, 0.15) : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "close"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 18
                            color: root.textColor
                        }

                        HoverHandler { id: closeHover }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.closeWallpaperPicker()
                        }
                    }
                }
            }

            // Separator line
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.alpha(root.textColor, 0.08)
            }

            // Grid Content Area
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Empty State
                ColumnLayout {
                    anchors.centerIn: parent
                    visible: !root.availableWallpapers || root.availableWallpapers.length === 0
                    spacing: 12

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "image_not_supported"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 48
                        color: Qt.alpha(root.textColor, 0.3)
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("No wallpapers found in the current folder")
                        font.family: "Google Sans"
                        font.pixelSize: 13
                        color: root.textMuted
                    }

                    SettingButton {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Import Manually")
                        icon: "add_photo_alternate"
                        variant: "primary"
                        compact: true
                        onClicked: {
                            if (root.importWpProc) {
                                root.importWpProc.running = true;
                            }
                        }
                    }
                }

                // Wallpaper Grid
                Flickable {
                    id: wpFlickable
                    anchors.fill: parent
                    visible: root.availableWallpapers && root.availableWallpapers.length > 0
                    contentHeight: wpGrid.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    WheelHandler {
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: (event) => {
                            var delta = event.angleDelta.y;
                            if (delta === 0) return;
                            var step = (delta / 120) * 140;
                            var maxY = Math.max(0, wpFlickable.contentHeight - wpFlickable.height);
                            wpFlickable.contentY = Math.max(0, Math.min(maxY, wpFlickable.contentY - step));
                        }
                    }

                    GridLayout {
                        id: wpGrid
                        width: parent.width
                        columns: Math.max(1, Math.floor((width + 12) / (190 + 12)))
                        columnSpacing: 12
                        rowSpacing: 12

                        Repeater {
                            model: root.availableWallpapers

                            delegate: Rectangle {
                                id: wpItemCard
                                required property var modelData

                                readonly property bool isSelected: Config.wallpaperCleanPath === wpItemCard.modelData.path

                                Layout.fillWidth: true
                                Layout.preferredHeight: width / 1.7
                                radius: 12
                                color: root.surfaceContainer
                                border.color: isSelected ? root.color1 : (cardMouse.containsMouse ? Qt.alpha(root.color1, 0.5) : Qt.alpha(root.textColor, 0.08))
                                border.width: isSelected ? 2.5 : 1
                                clip: true
                                scale: cardMouse.pressed ? 0.96 : (cardMouse.containsMouse ? 1.02 : 1.0)

                                Behavior on scale {
                                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                                }
                                Behavior on border.color {
                                    ColorAnimation { duration: 150 }
                                }

                                Image {
                                    id: cardImg
                                    anchors.fill: parent
                                    source: Config.toFileUrl(wpItemCard.modelData.path)
                                    fillMode: Image.PreserveAspectCrop
                                    sourceSize: Qt.size(280, 160)
                                    asynchronous: true
                                }

                                Item {
                                    anchors.fill: parent
                                    visible: cardImg.status !== Image.Ready

                                    Text {
                                        anchors.centerIn: parent
                                        text: "wallpaper"
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 32
                                        color: Qt.alpha(root.color1, 0.4)
                                    }
                                }

                                // Selection Checkmark Badge
                                Rectangle {
                                    visible: wpItemCard.isSelected
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 8
                                    width: 24
                                    height: 24
                                    radius: 12
                                    color: root.color1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "check"
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 15
                                        font.bold: true
                                        color: root.foreground
                                    }
                                }

                                // Bottom Label Strip
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    height: 26
                                    color: Qt.alpha("#000000", 0.72)

                                    Text {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        text: wpItemCard.modelData.name
                                        font.family: "Google Sans"
                                        font.pixelSize: 10
                                        font.weight: Font.Medium
                                        color: "#ffffff"
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }

                                MouseArea {
                                    id: cardMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Config.cfg.wallpaper = wpItemCard.modelData.path;
                                        Config.save();
                                        if (Config.cfg.colorsAutoGenerate) {
                                            Colors.generateDynamicColors(wpItemCard.modelData.path, Config.cfg.isDarkMode, Config.cfg.scheme);
                                        }
                                        root.showToast(qsTr("Wallpaper applied: ") + wpItemCard.modelData.name, "wallpaper");
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
