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
    visible: root.currentTab === "gtk"

    SettingSectionHeader {
        icon: "auto_fix_high"
        title: qsTr("GTK Interface Settings")
        description: qsTr("Manage application GTK themes, icons, cursor themes, and system fonts via nwg-look")
    }

    SettingCard {
        Layout.preferredHeight: 260

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 16
            Layout.alignment: Qt.AlignHCenter

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "auto_fix_high"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 48
                color: Colors.cfg.primary
            }

            ColumnLayout {
                spacing: 4
                Layout.alignment: Qt.AlignHCenter

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("External GTK Customization")
                    font.pixelSize: 14
                    font.bold: true
                    font.family: "Google Sans"
                    color: Colors.cfg.text
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("GTK themes, icons, cursors, and system fonts are managed via nwg-look.")
                    font.pixelSize: 11
                    font.family: "Google Sans"
                    color: Colors.cfg.textSecondary
                }
            }

            SettingButton {
                Layout.alignment: Qt.AlignHCenter
                icon: "open_in_new"
                text: qsTr("Open nwg-look")
                variant: "primary"
                onClicked: root.openNwgLook()
            }
        }
    }
}
