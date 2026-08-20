/*
** Transport facade for CamperControl's validated API v2.
**
** The Cerbo service is the single reader of Node-RED state. Native GX reads
** its D-Bus values and WASM receives the same values through Victron's MQTT
** bridge. This avoids a second one-second HTTP poll and duplicate JSON work.
*/

import QtQuick

Item {
    id: root

    property bool pollingEnabled: true
    readonly property bool connected: transport.item ? transport.item.connected : false
    readonly property bool commandsAllowed: transport.item ? transport.item.commandsAllowed : false
    readonly property bool remoteSession: transport.item ? transport.item.remoteSession : false
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

    function setFavoriteIds(ids) {
        if (transport.item) {
            transport.item.setFavoriteIds(ids);
        }
    }

    Loader {
        id: transport
        sourceComponent: bridgeTransport
        onLoaded: item.pollingEnabled = Qt.binding(() => root.pollingEnabled)
    }

    Component {
        id: bridgeTransport
        CamperNodeRedMqttAdapter {}
    }
}
