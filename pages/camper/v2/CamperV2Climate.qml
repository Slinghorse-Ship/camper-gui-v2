pragma ComponentBehavior: Bound

import QtQuick
import "../../../components/camper/v2"

Item {
    id: root

    required property var adapter
    property bool dayMode: false
    property bool runtimeOptionsVisible: false

    readonly property var snapshot: adapter.stateData || ({})
    readonly property var climate: snapshot.climate || ({})
    readonly property var automation: climate.automation || ({})
    readonly property var heater: climate.heater || ({})
    readonly property var fan: climate.fan || ({})

    CamperV2Style {
        id: style
        dayMode: root.dayMode
    }

    function valid(value) {
        return value !== null && value !== undefined && value !== "" && isFinite(Number(value));
    }

    function fmt(value, digits, suffix) {
        return valid(value) ? Number(value).toFixed(digits) + suffix : "–";
    }

    function controlMode() {
        const mode = String(root.automation.controlMode || "");
        return ["off", "manual", "auto"].indexOf(mode) >= 0 ? mode : (root.automation.enabled === true ? "auto" : "manual");
    }

    function setControlMode(mode) {
        if (root.adapter.customCommandsAllowed !== true || ["off", "manual", "auto"].indexOf(mode) < 0)
            return;
        root.adapter.command("settings", "patch", null, {
            patch: {
                climateAutomation: {
                    controlMode: mode
                }
            }
        });
    }

    function climatePatch(delta) {
        if (adapter.customCommandsAllowed !== true || !valid(automation.targetTemperature))
            return;
        adapter.command("settings", "patch", null, {
            patch: {
                climateAutomation: {
                    targetTemperature: Math.max(10, Math.min(30, Number(automation.targetTemperature) + delta))
                }
            }
        });
    }

    function setHeaterSetting(key, value) {
        if (adapter.customCommandsAllowed !== true)
            return;
        adapter.command("heater", "setting", value, {
            key: key
        });
    }

    CamperV2Card {
        x: 12
        y: 8
        width: 211
        height: 322
        dayMode: root.dayMode
        active: root.controlMode() !== "off"
        accent: root.controlMode() === "auto" ? style.orange : style.blue

        Text {
            x: 14
            y: 12
            text: "Komfort"
            color: style.text
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
        Row {
            x: 10
            y: 158
            spacing: 4

            Repeater {
                model: [
                    {
                        mode: "off",
                        label: "Aus"
                    },
                    {
                        mode: "manual",
                        label: "Manuell"
                    },
                    {
                        mode: "auto",
                        label: "Automatik"
                    }
                ]

                delegate: Rectangle {
                    id: modeButton
                    required property var modelData
                    readonly property bool selected: root.controlMode() === modelData.mode

                    width: 61
                    height: 34
                    radius: 10
                    color: modeArea.pressed ? style.pressed : (selected ? (modelData.mode === "auto" ? "#382314" : style.selectedBlue) : style.inner)
                    border.color: selected ? (modelData.mode === "auto" ? style.orange : style.blue) : style.border
                    opacity: root.adapter.customCommandsAllowed === true ? 1 : .55

                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData.label
                        color: parent.selected ? (parent.modelData.mode === "auto" ? style.orange : style.blue) : style.muted
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                    }
                    MouseArea {
                        id: modeArea
                        anchors.fill: parent
                        enabled: root.adapter.customCommandsAllowed === true
                        onClicked: root.setControlMode(modeButton.modelData.mode)
                    }
                }
            }
        }
        Text {
            x: 0
            y: 66
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.fmt(root.automation.targetTemperature, 0, "°")
            color: style.text
            font.pixelSize: 45
            font.bold: true
        }
        Text {
            x: 0
            y: 124
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.valid(root.climate.roomTemperature) ? root.fmt(root.climate.roomTemperature, 1, "° innen") : ""
            color: style.muted
            font.pixelSize: 10
        }
        Rectangle {
            x: 15
            y: 206
            width: 54
            height: 54
            radius: 27
            color: comfortMinus.pressed ? style.pressed : style.inner
            opacity: root.valid(root.automation.targetTemperature) ? 1 : .5
            Text {
                anchors.centerIn: parent
                text: "−"
                color: style.text
                font.pixelSize: 27
            }
            MouseArea {
                id: comfortMinus
                anchors.fill: parent
                enabled: root.adapter.customCommandsAllowed === true && root.valid(root.automation.targetTemperature)
                onClicked: root.climatePatch(-1)
            }
        }
        Text {
            x: 73
            y: 206
            width: 65
            height: 54
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: "Soll"
            color: style.muted
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }
        Rectangle {
            x: 142
            y: 206
            width: 54
            height: 54
            radius: 27
            color: comfortPlus.pressed ? style.pressed : style.inner
            opacity: root.valid(root.automation.targetTemperature) ? 1 : .5
            Text {
                anchors.centerIn: parent
                text: "+"
                color: style.text
                font.pixelSize: 25
            }
            MouseArea {
                id: comfortPlus
                anchors.fill: parent
                enabled: root.adapter.customCommandsAllowed === true && root.valid(root.automation.targetTemperature)
                onClicked: root.climatePatch(1)
            }
        }
        Rectangle {
            x: 82
            y: 285
            width: 47
            height: 9
            radius: 5
            color: root.controlMode() === "auto" ? style.orange : (root.controlMode() === "manual" ? style.blue : style.inner)
        }
    }

    CamperV2Card {
        x: 232
        y: 8
        width: 276
        height: 322
        dayMode: root.dayMode
        active: root.heater.on === true
        available: root.adapter.customConnected === true && root.heater.online === true
        accent: style.orange

        Text {
            x: 14
            y: 12
            text: "Autoterm"
            color: style.text
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
        Text {
            x: 0
            y: 43
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.heater.mode === "power" ? root.fmt(root.heater.powerLevel, 0, " / 10") : (root.heater.mode === "ventilation" ? "Lüften" : root.fmt(root.heater.setpoint, 0, "°"))
            color: style.orange
            font.pixelSize: 35
            font.bold: true
        }
        Text {
            x: 193
            y: 72
            text: root.heater.mode === "temperature" ? "Soll" : ""
            color: style.orange
            font.pixelSize: 9
        }

        Row {
            x: 9
            y: 102
            spacing: 4

            Repeater {
                model: [
                    {
                        mode: "temperature",
                        label: "Temperatur"
                    },
                    {
                        mode: "power",
                        label: "Leistung"
                    },
                    {
                        mode: "ventilation",
                        label: "Lüften"
                    }
                ]
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool selected: root.heater.mode === modelData.mode
                    width: 83
                    height: 37
                    radius: 10
                    color: selected ? "#382314" : style.inner
                    border.color: selected ? style.orange : style.border
                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData.label
                        color: parent.selected ? style.orange : style.text
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: root.adapter.customCommandsAllowed === true && root.heater.online === true
                        onClicked: root.setHeaterSetting("mode", parent.modelData.mode)
                    }
                }
            }
        }

        Rectangle {
            x: 9
            y: 149
            width: 258
            height: 37
            radius: 10
            color: runtimeArea.pressed ? style.pressed : style.inner
            CamperV2Icon {
                x: 11
                y: 8
                width: 21
                height: 21
                kind: "clock"
                lineColor: style.muted
                strokeWidth: 1.5
            }
            Text {
                x: 41
                y: 0
                width: 205
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                text: Number(root.heater.durationMinutes || 0) > 0 ? Number(root.heater.durationMinutes) + " min" : "Zeitlimit hinzufügen"
                color: style.text
                font.pixelSize: 9
                font.weight: Font.DemiBold
            }
            MouseArea {
                id: runtimeArea
                anchors.fill: parent
                onClicked: root.runtimeOptionsVisible = !root.runtimeOptionsVisible
            }
        }

        Row {
            x: 9
            y: 192
            spacing: 4
            visible: root.runtimeOptionsVisible

            Repeater {
                model: [
                    {
                        value: 0,
                        label: "Ohne"
                    },
                    {
                        value: 30,
                        label: "30 min"
                    },
                    {
                        value: 60,
                        label: "60 min"
                    },
                    {
                        value: 120,
                        label: "2 h"
                    }
                ]
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool selected: Number(root.heater.durationMinutes || 0) === modelData.value
                    width: 61
                    height: 34
                    radius: 9
                    color: selected ? "#382314" : style.inner
                    border.color: selected ? style.orange : style.border
                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData.label
                        color: parent.selected ? style.orange : style.text
                        font.pixelSize: 8
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.setHeaterSetting("duration", parent.modelData.value);
                            root.runtimeOptionsVisible = false;
                        }
                    }
                }
            }
        }

        Rectangle {
            x: 9
            y: root.runtimeOptionsVisible ? 239 : 208
            width: 258
            height: 55
            radius: 13
            color: root.heater.on === true ? "#382314" : style.inner
            border.color: root.heater.on === true ? style.orange : style.border
            Text {
                anchors.centerIn: parent
                text: root.heater.cooling === true ? "Nachlauf" : (root.heater.on === true ? "Stoppen" : "Starten")
                color: root.heater.on === true ? style.orange : style.text
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }
            MouseArea {
                anchors.fill: parent
                enabled: root.adapter.customCommandsAllowed === true && root.heater.online === true && root.heater.cooling !== true && (root.heater.on === true || !root.heater.startBlocked)
                onClicked: root.adapter.command("heater", root.heater.on === true ? "stop" : "start", null, ({}))
            }
        }
    }

    CamperV2Card {
        x: 517
        y: 8
        width: 271
        height: 322
        dayMode: root.dayMode
        active: root.fan.on === true
        available: root.adapter.customConnected === true && root.fan.online === true
        accent: style.blue

        Text {
            x: 14
            y: 12
            text: "MaxxFan"
            color: style.text
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
        Text {
            x: 0
            y: 43
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.fmt(fanRange.shownValue, 0, " %")
            color: root.fan.on === true ? style.blue : style.text
            font.pixelSize: 35
            font.bold: true
        }
        CamperV2Range {
            id: fanRange
            x: 14
            y: 99
            width: 243
            height: 38
            dayMode: root.dayMode
            value: root.valid(root.fan.selectedSpeed) ? Math.max(0, Math.min(100, Math.round(Number(root.fan.selectedSpeed) / 10) * 10))
                    : (root.valid(root.fan.speed) ? Math.max(0, Math.min(100, Math.round(Number(root.fan.speed) / 10) * 10)) : 0)
            stepSize: 10
            holdUntilConfirmed: true
            available: root.adapter.customCommandsAllowed === true && root.fan.online === true
            accent: style.blue
            onCommitted: value => root.adapter.command("maxxfan", "speed", value, ({}))
        }

        Row {
            x: 9
            y: 150
            spacing: 4

            Repeater {
                model: [
                    {
                        mode: "forward",
                        label: "Abluft"
                    },
                    {
                        mode: "reverse",
                        label: "Zuluft"
                    }
                ]
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool selected: root.fan.mode === modelData.mode
                    width: 124
                    height: 39
                    radius: 10
                    color: selected ? style.selectedBlue : style.inner
                    border.color: selected ? style.blue : style.border
                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData.label
                        color: parent.selected ? style.blue : style.text
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: root.adapter.customCommandsAllowed === true && root.fan.online === true
                        onClicked: root.adapter.command("maxxfan", "mode", parent.modelData.mode, ({}))
                    }
                }
            }
        }

        Rectangle {
            x: 9
            y: 225
            width: 253
            height: 57
            radius: 13
            color: root.fan.on === true ? style.selectedBlue : style.inner
            border.color: root.fan.on === true ? style.blue : style.border
            Text {
                anchors.centerIn: parent
                text: root.fan.on === true ? "Ausschalten" : "Einschalten"
                color: root.fan.on === true ? style.blue : style.text
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }
            MouseArea {
                anchors.fill: parent
                enabled: root.adapter.customCommandsAllowed === true && root.fan.online === true
                onClicked: root.adapter.command("maxxfan", "set", root.fan.on !== true, ({}))
            }
        }
    }
}
