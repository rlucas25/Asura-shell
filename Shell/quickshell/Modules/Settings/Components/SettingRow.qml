import QtQuick
import QtQuick.Layouts

RowLayout {
    id: rowRoot

    property bool uniform: true
    property real rowSpacing: 12

    Layout.fillWidth: true
    spacing: rowSpacing
    uniformCellSizes: uniform
}
