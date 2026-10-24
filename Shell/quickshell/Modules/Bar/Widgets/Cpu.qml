import QtQuick
import qs.Asura
import qs.Services

HardwareStat {
    id: root

    iconName: "memory"
    value: SystemMonitorService.cpuPercent
    absoluteValue: SystemMonitorService.cpuTemp > 0 ? (SystemMonitorService.cpuTemp + "°C") : (Math.round(SystemMonitorService.cpuPercent) + "%")
    accentColor: primary
}
