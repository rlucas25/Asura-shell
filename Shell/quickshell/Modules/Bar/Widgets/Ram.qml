import QtQuick
import qs.Asura
import qs.Services

HardwareStat {
    id: root

    iconName: "memory_alt"
    value: SystemMonitorService.memPercent
    absoluteValue: SystemMonitorService.memUsedGb > 0 ? (SystemMonitorService.memUsedGb.toFixed(1) + " GB") : ""
    accentColor: secondary
}
