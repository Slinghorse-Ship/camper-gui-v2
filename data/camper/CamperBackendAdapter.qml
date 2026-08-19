/* Shared facade: native Victron values plus CamperControl's custom API. */

import QtQuick

Item {
    id: root

    property alias pollingEnabled: custom.pollingEnabled
    readonly property bool connected: nativeData.connected
    // customReadConnected remains true in VRM monitor-only mode. The legacy
    // customConnected name is deliberately the control-capable connection so
    // existing buttons become unavailable without hiding received values.
    readonly property bool customReadConnected: custom.connected
    readonly property bool customCommandsAllowed: custom.connected && custom.commandsAllowed
    readonly property bool customConnected: customCommandsAllowed
    readonly property var stateData: custom.stateData
    readonly property string errorText: custom.errorText
    readonly property var weatherData: weather.weatherData
    readonly property bool weatherConnected: weather.connected
    readonly property string weatherErrorText: weather.errorText

    readonly property real batterySoc: nativeData.batterySoc
    readonly property real batteryVoltage: nativeData.batteryVoltage
    readonly property real solarPower: nativeData.solarPower
    readonly property bool hasBatterySoc: nativeData.hasBatterySoc
    readonly property bool hasBatteryVoltage: nativeData.hasBatteryVoltage
    readonly property bool hasSolarPower: nativeData.hasSolarPower

    function command(target, action, value, extra) {
        custom.command(target, action, value, extra);
    }

    function activateQuick(item) {
        custom.activateQuick(item);
    }

    function setQuickAccessIds(ids) {
        custom.setQuickAccessIds(ids);
    }

    CamperVictronAdapter {
        id: nativeData
    }

    CamperNodeRedAdapter {
        id: custom
    }

    CamperWeatherAdapter {
        id: weather
    }
}
