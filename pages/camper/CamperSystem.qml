/* Camper system page. It changes presentation only and does not invent backend paths. */

pragma ComponentBehavior: Bound

import QtQuick
import "../../components/camper"

Item {
    id: root

    required property var adapter
    property url v2LogoSource: "qrc:/images/camper_transit_line_dark.png"
    signal openVictronSettings
    signal closeRequested
    signal pageRequested(int page)
    signal designSelected(int version)

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
        height: 58
        pageTitle: "SYSTEM"
        v2LogoSource: root.v2LogoSource
        connected: root.adapter.customConnected === true
        onOpenVictronSettings: root.openVictronSettings()
        onCloseRequested: root.closeRequested()
    }

    Text {
        x: 18
        y: 73
        text: "DESIGN"
        color: visual.muted
        font.pixelSize: 10
        font.bold: true
    }

    Repeater {
        model: [
            {
                version: CamperDesignSettings.version1,
                title: "V1",
                detail: "Klassisch"
            },
            {
                version: CamperDesignSettings.version2,
                title: "V2",
                detail: "Transit Horizon"
            }
        ]
        delegate: Rectangle {
            required property var modelData
            required property int index
            readonly property bool selected: CamperDesignSettings.designVersion === modelData.version

            x: 14 + index * 390
            y: 94
            width: 382
            height: 104
            radius: visual.designV2 ? 17 : 13
            color: selected ? visual.selectedBlue : visual.panel
            border.color: selected ? visual.blue : visual.border
            border.width: selected ? 2 : 1

            Text {
                x: 18
                y: 17
                text: parent.modelData.title
                color: parent.selected ? visual.blue : visual.text
                font.pixelSize: 24
                font.bold: true
            }
            Text {
                x: 18
                y: 54
                text: parent.modelData.detail
                color: visual.muted
                font.pixelSize: 12
            }
            CamperLineIcon {
                x: 318
                y: 28
                width: 42
                height: 42
                kind: parent.selected ? "check" : "settings"
                lineColor: parent.selected ? visual.blue : visual.muted
                strokeWidth: 2
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    CamperDesignSettings.setDesignVersion(parent.modelData.version);
                    root.designSelected(parent.modelData.version);
                }
            }
        }
    }

    Rectangle {
        x: 14
        y: 216
        width: 772
        height: 112
        radius: visual.designV2 ? 17 : 13
        color: visual.panel
        border.color: visual.border

        Text {
            x: 18
            y: 16
            text: "VICTRON"
            color: visual.blue
            font.pixelSize: 10
            font.bold: true
        }
        Text {
            x: 18
            y: 39
            width: 438
            text: "Originale Einstellungen, Geräte und Diagnose bleiben vollständig erreichbar."
            wrapMode: Text.WordWrap
            color: visual.text
            font.pixelSize: 12
        }
        CamperTouchButton {
            x: 484
            y: 20
            width: 132
            height: 70
            label: "EINSTELLUNGEN"
            accentColor: visual.blue
            onClicked: root.openVictronSettings()
        }
        CamperTouchButton {
            x: 626
            y: 20
            width: 128
            height: 70
            label: "VICTRON UI"
            accentColor: visual.blue
            onClicked: root.closeRequested()
        }
    }

    Text {
        x: 18
        y: 350
        width: 764
        text: "Die Designauswahl ist lokal gespeichert und wird nicht automatisch mit Ford SYNC oder Node-RED abgeglichen."
        wrapMode: Text.WordWrap
        color: visual.muted
        font.pixelSize: 10
    }

    CamperNavBar {
        x: 0
        y: 422
        width: 800
        height: 58
        currentPage: 13
        onPageRequested: page => root.pageRequested(page)
    }
}
