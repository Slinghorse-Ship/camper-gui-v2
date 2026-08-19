import QtQuick

Canvas {
    id: root

    property var weatherCode: "cloudy"
    property color lineColor: "#f3f7fa"
    property color sunColor: "#f4c94c"
    property color rainColor: "#59caff"
    property real strokeWidth: 2

    onWeatherCodeChanged: requestPaint()
    onLineColorChanged: requestPaint()
    onSunColorChanged: requestPaint()
    onRainColorChanged: requestPaint()
    onStrokeWidthChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    function category() {
        const raw = String(weatherCode === null || weatherCode === undefined ? "" : weatherCode).toLowerCase();
        const numeric = Number(raw);
        if (raw.length > 0 && isFinite(numeric)) {
            if (numeric === 0)
                return "clear";
            if (numeric <= 3)
                return "cloudy";
            if (numeric === 45 || numeric === 48)
                return "fog";
            if (numeric >= 71 && numeric <= 86)
                return "snow";
            if (numeric >= 95)
                return "thunder";
            if (numeric >= 51)
                return "rain";
        }
        if (raw.indexOf("thunder") >= 0 || raw.indexOf("gewitter") >= 0)
            return "thunder";
        if (raw.indexOf("snow") >= 0 || raw.indexOf("schnee") >= 0)
            return "snow";
        if (raw.indexOf("rain") >= 0 || raw.indexOf("regen") >= 0 || raw.indexOf("shower") >= 0)
            return "rain";
        if (raw.indexOf("fog") >= 0 || raw.indexOf("nebel") >= 0)
            return "fog";
        if (raw.indexOf("clear") >= 0 || raw.indexOf("sun") >= 0 || raw.indexOf("klar") >= 0)
            return "clear";
        return "cloudy";
    }

    function line(ctx, x1, y1, x2, y2) {
        ctx.beginPath();
        ctx.moveTo(x1, y1);
        ctx.lineTo(x2, y2);
        ctx.stroke();
    }

    function sun(ctx, cx, cy, radius) {
        ctx.strokeStyle = sunColor;
        ctx.beginPath();
        ctx.arc(cx, cy, radius, 0, Math.PI * 2);
        ctx.stroke();
        for (let index = 0; index < 8; ++index) {
            const angle = index * Math.PI / 4;
            line(ctx, cx + Math.cos(angle) * radius * 1.45, cy + Math.sin(angle) * radius * 1.45, cx + Math.cos(angle) * radius * 2.05, cy + Math.sin(angle) * radius * 2.05);
        }
    }

    function cloud(ctx) {
        ctx.strokeStyle = lineColor;
        ctx.beginPath();
        ctx.moveTo(width * .19, height * .64);
        ctx.bezierCurveTo(width * .08, height * .61, width * .09, height * .43, width * .24, height * .41);
        ctx.bezierCurveTo(width * .28, height * .22, width * .54, height * .18, width * .64, height * .36);
        ctx.bezierCurveTo(width * .84, height * .34, width * .92, height * .58, width * .78, height * .67);
        ctx.lineTo(width * .22, height * .67);
        ctx.stroke();
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.clearRect(0, 0, width, height);
        ctx.lineWidth = strokeWidth;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";

        const state = category();
        if (state === "clear") {
            sun(ctx, width * .50, height * .49, width * .17);
            return;
        }
        if (state !== "fog")
            sun(ctx, width * .68, height * .30, width * .11);
        cloud(ctx);

        if (state === "rain" || state === "thunder") {
            ctx.strokeStyle = state === "thunder" ? sunColor : rainColor;
            if (state === "thunder") {
                ctx.beginPath();
                ctx.moveTo(width * .52, height * .69);
                ctx.lineTo(width * .42, height * .84);
                ctx.lineTo(width * .53, height * .84);
                ctx.lineTo(width * .45, height * .96);
                ctx.stroke();
            } else {
                line(ctx, width * .30, height * .75, width * .25, height * .88);
                line(ctx, width * .50, height * .75, width * .45, height * .88);
                line(ctx, width * .70, height * .75, width * .65, height * .88);
            }
        } else if (state === "snow") {
            ctx.strokeStyle = rainColor;
            for (let index = 0; index < 3; ++index) {
                const cx = width * (.30 + index * .20);
                const cy = height * .82;
                line(ctx, cx - width * .04, cy, cx + width * .04, cy);
                line(ctx, cx, cy - height * .04, cx, cy + height * .04);
            }
        } else if (state === "fog") {
            ctx.strokeStyle = lineColor;
            line(ctx, width * .20, height * .76, width * .80, height * .76);
            line(ctx, width * .28, height * .88, width * .72, height * .88);
        }
    }
}
