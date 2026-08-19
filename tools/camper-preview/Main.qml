import QtQuick
import QtQuick.Window
import "../../pages/camper"

Window {
    id: window
    objectName: "previewWindow"

    property int settingsClickCount: 0
    property int closeClickCount: 0
    property int lastRequestedPage: -1
    property int currentCamperPage: 0
    property int quickCommandCount: 0
    property int quickSettingsCount: 0

    width: 800
    height: 480
    visible: true
    color: "#05090c"
    title: "CamperControl gui-v2 Phase 2 preview"

    QtObject {
        id: previewAdapter

        readonly property bool connected: true
        readonly property bool customConnected: true
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
                        chargers: []
                    },
                    indevolt: {},
                    orion: {}
                },
                water: {
                    fresh: {
                        name: "FRISCHWASSER",
                        level: 74,
                        remainingLitres: 89
                    },
                    pump: {
                        on: true,
                        online: true,
                        channel: 2
                    }
                },
                climate: {
                    roomTemperature: 21.6,
                    heater: {
                        on: false,
                        cooling: false,
                        setpoint: 22,
                        status: "Bereit"
                    },
                    fan: {
                        name: "MAXXFAN",
                        on: true,
                        speed: 45
                    }
                },
                power: {
                    inverter: {
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
                        on: false,
                        manualOn: false,
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
                            on: false,
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
                            on: false,
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

        function command(target, action, value, extra) {
        }
        function activateQuick(item) {
            window.quickCommandCount += 1;
        }
        function setQuickAccessIds(ids) {
            window.quickSettingsCount += 1;
        }
    }

    CamperHome {
        anchors.fill: parent
        visible: window.currentCamperPage === 0
        adapter: previewAdapter
        logoSource: "../../images/camper_logo.png"
        onOpenVictronSettings: window.settingsClickCount += 1
        onCloseRequested: window.closeClickCount += 1
        onPageRequested: page => {
            window.lastRequestedPage = page;
            window.currentCamperPage = page;
        }
        onEditQuickAccessRequested: window.currentCamperPage = 12
    }

    CamperLights {
        anchors.fill: parent
        visible: window.currentCamperPage === 1
        adapter: previewAdapter
        leftVehicleSource: "../../images/camper_vehicle_left.png"
        rightVehicleSource: "../../images/camper_vehicle_right.png"
        onPageRequested: page => {
            window.lastRequestedPage = page;
            window.currentCamperPage = page;
        }
    }

    CamperPower {
        anchors.fill: parent
        visible: window.currentCamperPage === 5
        adapter: previewAdapter
        onPageRequested: page => {
            window.lastRequestedPage = page;
            window.currentCamperPage = page;
        }
    }

    CamperDetails {
        anchors.fill: parent
        visible: window.currentCamperPage >= 6 && window.currentCamperPage <= 11
        adapter: previewAdapter
        detailPage: window.currentCamperPage
        onBackRequested: window.currentCamperPage = 0
        onPageRequested: page => window.currentCamperPage = page
    }

    CamperQuickAccess {
        anchors.fill: parent
        visible: window.currentCamperPage === 12
        adapter: previewAdapter
        logoSource: "../../images/camper_logo.png"
        onBackRequested: window.currentCamperPage = 0
        onPageRequested: page => {
            window.lastRequestedPage = page;
            if (page === 0)
                window.currentCamperPage = 0;
        }
    }
}
