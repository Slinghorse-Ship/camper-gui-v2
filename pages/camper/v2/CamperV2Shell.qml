import QtQuick
import "../../../components/camper/v2"

Rectangle {
    id: root

    required property var adapter
    property int currentPage: 0
    property int energyPane: 0
    property alias activePanel: panelHost.activePanel
    property bool lightsRightView: false
    property bool dayMode: false
    property url darkLogoSource: "qrc:/images/camper_transit_line_dark.png"
    property url lightLogoSource: "qrc:/images/camper_transit_line_light.png"
    property url leftVehicleSource: "qrc:/images/camper_v2_vehicle_left.png"
    property url rightVehicleSource: "qrc:/images/camper_v2_vehicle_right.png"
    signal openVictronSettings
    signal closeRequested

    readonly property string pageTitle: ["Home", "Licht", "Klima", "Energie", "Wasser", "System"][Math.max(0, Math.min(5, currentPage))]

    radius: 0
    clip: true
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

    CamperV2Style {
        id: style
        dayMode: root.dayMode
    }

    CamperV2Header {
        x: 0
        y: 0
        width: 800
        pageTitle: root.pageTitle
        connected: root.adapter.customReadConnected === true
        dayMode: root.dayMode
        darkLogoSource: root.darkLogoSource
        lightLogoSource: root.lightLogoSource
        onThemeRequested: root.dayMode = !root.dayMode
        onCloseRequested: root.closeRequested()
    }

    Item {
        x: 0
        y: 50
        width: 800
        height: 342

        Loader {
            anchors.fill: parent
            active: root.currentPage === 0
            sourceComponent: homePage
        }
        Loader {
            anchors.fill: parent
            active: root.currentPage === 1
            sourceComponent: lightsPage
        }
        Loader {
            anchors.fill: parent
            active: root.currentPage === 2
            sourceComponent: climatePage
        }
        Loader {
            anchors.fill: parent
            active: root.currentPage === 3
            sourceComponent: energyPage
        }
        Loader {
            anchors.fill: parent
            active: root.currentPage === 4
            sourceComponent: waterPage
        }
        Loader {
            anchors.fill: parent
            active: root.currentPage === 5
            sourceComponent: systemPage
        }

        Component {
            id: homePage
            CamperV2Home {
                adapter: root.adapter
                dayMode: root.dayMode
                onPageRequested: page => root.currentPage = page
                onEditQuickAccessRequested: panelHost.openQuick(true)
            }
        }
        Component {
            id: lightsPage
            CamperV2Lights {
                adapter: root.adapter
                dayMode: root.dayMode
                rightView: root.lightsRightView
                leftVehicleSource: root.leftVehicleSource
                rightVehicleSource: root.rightVehicleSource
                onRightViewChanged: root.lightsRightView = rightView
            }
        }
        Component {
            id: climatePage
            CamperV2Climate {
                adapter: root.adapter
                dayMode: root.dayMode
            }
        }
        Component {
            id: energyPage
            CamperV2Energy {
                adapter: root.adapter
                dayMode: root.dayMode
                energyPane: root.energyPane
                onEnergyPaneChanged: root.energyPane = energyPane
            }
        }
        Component {
            id: waterPage
            CamperV2Water {
                adapter: root.adapter
                dayMode: root.dayMode
            }
        }
        Component {
            id: systemPage
            CamperV2System {
                adapter: root.adapter
                dayMode: root.dayMode
                onOpenVictronSettings: root.openVictronSettings()
                onCloseRequested: root.closeRequested()
            }
        }
    }

    CamperV2NavBar {
        x: 0
        y: 400
        width: 800
        currentPage: root.currentPage
        dayMode: root.dayMode
        onPageRequested: page => root.currentPage = page
    }

    CamperV2PanelHost {
        id: panelHost
        anchors.fill: parent
        adapter: root.adapter
        dayMode: root.dayMode
    }
}
