import QtQuick
import QtQuick.Window
import "../../pages/camper"

Window {
	id: window
	objectName: "previewWindow"

	property int settingsClickCount: 0
	property int closeClickCount: 0
	property int lastRequestedPage: -1

	width: 800
	height: 480
	visible: true
	color: "#05090c"
	title: "CamperControl gui-v2 Phase 2 preview"

	QtObject {
		id: previewAdapter

		readonly property bool connected: true
		readonly property real batterySoc: 82
		readonly property real batteryVoltage: 12.7
		readonly property real solarPower: 486
		readonly property bool hasBatterySoc: true
		readonly property bool hasBatteryVoltage: true
		readonly property bool hasSolarPower: true
	}

	CamperHome {
		anchors.fill: parent
		adapter: previewAdapter
		logoSource: "../../images/camper_logo.png"
		onOpenVictronSettings: window.settingsClickCount += 1
		onCloseRequested: window.closeClickCount += 1
		onPageRequested: (page) => window.lastRequestedPage = page
	}
}
