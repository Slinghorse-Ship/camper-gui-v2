pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    property int currentPage: 0
    property bool dayMode: false
    signal pageRequested(int page)

    height: 72

    CamperV2Style {
        id: style
        dayMode: root.dayMode
    }

    Rectangle {
        x: 10
        y: 0
        width: root.width - 20
        height: 64
        radius: 18
        color: style.panel
        border.color: style.border

        Row {
            anchors.fill: parent
            anchors.margins: 5
            spacing: 3

            Repeater {
                model: [
                    {
                        page: 0,
                        label: "Home",
                        icon: "home"
                    },
                    {
                        page: 1,
                        label: "Licht",
                        icon: "lightNav"
                    },
                    {
                        page: 2,
                        label: "Klima",
                        icon: "climate"
                    },
                    {
                        page: 3,
                        label: "Energie",
                        icon: "energy"
                    },
                    {
                        page: 4,
                        label: "Wasser",
                        icon: "water"
                    },
                    {
                        page: 5,
                        label: "System",
                        icon: "system"
                    }
                ]

                delegate: Rectangle {
                    required property var modelData
                    readonly property bool selected: root.currentPage === modelData.page

                    width: (parent.width - 15) / 6
                    height: 54
                    radius: 13
                    color: selected ? style.selectedBlue : (navArea.pressed ? style.pressed : "transparent")

                    CamperV2Icon {
                        x: Math.round((parent.width - width) / 2)
                        y: 5
                        width: 27
                        height: 27
                        kind: parent.modelData.icon
                        lineColor: parent.selected ? style.blue : style.muted
                        strokeWidth: 1.8
                    }

                    Text {
                        x: 0
                        y: 34
                        width: parent.width
                        height: 15
                        horizontalAlignment: Text.AlignHCenter
                        text: parent.modelData.label
                        color: parent.selected ? style.blue : style.muted
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: navArea
                        anchors.fill: parent
                        onClicked: root.pageRequested(parent.modelData.page)
                    }
                }
            }
        }
    }
}
