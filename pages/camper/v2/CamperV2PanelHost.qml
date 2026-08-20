import QtQuick
import "../../../components/camper/v2"

Item {
    id: root

    required property var adapter
    property bool dayMode: false
    property int activePanel: closedPanel
    property bool quickEditorRequested: false

    readonly property int closedPanel: 0
    readonly property int quickPanel: 1
    readonly property int weatherPanel: 2
    readonly property int edgeWidth: 18
    readonly property real swipeThreshold: 48

    function openQuick(openEditor) {
        quickEditorRequested = openEditor === true;
        activePanel = quickPanel;
    }

    function openWeather() {
        activePanel = weatherPanel;
    }

    function closePanel() {
        activePanel = closedPanel;
    }

    CamperV2Style {
        id: style
        dayMode: root.dayMode
    }

    // Narrow invisible edge zones stay clear of both header and navigation.
    MouseArea {
        id: leftEdge
        objectName: "camperV2LeftEdgeSwipe"
        x: 0
        y: 56
        width: root.edgeWidth
        height: 335
        z: 1
        enabled: root.activePanel === root.closedPanel
        preventStealing: true
        property real startX: 0
        property real startY: 0
        onPressed: mouse => {
            startX = mouse.x;
            startY = mouse.y;
        }
        onReleased: mouse => {
            const horizontal = mouse.x - startX;
            const vertical = Math.abs(mouse.y - startY);
            if (horizontal >= root.swipeThreshold && horizontal >= vertical * 1.5)
                root.openQuick(false);
        }
    }

    MouseArea {
        id: rightEdge
        objectName: "camperV2RightEdgeSwipe"
        x: root.width - root.edgeWidth
        y: 56
        width: root.edgeWidth
        height: 335
        z: 1
        enabled: root.activePanel === root.closedPanel
        preventStealing: true
        property real startX: 0
        property real startY: 0
        onPressed: mouse => {
            startX = mouse.x;
            startY = mouse.y;
        }
        onReleased: mouse => {
            const horizontal = startX - mouse.x;
            const vertical = Math.abs(mouse.y - startY);
            if (horizontal >= root.swipeThreshold && horizontal >= vertical * 1.5)
                root.openWeather();
        }
    }

    Rectangle {
        id: scrim
        anchors.fill: parent
        z: 2
        visible: root.activePanel !== root.closedPanel
        color: "#b0000000"

        MouseArea {
            anchors.fill: parent
            preventStealing: true
            property real startX: 0
            property real startY: 0
            onPressed: mouse => {
                startX = mouse.x;
                startY = mouse.y;
            }
            onReleased: mouse => {
                if (Math.abs(mouse.x - startX) < 12 && Math.abs(mouse.y - startY) < 12)
                    root.closePanel();
            }
        }
    }

    Rectangle {
        id: sheet
        objectName: "camperV2SharedPanel"
        z: 3
        visible: root.activePanel !== root.closedPanel
        x: root.activePanel === root.quickPanel ? 0 : root.width - width
        y: 0
        width: root.activePanel === root.quickPanel ? 340 : 560
        height: root.height
        radius: 0
        color: style.backgroundTop
        border.color: style.border

        gradient: Gradient {
            GradientStop {
                position: 0
                color: style.backgroundTop
            }
            GradientStop {
                position: 1
                color: style.backgroundBottom
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        Rectangle {
            x: 0
            y: 54
            width: parent.width
            height: 1
            color: style.border
        }

        CamperV2Icon {
            x: 17
            y: 14
            width: 27
            height: 27
            kind: root.activePanel === root.quickPanel ? "favorite" : "climate"
            lineColor: root.activePanel === root.quickPanel ? style.green : style.blue
            strokeWidth: 1.8
        }

        Text {
            x: 55
            y: 0
            width: parent.width - 122
            height: 54
            verticalAlignment: Text.AlignVCenter
            text: root.activePanel === root.quickPanel ? "Favoriten" : "Wetter"
            color: style.text
            font.pixelSize: 18
            font.weight: Font.DemiBold
        }

        Rectangle {
            x: parent.width - 52
            y: 5
            width: 44
            height: 44
            radius: 13
            color: closeArea.pressed ? style.pressed : style.inner
            border.color: style.border

            CamperV2Icon {
                anchors.centerIn: parent
                width: 22
                height: 22
                kind: "close"
                lineColor: style.text
                strokeWidth: 2
            }

            MouseArea {
                id: closeArea
                objectName: "camperV2PanelClose"
                anchors.fill: parent
                onClicked: root.closePanel()
            }
        }

        Loader {
            x: 16
            y: 64
            width: parent.width - 32
            height: parent.height - 76
            active: root.activePanel === root.quickPanel
            sourceComponent: quickPanelContent
        }

        Loader {
            x: 16
            y: 64
            width: parent.width - 32
            height: parent.height - 76
            active: root.activePanel === root.weatherPanel
            sourceComponent: weatherPanelContent
        }

        Component {
            id: quickPanelContent
            CamperV2QuickPanel {
                objectName: "camperV2QuickPanel"
                adapter: root.adapter
                dayMode: root.dayMode
                editing: root.quickEditorRequested
            }
        }

        Component {
            id: weatherPanelContent
            CamperV2WeatherPanel {
                objectName: "camperV2WeatherPanel"
                adapter: root.adapter
                dayMode: root.dayMode
            }
        }
    }
}
