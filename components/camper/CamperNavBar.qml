/* Current three-button navigation from Ford SYNC CamperMain.qml. */

import QtQuick

Rectangle {
	id: root

	property bool dayMode: false
	property int currentPage: 0
	property color lineColor: visual.border
	property color primaryText: visual.text
	property color accentColor: visual.blue
	signal pageRequested(int page)

	CamperStyle {
		id: visual
		dayMode: root.dayMode
	}

	color: visual.header
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
			color: selected ? visual.selectedBlue : "transparent"
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
