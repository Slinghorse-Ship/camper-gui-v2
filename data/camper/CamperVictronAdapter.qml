/*
** Phase-2 native-data adapter.
**
** These properties consume gui-v2's existing System model. On GX that model is
** populated through the existing D-Bus backend; in WASM it is populated through
** the existing MQTT backend. No D-Bus or MQTT paths are duplicated here.
*/

import QtQuick
import Victron.VenusOS

QtObject {
	id: root

	readonly property bool connected: Global.backendReady
	readonly property real batterySoc: Global.system && Global.system.battery
			? Global.system.battery.stateOfCharge : NaN
	readonly property real batteryVoltage: Global.system && Global.system.battery
			? Global.system.battery.voltage : NaN
	readonly property real solarPower: Global.system && Global.system.solar
			? Global.system.solar.power : NaN

	readonly property bool hasBatterySoc: !isNaN(batterySoc)
	readonly property bool hasBatteryVoltage: !isNaN(batteryVoltage)
	readonly property bool hasSolarPower: !isNaN(solarPower)
}
