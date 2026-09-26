import QtQuick

Text {
    id: root

    property string name: ""
    property real size: 18
    property int weight: 400
    property real fill: 1
    property real grade: 0

    width: size
    height: size

    text: name

    font.family: "Material Symbols Rounded"
    font.pixelSize: size
    font.weight: weight

    color: "white"

    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    font.variableAxes: {
        "FILL": fill,
        "wght": weight,
        "GRAD": grade,
        "opsz": size
    }
}