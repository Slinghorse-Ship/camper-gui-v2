import QtQuick

Rectangle {
    id: root

    property string pageTitle: "HOME"
    property string systemName: "FORD TRANSIT CAMPER"
    property url logoSource: "qrc:/images/camper_logo.png"
    property url v2LogoSource: dayMode ? "qrc:/images/camper_transit_line_light.png" : "qrc:/images/camper_transit_line_dark.png"
    property bool dayMode: false
    property bool connected: false
    property bool showBack: false
    signal backRequested
    signal openVictronSettings
    signal closeRequested

    CamperStyle {
        id: visual
        dayMode: root.dayMode
    }

    color: visual.header
    border.color: visual.border

    Image {
        x: visual.designV2 ? 14 : 5
        y: visual.designV2 ? 8 : 4
        width: visual.designV2 ? 55 : 56
        height: visual.designV2 ? 35 : 50
        source: visual.designV2 ? root.v2LogoSource : root.logoSource
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
        visible: !visual.designV2
    }

    Text {
        x: visual.designV2 ? 79 : 65
        y: visual.designV2 ? 14 : 31
        text: visual.designV2 ? root.pageTitle : "· " + root.pageTitle
        color: visual.designV2 ? visual.text : visual.blue
        font.pixelSize: visual.designV2 ? 19 : 11
        font.bold: true
    }

    Rectangle {
        x: visual.designV2 ? 538 : 524
        y: visual.designV2 ? 10 : 14
        width: visual.designV2 ? 108 : 112
        height: visual.designV2 ? 30 : 29
        radius: 15
        color: visual.inner
        border.color: visual.designV2 ? "transparent" : (root.connected ? visual.green : visual.red)

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
            text: visual.designV2 ? (root.connected ? "Online" : "Offline") : (root.connected ? "VERBUNDEN" : "VERBINDUNG")
            color: visual.designV2 ? (root.connected ? visual.green : visual.red) : visual.text
            font.pixelSize: visual.designV2 ? 11 : 9
            font.bold: true
        }
    }

    Rectangle {
        x: 647
        y: 9
        width: 92
        height: 39
        radius: visual.designV2 ? 12 : 9
        color: settingsArea.pressed ? visual.inner : "transparent"
        border.color: visual.designV2 ? "transparent" : visual.border

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
            text: root.showBack ? (visual.designV2 ? "Zurück" : "ZURÜCK") : (visual.designV2 ? "System" : "EINST.")
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
        radius: visual.designV2 ? 12 : 9
        color: closeArea.pressed ? "#44232a" : "transparent"
        border.color: visual.designV2 ? "transparent" : "#5a333b"

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
