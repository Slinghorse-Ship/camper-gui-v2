pragma ComponentBehavior: Bound

import QtQuick
import "../../../components/camper/v2"

Item {
    id: root

    required property var adapter
    property bool dayMode: false
    signal openVictronSettings
    signal closeRequested

    CamperV2Style {
        id: style
        dayMode: root.dayMode
    }

    Repeater {
        model: [
            {
                x: 12,
                width: 211,
                title: "Verbindungen"
            },
            {
                x: 232,
                width: 276,
                title: "Camper"
            },
            {
                x: 517,
                width: 271,
                title: "Victron"
            }
        ]
        delegate: CamperV2Card {
            required property var modelData
            x: modelData.x
            y: 8
            width: modelData.width
            height: 322
            dayMode: root.dayMode

            Text {
                x: 14
                y: 12
                text: parent.modelData.title
                color: style.text
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
        }
    }

    Column {
        x: 22
        y: 54
        spacing: 8

        Repeater {
            model: [
                {
                    label: "Victron",
                    connected: root.adapter.connected === true,
                    icon: "energy"
                },
                {
                    label: "Node-RED",
                    connected: root.adapter.customReadConnected === true,
                    icon: "system"
                },
                {
                    label: "DWD-Wetter",
                    connected: root.adapter.weatherConnected === true,
                    icon: "climate"
                }
            ]
            delegate: Rectangle {
                required property var modelData
                width: 191
                height: 68
                radius: 13
                color: style.inner
                border.color: modelData.connected ? style.green : style.border

                CamperV2Icon {
                    x: 10
                    y: 16
                    width: 36
                    height: 36
                    kind: parent.modelData.icon
                    lineColor: parent.modelData.connected ? style.green : style.muted
                    strokeWidth: 1.7
                }
                Text {
                    x: 57
                    y: 0
                    width: 104
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    text: parent.modelData.label
                    color: style.text
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
                Rectangle {
                    x: 169
                    y: 29
                    width: 8
                    height: 8
                    radius: 4
                    color: parent.modelData.connected ? style.green : style.muted
                }
            }
        }
    }

    Rectangle {
        x: 242
        y: 55
        width: 256
        height: 102
        radius: 14
        color: style.selectedBlue
        border.color: style.blue

        CamperV2Icon {
            x: 15
            y: 18
            width: 38
            height: 38
            kind: "home"
            lineColor: style.blue
            strokeWidth: 1.8
        }
        Text {
            x: 66
            y: 19
            text: "Transit Horizon"
            color: style.text
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
        Text {
            x: 66
            y: 44
            text: "V2 · feste Oberfläche"
            color: style.blue
            font.pixelSize: 10
        }
        Text {
            x: 15
            y: 73
            width: 226
            text: "Optimiert für GX Touch 50 und Remote Console"
            color: style.muted
            font.pixelSize: 9
        }
    }

    Rectangle {
        x: 242
        y: 168
        width: 256
        height: 117
        radius: 13
        color: style.inner
        border.color: style.border

        Text {
            x: 14
            y: 13
            text: "Seitliche Panels"
            color: style.text
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }
        Text {
            x: 14
            y: 40
            width: 228
            text: "Links  Favoriten\nRechts  DWD-Wetter"
            color: style.muted
            font.pixelSize: 10
            lineHeight: 1.45
        }
        Text {
            x: 14
            y: 91
            width: 228
            text: "Vom Bildschirmrand nach innen wischen"
            color: style.blue
            font.pixelSize: 8
        }
    }

    Column {
        x: 527
        y: 54
        spacing: 9

        Repeater {
            model: [
                {
                    label: "Einstellungen",
                    detail: "System und Geräte",
                    icon: "system",
                    action: 0
                },
                {
                    label: "Victron öffnen",
                    detail: "Originale Ansicht",
                    icon: "external",
                    action: 1
                }
            ]
            delegate: Rectangle {
                required property var modelData
                width: 251
                height: 91
                radius: 13
                color: systemArea.pressed ? style.pressed : style.inner
                border.color: style.border

                CamperV2Icon {
                    x: 13
                    y: 24
                    width: 42
                    height: 42
                    kind: parent.modelData.icon
                    lineColor: style.blue
                    strokeWidth: 1.8
                }
                Text {
                    x: 68
                    y: 23
                    width: 168
                    text: parent.modelData.label
                    color: style.text
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
                Text {
                    x: 68
                    y: 47
                    width: 168
                    text: parent.modelData.detail
                    color: style.muted
                    font.pixelSize: 9
                }
                MouseArea {
                    id: systemArea
                    anchors.fill: parent
                    onClicked: {
                        if (parent.modelData.action === 0)
                            root.openVictronSettings();
                        else
                            root.closeRequested();
                    }
                }
            }
        }
    }
}
