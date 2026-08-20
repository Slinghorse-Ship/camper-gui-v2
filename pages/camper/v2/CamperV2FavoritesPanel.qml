pragma ComponentBehavior: Bound

import QtQuick
import "../../../components/camper/v2"

Item {
    id: root

    required property var adapter
    property bool dayMode: false
    property bool editing: false
    property var favoriteIds: []

    readonly property var snapshot: adapter.stateData || ({})
    readonly property var favorites: snapshot.ui && snapshot.ui.favorites ? snapshot.ui.favorites.slice(0, 4) : []
    readonly property var options: snapshot.ui && snapshot.ui.quickAccessOptions ? snapshot.ui.quickAccessOptions.slice(0, 32) : []

    CamperV2Style {
        id: style
        dayMode: root.dayMode
    }

    function itemIcon(item) {
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
        if (itemId.indexOf("inverter") >= 0)
            return "plug";
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
        const ids = snapshot.ui && snapshot.ui.favoriteIds;
        favoriteIds = ids && Array.isArray(ids) ? ids.slice(0, 4) : [];
    }

    function selected(optionId) {
        return favoriteIds.indexOf(String(optionId || "")) >= 0;
    }

    function toggleOption(option) {
        if (adapter.customCommandsAllowed !== true || !option || !option.id)
            return;
        const optionId = String(option.id);
        const updated = favoriteIds.slice(0, 4);
        const current = updated.indexOf(optionId);
        if (current >= 0) {
            updated.splice(current, 1);
        } else if (updated.length < 4) {
            updated.push(optionId);
        } else {
            return;
        }
        favoriteIds = updated;
        adapter.setFavoriteIds(updated);
    }

    onVisibleChanged: {
        if (visible) {
            editing = false;
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
        border.color: root.editing ? style.green : style.border
        opacity: root.adapter.customCommandsAllowed === true ? 1 : .55

        Text {
            anchors.centerIn: parent
            text: root.editing ? "Fertig" : "Anpassen"
            color: root.editing ? style.green : style.text
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
        text: root.editing ? "Favoriten auswählen" : "Antippen zum Schalten"
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
            model: root.favorites

            delegate: CamperV2Card {
                id: favoriteTile

                required property var modelData
                readonly property bool isActive: modelData.active === true
                readonly property bool isAvailable: modelData.available !== false
                readonly property bool remoteProtected: root.adapter.remoteSession === true && isActive && String(modelData.id || "").toLowerCase().indexOf("starlink") >= 0

                objectName: "camperV2FavoriteTile-" + String(modelData.id || "unknown")
                width: (root.width - 10) / 2
                height: 124
                dayMode: root.dayMode
                active: isActive
                available: isAvailable
                accent: style.green
                color: favoriteArea.pressed ? style.pressed : (isActive ? style.selectedGreen : style.panel)

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
                        kind: root.itemIcon(favoriteTile.modelData)
                        lineColor: favoriteTile.isActive ? "#f4fffb" : style.muted
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
                    elide: Text.ElideRight
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
                    id: favoriteArea
                    anchors.fill: parent
                    enabled: root.adapter.customCommandsAllowed === true && parent.isAvailable && !parent.remoteProtected
                    onClicked: root.adapter.activateQuick(favoriteTile.modelData)
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: !root.editing && root.favorites.length === 0
        text: root.adapter.customReadConnected === true ? "Noch keine Favoriten gewählt" : "Camper-Backend nicht verbunden"
        color: style.muted
        font.pixelSize: 12
    }

    ListView {
        id: optionList
        x: 0
        y: 54
        width: root.width
        height: root.height - 80
        spacing: 6
        clip: true
        visible: root.editing
        model: root.options

        delegate: Rectangle {
            id: optionRow

            required property var modelData
            readonly property bool isSelected: root.selected(modelData.id)

            width: optionList.width
            height: 52
            radius: 12
            color: optionArea.pressed ? style.pressed : (isSelected ? style.selectedGreen : style.inner)
            border.color: isSelected ? style.green : style.border
            opacity: isSelected || root.favoriteIds.length < 4 ? 1 : .5

            CamperV2Icon {
                x: 12
                y: 13
                width: 26
                height: 26
                kind: root.itemIcon(optionRow.modelData)
                lineColor: optionRow.isSelected ? style.green : style.muted
                strokeWidth: 1.7
            }
            Text {
                x: 49
                y: 0
                width: parent.width - 95
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                text: parent.modelData.name || parent.modelData.id || "Funktion"
                color: style.text
                elide: Text.ElideRight
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }
            CamperV2Icon {
                x: parent.width - 37
                y: 14
                width: 24
                height: 24
                kind: parent.isSelected ? "check" : "favorite"
                lineColor: parent.isSelected ? style.green : style.muted
                strokeWidth: 1.8
            }
            MouseArea {
                id: optionArea
                anchors.fill: parent
                enabled: root.adapter.customCommandsAllowed === true && (parent.isSelected || root.favoriteIds.length < 4)
                onClicked: root.toggleOption(optionRow.modelData)
            }
        }
    }

    Text {
        x: 2
        y: root.height - 21
        width: root.width - 4
        text: root.editing ? root.favoriteIds.length + " / 4 gewählt · Speicherung auf dem Cerbo" : ""
        color: style.muted
        horizontalAlignment: Text.AlignRight
        font.pixelSize: 9
    }
}
