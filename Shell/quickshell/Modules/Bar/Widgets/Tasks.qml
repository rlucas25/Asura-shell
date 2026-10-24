import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.Modules.Bar.Widgets
import qs.Services
import qs.Asura

Item {
    id: root

    property color color1: Colors.cfg.textBright
    property alias primary: root.color1
    property alias text: root.color1
    property bool hoverEnabled: (typeof Config !== "undefined" && Config.barWidgetHoverTextEnabled !== undefined) ? Config.barWidgetHoverTextEnabled : true
    readonly property bool isHovered: hoverHandler.hovered
    readonly property bool expanded: isHovered && root.hoverEnabled
    property alias hovered: root.isHovered
    property alias opened: root.isHovered

    readonly property var nextInfo: (TaskService.tasks, TaskService.getNextTask())
    readonly property int pendingCount: nextInfo ? nextInfo.pendingCount : 0
    readonly property bool hasHighPriority: nextInfo ? nextInfo.hasHighPriority : false
    readonly property var topTask: nextInfo ? nextInfo.task : null

    readonly property color priorityAccent: {
        if (!topTask || topTask.priority === "none" || !topTask.priority) {
            return hasHighPriority ? Colors.cfg.error : root.color1;
        }
        return TaskService.getPriorityColor(topTask.priority);
    }

    signal clicked()

    readonly property bool isVertical: Config.isBarVertical
    implicitWidth: isVertical ? Math.round(22 * Config.barIconScale) : (taskLabel.implicitWidth + Math.round(14 * Config.barIconScale))
    implicitHeight: isVertical ? Math.round(22 * Config.barIconScale) : taskLabel.implicitHeight
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    ToolTip.visible: root.isHovered
    ToolTip.delay: 350
    ToolTip.text: {
        if (!topTask)
            return qsTr("Tasks: All tasks completed");

        var pStr = topTask.priority && topTask.priority !== "none" ? " [" + TaskService.getPriorityLabel(topTask.priority).toUpperCase() + "]" : "";
        var tStr = topTask.startTime ? " • " + TaskService.formatDisplayTime(topTask.startTime) : "";
        return qsTr("Next: ") + topTask.text + pStr + tStr + "\n" + qsTr("Pending: ") + root.pendingCount;
    }

    HoverHandler {
        id: hoverHandler
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
        color: root.hasHighPriority ? Qt.alpha(Colors.cfg.error, 0.25) : root.color1
        opacity: root.isHovered ? 0.2 : (root.hasHighPriority ? 0.12 : 0)

        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
    }

    RowLayout {
        id: taskLabel

        visible: !root.isVertical
        anchors.centerIn: parent
        spacing: Math.round(5 * Config.barIconScale)

        Icon {
            name: "task_alt"
            color: root.priorityAccent
            size: 16
        }

        Text {
            id: taskSummaryText

            visible: root.expanded || root.pendingCount > 0
            text: {
                if (root.expanded && root.topTask) {
                    var sTime = root.topTask.startTime ? TaskService.formatDisplayTime(root.topTask.startTime) + " " : "";
                    return sTime + root.topTask.text;
                }
                if (root.expanded && !root.topTask) {
                    return qsTr("Done");
                }
                return "" + root.pendingCount;
            }
            color: root.hasHighPriority ? Colors.cfg.error : root.color1
            font.family: "Google Sans"
            font.pixelSize: Math.round(13 * Config.barIconScale)
            font.weight: root.hasHighPriority ? 600 : 500
            verticalAlignment: Text.AlignVCenter
            maximumLineCount: 1
            elide: Text.ElideRight
            Layout.maximumWidth: root.expanded ? 140 : 40

            Behavior on Layout.maximumWidth {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    Item {
        id: verticalContent

        visible: root.isVertical
        anchors.centerIn: parent
        width: Math.round(22 * Config.barIconScale)
        height: Math.round(22 * Config.barIconScale)

        Icon {
            anchors.centerIn: parent
            name: "task_alt"
            color: root.priorityAccent
            size: 16
        }

        Rectangle {
            visible: root.pendingCount > 0
            anchors.top: parent.top
            anchors.right: parent.right
            width: 7
            height: 7
            radius: 3.5
            color: root.hasHighPriority ? Colors.cfg.error : Colors.cfg.primary
        }
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }
}
