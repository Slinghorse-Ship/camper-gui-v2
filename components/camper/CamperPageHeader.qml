import QtQuick

Rectangle {
    id: root

    property string pageTitle: "HOME"
    property string systemName: "FORD TRANSIT CAMPER"
    property url logoSource: "qrc:/images/camper_logo.png"
    property bool connected: false
    property bool showBack: false
    signal backRequested
    signal openVictronSettings
    signal closeRequested

    CamperStyle {
        id: visual
    }

    color: visual.header
    border.color: visual.border

    Image {
        x: 5
        y: 4
        width: 56
        height: 50
        source: root.logoSource
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    Text {
        x: 65
        y: 10
        text: root.systemName.toUpperCase()
        color: visual.text
        font.pixelSize: 17
        font.bold: true
    }

    Text {
        x: 65
        y: 31
        text: "· " + root.pageTitle
        color: visual.blue
        font.pixelSize: 11
        font.bold: true
    }

    Rectangle {
        x: 524
        y: 14
        width: 112
        height: 29
        radius: 15
        color: visual.inner
        border.color: root.connected ? visual.green : visual.red

        Rectangle {
            x: 10
            y: 10
            width: 8
            height: 8
            radius: 4
            color: root.connected ? visual.green : visual.red
        }
        Text {
            x: 24
            anchors.verticalCenter: parent.verticalCenter
            text: root.connected ? "VERBUNDEN" : "VERBINDUNG"
            color: visual.text
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
        color: settingsArea.pressed ? visual.inner : "transparent"
        border.color: visual.border

        CamperLineIcon {
            x: 9
            y: 8
            width: 22
            height: 22
            kind: root.showBack ? "back" : "settings"
            lineColor: visual.text
            strokeWidth: 1.8
        }
        Text {
            x: 37
            anchors.verticalCenter: parent.verticalCenter
            text: root.showBack ? "ZURÜCK" : "EINST."
            color: visual.text
            font.pixelSize: 10
            font.bold: true
        }
        MouseArea {
            id: settingsArea
            anchors.fill: parent
            onClicked: {
                if (root.showBack)
                    root.backRequested();
                else
                    root.openVictronSettings();
            }
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
            lineColor: visual.text
            strokeWidth: 2.6
        }
        MouseArea {
            id: closeArea
            anchors.fill: parent
            onClicked: root.closeRequested()
        }
    }
}
