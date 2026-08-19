import QtQuick
import "../../../components/camper/v2"

Item {
    id: root

    required property var adapter
    property bool dayMode: false

    readonly property var snapshot: adapter.stateData || ({})
    readonly property var water: snapshot.water || ({})
    readonly property var fresh: water.fresh || ({})
    readonly property var pump: water.pump || ({})

    CamperV2Style {
        id: style
        dayMode: root.dayMode
    }

    function valid(value) {
        return value !== null && value !== undefined && value !== "" && isFinite(Number(value));
    }

    readonly property bool levelAvailable: valid(fresh.level)
    readonly property real levelValue: levelAvailable ? Math.max(0, Math.min(100, Number(fresh.level))) : 0
    readonly property bool pumpAvailable: adapter.customCommandsAllowed === true && pump.online === true

    CamperV2Card {
        x: 12
        y: 8
        width: 383
        height: 322
        dayMode: root.dayMode
        active: root.levelAvailable
        available: root.levelAvailable
        accent: style.blue

        Text {
            x: 16
            y: 14
            text: "Frischwasser"
            color: style.text
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }

        Rectangle {
            x: 112
            y: 62
            width: 159
            height: 199
            radius: 38
            color: style.inner
            border.color: root.levelAvailable ? style.blue : style.border
            border.width: 2
            clip: true

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.height * root.levelValue / 100
                color: root.dayMode ? "#d7f3ff" : "#12364b"
            }
            Text {
                anchors.centerIn: parent
                text: root.levelAvailable ? root.levelValue.toFixed(0) + " %" : "– %"
                color: style.text
                font.pixelSize: 31
                font.bold: true
            }
            Text {
                x: 0
                y: 128
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.levelAvailable ? "" : "Nicht verfügbar"
                color: style.muted
                font.pixelSize: 10
            }
        }
    }

    CamperV2Card {
        x: 404
        y: 8
        width: 384
        height: 322
        dayMode: root.dayMode
        active: root.pump.on === true
        available: root.pumpAvailable
        accent: style.green

        CamperV2Icon {
            x: 112
            y: 58
            width: 160
            height: 160
            kind: "pump"
            lineColor: parent.active ? style.green : style.muted
            strokeWidth: 2.7
        }
        Text {
            x: 0
            y: 242
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "Wasserpumpe"
            color: parent.active ? style.green : style.text
            font.pixelSize: 18
            font.weight: Font.DemiBold
        }
        MouseArea {
            anchors.fill: parent
            enabled: root.pumpAvailable
            onClicked: root.adapter.command("waterPump", "set", root.pump.on !== true, ({}))
        }
    }
}
