#!/usr/bin/env python3

from pathlib import Path
import re
import unittest


ROOT = Path(__file__).parents[1]
V2_PAGES = ROOT / "pages" / "camper" / "v2"
V2_COMPONENTS = ROOT / "components" / "camper" / "v2"
MQTT = ROOT / "data" / "camper" / "CamperNodeRedMqttAdapter.qml"
FACADE = ROOT / "data" / "camper" / "CamperNodeRedAdapter.qml"
WEATHER = ROOT / "data" / "camper" / "CamperWeatherAdapter.qml"


class CamperV2ResourceContractTest(unittest.TestCase):
    def test_packaged_camper_ui_has_no_direct_http_poll_or_javascript_scheduler(self):
        cmake = (ROOT / "cmake" / "ModuleVenus_Sources.cmake").read_text(encoding="utf-8")
        self.assertNotIn("CamperNodeRedHttpAdapter.qml", cmake)
        self.assertNotIn("images/camper_logo.png", cmake)
        sources = [FACADE, MQTT, WEATHER, *V2_PAGES.glob("*.qml"), *V2_COMPONENTS.glob("*.qml")]
        combined = "\n".join(path.read_text(encoding="utf-8") for path in sources)
        self.assertNotIn("XMLHttpRequest", combined)
        self.assertNotIn("setInterval(", combined)
        self.assertNotIn("setTimeout(", combined)

    def test_only_bounded_low_frequency_timers_remain(self):
        sources = [MQTT, *V2_PAGES.glob("*.qml"), *V2_COMPONENTS.glob("*.qml")]
        combined = "\n".join(path.read_text(encoding="utf-8") for path in sources)
        intervals = sorted(int(value) for value in re.findall(r"\binterval:\s*(\d+)", combined))
        self.assertEqual(intervals, [20, 500, 1800, 30000])
        overlay = (V2_COMPONENTS / "CamperV2VehicleLightOverlay.qml").read_text(encoding="utf-8")
        self.assertIn("running: overlay.frontOn && overlay.frontAmber", overlay)
        mqtt = MQTT.read_text(encoding="utf-8")
        self.assertIn("repeat: false", mqtt)

        range_source = (V2_COMPONENTS / "CamperV2Range.qml").read_text(encoding="utf-8")
        climate = (V2_PAGES / "CamperV2Climate.qml").read_text(encoding="utf-8")
        lights = (V2_PAGES / "CamperV2Lights.qml").read_text(encoding="utf-8")
        self.assertIn("signal committed(real value)", range_source)
        self.assertIn("root.committed(root.pendingValue)", range_source)
        self.assertIn("onCommitted: value => root.adapter.command", climate)
        self.assertIn("onCommitted: value => root.dimLight", lights)
        self.assertNotIn("onMoved: value => root.adapter.command", climate)
        self.assertNotIn("onMoved: value => root.dimLight", lights)

    def test_external_payloads_and_visible_models_are_hard_capped(self):
        mqtt = MQTT.read_text(encoding="utf-8")
        weather = WEATHER.read_text(encoding="utf-8")
        panel = (V2_PAGES / "CamperV2WeatherPanel.qml").read_text(encoding="utf-8")
        quick = (V2_PAGES / "CamperV2QuickPanel.qml").read_text(encoding="utf-8")
        favorites = (V2_PAGES / "CamperV2FavoritesPanel.qml").read_text(encoding="utf-8")
        energy = (V2_PAGES / "CamperV2Energy.qml").read_text(encoding="utf-8")
        lights = (V2_PAGES / "CamperV2Lights.qml").read_text(encoding="utf-8")
        chart = (V2_COMPONENTS / "CamperV2WeatherChart.qml").read_text(encoding="utf-8")

        self.assertIn("item.value.length > 131072", mqtt)
        self.assertIn("value.length > 16384", mqtt)
        self.assertIn("weatherState.value.length > 16384", weather)
        self.assertIn("weather.hourly.slice(0, 48)", panel)
        self.assertIn("weather.daily.slice(0, 6)", panel)
        self.assertIn("quickAccessOptions.slice(0, 32)", quick)
        self.assertIn("quickAccessOptions.slice(0, 32)", favorites)
        self.assertIn("solar.chargers.slice(0, 8)", energy)
        self.assertIn("power.dcChannels.slice(0, 16)", energy)
        self.assertIn("snapshot.lights.items.slice(0, 16)", lights)
        self.assertIn("Math.min(24, values.length)", chart)

    def test_user_facing_core_models_have_fixed_layout_bounds(self):
        home = (V2_PAGES / "CamperV2Home.qml").read_text(encoding="utf-8")
        quick = (V2_PAGES / "CamperV2QuickPanel.qml").read_text(encoding="utf-8")
        favorites = (V2_PAGES / "CamperV2FavoritesPanel.qml").read_text(encoding="utf-8")
        weather = (V2_PAGES / "CamperV2WeatherPanel.qml").read_text(encoding="utf-8")
        self.assertIn("quickAccess.slice(0, 4)", home)
        self.assertIn("quickAccess.slice(0, 4)", quick)
        self.assertIn("favorites.slice(0, 4)", favorites)
        self.assertIn("model: 4", quick)
        self.assertIn("slice(0, 6)", weather)

    def test_shell_instantiates_only_the_visible_page(self):
        shell = (V2_PAGES / "CamperV2Shell.qml").read_text(encoding="utf-8")
        self.assertEqual(shell.count("Loader {"), 6)
        for page in range(6):
            self.assertIn(f"active: root.currentPage === {page}", shell)
        self.assertNotIn("visible: root.currentPage", shell)
        self.assertIn("property int energyPane: 0", shell)
        self.assertIn("property bool lightsRightView: false", shell)

        panels = (V2_PAGES / "CamperV2PanelHost.qml").read_text(encoding="utf-8")
        self.assertEqual(panels.count("Loader {"), 2)
        self.assertIn("active: root.activePanel === root.quickPanel", panels)
        self.assertIn("active: root.activePanel === root.weatherPanel", panels)
        self.assertNotIn("visible: root.activePanel === root.quickPanel", panels)
        self.assertNotIn("visible: root.activePanel === root.weatherPanel", panels)


if __name__ == "__main__":
    unittest.main()
