pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var playerList: Mpris.players.values || []
    readonly property int playerCount: playerList.length

    property string manualSelectedIdentity: ""

    readonly property var activePlayer: {
        var list = playerList;
        if (!list || list.length === 0)
            return null;

        if (manualSelectedIdentity !== "") {
            var found = list.find(p => p && p.identity === manualSelectedIdentity);
            if (found)
                return found;
        }

        var playing = list.find(p => p && p.isPlaying);
        if (playing)
            return playing;

        return list[0] ?? null;
    }

    readonly property bool isPlaying: {
        if (!activePlayer) return false;
        return (activePlayer.playbackState === MprisPlaybackState.Playing) || !!activePlayer.isPlaying;
    }

    function selectPlayer(identity) {
        manualSelectedIdentity = identity;
    }

    function cycleNextPlayer() {
        var list = playerList;
        if (!list || list.length <= 1)
            return;
        var curIdx = list.findIndex(p => p && p.identity === (activePlayer ? activePlayer.identity : ""));
        var nextIdx = (curIdx + 1) % list.length;
        if (list[nextIdx]) {
            manualSelectedIdentity = list[nextIdx].identity;
        }
    }

    function cyclePrevPlayer() {
        var list = playerList;
        if (!list || list.length <= 1)
            return;
        var curIdx = list.findIndex(p => p && p.identity === (activePlayer ? activePlayer.identity : ""));
        var prevIdx = (curIdx - 1 + list.length) % list.length;
        if (list[prevIdx]) {
            manualSelectedIdentity = list[prevIdx].identity;
        }
    }

    function getAppIcon(identity) {
        if (!identity) return "";
        var desktop = (root.activePlayer && root.activePlayer.identity === identity)
            ? (root.activePlayer.desktopEntry || "")
            : "";
        return IconService.getAppIcon(identity, desktop);
    }
}
