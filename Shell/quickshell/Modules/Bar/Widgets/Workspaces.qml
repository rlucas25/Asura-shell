import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.Asura
import qs.Modules.Bar.Widgets

GridLayout {
    id: root

    readonly property bool isVertical: Config.isBarVertical
    columns: isVertical ? 1 : -1
    rows: isVertical ? -1 : 1
    readonly property real scaleFactor: (typeof Config !== "undefined" && Config.barIconScale !== undefined) ? Config.barIconScale : 1.0
    readonly property real nodeSize: Math.round(15 * scaleFactor)

    columnSpacing: Math.round(4 * scaleFactor)
    rowSpacing: Math.round(4 * scaleFactor)

    property color primary: Colors.cfg.primary
    property color secondary: Colors.cfg.secondary
    property color surfaceContainer: Colors.cfg.surfaceContainer

    property alias color1: root.primary
    property alias color2: root.secondary
    property alias base: root.surfaceContainer

    property bool isSpecialActive: false

    readonly property int defaultWorkspacesCount: (Config.cfg && Config.cfg.workspacesCount !== undefined) ? Math.max(1, Config.cfg.workspacesCount) : 3
    readonly property bool showNumbers: (Config.cfg && Config.cfg.workspacesShowNumbers !== undefined) ? Config.cfg.workspacesShowNumbers : true
    readonly property string numberStyle: (Config.cfg && Config.cfg.workspacesNumberStyle !== undefined) ? Config.cfg.workspacesNumberStyle : "roman"

    readonly property var workspaceList: {
        let count = root.defaultWorkspacesCount;
        let arr = [];
        for (let i = 1; i <= count; i++) {
            arr.push(i);
        }
        let ids = new Set(arr);
        if (Hyprland.workspaces && Hyprland.workspaces.values) {
            for (let i = 0; i < Hyprland.workspaces.values.length; i++) {
                let ws = Hyprland.workspaces.values[i];
                if (ws && ws.id > 0) {
                    ids.add(ws.id);
                }
            }
        }
        if (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id > 0) {
            ids.add(Hyprland.focusedWorkspace.id);
        }
        return Array.from(ids).sort((a, b) => a - b);
    }

    function toRoman(num) {
        if (num <= 0)
            return "";
        const romanMap = [
            { value: 10, symbol: "X" },
            { value: 9, symbol: "IX" },
            { value: 5, symbol: "V" },
            { value: 4, symbol: "IV" },
            { value: 1, symbol: "I" }
        ];
        let result = "";
        let n = num;
        for (let i = 0; i < romanMap.length; i++) {
            while (n >= romanMap[i].value) {
                result += romanMap[i].symbol;
                n -= romanMap[i].value;
            }
        }
        return result || num.toString();
    }

    function formatWorkspaceLabel(num) {
        if (!root.showNumbers)
            return "";
        if (root.numberStyle === "common")
            return num.toString();
        return root.toRoman(num);
    }

    function switchToWorkspace(id) {
        try {
            Hyprland.dispatch("workspace", "" + id);
        } catch (e) {}
        wsProc.command = ["hyprctl", "eval", "hl.dispatch(hl.dsp.focus({workspace = " + id + "}))"];
        wsProc.running = false;
        wsProc.running = true;
    }

    function toggleSpecialWorkspace() {
        try {
            Hyprland.dispatch("togglespecialworkspace", "special");
        } catch (e) {}
        wsProc.command = ["hyprctl", "eval", "hl.dispatch(hl.dsp.workspace.toggle_special('special'))"];
        wsProc.running = false;
        wsProc.running = true;
    }

    Process {
        id: wsProc

        command: []
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "activespecial") {
                let data = String(event.data || "");
                let parts = data.split(",");
                let spName = parts[0] ? parts[0].trim() : "";
                root.isSpecialActive = (spName !== "");
            }
        }
    }

    Process {
        id: initSpecialProc

        command: ["hyprctl", "monitors", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let mons = JSON.parse(text);
                    if (Array.isArray(mons)) {
                        let isSp = false;
                        for (let i = 0; i < mons.length; i++) {
                            let sp = mons[i].specialWorkspace;
                            if (sp && sp.name && sp.name !== "") {
                                isSp = true;
                                break;
                            }
                        }
                        root.isSpecialActive = isSp;
                    }
                } catch (e) {}
            }
        }
    }

    Repeater {
        model: root.workspaceList

        Rectangle {
            id: workspaceNode

            required property int modelData
            required property int index

            readonly property int wsId: modelData
            property bool isExpanded: false
            property var ws: Hyprland.workspaces.values.find(w => w.id === wsId)
            property bool isActive: (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId)

            radius: 100
            readonly property real activeLength: root.showNumbers ? Math.round(root.nodeSize * 2.0) : Math.round(root.nodeSize * 1.6)
            readonly property real expandedLength: root.showNumbers ? Math.round(root.nodeSize * 1.67) : Math.round(root.nodeSize * 1.33)
            readonly property real currentLength: isActive ? activeLength : (isExpanded ? expandedLength : root.nodeSize)

            Layout.preferredWidth: root.isVertical ? root.nodeSize : currentLength
            Layout.preferredHeight: root.isVertical ? currentLength : root.nodeSize

            color: workspaceNode.isActive
                ? (root.isSpecialActive ? root.secondary : root.color1)
                : (workspaceNode.isExpanded
                    ? Qt.alpha(root.color1, 0.7)
                    : (workspaceNode.ws ? Qt.alpha(root.color1, 0.5) : Qt.alpha(Colors.cfg.text, 0.25)))

            Behavior on color {
                ColorAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }

            Text {
                visible: (workspaceNode.isActive && root.isSpecialActive) || (root.showNumbers && (workspaceNode.isActive || workspaceNode.isExpanded))
                anchors.centerIn: parent
                text: (workspaceNode.isActive && root.isSpecialActive) ? "S" : root.formatWorkspaceLabel(workspaceNode.wsId)
                font.pixelSize: (workspaceNode.isActive || workspaceNode.isExpanded) ? Math.round(11 * root.scaleFactor) : 0
                font.family: "GeistMono Nerd Font Propo ExtraBold"
                color: root.base
            }

            Behavior on Layout.preferredWidth {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.OutCirc
                }
            }

            Behavior on Layout.preferredHeight {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.OutCirc
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (workspaceNode.isActive && root.isSpecialActive) {
                        root.toggleSpecialWorkspace();
                    } else {
                        root.switchToWorkspace(workspaceNode.wsId);
                    }
                }
                onEntered: workspaceNode.isExpanded = true
                onExited: workspaceNode.isExpanded = false
            }
        }
    }

}

