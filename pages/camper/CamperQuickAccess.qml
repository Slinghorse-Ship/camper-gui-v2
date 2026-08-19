/* Freely assignable Home shortcuts, using the Node-RED v5 option catalog. */

import QtQuick
import "../../components/camper"

Item {
    id: root

    required property var adapter
    property url logoSource: "qrc:/images/camper_logo.png"
    property url v2LogoSource: "qrc:/images/camper_transit_line_dark.png"
    property var quickAccessIds: ["switch:water_pump", "switch:starlink", "switch:dc_outlets_left", "light:inside_main"]
    signal pageRequested(int page)
    signal backRequested

    readonly property bool dayMode: false
    readonly property var snapshot: adapter.stateData || ({})
    readonly property var quickOptions: snapshot.ui && snapshot.ui.quickAccessOptions ? snapshot.ui.quickAccessOptions : []
    readonly property color panel: visual.panel
    readonly property color inner: visual.inner
    readonly property color textColor: visual.text
    readonly property color muted: visual.muted
    readonly property color line: visual.border
    readonly property color blue: visual.blue

    width: 800
    height: 480

    CamperStyle {
        id: visual
        dayMode: root.dayMode
    }

    function syncFromBackend() {
        const ids = snapshot.ui && snapshot.ui.quickAccessIds;
        if (ids && ids.length === 4) {
            quickAccessIds = ids.slice(0);
        }
    }

    function optionFor(id) {
        for (let i = 0; i < quickOptions.length; ++i) {
            if (quickOptions[i].id === id) {
                return quickOptions[i];
            }
        }
        return {
            id: id,
            name: id,
            group: "Nicht verfügbar",
            icon: "power"
        };
    }

    function changeQuickAccess(index, direction) {
        if (quickOptions.length === 0) {
            return;
        }
        const choices = [];
        for (let i = 0; i < quickOptions.length; ++i) {
            choices.push(quickOptions[i].id);
        }
        let current = choices.indexOf(quickAccessIds[index]);
        if (current < 0) {
            current = 0;
        }
        const wanted = choices[(current + direction + choices.length) % choices.length];
        const occupant = quickAccessIds.indexOf(wanted);
        const updated = quickAccessIds.slice(0);
        if (occupant >= 0 && occupant !== index) {
            updated[occupant] = updated[index];
        }
        updated[index] = wanted;
        quickAccessIds = updated;
        adapter.setQuickAccessIds(updated);
    }

    onVisibleChanged: if (visible)
        syncFromBackend()
    Component.onCompleted: syncFromBackend()

    Rectangle {
        anchors.fill: parent
        color: visual.backgroundBottom
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

    Rectangle {
        x: 0
        y: 0
        width: 800
        height: 58
        color: visual.header
        border.color: root.line

        Image {
            x: visual.designV2 ? 14 : 5
            y: visual.designV2 ? 8 : 4
            width: visual.designV2 ? 55 : 56
            height: visual.designV2 ? 35 : 50
            source: visual.designV2 ? root.v2LogoSource : root.logoSource
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
        Text {
            x: 65
            y: 10
            text: "FORD TRANSIT CAMPER"
            color: root.textColor
            font.pixelSize: 17
            font.bold: true
            visible: !visual.designV2
        }
        Text {
            x: visual.designV2 ? 79 : 65
            y: visual.designV2 ? 14 : 31
            text: visual.designV2 ? "Schnellzugriff" : "· SCHNELLZUGRIFF"
            color: visual.designV2 ? root.textColor : root.blue
            font.pixelSize: visual.designV2 ? 19 : 11
            font.bold: true
        }
        CamperTouchButton {
            x: 662
            y: 9
            width: 128
            height: 39
            label: "‹ ZURÜCK"
            onClicked: root.backRequested()
        }
    }

    Text {
        x: 18
        y: 76
        text: "VIER FREI BELEGBARE KACHELN"
        color: root.blue
        font.pixelSize: 11
        font.bold: true
    }
    Text {
        x: 18
        y: 97
        text: "Licht, Wasserpumpe, Starlink, 12 V, Geräte oder Szenen"
        color: root.muted
        font.pixelSize: 9
    }

    Repeater {
        model: 4
        delegate: Rectangle {
            required property int index
            property var option: root.optionFor(root.quickAccessIds[index])

            x: 14 + (index % 2) * 390
            y: 128 + Math.floor(index / 2) * 118
            width: 382
            height: 102
            radius: 13
            color: root.panel
            border.color: root.line

            Text {
                x: 14
                y: 13
                text: "PLATZ " + (index + 1)
                color: root.muted
                font.pixelSize: 8
                font.bold: true
            }
            Text {
                x: 14
                y: 34
                width: 226
                text: parent.option.name
                elide: Text.ElideRight
                color: root.textColor
                font.pixelSize: 13
                font.bold: true
            }
            Text {
                x: 14
                y: 59
                width: 226
                text: parent.option.group
                elide: Text.ElideRight
                color: root.blue
                font.pixelSize: 9
                font.bold: true
            }
            CamperTouchButton {
                x: 258
                y: 20
                width: 48
                height: 62
                label: "−"
                fontSize: 20
                onClicked: root.changeQuickAccess(index, -1)
            }
            CamperTouchButton {
                x: 316
                y: 20
                width: 48
                height: 62
                label: "+"
                fontSize: 20
                onClicked: root.changeQuickAccess(index, 1)
            }
        }
    }

    Text {
        x: 18
        y: 374
        width: 764
        text: adapter.customConnected ? "ÄNDERUNGEN WERDEN SOFORT AUF CERBO, SYNC UND NODE-RED GESPEICHERT" : "CAMPER-API NICHT VERBUNDEN"
        color: adapter.customConnected ? root.muted : visual.red
        font.pixelSize: 9
        font.bold: true
    }

    CamperNavBar {
        x: 0
        y: 422
        width: 800
        height: 58
        dayMode: root.dayMode
        currentPage: -1
        lineColor: root.line
        primaryText: root.textColor
        accentColor: root.blue
        onPageRequested: page => root.pageRequested(page)
    }
}
