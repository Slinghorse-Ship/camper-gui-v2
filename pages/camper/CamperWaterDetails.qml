import QtQuick
import "../../components/camper"

Item {
    id: view

    required property var adapter
    property var water: ({})
    signal backRequested

    readonly property var fresh: water.fresh || ({})
    readonly property var waste: water.waste || ({})
    readonly property var pump: water.pump || ({})

    CamperStyle {
        id: visual
    }

    function fmt(value, digits, suffix) {
        if (value === null || value === undefined || value === "" || !isFinite(Number(value)))
            return "–";
        return Number(value).toFixed(digits) + (suffix || "");
    }

    Rectangle {
        x: 10
        y: 8
        width: 780
        height: 56
        radius: 13
        color: visual.panel
        border.color: visual.border

        CamperTouchButton {
            x: 8
            y: 9
            width: 76
            height: 38
            label: "ZURÜCK"
            onClicked: view.backRequested()
        }
        Text {
            x: 98
            y: 8
            text: "WASSERSYSTEM"
            color: visual.text
            font.pixelSize: 15
            font.bold: true
        }
        Text {
            x: 98
            y: 31
            text: "Frischwasser, Abwasser und STAR-Power Wasserpumpe"
            color: visual.muted
            font.pixelSize: 9
            font.bold: true
        }
        Rectangle {
            x: 686
            y: 22
            width: 8
            height: 8
            radius: 4
            color: view.pump.online === true ? visual.green : visual.red
        }
        Text {
            x: 703
            y: 18
            width: 63
            text: view.pump.online === true ? "ONLINE" : "OFFLINE"
            color: view.pump.online === true ? visual.green : visual.red
            font.pixelSize: 9
            font.bold: true
        }
    }

    Repeater {
        model: [
            {
                title: view.fresh.name || "FRISCHWASSER",
                tank: view.fresh,
                color: visual.blue
            },
            {
                title: view.waste.name || "ABWASSER",
                tank: view.waste,
                color: visual.orange
            }
        ]
        delegate: Rectangle {
            id: tankCard

            required property var modelData
            required property int index
            readonly property real levelValue: Math.max(0, Math.min(100, Number(modelData.tank.level || 0)))

            x: 10 + index * 258
            y: 72
            width: 248
            height: 342
            radius: 13
            color: visual.inner
            border.color: visual.border

            Text {
                x: 16
                y: 15
                text: parent.modelData.title.toUpperCase()
                color: visual.muted
                font.pixelSize: 9
                font.bold: true
            }
            Rectangle {
                x: 42
                y: 50
                width: 164
                height: 192
                radius: 18
                color: visual.panel
                border.color: parent.modelData.color
                border.width: 3
                clip: true

                Rectangle {
                    x: 4
                    y: parent.height - height - 4
                    width: parent.width - 8
                    height: (parent.height - 8) * tankCard.levelValue / 100
                    radius: 13
                    color: tankCard.modelData.color
                    opacity: 0.38
                }
                Text {
                    anchors.centerIn: parent
                    text: view.fmt(tankCard.modelData.tank.level, 0, " %")
                    color: tankCard.modelData.color
                    font.pixelSize: 32
                    font.bold: true
                }
            }
            Text {
                x: 16
                y: 263
                width: 216
                horizontalAlignment: Text.AlignHCenter
                text: view.fmt(tankCard.modelData.tank.remainingLitres, 0, " LITER")
                color: visual.text
                font.pixelSize: 22
                font.bold: true
            }
            Text {
                x: 16
                y: 301
                width: 216
                horizontalAlignment: Text.AlignHCenter
                text: "KAPAZITÄT " + view.fmt(tankCard.modelData.tank.capacityLitres, 0, " L")
                color: visual.muted
                font.pixelSize: 9
                font.bold: true
            }
        }
    }

    Rectangle {
        x: 526
        y: 72
        width: 264
        height: 342
        radius: 13
        color: visual.inner
        border.color: view.pump.on === true ? visual.blue : visual.border

        Text {
            x: 16
            y: 15
            text: "WASSERPUMPE"
            color: visual.muted
            font.pixelSize: 9
            font.bold: true
        }
        CamperLineIcon {
            x: 79
            y: 55
            width: 106
            height: 106
            kind: "pump"
            lineColor: view.pump.on === true ? visual.blue : visual.muted
            strokeWidth: 2.4
        }
        Text {
            x: 16
            y: 182
            width: 232
            horizontalAlignment: Text.AlignHCenter
            text: view.pump.on === true ? "EINGESCHALTET" : "AUSGESCHALTET"
            color: view.pump.on === true ? visual.green : visual.text
            font.pixelSize: 16
            font.bold: true
        }
        Text {
            x: 16
            y: 216
            width: 232
            horizontalAlignment: Text.AlignHCenter
            text: "STAR-POWER KANAL " + Number(view.pump.channel || 2)
            color: visual.muted
            font.pixelSize: 9
            font.bold: true
        }
        CamperTouchButton {
            x: 18
            y: 256
            width: 228
            height: 58
            enabled: view.adapter.customCommandsAllowed === true && view.pump.online === true
            label: view.pump.on === true ? "PUMPE AUSSCHALTEN" : "PUMPE EINSCHALTEN"
            active: view.pump.on === true
            onClicked: view.adapter.command("waterPump", "set", view.pump.on !== true, ({}))
        }
    }
}
