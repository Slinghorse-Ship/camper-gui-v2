/* CamperControl settings hosted inside the preserved Victron settings stack. */

import QtQuick
import Victron.VenusOS

Page {
    id: root

    title: "CamperControl"

    GradientListView {
        model: VisibleItemModel {
            ListRadioButtonGroup {
                text: "Design"
                caption: "Lokale Darstellung auf diesem GX Touch oder Browser"
                writeAccessLevel: VenusOS.User_AccessType_User
                optionModel: [
                    {
                        display: "V1 · Klassisch",
                        value: CamperDesignSettings.version1
                    },
                    {
                        display: "V2 · Transit Horizon",
                        value: CamperDesignSettings.version2
                    }
                ]
                currentIndex: CamperDesignSettings.designVersion === CamperDesignSettings.version2 ? 1 : 0
                updateDataOnClick: false
                onOptionClicked: index => CamperDesignSettings.setDesignVersion(optionModel[index].value)
            }

            ListText {
                text: "Aktiv"
                secondaryText: CamperDesignSettings.designVersion === CamperDesignSettings.version2 ? "V2 · Transit Horizon" : "V1 · Klassisch"
                caption: "Wird sofort angewendet und lokal dauerhaft gespeichert."
            }

            ListButton {
                text: "CamperControl öffnen"
                secondaryText: "ÖFFNEN"
                writeAccessLevel: VenusOS.User_AccessType_User
                onClicked: Global.mainView.showCamperUi()
            }

            ListText {
                text: "Hinweis"
                secondaryText: "Gerätelokal"
                caption: "Die Auswahl wird nicht automatisch zwischen Cerbo, Ford SYNC und Node-RED synchronisiert."
            }
        }
    }
}
