pragma ComponentBehavior: Bound

import QtQuick
import "../../../components/camper/v2"

Item {
    id: root

    required property var adapter
    property bool dayMode: false
    property url leftVehicleSource: "qrc:/images/camper_v2_vehicle_left.png"
    property url rightVehicleSource: "qrc:/images/camper_v2_vehicle_right.png"
    property bool rightView: false
    property string selectedLightId: "inside_main"

    readonly property var snapshot: adapter.stateData || ({})
    readonly property var lightItems: snapshot.lights && snapshot.lights.items ? snapshot.lights.items : []
    readonly property var highBeam: snapshot.vehicle && snapshot.vehicle.highBeam ? snapshot.vehicle.highBeam : ({})

    CamperV2Style {
        id: style
        dayMode: root.dayMode
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
            dimming: 0,
            available: false
        };
    }

    function percent(light) {
        return Math.max(0, Math.min(100, Math.round(Number(light && light.dimming || 0))));
    }

    function available(light) {
        return adapter.customCommandsAllowed === true && Number(light && light.channel || 0) > 0;
    }

    function setLight(light, enabled) {
        if (available(light))
            adapter.command("starpower", "set", enabled ? 1 : 0, {
                channel: Number(light.channel)
            });
    }

    function toggleLight(light) {
        setLight(light, light.on !== true);
    }

    function dimLight(light, value) {
        if (available(light))
            adapter.command("starpower", "dim", Math.max(0, Math.min(100, Math.round(value))), {
                channel: Number(light.channel)
            });
    }

    function setFrontMode(mode) {
        const target = mode === "orange" ? frontAmber : frontWhite;
        const other = mode === "orange" ? frontWhite : frontAmber;
        selectedLightId = target.id;
        if (available(other) && other.on === true)
            setLight(other, false);
        toggleLight(target);
    }

    function runScene(sceneId) {
        if (adapter.customCommandsAllowed === true)
            adapter.command("scene", "run", sceneId, {
                sceneId: sceneId
            });
    }

    readonly property var inside: findLight("inside_main")
    readonly property var leftSide: findLight("outside_left")
    readonly property var rightSide: findLight("outside_right")
    readonly property var rear: findLight("outside_rear")
    readonly property var frontWhite: findLight("outside_front_white")
    readonly property var frontAmber: findLight("outside_front_amber")
    readonly property var selectedLight: findLight(selectedLightId)
    readonly property bool selectedDimmable: selectedLightId !== "outside_front_amber" && selectedLightId !== "high_beam_manual"
    readonly property bool highBeamManualOn: highBeam.manualOn === true
    readonly property bool highBeamVehicleOn: highBeam.vehicleOn === true || highBeam.on === true
    readonly property bool highBeamOn: highBeamManualOn || highBeamVehicleOn
    readonly property bool highBeamAvailable: highBeam.outputOnline === true
    readonly property int highBeamChannel: Number(highBeam.outputChannel || 3)
    readonly property bool frontActive: frontWhite.on === true || frontAmber.on === true
    readonly property bool frontIsAmber: frontAmber.on === true

    CamperV2Card {
        x: 12
        y: 8
        width: 440
        height: 322
        dayMode: root.dayMode

        Item {
            id: vehicleCanvas
            x: 0
            y: 0
            width: 440
            height: 283

            Image {
                anchors.fill: parent
                source: root.rightView ? root.rightVehicleSource : root.leftVehicleSource
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            Canvas {
                anchors.fill: parent
                visible: !root.rightView

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    ctx.save();
                    ctx.scale(width / 560, height / 360);

                    ctx.beginPath();
                    ctx.moveTo(355.8, 194);
                    ctx.bezierCurveTo(357.8, 192.8, 362.3, 192.5, 364.7, 193.3);
                    ctx.lineTo(364.2, 195.6);
                    ctx.bezierCurveTo(361.9, 196.6, 358.1, 196.8, 355.9, 195.9);
                    ctx.closePath();
                    ctx.fillStyle = "rgba(16,19,21,.94)";
                    ctx.strokeStyle = "rgba(85,88,86,.58)";
                    ctx.lineWidth = .55;
                    ctx.fill();
                    ctx.stroke();

                    ctx.beginPath();
                    ctx.moveTo(357.1, 193.8);
                    ctx.bezierCurveTo(359.2, 193.1, 362.1, 193, 363.8, 193.6);
                    ctx.strokeStyle = "rgba(183,183,177,.32)";
                    ctx.lineWidth = .48;
                    ctx.lineCap = "round";
                    ctx.stroke();

                    ctx.beginPath();
                    ctx.moveTo(356.5, 196.1);
                    ctx.bezierCurveTo(358.7, 197, 362.1, 196.9, 364, 196);
                    ctx.strokeStyle = "rgba(5,7,8,.72)";
                    ctx.lineWidth = .65;
                    ctx.stroke();
                    ctx.restore();
                }
            }

            CamperV2VehicleLightOverlay {
                anchors.fill: parent
                rightView: root.rightView
                insideOn: root.inside.on === true
                insideLevel: root.percent(root.inside)
                sideOn: root.rightView ? root.rightSide.on === true : root.leftSide.on === true
                sideLevel: root.percent(root.rightView ? root.rightSide : root.leftSide)
                rearOn: root.rear.on === true
                rearLevel: root.percent(root.rear)
                frontOn: root.frontActive
                frontLevel: root.percent(root.frontIsAmber ? root.frontAmber : root.frontWhite)
                frontAmber: root.frontIsAmber
                highBeamOn: root.highBeamOn
            }

            MouseArea {
                x: parent.width * (root.rightView ? .309 : .6085)
                y: parent.height * .353
                width: parent.width * .162
                height: parent.height * .268
                enabled: root.available(root.inside)
                onClicked: {
                    root.selectedLightId = root.inside.id;
                    root.toggleLight(root.inside);
                }
            }
            MouseArea {
                x: parent.width * (root.rightView ? .077 : .643)
                y: parent.height * (root.rightView ? .065 : .036)
                width: parent.width * .25
                height: parent.height * .17
                enabled: root.available(root.rightView ? root.rightSide : root.leftSide)
                onClicked: {
                    const target = root.rightView ? root.rightSide : root.leftSide;
                    root.selectedLightId = target.id;
                    root.toggleLight(target);
                }
            }
            MouseArea {
                x: parent.width * (root.rightView ? .036 : .74)
                y: 0
                width: parent.width * .12
                height: parent.height * .14
                enabled: root.available(root.rear)
                onClicked: {
                    root.selectedLightId = root.rear.id;
                    root.toggleLight(root.rear);
                }
            }
            MouseArea {
                x: parent.width * (root.rightView ? .457 : .281)
                y: parent.height * (root.rightView ? .039 : .078)
                width: parent.width * .315
                height: parent.height * .145
                enabled: root.adapter.customCommandsAllowed === true && root.highBeamAvailable && root.highBeamChannel > 0
                onClicked: {
                    root.selectedLightId = "high_beam_manual";
                    root.adapter.command("starpower", "set", root.highBeamManualOn ? 0 : 1, {
                        channel: root.highBeamChannel
                    });
                }
            }
            MouseArea {
                x: parent.width * (root.rightView ? .457 : .281)
                y: parent.height * (root.rightView ? .19 : .22)
                width: parent.width * .315
                height: parent.height * .12
                enabled: root.available(root.frontWhite)
                onClicked: root.setFrontMode("white")
            }
        }

        Row {
            x: 8
            y: 286
            spacing: 4

            Repeater {
                model: [
                    {
                        label: "Fahrerseite",
                        right: false
                    },
                    {
                        label: "Beifahrerseite",
                        right: true
                    }
                ]
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool selected: root.rightView === modelData.right
                    width: 210
                    height: 29
                    radius: 10
                    color: selected ? style.selectedBlue : style.inner
                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData.label
                        color: parent.selected ? style.blue : style.muted
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.rightView = parent.modelData.right
                    }
                }
            }
        }
    }

    CamperV2Card {
        x: 461
        y: 8
        width: 327
        height: 322
        dayMode: root.dayMode

        Row {
            x: 6
            y: 6
            spacing: 4

            Repeater {
                model: [
                    {
                        label: "Camping",
                        id: "camping"
                    },
                    {
                        label: "Nacht",
                        id: "night"
                    },
                    {
                        label: "Alles aus",
                        id: "all_off"
                    }
                ]
                delegate: Rectangle {
                    required property var modelData
                    width: 102
                    height: 31
                    radius: 10
                    color: sceneMouse.pressed ? style.pressed : style.inner
                    opacity: root.adapter.customCommandsAllowed === true ? 1 : .5
                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData.label
                        color: style.text
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }
                    MouseArea {
                        id: sceneMouse
                        anchors.fill: parent
                        enabled: root.adapter.customCommandsAllowed === true
                        onClicked: root.runScene(parent.modelData.id)
                    }
                }
            }
        }

        Grid {
            x: 6
            y: 43
            columns: 2
            spacing: 4

            Repeater {
                model: [
                    {
                        id: "inside_main",
                        name: "Innen",
                        icon: "cabinLight"
                    },
                    {
                        id: "outside_left",
                        name: "Links",
                        icon: "workLightLeft"
                    },
                    {
                        id: "outside_right",
                        name: "Rechts",
                        icon: "workLightRight"
                    },
                    {
                        id: "outside_rear",
                        name: "Hinten",
                        icon: "rearLight"
                    }
                ]
                delegate: Rectangle {
                    required property var modelData
                    readonly property var lightData: root.findLight(modelData.id)
                    readonly property bool lightOn: lightData.on === true
                    readonly property bool isAvailable: root.available(lightData)
                    readonly property bool selected: root.selectedLightId === modelData.id
                    width: 155
                    height: 61
                    radius: 13
                    color: lightOn ? style.selectedBlue : style.panel
                    border.color: lightOn ? style.blue : (selected ? style.blue : style.border)
                    border.width: lightOn || selected ? 2 : 1
                    opacity: isAvailable ? 1 : .5

                    CamperV2Icon {
                        x: 8
                        y: 8
                        width: 38
                        height: 38
                        kind: parent.modelData.icon
                        lineColor: parent.lightOn ? style.blue : style.muted
                        strokeWidth: 1.7
                    }
                    Text {
                        x: 52
                        y: 9
                        width: 94
                        text: parent.modelData.name
                        color: parent.lightOn ? style.blue : style.text
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                    Text {
                        x: 52
                        y: 32
                        width: 94
                        text: parent.isAvailable ? root.percent(parent.lightData) + " %" : "–"
                        color: style.muted
                        font.pixelSize: 9
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: parent.isAvailable
                        onClicked: {
                            root.selectedLightId = parent.modelData.id;
                            root.toggleLight(parent.lightData);
                        }
                    }
                }
            }

            Rectangle {
                width: 155
                height: 61
                radius: 13
                color: root.frontActive ? (root.frontIsAmber ? "#302314" : style.selectedBlue) : style.panel
                border.color: root.frontActive ? (root.frontIsAmber ? style.orange : style.blue) : style.border

                Row {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 2

                    Repeater {
                        model: [
                            {
                                mode: "white",
                                name: "Weiß",
                                icon: "lightBar"
                            },
                            {
                                mode: "orange",
                                name: "Orange",
                                icon: "warningBar"
                            }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool active: modelData.mode === "white" ? root.frontWhite.on === true : root.frontAmber.on === true
                            width: 73
                            height: 55
                            radius: 10
                            color: "transparent"
                            CamperV2Icon {
                                x: 22
                                y: 4
                                width: 30
                                height: 30
                                kind: parent.modelData.icon
                                lineColor: parent.active ? (parent.modelData.mode === "orange" ? style.orange : style.blue) : style.muted
                                strokeWidth: 1.5
                            }
                            Text {
                                x: 0
                                y: 36
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: parent.modelData.name
                                color: parent.active ? (parent.modelData.mode === "orange" ? style.orange : style.blue) : style.text
                                font.pixelSize: 8
                            }
                            MouseArea {
                                anchors.fill: parent
                                enabled: root.available(parent.modelData.mode === "orange" ? root.frontAmber : root.frontWhite)
                                onClicked: root.setFrontMode(parent.modelData.mode)
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: 155
                height: 61
                radius: 13
                color: root.highBeamManualOn ? style.selectedBlue : style.panel
                border.color: root.highBeamOn ? style.blue : (root.selectedLightId === "high_beam_manual" ? style.blue : style.border)
                border.width: root.highBeamOn || root.selectedLightId === "high_beam_manual" ? 2 : 1
                opacity: root.highBeamAvailable ? 1 : .5

                CamperV2Icon {
                    x: 8
                    y: 8
                    width: 39
                    height: 39
                    kind: "highBeam"
                    lineColor: root.highBeamOn ? style.blue : style.muted
                    strokeWidth: 1.7
                }
                Text {
                    x: 54
                    y: 0
                    width: 92
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    text: "Fernlicht"
                    color: root.highBeamOn ? style.blue : style.text
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: root.adapter.customCommandsAllowed === true && root.highBeamAvailable
                    onClicked: {
                        root.selectedLightId = "high_beam_manual";
                        root.adapter.command("starpower", "set", root.highBeamManualOn ? 0 : 1, {
                            channel: root.highBeamChannel
                        });
                    }
                }
            }
        }

        Rectangle {
            x: 6
            y: 240
            width: 315
            height: 76
            radius: 12
            color: style.inner
            opacity: root.selectedDimmable && root.available(root.selectedLight) ? 1 : .52

            Text {
                x: 10
                y: 7
                text: root.selectedLight.name || "Helligkeit"
                color: style.text
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
            Text {
                x: 243
                y: 7
                width: 61
                horizontalAlignment: Text.AlignRight
                text: root.selectedDimmable && root.available(root.selectedLight) ? root.percent(root.selectedLight) + " %" : "–"
                color: style.muted
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
            CamperV2Range {
                x: 7
                y: 28
                width: 301
                height: 34
                dayMode: root.dayMode
                value: root.percent(root.selectedLight)
                available: root.selectedDimmable && root.available(root.selectedLight)
                accent: style.blue
                onMoved: value => root.dimLight(root.selectedLight, value)
            }
        }
    }
}
