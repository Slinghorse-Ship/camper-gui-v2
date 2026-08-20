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
    readonly property var tides: weather.tides && typeof weather.tides === "object" ? weather.tides : ({})

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
            const code = Math.round(Number(rawCode));
            const descriptions = {
                0: "Klar",
                1: "Auflockernd",
                2: "Bewölkt",
                3: "Zunehmend bewölkt",
                45: "Nebel",
                49: "Eisnebel",
                51: "Leichter Sprühregen",
                53: "Sprühregen",
                55: "Starker Sprühregen",
                56: "Leicht gefrierender Sprühregen",
                57: "Gefrierender Sprühregen",
                61: "Leichter Regen",
                63: "Regen",
                65: "Starker Regen",
                66: "Leicht gefrierender Regen",
                67: "Gefrierender Regen",
                68: "Leichter Schneeregen",
                69: "Schneeregen",
                71: "Leichter Schneefall",
                73: "Schneefall",
                75: "Starker Schneefall",
                80: "Leichter Regenschauer",
                81: "Regenschauer",
                82: "Heftiger Regenschauer",
                83: "Leichter Schneeregenschauer",
                84: "Schneeregenschauer",
                85: "Leichter Schneeschauer",
                86: "Schneeschauer",
                95: "Gewitter mit Regen oder Schnee",
                96: "Hagelgewitter",
                97: "Starkes Gewitter",
                98: "Gewitter",
                99: "Starkes Hagelgewitter"
            };
            if (descriptions[code])
                return descriptions[code];
        }
        const icon = String(value(item, ["icon"]) || "").toLowerCase();
        if (icon.indexOf("hail") >= 0)
            return "Hagelgewitter";
        if (icon.indexOf("thunder") >= 0 || icon.indexOf("storm") >= 0)
            return "Gewitter";
        if (icon.indexOf("freezing") >= 0)
            return "Gefrierender Niederschlag";
        if (icon.indexOf("sleet") >= 0 || icon.indexOf("mixed") >= 0)
            return "Schneeregen";
        if (icon.indexOf("snow") >= 0)
            return "Schnee";
        if (icon.indexOf("drizzle") >= 0)
            return "Sprühregen";
        if (icon.indexOf("shower") >= 0)
            return "Regenschauer";
        if (icon.indexOf("rain") >= 0)
            return "Regen";
        if (icon.indexOf("clear") >= 0 || icon.indexOf("sun") >= 0)
            return "Klar";
        if (icon.indexOf("cloud") >= 0 || icon.indexOf("overcast") >= 0)
            return "Bewölkt";
        return "Wetterlage";
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

    function tideEvent(label, event) {
        if (!event || !event.t)
            return "";
        const date = new Date(event.t);
        if (isNaN(date.getTime()))
            return "";
        const height = valid(event.heightM) ? " " + Number(event.heightM).toFixed(2).replace(".", ",") + " m" : "";
        return label + " " + Qt.formatTime(date, "hh:mm") + height;
    }

    function tideLabel() {
        const high = tideEvent("HW", tides.nextHigh);
        const low = tideEvent("NW", tides.nextLow);
        if (!high && !low)
            return "";
        const station = tides.station && tides.station.name ? " · " + String(tides.station.name) : "";
        const stale = tides.stale === true ? " · veraltet" : "";
        return "BSH Tide " + [high, low].filter(value => value.length > 0).join(" · ") + station + stale;
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
            x: parent.width - width - 13
            y: 12
            spacing: 8
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
            Rectangle {
                visible: weatherChart.hasTideCurve
                width: 19
                height: 2
                radius: 1
                color: weatherChart.tideColor
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                objectName: "camperV2WeatherTideLegend"
                visible: weatherChart.hasTideCurve
                text: "Tide"
                color: style.muted
                font.pixelSize: 8
            }
        }
        CamperV2WeatherChart {
            id: weatherChart
            x: 8
            y: 32
            width: parent.width - 16
            height: 135
            hourlyData: root.hourly
            tideData: root.tides.curve && Array.isArray(root.tides.curve) ? root.tides.curve : []
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
        objectName: "camperV2WeatherSunTide"
        x: 2
        y: root.height - 39
        width: root.width - 4
        height: 17
        visible: root.sunLabel().length > 0 || root.tideLabel().length > 0
        text: [root.sunLabel(), root.tideLabel()].filter(value => value.length > 0).join("   ·   ")
        color: root.tides.stale === true ? style.orange : style.muted
        elide: Text.ElideRight
        font.pixelSize: 9
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
            const stale = root.weather.stale === true ? " · Daten veraltet" : "";
            return "Quelle: Deutscher Wetterdienst" + station + updated + stale;
        }
        color: root.adapter.weatherConnected === true && root.weather.stale !== true ? style.muted : style.orange
        elide: Text.ElideRight
        font.pixelSize: 9
    }
}
