/* Current three-button navigation from Ford SYNC CamperMain.qml. */

import QtQuick

Rectangle {
	id: root

	property bool dayMode: false
	property int currentPage: 0
	property color lineColor: dayMode ? "#c8cdd2" : "#2b3946"
	property color primaryText: dayMode ? "#20252a" : "#f4f8fb"
	property color accentColor: dayMode ? "#0067b9" : "#45c9fa"
	signal pageRequested(int page)

	color: dayMode ? "#f7f8f9" : "#0c141b"
	border.color: lineColor

	Repeater {
		model: [
			{ label: "HOME", icon: "home", page: 0 },
			{ label: "LICHT", icon: "light", page: 1 },
			{ label: "12 / 230", icon: "power", page: 5 }
		]
		delegate: Rectangle {
			id: navButton

			required property var modelData
			required property int index
			readonly property bool selected: root.currentPage === modelData.page

			x: index * 267
			y: 0
			width: index === 2 ? 266 : 267
			height: 58
			color: selected ? (root.dayMode ? "#dceff8" : "#102d3d") : "transparent"
			border.color: root.lineColor

			Rectangle {
				x: 0
				y: 0
				width: parent.width
				height: 3
				color: navButton.selected ? root.accentColor : "transparent"
			}
			CamperLineIcon {
				x: 18
				y: 14
				width: 30
				height: 30
				kind: navButton.modelData.icon
				lineColor: navButton.selected ? root.accentColor : root.primaryText
				strokeWidth: 2
			}
			Text {
				x: 55
				anchors.verticalCenter: parent.verticalCenter
				text: navButton.modelData.label
				color: navButton.selected ? root.accentColor : root.primaryText
				font.pixelSize: 10
				font.bold: true
			}
			MouseArea {
				anchors.fill: parent
				onClicked: root.pageRequested(navButton.modelData.page)
			}
		}
	}
}
