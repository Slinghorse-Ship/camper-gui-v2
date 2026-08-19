/* Full-screen CamperControl layer hosted by gui-v2 MainView. */

import QtQuick
import "../../components/camper"
import "../../data/camper"
import "v2"

FocusScope {
    id: root

    signal openVictronSettings
    signal closeRequested

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

        CamperV2Shell {
            width: 800
            height: 480
            adapter: backend
            onOpenVictronSettings: root.openVictronSettings()
            onCloseRequested: root.closeRequested()
        }
    }
}
