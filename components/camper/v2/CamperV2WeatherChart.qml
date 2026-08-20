import QtQuick

Item {
    id: root
    objectName: "camperV2WeatherChart"

    property var hourlyData: []
    property var tideData: []
    property bool dayMode: false
    readonly property var tidePoints: normalizedTideData()
    readonly property int validTidePointCount: tidePoints.length
    readonly property bool hasTideCurve: validTidePointCount >= 2
    readonly property color tideColor: dayMode ? "#008da3" : "#63e6f2"

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

    function normalizedTideData() {
        if (!Array.isArray(tideData) || tideData.length < 2 || tideData.length > 27)
            return [];
        const points = [];
        let previousTime = Number.NEGATIVE_INFINITY;
        for (let index = 0; index < tideData.length; ++index) {
            const item = tideData[index];
            if (!item || !item.t || !valid(item.heightM))
                return [];
            const time = new Date(item.t).getTime();
            const height = Number(item.heightM);
            if (!isFinite(time) || time <= previousTime)
                return [];
            points.push({
                time: time,
                height: height
            });
            previousTime = time;
        }
        return points;
    }

    onHourlyDataChanged: chart.requestPaint()
    onTideDataChanged: chart.requestPaint()
    onDayModeChanged: chart.requestPaint()

    Canvas {
        id: chart
        objectName: "camperV2WeatherChartCanvas"
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
            // Keep both Y scales inside the canvas. 43 px is wide enough for
            // negative two-digit temperatures such as "-12 °C" without
            // clipping on the Ford/GX 800x480 renderers.
            const left = 43;
            const right = root.hasTideCurve ? 43 : 13;
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

            const firstWeatherTime = new Date(values[0].t).getTime();
            if (!isFinite(firstWeatherTime)) {
                ctx.font = "11px sans-serif";
                ctx.fillText("Ungültige Wetterzeit", left + 12, top + chartHeight / 2);
                return;
            }
            // The Cerbo publishes two explicit Tide boundary samples for
            // exactly now..+24 h. Anchor the shared chart to that first sample
            // when available so a rounded DWD hourly timestamp cannot clip a
            // Tide endpoint. Temperature and rain still use their real times.
            const firstTideTime = root.hasTideCurve ? root.tidePoints[0].time : Number.NaN;
            const chartStartTime = isFinite(firstTideTime) ? firstTideTime : firstWeatherTime;
            const chartEndTime = chartStartTime + 24 * 60 * 60 * 1000;
            const chartDuration = chartEndTime - chartStartTime;
            function weatherTime(item, index) {
                const parsed = new Date(item && item.t).getTime();
                return isFinite(parsed) ? parsed : chartStartTime + index * 60 * 60 * 1000;
            }
            function chartX(time) {
                return left + Math.max(0, Math.min(1, (time - chartStartTime) / chartDuration)) * chartWidth;
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

            const hourWidth = chartWidth / 24;
            ctx.save();
            ctx.globalAlpha = root.dayMode ? .5 : .38;
            ctx.fillStyle = style.blue;
            for (let index = 0; index < count; ++index) {
                const probability = root.rain(values[index]);
                const barHeight = chartHeight * .38 * probability / 100;
                const x = chartX(weatherTime(values[index], index));
                ctx.fillRect(x - Math.max(1, hourWidth * .25), top + chartHeight - barHeight, Math.max(2, hourWidth * .5), barHeight);
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
                const x = chartX(weatherTime(values[index], index));
                const y = top + (maximum - value) / (maximum - minimum) * chartHeight * .72;
                if (!started) {
                    ctx.moveTo(x, y);
                    started = true;
                } else {
                    ctx.lineTo(x, y);
                }
            }
            ctx.stroke();

            const tideValues = root.tidePoints.filter(point => point.time >= chartStartTime && point.time <= chartEndTime);
            if (tideValues.length >= 2) {
                let tideMinimum = Number.POSITIVE_INFINITY;
                let tideMaximum = Number.NEGATIVE_INFINITY;
                for (let index = 0; index < tideValues.length; ++index) {
                    tideMinimum = Math.min(tideMinimum, tideValues[index].height);
                    tideMaximum = Math.max(tideMaximum, tideValues[index].height);
                }
                if (tideMaximum - tideMinimum < .1) {
                    tideMaximum += .05;
                    tideMinimum -= .05;
                }
                ctx.strokeStyle = root.tideColor;
                ctx.lineWidth = 1.8;
                ctx.beginPath();
                for (let index = 0; index < tideValues.length; ++index) {
                    const point = tideValues[index];
                    const x = chartX(point.time);
                    const y = top + (tideMaximum - point.height) / (tideMaximum - tideMinimum) * chartHeight * .72;
                    if (index === 0)
                        ctx.moveTo(x, y);
                    else
                        ctx.lineTo(x, y);
                }
                ctx.stroke();
                ctx.fillStyle = root.tideColor;
                ctx.font = "7px sans-serif";
                ctx.fillText(tideMaximum.toFixed(1).replace(".", ",") + " m", width - right + 3, top + 7);
                ctx.fillText(tideMinimum.toFixed(1).replace(".", ",") + " m", width - right + 3, top + chartHeight * .72 + 2);
            }

            ctx.fillStyle = style.muted;
            ctx.font = "8px sans-serif";
            for (let hours = 0; hours <= 24; hours += 6) {
                const labelTime = new Date(chartStartTime + hours * 60 * 60 * 1000);
                const x = left + hours / 24 * chartWidth;
                ctx.fillText(Qt.formatTime(labelTime, "hh:mm"), Math.max(1, Math.min(width - 27, x - 12)), height - 7);
            }
            ctx.fillStyle = style.orange;
            ctx.fillText(Math.ceil(maximum) + " °C", 3, top + 7);
            ctx.fillText(Math.floor(minimum) + " °C", 3, top + chartHeight * .72 + 2);
        }
    }
}
