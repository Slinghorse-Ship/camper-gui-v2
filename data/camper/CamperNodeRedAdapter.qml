/*
** Transport facade for CamperControl's validated API v2.
**
** Native GX keeps the local loopback HTTP API. WASM always uses gui-v2's
** existing MQTT backend so the same code works both on LAN and through VRM.
*/

import QtQuick

Item {
    id: root

    property bool pollingEnabled: true
    readonly property bool connected: transport.item ? transport.item.connected : false
    readonly property bool commandsAllowed: transport.item ? transport.item.commandsAllowed : false
    readonly property var stateData: transport.item ? transport.item.stateData : ({})
    readonly property var lastCommandResult: transport.item ? transport.item.lastCommandResult : ({})
    readonly property string errorText: transport.item ? transport.item.errorText : "Camper-Transport startet"

    function command(target, action, value, extra) {
        if (transport.item) {
            transport.item.command(target, action, value, extra);
        }
    }

    function activateQuick(item) {
        if (transport.item) {
            transport.item.activateQuick(item);
        }
    }

    function setQuickAccessIds(ids) {
        if (transport.item) {
            transport.item.setQuickAccessIds(ids);
        }
    }

    Loader {
        id: transport
        sourceComponent: Qt.platform.os === "wasm" ? mqttTransport : httpTransport
        onLoaded: item.pollingEnabled = Qt.binding(() => root.pollingEnabled)
    }

    Component {
        id: httpTransport
        CamperNodeRedHttpAdapter {}
    }

    Component {
        id: mqttTransport
        CamperNodeRedMqttAdapter {}
    }
}
