import QtQuick
import QtQuick.Window
import "../../pages/camper/v2"

Window {
    id: window
    objectName: "previewWindow"

    property int settingsClickCount: 0
    property int closeClickCount: 0
    property int lastRequestedPage: -1
    property int currentCamperPage: 0
    property int quickCommandCount: 0
    property int quickSettingsCount: 0
    property int commandCount: 0
    property string lastCommandTarget: ""
    property string lastCommandAction: ""
    property var lastCommandValue: null
    property int lastCommandChannel: 0
    property bool previewHighBeamVehicleOn: false
    property bool previewHighBeamManualOn: false
    property bool previewHighBeamOutputOnline: true
    property int previewV2EnergyPane: 0
    property bool previewV2DayMode: false
    property int previewPanel: 0
    property bool previewCustomCommandsAllowed: true
    property bool previewAllLightsOn: false
    property bool previewLightsRightView: false
    readonly property int previewActivePanel: v2Shell.activePanel

    onPreviewPanelChanged: v2Shell.activePanel = previewPanel
    onPreviewLightsRightViewChanged: v2Shell.lightsRightView = previewLightsRightView

    width: 800
    height: 480
    visible: true
    color: "#05090c"
    title: "CamperControl gui-v2 V2 preview"

    QtObject {
        id: previewAdapter

        readonly property bool connected: true
        readonly property bool customConnected: true
        readonly property bool customReadConnected: true
        readonly property bool customCommandsAllowed: window.previewCustomCommandsAllowed
        readonly property real batterySoc: 82
        readonly property real batteryVoltage: 12.7
        readonly property real solarPower: 486
        readonly property bool hasBatterySoc: true
        readonly property bool hasBatteryVoltage: true
        readonly property bool hasSolarPower: true
        property var stateData: ({
                energy: {
                    battery: {
                        name: "SmartShunt",
                        online: true,
                        soc: 82,
                        voltage: 12.7,
                        starterVoltage: 12.5,
                        current: 4.2,
                        power: 53
                    },
                    solar: {
                        power: 486,
                        chargers: [
                            {
                                name: "MPPT 100/30 · 1",
                                online: true,
                                power: 0,
                                pvVoltage: 0.01,
                                yieldTodayKwh: 0
                            },
                            {
                                name: "MPPT 100/30 · 2",
                                online: true,
                                power: 478,
                                pvVoltage: 42.97,
                                yieldTodayKwh: 0.52
                            },
                            {
                                name: "MPPT 150/45",
                                online: false,
                                power: null,
                                pvVoltage: null,
                                yieldTodayKwh: null
                            }
                        ]
                    },
                    indevolt: {
                        online: true,
                        soc: 31,
                        solarPower: 8,
                        batteryPower: -5,
                        gridConnection: {
                            available: true,
                            on: false
                        }
                    },
                    orion: {
                        online: false,
                        on: false,
                        power: null,
                        voltage: null,
                        current: null
                    }
                },
                water: {
                    fresh: {
                        name: "FRISCHWASSER",
                        level: null,
                        remainingLitres: null
                    },
                    pump: {
                        on: true,
                        online: true,
                        channel: 2
                    }
                },
                climate: {
                    roomTemperature: 21.6,
                    automation: {
                        enabled: true,
                        mode: "auto",
                        targetTemperature: 20,
                        hysteresis: 1,
                        fanSpeed: 50
                    },
                    temperatureSensors: {
                        comfort: {
                            temp: 21.6,
                            humidity: 66
                        }
                    },
                    heater: {
                        online: true,
                        on: false,
                        cooling: false,
                        mode: "temperature",
                        setpoint: 22,
                        durationMinutes: 0,
                        status: "Bereit"
                    },
                    fan: {
                        name: "MAXXFAN",
                        online: true,
                        on: true,
                        speed: 40,
                        mode: "forward",
                        autoHold: false
                    }
                },
                power: {
                    inverter: {
                        online: true,
                        on: false,
                        outputPower: 0
                    },
                    dcChannels: [
                        {
                            id: "dc_outlets_left",
                            name: "12 V links",
                            channel: 1,
                            on: true
                        },
                        {
                            id: "water_pump",
                            name: "Wasserpumpe",
                            channel: 2,
                            on: true
                        },
                        {
                            id: "dc_outlets_right",
                            name: "12 V rechts",
                            channel: 4,
                            on: false
                        },
                        {
                            id: "starlink",
                            name: "Starlink",
                            channel: 5,
                            on: true
                        },
                        {
                            id: "maxxfan_power",
                            name: "MaxxFan",
                            channel: 6,
                            on: true
                        }
                    ]
                },
                vehicle: {
                    highBeam: {
                        on: window.previewAllLightsOn || window.previewHighBeamVehicleOn || window.previewHighBeamManualOn,
                        vehicleOn: window.previewHighBeamVehicleOn,
                        manualOn: window.previewAllLightsOn || window.previewHighBeamManualOn,
                        outputOnline: window.previewHighBeamOutputOnline,
                        outputChannel: 3
                    }
                },
                lights: {
                    items: [
                        {
                            id: "inside_main",
                            channel: 7,
                            on: true,
                            dimming: 65
                        },
                        {
                            id: "outside_left",
                            channel: 8,
                            on: window.previewAllLightsOn,
                            dimming: 80
                        },
                        {
                            id: "outside_right",
                            channel: 9,
                            on: true,
                            dimming: 70
                        },
                        {
                            id: "outside_rear",
                            channel: 10,
                            on: window.previewAllLightsOn,
                            dimming: 90
                        },
                        {
                            id: "outside_front_white",
                            channel: 11,
                            on: true,
                            dimming: 60
                        },
                        {
                            id: "outside_front_amber",
                            channel: 12,
                            on: false,
                            dimming: 100
                        }
                    ]
                },
                ui: {
                    quickAccessIds: ["switch:water_pump", "switch:starlink", "switch:dc_outlets_left", "light:inside_main"],
                    quickAccessOptions: [
                        {
                            id: "switch:water_pump",
                            name: "Wasserpumpe",
                            group: "12 V",
                            icon: "pump"
                        },
                        {
                            id: "switch:starlink",
                            name: "Starlink",
                            group: "12 V",
                            icon: "satellite"
                        },
                        {
                            id: "switch:dc_outlets_left",
                            name: "12-V-Steckdosen links",
                            group: "12 V",
                            icon: "outlet"
                        },
                        {
                            id: "light:inside_main",
                            name: "Innenlicht",
                            group: "Licht",
                            icon: "bulb"
                        },
                        {
                            id: "device:heater",
                            name: "Autoterm Air 2D",
                            group: "Klima",
                            icon: "heater"
                        }
                    ],
                    quickAccess: [
                        {
                            id: "switch:water_pump",
                            name: "Wasserpumpe",
                            icon: "pump",
                            active: true,
                            available: true,
                            status: "EIN",
                            command: {
                                target: "waterPump",
                                action: "set",
                                value: false
                            }
                        },
                        {
                            id: "switch:starlink",
                            name: "Starlink",
                            icon: "satellite",
                            active: true,
                            available: true,
                            status: "ONLINE",
                            command: {
                                target: "starpower",
                                action: "set",
                                value: 0,
                                channel: 5
                            }
                        },
                        {
                            id: "switch:dc_outlets_left",
                            name: "12 V links",
                            icon: "outlet",
                            active: false,
                            available: true,
                            status: "AUS",
                            command: {
                                target: "starpower",
                                action: "set",
                                value: 1,
                                channel: 1
                            }
                        },
                        {
                            id: "light:inside_main",
                            name: "Innenlicht",
                            icon: "bulb",
                            active: true,
                            available: true,
                            status: "EIN",
                            command: {
                                target: "starpower",
                                action: "set",
                                value: 0,
                                channel: 7
                            }
                        }
                    ]
                }
            })

        readonly property bool weatherConnected: true
        readonly property string weatherErrorText: ""
        property var weatherData: makeWeatherData()

        function makeWeatherData() {
            const hourly = [];
            const base = new Date();
            base.setMinutes(0, 0, 0);
            for (let hour = 0; hour < 24; ++hour) {
                hourly.push({
                    t: new Date(base.getTime() + hour * 3600000).toISOString(),
                    tempC: 16.5 + Math.sin((hour - 4) / 5) * 5.5,
                    precipProbabilityPct: hour >= 7 && hour <= 12 ? 65 - Math.abs(9 - hour) * 11 : Math.max(4, 21 - hour),
                    precipMm: hour >= 8 && hour <= 10 ? .8 : 0,
                    ww: hour >= 8 && hour <= 10 ? 61 : (hour < 6 || hour > 19 ? 2 : 1),
                    icon: hour >= 8 && hour <= 10 ? "rain" : "cloudy",
                    condition: hour >= 8 && hour <= 10 ? "Leichter Regen" : "Bewölkt",
                    windKmh: 12 + hour % 5
                });
            }
            const daily = [];
            for (let day = 0; day < 6; ++day) {
                daily.push({
                    date: new Date(base.getTime() + day * 86400000).toISOString().slice(0, 10),
                    minC: 10 + day,
                    maxC: 21 + (day % 3),
                    precipMm: day === 2 ? 4.2 : .4 * day,
                    maxHourlyPrecipProbabilityPct: day === 2 ? 78 : 12 + day * 7,
                    ww: day === 2 ? 61 : (day === 4 ? 3 : 1),
                    icon: day === 2 ? "rain" : "cloudy"
                });
            }
            return {
                fetchedAtUtc: new Date().toISOString(),
                stale: false,
                station: {
                    name: "Berlin-Tempelhof"
                },
                sun: {
                    riseUtc: new Date(base.getTime() + 6 * 3600000).toISOString(),
                    setUtc: new Date(base.getTime() + 20 * 3600000).toISOString(),
                    origin: "calculated"
                },
                hourly: hourly,
                daily: daily
            };
        }

        function command(target, action, value, extra) {
            window.commandCount += 1;
            window.lastCommandTarget = target;
            window.lastCommandAction = action;
            window.lastCommandValue = value;
            window.lastCommandChannel = extra && extra.channel ? Number(extra.channel) : 0;
        }
        function activateQuick(item) {
            window.quickCommandCount += 1;
        }
        function setQuickAccessIds(ids) {
            window.quickSettingsCount += 1;
        }
    }

    CamperV2Shell {
        id: v2Shell
        anchors.fill: parent
        currentPage: Math.max(0, Math.min(5, window.currentCamperPage))
        energyPane: window.previewV2EnergyPane
        dayMode: window.previewV2DayMode
        adapter: previewAdapter
        darkLogoSource: "../../../images/camper_transit_line_dark.png"
        lightLogoSource: "../../../images/camper_transit_line_light.png"
        leftVehicleSource: "../../../images/camper_v2_vehicle_left.png"
        rightVehicleSource: "../../../images/camper_v2_vehicle_right.png"
        onCurrentPageChanged: {
            if (window.currentCamperPage <= 5)
                window.currentCamperPage = currentPage;
        }
        onOpenVictronSettings: window.settingsClickCount += 1
        onCloseRequested: window.closeClickCount += 1
    }
}
