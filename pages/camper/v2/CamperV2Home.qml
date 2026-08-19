pragma ComponentBehavior: Bound

import QtQuick
import "../../../components/camper/v2"

Item {
    id: root

    required property var adapter
    property bool dayMode: false
    signal pageRequested(int page)
    signal editQuickAccessRequested

    readonly property var snapshot: adapter.stateData || ({})
    readonly property var energy: snapshot.energy || ({})
    readonly property var battery: energy.battery || ({})
    readonly property var solar: energy.solar || ({})
    readonly property var indevolt: energy.indevolt || ({})
    readonly property var climate: snapshot.climate || ({})
    readonly property var automation: climate.automation || ({})
    readonly property var temperatureSensors: climate.temperatureSensors || ({})
    readonly property var comfortSensor: temperatureSensors.comfort || ({})
    readonly property var heater: climate.heater || ({})
    readonly property var fan: climate.fan || ({})
    readonly property var quickAccess: snapshot.ui && snapshot.ui.quickAccess ? snapshot.ui.quickAccess.slice(0, 4) : []

    CamperV2Style {
        id: style
        dayMode: root.dayMode
    }

    function valid(value) {
        return value !== null && value !== undefined && value !== "" && isFinite(Number(value));
    }

    function numberText(value, digits, suffix) {
        return valid(value) ? Number(value).toFixed(digits) + suffix : "–";
    }

    function solarTotal() {
        let total = 0;
        let available = false;
        if (root.adapter.hasSolarPower) {
            total += Number(root.adapter.solarPower);
            available = true;
        } else if (valid(root.solar.power)) {
            total += Number(root.solar.power);
            available = true;
        }
        if (valid(root.indevolt.solarPower)) {
            total += Number(root.indevolt.solarPower);
            available = true;
        }
        return available ? total : NaN;
    }

    function batterySoc() {
        return root.adapter.hasBatterySoc ? Number(root.adapter.batterySoc) : (valid(root.battery.soc) ? Number(root.battery.soc) : NaN);
    }

    function roomHumidity() {
        if (valid(root.comfortSensor.humidity))
            return Number(root.comfortSensor.humidity);
        return NaN;
    }

    function targetTemperature() {
        return valid(root.automation.targetTemperature) ? Number(root.automation.targetTemperature) : NaN;
    }

    function changeTarget(delta) {
        if (root.adapter.customCommandsAllowed !== true || !valid(root.automation.targetTemperature))
            return;
        root.adapter.command("settings", "patch", null, {
            patch: {
                climateAutomation: {
                    enabled: root.automation.enabled === true,
                    mode: root.automation.mode || "auto",
                    targetTemperature: Math.max(10, Math.min(30, Number(root.automation.targetTemperature) + delta)),
                    hysteresis: valid(root.automation.hysteresis) ? Number(root.automation.hysteresis) : 1,
                    fanSpeed: valid(root.automation.fanSpeed) ? Number(root.automation.fanSpeed) : 50
                }
            }
        });
    }

    function quickIcon(item) {
        const iconName = String(item && item.icon || "").toLowerCase();
        const itemId = String(item && item.id || "").toLowerCase();
        if (iconName.indexOf("pump") >= 0 || itemId.indexOf("water_pump") >= 0)
            return "pump";
        if (iconName.indexOf("satellite") >= 0 || itemId.indexOf("starlink") >= 0)
            return "satellite";
        if (iconName.indexOf("outlet") >= 0 || itemId.indexOf("outlets") >= 0)
            return "outlet";
        if (iconName.indexOf("fan") >= 0 || itemId.indexOf("maxxfan") >= 0)
            return "fan";
        if (iconName.indexOf("heater") >= 0 || itemId.indexOf("heater") >= 0)
            return "flame";
        if (itemId.indexOf("front_amber") >= 0)
            return "warningBar";
        if (itemId.indexOf("front_white") >= 0)
            return "lightBar";
        if (itemId.indexOf("outside_left") >= 0)
            return "workLightLeft";
        if (itemId.indexOf("outside_right") >= 0)
            return "workLightRight";
        if (itemId.indexOf("outside_rear") >= 0)
            return "rearLight";
        if (itemId.indexOf("inside") >= 0 || iconName.indexOf("bulb") >= 0)
            return "cabinLight";
        if (itemId.indexOf("inverter") >= 0)
            return "plug";
        return "energy";
    }

    CamperV2Card {
        x: 12
        y: 8
        width: 442
        height: 154
        dayMode: root.dayMode

        Rectangle {
            id: socGauge
            x: 14
            y: 25
            width: 104
            height: 104
            radius: 52
            color: "transparent"
            border.color: root.valid(root.batterySoc()) ? style.blue : style.inner
            border.width: 8

            Text {
                anchors.centerIn: parent
                text: root.numberText(root.batterySoc(), 0, "%")
                color: style.text
                font.pixelSize: 28
                font.bold: true
            }
        }

        Text {
            x: 136
            y: 14
            text: "Energie"
            color: style.text
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }

        Text {
            x: 14
            y: 133
            width: 104
            horizontalAlignment: Text.AlignHCenter
            text: root.numberText(root.adapter.hasBatteryVoltage ? root.adapter.batteryVoltage : root.battery.voltage, 2, " V")
            color: style.muted
            font.pixelSize: 9
        }

        Rectangle {
            x: 136
            y: 42
            width: 137
            height: 96
            radius: 14
            color: solarMouse.pressed ? style.pressed : style.inner

            CamperV2Icon {
                x: 48
                y: 8
                width: 40
                height: 40
                kind: "solar"
                lineColor: style.yellow
                strokeWidth: 1.7
            }
            Text {
                x: 0
                y: 49
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.numberText(root.solarTotal(), 0, " W")
                color: style.text
                font.pixelSize: 17
                font.bold: true
            }
            Text {
                x: 0
                y: 73
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "Solar gesamt"
                color: style.muted
                font.pixelSize: 9
            }
            MouseArea {
                id: solarMouse
                anchors.fill: parent
                onClicked: root.pageRequested(3)
            }
        }

        Rectangle {
            x: 281
            y: 42
            width: 147
            height: 96
            radius: 14
            color: style.inner

            CamperV2Icon {
                x: 53
                y: 8
                width: 40
                height: 40
                kind: "battery"
                lineColor: style.blue
                strokeWidth: 1.7
            }
            Text {
                x: 0
                y: 49
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.numberText(root.battery.power, 0, " W")
                color: style.text
                font.pixelSize: 17
                font.bold: true
            }
            Text {
                x: 0
                y: 73
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "Batterieleistung"
                color: style.muted
                font.pixelSize: 9
            }
        }
    }

    CamperV2Card {
        x: 463
        y: 8
        width: 325
        height: 154
        dayMode: root.dayMode
        active: root.automation.enabled === true
        accent: style.orange

        Text {
            x: 13
            y: 10
            text: "Klimaautomatik"
            color: style.text
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }

        Text {
            x: 13
            y: 34
            text: root.numberText(root.climate.roomTemperature, 1, "°")
            color: style.text
            font.pixelSize: 31
            font.bold: true
        }

        Text {
            x: 13
            y: 72
            text: root.valid(root.roomHumidity()) ? root.numberText(root.roomHumidity(), 0, " % rF") : ""
            color: style.muted
            font.pixelSize: 10
        }

        Row {
            x: 13
            y: 94
            spacing: 8

            Rectangle {
                width: 92
                height: 23
                radius: 11
                color: root.heater.on === true ? "#382314" : style.inner
                CamperV2Icon {
                    x: 7
                    y: 4
                    width: 15
                    height: 15
                    kind: "flame"
                    lineColor: root.heater.on === true ? style.orange : style.muted
                    strokeWidth: 1.4
                }
                Text {
                    x: 28
                    y: 0
                    width: 59
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    text: "Autoterm"
                    color: root.heater.on === true ? style.orange : style.muted
                    font.pixelSize: 9
                }
            }
            Rectangle {
                width: 88
                height: 23
                radius: 11
                color: root.fan.on === true ? style.selectedBlue : style.inner
                CamperV2Icon {
                    x: 7
                    y: 4
                    width: 15
                    height: 15
                    kind: "fan"
                    lineColor: root.fan.on === true ? style.blue : style.muted
                    strokeWidth: 1.4
                }
                Text {
                    x: 28
                    y: 0
                    width: 55
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    text: "MaxxFan"
                    color: root.fan.on === true ? style.blue : style.muted
                    font.pixelSize: 9
                }
            }
        }

        Rectangle {
            x: 208
            y: 38
            width: 42
            height: 42
            radius: 21
            color: minusMouse.pressed ? style.pressed : style.inner
            opacity: root.valid(root.targetTemperature()) ? 1 : 0.5
            Text {
                anchors.centerIn: parent
                text: "−"
                color: style.text
                font.pixelSize: 24
            }
            MouseArea {
                id: minusMouse
                anchors.fill: parent
                enabled: root.adapter.customCommandsAllowed === true && root.valid(root.targetTemperature())
                onClicked: root.changeTarget(-1)
            }
        }

        Text {
            x: 250
            y: 34
            width: 33
            height: 50
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: root.numberText(root.targetTemperature(), 0, "°")
            color: style.text
            font.pixelSize: 16
            font.bold: true
        }

        Rectangle {
            x: 281
            y: 38
            width: 42
            height: 42
            radius: 21
            color: plusMouse.pressed ? style.pressed : style.inner
            opacity: root.valid(root.targetTemperature()) ? 1 : 0.5
            Text {
                anchors.centerIn: parent
                text: "+"
                color: style.text
                font.pixelSize: 22
            }
            MouseArea {
                id: plusMouse
                anchors.fill: parent
                enabled: root.adapter.customCommandsAllowed === true && root.valid(root.targetTemperature())
                onClicked: root.changeTarget(1)
            }
        }

        MouseArea {
            x: 0
            y: 0
            width: 196
            height: parent.height
            onClicked: root.pageRequested(2)
        }
    }

    CamperV2Card {
        x: 12
        y: 171
        width: 776
        height: 169
        dayMode: root.dayMode

        Text {
            x: 13
            y: 9
            text: "Schnellzugriff"
            color: style.text
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }

        Text {
            x: 690
            y: 8
            width: 72
            height: 22
            horizontalAlignment: Text.AlignRight
            text: "Anpassen"
            color: style.blue
            font.pixelSize: 10
            font.weight: Font.DemiBold
            MouseArea {
                anchors.fill: parent
                onClicked: root.editQuickAccessRequested()
            }
        }

        Row {
            x: 10
            y: 36
            spacing: 8

            Repeater {
                model: root.quickAccess

                delegate: Rectangle {
                    required property var modelData
                    readonly property bool isActive: modelData.active === true
                    readonly property bool isAvailable: modelData.available !== false

                    width: 183
                    height: 120
                    radius: 15
                    color: isActive ? style.selectedBlue : style.panel
                    border.color: isActive ? style.blue : style.border
                    border.width: isActive ? 2 : 1
                    opacity: isAvailable ? 1 : 0.55

                    Rectangle {
                        x: 12
                        y: 42
                        width: 36
                        height: 36
                        radius: 11
                        color: parent.isActive ? (root.dayMode ? "#d6f1fb" : "#14384b") : style.inner

                        CamperV2Icon {
                            anchors.centerIn: parent
                            width: 20
                            height: 20
                            kind: root.quickIcon(parent.parent.modelData)
                            lineColor: parent.parent.isActive ? style.blue : style.muted
                            strokeWidth: 1.8
                        }
                    }
                    Text {
                        x: 59
                        y: 39
                        width: 112
                        height: 42
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        text: parent.modelData.name || "Schnellzugriff"
                        color: style.text
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: root.adapter.customCommandsAllowed === true && parent.isAvailable
                        onClicked: root.adapter.activateQuick(parent.modelData)
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: root.quickAccess.length === 0
            text: root.adapter.customReadConnected === true ? "Noch kein Schnellzugriff gewählt" : "Camper-Backend nicht verbunden"
            color: style.muted
            font.pixelSize: 12
        }
    }
}
