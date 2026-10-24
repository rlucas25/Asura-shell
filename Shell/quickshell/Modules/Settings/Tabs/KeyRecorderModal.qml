import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Asura
import qs.Components
import qs.Services
import "../Components"

Item {
    id: root

    property bool active: false
    property var targetItem: null
    property string recordedChord: ""
    property string customLabel: ""
    property string customAction: "exec"
    property string customValue: ""
    property bool isRecording: false
    readonly property bool isCustom: targetItem && targetItem.isCustom
    readonly property bool hasConflict: recordedChord !== "" && ShortcutsService.isChordConflicting(recordedChord, targetItem ? targetItem.id : "")

    anchors.fill: parent
    z: 99998
    visible: active
    opacity: visible ? 1 : 0
    focus: visible

    Behavior on opacity {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    onActiveChanged: {
        if (active) {
            root.recordedChord = targetItem ? targetItem.chord : "";
            root.customLabel = targetItem ? (targetItem.label || "") : "New Shortcut";
            root.customAction = targetItem ? (targetItem.action || "exec") : "exec";
            root.customValue = targetItem ? (targetItem.value || "") : "";
            root.isRecording = true;
            recorderCard.forceActiveFocus();
        } else {
            root.isRecording = false;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.65)

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.dismiss()
        }
    }

    Rectangle {
        id: recorderCard

        anchors.centerIn: parent
        width: Math.min(540, parent.width - 32)
        implicitHeight: mainCol.implicitHeight + 36
        radius: Config.effectiveGeneralRadius
        color: Colors.cfg.surface
        border.color: root.hasConflict ? Colors.cfg.warning : Qt.alpha(Colors.cfg.primary, 0.4)
        border.width: 1.5
        clip: true
        focus: true

        scale: root.visible ? 1 : 0.95
        Behavior on scale {
            NumberAnimation { duration: 200; easing.type: Easing.OutBack }
        }

        Keys.onPressed: (event) => {
            if (!root.isRecording) return;

            if (event.key === Qt.Key_Escape && event.modifiers === Qt.NoModifier) {
                root.dismiss();
                event.accepted = true;
                return;
            }

            var mods = [];
            if (event.modifiers & Qt.MetaModifier) mods.push("SUPER");
            if (event.modifiers & Qt.ControlModifier) mods.push("CTRL");
            if (event.modifiers & Qt.AltModifier) mods.push("ALT");
            if (event.modifiers & Qt.ShiftModifier) mods.push("SHIFT");

            if (event.key === Qt.Key_Control || event.key === Qt.Key_Shift ||
                event.key === Qt.Key_Alt || event.key === Qt.Key_Meta ||
                event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R) {
                if (mods.length > 0) {
                    root.recordedChord = mods.join(" + ");
                }
                event.accepted = true;
                return;
            }

            var keyName = "";
            switch (event.key) {
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    keyName = "Return";
                    break;
                case Qt.Key_Space:
                    keyName = "Space";
                    break;
                case Qt.Key_Tab:
                    keyName = "Tab";
                    break;
                case Qt.Key_Backslash:
                    keyName = "backslash";
                    break;
                case Qt.Key_Slash:
                    keyName = "slash";
                    break;
                case Qt.Key_Backspace:
                    keyName = "BackSpace";
                    break;
                case Qt.Key_Delete:
                    keyName = "Delete";
                    break;
                case Qt.Key_Insert:
                    keyName = "Insert";
                    break;
                case Qt.Key_Left:
                    keyName = "Left";
                    break;
                case Qt.Key_Right:
                    keyName = "Right";
                    break;
                case Qt.Key_Up:
                    keyName = "Up";
                    break;
                case Qt.Key_Down:
                    keyName = "Down";
                    break;
                case Qt.Key_PageUp:
                    keyName = "Page_Up";
                    break;
                case Qt.Key_PageDown:
                    keyName = "Page_Down";
                    break;
                case Qt.Key_Home:
                    keyName = "Home";
                    break;
                case Qt.Key_End:
                    keyName = "End";
                    break;
                case Qt.Key_Equal:
                    keyName = "Equal";
                    break;
                case Qt.Key_Minus:
                    keyName = "Minus";
                    break;
                case Qt.Key_Comma:
                    keyName = "Comma";
                    break;
                case Qt.Key_Period:
                    keyName = "Period";
                    break;
                default:
                    if (event.key >= Qt.Key_F1 && event.key <= Qt.Key_F12) {
                        keyName = "F" + (event.key - Qt.Key_F1 + 1);
                    } else if (event.text && event.text.length > 0) {
                        keyName = event.text.toUpperCase();
                    } else {
                        keyName = String.fromCharCode(event.key).toUpperCase();
                    }
                    break;
            }

            if (keyName !== "") {
                var chordParts = mods.concat([keyName]);
                root.recordedChord = chordParts.join(" + ");
            }
            event.accepted = true;
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.isRecording = true;
                recorderCard.forceActiveFocus();
            }
        }

        ColumnLayout {
            id: mainCol

            anchors.fill: parent
            anchors.margins: 18
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: 8
                    color: Qt.alpha(Colors.cfg.primary, 0.15)
                    border.color: Qt.alpha(Colors.cfg.primary, 0.3)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "keyboard"
                        font.pixelSize: 18
                        font.family: "Material Symbols Rounded"
                        color: Colors.cfg.primary
                    }
                }

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true

                    Text {
                        text: root.targetItem ? (root.isCustom ? qsTr("Configure Custom Shortcut") : qsTr("Edit Shortcut: %1").arg(root.targetItem.label)) : qsTr("Key Recorder")
                        font.pixelSize: 15
                        font.bold: true
                        font.family: "Google Sans"
                        color: Colors.cfg.textBright
                    }

                    Text {
                        text: qsTr("Press any key combination on your keyboard to record")
                        font.pixelSize: 11
                        font.family: "Google Sans"
                        color: Qt.alpha(Colors.cfg.textSecondary, 0.8)
                    }
                }

                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 14
                    color: closeHover.hovered ? Qt.alpha(Colors.cfg.error, 0.2) : Qt.alpha(Colors.cfg.surfaceContainerHigh, 0.5)

                    Text {
                        anchors.centerIn: parent
                        text: "close"
                        font.pixelSize: 16
                        font.family: "Material Symbols Rounded"
                        color: closeHover.hovered ? Colors.cfg.error : Colors.cfg.textSecondary
                    }

                    HoverHandler { id: closeHover }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.dismiss()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 80
                radius: 12
                color: Qt.alpha(Colors.cfg.surfaceContainerHigh, 0.5)
                border.color: root.hasConflict ? Colors.cfg.warning : (root.isRecording ? Colors.cfg.primary : Qt.alpha(Colors.cfg.border, 0.3))
                border.width: root.isRecording ? 1.5 : 1

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.isRecording ? qsTr("Listening for keystrokes...") : qsTr("Recorded Combination:")
                        font.pixelSize: 11
                        font.family: "Google Sans"
                        color: root.isRecording ? Colors.cfg.primary : Qt.alpha(Colors.cfg.textSecondary, 0.7)
                    }

                    KeyComboView {
                        Layout.alignment: Qt.AlignHCenter
                        chord: root.recordedChord !== "" ? root.recordedChord : "Press Keys..."
                    }
                }
            }

            Rectangle {
                visible: root.hasConflict
                Layout.fillWidth: true
                implicitHeight: 34
                radius: 8
                color: Qt.alpha(Colors.cfg.warning, 0.15)
                border.color: Qt.alpha(Colors.cfg.warning, 0.4)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Text {
                        text: "warning"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 16
                        color: Colors.cfg.warning
                    }

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Warning: This chord is already in use by another shortcut.")
                        font.pixelSize: 11
                        font.family: "Google Sans"
                        color: Colors.cfg.warning
                    }
                }
            }

            ColumnLayout {
                visible: root.isCustom
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: qsTr("Shortcut Name")
                    font.pixelSize: 11
                    font.family: "Google Sans"
                    color: Colors.cfg.textBright
                }

                TextField {
                    id: labelInput
                    Layout.fillWidth: true
                    text: root.customLabel
                    placeholderText: qsTr("e.g. Open Terminal, Screenshot Area...")
                    font.pixelSize: 12
                    font.family: "Google Sans"
                    color: Colors.cfg.textBright
                    background: Rectangle {
                        radius: 8
                        color: Qt.alpha(Colors.cfg.surfaceContainerHigh, 0.6)
                        border.color: Qt.alpha(Colors.cfg.border, 0.3)
                        border.width: 1
                    }
                    onTextChanged: root.customLabel = text
                }

                Text {
                    text: qsTr("Action Type")
                    font.pixelSize: 11
                    font.family: "Google Sans"
                    color: Colors.cfg.textBright
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [
                            { id: "exec", label: qsTr("Command") },
                            { id: "close", label: qsTr("Close Window") },
                            { id: "float", label: qsTr("Float") },
                            { id: "fullscreen", label: qsTr("Fullscreen") }
                        ]

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 30
                            radius: 8
                            color: root.customAction === modelData.id ? Colors.cfg.primary : Qt.alpha(Colors.cfg.surfaceContainerHigh, 0.6)
                            border.color: root.customAction === modelData.id ? Colors.cfg.primary : Qt.alpha(Colors.cfg.border, 0.3)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                font.pixelSize: 11
                                font.weight: root.customAction === modelData.id ? Font.DemiBold : Font.Normal
                                font.family: "Google Sans"
                                color: root.customAction === modelData.id ? Colors.cfg.on_primary : Colors.cfg.textBright
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.customAction = modelData.id
                            }
                        }
                    }
                }

                ColumnLayout {
                    visible: root.customAction === "exec"
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: qsTr("Command / Application Executable")
                        font.pixelSize: 11
                        font.family: "Google Sans"
                        color: Colors.cfg.textBright
                    }

                    TextField {
                        id: valueInput
                        Layout.fillWidth: true
                        text: root.customValue
                        placeholderText: qsTr("e.g. kitty, alacritty, rofi -show drun, firefox")
                        font.pixelSize: 12
                        font.family: "Google Sans"
                        color: Colors.cfg.textBright
                        background: Rectangle {
                            radius: 8
                            color: Qt.alpha(Colors.cfg.surfaceContainerHigh, 0.6)
                            border.color: Qt.alpha(Colors.cfg.border, 0.3)
                            border.width: 1
                        }
                        onTextChanged: root.customValue = text
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                SettingButton {
                    visible: !root.isCustom && root.targetItem && root.targetItem.var !== null
                    text: qsTr("Reset Default")
                    variant: "secondary"
                    compact: true
                    onClicked: {
                        if (root.targetItem && root.targetItem.var) {
                            ShortcutsService.resetShortcut(root.targetItem.var);
                            root.dismiss();
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                SettingButton {
                    text: qsTr("Cancel")
                    variant: "ghost"
                    compact: true
                    onClicked: root.dismiss()
                }

                SettingButton {
                    text: qsTr("Apply Shortcut")
                    variant: "primary"
                    compact: true
                    enabled: root.recordedChord !== "" && (!root.isCustom || root.customLabel !== "")
                    opacity: enabled ? 1 : 0.4
                    onClicked: root.applySave()
                }
            }
        }
    }

    function dismiss() {
        root.active = false;
        root.targetItem = null;
    }

    function applySave() {
        if (!root.targetItem) return;

        if (root.isCustom) {
            if (root.targetItem.id && root.targetItem.id !== "new") {
                ShortcutsService.updateCustomShortcut(root.targetItem.id, root.customLabel, root.recordedChord, root.customAction, root.customValue);
            } else {
                ShortcutsService.addCustomShortcut(root.customLabel, root.recordedChord, root.customAction, root.customValue);
            }
        } else {
            if (root.targetItem.var) {
                ShortcutsService.setShortcut(root.targetItem.var, root.recordedChord);
            }
        }
        root.dismiss();
    }
}
