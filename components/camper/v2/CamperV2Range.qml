import QtQuick

Item {
    id: root

    property real value: 0
    property real from: 0
    property real to: 100
    property real stepSize: 1
    property bool dayMode: false
    property bool available: true
    property color accent: style.blue
    property bool dragging: false
    property bool awaitingCommit: false
    property bool holdUntilConfirmed: false
    property real pendingValue: value
    readonly property real shownValue: dragging || awaitingCommit ? pendingValue : value
    signal moved(real value)
    signal committed(real value)

    implicitHeight: 34

    CamperV2Style {
        id: style
        dayMode: root.dayMode
    }

    function normalizedValue(candidate) {
        const bounded = Math.max(from, Math.min(to, candidate));
        if (stepSize <= 0)
            return bounded;
        return Math.max(from, Math.min(to, from + Math.round((bounded - from) / stepSize) * stepSize));
    }

    onValueChanged: {
        if (dragging)
            return;
        if (!awaitingCommit || Math.abs(value - pendingValue) <= Math.max(.51, stepSize / 2)) {
            pendingValue = value;
            awaitingCommit = false;
            settleTimer.stop();
        }
    }
    onAvailableChanged: {
        if (!available) {
            dragging = false;
            awaitingCommit = false;
            pendingValue = value;
            settleTimer.stop();
        }
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
            width: Math.max(0, Math.min(parent.width, parent.width * (root.shownValue - root.from) / Math.max(1, root.to - root.from)))
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
        x: Math.max(0, Math.min(parent.width - width, 4 + (track.width - width) * (root.shownValue - root.from) / Math.max(1, root.to - root.from)))
        color: root.available ? root.accent : style.muted
        border.color: style.panel
        border.width: 3
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.available

        function updateValue(mouseX) {
            const ratio = Math.max(0, Math.min(1, (mouseX - 4) / Math.max(1, track.width)));
            root.pendingValue = root.normalizedValue(root.from + ratio * (root.to - root.from));
            root.moved(root.pendingValue);
        }

        onPressed: mouse => {
            settleTimer.stop();
            root.awaitingCommit = false;
            root.dragging = true;
            updateValue(mouse.x);
        }
        onPositionChanged: mouse => {
            if (pressed)
                updateValue(mouse.x);
        }
        onReleased: mouse => {
            updateValue(mouse.x);
            root.dragging = false;
            root.awaitingCommit = true;
            root.committed(root.pendingValue);
            if (!root.holdUntilConfirmed)
                settleTimer.restart();
        }
        onCanceled: {
            root.dragging = false;
            root.awaitingCommit = false;
            root.pendingValue = root.value;
        }
    }

    Timer {
        id: settleTimer
        interval: 1800
        repeat: false
        onTriggered: {
            root.awaitingCommit = false;
            root.pendingValue = root.value;
        }
    }
}
