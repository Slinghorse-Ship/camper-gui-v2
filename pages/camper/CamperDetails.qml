import QtQuick
import "../../components/camper"

Item {
    id: root

    required property var adapter
    required property int detailPage
    signal backRequested
    signal openVictronSettings
    signal closeRequested
    signal pageRequested(int page)

    readonly property var snapshot: adapter.stateData || ({})
    readonly property var energy: snapshot.energy || ({})
    readonly property var climate: snapshot.climate || ({})
    readonly property string pageTitle: {
        if (detailPage === 6)
            return "AUTOTERM AIR 2D";
        if (detailPage === 7)
            return "ENERGIEQUELLEN";
        if (detailPage === 8)
            return "BATTERIEN";
        if (detailPage === 9)
            return "MAXXFAN";
        if (detailPage === 11)
            return "WASSER";
        return "TEMPERATUR";
    }

    CamperStyle {
        id: visual
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop {
                position: 0
                color: visual.backgroundTop
            }
            GradientStop {
                position: 1
                color: visual.backgroundBottom
            }
        }
    }

    CamperPageHeader {
        width: 800
        height: 56
        pageTitle: root.pageTitle
        connected: root.adapter.customConnected === true
        onOpenVictronSettings: root.openVictronSettings()
        onCloseRequested: root.closeRequested()
    }

    CamperHeaterDetails {
        x: 0
        y: 56
        width: 800
        height: 424
        visible: root.detailPage === 6
        transform: Scale {
            origin.x: 0
            origin.y: 0
            yScale: 366 / 424
        }
        adapter: root.adapter
        climate: root.climate
        onBackRequested: root.backRequested()
    }

    CamperEnergySolarDetails {
        x: 0
        y: 56
        width: 800
        height: 424
        visible: root.detailPage === 7
        transform: Scale {
            origin.x: 0
            origin.y: 0
            yScale: 366 / 424
        }
        solar: root.energy.solar || ({})
        indevolt: root.energy.indevolt || ({})
        orion: root.energy.orion || ({})
        onBackRequested: root.backRequested()
        onOrionCommandRequested: enabledState => root.adapter.command("orion", "set", enabledState, ({}))
        onIndevoltGridCommandRequested: enabledState => root.adapter.command("indevoltGrid", "set", enabledState, ({}))
    }

    CamperBatteryDetails {
        x: 0
        y: 56
        width: 800
        height: 424
        visible: root.detailPage === 8
        transform: Scale {
            origin.x: 0
            origin.y: 0
            yScale: 366 / 424
        }
        battery: root.energy.battery || ({})
        onBackRequested: root.backRequested()
    }

    CamperMaxxFanDetails {
        x: 0
        y: 56
        width: 800
        height: 424
        visible: root.detailPage === 9
        transform: Scale {
            origin.x: 0
            origin.y: 0
            yScale: 366 / 424
        }
        fan: root.climate.fan || ({})
        onBackRequested: root.backRequested()
        onCommandRequested: (action, value) => root.adapter.command("maxxfan", action, value, ({}))
    }

    CamperTemperatureDetails {
        x: 0
        y: 56
        width: 800
        height: 424
        visible: root.detailPage === 10
        transform: Scale {
            origin.x: 0
            origin.y: 0
            yScale: 366 / 424
        }
        climate: root.climate
        heater: root.climate.heater || ({})
        temperatureSensors: root.climate.temperatureSensors || []
        onBackRequested: root.backRequested()
        onVentilationPatchRequested: patch => root.adapter.command("settings", "patch", null, {
                patch: patch
            })
        onClimateAutomationPatchRequested: patch => root.adapter.command("settings", "patch", null, {
                patch: patch
            })
        onTemperatureSensorPatchRequested: patch => root.adapter.command("settings", "patch", null, {
                patch: patch
            })
    }

    CamperWaterDetails {
        x: 0
        y: 56
        width: 800
        height: 424
        visible: root.detailPage === 11
        transform: Scale {
            origin.x: 0
            origin.y: 0
            yScale: 366 / 424
        }
        adapter: root.adapter
        water: root.snapshot.water || ({})
        onBackRequested: root.backRequested()
    }

    CamperNavBar {
        x: 0
        y: 422
        width: 800
        height: 58
        currentPage: 0
        onPageRequested: page => root.pageRequested(page)
    }
}
