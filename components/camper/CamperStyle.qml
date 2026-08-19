import QtQuick

// Canonical visual tokens shared with Ford SYNC and the Node-RED dashboard.
QtObject {
    id: style

    property bool dayMode: false
    readonly property bool designV2: CamperDesignSettings.designVersion === CamperDesignSettings.version2

    readonly property color backgroundTop: designV2 ? (dayMode ? "#f8fafb" : "#0d1722") : (dayMode ? "#fafafa" : "#081116")
    readonly property color backgroundBottom: designV2 ? (dayMode ? "#edf2f4" : "#080c12") : (dayMode ? "#eceff1" : "#03090d")
    readonly property color header: designV2 ? (dayMode ? "#f8fafb" : "#0d1722") : (dayMode ? "#ffffff" : "#071116")
    readonly property color panel: designV2 ? (dayMode ? "#ffffff" : "#111923") : (dayMode ? "#fbfbfb" : "#111b20")
    readonly property color inner: designV2 ? (dayMode ? "#e8eef1" : "#15212b") : (dayMode ? "#f1f3f4" : "#0d171c")
    readonly property color text: designV2 ? (dayMode ? "#10161a" : "#f3f7fa") : (dayMode ? "#24282c" : "#f4f7f9")
    readonly property color muted: designV2 ? (dayMode ? "#60717b" : "#9babb6") : (dayMode ? "#626a70" : "#aab4ba")
    readonly property color border: designV2 ? (dayMode ? "#cad6dc" : "#1f9cc2dd") : (dayMode ? "#d0d3d5" : "#344149")

    readonly property color blue: designV2 ? (dayMode ? "#006f9f" : "#59caff") : (dayMode ? "#0875c1" : "#42b9f4")
    readonly property color green: designV2 ? (dayMode ? "#087a58" : "#2ed8b0") : (dayMode ? "#11845f" : "#2fd49b")
    readonly property color orange: designV2 ? (dayMode ? "#d66b00" : "#ffad45") : (dayMode ? "#d66b00" : "#ff981f")
    readonly property color yellow: dayMode ? "#a96f00" : "#f4c94c"
    readonly property color purple: dayMode ? "#7555b5" : "#ad8cf2"
    readonly property color red: dayMode ? "#b83f4a" : "#ef6e76"

    readonly property color selectedBlue: designV2 ? (dayMode ? "#e2f5fc" : "#123044") : (dayMode ? "#e4f3fb" : "#102b38")
    readonly property color selectedGreen: designV2 ? (dayMode ? "#e4f7ef" : "#112b27") : (dayMode ? "#e0f4ec" : "#15352d")
    readonly property color pressed: designV2 ? (dayMode ? "#dce7eb" : "#1c2b39") : (dayMode ? "#d9e1e5" : "#263640")
    readonly property color disabled: designV2 ? (dayMode ? "#e1e7ea" : "#131d26") : (dayMode ? "#e1e4e6" : "#182229")
}
