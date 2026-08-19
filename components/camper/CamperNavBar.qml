/* V1 keeps the Ford three-button bar; V2 uses the approved six-target compact bar. */

pragma ComponentBehavior: Bound

import QtQuick

Rectangle {
    id: root

    property bool dayMode: false
    property int currentPage: 0
    property color lineColor: visual.border
    property color primaryText: visual.text
    property color accentColor: visual.blue
    signal pageRequested(int page)

    CamperStyle {
        id: visual
        dayMode: root.dayMode
    }

    color: visual.designV2 ? "transparent" : visual.header
    border.color: visual.designV2 ? "transparent" : root.lineColor

    Repeater {
        model: visual.designV2 ? [] : [
            {
                label: "HOME",
                icon: "home",
                page: 0
            },
            {
                label: "LICHT",
                icon: "light",
                page: 1
            },
            {
                label: "12 / 230",
                icon: "power",
                page: 5
            }
        ]
        delegate: Rectangle {
            id: classicNavButton

            required property var modelData
            required property int index
            readonly property bool selected: root.currentPage === modelData.page

            x: index * 267
            y: 0
            width: index === 2 ? 266 : 267
            height: 58
            color: selected ? visual.selectedBlue : "transparent"
            border.color: root.lineColor

            Rectangle {
                x: 0
                y: 0
                width: parent.width
                height: 3
                color: classicNavButton.selected ? root.accentColor : "transparent"
            }
            CamperLineIcon {
                x: 18
                y: 14
                width: 30
                height: 30
                kind: classicNavButton.modelData.icon
                lineColor: classicNavButton.selected ? root.accentColor : root.primaryText
                strokeWidth: 2
            }
            Text {
                x: 55
                anchors.verticalCenter: parent.verticalCenter
                text: classicNavButton.modelData.label
                color: classicNavButton.selected ? root.accentColor : root.primaryText
                font.pixelSize: 10
                font.bold: true
            }
            MouseArea {
                anchors.fill: parent
                onClicked: root.pageRequested(classicNavButton.modelData.page)
            }
        }
    }

    Rectangle {
        x: 10
        y: 2
        width: 780
        height: 52
        visible: visual.designV2
        radius: 15
        color: visual.panel
        border.color: visual.border

        Repeater {
            model: [
                {
                    label: "Home",
                    icon: "home",
                    page: 0
                },
                {
                    label: "Licht",
                    icon: "light",
                    page: 1
                },
                {
                    label: "Klima",
                    icon: "climate",
                    page: 10
                },
                {
                    label: "Energie",
                    icon: "battery",
                    page: 5
                },
                {
                    label: "Wasser",
                    icon: "water",
                    page: 11
                },
                {
                    label: "System",
                    icon: "settings",
                    page: 13
                }
            ]
            delegate: Rectangle {
                id: horizonNavButton

                required property var modelData
                required property int index
                readonly property bool selected: root.currentPage === modelData.page

                x: 4 + index * 128
                y: 4
                width: index === 5 ? 128 : 125
                height: 44
                radius: 11
                color: selected ? visual.selectedBlue : "transparent"

                CamperLineIcon {
                    x: (parent.width - width) / 2
                    y: 3
                    width: 21
                    height: 21
                    kind: horizonNavButton.modelData.icon
                    lineColor: horizonNavButton.selected ? root.accentColor : visual.muted
                    strokeWidth: 1.8
                }
                Text {
                    x: 2
                    y: 27
                    width: parent.width - 4
                    horizontalAlignment: Text.AlignHCenter
                    text: horizonNavButton.modelData.label
                    color: horizonNavButton.selected ? root.accentColor : visual.muted
                    font.pixelSize: 9
                    font.bold: true
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.pageRequested(horizonNavButton.modelData.page)
                }
            }
        }
    }
}
