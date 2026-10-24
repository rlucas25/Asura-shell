import QtQuick
import QtQuick.Layouts
import qs.Asura

Item {
    id: groupRoot

    default property list<Item> items
    property real bigRadius: 14
    property real smallRadius: 6
    property color groupColor: Colors.cfg.surface
    property color borderColor: Qt.alpha(Colors.cfg.base03, 0.25)
    property real itemPadding: 12

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        anchors.fill: parent
        spacing: 2

        Repeater {
            model: groupRoot.items.length
            delegate: Rectangle {
                id: cellRect
                required property int index
                readonly property bool isFirst: index === 0
                readonly property bool isLast: index === groupRoot.items.length - 1

                Layout.fillWidth: true
                implicitHeight: (groupRoot.items[index] ? groupRoot.items[index].implicitHeight : 0) + (groupRoot.itemPadding * 2)
                color: groupRoot.groupColor
                border.color: groupRoot.borderColor
                border.width: 1

                topLeftRadius: isFirst ? groupRoot.bigRadius : groupRoot.smallRadius
                topRightRadius: isFirst ? groupRoot.bigRadius : groupRoot.smallRadius
                bottomLeftRadius: isLast ? groupRoot.bigRadius : groupRoot.smallRadius
                bottomRightRadius: isLast ? groupRoot.bigRadius : groupRoot.smallRadius

                Component.onCompleted: {
                    const child = groupRoot.items[index];
                    if (child) {
                        child.parent = cellContent;
                        child.Layout.fillWidth = true;
                    }
                }

                ColumnLayout {
                    id: cellContent
                    anchors.fill: parent
                    anchors.margins: groupRoot.itemPadding
                    spacing: 0
                }
            }
        }
    }
}
