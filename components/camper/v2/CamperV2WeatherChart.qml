import QtQuick

Item {
    id: root

    property var hourlyData: []
    property bool dayMode: false

    CamperV2Style {
        id: style
        dayMode: root.dayMode
    }

    function valid(value) {
        return value !== null && value !== undefined && value !== "" && isFinite(Number(value));
    }

    function temperature(item) {
        if (!item)
            return null;
        const value = item.tempC !== undefined ? item.tempC : item.temperature;
        return valid(value) ? Number(value) : null;
    }

    function rain(item) {
        if (!item)
            return 0;
        const value = item.precipProbabilityPct;
        return valid(value) ? Math.max(0, Math.min(100, Number(value))) : 0;
    }

    function hourLabel(item) {
        if (!item)
            return "";
        if (item.time && String(item.time).length <= 5)
            return String(item.time);
        const raw = item.t;
        const date = new Date(raw);
        return isNaN(date.getTime()) ? "" : Qt.formatTime(date, "hh:mm");
    }

    onHourlyDataChanged: chart.requestPaint()
    onDayModeChanged: chart.requestPaint()

    Canvas {
        id: chart
        objectName: "camperV2WeatherChart"
        anchors.fill: parent
        renderTarget: Canvas.FramebufferObject

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, width, height);

            const values = root.hourlyData || [];
            const count = Math.min(24, values.length);
            const left = 31;
            const right = 13;
            const top = 12;
            const bottom = 25;
            const chartWidth = Math.max(1, width - left - right);
            const chartHeight = Math.max(1, height - top - bottom);

            ctx.lineWidth = 1;
            ctx.strokeStyle = style.border;
            ctx.fillStyle = style.muted;
            ctx.font = "8px sans-serif";
            for (let row = 0; row <= 3; ++row) {
                const y = top + chartHeight * row / 3;
                ctx.beginPath();
                ctx.moveTo(left, y);
                ctx.lineTo(width - right, y);
                ctx.stroke();
            }

            if (count === 0) {
                ctx.font = "11px sans-serif";
                ctx.fillText("Noch keine 24-h-Prognose", left + 12, top + chartHeight / 2);
                return;
            }

            let minimum = Number.POSITIVE_INFINITY;
            let maximum = Number.NEGATIVE_INFINITY;
            for (let index = 0; index < count; ++index) {
                const value = root.temperature(values[index]);
                if (root.valid(value)) {
                    minimum = Math.min(minimum, value);
                    maximum = Math.max(maximum, value);
                }
            }
            if (!isFinite(minimum) || !isFinite(maximum)) {
                minimum = 0;
                maximum = 1;
            }
            if (maximum - minimum < 3) {
                maximum += 1.5;
                minimum -= 1.5;
            }

            const step = count > 1 ? chartWidth / (count - 1) : chartWidth;
            ctx.save();
            ctx.globalAlpha = root.dayMode ? .5 : .38;
            ctx.fillStyle = style.blue;
            for (let index = 0; index < count; ++index) {
                const probability = root.rain(values[index]);
                const barHeight = chartHeight * .38 * probability / 100;
                const x = left + index * step;
                ctx.fillRect(x - Math.max(1, step * .25), top + chartHeight - barHeight, Math.max(2, step * .5), barHeight);
            }
            ctx.restore();

            ctx.strokeStyle = style.orange;
            ctx.lineWidth = 2.4;
            ctx.beginPath();
            let started = false;
            for (let index = 0; index < count; ++index) {
                const value = root.temperature(values[index]);
                if (!root.valid(value))
                    continue;
                const x = left + index * step;
                const y = top + (maximum - value) / (maximum - minimum) * chartHeight * .72;
                if (!started) {
                    ctx.moveTo(x, y);
                    started = true;
                } else {
                    ctx.lineTo(x, y);
                }
            }
            ctx.stroke();

            ctx.fillStyle = style.muted;
            ctx.font = "8px sans-serif";
            for (let index = 0; index < count; index += 4) {
                const x = left + index * step;
                ctx.fillText(root.hourLabel(values[index]), Math.max(1, x - 12), height - 7);
            }
            ctx.fillStyle = style.orange;
            ctx.fillText(Math.round(maximum) + "°", 1, top + 7);
            ctx.fillText(Math.round(minimum) + "°", 1, top + chartHeight * .72 + 2);
        }
    }
}
