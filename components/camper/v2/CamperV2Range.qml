import QtQuick

Item {
    id: root

    property real value: 0
    property real from: 0
    property real to: 100
    property bool dayMode: false
    property bool available: true
    property color accent: style.blue
    signal moved(real value)

    implicitHeight: 34

    CamperV2Style {
        id: style
        dayMode: root.dayMode
    }

    Rectangle {
        id: track
        x: 4
        y: Math.round((parent.height - height) / 2)
        width: parent.width - 8
        height: 7
        radius: 4
        color: style.inner

        Rectangle {
            width: Math.max(0, Math.min(parent.width, parent.width * (root.value - root.from) / Math.max(1, root.to - root.from)))
            height: parent.height
            radius: parent.radius
            color: root.accent
        }
    }

    Rectangle {
        id: handle
        width: 22
        height: 22
        radius: 11
        y: Math.round((parent.height - height) / 2)
        x: Math.max(0, Math.min(parent.width - width, 4 + (track.width - width) * (root.value - root.from) / Math.max(1, root.to - root.from)))
        color: root.available ? root.accent : style.muted
        border.color: style.panel
        border.width: 3
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.available

        function updateValue(mouseX) {
            const ratio = Math.max(0, Math.min(1, (mouseX - 4) / Math.max(1, track.width)));
            root.value = root.from + ratio * (root.to - root.from);
            root.moved(root.value);
        }

        onPressed: mouse => updateValue(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                updateValue(mouse.x);
        }
    }
}
