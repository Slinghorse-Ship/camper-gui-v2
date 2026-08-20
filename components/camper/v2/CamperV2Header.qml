import QtQuick

Item {
    id: root
    objectName: "camperV2Header"

    property string pageTitle: "Home"
    property bool connected: false
    property bool dayMode: false
    property bool favoritesOpen: false
    property bool weatherOpen: false
    property url darkLogoSource: "qrc:/images/camper_transit_line_dark.png"
    property url lightLogoSource: "qrc:/images/camper_transit_line_light.png"
    signal favoritesRequested
    signal weatherRequested
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
        width: Math.max(120, root.width - 390)
        height: 50
        verticalAlignment: Text.AlignVCenter
        text: root.pageTitle
        color: style.text
        font.pixelSize: 19
        font.weight: Font.DemiBold
    }

    Rectangle {
        objectName: "camperV2HeaderFavoriteButton"
        x: root.width - 300
        y: 3
        width: 44
        height: 44
        radius: 13
        color: favoritesArea.pressed ? style.pressed : (root.favoritesOpen ? style.selectedGreen : style.inner)
        border.color: root.favoritesOpen ? style.green : style.border
        border.width: root.favoritesOpen ? 2 : 1

        CamperV2Icon {
            anchors.centerIn: parent
            width: 22
            height: 22
            kind: "favorite"
            lineColor: style.green
            strokeWidth: 1.8
        }

        MouseArea {
            id: favoritesArea
            anchors.fill: parent
            onClicked: root.favoritesRequested()
        }
    }

    Rectangle {
        objectName: "camperV2HeaderWeatherButton"
        x: root.width - 252
        y: 3
        width: 44
        height: 44
        radius: 13
        color: weatherArea.pressed ? style.pressed : (root.weatherOpen ? style.selectedBlue : style.inner)
        border.color: root.weatherOpen ? style.blue : style.border
        border.width: root.weatherOpen ? 2 : 1

        CamperV2WeatherIcon {
            anchors.centerIn: parent
            width: 24
            height: 24
            weatherCode: "cloudy"
            lineColor: style.blue
            sunColor: style.orange
            rainColor: style.blue
            strokeWidth: 1.8
        }

        MouseArea {
            id: weatherArea
            anchors.fill: parent
            onClicked: root.weatherRequested()
        }
    }

    Rectangle {
        x: root.width - 204
        y: 10
        width: 78
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
        x: root.width - 116
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
        x: root.width - 52
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
