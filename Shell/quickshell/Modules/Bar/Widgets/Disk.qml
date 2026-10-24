import QtQuick
import qs.Asura
import qs.Services

HardwareStat {
    id: root

    iconName: "hard_drive"
    value: SystemMonitorService.diskPercent
    absoluteValue: SystemMonitorService.diskUsedGb > 0
        ? (SystemMonitorService.diskUsedGb >= 1000
            ? (SystemMonitorService.diskUsedGb / 1024).toFixed(1) + " TB"
            : SystemMonitorService.diskUsedGb.toFixed(0) + " GB")
        : ""
    accentColor: tertiary
}
