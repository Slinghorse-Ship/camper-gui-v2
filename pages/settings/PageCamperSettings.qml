/* CamperControl settings hosted inside the preserved Victron settings stack. */

import QtQuick
import Victron.VenusOS

Page {
    id: root

    title: "CamperControl"

    readonly property string camperServiceUid: BackendConnection.serviceUidFromName("com.victronenergy.campercontrol", 0)
    readonly property bool locationWriteAllowed: !BackendConnection.vrm
            || BackendConnection.vrmPortalMode === BackendConnection.Full
    property var locationConfig: defaultLocationConfig()
    property string locationError: ""
    property var coldProtection: defaultColdProtection()
    property string coldProtectionError: ""

    readonly property var weatherStations: [
        { display: "GPS / automatisch", value: "" },
        { display: "Nordsee · Norderney", value: "10113" },
        { display: "Schleswig-Holstein · Flensburg", value: "10033" },
        { display: "Schleswig-Holstein · Kiel-Holtenau", value: "10044" },
        { display: "Hamburg · Fuhlsbüttel", value: "10147" },
        { display: "Bremen · Flughafen", value: "10224" },
        { display: "Niedersachsen · Hannover", value: "10338" },
        { display: "Brandenburg · Potsdam", value: "10379" },
        { display: "Berlin · Tempelhof", value: "10384" },
        { display: "Nordrhein-Westfalen · Düsseldorf", value: "10400" },
        { display: "Nordrhein-Westfalen · Köln/Bonn", value: "10513" },
        { display: "Hessen · Kassel", value: "10438" },
        { display: "Hessen · Offenbach-Wetterpark", value: "10641" },
        { display: "Sachsen · Leipzig/Schkeuditz", value: "10469" },
        { display: "Sachsen · Dresden-Stadt", value: "10487" },
        { display: "Thüringen · Erfurt", value: "10554" },
        { display: "Saarland · Saarbrücken", value: "10708" },
        { display: "Baden-Württemberg · Stuttgart-Echterdingen", value: "10738" },
        { display: "Baden-Württemberg · Freiburg", value: "10803" },
        { display: "Baden-Württemberg · Konstanz", value: "10929" },
        { display: "Bayern · Nürnberg", value: "10763" },
        { display: "Bayern · München Stadt", value: "10865" },
        { display: "Bayern · München Flughafen", value: "10870" }
    ]

    // Deliberately curated coastal BSH gauges only. River, inland-waterway,
    // Binnenpegel and non-North-Sea features must never enter this model.
    readonly property var tideStations: [
        { display: "GPS / automatisch", value: "" },
        { display: "Jade · Wilhelmshaven, Alter Vorhafen", value: "wilhelmshaven_alter_vorhafen" },
        { display: "Jade · Jade-Weser-Port", value: "jade-weser-port" },
        { display: "Jade · Hooksielplate", value: "hooksielplate" },
        { display: "Ostfriesland · Borkum, Fischerbalje", value: "borkum_fischerbalje" },
        { display: "Ostfriesland · Emden, Große Seeschleuse", value: "emden_grosse_seeschleuse" },
        { display: "Ostfriesland · Norderney, Riffgat", value: "norderney_riffgat" },
        { display: "Ostfriesland · Wangerooge Hafen", value: "wangerooge_hafen" },
        { display: "Ostfriesland · Spiekeroog", value: "spiekeroog" },
        { display: "Ostfriesland · Langeoog Hafeneinfahrt", value: "langeoog_hafeneinfahrt" },
        { display: "Elbmündung · Cuxhaven, Steubenhöft", value: "cuxhaven_steubenhoeft" },
        { display: "Dithmarschen · Büsum, Schleuse", value: "buesum_schleuse" },
        { display: "Nordfriesland · Husum, Schleuse", value: "husum_schleuse" },
        { display: "Nordfriesland · Dagebüll", value: "dagebuell" },
        { display: "Sylt · List Hafen", value: "list_hafen" },
        { display: "Sylt · Hörnum Hafen", value: "hoernum_hafen" },
        { display: "Sylt · Westerland", value: "westerland" },
        { display: "Föhr · Wyk", value: "wyk" },
        { display: "Amrum · Wittdün Hafen", value: "wittduen_hafen" }
    ]

    function defaultLocationConfig() {
        return {
            schema: 1,
            weather: { mode: "gps", stationId: "" },
            tide: { mode: "gps", stationId: "" }
        };
    }

    function defaultColdProtection() {
        return {
            enabled: false,
            startTemperature: 3,
            stopTemperature: 5,
            power: 4,
            sensor: "floor",
            sensorName: "Ruuvi B7B8 · Boden",
            sensorTemperature: null,
            active: false
        };
    }

    function boundedNumber(value, fallback, minimum, maximum) {
        const parsed = Number(value);
        return isNaN(parsed) ? fallback : Math.max(minimum, Math.min(maximum, parsed));
    }

    function normalizeColdProtection(value) {
        if (!value || typeof value !== "object" || Array.isArray(value))
            return null;
        const startTemperature = boundedNumber(value.startTemperature, 3, 0, 8);
        const stopTemperature = Math.max(startTemperature + 1,
                boundedNumber(value.stopTemperature, 5, 1, 12));
        return {
            enabled: value.enabled === true,
            startTemperature: startTemperature,
            stopTemperature: stopTemperature,
            power: Math.round(boundedNumber(value.power, 4, 1, 10)),
            sensor: "floor",
            sensorName: value.sensorName || "Ruuvi B7B8 · Boden",
            sensorTemperature: value.sensorTemperature === null || value.sensorTemperature === undefined
                    ? null : Number(value.sensorTemperature),
            active: value.active === true
        };
    }

    function refreshColdProtection() {
        if (!climateStateItem.valid) {
            coldProtection = defaultColdProtection();
            coldProtectionError = "CamperControl-Dienst nicht verbunden";
            return;
        }
        try {
            const climate = JSON.parse(String(climateStateItem.value || "{}"));
            const normalized = normalizeColdProtection(climate.coldProtection);
            coldProtection = normalized || defaultColdProtection();
            coldProtectionError = normalized ? "" : "Kälteschutzstatus nicht verfügbar";
        } catch (error) {
            coldProtection = defaultColdProtection();
            coldProtectionError = "Ungültiger Kälteschutzstatus";
        }
    }

    function setColdProtection(patch) {
        if (!commandItem.valid || !locationWriteAllowed)
            return;
        const next = normalizeColdProtection(Object.assign({}, coldProtection, patch));
        if (!next)
            return;
        coldProtection = next;
        coldProtectionError = "";
        commandItem.setValue(JSON.stringify({
            target: "settings",
            action: "patch",
            origin: BackendConnection.vrm ? "vrm" : "gx",
            patch: {
                coldProtection: {
                    enabled: next.enabled,
                    startTemperature: next.startTemperature,
                    stopTemperature: next.stopTemperature,
                    power: next.power,
                    sensor: "floor"
                }
            }
        }));
    }

    function normalizeLocationSection(section, weatherSection) {
        if (!section || typeof section !== "object" || Array.isArray(section))
            return null;
        const mode = section.mode;
        let stationId = section.stationId;
        if ((mode !== "gps" && mode !== "station") || typeof stationId !== "string")
            return null;
        stationId = stationId.trim();
        if (mode === "gps" && stationId !== "")
            return null;
        if (mode === "station") {
            const pattern = weatherSection ? /^[A-Za-z0-9]{5}$/ : /^[a-z0-9][a-z0-9_-]{0,127}$/;
            if (!pattern.test(stationId))
                return null;
        }
        return {
            mode: mode,
            stationId: weatherSection ? stationId.toUpperCase() : stationId
        };
    }

    function parseLocationConfig(rawValue) {
        if (typeof rawValue !== "string" || rawValue.length === 0 || rawValue.length > 1024)
            return null;
        try {
            const value = JSON.parse(rawValue);
            if (!value || typeof value !== "object" || Array.isArray(value) || value.schema !== 1)
                return null;
            const weather = normalizeLocationSection(value.weather, true);
            const tide = normalizeLocationSection(value.tide, false);
            return weather && tide ? { schema: 1, weather: weather, tide: tide } : null;
        } catch (error) {
            return null;
        }
    }

    function optionIndex(options, stationId) {
        for (let index = 0; index < options.length; ++index) {
            if (options[index].value === stationId)
                return index;
        }
        return -1;
    }

    function sectionIndex(options, section) {
        return section.mode === "gps" ? 0 : optionIndex(options, section.stationId);
    }

    function refreshLocationConfig() {
        if (!weatherLocationItem.valid) {
            locationConfig = defaultLocationConfig();
            locationError = "CamperControl-Dienst nicht verbunden";
            return;
        }
        const parsed = parseLocationConfig(weatherLocationItem.value);
        locationConfig = parsed || defaultLocationConfig();
        locationError = parsed ? "" : "Ungültige Standortkonfiguration – GPS-Standard aktiv";
    }

    function selectLocation(sectionName, options, index) {
        if (!weatherLocationItem.valid || !locationWriteAllowed || index < 0 || index >= options.length)
            return;
        const stationId = options[index].value;
        const selection = stationId === ""
                ? { mode: "gps", stationId: "" }
                : { mode: "station", stationId: stationId };
        const current = locationConfig[sectionName];
        if (current.mode === selection.mode && current.stationId === selection.stationId)
            return;

        const nextConfig = {
            schema: 1,
            weather: sectionName === "weather" ? selection : locationConfig.weather,
            tide: sectionName === "tide" ? selection : locationConfig.tide
        };
        const rawValue = JSON.stringify(nextConfig);
        if (rawValue.length > 1024 || parseLocationConfig(rawValue) === null)
            return;
        locationConfig = nextConfig;
        locationError = "";
        weatherLocationItem.setValue(rawValue);
    }

    VeQuickItem {
        id: weatherLocationItem
        uid: root.camperServiceUid ? root.camperServiceUid + "/Settings/WeatherLocation" : ""
        onValueChanged: root.refreshLocationConfig()
        onValidChanged: root.refreshLocationConfig()
    }

    VeQuickItem {
        id: climateStateItem
        uid: root.camperServiceUid ? root.camperServiceUid + "/State/Climate" : ""
        onValueChanged: root.refreshColdProtection()
        onValidChanged: root.refreshColdProtection()
    }

    VeQuickItem {
        id: commandItem
        uid: root.camperServiceUid ? root.camperServiceUid + "/Command" : ""
    }

    Component.onCompleted: {
        refreshLocationConfig();
        refreshColdProtection();
    }

    GradientListView {
        model: VisibleItemModel {
            ListText {
                text: "Oberfläche"
                secondaryText: "V2 · Transit Horizon"
                caption: "Die Camper-Oberfläche dieses Builds verwendet ausschließlich V2."
            }

            ListButton {
                text: "CamperControl öffnen"
                secondaryText: "ÖFFNEN"
                writeAccessLevel: VenusOS.User_AccessType_User
                onClicked: Global.mainView.showCamperUi()
            }

            ListText {
                text: "Seitliche Panels"
                secondaryText: "Links Favoriten · rechts Wetter & Tide"
                caption: "Vom unsichtbaren Bildschirmrand zur Mitte wischen."
            }

            SectionHeader {
                text: "Wetter und Tide"
            }

            ListRadioButtonGroup {
                id: weatherLocation
                text: "Wetterstandort"
                caption: "Automatisch per GPS oder feste DWD-Wetterstation."
                writeAccessLevel: VenusOS.User_AccessType_User
                interactive: weatherLocationItem.valid && root.locationWriteAllowed
                optionModel: root.weatherStations
                currentIndex: root.sectionIndex(optionModel, root.locationConfig.weather)
                defaultSecondaryText: root.locationConfig.weather.mode === "station"
                        ? "DWD · " + root.locationConfig.weather.stationId
                        : "Nicht verfügbar"
                updateDataOnClick: false
                onOptionClicked: function(index) {
                    root.selectLocation("weather", optionModel, index);
                }
            }

            ListRadioButtonGroup {
                id: tideLocation
                text: "Tidestation"
                caption: "Automatisch per GPS oder feste BSH-Nordseestation. Ohne nahe Station wird Wilhelmshaven verwendet."
                writeAccessLevel: VenusOS.User_AccessType_User
                interactive: weatherLocationItem.valid && root.locationWriteAllowed
                optionModel: root.tideStations
                currentIndex: root.sectionIndex(optionModel, root.locationConfig.tide)
                defaultSecondaryText: root.locationConfig.tide.mode === "station"
                        ? "BSH · " + root.locationConfig.tide.stationId
                        : "Nicht verfügbar"
                updateDataOnClick: false
                onOptionClicked: function(index) {
                    root.selectLocation("tide", optionModel, index);
                }
            }

            ListText {
                preferredVisible: root.locationError !== ""
                text: "Standortauswahl"
                secondaryText: root.locationError
            }

            SectionHeader {
                text: "AUTOTERM-Kälteschutz"
            }

            ListSwitch {
                text: "Kälteschutz"
                secondaryText: root.coldProtection.active ? "AKTIV · Heizung durch Frostschutz gestartet"
                        : (root.coldProtection.enabled ? "Automatik bereit" : "Aus")
                caption: "Hält den Bodenbereich automatisch frostfrei. Batterie- und AUTOTERM-Schutz bleiben wirksam."
                writeAccessLevel: VenusOS.User_AccessType_User
                interactive: commandItem.valid && root.locationWriteAllowed
                checkable: true
                updateDataOnClick: false
                checked: root.coldProtection.enabled
                onClicked: root.setColdProtection({ enabled: checked })
            }

            ListSpinBox {
                text: "Start unter"
                suffix: " °C"
                from: 0
                to: 8
                stepSize: 1
                value: root.coldProtection.startTemperature
                writeAccessLevel: VenusOS.User_AccessType_User
                interactive: commandItem.valid && root.locationWriteAllowed
                onSelectorAccepted: function(newValue) {
                    root.setColdProtection({ startTemperature: newValue });
                }
            }

            ListSpinBox {
                text: "Stopp ab"
                suffix: " °C"
                from: 1
                to: 12
                stepSize: 1
                value: root.coldProtection.stopTemperature
                writeAccessLevel: VenusOS.User_AccessType_User
                interactive: commandItem.valid && root.locationWriteAllowed
                onSelectorAccepted: function(newValue) {
                    root.setColdProtection({ stopTemperature: newValue });
                }
            }

            ListSpinBox {
                text: "Heizstufe"
                suffix: " / 10"
                from: 1
                to: 10
                stepSize: 1
                value: root.coldProtection.power
                writeAccessLevel: VenusOS.User_AccessType_User
                interactive: commandItem.valid && root.locationWriteAllowed
                onSelectorAccepted: function(newValue) {
                    root.setColdProtection({ power: newValue });
                }
            }

            ListText {
                text: "Fester Sensor"
                secondaryText: root.coldProtection.sensorName
                caption: root.coldProtection.sensorTemperature === null
                        ? "B7B8 liefert derzeit keinen Temperaturwert."
                        : "Aktuell " + root.coldProtection.sensorTemperature.toFixed(1) + " °C"
            }

            ListText {
                preferredVisible: root.coldProtectionError !== ""
                text: "Kälteschutz"
                secondaryText: root.coldProtectionError
            }

            SectionHeader {
                text: "Datenquellen & Lizenzen"
            }

            ListText {
                text: "DWD-Wetterdaten"
                secondaryText: "Quelle: Deutscher Wetterdienst · CC BY 4.0"
                caption: "CamperControl wählt die Station, normalisiert MOSMIX und bildet Tageswerte."
            }

            ListLink {
                text: "DWD Open Data – Lizenz und Quellenhinweis"
                url: "https://www.dwd.de/DE/leistungen/opendata/faqs_opendata.html"
            }

            ListText {
                text: "BSH-Tidedaten"
                secondaryText: "© Bundesamt für Seeschifffahrt und Hydrographie (BSH) · CC BY 4.0"
                caption: "CamperControl wählt nur Nordseestationen, normalisiert UTC/cm→m und reduziert die Kurve."
            }

            ListLink {
                text: "BSH WaterLevelForecast – Lizenz und Quelle"
                url: "https://gdi.bsh.de/ldproxy/rest/services/WaterLevelForecast"
            }

            ListText {
                text: "CamperControl-Software"
                secondaryText: "PolyForm Noncommercial 1.0.0"
                caption: "Kommerzielle Nutzung der eigenständigen CamperControl-Anteile ist nicht erlaubt."
            }
        }
    }
}
