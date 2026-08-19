import QtQuick
import "../../components/camper"

Item {
    id: view

    required property var adapter
    property bool dayMode: false
    property var climate: ({})
    readonly property var heater: climate.heater || ({})
    signal backRequested

    readonly property color panelColor: visual.panel
    readonly property color primaryText: visual.text
    readonly property color secondaryText: visual.muted
    readonly property color lineColor: visual.border

    CamperStyle {
        id: visual
        dayMode: view.dayMode
    }

    function formatted(value, digits, suffix) {
        if (value === null || value === undefined || value === "" || !isFinite(Number(value)))
            return "–";
        return Number(value).toFixed(digits) + (suffix || "");
    }

    function timeText(timestamp) {
        if (!timestamp)
            return "–";
        return new Date(Number(timestamp)).toLocaleString(Qt.locale("de_DE"), "dd.MM. hh:mm");
    }

    function heaterSetting(key, value) {
        adapter.command("heater", "setting", value, {
            key: key
        });
    }

    function nextValue(current, values) {
        const index = values.indexOf(current);
        return values[(index + 1) % values.length];
    }

    function heaterModeText(value) {
        if (value === "power")
            return "LEISTUNG";
        if (value === "ventilation")
            return "LÜFTEN";
        return "TEMPERATUR";
    }

    function sensorText(value) {
        if (value === "internal")
            return "AUTOTERM INTERN";
        if (value === "external")
            return "AUTOTERM EXTERN";
        if (value === "ruuvi1")
            return "RUUVI DECKE";
        if (value === "ruuvi2")
            return "RUUVI BODEN";
        if (value === "ruuvi3")
            return "KOMFORTMITTEL";
        return "KOMFORTMITTEL";
    }
    Rectangle {
        x: 10
        y: 8
        width: 780
        height: 52
        radius: 10
        color: heater.cooling ? (view.dayMode ? "#eee7ff" : "#35284b") : heater.on ? (view.dayMode ? "#fff0df" : "#3b2916") : view.panelColor
        border.color: heater.cooling ? "#8b61dc" : heater.on ? "#dc7429" : view.lineColor
        CamperTouchButton {
            x: 7
            y: 8
            width: 72
            height: 36
            label: "ZURÜCK"
            onClicked: view.backRequested()
        }
        Text {
            x: 92
            y: 7
            text: "AUTOTERM AIR 2D"
            color: view.primaryText
            font.pixelSize: 15
            font.bold: true
        }
        Text {
            x: 92
            y: 28
            width: 310
            elide: Text.ElideRight
            text: heater.warning || heater.startBlocked || heater.status || "Keine Daten"
            color: heater.warning || heater.startBlocked ? "#f5c451" : "#aeb9c5"
            font.pixelSize: 9
        }
        Rectangle {
            x: 455
            y: 21
            width: 9
            height: 9
            radius: 5
            color: heater.online ? "#32d4a0" : "#e05e68"
        }
        Text {
            x: 473
            y: 18
            text: heater.online ? view.heaterModeText(heater.mode) : "KEINE SERIELLE VERBINDUNG"
            color: heater.online ? "#32d4a0" : "#e05e68"
            font.pixelSize: 9
            font.bold: true
        }
        CamperTouchButton {
            x: 630
            y: 8
            width: 140
            height: 36
            label: heater.cooling ? "NACHLAUF" : (heater.on ? "STOPPEN" : "STARTEN")
            active: heater.on === true
            enabled: heater.cooling !== true && (heater.on === true || !heater.startBlocked)
            accentColor: "#f39b58"
            onClicked: view.adapter.command("heater", heater.on ? "stop" : "start", null)
        }
    }

    Rectangle {
        x: 10
        y: 68
        width: 382
        height: 156
        radius: 10
        color: view.panelColor
        border.color: view.lineColor
        Text {
            x: 12
            y: 9
            text: "BETRIEBSART"
            color: view.secondaryText
            font.pixelSize: 9
            font.bold: true
        }
        CamperTouchButton {
            x: 12
            y: 29
            width: 112
            height: 34
            label: "TEMPERATUR"
            active: heater.mode === "temperature"
            accentColor: "#f39b58"
            onClicked: view.heaterSetting("mode", "temperature")
        }
        CamperTouchButton {
            x: 134
            y: 29
            width: 112
            height: 34
            label: "LEISTUNG"
            active: heater.mode === "power"
            accentColor: "#f39b58"
            onClicked: view.heaterSetting("mode", "power")
        }
        CamperTouchButton {
            x: 256
            y: 29
            width: 112
            height: 34
            label: "LÜFTEN"
            active: heater.mode === "ventilation"
            accentColor: "#45c9fa"
            onClicked: view.heaterSetting("mode", "ventilation")
        }
        Text {
            x: 12
            y: 78
            text: heater.mode === "power" ? "Leistungsstufe" : heater.mode === "ventilation" ? "Lüftungsbetrieb" : "Solltemperatur"
            color: view.secondaryText
            font.pixelSize: 10
        }
        CamperTouchButton {
            x: 144
            y: 70
            width: 42
            height: 34
            visible: heater.mode !== "ventilation"
            label: "−"
            onClicked: heater.mode === "power" ? view.heaterSetting("power", Math.max(1, Number(heater.powerLevel || 5) - 1)) : view.adapter.command("heater", "setpoint", Math.max(5, Number(heater.setpoint || 20) - 1))
        }
        Text {
            x: 194
            y: 78
            width: 70
            horizontalAlignment: Text.AlignHCenter
            text: heater.mode === "power" ? view.formatted(heater.powerLevel, 0, " / 10") : heater.mode === "ventilation" ? "AKTIV" : view.formatted(heater.setpoint, 0, " °C")
            color: view.primaryText
            font.pixelSize: 13
            font.bold: true
        }
        CamperTouchButton {
            x: 272
            y: 70
            width: 42
            height: 34
            visible: heater.mode !== "ventilation"
            label: "+"
            onClicked: heater.mode === "power" ? view.heaterSetting("power", Math.min(10, Number(heater.powerLevel || 5) + 1)) : view.adapter.command("heater", "setpoint", Math.min(30, Number(heater.setpoint || 20) + 1))
        }
        Text {
            x: 12
            y: 122
            text: "Laufzeit"
            color: view.secondaryText
            font.pixelSize: 10
        }
        CamperTouchButton {
            x: 85
            y: 112
            width: 42
            height: 34
            label: "−"
            onClicked: view.heaterSetting("duration", Math.max(0, Number(heater.durationMinutes || 0) - 60))
        }
        Text {
            x: 136
            y: 121
            width: 105
            horizontalAlignment: Text.AlignHCenter
            text: Number(heater.durationMinutes || 0) === 0 ? "DAUERBETRIEB" : (Number(heater.durationMinutes) / 60) + " STUNDEN"
            color: view.primaryText
            font.pixelSize: 10
            font.bold: true
        }
        CamperTouchButton {
            x: 251
            y: 112
            width: 42
            height: 34
            label: "+"
            onClicked: view.heaterSetting("duration", Math.min(720, Number(heater.durationMinutes || 0) + 60))
        }
        CamperTouchButton {
            x: 303
            y: 112
            width: 65
            height: 34
            label: "STANDBY"
            active: heater.standbyVent === true
            onClicked: view.heaterSetting("standbyVent", !heater.standbyVent)
        }
    }

    Rectangle {
        x: 400
        y: 68
        width: 390
        height: 156
        radius: 10
        color: view.panelColor
        border.color: view.lineColor
        Text {
            x: 12
            y: 9
            text: "SENSOR & SCHUTZ"
            color: view.secondaryText
            font.pixelSize: 9
            font.bold: true
        }
        Text {
            x: 12
            y: 35
            text: "Regelsensor"
            color: view.secondaryText
            font.pixelSize: 10
        }
        CamperTouchButton {
            x: 125
            y: 26
            width: 144
            height: 34
            label: view.sensorText(heater.tempSource)
            active: heater.sensorOnline === true
            onClicked: view.heaterSetting("tempSource", view.nextValue(heater.tempSource, ["ruuvi1", "ruuvi2", "ruuvi3", "internal", "external"]))
        }
        Text {
            x: 279
            y: 35
            text: heater.sensorFallback ? "ERSATZ AKTIV" : (heater.sensorOnline ? "BEREIT" : "FEHLT")
            color: heater.sensorOnline ? "#32d4a0" : "#f5c451"
            font.pixelSize: 8
            font.bold: true
        }
        CamperTouchButton {
            x: 12
            y: 68
            width: 112
            height: 34
            label: "FROSTSCHUTZ"
            active: heater.frostEnabled === true
            accentColor: "#45c9fa"
            onClicked: view.heaterSetting("frostEnabled", !heater.frostEnabled)
        }
        Text {
            x: 135
            y: 77
            text: "Start " + view.formatted(heater.frostTemp, 0, " °C") + " · Stopp " + view.formatted(heater.frostStop, 0, " °C")
            color: view.primaryText
            font.pixelSize: 10
            font.bold: true
        }
        CamperTouchButton {
            x: 302
            y: 68
            width: 35
            height: 34
            label: "−"
            onClicked: view.heaterSetting("frostTemp", Math.max(0, Number(heater.frostTemp || 5) - 1))
        }
        CamperTouchButton {
            x: 343
            y: 68
            width: 35
            height: 34
            label: "+"
            onClicked: view.heaterSetting("frostTemp", Math.min(12, Number(heater.frostTemp || 5) + 1))
        }
        Text {
            x: 12
            y: 122
            text: "Unterspannung"
            color: view.secondaryText
            font.pixelSize: 10
        }
        CamperTouchButton {
            x: 125
            y: 112
            width: 42
            height: 34
            label: "−"
            onClicked: view.heaterSetting("lowVoltage", Math.max(10.5, Math.round((Number(heater.lowVoltage || 11.5) - 0.1) * 10) / 10))
        }
        Text {
            x: 176
            y: 121
            width: 70
            horizontalAlignment: Text.AlignHCenter
            text: view.formatted(heater.lowVoltage, 1, " V")
            color: view.primaryText
            font.pixelSize: 11
            font.bold: true
        }
        CamperTouchButton {
            x: 255
            y: 112
            width: 42
            height: 34
            label: "+"
            onClicked: view.heaterSetting("lowVoltage", Math.min(13, Math.round((Number(heater.lowVoltage || 11.5) + 0.1) * 10) / 10))
        }
        CamperTouchButton {
            x: 305
            y: 112
            width: 73
            height: 34
            label: heater.batterySource === "victron" ? "VICTRON" : "HEIZUNG"
            onClicked: view.heaterSetting("batterySource", heater.batterySource === "victron" ? "heater" : "victron")
        }
    }

    Rectangle {
        x: 10
        y: 232
        width: 382
        height: 180
        radius: 10
        color: view.panelColor
        border.color: view.lineColor
        Text {
            x: 12
            y: 9
            text: "STATUS & TECHNIK"
            color: view.secondaryText
            font.pixelSize: 9
            font.bold: true
        }
        Text {
            x: 12
            y: 31
            text: "Innenraum"
            color: view.secondaryText
            font.pixelSize: 9
        }
        Text {
            x: 118
            y: 27
            text: view.formatted(climate.roomTemperature, 1, " °C")
            color: view.primaryText
            font.pixelSize: 14
            font.bold: true
        }
        Text {
            x: 205
            y: 31
            text: "Heizung"
            color: view.secondaryText
            font.pixelSize: 9
        }
        Text {
            x: 294
            y: 27
            text: view.formatted(heater.voltage, 1, " V")
            color: view.primaryText
            font.pixelSize: 14
            font.bold: true
        }
        Text {
            x: 12
            y: 68
            text: "Wärmetauscher"
            color: view.secondaryText
            font.pixelSize: 9
        }
        Text {
            x: 118
            y: 64
            text: view.formatted(heater.heatExchangerTemperature, 1, " °C")
            color: view.primaryText
            font.pixelSize: 13
            font.bold: true
        }
        Text {
            x: 205
            y: 68
            text: "Gebläse"
            color: view.secondaryText
            font.pixelSize: 9
        }
        Text {
            x: 294
            y: 64
            text: view.formatted(heater.fanRpm, 0, " rpm")
            color: view.primaryText
            font.pixelSize: 13
            font.bold: true
        }
        Text {
            x: 12
            y: 105
            text: "Kraftstoffpumpe"
            color: view.secondaryText
            font.pixelSize: 9
        }
        Text {
            x: 118
            y: 101
            text: view.formatted(heater.pumpHz, 2, " Hz")
            color: view.primaryText
            font.pixelSize: 13
            font.bold: true
        }
        Text {
            x: 205
            y: 105
            text: "Fehler"
            color: view.secondaryText
            font.pixelSize: 9
        }
        Text {
            x: 294
            y: 101
            text: Number(heater.error || 0) ? "E" + heater.error : "KEINER"
            color: Number(heater.error || 0) ? "#e05e68" : "#32d4a0"
            font.pixelSize: 12
            font.bold: true
        }
        Text {
            x: 12
            y: 143
            width: 356
            elide: Text.ElideRight
            text: "Start: " + (heater.startedBy || "–") + (heater.endAt ? " · Ende " + view.timeText(heater.endAt) : " · Dauerbetrieb")
            color: view.secondaryText
            font.pixelSize: 9
        }
    }

    Rectangle {
        x: 400
        y: 232
        width: 390
        height: 180
        radius: 10
        color: view.panelColor
        border.color: view.lineColor
        Text {
            x: 12
            y: 9
            text: "AUTOTERM-WARTUNG"
            color: view.secondaryText
            font.pixelSize: 9
            font.bold: true
        }
        Text {
            x: 12
            y: 31
            text: heater.maintenanceActive ? "WARTUNGSLAUF AKTIV" : heater.maintenanceDue ? "MONATLICHER LAUF FÄLLIG" : "MONATLICHER LAUF ERLEDIGT"
            color: heater.maintenanceActive || heater.maintenanceDue ? "#f5c451" : "#32d4a0"
            font.pixelSize: 11
            font.bold: true
        }
        Text {
            x: 12
            y: 51
            text: heater.maintenanceActive ? Math.floor(Number(heater.maintenanceSeconds || 0) / 60) + " / 20 min" : "Zuletzt: " + view.timeText(heater.lastMaintenanceRun)
            color: view.secondaryText
            font.pixelSize: 9
        }
        CamperTouchButton {
            x: 12
            y: 72
            width: 366
            height: 38
            label: heater.maintenanceActive ? "WARTUNGSLAUF LÄUFT" : "20-MIN-WARTUNGSLAUF STARTEN"
            enabled: !heater.on && !heater.cooling && !heater.maintenanceActive && !heater.startBlocked
            active: heater.maintenanceActive === true
            accentColor: "#f5c451"
            onClicked: view.adapter.command("heater", "maintenance", null)
        }
        Text {
            x: 12
            y: 123
            text: heater.annualServiceDue ? "JAHRESWARTUNG FÄLLIG" : "JAHRESWARTUNG DOKUMENTIERT"
            color: heater.annualServiceDue ? "#f5c451" : "#32d4a0"
            font.pixelSize: 10
            font.bold: true
        }
        CamperTouchButton {
            x: 229
            y: 116
            width: 149
            height: 36
            label: "ALS ERLEDIGT"
            onClicked: view.adapter.command("heater", "annualDone", null)
        }
        Text {
            x: 12
            y: 151
            text: "Zuletzt: " + view.timeText(heater.lastAnnualService)
            color: view.secondaryText
            font.pixelSize: 9
        }
    }
}
