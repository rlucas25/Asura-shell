import QtQuick
import QtQuick.Layouts
import qs.Asura

Rectangle {
    id: buttonRoot

    property string text: ""
    property string icon: ""
    property string variant: "secondary"
    property bool disabled: false
    property bool compact: false

    signal clicked()

    implicitWidth: btnRow.implicitWidth + (compact ? 20 : 28)
    implicitHeight: compact ? 32 : 40
    radius: compact ? 8 : 10

    color: {
        if (disabled) return Qt.alpha(Colors.cfg.base03, 0.3);
        if (variant === "primary") {
            return btnMa.pressed ? Qt.darker(Colors.cfg.primary, 1.1) : (btnMa.containsMouse ? Qt.lighter(Colors.cfg.primary, 1.1) : Colors.cfg.primary);
        } else if (variant === "danger") {
            return btnMa.pressed ? Qt.alpha(Colors.cfg.error, 0.35) : (btnMa.containsMouse ? Qt.alpha(Colors.cfg.error, 0.25) : Qt.alpha(Colors.cfg.error, 0.15));
        } else if (variant === "ghost") {
            return btnMa.containsMouse ? Qt.alpha(Colors.cfg.base03, 0.5) : "transparent";
        } else {
            return btnMa.pressed ? Qt.alpha(Colors.cfg.primary, 0.25) : (btnMa.containsMouse ? Qt.alpha(Colors.cfg.base03, 0.6) : Colors.cfg.surfaceContainer);
        }
    }

    border.color: {
        if (disabled || variant === "primary" || variant === "ghost") return "transparent";
        if (variant === "danger") return btnMa.containsMouse ? Colors.cfg.error : Qt.alpha(Colors.cfg.error, 0.4);
        return btnMa.containsMouse ? Qt.alpha(Colors.cfg.primary, 0.4) : Qt.alpha(Colors.cfg.base03, 0.4);
    }
    border.width: (variant === "primary" || variant === "ghost") ? 0 : 1

    scale: btnMa.pressed ? 0.96 : (btnMa.containsMouse ? 1.02 : 1.0)

    Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

    RowLayout {
        id: btnRow
        anchors.centerIn: parent
        spacing: 8

        Text {
            visible: buttonRoot.icon !== ""
            text: buttonRoot.icon
            font.pixelSize: buttonRoot.compact ? 15 : 18
            font.family: "Material Symbols Rounded"
            color: {
                if (buttonRoot.disabled) return Colors.cfg.base04;
                if (buttonRoot.variant === "primary") return Colors.cfg.on_primary;
                if (buttonRoot.variant === "danger") return Colors.cfg.error;
                return buttonRoot.variant === "secondary" && btnMa.containsMouse ? Colors.cfg.primary : Colors.cfg.text;
            }
        }

        Text {
            visible: buttonRoot.text !== ""
            text: buttonRoot.text
            font.pixelSize: buttonRoot.compact ? 12 : 14
            font.bold: buttonRoot.variant === "primary"
            font.family: "Google Sans"
            color: {
                if (buttonRoot.disabled) return Colors.cfg.base04;
                if (buttonRoot.variant === "primary") return Colors.cfg.on_primary;
                if (buttonRoot.variant === "danger") return Colors.cfg.error;
                return Colors.cfg.textBright;
            }
        }
    }

    MouseArea {
        id: btnMa
        anchors.fill: parent
        hoverEnabled: !buttonRoot.disabled
        cursorShape: buttonRoot.disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: {
            if (!buttonRoot.disabled) {
                buttonRoot.clicked();
            }
        }
    }
}
