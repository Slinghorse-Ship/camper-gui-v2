import QtQuick

Rectangle {
    id: root

    property bool dayMode: false
    property bool active: false
    property bool available: true
    property color accent: style.blue

    radius: 17
    color: active ? Qt.tint(style.panel, Qt.rgba(accent.r, accent.g, accent.b, dayMode ? 0.10 : 0.13)) : style.panel
    border.color: active ? accent : style.border
    border.width: active ? 2 : 1
    opacity: available ? 1 : 0.58

    CamperV2Style {
        id: style
        dayMode: root.dayMode
    }
}
