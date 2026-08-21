pragma ComponentBehavior: Bound

import QtQuick
import "../../../components/camper/v2"

Item {
    id: root

    required property var adapter
    property bool dayMode: false
    property bool editing: false
    property var quickAccessIds: []

    readonly property var snapshot: adapter.stateData || ({})
    readonly property var quickAccess: snapshot.ui && snapshot.ui.quickAccess ? snapshot.ui.quickAccess.slice(0, 4) : []
    readonly property var quickOptions: snapshot.ui && snapshot.ui.quickAccessOptions ? snapshot.ui.quickAccessOptions.slice(0, 32) : []

    CamperV2Style {
        id: style
        dayMode: root.dayMode
    }

    function quickIcon(item) {
        const iconName = String(item && item.icon || "").toLowerCase();
        const itemId = String(item && item.id || "").toLowerCase();
        if (iconName.indexOf("pump") >= 0 || itemId.indexOf("water_pump") >= 0)
            return "pump";
        if (iconName.indexOf("satellite") >= 0 || itemId.indexOf("starlink") >= 0)
            return "satellite";
        if (iconName.indexOf("outlet") >= 0 || itemId.indexOf("outlets") >= 0)
            return "outlet";
        if (iconName.indexOf("heater") >= 0 || itemId.indexOf("heater") >= 0)
            return "flame";
        if (iconName.indexOf("fan") >= 0 || itemId.indexOf("fan") >= 0)
            return "fan";
        if (itemId.indexOf("light") >= 0 || iconName.indexOf("bulb") >= 0)
            return "lightNav";
        return "system";
    }

    function statusText(item) {
        if (!item || item.available === false)
            return "Nicht verfügbar";
        if (item.status)
            return String(item.status);
        return item.active === true ? "Ein" : "Aus";
    }

    function syncFromBackend() {
        const ids = snapshot.ui && snapshot.ui.quickAccessIds;
        quickAccessIds = ids && ids.length ? ids.slice(0, 4) : [];
    }

    function optionFor(id) {
        for (let index = 0; index < quickOptions.length; ++index) {
            if (quickOptions[index].id === id)
                return quickOptions[index];
        }
        return {
            id: id || "",
            name: id || "Nicht belegt",
            group: "",
            icon: "system"
        };
    }

    function cycleUniqueSelection(values, index, direction) {
        const choices = [];
        for (let optionIndex = 0; optionIndex < quickOptions.length; ++optionIndex)
            choices.push(quickOptions[optionIndex].id);
        const updated = values.slice(0, 4);
        while (updated.length < 4)
            updated.push("");
        const step = direction < 0 ? -1 : 1;
        let current = choices.indexOf(updated[index]);
        if (current < 0)
            current = step > 0 ? -1 : 0;
        for (let offset = 1; offset <= choices.length; ++offset) {
            const choiceIndex = (current + step * offset + choices.length) % choices.length;
            const wanted = choices[choiceIndex];
            let occupied = false;
            for (let slotIndex = 0; slotIndex < updated.length; ++slotIndex) {
                if (slotIndex !== index && updated[slotIndex] === wanted) {
                    occupied = true;
                    break;
                }
            }
            if (!occupied) {
                updated[index] = wanted;
                return updated;
            }
        }
        return updated;
    }

    function changeQuickAccess(index, direction) {
        if (adapter.customCommandsAllowed !== true || quickOptions.length === 0 || index < 0 || index >= 4)
            return;
        const updated = cycleUniqueSelection(quickAccessIds, index, direction);
        quickAccessIds = updated;
        adapter.setQuickAccessIds(updated);
    }

    onVisibleChanged: {
        if (visible) {
            syncFromBackend();
        }
    }
    Component.onCompleted: syncFromBackend()

    Rectangle {
        x: root.width - 116
        y: 0
        width: 106
        height: 44
        radius: 12
        color: editArea.pressed ? style.pressed : style.inner
        border.color: root.editing ? style.blue : style.border
        opacity: root.adapter.customCommandsAllowed === true ? 1 : .55

        Text {
            anchors.centerIn: parent
            text: root.editing ? "Fertig" : "Anpassen"
            color: root.editing ? style.blue : style.text
            font.pixelSize: 10
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: editArea
            anchors.fill: parent
            enabled: root.adapter.customCommandsAllowed === true
            onClicked: {
                root.editing = !root.editing;
                if (root.editing)
                    root.syncFromBackend();
            }
        }
    }

    Text {
        x: 2
        y: 9
        width: root.width - 130
        height: 24
        text: root.editing ? "Schnellzugriff auswählen" : "Antippen zum Schalten"
        color: style.muted
        elide: Text.ElideRight
        clip: true
        font.pixelSize: 10
    }

    Grid {
        x: 0
        y: 56
        columns: 2
        columnSpacing: 10
        rowSpacing: 10
        visible: !root.editing

        Repeater {
            model: root.quickAccess

            delegate: CamperV2Card {
                id: quickTile

                required property var modelData
                readonly property bool isActive: modelData.active === true
                readonly property bool isAvailable: modelData.available !== false
                readonly property bool remoteProtected: root.adapter.remoteSession === true && isActive && String(modelData.id || "").toLowerCase().indexOf("starlink") >= 0

                objectName: "camperV2QuickTile-" + String(modelData.id || "unknown")
                width: (root.width - 10) / 2
                height: 124
                dayMode: root.dayMode
                active: isActive
                available: isAvailable
                accent: style.green
                color: quickArea.pressed ? style.pressed : (isActive ? style.selectedGreen : style.panel)

                Rectangle {
                    x: 14
                    y: 18
                    width: 48
                    height: 48
                    radius: 15
                    color: parent.isActive ? style.green : style.inner

                    CamperV2Icon {
                        anchors.centerIn: parent
                        width: 27
                        height: 27
                        kind: root.quickIcon(quickTile.modelData)
                        lineColor: quickTile.isActive ? "#f4fffb" : style.muted
                        strokeWidth: 1.8
                    }
                }
                Text {
                    x: 76
                    y: 21
                    width: parent.width - 90
                    text: parent.modelData.name || "Favorit"
                    color: style.text
                    elide: Text.ElideRight
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }
                Text {
                    x: 76
                    y: 48
                    width: parent.width - 90
                    text: root.statusText(parent.modelData)
                    color: parent.isActive ? style.green : style.muted
                    elide: Text.ElideRight
                    font.pixelSize: 10
                }
                Text {
                    x: 15
                    y: 91
                    width: parent.width - 30
                    text: parent.remoteProtected ? "Remote geschützt" : (root.adapter.customCommandsAllowed === true ? "Antippen zum Schalten" : "Nur Anzeige")
                    color: style.muted
                    font.pixelSize: 8
                }

                CamperV2Icon {
                    visible: parent.remoteProtected
                    x: parent.width - 29
                    y: 14
                    width: 16
                    height: 16
                    kind: "lock"
                    lineColor: style.green
                    strokeWidth: 1.6
                }

                MouseArea {
                    id: quickArea
                    anchors.fill: parent
                    enabled: root.adapter.customCommandsAllowed === true && parent.isAvailable && !parent.remoteProtected
                    onClicked: root.adapter.activateQuick(quickTile.modelData)
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: !root.editing && root.quickAccess.length === 0
        text: root.adapter.customReadConnected === true ? "Noch keine Favoriten konfiguriert" : "Camper-Backend nicht verbunden"
        color: style.muted
        font.pixelSize: 12
    }

    Column {
        x: 0
        y: 54
        width: root.width
        spacing: 7
        visible: root.editing

        Repeater {
            model: 4

            delegate: Rectangle {
                id: editorSlot

                required property int index
                property var option: root.optionFor(root.quickAccessIds[index])

                width: root.width
                height: 67
                radius: 13
                color: style.inner
                border.color: style.border

                Text {
                    x: 13
                    y: 9
                    text: "PLATZ " + (parent.index + 1)
                    color: style.muted
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                }
                Text {
                    x: 13
                    y: 27
                    width: parent.width - 132
                    text: parent.option.name
                    color: style.text
                    elide: Text.ElideRight
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
                Rectangle {
                    x: parent.width - 108
                    y: 11
                    width: 44
                    height: 44
                    radius: 12
                    color: previousArea.pressed ? style.pressed : style.panel
                    opacity: root.adapter.customCommandsAllowed === true ? 1 : .5
                    Text {
                        anchors.centerIn: parent
                        text: "−"
                        color: style.text
                        font.pixelSize: 20
                    }
                    MouseArea {
                        id: previousArea
                        anchors.fill: parent
                        enabled: root.adapter.customCommandsAllowed === true
                        onClicked: root.changeQuickAccess(editorSlot.index, -1)
                    }
                }
                Rectangle {
                    x: parent.width - 54
                    y: 11
                    width: 44
                    height: 44
                    radius: 12
                    color: nextArea.pressed ? style.pressed : style.panel
                    opacity: root.adapter.customCommandsAllowed === true ? 1 : .5
                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: style.text
                        font.pixelSize: 20
                    }
                    MouseArea {
                        id: nextArea
                        anchors.fill: parent
                        enabled: root.adapter.customCommandsAllowed === true
                        onClicked: root.changeQuickAccess(editorSlot.index, 1)
                    }
                }
            }
        }
    }

    Text {
        x: 2
        y: root.height - 21
        width: root.width - 4
        text: root.adapter.customCommandsAllowed === true ? "Änderungen werden über CamperControl auf dem Cerbo gespeichert." : "Monitor-only · Zustände sichtbar, Schalten und Anpassen gesperrt."
        color: root.adapter.customCommandsAllowed === true ? style.muted : style.orange
        font.pixelSize: 9
    }
}
