import QtQuick

Canvas {
    id: overlay

    property bool rightView: false
    property bool insideOn: false
    property real insideLevel: 0
    property bool sideOn: false
    property real sideLevel: 0
    property bool rearOn: false
    property real rearLevel: 0
    property bool frontOn: false
    property real frontLevel: 0
    property bool frontAmber: false
    property bool highBeamOn: false
    property bool blinkVisible: true

    Timer {
        interval: 500
        repeat: true
        running: overlay.frontOn && overlay.frontAmber
        onTriggered: {
            overlay.blinkVisible = !overlay.blinkVisible;
            overlay.requestPaint();
        }
        onRunningChanged: {
            if (!running) {
                overlay.blinkVisible = true;
                overlay.requestPaint();
            }
        }
    }

    onRightViewChanged: requestPaint()
    onInsideOnChanged: requestPaint()
    onInsideLevelChanged: requestPaint()
    onSideOnChanged: requestPaint()
    onSideLevelChanged: requestPaint()
    onRearOnChanged: requestPaint()
    onRearLevelChanged: requestPaint()
    onFrontOnChanged: requestPaint()
    onFrontLevelChanged: requestPaint()
    onFrontAmberChanged: requestPaint()
    onHighBeamOnChanged: requestPaint()

    function glow(ctx, x, y, radius, red, green, blue, strength) {
        const gradient = ctx.createRadialGradient(x, y, 1, x, y, radius);
        gradient.addColorStop(0, Qt.rgba(red, green, blue, Math.min(.95, strength)));
        gradient.addColorStop(.35, Qt.rgba(red, green, blue, Math.min(.45, strength * .55)));
        gradient.addColorStop(1, Qt.rgba(red, green, blue, 0));
        ctx.fillStyle = gradient;
        ctx.beginPath();
        ctx.arc(x, y, radius, 0, Math.PI * 2);
        ctx.fill();
    }

    function sourceX(value) {
        return width * value / 560;
    }

    function sourceY(value) {
        return height * value / 360;
    }

    function fixtureLine(ctx, x1, x2, y, sourceWidth, red, green, blue, strength) {
        const centerX = sourceX((x1 + x2) / 2);
        const centerY = sourceY(y);
        glow(ctx, centerX, centerY, sourceX(18), red, green, blue, strength * .46);
        ctx.save();
        ctx.lineCap = "round";
        ctx.lineWidth = Math.max(2, sourceY(sourceWidth));
        ctx.strokeStyle = Qt.rgba(red, green, blue, Math.min(.98, strength));
        ctx.shadowColor = Qt.rgba(red, green, blue, .92);
        ctx.shadowBlur = sourceX(8);
        ctx.beginPath();
        ctx.moveTo(sourceX(x1), centerY);
        ctx.lineTo(sourceX(x2), centerY);
        ctx.stroke();
        ctx.restore();
    }

    function fixtureSquare(ctx, x, y, size, red, green, blue, strength) {
        const centerX = sourceX(x);
        const centerY = sourceY(y);
        const side = Math.max(3, sourceX(size));
        glow(ctx, centerX, centerY, sourceX(19), red, green, blue, strength * .5);
        ctx.save();
        ctx.fillStyle = Qt.rgba(red, green, blue, Math.min(.98, strength));
        ctx.shadowColor = Qt.rgba(red, green, blue, .94);
        ctx.shadowBlur = sourceX(9);
        ctx.fillRect(centerX - side / 2, centerY - side / 2, side, side);
        ctx.restore();
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        if (insideOn)
            glow(ctx, sourceX(rightView ? 165 : 420), sourceY(170), sourceX(90), 1, .75, .36, .20 + insideLevel / 180);

        if (sideOn) {
            const strength = .52 + sideLevel / 220;
            if (rightView) {
                fixtureLine(ctx, 65, 73, 45, 5, .92, .98, 1, strength);
                fixtureLine(ctx, 154, 162, 41, 5, .92, .98, 1, strength);
            } else {
                fixtureLine(ctx, 374, 383, 33, 5, .92, .98, 1, strength);
                fixtureLine(ctx, 458, 466, 36, 5, .92, .98, 1, strength);
            }
        }

        if (rearOn)
            fixtureSquare(ctx, rightView ? 52 : 437, 12, 7, .92, .98, 1, .56 + rearLevel / 210);

        const frontX1 = sourceX(rightView ? 260 : 166);
        const frontX2 = sourceX(rightView ? 407 : 339);
        const frontY = sourceY(rightView ? 39 : 50);
        if (highBeamOn) {
            ctx.save();
            ctx.lineCap = "round";
            ctx.lineWidth = Math.max(5, sourceY(8));
            ctx.strokeStyle = "rgba(108,198,255,.95)";
            ctx.shadowColor = "#49aef4";
            ctx.shadowBlur = sourceX(24);
            ctx.beginPath();
            ctx.moveTo(frontX1, frontY);
            ctx.lineTo(frontX2, frontY);
            ctx.stroke();
            ctx.restore();
        }
        if (frontOn && (!frontAmber || blinkVisible)) {
            ctx.save();
            ctx.lineCap = "round";
            ctx.lineWidth = Math.max(2, sourceY(3));
            ctx.strokeStyle = frontAmber ? "rgba(255,143,18,.95)" : "rgba(250,253,255,.95)";
            ctx.shadowColor = frontAmber ? "#ff8f12" : "#ffffff";
            ctx.shadowBlur = sourceX(8 + frontLevel / 10);
            ctx.beginPath();
            ctx.moveTo(frontX1, frontY + sourceY(2));
            ctx.lineTo(frontX2, frontY + sourceY(2));
            ctx.stroke();
            ctx.restore();
        }
    }
}
