/*
** CamperControl gui-v2 port
** Keep the Ford SYNC design on its native 800x480 canvas and scale it uniformly.
*/

import QtQuick

Item {
	id: root

	default property alias viewportData: logicalCanvas.data
	readonly property real contentScale: Math.min(width / logicalWidth, height / logicalHeight)
	property real logicalWidth: 800
	property real logicalHeight: 480

	Rectangle {
		anchors.fill: parent
		color: "#05090c"
	}

	Item {
		id: logicalCanvas

		x: (root.width - width * scale) / 2
		y: (root.height - height * scale) / 2
		width: root.logicalWidth
		height: root.logicalHeight
		scale: root.contentScale
		transformOrigin: Item.TopLeft
	}
}
