/*
** Local CamperControl HTTP transport.
**
** This is intentionally used only by the native GX process. A browser opened
** through VRM cannot reach the GX device's loopback Node-RED API.
*/

import QtQuick

Item {
    id: root

    property bool pollingEnabled: true
    property bool connected: false
    property bool requestActive: false
    property var stateData: ({})
    property var lastCommandResult: ({})
    property string errorText: ""
    property int requestSequence: 0

    readonly property string baseUrl: "http://127.0.0.1:1880/camper/api/v2"
    readonly property bool commandsAllowed: true

    function parseResponse(xhr) {
        try {
            return JSON.parse(xhr.responseText || "{}");
        } catch (error) {
            return null;
        }
    }

    function fetchState() {
        if (!pollingEnabled || requestActive) {
            return;
        }
        requestActive = true;
        const xhr = new XMLHttpRequest();
        xhr.open("GET", baseUrl + "/state", true);
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) {
                return;
            }
            root.requestActive = false;
            const packet = root.parseResponse(xhr);
            if (xhr.status >= 200 && xhr.status < 300 && packet) {
                root.stateData = packet.state || packet;
                root.connected = true;
                root.errorText = "";
            } else {
                root.connected = false;
                root.errorText = "Camper-API nicht erreichbar (" + xhr.status + ")";
            }
        };
        try {
            xhr.send();
        } catch (error) {
            requestActive = false;
            connected = false;
            errorText = String(error);
        }
    }

    function command(target, action, value, extra) {
        if (!connected) {
            errorText = "Camper-API nicht verbunden";
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
        body.requestId = "gui-v2-" + new Date().getTime() + "-" + requestSequence;

        const xhr = new XMLHttpRequest();
        xhr.open("POST", baseUrl + "/command", true);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) {
                return;
            }
            const packet = root.parseResponse(xhr);
            if (xhr.status >= 200 && xhr.status < 300 && packet) {
                root.lastCommandResult = packet;
                root.errorText = "";
                commandRefresh.restart();
            } else {
                root.errorText = packet && packet.error ? String(packet.error) : "Befehl fehlgeschlagen (" + xhr.status + ")";
            }
        };
        try {
            xhr.send(JSON.stringify(body));
        } catch (error) {
            errorText = String(error);
        }
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

    Timer {
        interval: 1000
        running: root.pollingEnabled
        repeat: true
        triggeredOnStart: true
        onTriggered: root.fetchState()
    }

    Timer {
        id: commandRefresh
        interval: 150
        repeat: false
        onTriggered: root.fetchState()
    }
}
