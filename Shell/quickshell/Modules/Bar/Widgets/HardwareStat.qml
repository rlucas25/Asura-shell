import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Asura
import qs.Components
import qs.Modules.Bar.Widgets
import qs.Services

Item {
    id: root

    property color primary: Colors.cfg.primary
    property color secondary: Colors.cfg.secondary
    property color tertiary: Colors.cfg.tertiary
    property color textColor: Colors.cfg.textBright
    property color accentColor: primary

    property string iconName: "memory"
    property real value: 0.0
    property bool dynamicLoadColor: true

    readonly property bool isVertical: Config.isBarVertical
    readonly property bool hidePercent: (Config.cfg && Config.cfg.hardwareHidePercent !== undefined) ? Config.cfg.hardwareHidePercent : false
    readonly property bool effectiveHidePercent: root.hidePercent || root.isVertical
    readonly property bool showAbsolute: (Config.cfg && Config.cfg.hardwareShowAbsolute !== undefined) ? Config.cfg.hardwareShowAbsolute : false
    property string absoluteValue: ""

    signal clicked()

    property bool hoverEnabled: (typeof Config !== "undefined" && Config.barWidgetHoverTextEnabled !== undefined) ? Config.barWidgetHoverTextEnabled : true
    readonly property bool isHovered: hoverHandler.hovered && root.hoverEnabled
    property alias hovered: root.isHovered
    property alias opened: root.isHovered

    readonly property color effectiveAccentColor: {
        if (!dynamicLoadColor)
            return accentColor;
        if (value >= 90)
            return Colors.cfg.error;
        if (value >= 75)
            return Colors.cfg.warning;
        return accentColor;
    }

    property real animatedValue: value
    Behavior on animatedValue {
        NumberAnimation {
            duration: 350
            easing.type: Easing.OutCubic
        }
    }

    implicitWidth: root.isVertical ? Math.round(22 * Config.barIconScale) : (contentRow.implicitWidth + (root.effectiveHidePercent ? Math.round(8 * Config.barIconScale) : Math.round(14 * Config.barIconScale)))
    implicitHeight: root.isVertical ? Math.round(22 * Config.barIconScale) : Math.round(26 * Config.barIconScale)
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    HoverHandler {
        id: hoverHandler
        enabled: root.hoverEnabled
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Rectangle {
        id: capsuleBackground
        anchors.fill: parent
        radius: height / 2
        color: root.textColor
        opacity: root.isHovered ? 0.2 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6

        Item {
            id: circleWrapper
            width: Math.round(22 * Config.barIconScale)
            height: Math.round(22 * Config.barIconScale)
            Layout.alignment: Qt.AlignVCenter

            CircularProgress {
                anchors.fill: parent
                lineWidth: 2.2 * Config.barIconScale
                trackColor: Qt.alpha(root.effectiveAccentColor, 0.2)
                color: root.effectiveAccentColor
                value: Math.max(0.0, Math.min(1.0, root.animatedValue / 100.0))
            }

            Icon {
                anchors.centerIn: parent
                name: root.iconName
                size: 13
                color: root.effectiveAccentColor
            }
        }

        Text {
            id: percentLabel
            visible: !root.effectiveHidePercent
            text: (root.showAbsolute && root.absoluteValue.length > 0) ? root.absoluteValue : (Math.round(root.value) + "%")
            font.family: "Google Sans"
            font.pixelSize: Math.round(12 * Config.barIconScale)
            font.weight: 500
            color: root.textColor
            verticalAlignment: Text.AlignVCenter
            Layout.alignment: Qt.AlignVCenter
        }
    }

    ToolTip.visible: root.isVertical && root.isHovered
    ToolTip.text: (root.showAbsolute && root.absoluteValue.length > 0) ? root.absoluteValue : (Math.round(root.value) + "%")
    ToolTip.delay: 300

    Component.onCompleted: {
        SystemMonitorService.subscribe();
    }

    Component.onDestruction: {
        SystemMonitorService.unsubscribe();
    }
}
