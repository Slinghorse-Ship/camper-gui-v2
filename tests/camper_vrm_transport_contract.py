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
    def test_wasm_uses_mqtt_service_instance_zero_and_seven_fragments(self):
        source = MQTT.read_text(encoding="utf-8")
        self.assertIn('serviceUidFromName("com.victronenergy.campercontrol", 0)', source)
        self.assertIn("BackendConnection.vrmPortalMode === BackendConnection.Full", source)
        self.assertNotIn("XMLHttpRequest", source)
        for section in ("Ui", "Energy", "Water", "Climate", "Lights", "Vehicle", "Power"):
            self.assertEqual(source.count(f'"/State/{section}"'), 1)

    def test_facade_keeps_native_http_and_selects_mqtt_only_for_wasm(self):
        source = FACADE.read_text(encoding="utf-8")
        self.assertIn('Qt.platform.os === "wasm" ? mqttTransport : httpTransport', source)
        self.assertIn("CamperNodeRedHttpAdapter", source)
        self.assertIn("CamperNodeRedMqttAdapter", source)

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
            if re.search(r"adapter\.(?:command|activateQuick|setQuickAccessIds)", text):
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


if __name__ == "__main__":
    unittest.main()
