import QtQuick

Item {
    id: root

    property string pageTitle: "Home"
    property bool connected: false
    property bool dayMode: false
    property url darkLogoSource: "qrc:/images/camper_transit_line_dark.png"
    property url lightLogoSource: "qrc:/images/camper_transit_line_light.png"
    signal themeRequested
    signal closeRequested

    height: 50

    CamperV2Style {
        id: style
        dayMode: root.dayMode
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: "transparent"

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: style.border
        }
    }

    Image {
        objectName: "camperV2HeaderLogo"
        x: 14
        y: 7
        width: 55
        height: 35
        source: root.dayMode ? root.lightLogoSource : root.darkLogoSource
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    Text {
        x: 82
        y: 0
        width: 470
        height: 50
        verticalAlignment: Text.AlignVCenter
        text: root.pageTitle
        color: style.text
        font.pixelSize: 19
        font.weight: Font.DemiBold
    }

    Rectangle {
        x: 592
        y: 10
        width: 82
        height: 30
        radius: 15
        color: root.connected ? (root.dayMode ? "#e4f7ef" : "#112b27") : style.inner

        Rectangle {
            x: 11
            y: 11
            width: 8
            height: 8
            radius: 4
            color: root.connected ? "#2ed8b0" : style.muted
        }

        Text {
            x: 25
            y: 0
            width: 49
            height: 30
            verticalAlignment: Text.AlignVCenter
            text: Qt.formatTime(new Date(), "hh:mm")
            color: root.connected ? (root.dayMode ? "#087a58" : "#8de8c8") : style.muted
            font.pixelSize: 11
            font.weight: Font.DemiBold

            Timer {
                interval: 30000
                running: true
                repeat: true
                onTriggered: parent.text = Qt.formatTime(new Date(), "hh:mm")
            }
        }
    }

    Rectangle {
        x: 684
        y: 6
        width: 38
        height: 38
        radius: 12
        color: themeArea.pressed ? style.pressed : style.inner

        CamperV2Icon {
            anchors.centerIn: parent
            width: 21
            height: 21
            kind: "theme"
            lineColor: style.text
            strokeWidth: 1.8
        }

        MouseArea {
            id: themeArea
            anchors.fill: parent
            onClicked: root.themeRequested()
        }
    }

    Rectangle {
        x: 748
        y: 4
        width: 42
        height: 42
        radius: 12
        color: closeArea.pressed ? (root.dayMode ? "#f4d8da" : "#49242b") : style.inner
        border.color: root.dayMode ? "#d75b64" : "#e47780"
        border.width: 1

        CamperV2Icon {
            anchors.centerIn: parent
            width: 21
            height: 21
            kind: "close"
            lineColor: style.red
            strokeWidth: 2
        }

        MouseArea {
            id: closeArea
            anchors.fill: parent
            onClicked: root.closeRequested()
        }
    }
}
