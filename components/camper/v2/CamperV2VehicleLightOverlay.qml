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

    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        if (insideOn)
            glow(ctx, width * (rightView ? .39 : .69), height * .49, width * .16, 1, .75, .36, .20 + insideLevel / 180);

        if (sideOn) {
            const firstX = rightView ? .126 : .692;
            const secondX = rightView ? .281 : .843;
            glow(ctx, width * firstX, height * .12, width * (.032 + sideLevel / 3000), .92, .98, 1, .40 + sideLevel / 145);
            glow(ctx, width * secondX, height * .11, width * (.032 + sideLevel / 3000), .92, .98, 1, .40 + sideLevel / 145);
        }

        if (rearOn)
            glow(ctx, width * (rightView ? .087 : .791), height * .055, width * (.035 + rearLevel / 3000), .92, .98, 1, .42 + rearLevel / 140);

        const frontX1 = width * (rightView ? .457 : .281);
        const frontX2 = width * (rightView ? .753 : .596);
        const frontY = height * (rightView ? .095 : .132);
        if (highBeamOn) {
            ctx.save();
            ctx.lineCap = "round";
            ctx.lineWidth = 9;
            ctx.strokeStyle = "rgba(108,198,255,.95)";
            ctx.shadowColor = "#49aef4";
            ctx.shadowBlur = 22;
            ctx.beginPath();
            ctx.moveTo(frontX1, frontY);
            ctx.lineTo(frontX2, frontY);
            ctx.stroke();
            ctx.restore();
        }
        if (frontOn && (!frontAmber || blinkVisible)) {
            ctx.save();
            ctx.lineCap = "round";
            ctx.lineWidth = 3;
            ctx.strokeStyle = frontAmber ? "rgba(255,143,18,.95)" : "rgba(250,253,255,.95)";
            ctx.shadowColor = frontAmber ? "#ff8f12" : "#ffffff";
            ctx.shadowBlur = 7 + frontLevel / 9;
            ctx.beginPath();
            ctx.moveTo(frontX1, frontY + 2);
            ctx.lineTo(frontX2, frontY + 2);
            ctx.stroke();
            ctx.restore();
        }
    }
}
