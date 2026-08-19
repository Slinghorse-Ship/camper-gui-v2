import QtQuick
import "../../components/camper"

Item {
    id: root

    required property var adapter
    property url leftVehicleSource: "qrc:/images/camper_vehicle_left.png"
    property url rightVehicleSource: "qrc:/images/camper_vehicle_right.png"
    signal openVictronSettings
    signal closeRequested
    signal pageRequested(int page)

    readonly property var snapshot: adapter.stateData || ({})
    readonly property var lightItems: snapshot.lights && snapshot.lights.items ? snapshot.lights.items : []
    readonly property var highBeam: snapshot.vehicle && snapshot.vehicle.highBeam ? snapshot.vehicle.highBeam : ({})
    property bool rightView: false

    CamperStyle {
        id: visual
    }

    function findLight(lightId) {
        for (let index = 0; index < lightItems.length; ++index) {
            if (lightItems[index].id === lightId)
                return lightItems[index];
        }
        return {
            id: lightId,
            name: lightId,
            channel: 0,
            on: false,
            dimming: 0
        };
    }

    function percent(light) {
        return Math.max(0, Math.min(100, Math.round(Number(light.dimming || 0))));
    }

    function setLight(channel, enabled) {
        if (channel > 0)
            adapter.command("starpower", "set", enabled ? 1 : 0, {
                channel: channel
            });
    }

    function dimLight(channel, value) {
        if (channel > 0)
            adapter.command("starpower", "dim", value, {
                channel: channel
            });
    }

    function setFrontMode(mode) {
        const target = mode === "orange" ? frontAmber : frontWhite;
        const other = mode === "orange" ? frontWhite : frontAmber;
        if (Number(other.channel) > 0 && other.on === true)
            setLight(Number(other.channel), false);
        if (Number(target.channel) > 0)
            setLight(Number(target.channel), true);
    }

    readonly property var inside: findLight("inside_main")
    readonly property var leftSide: findLight("outside_left")
    readonly property var rightSide: findLight("outside_right")
    readonly property var rear: findLight("outside_rear")
    readonly property var frontWhite: findLight("outside_front_white")
    readonly property var frontAmber: findLight("outside_front_amber")
    readonly property bool frontActive: frontWhite.on === true || frontAmber.on === true
    readonly property string frontMode: frontAmber.on === true ? "orange" : "white"
    readonly property int frontDimming: percent(frontMode === "orange" ? frontAmber : frontWhite)

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
        pageTitle: "LICHT"
        connected: root.adapter.customConnected === true
        onOpenVictronSettings: root.openVictronSettings()
        onCloseRequested: root.closeRequested()
    }

    Item {
        x: 0
        y: 58
        width: 800
        height: 364

        CamperVehicleLightCard {
            x: 6
            y: 6
            width: 154
            height: 112
            title: "INNENLICHT"
            iconKind: "cabinLight"
            channel: Number(root.inside.channel)
            lightOn: root.inside.on === true
            dimming: root.percent(root.inside)
            onToggleRequested: (channel, enabled) => root.setLight(channel, enabled)
            onDimmerRequested: (title, iconKind, channel, enabled, value) => dimmer.open(title, iconKind, channel, enabled, value)
        }
        CamperVehicleLightCard {
            x: 6
            y: 124
            width: 154
            height: 112
            title: "AUSSEN LINKS"
            iconKind: "workLightLeft"
            channel: Number(root.leftSide.channel)
            lightOn: root.leftSide.on === true
            dimming: root.percent(root.leftSide)
            onToggleRequested: (channel, enabled) => {
                root.rightView = false;
                root.setLight(channel, enabled);
            }
            onDimmerRequested: (title, iconKind, channel, enabled, value) => {
                root.rightView = false;
                dimmer.open(title, iconKind, channel, enabled, value);
            }
        }
        CamperVehicleLightCard {
            x: 6
            y: 242
            width: 154
            height: 112
            title: "AUSSEN RECHTS"
            iconKind: "workLightRight"
            channel: Number(root.rightSide.channel)
            lightOn: root.rightSide.on === true
            dimming: root.percent(root.rightSide)
            onToggleRequested: (channel, enabled) => {
                root.rightView = true;
                root.setLight(channel, enabled);
            }
            onDimmerRequested: (title, iconKind, channel, enabled, value) => {
                root.rightView = true;
                dimmer.open(title, iconKind, channel, enabled, value);
            }
        }

        Item {
            x: 164
            y: 6
            width: 470
            height: 306

            Image {
                anchors.fill: parent
                source: root.rightView ? root.rightVehicleSource : root.leftVehicleSource
                fillMode: Image.PreserveAspectFit
                smooth: true
            }
            CamperVehicleLightOverlay {
                anchors.fill: parent
                rightView: root.rightView
                insideOn: root.inside.on === true
                insideLevel: root.percent(root.inside)
                leftOn: root.leftSide.on === true
                leftLevel: root.percent(root.leftSide)
                rightOn: root.rightSide.on === true
                rightLevel: root.percent(root.rightSide)
                rearOn: root.rear.on === true
                rearLevel: root.percent(root.rear)
                frontOn: root.frontActive
                frontLevel: root.frontDimming
                frontAmber: root.frontMode === "orange"
                highBeamOn: root.highBeam.on === true
            }
            MouseArea {
                x: root.rightView ? 145 : 286
                y: 108
                width: 76
                height: 82
                onClicked: root.setLight(Number(root.inside.channel), root.inside.on !== true)
            }
            MouseArea {
                x: root.rightView ? 36 : 302
                y: root.rightView ? 20 : 11
                width: 46
                height: 46
                onClicked: root.setLight(Number(root.rightView ? root.rightSide.channel : root.leftSide.channel), !(root.rightView ? root.rightSide.on : root.leftSide.on))
            }
            MouseArea {
                x: root.rightView ? 17 : 348
                y: 0
                width: 48
                height: 38
                onClicked: root.setLight(Number(root.rear.channel), root.rear.on !== true)
            }
            MouseArea {
                x: root.rightView ? 215 : 132
                y: root.rightView ? 12 : 24
                width: root.rightView ? 139 : 148
                height: 44
                onClicked: root.setLight(Number(root.highBeam.outputChannel || 3), root.highBeam.manualOn !== true)
            }
        }

        CamperTouchButton {
            x: 300
            y: 318
            width: 88
            height: 38
            label: "FAHRER"
            active: !root.rightView
            onClicked: root.rightView = false
        }
        CamperTouchButton {
            x: 394
            y: 318
            width: 104
            height: 38
            label: "BEIFAHRER"
            active: root.rightView
            onClicked: root.rightView = true
        }

        CamperVehicleLightCard {
            x: 640
            y: 6
            width: 154
            height: 112
            title: "AUSSEN HINTEN"
            iconKind: "rearLight"
            channel: Number(root.rear.channel)
            lightOn: root.rear.on === true
            dimming: root.percent(root.rear)
            onToggleRequested: (channel, enabled) => root.setLight(channel, enabled)
            onDimmerRequested: (title, iconKind, channel, enabled, value) => dimmer.open(title, iconKind, channel, enabled, value)
        }
        Rectangle {
            x: 640
            y: 124
            width: 154
            height: 82
            radius: 12
            color: root.highBeam.on === true ? "#14354b" : visual.panel
            border.color: root.highBeam.on === true ? "#56b9ff" : visual.border
            border.width: root.highBeam.on === true ? 2 : 1

            CamperLineIcon {
                x: 57
                y: 8
                width: 40
                height: 40
                kind: "highBeam"
                lineColor: root.highBeam.on === true ? "#56b9ff" : visual.muted
                strokeWidth: 2
            }
            Text {
                x: 8
                y: 57
                width: 138
                horizontalAlignment: Text.AlignRight
                text: "FERNLICHT"
                color: root.highBeam.on === true ? "#56b9ff" : visual.text
                font.pixelSize: 10
                font.bold: true
            }
            MouseArea {
                anchors.fill: parent
                onClicked: root.setLight(Number(root.highBeam.outputChannel || 3), root.highBeam.manualOn !== true)
            }
        }
        Rectangle {
            x: 640
            y: 212
            width: 154
            height: 142
            radius: 12
            color: root.frontActive ? "#382913" : visual.panel
            border.color: root.frontActive ? (root.frontMode === "orange" ? "#ff9f1a" : "#bfeeff") : visual.border

            CamperLineIcon {
                x: 9
                y: 5
                width: 25
                height: 25
                kind: root.frontMode === "orange" ? "warningBar" : "lightBar"
                lineColor: root.frontMode === "orange" ? "#ff9f1a" : (root.frontActive ? visual.blue : visual.muted)
                strokeWidth: 1.8
            }
            CamperTouchButton {
                x: 8
                y: 31
                width: 67
                height: 48
                label: "TAGFAHR"
                fontSize: 9
                active: root.frontMode === "white" && root.frontActive
                onClicked: root.frontWhite.on === true ? root.setLight(Number(root.frontWhite.channel), false) : root.setFrontMode("white")
            }
            CamperTouchButton {
                x: 79
                y: 31
                width: 67
                height: 48
                label: "WARNBLINK"
                fontSize: 8
                active: root.frontMode === "orange" && root.frontActive
                accentColor: "#ff9f1a"
                onClicked: root.frontAmber.on === true ? root.setLight(Number(root.frontAmber.channel), false) : root.setFrontMode("orange")
            }
            CamperTouchButton {
                x: 8
                y: 93
                width: 138
                height: 41
                visible: root.frontMode !== "orange"
                label: root.frontDimming + " %  DIMMEN"
                fontSize: 10
                active: root.frontWhite.on === true
                onClicked: dimmer.open("TAGFAHRLICHT BALKEN", "lightBar", Number(root.frontWhite.channel), root.frontWhite.on === true, root.frontDimming)
            }
            Text {
                x: 48
                y: 106
                width: 58
                visible: root.frontMode === "orange"
                horizontalAlignment: Text.AlignHCenter
                text: "500 ms"
                color: "#ff9f1a"
                font.pixelSize: 10
                font.bold: true
            }
        }

        CamperDimmerOverlay {
            id: dimmer
            anchors.fill: parent
            onToggleRequested: (channel, enabled) => root.setLight(channel, enabled)
            onDimRequested: (channel, value) => root.dimLight(channel, value)
        }
    }

    CamperNavBar {
        x: 0
        y: 422
        width: 800
        height: 58
        currentPage: 1
        onPageRequested: page => root.pageRequested(page)
    }
}
