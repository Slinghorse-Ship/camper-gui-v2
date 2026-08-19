import QtQuick

Canvas {
    id: overlay

    property bool rightView: false
    property bool insideOn: false
    property real insideLevel: 0
    property bool leftOn: false
    property real leftLevel: 0
    property bool rightOn: false
    property real rightLevel: 0
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
    onLeftOnChanged: requestPaint()
    onLeftLevelChanged: requestPaint()
    onRightOnChanged: requestPaint()
    onRightLevelChanged: requestPaint()
    onRearOnChanged: requestPaint()
    onRearLevelChanged: requestPaint()
    onFrontOnChanged: requestPaint()
    onFrontLevelChanged: requestPaint()
    onFrontAmberChanged: requestPaint()
    onHighBeamOnChanged: requestPaint()
    Component.onCompleted: requestPaint()

    function glow(ctx, x, y, radius, color, strength) {
        const gradient = ctx.createRadialGradient(x, y, 1, x, y, radius);
        gradient.addColorStop(0, color.replace("ALPHA", Math.min(0.95, strength).toFixed(2)));
        gradient.addColorStop(0.35, color.replace("ALPHA", Math.min(0.45, strength * 0.55).toFixed(2)));
        gradient.addColorStop(1, color.replace("ALPHA", "0"));
        ctx.fillStyle = gradient;
        ctx.beginPath();
        ctx.arc(x, y, radius, 0, Math.PI * 2);
        ctx.fill();
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        if (insideOn)
            glow(ctx, rightView ? 180 : 325, 150, 78, "rgba(255,191,93,ALPHA)", 0.18 + insideLevel / 180);

        const fx1 = rightView ? 225 : 142;
        const fx2 = rightView ? 340 : 270;
        const fy = rightView ? 32 : 43;
        if (highBeamOn) {
            ctx.save();
            ctx.lineCap = "round";
            ctx.lineWidth = 10;
            ctx.strokeStyle = "rgba(108,198,255,0.92)";
            ctx.shadowColor = "#49aef4";
            ctx.shadowBlur = 22;
            ctx.beginPath();
            ctx.moveTo(fx1, fy);
            ctx.lineTo(fx2, fy + (rightView ? 4 : 1));
            ctx.stroke();
            ctx.restore();
        }
        if (frontOn && (!frontAmber || blinkVisible)) {
            const frontColor = frontAmber ? "rgba(255,143,18,ALPHA)" : "rgba(250,253,255,ALPHA)";
            ctx.save();
            ctx.lineCap = "round";
            ctx.lineWidth = 2;
            ctx.strokeStyle = frontColor.replace("ALPHA", (0.4 + frontLevel / 170).toFixed(2));
            ctx.shadowColor = frontAmber ? "#ff8f12" : "#ffffff";
            ctx.shadowBlur = 5 + frontLevel / 12;
            ctx.beginPath();
            ctx.moveTo(fx1, fy + 2);
            ctx.lineTo(fx2, fy + 2 + (rightView ? 4 : 1));
            ctx.stroke();
            ctx.restore();
        }
        const sideActive = rightView ? rightOn : leftOn;
        const sideLevel = rightView ? rightLevel : leftLevel;
        if (sideActive) {
            const lamps = rightView ? [[58, 43], [137, 36]] : [[324, 32], [395, 37]];
            for (let index = 0; index < lamps.length; ++index)
                glow(ctx, lamps[index][0], lamps[index][1], 14 + sideLevel / 18, "rgba(235,249,255,ALPHA)", 0.38 + sideLevel / 135);
        }
        if (rearOn)
            glow(ctx, rightView ? 42 : 372, 13, 15 + rearLevel / 18, "rgba(235,249,255,ALPHA)", 0.42 + rearLevel / 130);
    }
}
