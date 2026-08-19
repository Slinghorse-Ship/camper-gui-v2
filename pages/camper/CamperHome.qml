/*
** Phase-2 Camper Home.
** Geometry, colors and interaction sizes are ported from Ford SYNC v3.9.9.
*/

import QtQuick
import "../../components/camper"

Item {
    id: root

    required property var adapter
    property url logoSource: "qrc:/images/camper_logo.png"
    property url v2LogoSource: "qrc:/images/camper_transit_line_dark.png"
    signal openVictronSettings
    signal closeRequested
    signal pageRequested(int page)
    signal editQuickAccessRequested

    readonly property var snapshot: adapter.stateData || ({})
    readonly property var water: snapshot.water || ({})
    readonly property var fresh: water.fresh || ({})
    readonly property var climate: snapshot.climate || ({})
    readonly property var heater: climate.heater || ({})
    readonly property var fan: climate.fan || ({})
    readonly property var power: snapshot.power || ({})
    readonly property var inverter: power.inverter || ({})
    readonly property bool customReadConnected: adapter.customReadConnected === true
    readonly property bool customConnected: adapter.customConnected === true

    readonly property bool dayMode: false
    readonly property color background: visual.backgroundBottom
    readonly property color panel: visual.panel
    readonly property color inner: visual.inner
    readonly property color textColor: visual.text
    readonly property color muted: visual.muted
    readonly property color line: visual.border
    readonly property color blue: visual.blue
    readonly property color green: visual.green
    readonly property color orange: visual.orange

    width: 800
    height: 480

    CamperStyle {
        id: visual
        dayMode: root.dayMode
    }

    function fmt(value, digits, suffix) {
        if (value === null || value === undefined || value === "" || !isFinite(Number(value))) {
            return "–";
        }
        return Number(value).toFixed(digits) + (suffix || "");
    }

    function quickItems() {
        const items = snapshot.ui && snapshot.ui.quickAccess;
        return items && items.length ? items : [];
    }

    function quickIconKind(item) {
        const kinds = {
            "bulb": "cabinLight",
            "right-light": "workLightRight",
            "down-light": "rearLight",
            "left-light": "workLightLeft",
            "lightbar": "lightBar",
            "warningbar": "warningBar",
            "highbeam": "highBeam",
            "outlet": "outlet",
            "pump": "pump",
            "satellite": "satellite",
            "fan": "fan",
            "plug": "plug",
            "heater": "climate",
            "battery": "battery",
            "home": "scenes"
        };
        return kinds[item.icon] || "power";
    }

    Rectangle {
        anchors.fill: parent
        color: root.background
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: visual.backgroundTop
            }
            GradientStop {
                position: 1.0
                color: visual.backgroundBottom
            }
        }
    }

    CamperPageHeader {
        width: 800
        height: 58
        pageTitle: "HOME"
        logoSource: root.logoSource
        v2LogoSource: root.v2LogoSource
        connected: root.customReadConnected
        onOpenVictronSettings: {
            if (visual.designV2)
                root.pageRequested(13);
            else
                root.openVictronSettings();
        }
        onCloseRequested: root.closeRequested()
    }

    Item {
        x: 0
        y: 58
        width: 800
        height: 364

        CamperMetricTile {
            x: 10
            y: 10
            width: 188
            height: 88
            dayMode: root.dayMode
            icon: "battery"
            caption: "SMARTSHUNT"
            value: root.fmt(root.adapter.batterySoc, 0, " %")
            detail: root.adapter.hasBatteryVoltage ? "SYSTEM " + root.fmt(root.adapter.batteryVoltage, 1, " V") : "VICTRON BATTERIE"
            active: root.adapter.hasBatterySoc
            accentColor: root.blue
            onClicked: root.pageRequested(8)
        }
        CamperMetricTile {
            x: 207
            y: 10
            width: 188
            height: 88
            dayMode: root.dayMode
            icon: "solar"
            caption: "SOLAR GESAMT"
            value: root.fmt(root.adapter.solarPower, 0, " W")
            detail: root.adapter.hasSolarPower ? "VICTRON SYSTEM" : "KEINE VICTRON DATEN"
            active: root.adapter.hasSolarPower && root.adapter.solarPower > 0
            accentColor: root.blue
            onClicked: root.pageRequested(7)
        }
        CamperMetricTile {
            x: 404
            y: 10
            width: 188
            height: 88
            dayMode: root.dayMode
            icon: "water"
            caption: "FRISCHWASSER"
            value: root.fmt(root.fresh.level, 0, " %")
            detail: root.fmt(root.fresh.remainingLitres, 0, " LITER")
            active: root.customReadConnected && Number(root.fresh.level || 0) > 0
            accentColor: root.blue
            onClicked: root.pageRequested(11)
        }
        CamperMetricTile {
            x: 601
            y: 10
            width: 189
            height: 88
            dayMode: root.dayMode
            icon: "climate"
            caption: "INNENRAUM"
            value: root.fmt(root.climate.roomTemperature, 1, " °C")
            detail: "INNENTEMPERATUR"
            active: root.customReadConnected && isFinite(Number(root.climate.roomTemperature))
            accentColor: root.blue
            onClicked: root.pageRequested(10)
        }

        Rectangle {
            x: 10
            y: 108
            width: 384
            height: 118
            radius: 15
            color: root.panel
            border.color: root.heater.on === true ? root.orange : root.line

            CamperLineIcon {
                x: 20
                y: 20
                width: 34
                height: 34
                kind: "climate"
                lineColor: root.heater.on === true ? root.orange : root.muted
                strokeWidth: 1.9
            }
            Text {
                x: 72
                y: 14
                width: 180
                elide: Text.ElideRight
                text: "AUTOTERM AIR 2D"
                color: root.textColor
                font.pixelSize: 14
                font.bold: true
            }
            Text {
                x: 72
                y: 38
                text: root.customReadConnected ? root.fmt(root.heater.setpoint, 0, " °C SOLL") + "  |  " + (root.heater.status || "keine Daten") : "NICHT VERBUNDEN"
                color: root.muted
                font.pixelSize: 10
            }
            MouseArea {
                x: 8
                y: 8
                width: 250
                height: 53
                onClicked: root.pageRequested(6)
            }
            CamperTouchButton {
                x: 268
                y: 12
                width: 100
                height: 42
                enabled: root.customConnected && root.heater.cooling !== true
                label: root.heater.on === true ? "STOPP" : "START"
                active: root.heater.on === true
                accentColor: root.orange
                onClicked: root.adapter.command("heater", root.heater.on === true ? "stop" : "start", null, ({}))
            }
            Rectangle {
                x: 16
                y: 72
                width: 352
                height: 1
                color: root.line
            }
            Text {
                x: 16
                y: 87
                text: root.fan.name || "MAXXFAN"
                color: root.textColor
                font.pixelSize: 10
                font.bold: true
            }
            CamperLineIcon {
                x: 112
                y: 81
                width: 25
                height: 25
                kind: "fan"
                lineColor: root.fan.on === true ? root.blue : root.muted
                strokeWidth: 1.8
            }
            Text {
                x: 145
                y: 87
                text: root.fmt(root.fan.speed, 0, " %")
                color: root.textColor
                font.pixelSize: 11
                font.bold: true
            }
            MouseArea {
                x: 8
                y: 76
                width: 250
                height: 40
                onClicked: root.pageRequested(9)
            }
            CamperTouchButton {
                x: 268
                y: 77
                width: 100
                height: 36
                enabled: root.customConnected
                label: root.fan.on === true ? "AUSSCHALTEN" : "EINSCHALTEN"
                active: root.fan.on === true
                fontSize: 10
                onClicked: root.adapter.command("maxxfan", "set", root.fan.on !== true, ({}))
            }
        }

        Rectangle {
            x: 404
            y: 108
            width: 386
            height: 118
            radius: 15
            color: root.panel
            border.color: root.line

            CamperLineIcon {
                x: 20
                y: 20
                width: 34
                height: 34
                kind: "pump"
                lineColor: root.water.pump && root.water.pump.on === true ? root.blue : root.muted
                strokeWidth: 1.9
            }
            Text {
                x: 72
                y: 14
                text: "WASSERPUMPE"
                color: root.textColor
                font.pixelSize: 14
                font.bold: true
            }
            Text {
                x: 72
                y: 38
                text: root.customReadConnected ? (root.water.pump && root.water.pump.on === true ? "EINGESCHALTET" : "AUSGESCHALTET") : "NICHT VERBUNDEN"
                color: root.muted
                font.pixelSize: 10
            }
            CamperTouchButton {
                x: 270
                y: 12
                width: 100
                height: 42
                enabled: root.customConnected
                label: root.water.pump && root.water.pump.on === true ? "AUSSCHALTEN" : "EINSCHALTEN"
                active: root.water.pump ? root.water.pump.on === true : false
                fontSize: 10
                onClicked: root.adapter.command("waterPump", "set", !(root.water.pump && root.water.pump.on === true), ({}))
            }
            Rectangle {
                x: 16
                y: 72
                width: 354
                height: 1
                color: root.line
            }
            Text {
                x: 16
                y: 87
                text: "MULTIPLUS COMPACT"
                color: root.textColor
                font.pixelSize: 11
                font.bold: true
            }
            Text {
                x: 168
                y: 87
                text: root.fmt(root.inverter.outputPower, 0, " W")
                color: root.muted
                font.pixelSize: 10
            }
            CamperTouchButton {
                x: 270
                y: 77
                width: 100
                height: 36
                enabled: root.customConnected
                label: root.inverter.on === true ? "230 V AUS" : "230 V AN"
                active: root.inverter.on === true
                accentColor: visual.purple
                onClicked: root.adapter.command("inverter", "set", root.inverter.on !== true, ({}))
            }
        }

        Rectangle {
            x: 10
            y: 236
            width: 780
            height: 116
            radius: 15
            color: root.panel
            border.color: root.line

            Text {
                x: 16
                y: 12
                text: "SCHNELLZUGRIFF"
                color: root.muted
                font.pixelSize: 9
                font.bold: true
            }
            Text {
                x: 675
                y: 10
                width: 88
                horizontalAlignment: Text.AlignRight
                text: "ANPASSEN ›"
                color: root.blue
                font.pixelSize: 9
                font.bold: true
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.editQuickAccessRequested()
                }
            }
            Repeater {
                model: root.quickItems()
                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    x: 14 + index * 190
                    y: 34
                    width: 180
                    height: 68
                    radius: 12
                    opacity: modelData.available === true ? 1.0 : 0.52
                    color: modelData.active === true ? (root.dayMode ? "#dff4ed" : "#15342d") : root.inner
                    border.color: modelData.active === true ? root.green : root.line

                    CamperLineIcon {
                        x: 73
                        y: 3
                        width: 32
                        height: 32
                        kind: root.quickIconKind(modelData)
                        lineColor: modelData.active === true ? (modelData.icon === "warningbar" ? root.orange : root.green) : root.muted
                        strokeWidth: 1.8
                    }
                    Text {
                        x: 10
                        y: 39
                        width: 160
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: modelData.name
                        color: root.textColor
                        font.pixelSize: 9
                        font.bold: true
                    }
                    Text {
                        x: 10
                        y: 54
                        width: 160
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: modelData.status || ""
                        color: root.muted
                        font.pixelSize: 7
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: root.customConnected && modelData.available === true
                        onClicked: root.adapter.activateQuick(modelData)
                    }
                }
            }
        }
    }

    CamperNavBar {
        x: 0
        y: 422
        width: 800
        height: 58
        dayMode: root.dayMode
        currentPage: 0
        lineColor: root.line
        primaryText: root.textColor
        accentColor: root.blue
        onPageRequested: page => root.pageRequested(page)
    }
}
