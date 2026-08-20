#!/usr/bin/env python3

from pathlib import Path
import re
import unittest


ROOT = Path(__file__).parents[1]
MQTT = ROOT / "data" / "camper" / "CamperNodeRedMqttAdapter.qml"
FACADE = ROOT / "data" / "camper" / "CamperNodeRedAdapter.qml"
BACKEND = ROOT / "data" / "camper" / "CamperBackendAdapter.qml"
WEATHER = ROOT / "data" / "camper" / "CamperWeatherAdapter.qml"


class CamperVrmTransportContractTest(unittest.TestCase):
    def test_gx_and_wasm_use_bridge_service_instance_zero_and_eight_fragments(self):
        source = MQTT.read_text(encoding="utf-8")
        self.assertIn('serviceUidFromName("com.victronenergy.campercontrol", 0)', source)
        self.assertIn("BackendConnection.vrmPortalMode === BackendConnection.Full", source)
        self.assertNotIn("XMLHttpRequest", source)
        for section in ("Ui", "Energy", "Water", "Climate", "Lights", "Vehicle", "Power", "Operations"):
            self.assertEqual(source.count(f'"/State/{section}"'), 1)

    def test_facade_uses_one_dbus_mqtt_transport_without_duplicate_http_poll(self):
        source = FACADE.read_text(encoding="utf-8")
        self.assertIn("CamperNodeRedMqttAdapter", source)
        self.assertNotIn("CamperNodeRedHttpAdapter", source)
        self.assertNotIn("Qt.platform.os", source)
        self.assertNotIn("XMLHttpRequest", source)

        cmake = (ROOT / "cmake" / "ModuleVenus_Sources.cmake").read_text(encoding="utf-8")
        self.assertIn("data/camper/CamperNodeRedMqttAdapter.qml", cmake)
        self.assertNotIn("data/camper/CamperNodeRedHttpAdapter.qml", cmake)

    def test_fragment_bursts_are_coalesced_before_rebuilding_state(self):
        source = MQTT.read_text(encoding="utf-8")
        self.assertIn("function scheduleRebuild()", source)
        self.assertIn("id: rebuildTimer", source)
        self.assertIn("interval: 20", source)
        self.assertGreaterEqual(source.count("onValueChanged: root.scheduleRebuild()"), 9)

    def test_weather_is_a_separate_read_only_vequickitem_for_gx_and_wasm(self):
        source = WEATHER.read_text(encoding="utf-8")
        self.assertIn('serviceUidFromName("com.victronenergy.campercontrol", 0)', source)
        self.assertIn('"/State/Weather"', source)
        self.assertIn("VeQuickItem", source)
        self.assertNotIn("XMLHttpRequest", source)
        self.assertNotIn("setValue", source)

    def test_monitor_only_separates_read_status_from_control_capability(self):
        source = BACKEND.read_text(encoding="utf-8")
        self.assertIn("customReadConnected: custom.connected", source)
        self.assertIn("customCommandsAllowed: custom.connected && custom.commandsAllowed", source)
        self.assertIn("customConnected: customCommandsAllowed", source)

        command_pages = []
        for path in (ROOT / "pages" / "camper").rglob("*.qml"):
            text = path.read_text(encoding="utf-8")
            if re.search(r"adapter\.(?:command|activateQuick|setQuickAccessIds|setFavoriteIds)", text):
                command_pages.append(path)
                self.assertTrue(
                    "customCommandsAllowed" in text or "customConnected" in text,
                    f"{path.relative_to(ROOT)} has a command path without a control-capability gate",
                )
        self.assertGreaterEqual(len(command_pages), 12)

        shell = (ROOT / "pages" / "camper" / "v2" / "CamperV2Shell.qml").read_text(encoding="utf-8")
        system = (ROOT / "pages" / "camper" / "v2" / "CamperV2System.qml").read_text(encoding="utf-8")
        self.assertIn("customReadConnected", shell)
        self.assertIn("customReadConnected", system)

    def test_vrm_cannot_turn_off_its_only_starlink_connection(self):
        source = MQTT.read_text(encoding="utf-8")
        self.assertIn("function isRemoteStarlinkOff(target, action, value, extra)", source)
        self.assertIn('Number(fields.channel) === 5', source)
        self.assertIn('body.origin = remoteSession ? "vrm" : "gx"', source)
        self.assertIn('Starlink kann über VRM nicht ausgeschaltet werden', source)

        energy = (ROOT / "pages" / "camper" / "v2" / "CamperV2Energy.qml").read_text(encoding="utf-8")
        home = (ROOT / "pages" / "camper" / "v2" / "CamperV2Home.qml").read_text(encoding="utf-8")
        quick = (ROOT / "pages" / "camper" / "v2" / "CamperV2QuickPanel.qml").read_text(encoding="utf-8")
        favorites = (ROOT / "pages" / "camper" / "v2" / "CamperV2FavoritesPanel.qml").read_text(encoding="utf-8")
        self.assertIn("remoteProtected", energy)
        self.assertIn("remoteProtected", home)
        self.assertIn('Remote geschützt', quick)
        self.assertIn('Remote geschützt', favorites)


if __name__ == "__main__":
    unittest.main()
