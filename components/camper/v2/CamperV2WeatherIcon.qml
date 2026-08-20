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
            const code = Math.round(numeric);
            if (code === 0)
                return "clear";
            if (code === 1 || code === 2)
                return "partly-cloudy";
            if (code === 3)
                return "cloudy";
            if (code === 45 || code === 49)
                return "fog";
            if (code === 96 || code === 99)
                return "hail";
            if (code === 95 || code === 97 || code === 98)
                return "thunder";
            if (code === 56 || code === 57 || code === 66 || code === 67)
                return "freezing-rain";
            if (code === 68 || code === 69 || code === 83 || code === 84)
                return "sleet";
            if (code === 71 || code === 73 || code === 75 || code === 85 || code === 86)
                return "snow";
            if (code === 51 || code === 53 || code === 55 || code === 61 || code === 63 || code === 65 || code === 80 || code === 81 || code === 82)
                return "rain";
        }
        if (raw.indexOf("hail") >= 0 || raw.indexOf("hagel") >= 0)
            return "hail";
        if (raw.indexOf("thunder") >= 0 || raw.indexOf("gewitter") >= 0)
            return "thunder";
        if (raw.indexOf("freezing") >= 0 || raw.indexOf("gefrier") >= 0 || raw.indexOf("ice-rain") >= 0)
            return "freezing-rain";
        if (raw.indexOf("sleet") >= 0 || raw.indexOf("mixed") >= 0 || raw.indexOf("schneeregen") >= 0)
            return "sleet";
        if (raw.indexOf("snow") >= 0 || raw.indexOf("schnee") >= 0)
            return "snow";
        if (raw.indexOf("rain") >= 0 || raw.indexOf("regen") >= 0 || raw.indexOf("shower") >= 0 || raw.indexOf("drizzle") >= 0 || raw.indexOf("sprüh") >= 0)
            return "rain";
        if (raw.indexOf("fog") >= 0 || raw.indexOf("nebel") >= 0)
            return "fog";
        if (raw.indexOf("partly") >= 0 || raw.indexOf("mostly-clear") >= 0 || raw.indexOf("aufgelockert") >= 0)
            return "partly-cloudy";
        if (raw.indexOf("clear") >= 0 || raw.indexOf("sun") >= 0 || raw.indexOf("klar") >= 0)
            return "clear";
        if (raw.indexOf("cloud") >= 0 || raw.indexOf("overcast") >= 0 || raw.indexOf("bewölkt") >= 0)
            return "cloudy";
        return "unknown";
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
        if (state === "unknown") {
            ctx.strokeStyle = lineColor;
            ctx.beginPath();
            ctx.arc(width * .50, height * .50, width * .30, 0, Math.PI * 2);
            ctx.stroke();
            ctx.fillStyle = lineColor;
            ctx.font = "bold " + Math.max(10, Math.round(width * .46)) + "px sans-serif";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("?", width * .50, height * .50);
            return;
        }
        if (state === "clear") {
            sun(ctx, width * .50, height * .49, width * .17);
            return;
        }
        if (state === "partly-cloudy")
            sun(ctx, width * .68, height * .30, width * .11);
        cloud(ctx);

        if (state === "rain" || state === "freezing-rain" || state === "thunder") {
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
                if (state === "freezing-rain") {
                    line(ctx, width * .42, height * .91, width * .50, height * .91);
                    line(ctx, width * .46, height * .87, width * .46, height * .95);
                }
            }
        } else if (state === "snow" || state === "sleet") {
            ctx.strokeStyle = rainColor;
            for (let index = 0; index < 3; ++index) {
                const cx = width * (.30 + index * .20);
                const cy = height * .82;
                if (state === "sleet" && index !== 1)
                    line(ctx, cx + width * .02, cy - height * .05, cx - width * .03, cy + height * .06);
                else {
                    line(ctx, cx - width * .04, cy, cx + width * .04, cy);
                    line(ctx, cx, cy - height * .04, cx, cy + height * .04);
                }
            }
        } else if (state === "hail") {
            ctx.strokeStyle = rainColor;
            for (let index = 0; index < 3; ++index) {
                ctx.beginPath();
                ctx.arc(width * (.30 + index * .20), height * .83, width * .035, 0, Math.PI * 2);
                ctx.stroke();
            }
        } else if (state === "fog") {
            ctx.strokeStyle = lineColor;
            line(ctx, width * .20, height * .76, width * .80, height * .76);
            line(ctx, width * .28, height * .88, width * .72, height * .88);
        }
    }
}
