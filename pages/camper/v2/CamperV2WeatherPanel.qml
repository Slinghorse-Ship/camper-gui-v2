pragma ComponentBehavior: Bound

import QtQuick
import "../../../components/camper/v2"

Item {
    id: root

    required property var adapter
    property bool dayMode: false

    readonly property var weather: adapter.weatherData || ({})
    readonly property var hourly: weather.hourly && Array.isArray(weather.hourly) ? weather.hourly.slice(0, 48) : []
    readonly property var daily: weather.daily && Array.isArray(weather.daily) ? weather.daily.slice(0, 6) : []
    readonly property var currentWeather: weather.current || currentFromHourly()

    CamperV2Style {
        id: style
        dayMode: root.dayMode
    }

    function valid(value) {
        return value !== null && value !== undefined && value !== "" && isFinite(Number(value));
    }

    function value(item, names) {
        for (let index = 0; index < names.length; ++index) {
            if (item && item[names[index]] !== undefined && item[names[index]] !== null)
                return item[names[index]];
        }
        return null;
    }

    function temperature(item) {
        const result = value(item, ["tempC"]);
        return valid(result) ? Number(result) : null;
    }

    function rain(item) {
        const result = value(item, ["precipProbabilityPct", "maxHourlyPrecipProbabilityPct"]);
        return valid(result) ? Math.max(0, Math.min(100, Number(result))) : null;
    }

    function currentFromHourly() {
        const values = hourly || [];
        if (values.length === 0)
            return ({});
        const now = Date.now();
        for (let index = 0; index < values.length; ++index) {
            const time = new Date(values[index].t).getTime();
            if (!isNaN(time) && time >= now - 3600000)
                return values[index];
        }
        return values[0];
    }

    function weatherDescription(item) {
        if (item && item.condition)
            return String(item.condition);
        const rawCode = value(item, ["ww"]);
        if (valid(rawCode)) {
            const code = Number(rawCode);
            if (code === 0)
                return "Klar";
            if (code <= 3)
                return "Bewölkt";
            if (code === 45 || code === 48)
                return "Nebel";
            if (code >= 95)
                return "Gewitter";
            if (code >= 71 && code <= 86)
                return "Schnee";
            if (code >= 51)
                return "Regen";
        }
        const icon = String(value(item, ["icon"]) || "").toLowerCase();
        if (icon.indexOf("thunder") >= 0 || icon.indexOf("storm") >= 0)
            return "Gewitter";
        if (icon.indexOf("snow") >= 0)
            return "Schnee";
        if (icon.indexOf("rain") >= 0 || icon.indexOf("shower") >= 0)
            return "Regen";
        if (icon.indexOf("clear") >= 0 || icon.indexOf("sun") >= 0)
            return "Klar";
        if (icon.length > 0)
            return "Bewölkt";
        return "Wetter";
    }

    function dayLabel(item) {
        const date = new Date(value(item, ["date"]));
        if (isNaN(date.getTime()))
            return "–";
        return ["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"][date.getDay()];
    }

    function updateLabel() {
        const raw = weather.fetchedAtUtc;
        const date = new Date(raw);
        return isNaN(date.getTime()) ? "" : "Stand " + Qt.formatDateTime(date, "dd.MM. hh:mm");
    }

    function sunLabel() {
        const sun = weather.sun || ({});
        const rise = new Date(sun.riseUtc);
        const set = new Date(sun.setUtc);
        if (isNaN(rise.getTime()) || isNaN(set.getTime()))
            return "";
        return "Sonne ↑" + Qt.formatTime(rise, "hh:mm") + " ↓" + Qt.formatTime(set, "hh:mm");
    }

    CamperV2Card {
        x: 0
        y: 0
        width: 170
        height: 174
        dayMode: root.dayMode

        Rectangle {
            x: 12
            y: 11
            width: 44
            height: 20
            radius: 10
            color: style.selectedBlue
            Text {
                anchors.centerIn: parent
                text: "DWD"
                color: style.blue
                font.pixelSize: 9
                font.weight: Font.Bold
            }
        }
        CamperV2WeatherIcon {
            x: 93
            y: 8
            width: 62
            height: 62
            weatherCode: root.value(root.currentWeather, ["icon", "ww"])
            lineColor: style.text
            sunColor: style.yellow
            rainColor: style.blue
            strokeWidth: 2
        }
        Text {
            x: 13
            y: 42
            width: 83
            text: {
                const number = root.temperature(root.currentWeather);
                return root.valid(number) ? number.toFixed(1) + "°" : "–°";
            }
            color: style.text
            font.pixelSize: 31
            font.weight: Font.DemiBold
        }
        Text {
            x: 13
            y: 88
            width: 144
            text: root.weatherDescription(root.currentWeather)
            color: style.text
            elide: Text.ElideRight
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }
        Text {
            x: 13
            y: 113
            width: 144
            text: {
                const probability = root.rain(root.currentWeather);
                return "Regen " + (root.valid(probability) ? Math.round(probability) + " %" : "–");
            }
            color: style.blue
            font.pixelSize: 9
        }
        Text {
            x: 13
            y: 134
            width: 144
            text: {
                const wind = root.value(root.currentWeather, ["windKmh"]);
                return "Wind " + (root.valid(wind) ? Math.round(Number(wind)) + " km/h" : "–");
            }
            color: style.muted
            font.pixelSize: 9
        }
    }

    CamperV2Card {
        x: 180
        y: 0
        width: root.width - 180
        height: 174
        dayMode: root.dayMode

        Text {
            x: 13
            y: 10
            text: "Nächste 24 Stunden"
            color: style.text
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }
        Row {
            x: parent.width - 153
            y: 12
            spacing: 12
            Rectangle {
                width: 19
                height: 3
                radius: 2
                color: style.orange
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: "Temperatur"
                color: style.muted
                font.pixelSize: 8
            }
            Rectangle {
                width: 13
                height: 8
                radius: 2
                color: style.blue
                opacity: .55
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: "Regen"
                color: style.muted
                font.pixelSize: 8
            }
        }
        CamperV2WeatherChart {
            x: 8
            y: 32
            width: parent.width - 16
            height: 135
            hourlyData: root.hourly
            dayMode: root.dayMode
        }
    }

    CamperV2Card {
        x: 0
        y: 184
        width: root.width
        height: 174
        dayMode: root.dayMode

        Text {
            x: 13
            y: 10
            text: "6-Tage-Vorschau"
            color: style.text
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        Row {
            x: 9
            y: 34
            spacing: 7

            Repeater {
                model: (root.daily || []).slice(0, 6)

                delegate: Rectangle {
                    required property var modelData
                    readonly property var minimum: {
                        const number = root.value(modelData, ["minC"]);
                        return root.valid(number) ? Number(number) : null;
                    }
                    readonly property var maximum: {
                        const number = root.value(modelData, ["maxC"]);
                        return root.valid(number) ? Number(number) : null;
                    }

                    width: (root.width - 53) / 6
                    height: 126
                    radius: 12
                    color: style.inner
                    border.color: style.border

                    Text {
                        x: 0
                        y: 8
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: root.dayLabel(parent.modelData)
                        color: style.text
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                    CamperV2WeatherIcon {
                        x: (parent.width - 42) / 2
                        y: 29
                        width: 42
                        height: 42
                        weatherCode: root.value(parent.modelData, ["icon", "ww"])
                        lineColor: style.text
                        sunColor: style.yellow
                        rainColor: style.blue
                        strokeWidth: 1.6
                    }
                    Text {
                        x: 0
                        y: 75
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: (root.valid(parent.minimum) ? Math.round(parent.minimum) + "°" : "–") + "  " + (root.valid(parent.maximum) ? Math.round(parent.maximum) + "°" : "–")
                        color: style.text
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                    Text {
                        x: 0
                        y: 99
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: {
                            const probability = root.rain(parent.modelData);
                            return root.valid(probability) ? Math.round(probability) + " %" : "–";
                        }
                        color: style.blue
                        font.pixelSize: 9
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: root.daily.length === 0
            text: "Noch keine Tagesprognose"
            color: style.muted
            font.pixelSize: 11
        }
    }

    Text {
        x: 2
        y: root.height - 19
        width: root.width - 4
        text: {
            if (root.adapter.weatherConnected !== true)
                return root.adapter.weatherErrorText || "Wetterdaten noch nicht verfügbar";
            const station = root.weather.station && root.weather.station.name ? " · " + root.weather.station.name : "";
            const updated = root.updateLabel() ? " · " + root.updateLabel() : "";
            const sun = root.sunLabel() ? " · " + root.sunLabel() : "";
            const stale = root.weather.stale === true ? " · Daten veraltet" : "";
            return "Quelle: Deutscher Wetterdienst" + station + updated + sun + stale;
        }
        color: root.adapter.weatherConnected === true && root.weather.stale !== true ? style.muted : style.orange
        elide: Text.ElideRight
        font.pixelSize: 9
    }
}
