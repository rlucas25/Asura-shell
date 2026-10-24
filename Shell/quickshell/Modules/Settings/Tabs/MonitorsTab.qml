import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Asura
import qs.Services
import "../Components"

ColumnLayout {
    id: tabRoot

    required property var settingsRoot
    readonly property var root: settingsRoot
    readonly property var activeMon: MonitorService.selectedMonitor
    property string stagedMode: ""
    property real stagedScale: 1
    property int stagedTransform: 0
    property string stagedPosition: "auto"
    property bool stagedVrr: false
    property string lastAppliedNotification: ""
    property bool confirmationActive: false
    property int revertCountdown: 15
    property var previousSnapshot: []
    property bool isReverting: false

    function captureMonitorsSnapshot() {
        var mons = MonitorService.monitors;
        if (!mons || mons.length === 0)
            return [];

        var snap = [];
        for (var i = 0; i < mons.length; i++) {
            var m = mons[i];
            var mMode = (m.width && m.height) ? (m.width + "x" + m.height + "@" + Math.round(m.refreshRate || 60)) : "preferred";
            var mPos = (m.x !== undefined && m.y !== undefined) ? (m.x + "x" + m.y) : "auto";
            snap.push({
                "name": m.name,
                "mode": mMode,
                "position": mPos,
                "scale": (m.scale !== undefined && m.scale !== null) ? m.scale : 1.0,
                "transform": m.transform || 0,
                "vrr": m.vrr || false
            });
        }
        return snap;
    }

    function startConfirmationCountdown() {
        if (!tabRoot.confirmationActive)
            tabRoot.previousSnapshot = tabRoot.captureMonitorsSnapshot();

        tabRoot.revertCountdown = 15;
        tabRoot.confirmationActive = true;
        countdownTimer.restart();
    }

    function confirmChanges() {
        countdownTimer.stop();
        tabRoot.confirmationActive = false;
        tabRoot.previousSnapshot = [];
        tabRoot.revertCountdown = 15;
        tabRoot.lastAppliedNotification = qsTr("Display settings confirmed");
        notifTimer.restart();
    }

    function revertToPreviousConfig() {
        countdownTimer.stop();
        if (!tabRoot.confirmationActive || !tabRoot.previousSnapshot || tabRoot.previousSnapshot.length === 0) {
            tabRoot.confirmationActive = false;
            return ;
        }
        tabRoot.isReverting = true;
        tabRoot.confirmationActive = false;
        var snap = tabRoot.previousSnapshot;
        tabRoot.previousSnapshot = [];
        tabRoot.revertCountdown = 15;
        MonitorService.applyAll(snap);
        for (var i = 0; i < snap.length; i++) {
            if (activeMon && snap[i].name === activeMon.name) {
                tabRoot.stagedMode = snap[i].mode;
                tabRoot.stagedPosition = snap[i].position;
                tabRoot.stagedScale = snap[i].scale;
                tabRoot.stagedTransform = snap[i].transform;
                tabRoot.stagedVrr = snap[i].vrr;
                break;
            }
        }
        tabRoot.layoutCanvasTiles();
        tabRoot.lastAppliedNotification = qsTr("Display settings reverted to previous configuration");
        notifTimer.restart();
        tabRoot.isReverting = false;
    }
    readonly property int monitorCount: (MonitorService.monitors && MonitorService.monitors.length) ? MonitorService.monitors.length : 1
    readonly property real baseTileHeight: {
        var h = (dragCanvas && dragCanvas.height > 60) ? dragCanvas.height : 212;
        if (monitorCount <= 1)
            return Math.min(155, Math.max(130, Math.round(h * 0.72)));
        if (monitorCount === 2)
            return Math.min(118, Math.max(90, Math.round(h * 0.54)));
        if (monitorCount === 3)
            return Math.min(96, Math.max(75, Math.round(h * 0.44)));
        return Math.min(78, Math.max(60, Math.round(h * 0.36)));
    }
    readonly property real effectiveCanvasScale: baseTileHeight / 1080.0
    readonly property real canvasScale: effectiveCanvasScale
    // Track user drag state to prevent unwanted layout resets while dragging
    property bool isUserDragging: false
    property real dragStartX: 0
    property real dragStartY: 0
    property var activeDragTile: null
    property bool snapGuideVisibleX: false
    property real snapGuideX: 0
    property bool snapGuideVisibleY: false
    property real snapGuideY: 0
    property string snapBadgeText: ""

    function syncFromActiveMonitor() {
        if (!activeMon)
            return ;

        stagedMode = (activeMon.width && activeMon.height) ? (activeMon.width + "x" + activeMon.height + "@" + Math.round(activeMon.refreshRate || 60)) : "preferred";
        stagedScale = activeMon.scale || 1;
        stagedTransform = activeMon.transform || 0;
        stagedPosition = (activeMon.x !== undefined && activeMon.y !== undefined) ? (activeMon.x + "x" + activeMon.y) : "auto";
        stagedVrr = activeMon.vrr || false;
    }

    function layoutCanvasTiles() {
        if (!monitorCanvasRepeater || monitorCanvasRepeater.count === 0)
            return ;

        if (!dragCanvas || dragCanvas.width <= 0 || dragCanvas.height <= 0)
            return ;

        var mons = MonitorService.monitors;
        if (!mons || mons.length === 0)
            return ;

        var count = monitorCanvasRepeater.count;

        if (count === 1) {
            var singleTile = monitorCanvasRepeater.itemAt(0);
            if (singleTile) {
                singleTile.x = Math.round((dragCanvas.width - singleTile.width) / 2);
                singleTile.y = Math.round((dragCanvas.height - singleTile.height) / 2);
            }
            return ;
        }

        if (count === 2) {
            var t0 = monitorCanvasRepeater.itemAt(0);
            var t1 = monitorCanvasRepeater.itemAt(1);
            if (t0 && t1 && t0.monData && t1.monData) {
                var m0 = t0.monData;
                var m1 = t1.monData;
                var dx = (m1.x || 0) - (m0.x || 0);
                var dy = (m1.y || 0) - (m0.y || 0);
                var gap = 12;

                if (Math.abs(dx) >= Math.abs(dy)) {
                    var leftTile = (dx >= 0) ? t0 : t1;
                    var rightTile = (dx >= 0) ? t1 : t0;
                    var totalW = leftTile.width + gap + rightTile.width;
                    var startX = Math.round((dragCanvas.width - totalW) / 2);
                    var centerY = Math.round(dragCanvas.height / 2);

                    leftTile.x = Math.max(8, startX);
                    rightTile.x = Math.max(8, startX + leftTile.width + gap);

                    var relDy = (dx >= 0) ? dy : -dy;
                    if (Math.abs(relDy) < 50) {
                        leftTile.y = Math.round(centerY - leftTile.height / 2);
                        rightTile.y = Math.round(centerY - rightTile.height / 2);
                    } else if (relDy > 0) {
                        leftTile.y = Math.round(centerY - leftTile.height / 2 - 12);
                        rightTile.y = Math.round(centerY - rightTile.height / 2 + 12);
                    } else {
                        leftTile.y = Math.round(centerY - leftTile.height / 2 + 12);
                        rightTile.y = Math.round(centerY - rightTile.height / 2 - 12);
                    }
                    return ;
                } else {
                    var topTile = (dy >= 0) ? t0 : t1;
                    var btmTile = (dy >= 0) ? t1 : t0;
                    var totalH = topTile.height + gap + btmTile.height;
                    var startY = Math.round((dragCanvas.height - totalH) / 2);
                    var centerX = Math.round(dragCanvas.width / 2);

                    topTile.y = Math.max(8, startY);
                    btmTile.y = Math.max(8, startY + topTile.height + gap);

                    var relDx = (dy >= 0) ? dx : -dx;
                    if (Math.abs(relDx) < 50) {
                        topTile.x = Math.round(centerX - topTile.width / 2);
                        btmTile.x = Math.round(centerX - btmTile.width / 2);
                    } else if (relDx > 0) {
                        topTile.x = Math.round(centerX - topTile.width / 2 - 16);
                        btmTile.x = Math.round(centerX - btmTile.width / 2 + 16);
                    } else {
                        topTile.x = Math.round(centerX - topTile.width / 2 + 16);
                        btmTile.x = Math.round(centerX - btmTile.width / 2 - 16);
                    }
                    return ;
                }
            }
        }

        var minX = Infinity;
        var minY = Infinity;
        var maxX = -Infinity;
        var maxY = -Infinity;
        for (var i = 0; i < mons.length; i++) {
            var m = mons[i];
            var sc = m.scale || 1;
            var isRot = (m.transform === 1 || m.transform === 3);
            var lw = isRot ? ((m.height || 1080) / sc) : ((m.width || 1920) / sc);
            var lh = isRot ? ((m.width || 1920) / sc) : ((m.height || 1080) / sc);
            var mx = m.x || 0;
            var my = m.y || 0;
            if (mx < minX)
                minX = mx;

            if (my < minY)
                minY = my;

            if (mx + lw > maxX)
                maxX = mx + lw;

            if (my + lh > maxY)
                maxY = my + lh;

        }
        var clusterSpanW = Math.max(1, maxX - minX);
        var clusterSpanH = Math.max(1, maxY - minY);
        var availW = dragCanvas.width - 32;
        var availH = dragCanvas.height - 32;
        var cScale = Math.min(availW / clusterSpanW, availH / clusterSpanH, tabRoot.effectiveCanvasScale);
        var clusterW = clusterSpanW * cScale;
        var clusterH = clusterSpanH * cScale;
        var originX = Math.max(16, Math.round((dragCanvas.width - clusterW) / 2));
        var originY = Math.max(16, Math.round((dragCanvas.height - clusterH) / 2));
        for (var j = 0; j < monitorCanvasRepeater.count; j++) {
            var tile = monitorCanvasRepeater.itemAt(j);
            if (tile && tile.monData) {
                var md = tile.monData;
                var targetX = originX + ((md.x || 0) - minX) * cScale;
                var targetY = originY + ((md.y || 0) - minY) * cScale;
                tile.x = Math.max(8, Math.min(dragCanvas.width - tile.width - 8, Math.round(targetX)));
                tile.y = Math.max(8, Math.min(dragCanvas.height - tile.height - 8, Math.round(targetY)));
            }
        }
    }

    function updateLiveDragSnap(rawX, rawY) {
        if (!activeDragTile)
            return ;

        var wA = activeDragTile.width;
        var hA = activeDragTile.height;
        var maxX = dragCanvas.width - wA - 8;
        var maxY = dragCanvas.height - hA - 8;
        var clampedX = Math.max(8, Math.min(maxX, rawX));
        var clampedY = Math.max(8, Math.min(maxY, rawY));
        var bestX = null;
        var bestDistX = 16;
        var foundGuideX = 0;
        var labelX = "";
        var bestY = null;
        var bestDistY = 16;
        var foundGuideY = 0;
        var labelY = "";
        for (var i = 0; i < monitorCanvasRepeater.count; i++) {
            var tileB = monitorCanvasRepeater.itemAt(i);
            if (!tileB || tileB === activeDragTile)
                continue;

            var xB = tileB.x;
            var yB = tileB.y;
            var wB = tileB.width;
            var hB = tileB.height;
            var xCandidates = [{
                "x": xB + wB,
                "gx": xB + wB,
                "lbl": qsTr("Docked Right")
            }, {
                "x": xB - wA,
                "gx": xB,
                "lbl": qsTr("Docked Left")
            }, {
                "x": xB,
                "gx": xB,
                "lbl": qsTr("Left Aligned")
            }, {
                "x": xB + wB - wA,
                "gx": xB + wB,
                "lbl": qsTr("Right Aligned")
            }, {
                "x": xB + (wB - wA) / 2,
                "gx": xB + wB / 2,
                "lbl": qsTr("Center Aligned")
            }];
            for (var cx = 0; cx < xCandidates.length; cx++) {
                var candX = xCandidates[cx];
                var distX = Math.abs(clampedX - candX.x);
                if (distX <= bestDistX) {
                    bestDistX = distX;
                    bestX = candX.x;
                    foundGuideX = candX.gx;
                    labelX = candX.lbl;
                }
            }
            var yCandidates = [{
                "y": yB + hB,
                "gy": yB + hB,
                "lbl": qsTr("Docked Below")
            }, {
                "y": yB - hA,
                "gy": yB,
                "lbl": qsTr("Docked Above")
            }, {
                "y": yB,
                "gy": yB,
                "lbl": qsTr("Top Aligned")
            }, {
                "y": yB + hB - hA,
                "gy": yB + hB,
                "lbl": qsTr("Bottom Aligned")
            }, {
                "y": yB + (hB - hA) / 2,
                "gy": yB + hB / 2,
                "lbl": qsTr("Center Aligned")
            }];
            for (var cy = 0; cy < yCandidates.length; cy++) {
                var candY = yCandidates[cy];
                var distY = Math.abs(clampedY - candY.y);
                if (distY <= bestDistY) {
                    bestDistY = distY;
                    bestY = candY.y;
                    foundGuideY = candY.gy;
                    labelY = candY.lbl;
                }
            }
        }
        activeDragTile.x = (bestX !== null) ? Math.max(8, Math.min(maxX, Math.round(bestX))) : clampedX;
        activeDragTile.y = (bestY !== null) ? Math.max(8, Math.min(maxY, Math.round(bestY))) : clampedY;
        if (bestX !== null) {
            snapGuideVisibleX = true;
            snapGuideX = foundGuideX;
        } else {
            snapGuideVisibleX = false;
        }
        if (bestY !== null) {
            snapGuideVisibleY = true;
            snapGuideY = foundGuideY;
        } else {
            snapGuideVisibleY = false;
        }
        if (labelX && labelY)
            snapBadgeText = labelX + " • " + labelY;
        else if (labelX)
            snapBadgeText = labelX;
        else if (labelY)
            snapBadgeText = labelY;
        else
            snapBadgeText = "";
    }

    // Apply specific property immediately to Hyprland with zero latency
    function applyPropertyChange(newMode, newPos, newScale, newTransform, newVrr) {
        if (!activeMon)
            return ;

        startConfirmationCountdown();
        stagedMode = newMode;
        stagedPosition = newPos;
        stagedScale = newScale;
        stagedTransform = newTransform;
        stagedVrr = newVrr;
        MonitorService.applyMonitor(activeMon.name, newMode, newPos, newScale, newTransform, newVrr);
        lastAppliedNotification = qsTr("Applied %1 (%2x) - Confirm in %3s").arg(activeMon.name).arg(newScale).arg(revertCountdown);
        notifTimer.restart();
    }

    function arrangePresets(mode) {
        var mons = MonitorService.monitors;
        if (!mons || mons.length < 2)
            return ;

        startConfirmationCountdown();
        var payload = [];
        var curX = 0;
        var curY = 0;
        for (var i = 0; i < mons.length; i++) {
            var m = mons[i];
            var sc = m.scale || 1;
            var isRot = (m.transform === 1 || m.transform === 3);
            var lw = Math.round(isRot ? ((m.height || 1080) / sc) : ((m.width || 1920) / sc));
            var lh = Math.round(isRot ? ((m.width || 1920) / sc) : ((m.height || 1080) / sc));
            var mMode = (m.width && m.height) ? (m.width + "x" + m.height + "@" + Math.round(m.refreshRate || 60)) : "preferred";
            payload.push({
                "name": m.name,
                "mode": mMode,
                "position": (mode === "vertical" ? ("0x" + curY) : (curX + "x0")),
                "scale": m.scale || 1,
                "transform": m.transform || 0,
                "vrr": m.vrr || false
            });
            if (mode === "vertical")
                curY += lh;
            else
                curX += lw;
        }
        MonitorService.applyAll(payload);
        lastAppliedNotification = (mode === "vertical") ? qsTr("Arranged displays vertically") : qsTr("Arranged displays horizontally");
        notifTimer.restart();
    }

    function applyDraggedArrangement(draggedTile) {
        if (!monitorCanvasRepeater || monitorCanvasRepeater.count < 2) {
            tabRoot.layoutCanvasTiles();
            return ;
        }

        startConfirmationCountdown();
        var count = monitorCanvasRepeater.count;
        var tiles = [];
        for (var i = 0; i < count; i++) {
            var item = monitorCanvasRepeater.itemAt(i);
            if (item && item.monData)
                tiles.push(item);

        }
        if (tiles.length < 2)
            return ;

        if (tiles.length === 2) {
            var tA = draggedTile || tiles[0];
            var tB = (tiles[0] === tA) ? tiles[1] : tiles[0];
            var wA = tA.width, hA = tA.height;
            var wB = tB.width, hB = tB.height;
            var logWA = tA.logW, logHA = tA.logH;
            var logWB = tB.logW, logHB = tB.logH;
            var cX = (tA.x + wA / 2) - (tB.x + wB / 2);
            var cY = (tA.y + hA / 2) - (tB.y + hB / 2);
            var normX = cX / ((wA + wB) / 2);
            var normY = cY / ((hA + hB) / 2);
            var logXA = 0, logYA = 0;
            var logXB = 0, logYB = 0;
            if (Math.abs(normY) > Math.abs(normX)) {
                if (normY > 0) {
                    logYB = 0;
                    logYA = logHB;
                    if (Math.abs(tA.x - tB.x) < 24) {
                        logXA = 0;
                        logXB = 0;
                    } else if (Math.abs((tA.x + wA) - (tB.x + wB)) < 24) {
                        if (logWB >= logWA) {
                            logXB = 0;
                            logXA = Math.max(0, logWB - logWA);
                        } else {
                            logXA = 0;
                            logXB = Math.max(0, logWA - logWB);
                        }
                    } else if (Math.abs(cX) < 24) {
                        if (logWB >= logWA) {
                            logXB = 0;
                            logXA = Math.round((logWB - logWA) / 2);
                        } else {
                            logXA = 0;
                            logXB = Math.round((logWA - logWB) / 2);
                        }
                    } else {
                        var deltaX = Math.round((tA.x - tB.x) / tabRoot.canvasScale);
                        if (deltaX >= 0) {
                            logXB = 0;
                            logXA = deltaX;
                        } else {
                            logXA = 0;
                            logXB = -deltaX;
                        }
                    }
                } else {
                    logYA = 0;
                    logYB = logHA;
                    if (Math.abs(tA.x - tB.x) < 24) {
                        logXA = 0;
                        logXB = 0;
                    } else if (Math.abs((tA.x + wA) - (tB.x + wB)) < 24) {
                        if (logWA >= logWB) {
                            logXA = 0;
                            logXB = Math.max(0, logWA - logWB);
                        } else {
                            logXB = 0;
                            logXA = Math.max(0, logWB - logWA);
                        }
                    } else if (Math.abs(cX) < 24) {
                        if (logWA >= logWB) {
                            logXA = 0;
                            logXB = Math.round((logWA - logWB) / 2);
                        } else {
                            logXB = 0;
                            logXA = Math.round((logWA - logWB) / 2);
                        }
                    } else {
                        var deltaX = Math.round((tA.x - tB.x) / tabRoot.canvasScale);
                        if (deltaX >= 0) {
                            logXB = 0;
                            logXA = deltaX;
                        } else {
                            logXA = 0;
                            logXB = -deltaX;
                        }
                    }
                }
            } else {
                if (normX > 0) {
                    logXB = 0;
                    logXA = logWB;
                    if (Math.abs(tA.y - tB.y) < 24) {
                        logYA = 0;
                        logYB = 0;
                    } else if (Math.abs((tA.y + hA) - (tB.y + hB)) < 24) {
                        if (logHB >= logHA) {
                            logYB = 0;
                            logYA = Math.max(0, logHB - logHA);
                        } else {
                            logYA = 0;
                            logYB = Math.max(0, logHA - logHB);
                        }
                    } else if (Math.abs(cY) < 24) {
                        if (logHB >= logHA) {
                            logYB = 0;
                            logYA = Math.round((logHB - logHA) / 2);
                        } else {
                            logYA = 0;
                            logYB = Math.round((logHA - logHB) / 2);
                        }
                    } else {
                        var deltaY = Math.round((tA.y - tB.y) / tabRoot.canvasScale);
                        if (deltaY >= 0) {
                            logYB = 0;
                            logYA = deltaY;
                        } else {
                            logYA = 0;
                            logYB = -deltaY;
                        }
                    }
                } else {
                    logXA = 0;
                    logXB = logWA;
                    if (Math.abs(tA.y - tB.y) < 24) {
                        logYA = 0;
                        logYB = 0;
                    } else if (Math.abs((tA.y + hA) - (tB.y + hB)) < 24) {
                        if (logHA >= logHB) {
                            logYA = 0;
                            logYB = Math.max(0, logHA - logHB);
                        } else {
                            logYB = 0;
                            logYA = Math.max(0, logHB - logHA);
                        }
                    } else if (Math.abs(cY) < 24) {
                        if (logHA >= logHB) {
                            logYA = 0;
                            logYB = Math.round((logHA - logHB) / 2);
                        } else {
                            logYB = 0;
                            logYA = Math.round((logHB - logHA) / 2);
                        }
                    } else {
                        var deltaY = Math.round((tA.y - tB.y) / tabRoot.canvasScale);
                        if (deltaY >= 0) {
                            logYB = 0;
                            logYA = deltaY;
                        } else {
                            logYA = 0;
                            logYB = -deltaY;
                        }
                    }
                }
            }
            var modeA = (tA.monData.width && tA.monData.height) ? (tA.monData.width + "x" + tA.monData.height + "@" + Math.round(tA.monData.refreshRate || 60)) : "preferred";
            var modeB = (tB.monData.width && tB.monData.height) ? (tB.monData.width + "x" + tB.monData.height + "@" + Math.round(tB.monData.refreshRate || 60)) : "preferred";
            var payload = [{
                "name": tA.monData.name,
                "mode": modeA,
                "position": logXA + "x" + logYA,
                "scale": tA.monData.scale || 1,
                "transform": tA.monData.transform || 0,
                "vrr": tA.monData.vrr || false
            }, {
                "name": tB.monData.name,
                "mode": modeB,
                "position": logXB + "x" + logYB,
                "scale": tB.monData.scale || 1,
                "transform": tB.monData.transform || 0,
                "vrr": tB.monData.vrr || false
            }];
            MonitorService.applyAll(payload);
            lastAppliedNotification = qsTr("Display arrangement updated");
            notifTimer.restart();
            return ;
        }
        var minCanvasX = Infinity, minCanvasY = Infinity;
        for (var k = 0; k < tiles.length; k++) {
            if (tiles[k].x < minCanvasX)
                minCanvasX = tiles[k].x;

            if (tiles[k].y < minCanvasY)
                minCanvasY = tiles[k].y;

        }
        var payloadN = [];
        for (var n = 0; n < tiles.length; n++) {
            var tn = tiles[n];
            var lX = Math.round((tn.x - minCanvasX) / tabRoot.canvasScale);
            var lY = Math.round((tn.y - minCanvasY) / tabRoot.canvasScale);
            var mModeN = (tn.monData.width && tn.monData.height) ? (tn.monData.width + "x" + tn.monData.height + "@" + Math.round(tn.monData.refreshRate || 60)) : "preferred";
            payloadN.push({
                "name": tn.monData.name,
                "mode": mModeN,
                "position": Math.max(0, lX) + "x" + Math.max(0, lY),
                "scale": tn.monData.scale || 1,
                "transform": tn.monData.transform || 0,
                "vrr": tn.monData.vrr || false
            });
        }
        MonitorService.applyAll(payloadN);
        lastAppliedNotification = qsTr("Display arrangement updated");
        notifTimer.restart();
    }

    Layout.fillWidth: true
    spacing: 16
    visible: root.currentTab === "monitors"
    onActiveMonChanged: {
        syncFromActiveMonitor();
    }
    Component.onCompleted: {
        syncFromActiveMonitor();
        layoutCanvasTiles();
    }
    onVisibleChanged: {
        if (visible) {
            syncFromActiveMonitor();
            layoutCanvasTiles();
        }
    }

    Connections {
        function onMonitorsUpdated() {
            if (!tabRoot.isUserDragging)
                tabRoot.layoutCanvasTiles();

            if (activeMon && !tabRoot.confirmationActive) {
                stagedScale = activeMon.scale || 1;
                stagedTransform = activeMon.transform || 0;
                stagedVrr = activeMon.vrr || false;
                stagedPosition = (activeMon.x !== undefined && activeMon.y !== undefined) ? (activeMon.x + "x" + activeMon.y) : "auto";
                if (activeMon.width && activeMon.height)
                    stagedMode = activeMon.width + "x" + activeMon.height + "@" + Math.round(activeMon.refreshRate || 60);

            }
        }

        target: MonitorService
    }

    Timer {
        id: notifTimer

        interval: 3000
        repeat: false
        onTriggered: tabRoot.lastAppliedNotification = ""
    }

    Timer {
        id: countdownTimer

        interval: 1000
        repeat: true
        running: false
        onTriggered: {
            if (!tabRoot.confirmationActive) {
                stop();
                return ;
            }
            tabRoot.revertCountdown--;
            if (tabRoot.revertCountdown <= 0)
                tabRoot.revertToPreviousConfig();

        }
    }

    SettingSectionHeader {
        icon: "desktop_windows"
        title: qsTr("Monitors & Displays")
        description: qsTr("Arrange screens by dragging, adjust scale and resolution")

        SettingButton {
            icon: "refresh"
            text: qsTr("Detect")
            variant: "secondary"
            onClicked: MonitorService.refresh()
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: tabRoot.confirmationActive ? 56 : 0
        radius: 12
        color: (tabRoot.revertCountdown <= 5) ? Qt.alpha(Colors.cfg.error, 0.16) : Qt.alpha(root.color1, 0.16)
        border.color: (tabRoot.revertCountdown <= 5) ? Colors.cfg.error : Qt.alpha(root.color1, 0.5)
        border.width: 1.5
        visible: tabRoot.confirmationActive
        clip: true

        Behavior on implicitHeight {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }

        }

        Behavior on color {
            ColorAnimation {
                duration: 200
            }

        }

        Behavior on border.color {
            ColorAnimation {
                duration: 200
            }

        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 12

            Rectangle {
                implicitWidth: 34
                implicitHeight: 34
                radius: 17
                color: (tabRoot.revertCountdown <= 5) ? Qt.alpha(Colors.cfg.error, 0.25) : Qt.alpha(root.color1, 0.25)
                border.color: (tabRoot.revertCountdown <= 5) ? Colors.cfg.error : root.color1
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: tabRoot.revertCountdown + "s"
                    font.family: "Google Sans"
                    font.pixelSize: 11
                    font.bold: true
                    color: (tabRoot.revertCountdown <= 5) ? Colors.cfg.error : root.color1
                }

            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 160
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Keep new display settings?")
                    font.family: "Google Sans"
                    font.pixelSize: 12
                    font.bold: true
                    color: root.textBright
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Reverting to previous settings in %1s if unconfirmed (Press Enter to keep, Esc to revert)").arg(tabRoot.revertCountdown)
                    font.family: "Google Sans"
                    font.pixelSize: 10
                    color: root.textMuted
                    elide: Text.ElideRight
                }

            }

            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 8

                SettingButton {
                    text: qsTr("Revert")
                    icon: "undo"
                    variant: "danger"
                    compact: true
                    Layout.minimumWidth: implicitWidth
                    onClicked: tabRoot.revertToPreviousConfig()
                }

                SettingButton {
                    text: qsTr("Keep Changes")
                    icon: "check"
                    variant: "primary"
                    compact: true
                    Layout.minimumWidth: implicitWidth
                    onClicked: tabRoot.confirmChanges()
                }

            }

        }

    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: tabRoot.lastAppliedNotification ? 32 : 0
        radius: 8
        color: Qt.alpha(root.color1, 0.15)
        border.color: Qt.alpha(root.color1, 0.4)
        border.width: 1
        visible: tabRoot.lastAppliedNotification !== ""
        clip: true

        RowLayout {
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: "check"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 14
                color: root.color1
            }

            Text {
                text: tabRoot.lastAppliedNotification
                font.family: "Google Sans"
                font.pixelSize: 10
                font.bold: true
                color: root.textBright
            }

        }

        Behavior on implicitHeight {
            NumberAnimation {
                duration: 200
            }

        }

    }

    Rectangle {
        id: canvasWrapper

        Layout.fillWidth: true
        Layout.preferredHeight: 280
        radius: 18
        color: root.surface
        border.color: Qt.alpha(root.borderCol, 0.35)
        border.width: 1
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: qsTr("Display Arrangement")
                    font.family: "Google Sans"
                    font.pixelSize: 12
                    font.bold: true
                    color: root.textColor
                }

                Text {
                    text: tabRoot.monitorCount <= 1 ? qsTr("Single display preview") : qsTr("Drag to arrange in 2D")
                    font.family: "Google Sans"
                    font.pixelSize: 10
                    color: root.textMuted
                    Layout.fillWidth: true
                }

                Rectangle {
                    visible: tabRoot.monitorCount >= 2
                    implicitWidth: sideBtnRow.implicitWidth + 14
                    implicitHeight: 26
                    radius: 13
                    color: sideHover.hovered ? Qt.alpha(root.color1, 0.18) : root.surfaceContainer
                    border.color: Qt.alpha(root.color1, 0.25)
                    border.width: 1

                    RowLayout {
                        id: sideBtnRow

                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "view_column"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 15
                            color: root.color1
                        }

                        Text {
                            text: qsTr("Side by Side")
                            font.family: "Google Sans"
                            font.pixelSize: 10
                            font.bold: true
                            color: root.textBright
                        }

                    }

                    HoverHandler {
                        id: sideHover
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: tabRoot.arrangePresets("horizontal")
                    }

                }

                Rectangle {
                    visible: tabRoot.monitorCount >= 2
                    implicitWidth: stackBtnRow.implicitWidth + 14
                    implicitHeight: 26
                    radius: 13
                    color: stackHover.hovered ? Qt.alpha(root.color1, 0.18) : root.surfaceContainer
                    border.color: Qt.alpha(root.color1, 0.25)
                    border.width: 1

                    RowLayout {
                        id: stackBtnRow

                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "table_rows"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 15
                            color: root.color1
                        }

                        Text {
                            text: qsTr("Stacked")
                            font.family: "Google Sans"
                            font.pixelSize: 10
                            font.bold: true
                            color: root.textBright
                        }

                    }

                    HoverHandler {
                        id: stackHover
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: tabRoot.arrangePresets("vertical")
                    }

                }

            }

            Rectangle {
                id: dragCanvas

                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: root.surfaceContainer
                border.color: Qt.alpha(root.borderCol, 0.25)
                border.width: 1
                clip: true
                onWidthChanged: {
                    if (width > 0 && !tabRoot.isUserDragging)
                        tabRoot.layoutCanvasTiles();

                }
                onHeightChanged: {
                    if (height > 0 && !tabRoot.isUserDragging)
                        tabRoot.layoutCanvasTiles();

                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: Qt.alpha(root.borderCol, 0.15)
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Qt.alpha(root.borderCol, 0.15)
                }

                Item {
                    id: dragProxy

                    width: 1
                    height: 1
                    visible: false
                    onXChanged: {
                        if (tabRoot.isUserDragging && tabRoot.activeDragTile)
                            tabRoot.updateLiveDragSnap(dragProxy.x, dragProxy.y);

                    }
                    onYChanged: {
                        if (tabRoot.isUserDragging && tabRoot.activeDragTile)
                            tabRoot.updateLiveDragSnap(dragProxy.x, dragProxy.y);

                    }
                }

                Rectangle {
                    id: vSnapGuide

                    visible: tabRoot.snapGuideVisibleX && tabRoot.isUserDragging
                    x: Math.round(tabRoot.snapGuideX)
                    y: 0
                    width: 2
                    height: parent.height
                    color: root.color1
                    z: 35
                    opacity: 0.9

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -1
                        color: "transparent"
                        border.color: Qt.alpha(root.color1, 0.35)
                        border.width: 1
                    }

                }

                Rectangle {
                    id: hSnapGuide

                    visible: tabRoot.snapGuideVisibleY && tabRoot.isUserDragging
                    x: 0
                    y: Math.round(tabRoot.snapGuideY)
                    width: parent.width
                    height: 2
                    color: root.color1
                    z: 35
                    opacity: 0.9

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -1
                        color: "transparent"
                        border.color: Qt.alpha(root.color1, 0.35)
                        border.width: 1
                    }

                }

                Rectangle {
                    visible: tabRoot.isUserDragging && tabRoot.snapBadgeText !== ""
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 8
                    implicitHeight: 24
                    implicitWidth: snapBadgeRow.implicitWidth + 18
                    radius: 12
                    color: Qt.alpha(root.surface, 0.94)
                    border.color: root.color1
                    border.width: 1
                    z: 45

                    RowLayout {
                        id: snapBadgeRow

                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: "check"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 13
                            font.bold: true
                            color: root.color1
                        }

                        Text {
                            text: tabRoot.snapBadgeText
                            font.family: "Google Sans"
                            font.pixelSize: 10
                            font.bold: true
                            color: root.textBright
                        }

                    }

                }

                Repeater {
                    id: monitorCanvasRepeater

                    model: MonitorService.monitors

                    Rectangle {
                        id: draggableTile

                        required property var modelData
                        required property int index
                        readonly property var monData: modelData
                        readonly property bool isSelected: tabRoot.activeMon && (tabRoot.activeMon.name === modelData.name)
                        readonly property bool isFocused: modelData.focused || false
                        readonly property bool isRotated: (modelData.transform === 1 || modelData.transform === 3)
                        readonly property real logW: isRotated ? ((modelData.height || 1080) / (modelData.scale || 1)) : ((modelData.width || 1920) / (modelData.scale || 1))
                        readonly property real logH: isRotated ? ((modelData.width || 1920) / (modelData.scale || 1)) : ((modelData.height || 1080) / (modelData.scale || 1))

                        readonly property real rawAspect: (modelData.width && modelData.height && modelData.height > 0) ? (modelData.width / modelData.height) : (16 / 9)
                        readonly property real aspectRatio: isRotated ? (1.0 / Math.max(0.2, rawAspect)) : rawAspect

                        width: Math.max(80, Math.round(tabRoot.baseTileHeight * aspectRatio))
                        height: Math.max(50, Math.round(tabRoot.baseTileHeight))
                        radius: tabRoot.monitorCount <= 1 ? 14 : 10
                        Component.onCompleted: {
                            if (!tabRoot.isUserDragging)
                                tabRoot.layoutCanvasTiles();

                        }
                        z: tileMouseArea.drag.active ? 50 : (isSelected ? 10 : 1)
                        scale: tileMouseArea.drag.active ? 1.04 : 1
                        color: isSelected ? Qt.alpha(root.color1, tileMouseArea.drag.active ? 0.35 : 0.2) : (tileHover.hovered ? Qt.alpha(root.color1, 0.08) : root.surface)
                        border.color: isSelected ? root.color1 : Qt.alpha(root.borderCol, 0.5)
                        border.width: isSelected ? (tabRoot.monitorCount <= 1 ? 2.5 : 2) : 1

                        Text {
                            anchors.centerIn: parent
                            text: (draggableTile.index + 1)
                            font.family: "Google Sans"
                            font.pixelSize: tabRoot.monitorCount <= 1 ? 64 : (tabRoot.monitorCount === 2 ? 46 : 32)
                            font.bold: true
                            color: draggableTile.isSelected ? Qt.alpha(root.color1, 0.08) : Qt.alpha(root.textColor, 0.04)
                            visible: draggableTile.width >= 90 && draggableTile.height >= 60
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: tabRoot.monitorCount <= 1 ? 4 : 2

                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: tabRoot.monitorCount <= 1 ? 6 : 4

                                Text {
                                    text: "desktop_windows"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: tabRoot.monitorCount <= 1 ? 22 : (tabRoot.monitorCount === 2 ? 18 : 14)
                                    color: draggableTile.isSelected ? root.color1 : root.textColor
                                }

                                Text {
                                    text: draggableTile.modelData.name || ("Display " + (draggableTile.index + 1))
                                    font.family: "Google Sans"
                                    font.pixelSize: tabRoot.monitorCount <= 1 ? 14 : (tabRoot.monitorCount === 2 ? 11 : 9)
                                    font.bold: true
                                    color: draggableTile.isSelected ? root.color1 : root.textBright
                                }

                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: draggableTile.modelData.width + "×" + draggableTile.modelData.height + (draggableTile.modelData.refreshRate ? (" @ " + Math.round(draggableTile.modelData.refreshRate) + "Hz") : "")
                                font.family: "Google Sans"
                                font.pixelSize: tabRoot.monitorCount <= 1 ? 11 : (tabRoot.monitorCount === 2 ? 9 : 8)
                                color: root.textMuted
                            }

                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 4

                                Rectangle {
                                    implicitHeight: tabRoot.monitorCount <= 1 ? 20 : 16
                                    implicitWidth: scaleTxt.implicitWidth + (tabRoot.monitorCount <= 1 ? 12 : 8)
                                    radius: height / 2
                                    color: Qt.alpha(root.color1, draggableTile.isSelected ? 0.25 : 0.12)

                                    Text {
                                        id: scaleTxt
                                        anchors.centerIn: parent
                                        text: Math.round((draggableTile.modelData.scale || 1) * 100) + "%"
                                        font.family: "Google Sans"
                                        font.pixelSize: tabRoot.monitorCount <= 1 ? 10 : 8
                                        color: root.color1
                                        font.bold: true
                                    }

                                }

                                Rectangle {
                                    visible: draggableTile.modelData.vrr || false
                                    implicitHeight: tabRoot.monitorCount <= 1 ? 20 : 16
                                    implicitWidth: vrrTxt.implicitWidth + (tabRoot.monitorCount <= 1 ? 12 : 8)
                                    radius: height / 2
                                    color: Qt.alpha(root.color1, 0.15)

                                    Text {
                                        id: vrrTxt
                                        anchors.centerIn: parent
                                        text: "VRR"
                                        font.family: "Google Sans"
                                        font.pixelSize: tabRoot.monitorCount <= 1 ? 10 : 8
                                        color: root.color1
                                        font.bold: true
                                    }

                                }

                                Rectangle {
                                    visible: draggableTile.isRotated
                                    implicitHeight: tabRoot.monitorCount <= 1 ? 20 : 16
                                    implicitWidth: rotTxt.implicitWidth + (tabRoot.monitorCount <= 1 ? 12 : 8)
                                    radius: height / 2
                                    color: Qt.alpha(root.color1, 0.15)

                                    Text {
                                        id: rotTxt
                                        anchors.centerIn: parent
                                        text: (draggableTile.modelData.transform === 1 ? "90°" : (draggableTile.modelData.transform === 3 ? "270°" : "180°"))
                                        font.family: "Google Sans"
                                        font.pixelSize: tabRoot.monitorCount <= 1 ? 10 : 8
                                        color: root.color1
                                        font.bold: true
                                    }

                                }

                            }

                        }

                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: tabRoot.monitorCount <= 1 ? 8 : 4
                            implicitWidth: tabRoot.monitorCount <= 1 ? 20 : 14
                            implicitHeight: tabRoot.monitorCount <= 1 ? 20 : 14
                            radius: height / 2
                            visible: draggableTile.isFocused
                            color: root.color1

                            Text {
                                anchors.centerIn: parent
                                text: "★"
                                font.pixelSize: tabRoot.monitorCount <= 1 ? 11 : 8
                                color: root.foreground
                            }

                        }

                        HoverHandler {
                            id: tileHover
                        }

                        MouseArea {
                            id: tileMouseArea

                            anchors.fill: parent
                            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                            drag.target: dragProxy
                            drag.axis: Drag.XAndYAxis
                            onPressed: {
                                dragProxy.x = draggableTile.x;
                                dragProxy.y = draggableTile.y;
                                tileMouseArea.drag.minimumX = 8;
                                tileMouseArea.drag.maximumX = dragCanvas.width - draggableTile.width - 8;
                                tileMouseArea.drag.minimumY = 8;
                                tileMouseArea.drag.maximumY = dragCanvas.height - draggableTile.height - 8;
                                tabRoot.activeDragTile = draggableTile;
                                tabRoot.isUserDragging = true;
                                tabRoot.dragStartX = draggableTile.x;
                                tabRoot.dragStartY = draggableTile.y;
                                MonitorService.selectByName(draggableTile.modelData.name);
                            }
                            onReleased: {
                                tabRoot.isUserDragging = false;
                                tabRoot.snapGuideVisibleX = false;
                                tabRoot.snapGuideVisibleY = false;
                                tabRoot.snapBadgeText = "";
                                var moved = Math.abs(draggableTile.x - tabRoot.dragStartX) > 4 || Math.abs(draggableTile.y - tabRoot.dragStartY) > 4;
                                if (moved)
                                    tabRoot.applyDraggedArrangement(draggableTile);

                                tabRoot.activeDragTile = null;
                            }
                        }

                        Behavior on x {
                            enabled: !tileMouseArea.drag.active

                            NumberAnimation {
                                duration: 180
                                easing.type: Easing.OutCubic
                            }

                        }

                        Behavior on y {
                            enabled: !tileMouseArea.drag.active

                            NumberAnimation {
                                duration: 180
                                easing.type: Easing.OutCubic
                            }

                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 120
                            }

                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }

                        }

                    }

                }

            }

        }

    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 72
        radius: 14
        color: root.surface
        visible: tabRoot.activeMon !== null

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Rectangle {
                implicitWidth: 40
                implicitHeight: 40
                radius: 10
                color: Qt.alpha(root.color1, 0.15)
                border.color: Qt.alpha(root.color1, 0.25)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "desktop_windows"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 22
                    color: root.color1
                }

            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    spacing: 8

                    Text {
                        text: tabRoot.activeMon ? (tabRoot.activeMon.name) : ""
                        font.family: "Google Sans"
                        font.pixelSize: 13
                        font.bold: true
                        color: root.textBright
                    }

                    Rectangle {
                        implicitHeight: 18
                        implicitWidth: dpmsTxt.implicitWidth + 12
                        radius: 9
                        color: (tabRoot.activeMon && tabRoot.activeMon.dpmsStatus) ? Qt.alpha(root.color1, 0.2) : Qt.alpha(root.borderCol, 0.3)

                        Text {
                            id: dpmsTxt

                            anchors.centerIn: parent
                            text: (tabRoot.activeMon && tabRoot.activeMon.dpmsStatus) ? qsTr("Active") : qsTr("Suspended")
                            font.family: "Google Sans"
                            font.pixelSize: 8
                            font.bold: true
                            color: (tabRoot.activeMon && tabRoot.activeMon.dpmsStatus) ? root.color1 : root.textMuted
                        }

                    }

                }

                Text {
                    text: tabRoot.activeMon ? ((tabRoot.activeMon.description && tabRoot.activeMon.description.length > 0) ? tabRoot.activeMon.description : (tabRoot.activeMon.make + " " + tabRoot.activeMon.model)) : ""
                    font.family: "Google Sans"
                    font.pixelSize: 10
                    color: root.textMuted
                    elide: Text.ElideRight
                    Layout.maximumWidth: 420
                }

            }

            Rectangle {
                implicitWidth: 100
                implicitHeight: 32
                radius: 16
                color: dpmsBtnH.hovered ? Qt.alpha(root.color1, 0.25) : root.surfaceContainer
                border.color: Qt.alpha(root.color1, 0.3)
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "power_settings_new"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 15
                        color: (tabRoot.activeMon && tabRoot.activeMon.dpmsStatus) ? root.color1 : root.textMuted
                    }

                    Text {
                        text: (tabRoot.activeMon && tabRoot.activeMon.dpmsStatus) ? qsTr("Turn Off") : qsTr("Turn On")
                        font.family: "Google Sans"
                        font.pixelSize: 10
                        font.bold: true
                        color: root.textBright
                    }

                }

                HoverHandler {
                    id: dpmsBtnH
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (tabRoot.activeMon)
                            MonitorService.setDpms(tabRoot.activeMon.name, !tabRoot.activeMon.dpmsStatus);

                    }
                }

            }

        }

    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 140
        radius: 14
        color: root.surface
        visible: tabRoot.activeMon !== null

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            SettingSlider {
                title: qsTr("Display Scaling")
                description: qsTr("Proportionally scales UI elements and text size for high density displays.")
                from: 0.5
                to: 2.25
                stepSize: 0.05
                value: tabRoot.stagedScale
                showReset: true
                resetValue: 1.0
                customValueText: Math.round(tabRoot.stagedScale * 100) + "% (" + Number(tabRoot.stagedScale).toFixed(2) + "x)"
                onValueModified: (val) => {
                    tabRoot.stagedScale = val;
                }
                onValueCommitted: (val) => {
                    tabRoot.stagedScale = val;
                    tabRoot.applyPropertyChange(tabRoot.stagedMode, tabRoot.stagedPosition, val, tabRoot.stagedTransform, tabRoot.stagedVrr);
                }
            }

            SettingPills {
                model: [
                    { "label": "50%", "val": 0.5 },
                    { "label": "75%", "val": 0.75 },
                    { "label": "80%", "val": 0.8 },
                    { "label": "90%", "val": 0.9 },
                    { "label": "100%", "val": 1 },
                    { "label": "125%", "val": 1.25 },
                    { "label": "150%", "val": 1.5 },
                    { "label": "175%", "val": 1.75 },
                    { "label": "200%", "val": 2 }
                ]
                currentValue: tabRoot.stagedScale
                fillWidth: true
                onSelected: (val) => {
                    tabRoot.applyPropertyChange(tabRoot.stagedMode, tabRoot.stagedPosition, val, tabRoot.stagedTransform, tabRoot.stagedVrr);
                }
            }

        }

    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 116
        radius: 14
        color: root.surface
        visible: tabRoot.activeMon !== null

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: qsTr("Resolution & Refresh Rate:")
                    font.family: "Google Sans"
                    font.pixelSize: 11
                    font.bold: true
                    color: root.textColor
                    Layout.fillWidth: true
                }

                Text {
                    text: tabRoot.stagedMode
                    font.family: "Google Sans"
                    font.pixelSize: 11
                    font.bold: true
                    color: root.color1
                }

            }

            Text {
                text: qsTr("Choose standard mode or preferred native display timings.")
                font.family: "Google Sans"
                font.pixelSize: 10
                color: root.textMuted
            }

            RowLayout {
                spacing: 6
                Layout.fillWidth: true

                Repeater {
                    model: {
                        var resList = [];
                        if (tabRoot.activeMon && tabRoot.activeMon.width && tabRoot.activeMon.height) {
                            var nativeMode = tabRoot.activeMon.width + "x" + tabRoot.activeMon.height + "@" + Math.round(tabRoot.activeMon.refreshRate || 60);
                            resList.push({
                                "label": qsTr("Native"),
                                "mode": nativeMode,
                                "desc": tabRoot.activeMon.width + "x" + tabRoot.activeMon.height
                            });
                        }
                        resList.push({
                            "label": qsTr("Preferred"),
                            "mode": "preferred",
                            "desc": qsTr("Auto")
                        });
                        resList.push({
                            "label": "1080p",
                            "mode": "1920x1080@60",
                            "desc": "1920x1080"
                        });
                        resList.push({
                            "label": "1440p",
                            "mode": "2560x1440@60",
                            "desc": "2560x1440"
                        });
                        resList.push({
                            "label": "4K UHD",
                            "mode": "3840x2160@60",
                            "desc": "3840x2160"
                        });
                        return resList;
                    }

                    Rectangle {
                        id: modeChip

                        required property var modelData
                        readonly property bool isSelected: tabRoot.stagedMode === modelData.mode

                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        radius: 8
                        color: isSelected ? root.color1 : (modeChipH.hovered ? Qt.alpha(root.color1, 0.15) : root.surfaceContainer)

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 1

                            Text {
                                text: modeChip.modelData.label
                                font.family: "Google Sans"
                                font.pixelSize: 10
                                font.bold: true
                                color: modeChip.isSelected ? root.foreground : root.textColor
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: modeChip.modelData.desc
                                font.family: "Google Sans"
                                font.pixelSize: 8
                                color: modeChip.isSelected ? Qt.alpha(root.foreground, 0.75) : root.textMuted
                                Layout.alignment: Qt.AlignHCenter
                            }

                        }

                        HoverHandler {
                            id: modeChipH
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                tabRoot.applyPropertyChange(modeChip.modelData.mode, tabRoot.stagedPosition, tabRoot.stagedScale, tabRoot.stagedTransform, tabRoot.stagedVrr);
                            }
                        }

                    }

                }

            }

        }

    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 88
        radius: 14
        color: root.surface
        visible: tabRoot.activeMon !== null

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: qsTr("Orientation & Rotation:")
                    font.family: "Google Sans"
                    font.pixelSize: 11
                    font.bold: true
                    color: root.textColor
                    Layout.fillWidth: true
                }

            }

            RowLayout {
                spacing: 8
                Layout.fillWidth: true

                Repeater {
                    model: [{
                        "label": qsTr("Standard (0°)"),
                        "icon": "crop_landscape",
                        "val": 0
                    }, {
                        "label": qsTr("Portrait (90°)"),
                        "icon": "crop_portrait",
                        "val": 1
                    }, {
                        "label": qsTr("Inverted (180°)"),
                        "icon": "crop_landscape",
                        "val": 2
                    }, {
                        "label": qsTr("Portrait Inv (270°)"),
                        "icon": "crop_portrait",
                        "val": 3
                    }]

                    Rectangle {
                        id: rotChip

                        required property var modelData
                        readonly property bool isSelected: tabRoot.stagedTransform === modelData.val

                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        radius: 8
                        color: isSelected ? root.color1 : (rotH.hovered ? Qt.alpha(root.color1, 0.15) : root.surfaceContainer)

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: rotChip.modelData.icon
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 15
                                color: rotChip.isSelected ? root.foreground : root.color1
                            }

                            Text {
                                text: rotChip.modelData.label
                                font.family: "Google Sans"
                                font.pixelSize: 9
                                font.bold: true
                                color: rotChip.isSelected ? root.foreground : root.textColor
                            }

                        }

                        HoverHandler {
                            id: rotH
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                tabRoot.applyPropertyChange(tabRoot.stagedMode, tabRoot.stagedPosition, tabRoot.stagedScale, rotChip.modelData.val, tabRoot.stagedVrr);
                            }
                        }

                    }

                }

            }

        }

    }

    SettingCard {
        visible: tabRoot.activeMon !== null

        SettingToggle {
            title: qsTr("Variable Refresh Rate (VRR / Adaptive Sync)")
            description: qsTr("Reduces tearing and optimizes display frame pacing")
            checked: tabRoot.stagedVrr
            onToggled: (newState) => {
                tabRoot.applyPropertyChange(tabRoot.stagedMode, tabRoot.stagedPosition, tabRoot.stagedScale, tabRoot.stagedTransform, newState);
            }
        }
    }

}
