/* Full-screen CamperControl layer hosted by gui-v2 MainView. */

import QtQuick
import "../../components/camper"
import "../../data/camper"

FocusScope {
    id: root

    signal openVictronSettings
    signal closeRequested
    property int currentPage: 0

    CamperBackendAdapter {
        id: backend
    }

    // Ford SYNC uses the same full-screen grabber so empty UI areas cannot leak touch
    // events to the application below the Camper layer.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        preventStealing: true
        propagateComposedEvents: false
        onPressed: mouse => {
            mouse.accepted = true;
        }
        onReleased: mouse => {
            mouse.accepted = true;
        }
        onClicked: mouse => {
            mouse.accepted = true;
        }
        onDoubleClicked: mouse => {
            mouse.accepted = true;
        }
        onPressAndHold: mouse => {
            mouse.accepted = true;
        }
    }

    CamperViewport {
        anchors.fill: parent

        CamperHome {
            width: 800
            height: 480
            visible: root.currentPage === 0
            adapter: backend
            onOpenVictronSettings: root.openVictronSettings()
            onCloseRequested: root.closeRequested()
            onEditQuickAccessRequested: root.currentPage = 12
            onPageRequested: page => {
                root.currentPage = page;
            }
        }

        CamperLights {
            width: 800
            height: 480
            visible: root.currentPage === 1
            adapter: backend
            onOpenVictronSettings: root.openVictronSettings()
            onCloseRequested: root.closeRequested()
            onPageRequested: page => root.currentPage = page
        }

        CamperPower {
            width: 800
            height: 480
            visible: root.currentPage === 5
            adapter: backend
            onOpenVictronSettings: root.openVictronSettings()
            onCloseRequested: root.closeRequested()
            onPageRequested: page => root.currentPage = page
        }

        CamperDetails {
            width: 800
            height: 480
            visible: root.currentPage >= 6 && root.currentPage <= 11
            adapter: backend
            detailPage: root.currentPage
            onBackRequested: root.currentPage = 0
            onOpenVictronSettings: root.openVictronSettings()
            onCloseRequested: root.closeRequested()
            onPageRequested: page => root.currentPage = page
        }

        CamperQuickAccess {
            width: 800
            height: 480
            visible: root.currentPage === 12
            adapter: backend
            onBackRequested: root.currentPage = 0
            onPageRequested: page => {
                root.currentPage = page;
            }
        }
    }
}
