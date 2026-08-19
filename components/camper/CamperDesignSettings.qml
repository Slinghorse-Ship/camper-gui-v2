/* Local, per-frontend CamperControl presentation preference. */

pragma Singleton

import QtQuick
import QtCore

QtObject {
    id: root

    readonly property int version1: 1
    readonly property int version2: 2
    readonly property url settingsLocation: Qt.platform.os === "linux" ? "file:///data/campercontrol-gui-v2.ini" : ""
    property alias designVersion: storage.designVersion

    function setDesignVersion(version) {
        const normalizedVersion = Number(version) === version1 ? version1 : version2;
        if (storage.designVersion === normalizedVersion) {
            return;
        }
        storage.designVersion = normalizedVersion;
        storage.sync();
    }

    Component.onCompleted: {
        if (storage.designVersion !== version1 && storage.designVersion !== version2) {
            storage.designVersion = version2;
            storage.sync();
        }
    }

    property Settings _storage: Settings {
        id: storage
        category: "CamperControl"
        location: root.settingsLocation
        property int designVersion: 2
    }
}
