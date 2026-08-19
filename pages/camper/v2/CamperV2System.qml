pragma ComponentBehavior: Bound

import QtQuick
import "../../../components/camper"
import "../../../components/camper/v2"

Item {
    id: root

    required property var adapter
    property bool dayMode: false
    signal openVictronSettings
    signal closeRequested
    signal designSelected(int version)

    CamperV2Style {
        id: style
        dayMode: root.dayMode
    }

    function selectDesign(version) {
        CamperDesignSettings.setDesignVersion(version);
        designSelected(version);
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

    Text {
        x: 246
        y: 55
        text: "Design"
        color: style.muted
        font.pixelSize: 9
    }

    Row {
        x: 242
        y: 76
        spacing: 7

        Repeater {
            model: [
                {
                    version: 1,
                    label: "V1"
                },
                {
                    version: 2,
                    label: "V2"
                }
            ]
            delegate: Rectangle {
                required property var modelData
                readonly property bool selected: CamperDesignSettings.designVersion === modelData.version
                width: 124
                height: 78
                radius: 14
                color: selected ? style.selectedBlue : style.inner
                border.color: selected ? style.blue : style.border
                border.width: selected ? 2 : 1

                Text {
                    x: 13
                    y: 10
                    text: parent.modelData.label
                    color: parent.selected ? style.blue : style.text
                    font.pixelSize: 22
                    font.bold: true
                }
                CamperV2Icon {
                    x: 82
                    y: 23
                    width: 28
                    height: 28
                    kind: parent.selected ? "check" : "system"
                    lineColor: parent.selected ? style.blue : style.muted
                    strokeWidth: 1.8
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.selectDesign(parent.modelData.version)
                }
            }
        }
    }

    Text {
        x: 246
        y: 169
        width: 248
        text: "Die Auswahl wird lokal auf diesem Gerät gespeichert."
        wrapMode: Text.WordWrap
        color: style.muted
        font.pixelSize: 9
    }

    Rectangle {
        x: 242
        y: 223
        width: 256
        height: 62
        radius: 13
        color: style.inner
        Text {
            anchors.centerIn: parent
            text: root.dayMode ? "Helle Darstellung" : "Dunkle Darstellung"
            color: style.text
            font.pixelSize: 10
            font.weight: Font.DemiBold
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
