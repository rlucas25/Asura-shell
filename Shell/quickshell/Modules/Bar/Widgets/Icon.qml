import QtQuick
import qs.Asura

Text {
    id: root

    property string name: ""
    property real size: 18
    readonly property real effectiveSize: Math.round(size * ((typeof Config !== "undefined" && Config.barIconScale !== undefined) ? Config.barIconScale : 1))
    property int weight: 400
    property real fill: 0
    property real grade: 0

    width: effectiveSize
    height: effectiveSize
    text: name
    font.family: "Material Symbols Rounded"
    font.pixelSize: effectiveSize
    font.weight: weight
    color: "white"
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    font.variableAxes: {
        "FILL": fill,
        "wght": weight,
        "GRAD": grade,
        "opsz": effectiveSize
    }
}
