import QtQuick
import qs.Asura
import qs.Services

HardwareStat {
    id: root

    iconName: "speed"
    value: SystemMonitorService.gpuPercent
    absoluteValue: SystemMonitorService.gpuTemp > 0
        ? (SystemMonitorService.gpuTemp + "°C")
        : (SystemMonitorService.gpuUsedGb > 0
            ? (SystemMonitorService.gpuUsedGb.toFixed(1) + " GB")
            : (Math.round(SystemMonitorService.gpuPercent) + "%"))
    accentColor: tertiary
}
