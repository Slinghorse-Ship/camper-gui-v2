/*
** CamperControl transport for WASM (local Remote Console and VRM).
**
** VeQuickItem uses gui-v2's existing MQTT producer. On VRM this means the
** documented N/R/W bridge; no browser request is made to GX port 1880/1881.
*/

import QtQuick
import Victron.VenusOS

Item {
    id: root

    property bool pollingEnabled: true
    property var stateData: ({})
    property var lastCommandResult: ({})
    property string errorText: ""
    property int requestSequence: 0

    readonly property string serviceUid: BackendConnection.serviceUidFromName("com.victronenergy.campercontrol", 0)
    readonly property bool transportReady: BackendConnection.state === BackendConnection.Ready
    readonly property bool commandsAllowed: !BackendConnection.vrm || BackendConnection.vrmPortalMode === BackendConnection.Full
    readonly property bool connected: pollingEnabled
            && transportReady
            && apiConnected.valid
            && Number(apiConnected.value) === 1
            && uiState.valid

    function parseFragment(item) {
        if (!item.valid || typeof item.value !== "string" || item.value.length === 0) {
            return ({});
        }
        try {
            const value = JSON.parse(item.value);
            return value && typeof value === "object" ? value : ({});
        } catch (error) {
            root.errorText = "Camper-MQTT-Daten ungültig";
            return ({});
        }
    }

    function rebuildState() {
        const next = ({
            ui: parseFragment(uiState),
            energy: parseFragment(energyState),
            water: parseFragment(waterState),
            climate: parseFragment(climateState),
            lights: parseFragment(lightsState),
            vehicle: parseFragment(vehicleState),
            power: parseFragment(powerState)
        });
        stateData = next;
        if (connected) {
            errorText = commandsAllowed ? "" : "VRM ist auf Nur Lesen eingestellt";
        } else if (transportReady) {
            errorText = bridgeError.valid && String(bridgeError.value).length > 0
                    ? String(bridgeError.value)
                    : "Camper-D-Bus-Brücke nicht verbunden";
        }
    }

    function command(target, action, value, extra) {
        if (!connected) {
            errorText = "Camper-D-Bus-Brücke nicht verbunden";
            return;
        }
        if (!commandsAllowed) {
            errorText = "VRM ist auf Nur Lesen eingestellt";
            return;
        }

        const body = ({});
        const fields = extra || ({});
        for (const key in fields) {
            body[key] = fields[key];
        }
        body.target = target;
        body.action = action;
        body.value = value;
        requestSequence += 1;
        body.requestId = "gui-v2-mqtt-" + new Date().getTime() + "-" + requestSequence;
        commandItem.setValue(JSON.stringify(body));
        errorText = "";
    }

    function activateQuick(item) {
        const resolved = item && item.command;
        if (!item || item.available !== true || !resolved || !resolved.target) {
            return;
        }
        const extra = ({});
        for (const key in resolved) {
            if (key !== "target" && key !== "action" && key !== "value") {
                extra[key] = resolved[key];
            }
        }
        command(resolved.target, resolved.action, resolved.value, extra);
    }

    function setQuickAccessIds(ids) {
        command("settings", "patch", null, {
            patch: {
                ui: {
                    quickAccessIds: ids
                }
            }
        });
    }

    VeQuickItem {
        id: apiConnected
        uid: root.serviceUid + "/Status/ApiConnected"
        onValueChanged: root.rebuildState()
    }

    VeQuickItem {
        id: bridgeError
        uid: root.serviceUid + "/Status/LastError"
        onValueChanged: root.rebuildState()
    }

    VeQuickItem {
        id: uiState
        uid: root.serviceUid + "/State/Ui"
        onValueChanged: root.rebuildState()
    }

    VeQuickItem {
        id: energyState
        uid: root.serviceUid + "/State/Energy"
        onValueChanged: root.rebuildState()
    }

    VeQuickItem {
        id: waterState
        uid: root.serviceUid + "/State/Water"
        onValueChanged: root.rebuildState()
    }

    VeQuickItem {
        id: climateState
        uid: root.serviceUid + "/State/Climate"
        onValueChanged: root.rebuildState()
    }

    VeQuickItem {
        id: lightsState
        uid: root.serviceUid + "/State/Lights"
        onValueChanged: root.rebuildState()
    }

    VeQuickItem {
        id: vehicleState
        uid: root.serviceUid + "/State/Vehicle"
        onValueChanged: root.rebuildState()
    }

    VeQuickItem {
        id: powerState
        uid: root.serviceUid + "/State/Power"
        onValueChanged: root.rebuildState()
    }

    VeQuickItem {
        id: commandItem
        uid: root.serviceUid + "/Command"
    }

    VeQuickItem {
        id: commandResult
        uid: root.serviceUid + "/LastCommandResult"
        onValueChanged: {
            if (!valid || typeof value !== "string" || value.length === 0) {
                return;
            }
            try {
                root.lastCommandResult = JSON.parse(value);
                root.errorText = root.lastCommandResult.ok === false
                        ? String(root.lastCommandResult.error || "Befehl fehlgeschlagen")
                        : "";
            } catch (error) {
                root.errorText = "Camper-Befehlsantwort ungültig";
            }
        }
    }

    Connections {
        target: BackendConnection
        function onStateChanged() {
            root.rebuildState();
        }
        function onVrmPortalModeChanged() {
            root.rebuildState();
        }
    }

    Component.onCompleted: rebuildState()
}
