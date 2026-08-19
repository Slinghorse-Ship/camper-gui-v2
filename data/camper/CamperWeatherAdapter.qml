/*
** Read-only weather transport shared by GX and WASM.
**
** The CamperControl service owns acquisition and DWD normalization. VeQuickItem
** keeps the UI on gui-v2's existing D-Bus/MQTT path; QML never performs a
** direct network request.
*/

import QtQuick
import Victron.VenusOS

Item {
    id: root

    property var weatherData: ({})
    property string errorText: ""
    property bool hasPayload: false

    readonly property string serviceUid: BackendConnection.serviceUidFromName("com.victronenergy.campercontrol", 0)
    readonly property bool transportReady: BackendConnection.state === BackendConnection.Ready
    readonly property bool connected: transportReady && weatherState.valid && hasPayload

    function rebuildWeather() {
        if (!weatherState.valid || weatherState.value === null || weatherState.value === undefined || weatherState.value === "") {
            weatherData = ({});
            hasPayload = false;
            errorText = transportReady ? "Wetterdaten noch nicht verfügbar" : "Camper-D-Bus-Brücke nicht verbunden";
            return;
        }

        try {
            const value = typeof weatherState.value === "string" ? JSON.parse(weatherState.value) : weatherState.value;
            if (!value || typeof value !== "object" || Array.isArray(value)) {
                throw new Error("weather payload is not an object");
            }
            weatherData = value;
            hasPayload = true;
            errorText = "";
        } catch (error) {
            weatherData = ({});
            hasPayload = false;
            errorText = "Camper-Wetterdaten ungültig";
        }
    }

    VeQuickItem {
        id: weatherState
        uid: root.serviceUid + "/State/Weather"
        onValueChanged: root.rebuildWeather()
    }

    Connections {
        target: BackendConnection

        function onStateChanged() {
            root.rebuildWeather();
        }
    }

    Component.onCompleted: rebuildWeather()
}
