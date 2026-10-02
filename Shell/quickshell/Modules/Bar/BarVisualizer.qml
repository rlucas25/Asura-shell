import QtQuick
import qs.Asura
import qs.Services

Item {
    id: root

    // Bar Audio Visualizer configuration properties
    property bool enabled: (Config.cfg && Config.cfg.barVisualizerEnabled !== undefined)
        ? Config.cfg.barVisualizerEnabled : true
    property string visualizerType: (Config.cfg && Config.cfg.barVisualizerType)
        ? Config.cfg.barVisualizerType : "bars"
    property real heightRatio: (Config.cfg && Config.cfg.barVisualizerHeight !== undefined)
        ? Config.cfg.barVisualizerHeight : 0.75
    property real spectrumOpacity: (Config.cfg && Config.cfg.barVisualizerOpacity !== undefined)
        ? Config.cfg.barVisualizerOpacity : 0.45
    property string barsOrigin: (Config.cfg && Config.cfg.barVisualizerBarsOrigin)
        ? Config.cfg.barVisualizerBarsOrigin : "bottom"
    property int density: (Config.cfg && Config.cfg.barVisualizerDensity)
        ? Config.cfg.barVisualizerDensity : 10
    property int gap: (Config.cfg && Config.cfg.barVisualizerGap !== undefined)
        ? Config.cfg.barVisualizerGap : 2
    property int smoothing: (Config.cfg && Config.cfg.barVisualizerSmoothing !== undefined)
        ? Config.cfg.barVisualizerSmoothing : 2
    property real barRadius: 0

    property color primaryColor: Colors.cfg.primary
    property color secondaryColor: Colors.cfg.secondary

    readonly property bool isPlaying: PlayerService.isPlaying
    readonly property bool active: root.enabled && (root.isPlaying || decayTimer.running)
    readonly property var points: CavaService.bars || []

    property bool _consumerRegistered: false
    property var _smoothedValues: []

    opacity: root.active ? root.spectrumOpacity : 0

    Behavior on opacity {
        NumberAnimation {
            duration: 320
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        id: decayTimer
        interval: 1400
        repeat: false
        onTriggered: {
            root._smoothedValues = [];
            if (canvas.available) canvas.requestPaint();
        }
    }

    onIsPlayingChanged: {
        if (root.isPlaying) {
            decayTimer.stop();
        } else if (root.enabled) {
            decayTimer.restart();
        }
    }

    function _updateConsumerState() {
        if (root.enabled && (root.isPlaying || decayTimer.running)) {
            if (!_consumerRegistered) {
                CavaService.registerConsumer();
                _consumerRegistered = true;
            }
        } else {
            if (_consumerRegistered) {
                CavaService.unregisterConsumer();
                _consumerRegistered = false;
            }
        }
    }

    onActiveChanged: {
        _updateConsumerState();
        if (!root.active) {
            root._smoothedValues = [];
            if (canvas.available) canvas.requestPaint();
        }
    }
    onEnabledChanged: _updateConsumerState()

    Component.onCompleted: _updateConsumerState()
    Component.onDestruction: {
        if (_consumerRegistered) {
            CavaService.unregisterConsumer();
            _consumerRegistered = false;
        }
    }

    Connections {
        target: CavaService
        function onBarsChanged() {
            if (root.active && canvas.available) {
                canvas.requestPaint();
            }
        }
    }

    Canvas {
        id: canvas

        anchors.fill: parent
        renderStrategy: Canvas.Threaded

        // Helper to draw rounded rectangles portably
        function drawRoundedRect(ctx, x, y, w, h, r) {
            if (r <= 0) {
                ctx.rect(x, y, w, h);
                return;
            }
            var rad = Math.min(r, Math.min(w / 2, h / 2));
            ctx.beginPath();
            ctx.moveTo(x + rad, y);
            ctx.lineTo(x + w - rad, y);
            ctx.arcTo(x + w, y, x + w, y + rad, rad);
            ctx.lineTo(x + w, y + h - rad);
            ctx.arcTo(x + w, y + h, x + w - rad, y + h, rad);
            ctx.lineTo(x + rad, y + h);
            ctx.arcTo(x, y + h, x, y + h - rad, rad);
            ctx.lineTo(x, y + rad);
            ctx.arcTo(x, y, x + rad, y, rad);
            ctx.closePath();
        }

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            if (!root.active || width <= 0 || height <= 0 || !root.points || root.points.length === 0)
                return;

            // Clip visualizer within the outer bar capsule radius if specified
            if (root.barRadius > 0) {
                drawRoundedRect(ctx, 0, 0, width, height, root.barRadius);
                ctx.clip();
            }

            var srcRaw = root.points;

            // Maintain temporal smoothing across frames for liquid motion
            if (!root._smoothedValues || root._smoothedValues.length !== srcRaw.length) {
                var initialVals = [];
                for (var initIdx = 0; initIdx < srcRaw.length; initIdx++) {
                    initialVals.push(srcRaw[initIdx] || 0);
                }
                root._smoothedValues = initialVals;
            }

            var smoothLevel = root.smoothing;
            var attackFactor = (smoothLevel === 0) ? 1.0 : (smoothLevel === 1 ? 0.70 : (smoothLevel === 2 ? 0.55 : 0.40));
            var decayFactor  = (smoothLevel === 0) ? 1.0 : (smoothLevel === 1 ? 0.35 : (smoothLevel === 2 ? 0.22 : 0.15));

            var src = [];
            for (var iVal = 0; iVal < srcRaw.length; iVal++) {
                var target = srcRaw[iVal] || 0;
                var current = root._smoothedValues[iVal] || 0;
                var factor = (target >= current) ? attackFactor : decayFactor;
                var smoothed = current + (target - current) * factor;
                root._smoothedValues[iVal] = smoothed;
                src.push(smoothed);
            }

            var grad = ctx.createLinearGradient(0, 0, width, 0);
            grad.addColorStop(0, root.primaryColor);
            grad.addColorStop(1, root.secondaryColor);
            ctx.fillStyle = grad;

            if (root.visualizerType === "wave") {
                // === SMOOTH WAVE VISUALIZER ===
                var step = Math.max(6, root.density);
                var sampleCount = Math.max(8, Math.floor(width / step));
                var wavePoints = [];
                var maxH = height * Math.max(0.1, Math.min(1.0, root.heightRatio));

                for (var s = 0; s < sampleCount; s++) {
                    var x = s * width / Math.max(1, sampleCount - 1);
                    var pIdx = s * (src.length - 1) / Math.max(1, sampleCount - 1);
                    var i0 = Math.floor(pIdx);
                    var i1 = Math.min(src.length - 1, i0 + 1);
                    var frac = pIdx - i0;
                    var raw = (src[i0] || 0) * (1 - frac) + (src[i1] || 0) * frac;
                    var norm = Math.max(0, Math.min(1, raw / 100000));
                    var amp = Math.pow(norm, 0.75);
                    var valH = Math.max(1, amp * maxH);

                    wavePoints.push({ x: x, h: valH });
                }

                // Render filled wave based on origin
                ctx.beginPath();
                if (root.barsOrigin === "top") {
                    ctx.moveTo(0, 0);
                    ctx.lineTo(wavePoints[0].x, wavePoints[0].h);
                    for (var i = 0; i < wavePoints.length - 1; i++) {
                        var midX = (wavePoints[i].x + wavePoints[i + 1].x) / 2;
                        var midY = (wavePoints[i].h + wavePoints[i + 1].h) / 2;
                        ctx.quadraticCurveTo(wavePoints[i].x, wavePoints[i].h, midX, midY);
                    }
                    ctx.lineTo(width, 0);
                    ctx.closePath();
                    ctx.fill();

                    // Wave outline crest
                    ctx.beginPath();
                    ctx.moveTo(wavePoints[0].x, wavePoints[0].h);
                    for (var j = 0; j < wavePoints.length - 1; j++) {
                        var mX = (wavePoints[j].x + wavePoints[j + 1].x) / 2;
                        var mY = (wavePoints[j].h + wavePoints[j + 1].h) / 2;
                        ctx.quadraticCurveTo(wavePoints[j].x, wavePoints[j].h, mX, mY);
                    }
                    ctx.lineWidth = 1.5;
                    ctx.strokeStyle = root.primaryColor;
                    ctx.stroke();

                } else if (root.barsOrigin === "mirror" || root.barsOrigin === "center") {
                    var centerY = height / 2;
                    // Upper half
                    ctx.moveTo(0, centerY);
                    ctx.lineTo(wavePoints[0].x, centerY - wavePoints[0].h / 2);
                    for (var u = 0; u < wavePoints.length - 1; u++) {
                        var uMidX = (wavePoints[u].x + wavePoints[u + 1].x) / 2;
                        var uMidY = centerY - (wavePoints[u].h + wavePoints[u + 1].h) / 4;
                        ctx.quadraticCurveTo(wavePoints[u].x, centerY - wavePoints[u].h / 2, uMidX, uMidY);
                    }
                    ctx.lineTo(width, centerY);

                    // Lower half
                    for (var l = wavePoints.length - 1; l > 0; l--) {
                        var lMidX = (wavePoints[l].x + wavePoints[l - 1].x) / 2;
                        var lMidY = centerY + (wavePoints[l].h + wavePoints[l - 1].h) / 4;
                        ctx.quadraticCurveTo(wavePoints[l].x, centerY + wavePoints[l].h / 2, lMidX, lMidY);
                    }
                    ctx.closePath();
                    ctx.fill();

                } else {
                    // Default: bottom rising wave
                    ctx.moveTo(0, height);
                    ctx.lineTo(wavePoints[0].x, height - wavePoints[0].h);
                    for (var b = 0; b < wavePoints.length - 1; b++) {
                        var bMidX = (wavePoints[b].x + wavePoints[b + 1].x) / 2;
                        var bMidY = height - (wavePoints[b].h + wavePoints[b + 1].h) / 2;
                        ctx.quadraticCurveTo(wavePoints[b].x, height - wavePoints[b].h, bMidX, bMidY);
                    }
                    ctx.lineTo(width, height);
                    ctx.closePath();
                    ctx.fill();

                    // Wave outline crest
                    ctx.beginPath();
                    ctx.moveTo(wavePoints[0].x, height - wavePoints[0].h);
                    for (var k = 0; k < wavePoints.length - 1; k++) {
                        var kmX = (wavePoints[k].x + wavePoints[k + 1].x) / 2;
                        var kmY = height - (wavePoints[k].h + wavePoints[k + 1].h) / 2;
                        ctx.quadraticCurveTo(wavePoints[k].x, height - wavePoints[k].h, kmX, kmY);
                    }
                    ctx.lineWidth = 1.5;
                    ctx.strokeStyle = root.primaryColor;
                    ctx.stroke();
                }

            } else {
                // === BARS VISUALIZER (CAVA EQUALIZER STYLE) ===
                var barGap = Math.max(0, root.gap);
                var barPitch = Math.max(4, root.density);
                var barCount = Math.max(6, Math.floor((width + barGap) / barPitch));
                var barWidth = Math.max(1, (width - (barCount - 1) * barGap) / barCount);
                var maxBarH = height * Math.max(0.1, Math.min(1.0, root.heightRatio));
                var radius = Math.min(2, barWidth / 2);

                for (var barIdx = 0; barIdx < barCount; barIdx++) {
                    var xPos = barIdx * (barWidth + barGap);
                    var sampleIdx = barIdx * (src.length - 1) / Math.max(1, barCount - 1);
                    var idx0 = Math.floor(sampleIdx);
                    var idx1 = Math.min(src.length - 1, idx0 + 1);
                    var subFrac = sampleIdx - idx0;
                    var sampleRaw = (src[idx0] || 0) * (1 - subFrac) + (src[idx1] || 0) * subFrac;
                    var sampleNorm = Math.max(0, Math.min(1, sampleRaw / 100000));
                    var sampleAmp = Math.pow(sampleNorm, 0.8);
                    var curBarH = Math.max(2, sampleAmp * maxBarH);

                    if (root.barsOrigin === "top") {
                        drawRoundedRect(ctx, xPos, 0, barWidth, curBarH, radius);
                        ctx.fill();
                    } else if (root.barsOrigin === "center") {
                        var cY = (height - curBarH) / 2;
                        drawRoundedRect(ctx, xPos, cY, barWidth, curBarH, radius);
                        ctx.fill();
                    } else if (root.barsOrigin === "mirror") {
                        var mHalf = curBarH / 2;
                        var mCenter = height / 2;
                        drawRoundedRect(ctx, xPos, mCenter - mHalf, barWidth, curBarH, radius);
                        ctx.fill();
                    } else {
                        // Default: bottom rising bars
                        drawRoundedRect(ctx, xPos, height - curBarH, barWidth, curBarH, radius);
                        ctx.fill();
                    }
                }
            }
        }
    }
}
