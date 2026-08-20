pragma ComponentBehavior: Bound

import QtQuick
import "../../../components/camper/v2"

Item {
    id: root

    required property var adapter
    property bool dayMode: false
    property int energyPane: 0

    readonly property var snapshot: adapter.stateData || ({})
    readonly property var energy: snapshot.energy || ({})
    readonly property var solar: energy.solar || ({})
    readonly property var chargers: solar.chargers && Array.isArray(solar.chargers) ? solar.chargers.slice(0, 8) : []
    readonly property var indevolt: energy.indevolt || ({})
    readonly property var orion: energy.orion || ({})
    readonly property var power: snapshot.power || ({})
    readonly property var inverter: power.inverter || ({})
    readonly property var dcChannels: power.dcChannels && Array.isArray(power.dcChannels) ? power.dcChannels.slice(0, 16) : []

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

    function findChannel(channelId, channelNumber) {
        for (let index = 0; index < dcChannels.length; ++index) {
            const candidate = dcChannels[index];
            if (candidate.id === channelId || Number(candidate.channel) === channelNumber)
                return candidate;
        }
        return {
            id: channelId,
            name: channelId,
            channel: 0,
            on: false,
            available: false
        };
    }

    function channelAvailable(channel) {
        return adapter.customCommandsAllowed === true && Number(channel && channel.channel || 0) > 0;
    }

    function solarTotal() {
        let total = 0;
        let available = false;
        if (valid(solar.power)) {
            total += Number(solar.power);
            available = true;
        } else if (adapter.hasSolarPower) {
            total += Number(adapter.solarPower);
            available = true;
        }
        if (valid(indevolt.solarPower)) {
            total += Number(indevolt.solarPower);
            available = true;
        }
        return available ? total : NaN;
    }

    function yieldToday() {
        let total = 0;
        let available = false;
        for (let index = 0; index < chargers.length; ++index) {
            if (valid(chargers[index].yieldTodayKwh)) {
                total += Number(chargers[index].yieldTodayKwh);
                available = true;
            }
        }
        return available ? total : NaN;
    }

    readonly property var channelModels: [
        {
            id: "dc_outlets_left",
            channel: 1,
            name: "Links",
            icon: "outlet"
        },
        {
            id: "water_pump",
            channel: 2,
            name: "Wasserpumpe",
            icon: "pump"
        },
        {
            id: "dc_outlets_right",
            channel: 4,
            name: "Rechts",
            icon: "outlet"
        },
        {
            id: "starlink",
            channel: 5,
            name: "Starlink",
            icon: "satellite"
        },
        {
            id: "maxxfan_power",
            channel: 6,
            name: "MaxxFan",
            icon: "fan"
        }
    ]

    Rectangle {
        x: 12
        y: 8
        width: 290
        height: 40
        radius: 12
        color: style.inner

        Row {
            anchors.fill: parent
            anchors.margins: 3
            spacing: 4

            Repeater {
                model: [
                    {
                        pane: 0,
                        label: "12 V & 230 V"
                    },
                    {
                        pane: 1,
                        label: "Quellen"
                    }
                ]
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool selected: root.energyPane === modelData.pane || (root.energyPane === 2 && modelData.pane === 1)
                    width: 140
                    height: 34
                    radius: 10
                    color: selected ? style.panel : "transparent"
                    border.color: selected ? style.border : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData.label
                        color: parent.selected ? style.text : style.muted
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.energyPane = parent.modelData.pane
                    }
                }
            }
        }
    }

    Item {
        x: 12
        y: 56
        width: 776
        height: 274
        visible: root.energyPane === 0

        CamperV2Card {
            x: 0
            y: 0
            width: 502
            height: 274
            dayMode: root.dayMode

            Repeater {
                model: root.channelModels
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    readonly property var channelData: root.findChannel(modelData.id, modelData.channel)
                    readonly property bool isActive: channelData.on === true
                    readonly property bool isAvailable: root.channelAvailable(channelData)

                    x: index < 3 ? 9 + index * 163 : 90 + (index - 3) * 163
                    y: index < 3 ? 9 : 142
                    width: 156
                    height: 123
                    radius: 15
                    color: isActive ? style.selectedGreen : style.inner
                    border.color: isActive ? style.green : style.border
                    border.width: isActive ? 2 : 1
                    opacity: isAvailable ? 1 : .52
                    Rectangle {
                        x: 12
                        y: 42
                        width: 38
                        height: 38
                        radius: 12
                        color: parent.isActive ? (root.dayMode ? "#168867" : "#168867") : style.panel

                        CamperV2Icon {
                            anchors.centerIn: parent
                            width: 23
                            height: 23
                            kind: parent.parent.modelData.icon
                            lineColor: parent.parent.isActive ? "#effff9" : style.muted
                            strokeWidth: 1.8
                        }
                    }
                    Text {
                        x: 60
                        y: 39
                        width: 84
                        height: 44
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        text: parent.modelData.name
                        color: parent.isActive ? style.green : style.text
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: parent.isAvailable
                        onClicked: root.adapter.command("starpower", "set", parent.channelData.on === true ? 0 : 1, {
                            channel: Number(parent.channelData.channel)
                        })
                    }
                }
            }
        }

        CamperV2Card {
            x: 511
            y: 0
            width: 265
            height: 274
            dayMode: root.dayMode
            active: root.inverter.on === true
            available: root.adapter.customCommandsAllowed === true && (root.inverter.online === true || Object.keys(root.inverter).length > 0)
            accent: style.purple

            Rectangle {
                x: 17
                y: 18
                width: 46
                height: 46
                radius: 14
                color: parent.active ? "#7451d2" : style.inner

                CamperV2Icon {
                    anchors.centerIn: parent
                    width: 27
                    height: 27
                    kind: "plug"
                    lineColor: parent.parent.active ? "#f4efff" : style.muted
                    strokeWidth: 1.9
                }
            }
            Text {
                x: 76
                y: 25
                width: 170
                text: "230 V"
                color: parent.active ? style.purple : style.text
                font.pixelSize: 15
                font.bold: true
            }
            Text {
                x: 0
                y: 203
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.fmt(root.inverter.outputPower, 0, " W")
                color: style.text
                font.pixelSize: 19
                font.bold: true
            }
            Text {
                x: 0
                y: 231
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "Verbrauch"
                color: style.muted
                font.pixelSize: 9
            }
            MouseArea {
                anchors.fill: parent
                enabled: parent.available
                onClicked: root.adapter.command("inverter", "set", root.inverter.on !== true, ({}))
            }
        }
    }

    Item {
        x: 12
        y: 56
        width: 776
        height: 274
        visible: root.energyPane === 1

        CamperV2Card {
            x: 0
            y: 0
            width: 252
            height: 274
            dayMode: root.dayMode
            active: false

            Rectangle {
                x: 17
                y: 18
                width: 48
                height: 48
                radius: 15
                color: root.dayMode ? "#fff2cf" : "#332713"

                CamperV2Icon {
                    anchors.centerIn: parent
                    width: 29
                    height: 29
                    kind: "solar"
                    lineColor: style.yellow
                    strokeWidth: 1.8
                }
            }
            Text {
                x: 77
                y: 26
                width: 158
                text: "Solar gesamt"
                color: style.text
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
            Text {
                x: 17
                y: 112
                width: 218
                horizontalAlignment: Text.AlignHCenter
                text: root.fmt(root.solarTotal(), 0, " W")
                color: style.text
                font.pixelSize: 31
                font.bold: true
            }
            Text {
                x: 17
                y: 158
                width: 218
                horizontalAlignment: Text.AlignHCenter
                text: root.valid(root.yieldToday()) ? root.fmt(root.yieldToday(), 2, " kWh heute") : ""
                color: style.muted
                font.pixelSize: 10
            }
            MouseArea {
                anchors.fill: parent
                onClicked: root.energyPane = 2
            }
        }

        CamperV2Card {
            x: 261
            y: 0
            width: 253
            height: 274
            dayMode: root.dayMode
            active: root.orion.online === true && root.orion.on === true
            available: root.adapter.customCommandsAllowed === true && root.orion.online === true
            accent: style.purple

            Rectangle {
                x: 17
                y: 18
                width: 48
                height: 48
                radius: 15
                color: parent.active ? "#168fca" : (parent.available ? (root.dayMode ? "#fff0d9" : "#352311") : style.inner)
                border.color: parent.active ? "#6fd7ff" : (parent.available ? style.orange : style.muted)
                border.width: 1

                CamperV2Icon {
                    anchors.centerIn: parent
                    width: 29
                    height: 29
                    kind: "alternator"
                    lineColor: parent.parent.active ? "#effcff" : (parent.parent.available ? style.orange : style.muted)
                    strokeWidth: 1.8
                }
            }
            Text {
                x: 77
                y: 26
                width: 159
                text: "Lichtmaschine"
                color: style.text
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
            Text {
                x: 17
                y: 111
                width: 219
                horizontalAlignment: Text.AlignHCenter
                text: parent.available ? root.fmt(root.orion.power, 0, " W") : "– W"
                color: style.text
                font.pixelSize: 31
                font.bold: true
            }
            Text {
                x: 17
                y: 159
                width: 219
                horizontalAlignment: Text.AlignHCenter
                text: parent.available ? root.fmt(root.orion.voltage, 1, " V") + " · " + root.fmt(root.orion.current, 1, " A") : "– V · – A"
                color: style.muted
                font.pixelSize: 10
            }
            MouseArea {
                anchors.fill: parent
                enabled: parent.available
                onClicked: root.adapter.command("orion", "set", root.orion.on !== true, ({}))
            }
        }

        CamperV2Card {
            x: 523
            y: 0
            width: 253
            height: 274
            dayMode: root.dayMode
            active: false
            available: root.indevolt.online === true

            Rectangle {
                readonly property bool gridOn: root.indevolt.gridConnection && root.indevolt.gridConnection.available === true && root.indevolt.gridConnection.on === true

                x: 17
                y: 18
                width: 48
                height: 48
                radius: 15
                color: gridOn ? "#168fca" : (root.dayMode ? "#eee8ff" : "#241d38")
                border.color: gridOn ? "#6fd7ff" : "transparent"
                border.width: gridOn ? 1 : 0

                CamperV2Icon {
                    anchors.centerIn: parent
                    width: 29
                    height: 29
                    kind: "battery"
                    lineColor: parent.gridOn ? "#effcff" : style.purple
                    strokeWidth: 1.8
                }
            }
            Text {
                x: 77
                y: 26
                width: 159
                text: "INDEVOLT"
                color: style.text
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
            Text {
                x: 17
                y: 111
                width: 219
                horizontalAlignment: Text.AlignHCenter
                text: root.fmt(root.indevolt.soc, 0, " %")
                color: style.text
                font.pixelSize: 31
                font.bold: true
            }
            Row {
                x: 81
                y: 165
                spacing: 13

                Rectangle {
                    width: 38
                    height: 38
                    radius: 12
                    color: root.valid(root.indevolt.solarPower) && Number(root.indevolt.solarPower) > 0 ? "#332713" : style.inner
                    CamperV2Icon {
                        anchors.centerIn: parent
                        width: 25
                        height: 25
                        kind: "solar"
                        lineColor: root.valid(root.indevolt.solarPower) && Number(root.indevolt.solarPower) > 0 ? style.yellow : style.muted
                        strokeWidth: 1.5
                    }
                }
                Rectangle {
                    width: 38
                    height: 38
                    radius: 12
                    color: root.indevolt.gridConnection && root.indevolt.gridConnection.on === true ? style.selectedGreen : style.inner
                    CamperV2Icon {
                        anchors.centerIn: parent
                        width: 25
                        height: 25
                        kind: "plug"
                        lineColor: root.indevolt.gridConnection && root.indevolt.gridConnection.on === true ? style.green : style.muted
                        strokeWidth: 1.5
                    }
                }
            }
            MouseArea {
                anchors.fill: parent
                enabled: root.adapter.customCommandsAllowed === true && root.indevolt.online === true && root.indevolt.gridConnection && root.indevolt.gridConnection.available === true
                onClicked: root.adapter.command("indevoltGrid", "set", root.indevolt.gridConnection.on !== true, ({}))
            }
        }
    }

    Item {
        x: 12
        y: 56
        width: 776
        height: 274
        visible: root.energyPane === 2

        CamperV2Card {
            x: 0
            y: 0
            width: 776
            height: 54
            dayMode: root.dayMode

            Rectangle {
                x: 6
                y: 6
                width: 42
                height: 42
                radius: 12
                color: backArea.pressed ? style.pressed : style.inner
                CamperV2Icon {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    kind: "back"
                    lineColor: style.text
                    strokeWidth: 1.8
                }
                MouseArea {
                    id: backArea
                    anchors.fill: parent
                    onClicked: root.energyPane = 1
                }
            }
            Text {
                x: 61
                y: 8
                text: "Solar gesamt"
                color: style.text
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
            Text {
                x: 61
                y: 29
                text: root.chargers.length + " MPPT" + (root.chargers.length === 1 ? "" : "-Regler") + " und INDEVOLT"
                color: style.muted
                font.pixelSize: 9
            }
            Text {
                x: 594
                y: 7
                width: 164
                horizontalAlignment: Text.AlignRight
                text: root.fmt(root.solarTotal(), 0, " W")
                color: style.text
                font.pixelSize: 18
                font.bold: true
            }
            Text {
                x: 594
                y: 30
                width: 164
                horizontalAlignment: Text.AlignRight
                text: root.valid(root.yieldToday()) ? root.fmt(root.yieldToday(), 2, " kWh heute") : ""
                color: style.muted
                font.pixelSize: 9
            }
        }

        Flickable {
            x: 0
            y: 62
            width: 776
            height: 212
            clip: true
            contentWidth: deviceRow.width
            contentHeight: height
            boundsBehavior: Flickable.StopAtBounds

            Row {
                id: deviceRow
                height: 212
                spacing: 8

                Repeater {
                    model: root.chargers
                    delegate: CamperV2Card {
                        required property var modelData
                        readonly property bool online: modelData.online === true
                        width: Math.max(186, (776 - Math.min(4, root.chargers.length + 1) * 8) / Math.min(4, root.chargers.length + 1))
                        height: 212
                        dayMode: root.dayMode
                        active: online
                        available: online
                        accent: style.yellow

                        CamperV2Icon {
                            x: 12
                            y: 12
                            width: 32
                            height: 32
                            kind: "solar"
                            lineColor: parent.online ? style.yellow : style.muted
                            strokeWidth: 1.5
                        }
                        Text {
                            x: 52
                            y: 13
                            width: parent.width - 78
                            elide: Text.ElideRight
                            text: parent.modelData.name || "SmartSolar MPPT"
                            color: style.text
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }
                        Rectangle {
                            x: parent.width - 17
                            y: 17
                            width: 7
                            height: 7
                            radius: 4
                            color: parent.online ? style.green : style.muted
                        }
                        Text {
                            x: 10
                            y: 72
                            width: parent.width - 20
                            horizontalAlignment: Text.AlignHCenter
                            text: parent.online ? root.fmt(parent.modelData.power, 0, " W") : "– W"
                            color: style.text
                            font.pixelSize: 26
                            font.bold: true
                        }
                        Text {
                            x: 12
                            y: 145
                            text: "PV"
                            color: style.muted
                            font.pixelSize: 9
                        }
                        Text {
                            x: 12
                            y: 164
                            text: parent.online ? root.fmt(parent.modelData.pvVoltage, 2, " V") : "– V"
                            color: style.text
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }
                        Text {
                            x: parent.width / 2
                            y: 145
                            text: "Heute"
                            color: style.muted
                            font.pixelSize: 9
                        }
                        Text {
                            x: parent.width / 2
                            y: 164
                            text: parent.online ? root.fmt(parent.modelData.yieldTodayKwh, 2, " kWh") : "– kWh"
                            color: style.text
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }
                    }
                }

                CamperV2Card {
                    readonly property bool online: root.indevolt.online === true
                    width: Math.max(186, (776 - Math.min(4, root.chargers.length + 1) * 8) / Math.min(4, root.chargers.length + 1))
                    height: 212
                    dayMode: root.dayMode
                    active: online
                    available: online
                    accent: style.green

                    CamperV2Icon {
                        x: 12
                        y: 12
                        width: 32
                        height: 32
                        kind: "battery"
                        lineColor: parent.online ? style.green : style.muted
                        strokeWidth: 1.5
                    }
                    Text {
                        x: 52
                        y: 13
                        width: parent.width - 78
                        text: "INDEVOLT"
                        color: style.text
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                    Rectangle {
                        x: parent.width - 17
                        y: 17
                        width: 7
                        height: 7
                        radius: 4
                        color: parent.online ? style.green : style.muted
                    }
                    Text {
                        x: 10
                        y: 72
                        width: parent.width - 20
                        horizontalAlignment: Text.AlignHCenter
                        text: parent.online ? root.fmt(root.indevolt.solarPower, 0, " W") : "– W"
                        color: style.text
                        font.pixelSize: 26
                        font.bold: true
                    }
                    Text {
                        x: 12
                        y: 145
                        text: "Akku"
                        color: style.muted
                        font.pixelSize: 9
                    }
                    Text {
                        x: 12
                        y: 164
                        text: parent.online ? root.fmt(root.indevolt.soc, 0, " %") : "– %"
                        color: style.text
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                    Text {
                        x: parent.width / 2
                        y: 145
                        text: "Batterie"
                        color: style.muted
                        font.pixelSize: 9
                    }
                    Text {
                        x: parent.width / 2
                        y: 164
                        text: parent.online ? root.fmt(root.indevolt.batteryPower, 0, " W") : "– W"
                        color: style.text
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }
}
