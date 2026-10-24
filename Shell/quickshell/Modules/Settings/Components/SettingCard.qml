import QtQuick
import QtQuick.Layouts
import qs.Asura

Rectangle {
    id: cardRoot

    default property alias content: contentLayout.data
    property int margins: 14
    property alias spacing: contentLayout.spacing
    property alias cardColor: cardRoot.color
    property alias cardRadius: cardRoot.radius
    property alias cardBorderColor: cardRoot.border.color
    property alias cardBorderWidth: cardRoot.border.width

    property real flashTint: 0

    function flash() {
        cardFlashAnim.restart();
    }

    Layout.fillWidth: true
    implicitHeight: contentLayout.implicitHeight + (cardRoot.margins * 2)
    radius: 14
    color: Colors.cfg.surface
    border.color: cardRoot.flashTint > 0 ? Qt.rgba(Colors.cfg.primary.r, Colors.cfg.primary.g, Colors.cfg.primary.b, Math.max(0.3, cardRoot.flashTint)) : Qt.alpha(Colors.cfg.base03, 0.25)
    border.width: cardRoot.flashTint > 0 ? 2 : 1
    scale: cardRoot.flashTint > 0 ? (1.0 + (0.015 * cardRoot.flashTint)) : 1.0

    Behavior on scale {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: cardFlashAnim

        NumberAnimation {
            target: cardRoot
            property: "flashTint"
            to: 1.0
            duration: 180
            easing.type: Easing.OutCubic
        }
        PauseAnimation {
            duration: 1400
        }
        NumberAnimation {
            target: cardRoot
            property: "flashTint"
            to: 0.0
            duration: 400
            easing.type: Easing.InOutQuad
        }
    }

    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.margins: cardRoot.margins
        spacing: 12
    }
}
