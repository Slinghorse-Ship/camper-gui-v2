import QtQuick
import "../../components/camper"

Item {
    id: view

    property bool dayMode: false
    property var fan: ({})
    property bool controlsEnabled: true
    signal backRequested
    signal commandRequested(string action, var value)

    property color panelColor: visual.panel
    property color innerColor: visual.inner
    property color textColor: visual.text
    property color mutedColor: visual.muted
    property color lineColor: visual.border
    property color blueColor: visual.blue
    property color greenColor: visual.green

    CamperStyle {
        id: visual
        dayMode: view.dayMode
    }

    function fmt(value, digits, suffix) {
        if (value === null || value === undefined || value === "" || !isFinite(Number(value)))
            return "–";
        return Number(value).toFixed(digits) + (suffix || "");
    }

    Rectangle {
        x: 10
        y: 8
        width: 780
        height: 56
        radius: 13
        color: view.panelColor
        border.color: view.fan.online ? view.greenColor : view.lineColor
        CamperTouchButton {
            x: 8
            y: 9
            width: 76
            height: 38
            label: "ZURÜCK"
            onClicked: view.backRequested()
        }
        CamperLineIcon {
            x: 98
            y: 10
            width: 35
            height: 35
            kind: "fan"
            lineColor: view.fan.on === true ? view.blueColor : view.mutedColor
            strokeWidth: 2
        }
        Text {
            x: 143
            y: 8
            text: view.fan.name || "MAXXFAN"
            color: view.textColor
            font.pixelSize: 15
            font.bold: true
        }
        Text {
            x: 143
            y: 31
            text: "VanTurtle WLAN-Steuerung · STAR-Power CH " + Number(view.fan.powerChannel || 6)
            color: view.mutedColor
            font.pixelSize: 9
        }
        Rectangle {
            x: 502
            y: 22
            width: 9
            height: 9
            radius: 5
            color: view.fan.online ? view.greenColor : "#ef6e76"
        }
        Text {
            x: 520
            y: 18
            text: view.fan.online ? "VERBUNDEN" : "NICHT VERBUNDEN"
            color: view.fan.online ? view.greenColor : "#ef6e76"
            font.pixelSize: 9
            font.bold: true
        }
        CamperTouchButton {
            x: 650
            y: 9
            width: 116
            height: 38
            label: view.fan.on === true ? "AUSSCHALTEN" : "EINSCHALTEN"
            active: view.fan.on === true
            enabled: view.controlsEnabled
            onClicked: view.commandRequested("set", view.fan.on !== true)
        }
    }

    Rectangle {
        x: 10
        y: 72
        width: 246
        height: 342
        radius: 13
        color: view.innerColor
        border.color: view.lineColor
        Text {
            x: 14
            y: 13
            text: "STATUS"
            color: view.mutedColor
            font.pixelSize: 9
            font.bold: true
        }
        Text {
            x: 14
            y: 42
            text: view.fmt(view.fan.speed, 0, " %")
            color: view.fan.on === true ? view.blueColor : view.textColor
            font.pixelSize: 36
            font.bold: true
        }
        Text {
            x: 14
            y: 87
            text: view.fan.on === true ? "LÜFTER AKTIV" : "LÜFTER AUS"
            color: view.fan.on === true ? view.greenColor : view.mutedColor
            font.pixelSize: 10
            font.bold: true
        }
        Rectangle {
            x: 14
            y: 116
            width: 218
            height: 1
            color: view.lineColor
        }
        Text {
            x: 14
            y: 136
            text: "Richtung"
            color: view.mutedColor
            font.pixelSize: 9
        }
        Text {
            x: 126
            y: 132
            width: 106
            horizontalAlignment: Text.AlignRight
            text: view.fan.mode === "reverse" ? "ZULUFT" : "ABLUFT"
            color: view.textColor
            font.pixelSize: 11
            font.bold: true
        }
        Text {
            x: 14
            y: 171
            text: "Versorgung"
            color: view.mutedColor
            font.pixelSize: 9
        }
        Text {
            x: 126
            y: 167
            width: 106
            horizontalAlignment: Text.AlignRight
            text: view.fan.powered ? "BEREIT" : "CH 6 AUS"
            color: view.fan.powered ? view.greenColor : "#ef6e76"
            font.pixelSize: 11
            font.bold: true
        }
        Rectangle {
            x: 14
            y: 200
            width: 218
            height: 1
            color: view.lineColor
        }
        Text {
            x: 14
            y: 218
            text: "Spannung"
            color: view.mutedColor
            font.pixelSize: 9
        }
        Text {
            x: 126
            y: 214
            width: 106
            horizontalAlignment: Text.AlignRight
            text: view.fmt(view.fan.voltage, 1, " V")
            color: view.textColor
            font.pixelSize: 11
            font.bold: true
        }
        Text {
            x: 14
            y: 245
            text: "Strom"
            color: view.mutedColor
            font.pixelSize: 9
        }
        Text {
            x: 126
            y: 241
            width: 106
            horizontalAlignment: Text.AlignRight
            text: view.fmt(view.fan.current, 1, " A")
            color: view.textColor
            font.pixelSize: 11
            font.bold: true
        }
        Text {
            x: 14
            y: 272
            text: "Leistung"
            color: view.mutedColor
            font.pixelSize: 9
        }
        Text {
            x: 126
            y: 268
            width: 106
            horizontalAlignment: Text.AlignRight
            text: view.fmt(view.fan.power, 1, " W")
            color: view.textColor
            font.pixelSize: 11
            font.bold: true
        }
    }

    Rectangle {
        x: 264
        y: 72
        width: 526
        height: 342
        radius: 13
        color: view.innerColor
        border.color: view.lineColor
        Text {
            x: 14
            y: 13
            text: "LÜFTERSTUFE"
            color: view.mutedColor
            font.pixelSize: 9
            font.bold: true
        }
        CamperTouchButton {
            x: 14
            y: 35
            width: 54
            height: 46
            label: "−"
            enabled: view.controlsEnabled
            onClicked: view.commandRequested("speed", Math.max(0, Number(view.fan.speed || 0) - 10))
        }
        Text {
            x: 77
            y: 45
            width: 96
            horizontalAlignment: Text.AlignHCenter
            text: view.fmt(view.fan.speed, 0, " %")
            color: view.textColor
            font.pixelSize: 20
            font.bold: true
        }
        CamperTouchButton {
            x: 182
            y: 35
            width: 54
            height: 46
            label: "+"
            enabled: view.controlsEnabled
            onClicked: view.commandRequested("speed", Math.min(100, Number(view.fan.speed || 0) + 10))
        }
        Repeater {
            model: [10, 30, 50, 70, 100]
            delegate: CamperTouchButton {
                x: 250 + index * 51
                y: 35
                width: 46
                height: 46
                label: modelData + "%"
                active: Number(view.fan.speed || 0) === modelData
                enabled: view.controlsEnabled
                onClicked: view.commandRequested("speed", modelData)
            }
        }

        Rectangle {
            x: 14
            y: 96
            width: 498
            height: 1
            color: view.lineColor
        }
        Text {
            x: 14
            y: 113
            text: "LUFTRICHTUNG"
            color: view.mutedColor
            font.pixelSize: 9
            font.bold: true
        }
        CamperTouchButton {
            x: 14
            y: 135
            width: 236
            height: 47
            label: "ABLUFT"
            active: view.fan.mode !== "reverse"
            enabled: view.controlsEnabled
            onClicked: view.commandRequested("mode", "forward")
        }
        CamperTouchButton {
            x: 262
            y: 135
            width: 250
            height: 47
            label: "ZULUFT"
            active: view.fan.mode === "reverse"
            enabled: view.controlsEnabled
            onClicked: view.commandRequested("mode", "reverse")
        }

        Rectangle {
            x: 14
            y: 198
            width: 498
            height: 1
            color: view.lineColor
        }
        Text {
            x: 14
            y: 215
            text: "HAUBE"
            color: view.mutedColor
            font.pixelSize: 9
            font.bold: true
        }
        CamperTouchButton {
            x: 14
            y: 237
            width: 498
            height: 48
            label: "HAUBE UMSCHALTEN"
            active: Number(view.fan.lid) === 1
            enabled: view.controlsEnabled
            onClicked: view.commandRequested("lid", true)
        }
        Text {
            x: 14
            y: 302
            width: 498
            text: view.fan.calibrating ? "Kalibrierung läuft" : (view.fan.calibrated ? "Controller kalibriert" : "Controller noch nicht kalibriert")
            color: view.fan.calibrated ? view.greenColor : view.mutedColor
            font.pixelSize: 10
            font.bold: true
        }
    }
}
