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
    property bool sceneEditorVisible: false
    property string sceneEditorId: "camping"
    property var sceneDraft: ({})

    readonly property var snapshot: adapter.stateData || ({})
    readonly property var lightItems: snapshot.lights && snapshot.lights.items ? snapshot.lights.items.slice(0, 16) : []
    readonly property var highBeam: snapshot.vehicle && snapshot.vehicle.highBeam ? snapshot.vehicle.highBeam : ({})
    readonly property var lightScenes: snapshot.operations && Array.isArray(snapshot.operations.lightScenes) ? snapshot.operations.lightScenes : []
    readonly property var sceneLightModels: [
        {
            id: "inside_main",
            name: "Innenlicht"
        },
        {
            id: "outside_left",
            name: "Außen links"
        },
        {
            id: "outside_right",
            name: "Außen rechts"
        },
        {
            id: "outside_rear",
            name: "Hecklicht"
        },
        {
            id: "outside_front_white",
            name: "Front weiß"
        },
        {
            id: "outside_front_amber",
            name: "Front orange"
        }
    ]

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

    function pointDistance(x1, y1, x2, y2) {
        const dx = x1 - x2;
        const dy = y1 - y2;
        return Math.sqrt(dx * dx + dy * dy);
    }

    function lineDistance(x, y, x1, y1, x2, y2) {
        const dx = x2 - x1;
        const dy = y2 - y1;
        const lengthSquared = dx * dx + dy * dy;
        if (lengthSquared <= 0)
            return pointDistance(x, y, x1, y1);
        const position = Math.max(0, Math.min(1, ((x - x1) * dx + (y - y1) * dy) / lengthSquared));
        return pointDistance(x, y, x1 + position * dx, y1 + position * dy);
    }

    function handleVehicleLampClick(x, y, itemWidth, itemHeight) {
        const sourceX = x * 560 / itemWidth;
        const sourceY = y * 360 / itemHeight;
        const sideDistance = rightView ? Math.min(pointDistance(sourceX, sourceY, 71, 44.5), pointDistance(sourceX, sourceY, 155.5, 43.5)) : Math.min(pointDistance(sourceX, sourceY, 376, 37.5), pointDistance(sourceX, sourceY, 462.5, 38.5));
        const rearDistance = pointDistance(sourceX, sourceY, rightView ? 50 : 439, 12);
        const highBeamDistance = rightView ? lineDistance(sourceX, sourceY, 263, 36, 399, 41) : lineDistance(sourceX, sourceY, 168, 49, 317, 49);
        const nearest = Math.min(sideDistance, rearDistance, highBeamDistance);

        // Keep the hit areas forgiving without turning blank roof/body pixels
        // into hidden switches. 34 source pixels equal about 27 px at 800x480.
        if (nearest > 34)
            return;
        if (nearest === rearDistance) {
            if (available(rear)) {
                selectedLightId = rear.id;
                toggleLight(rear);
            }
        } else if (nearest === sideDistance) {
            const target = rightView ? rightSide : leftSide;
            if (available(target)) {
                selectedLightId = target.id;
                toggleLight(target);
            }
        } else if (adapter.customCommandsAllowed === true && highBeamAvailable && highBeamChannel > 0) {
            selectedLightId = "high_beam_manual";
            adapter.command("starpower", "set", highBeamManualOn ? 0 : 1, {
                channel: highBeamChannel
            });
        }
    }

    function runScene(sceneId) {
        if (adapter.customCommandsAllowed === true)
            adapter.command("scene", "run", sceneId, {
                sceneId: sceneId
            });
    }

    function sceneProfile(sceneId) {
        for (let index = 0; index < lightScenes.length; ++index) {
            if (lightScenes[index] && String(lightScenes[index].id) === sceneId)
                return lightScenes[index];
        }
        return ({
                id: sceneId,
                values: ({})
            });
    }

    function openSceneEditor(sceneId) {
        sceneEditorId = ["camping", "night", "all_off"].indexOf(sceneId) >= 0 ? sceneId : "camping";
        const source = sceneProfile(sceneEditorId).values || ({});
        const next = ({});
        for (let index = 0; index < sceneLightModels.length; ++index) {
            const lightId = sceneLightModels[index].id;
            if (Object.prototype.hasOwnProperty.call(source, lightId) && validSceneValue(source[lightId]))
                next[lightId] = Math.max(0, Math.min(100, Math.round(Number(source[lightId]))));
        }
        sceneDraft = next;
        sceneEditorVisible = true;
    }

    function validSceneValue(value) {
        return value !== null && value !== undefined && value !== "" && isFinite(Number(value));
    }

    function sceneValue(lightId) {
        return Object.prototype.hasOwnProperty.call(sceneDraft, lightId) ? Number(sceneDraft[lightId]) : null;
    }

    function sceneMode(lightId) {
        const value = sceneValue(lightId);
        return value === null ? "keep" : (value <= 0 ? "off" : "on");
    }

    function setSceneMode(lightId, mode) {
        const next = Object.assign({}, sceneDraft);
        if (mode === "keep") {
            delete next[lightId];
        } else if (mode === "off") {
            next[lightId] = 0;
        } else {
            const previous = sceneValue(lightId);
            next[lightId] = previous !== null && previous > 0 ? previous : 100;
        }
        sceneDraft = next;
    }

    function setSceneDim(lightId, value) {
        const next = Object.assign({}, sceneDraft);
        next[lightId] = Math.max(1, Math.min(100, Math.round(Number(value))));
        sceneDraft = next;
    }

    function saveSceneProfile() {
        if (adapter.customCommandsAllowed !== true)
            return;
        const values = ({});
        for (let index = 0; index < sceneLightModels.length; ++index) {
            const lightId = sceneLightModels[index].id;
            const value = sceneValue(lightId);
            if (value !== null)
                values[lightId] = Math.max(0, Math.min(100, Math.round(value)));
        }
        const lightingScenes = ({});
        lightingScenes[sceneEditorId] = values;
        adapter.command("settings", "patch", null, {
            patch: {
                lightingScenes: lightingScenes
            }
        });
        sceneEditorVisible = false;
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
                x: parent.width * (root.rightView ? .3172 : .637)
                y: parent.height * .322
                width: parent.width * .162
                height: parent.height * .268
                enabled: root.available(root.inside)
                onClicked: {
                    root.selectedLightId = root.inside.id;
                    root.toggleLight(root.inside);
                }
            }
            MouseArea {
                x: 0
                y: 0
                width: parent.width
                height: parent.height * .24
                enabled: root.adapter.customCommandsAllowed === true
                onClicked: mouse => root.handleVehicleLampClick(mouse.x, mouse.y, width, parent.height)
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
                    },
                    {
                        label: "Anpassen",
                        id: "edit"
                    }
                ]
                delegate: Rectangle {
                    required property var modelData
                    width: modelData.id === "edit" ? 72 : 78
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
                        onClicked: parent.modelData.id === "edit" ? root.openSceneEditor("camping") : root.runScene(parent.modelData.id)
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
                        id: "outside_rear",
                        name: "Hinten",
                        icon: "rearLight"
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
                text: root.selectedDimmable && root.available(root.selectedLight) ? Math.round(dimmerRange.shownValue) + " %" : "–"
                color: style.muted
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
            CamperV2Range {
                id: dimmerRange
                x: 7
                y: 28
                width: 301
                height: 34
                dayMode: root.dayMode
                value: root.percent(root.selectedLight)
                stepSize: 1
                available: root.selectedDimmable && root.available(root.selectedLight)
                accent: style.blue
                onCommitted: value => root.dimLight(root.selectedLight, value)
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        z: 20
        visible: root.sceneEditorVisible
        color: "#b8000000"

        MouseArea {
            anchors.fill: parent
        }

        CamperV2Card {
            x: 64
            y: 8
            width: 672
            height: 326
            dayMode: root.dayMode

            Text {
                x: 14
                y: 10
                text: "Lichtszenen anpassen"
                color: style.text
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }

            Row {
                x: 177
                y: 6
                spacing: 4

                Repeater {
                    model: [
                        {
                            id: "camping",
                            label: "Camping"
                        },
                        {
                            id: "night",
                            label: "Nacht"
                        },
                        {
                            id: "all_off",
                            label: "Alles aus"
                        }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool selected: root.sceneEditorId === modelData.id
                        width: 77
                        height: 32
                        radius: 10
                        color: sceneSelect.pressed ? style.pressed : (selected ? style.selectedBlue : style.inner)
                        border.color: selected ? style.blue : style.border
                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData.label
                            color: parent.selected ? style.blue : style.muted
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                        }
                        MouseArea {
                            id: sceneSelect
                            anchors.fill: parent
                            onClicked: root.openSceneEditor(parent.modelData.id)
                        }
                    }
                }
            }

            Rectangle {
                x: 427
                y: 5
                width: 106
                height: 34
                radius: 11
                color: saveSceneArea.pressed ? style.pressed : style.selectedGreen
                border.color: style.green
                Text {
                    anchors.centerIn: parent
                    text: "Speichern"
                    color: style.green
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    id: saveSceneArea
                    anchors.fill: parent
                    enabled: root.adapter.customCommandsAllowed === true
                    onClicked: root.saveSceneProfile()
                }
            }

            Rectangle {
                x: parent.width - 49
                y: 4
                width: 40
                height: 40
                radius: 12
                color: closeSceneArea.pressed ? style.pressed : style.inner
                CamperV2Icon {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    kind: "close"
                    lineColor: style.text
                    strokeWidth: 2
                }
                MouseArea {
                    id: closeSceneArea
                    anchors.fill: parent
                    onClicked: root.sceneEditorVisible = false
                }
            }

            Grid {
                x: 10
                y: 51
                columns: 2
                columnSpacing: 8
                rowSpacing: 7

                Repeater {
                    model: root.sceneLightModels

                    delegate: Rectangle {
                        id: sceneLightRow
                        required property var modelData
                        readonly property bool dimmable: modelData.id !== "outside_front_amber"
                        readonly property real configuredValue: root.sceneValue(modelData.id) === null ? 100 : root.sceneValue(modelData.id)

                        width: 322
                        height: 82
                        radius: 12
                        color: style.inner
                        border.color: style.border

                        Text {
                            x: 10
                            y: 8
                            width: 112
                            text: parent.modelData.name
                            color: style.text
                            elide: Text.ElideRight
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }

                        Row {
                            x: 126
                            y: 5
                            spacing: 3
                            Repeater {
                                model: [
                                    {
                                        mode: "keep",
                                        label: "Lassen"
                                    },
                                    {
                                        mode: "off",
                                        label: "Aus"
                                    },
                                    {
                                        mode: "on",
                                        label: "Ein"
                                    }
                                ]
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool selected: root.sceneMode(sceneLightRow.modelData.id) === modelData.mode
                                    width: 58
                                    height: 27
                                    radius: 9
                                    color: sceneModeArea.pressed ? style.pressed : (selected ? style.selectedBlue : style.panel)
                                    border.color: selected ? style.blue : style.border
                                    Text {
                                        anchors.centerIn: parent
                                        text: parent.modelData.label
                                        color: parent.selected ? style.blue : style.muted
                                        font.pixelSize: 8
                                    }
                                    MouseArea {
                                        id: sceneModeArea
                                        anchors.fill: parent
                                        onClicked: root.setSceneMode(sceneLightRow.modelData.id, parent.modelData.mode)
                                    }
                                }
                            }
                        }

                        CamperV2Range {
                            x: 8
                            y: 40
                            width: 270
                            height: 34
                            visible: parent.dimmable && root.sceneMode(parent.modelData.id) === "on"
                            dayMode: root.dayMode
                            value: parent.configuredValue
                            stepSize: 1
                            available: true
                            accent: style.blue
                            onCommitted: value => root.setSceneDim(sceneLightRow.modelData.id, value)
                        }
                        Text {
                            x: 278
                            y: 46
                            width: 36
                            horizontalAlignment: Text.AlignRight
                            visible: parent.dimmable && root.sceneMode(parent.modelData.id) === "on"
                            text: Math.round(parent.configuredValue) + "%"
                            color: style.blue
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                        }
                        Text {
                            x: 10
                            y: 48
                            width: parent.width - 20
                            visible: root.sceneMode(parent.modelData.id) !== "on" || !parent.dimmable
                            text: root.sceneMode(parent.modelData.id) === "keep" ? "Beim Szenenstart unverändert" : (root.sceneMode(parent.modelData.id) === "off" ? "Wird ausgeschaltet" : "Wird eingeschaltet")
                            color: style.muted
                            font.pixelSize: 8
                        }
                    }
                }
            }
        }
    }
}
