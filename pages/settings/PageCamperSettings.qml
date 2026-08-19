/* CamperControl settings hosted inside the preserved Victron settings stack. */

import QtQuick
import Victron.VenusOS

Page {
    id: root

    title: "CamperControl"

    GradientListView {
        model: VisibleItemModel {
            ListText {
                text: "Oberfläche"
                secondaryText: "V2 · Transit Horizon"
                caption: "Die Camper-Oberfläche dieses Builds verwendet ausschließlich V2."
            }

            ListButton {
                text: "CamperControl öffnen"
                secondaryText: "ÖFFNEN"
                writeAccessLevel: VenusOS.User_AccessType_User
                onClicked: Global.mainView.showCamperUi()
            }

            ListText {
                text: "Seitliche Panels"
                secondaryText: "Links Favoriten · rechts Wetter"
                caption: "Vom unsichtbaren Bildschirmrand zur Mitte wischen."
            }
        }
    }
}
