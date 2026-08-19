import QtQuick
import "../../components/camper"

Item {
    id: root

    required property var adapter
    property url v2LogoSource: "qrc:/images/camper_transit_line_dark.png"
    signal openVictronSettings
    signal closeRequested
    signal pageRequested(int page)

    readonly property var snapshot: adapter.stateData || ({})
    readonly property var energy: snapshot.energy || ({})
    readonly property var power: snapshot.power || ({})
    readonly property var inverter: power.inverter || ({})
    readonly property var dcChannels: power.dcChannels || []
    readonly property var visibleChannels: filteredChannels()

    CamperStyle {
        id: visual
    }

    function filteredChannels() {
        const result = [];
        for (let index = 0; index < dcChannels.length; ++index) {
            const channel = dcChannels[index];
            if (Number(channel.channel) !== 3 && channel.id !== "high_beam_manual")
                result.push(channel);
        }
        return result;
    }

    function fmt(value, digits, suffix) {
        if (value === null || value === undefined || value === "" || !isFinite(Number(value)))
            return "–";
        return Number(value).toFixed(digits) + (suffix || "");
    }

    function powerIconKind(channel) {
        const number = Number(channel.channel);
        if (channel.id === "dc_outlets_left" || channel.id === "dc_outlets_right" || number === 1 || number === 4)
            return "outlet";
        if (channel.id === "water_pump" || number === 2)
            return "pump";
        if (channel.id === "starlink" || number === 5)
            return "satellite";
        if (channel.id === "maxxfan_power" || number === 6)
            return "fan";
        return "power";
    }

    function tileX(index) {
        if (visibleChannels.length === 5 && index >= 3)
            return 144 + (index - 3) * 260;
        return 14 + (index % 3) * 260;
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop {
                position: 0
                color: visual.backgroundTop
            }
            GradientStop {
                position: 1
                color: visual.backgroundBottom
            }
        }
    }

    CamperPageHeader {
        width: 800
        height: 58
        pageTitle: "12 / 230 V"
        v2LogoSource: root.v2LogoSource
        connected: root.adapter.customConnected === true
        onOpenVictronSettings: {
            if (visual.designV2)
                root.pageRequested(13);
            else
                root.openVictronSettings();
        }
        onCloseRequested: root.closeRequested()
    }

    Item {
        x: 0
        y: 58
        width: 800
        height: 364

        Rectangle {
            x: 14
            y: 10
            width: 772
            height: 76
            radius: 15
            color: root.inverter.on === true ? "#29203d" : visual.panel
            border.color: root.inverter.on === true ? visual.purple : visual.border

            CamperLineIcon {
                anchors.centerIn: parent
                width: 56
                height: 56
                kind: "plug"
                lineColor: root.inverter.on === true ? visual.purple : visual.muted
                strokeWidth: 2.2
            }
            Text {
                x: 22
                y: 13
                width: 180
                text: root.fmt(root.inverter.outputPower, 0, " W")
                color: root.inverter.on === true ? visual.purple : visual.muted
                font.pixelSize: 22
                font.bold: true
            }
            Text {
                x: 22
                y: 45
                width: 190
                text: "ANTIPPEN ZUM SCHALTEN"
                color: visual.muted
                font.pixelSize: 8
                font.bold: true
            }
            Text {
                x: 390
                y: 18
                width: 360
                horizontalAlignment: Text.AlignRight
                text: "MULTIPLUS COMPACT"
                color: root.inverter.on === true ? visual.purple : visual.text
                font.pixelSize: 16
                font.bold: true
            }
            Text {
                x: 390
                y: 43
                width: 360
                horizontalAlignment: Text.AlignRight
                text: root.inverter.on === true ? "230 V EINGESCHALTET" : "230 V AUSGESCHALTET"
                color: root.inverter.on === true ? visual.green : visual.muted
                font.pixelSize: 9
                font.bold: true
            }
            MouseArea {
                anchors.fill: parent
                enabled: root.adapter.customConnected === true
                onClicked: root.adapter.command("inverter", "set", root.inverter.on !== true, ({}))
            }
        }

        Repeater {
            model: Math.min(6, root.visibleChannels.length)
            delegate: Rectangle {
                required property int index
                readonly property var channelData: root.visibleChannels[index]
                readonly property string displayName: Number(channelData.channel) === 6 ? "MAXXFAN" : (channelData.name || "12 V KANAL")

                x: root.tileX(index)
                y: 98 + Math.floor(index / 3) * 121
                width: 246
                height: 107
                radius: 15
                color: channelData.on === true ? "#15342d" : visual.panel
                border.color: channelData.on === true ? visual.green : visual.border

                CamperLineIcon {
                    x: 94
                    y: 12
                    width: 58
                    height: 58
                    kind: root.powerIconKind(parent.channelData)
                    lineColor: parent.channelData.on === true ? visual.green : visual.muted
                    strokeWidth: 2.1
                }
                Text {
                    x: 18
                    y: 72
                    width: 210
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: parent.displayName
                    color: parent.channelData.on === true ? visual.green : visual.text
                    font.pixelSize: 13
                    font.bold: true
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: root.adapter.customConnected === true && Number(parent.channelData.channel) > 0
                    onClicked: root.adapter.command("starpower", "set", parent.channelData.on === true ? 0 : 1, {
                        channel: Number(parent.channelData.channel)
                    })
                }
            }
        }

        Text {
            visible: root.visibleChannels.length === 0
            anchors.centerIn: parent
            text: root.adapter.customConnected === true ? "KEINE 12-V-KANÄLE ERKANNT" : "CAMPER-BACKEND NICHT VERBUNDEN"
            color: visual.muted
            font.pixelSize: 15
            font.bold: true
        }
    }

    CamperNavBar {
        x: 0
        y: 422
        width: 800
        height: 58
        currentPage: 5
        onPageRequested: page => root.pageRequested(page)
    }
}
