/*
** CamperControl transport for native GX and WASM (local/VRM Remote Console).
**
** VeQuickItem uses the native D-Bus producer on GX and gui-v2's existing MQTT
** producer in WASM. On VRM this is the N/R/W bridge; no UI polls Node-RED.
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
    readonly property bool remoteSession: BackendConnection.vrm
    readonly property bool commandsAllowed: !BackendConnection.vrm || BackendConnection.vrmPortalMode === BackendConnection.Full
    readonly property bool connected: pollingEnabled && transportReady && apiConnected.valid && Number(apiConnected.value) === 1 && uiState.valid

    function parseFragment(item) {
        if (!item.valid || typeof item.value !== "string" || item.value.length === 0) {
            return ({});
        }
        if (item.value.length > 131072) {
            root.errorText = "Camper-Daten überschreiten das Größenlimit";
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
                power: parseFragment(powerState),
                operations: parseFragment(operationsState)
            });
        stateData = next;
        if (connected) {
            errorText = commandsAllowed ? "" : "VRM ist auf Nur Lesen eingestellt";
        } else if (transportReady) {
            errorText = bridgeError.valid && String(bridgeError.value).length > 0 ? String(bridgeError.value) : "Camper-D-Bus-Brücke nicht verbunden";
        }
    }

    function scheduleRebuild() {
        // The bridge updates several fragments together. Coalesce that burst
        // so one logical snapshot causes one set of JSON parses and bindings.
        rebuildTimer.restart();
    }

    function isRemoteStarlinkOff(target, action, value, extra) {
        const fields = extra || ({});
        const off = value === false || Number(value) === 0;
        return remoteSession && target === "starpower" && action === "set" && Number(fields.channel) === 5 && off;
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
        if (isRemoteStarlinkOff(target, action, value, extra)) {
            errorText = "Starlink kann über VRM nicht ausgeschaltet werden";
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
        // The Cerbo validates this origin again before touching hardware. It
        // prevents a remote Starlink-off command from severing its own link.
        body.origin = remoteSession ? "vrm" : "gx";
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

    function setFavoriteIds(ids) {
        command("settings", "patch", null, {
            patch: {
                ui: {
                    favoriteIds: ids
                }
            }
        });
    }

    VeQuickItem {
        id: apiConnected
        uid: root.serviceUid + "/Status/ApiConnected"
        onValueChanged: root.scheduleRebuild()
    }

    VeQuickItem {
        id: bridgeError
        uid: root.serviceUid + "/Status/LastError"
        onValueChanged: root.scheduleRebuild()
    }

    VeQuickItem {
        id: uiState
        uid: root.serviceUid + "/State/Ui"
        onValueChanged: root.scheduleRebuild()
    }

    VeQuickItem {
        id: energyState
        uid: root.serviceUid + "/State/Energy"
        onValueChanged: root.scheduleRebuild()
    }

    VeQuickItem {
        id: waterState
        uid: root.serviceUid + "/State/Water"
        onValueChanged: root.scheduleRebuild()
    }

    VeQuickItem {
        id: climateState
        uid: root.serviceUid + "/State/Climate"
        onValueChanged: root.scheduleRebuild()
    }

    VeQuickItem {
        id: lightsState
        uid: root.serviceUid + "/State/Lights"
        onValueChanged: root.scheduleRebuild()
    }

    VeQuickItem {
        id: vehicleState
        uid: root.serviceUid + "/State/Vehicle"
        onValueChanged: root.scheduleRebuild()
    }

    VeQuickItem {
        id: powerState
        uid: root.serviceUid + "/State/Power"
        onValueChanged: root.scheduleRebuild()
    }

    VeQuickItem {
        id: operationsState
        uid: root.serviceUid + "/State/Operations"
        onValueChanged: root.scheduleRebuild()
    }

    VeQuickItem {
        id: commandItem
        uid: root.serviceUid + "/Command"
    }

    Timer {
        id: rebuildTimer
        interval: 20
        repeat: false
        onTriggered: root.rebuildState()
    }

    VeQuickItem {
        id: commandResult
        uid: root.serviceUid + "/LastCommandResult"
        onValueChanged: {
            if (!valid || typeof value !== "string" || value.length === 0 || value.length > 16384) {
                return;
            }
            try {
                root.lastCommandResult = JSON.parse(value);
                root.errorText = root.lastCommandResult.ok === false ? String(root.lastCommandResult.error || "Befehl fehlgeschlagen") : "";
            } catch (error) {
                root.errorText = "Camper-Befehlsantwort ungültig";
            }
        }
    }

    Connections {
        target: BackendConnection
        function onStateChanged() {
            root.scheduleRebuild();
        }
        function onVrmPortalModeChanged() {
            root.scheduleRebuild();
        }
    }

    Component.onCompleted: rebuildState()
}
