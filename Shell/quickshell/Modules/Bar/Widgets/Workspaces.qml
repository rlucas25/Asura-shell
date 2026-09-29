import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.Asura
import qs.Modules.Bar.Widgets

// === HYPRLAND WORKSPACES BAR WIDGET ===

RowLayout {
    id: root

    // Theme color properties
    property color primary: Colors.cfg.primary
    property color surfaceContainer: Colors.cfg.surfaceContainer

    // Compatibility aliases
    property alias color1: root.primary
    property alias base: root.surfaceContainer

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

    // === HELPER METHODS ===

    // Converts numeric integer to Roman numeral
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

    // Dispatches workspace switch to Hyprland
    function switchToWorkspace(id) {
        try {
            Hyprland.dispatch("workspace", "" + id);
        } catch (e) {}
        wsProc.command = ["hyprctl", "eval", "hl.dispatch(hl.dsp.focus({workspace = " + id + "}))"];
        wsProc.running = false;
        wsProc.running = true;
    }

    // Process helper for Hyprland evaluation
    Process {
        id: wsProc

        command: []
    }

    // === WORKSPACE NODES ===

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
            Layout.preferredHeight: 15
            Layout.preferredWidth: isActive ? (root.showNumbers ? 30 : 24) : (isExpanded ? (root.showNumbers ? 25 : 20) : 15)

            color: isActive ? root.color1 : (isExpanded ? Qt.alpha(root.color1, 0.7) : (ws ? Qt.alpha(root.color1, 0.5) : Qt.alpha(Colors.cfg.text, 0.25)))

            Text {
                visible: root.showNumbers && (workspaceNode.isActive || workspaceNode.isExpanded)
                anchors.centerIn: parent
                text: root.formatWorkspaceLabel(workspaceNode.wsId)
                font.pixelSize: (workspaceNode.isActive || workspaceNode.isExpanded) ? 12 : 0
                font.family: "GeistMono Nerd Font Propo ExtraBold"
                color: root.base
            }

            Behavior on Layout.preferredWidth {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.OutCirc
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.switchToWorkspace(workspaceNode.wsId)
                onEntered: workspaceNode.isExpanded = true
                onExited: workspaceNode.isExpanded = false
            }
        }
    }

    Item {
        Layout.fillWidth: true
    }
}
