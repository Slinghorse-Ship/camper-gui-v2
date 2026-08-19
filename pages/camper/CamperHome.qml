/*
** Phase-2 Camper Home.
** Geometry, colors and interaction sizes are ported from Ford SYNC v3.9.9.
*/

import QtQuick
import "../../components/camper"

Item {
	id: root

	required property var adapter
	property url logoSource: "qrc:/images/camper_logo.png"
	signal openVictronSettings()
	signal closeRequested()
	signal pageRequested(int page)

	readonly property bool dayMode: false
	readonly property color background: "#070c10"
	readonly property color panel: "#111a21"
	readonly property color inner: "#0d151b"
	readonly property color textColor: "#f3f7f9"
	readonly property color muted: "#84939e"
	readonly property color line: "#293842"
	readonly property color blue: "#36c3fa"
	readonly property color green: "#35d2a1"
	readonly property color orange: "#f6a23c"

	width: 800
	height: 480

	function fmt(value, digits, suffix) {
		if (value === null || value === undefined || value === "" || !isFinite(Number(value))) {
			return "–"
		}
		return Number(value).toFixed(digits) + (suffix || "")
	}

	Rectangle {
		anchors.fill: parent
		color: root.background
		gradient: Gradient {
			GradientStop { position: 0.0; color: "#081016" }
			GradientStop { position: 1.0; color: "#05090c" }
		}
	}

	Rectangle {
		x: 0
		y: 0
		width: 800
		height: 58
		color: "#091016"
		border.color: root.line

		Image {
			x: 8
			y: 4
			width: 50
			height: 50
			source: root.logoSource
			fillMode: Image.PreserveAspectFit
			smooth: true
		}
		Text {
			x: 65
			y: 10
			text: "FORD TRANSIT CAMPER"
			color: root.textColor
			font.pixelSize: 17
			font.bold: true
		}
		Text {
			x: 65
			y: 31
			text: "· HOME"
			color: root.blue
			font.pixelSize: 11
			font.bold: true
		}

		Rectangle {
			x: 524
			y: 14
			width: 112
			height: 29
			radius: 15
			color: root.inner
			border.color: root.adapter.connected ? root.green : "#ef6e76"

			Rectangle {
				x: 10
				y: 10
				width: 8
				height: 8
				radius: 4
				color: root.adapter.connected ? root.green : "#ef6e76"
			}
			Text {
				x: 24
				anchors.verticalCenter: parent.verticalCenter
				text: root.adapter.connected ? "VERBUNDEN" : "VERBINDUNG"
				color: root.textColor
				font.pixelSize: 9
				font.bold: true
			}
		}

		Rectangle {
			x: 647
			y: 9
			width: 92
			height: 39
			radius: 9
			color: settingsArea.pressed ? root.inner : "transparent"
			border.color: root.line

			CamperLineIcon {
				x: 9
				y: 8
				width: 22
				height: 22
				kind: "settings"
				lineColor: root.textColor
				strokeWidth: 1.8
			}
			Text {
				x: 37
				anchors.verticalCenter: parent.verticalCenter
				text: "EINST."
				color: root.textColor
				font.pixelSize: 10
				font.bold: true
			}
			MouseArea {
				id: settingsArea
				anchors.fill: parent
				onClicked: root.openVictronSettings()
			}
		}

		Rectangle {
			x: 748
			y: 9
			width: 42
			height: 39
			radius: 9
			color: closeArea.pressed ? "#44232a" : "transparent"
			border.color: "#5a333b"

			CamperLineIcon {
				anchors.centerIn: parent
				width: 23
				height: 23
				kind: "close"
				lineColor: root.textColor
				strokeWidth: 2.6
			}
			MouseArea {
				id: closeArea
				anchors.fill: parent
				onClicked: root.closeRequested()
			}
		}
	}

	Item {
		x: 0
		y: 58
		width: 800
		height: 364

		CamperMetricTile {
			x: 10
			y: 10
			width: 188
			height: 88
			dayMode: root.dayMode
			icon: "battery"
			caption: "SMARTSHUNT"
			value: root.fmt(root.adapter.batterySoc, 0, " %")
			detail: root.adapter.hasBatteryVoltage
					? "SYSTEM " + root.fmt(root.adapter.batteryVoltage, 1, " V")
					: "VICTRON BATTERIE"
			active: root.adapter.hasBatterySoc
			accentColor: root.green
		}
		CamperMetricTile {
			x: 207
			y: 10
			width: 188
			height: 88
			dayMode: root.dayMode
			icon: "solar"
			caption: "SOLAR GESAMT"
			value: root.fmt(root.adapter.solarPower, 0, " W")
			detail: root.adapter.hasSolarPower ? "VICTRON SYSTEM" : "KEINE VICTRON DATEN"
			active: root.adapter.hasSolarPower && root.adapter.solarPower > 0
			accentColor: "#f4c94c"
		}
		CamperMetricTile {
			x: 404
			y: 10
			width: 188
			height: 88
			dayMode: root.dayMode
			icon: "water"
			caption: "FRISCHWASSER"
			value: "–"
			detail: "NOCH NICHT ANGEBUNDEN"
			active: false
			accentColor: root.blue
		}
		CamperMetricTile {
			x: 601
			y: 10
			width: 189
			height: 88
			dayMode: root.dayMode
			icon: "climate"
			caption: "INNENRAUM"
			value: "–"
			detail: "NOCH NICHT ANGEBUNDEN"
			active: false
			accentColor: root.orange
		}

		Rectangle {
			x: 10
			y: 108
			width: 384
			height: 118
			radius: 15
			color: root.panel
			border.color: root.line

			CamperLineIcon {
				x: 20
				y: 20
				width: 34
				height: 34
				kind: "climate"
				lineColor: root.muted
				strokeWidth: 1.9
			}
			Text {
				x: 72
				y: 14
				width: 180
				elide: Text.ElideRight
				text: "AUTOTERM AIR 2D"
				color: root.textColor
				font.pixelSize: 14
				font.bold: true
			}
			Text {
				x: 72
				y: 38
				text: "NICHT ANGEBUNDEN"
				color: root.muted
				font.pixelSize: 10
			}
			CamperTouchButton {
				x: 268
				y: 12
				width: 100
				height: 42
				enabled: false
				label: "START"
				accentColor: root.orange
			}
			Rectangle {
				x: 16
				y: 72
				width: 352
				height: 1
				color: root.line
			}
			Text {
				x: 16
				y: 87
				text: "MAXXFAN"
				color: root.textColor
				font.pixelSize: 10
				font.bold: true
			}
			CamperLineIcon {
				x: 112
				y: 81
				width: 25
				height: 25
				kind: "fan"
				lineColor: root.muted
				strokeWidth: 1.8
			}
			Text {
				x: 145
				y: 87
				text: "– %"
				color: root.textColor
				font.pixelSize: 11
				font.bold: true
			}
			CamperTouchButton {
				x: 268
				y: 77
				width: 100
				height: 36
				enabled: false
				label: "EINSCHALTEN"
				fontSize: 10
			}
		}

		Rectangle {
			x: 404
			y: 108
			width: 386
			height: 118
			radius: 15
			color: root.panel
			border.color: root.line

			CamperLineIcon {
				x: 20
				y: 20
				width: 34
				height: 34
				kind: "pump"
				lineColor: root.muted
				strokeWidth: 1.9
			}
			Text {
				x: 72
				y: 14
				text: "WASSERPUMPE"
				color: root.textColor
				font.pixelSize: 14
				font.bold: true
			}
			Text {
				x: 72
				y: 38
				text: "NICHT ANGEBUNDEN"
				color: root.muted
				font.pixelSize: 10
			}
			CamperTouchButton {
				x: 270
				y: 12
				width: 100
				height: 42
				enabled: false
				label: "EINSCHALTEN"
				fontSize: 10
			}
			Rectangle {
				x: 16
				y: 72
				width: 354
				height: 1
				color: root.line
			}
			Text {
				x: 16
				y: 87
				text: "MULTIPLUS COMPACT"
				color: root.textColor
				font.pixelSize: 11
				font.bold: true
			}
			Text {
				x: 168
				y: 87
				text: "– W"
				color: root.muted
				font.pixelSize: 10
			}
			CamperTouchButton {
				x: 270
				y: 77
				width: 100
				height: 36
				enabled: false
				label: "230 V AN"
				accentColor: "#ad8cf2"
			}
		}

		Rectangle {
			x: 10
			y: 236
			width: 780
			height: 116
			radius: 15
			color: root.panel
			border.color: root.line

			Text {
				x: 16
				y: 12
				text: "SCHNELLZUGRIFF"
				color: root.muted
				font.pixelSize: 9
				font.bold: true
			}
			Repeater {
				model: [
					{ label: "TAGFAHR", icon: "lightBar" },
					{ label: "WARNBLINK", icon: "warningBar" },
					{ label: "INNENLICHT", icon: "cabinLight" },
					{ label: "AUSSEN RECHTS", icon: "workLightRight" }
				]
				delegate: Rectangle {
					required property var modelData
					required property int index

					x: 14 + index * 190
					y: 34
					width: 180
					height: 68
					radius: 12
					color: root.inner
					border.color: root.line

					CamperLineIcon {
						x: 73
						y: 5
						width: 34
						height: 34
						kind: modelData.icon
						lineColor: root.muted
						strokeWidth: 1.8
					}
					Text {
						x: 10
						y: 47
						width: 160
						horizontalAlignment: Text.AlignRight
						elide: Text.ElideRight
						text: modelData.label
						color: root.textColor
						font.pixelSize: 9
						font.bold: true
					}
					MouseArea {
						anchors.fill: parent
						// The Phase-2 adapter intentionally exposes no custom light API yet.
						onClicked: (mouse) => { mouse.accepted = true }
					}
				}
			}
		}
	}

	CamperNavBar {
		x: 0
		y: 422
		width: 800
		height: 58
		dayMode: root.dayMode
		currentPage: 0
		lineColor: root.line
		primaryText: root.textColor
		accentColor: root.blue
		onPageRequested: (page) => root.pageRequested(page)
	}
}
