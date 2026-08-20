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
        color: "#03090d"
    }

    Item {
        id: logicalCanvas

        x: 0
        y: 0
        width: root.contentScale > 0 ? root.width / root.contentScale : root.logicalWidth
        height: root.contentScale > 0 ? root.height / root.contentScale : root.logicalHeight
        scale: root.contentScale
        transformOrigin: Item.TopLeft
    }
}
