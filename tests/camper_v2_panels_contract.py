#!/usr/bin/env python3

from pathlib import Path
import unittest


ROOT = Path(__file__).parents[1]
MODULE = ROOT / "cmake" / "ModuleVenus_Sources.cmake"
SHELL = ROOT / "pages" / "camper" / "CamperShell.qml"
V2_SHELL = ROOT / "pages" / "camper" / "v2" / "CamperV2Shell.qml"
HOST = ROOT / "pages" / "camper" / "v2" / "CamperV2PanelHost.qml"
QUICK = ROOT / "pages" / "camper" / "v2" / "CamperV2QuickPanel.qml"
WEATHER = ROOT / "pages" / "camper" / "v2" / "CamperV2WeatherPanel.qml"
WEATHER_ADAPTER = ROOT / "data" / "camper" / "CamperWeatherAdapter.qml"
BACKEND = ROOT / "data" / "camper" / "CamperBackendAdapter.qml"
SETTINGS = ROOT / "pages" / "settings" / "PageCamperSettings.qml"
PREVIEW = ROOT / "tools" / "camper-preview" / "Main.qml"
SOLAR = ROOT / "pages" / "camper" / "CamperEnergySolarDetails.qml"


class CamperV2PanelsContractTest(unittest.TestCase):
    def test_weather_uses_one_read_only_dbus_mqtt_item(self):
        source = WEATHER_ADAPTER.read_text(encoding="utf-8")
        self.assertIn('serviceUidFromName("com.victronenergy.campercontrol", 0)', source)
        self.assertEqual(source.count('"/State/Weather"'), 1)
        self.assertEqual(source.count("VeQuickItem {"), 1)
        for forbidden in ("XMLHttpRequest", "setValue", "command(", "fetch(", "http://", "https://"):
            self.assertNotIn(forbidden, source)

        backend = BACKEND.read_text(encoding="utf-8")
        for name in ("weatherData", "weatherConnected", "weatherErrorText", "CamperWeatherAdapter"):
            self.assertIn(name, backend)

    def test_weather_panel_matches_the_cerbo_dwd_snapshot(self):
        source = WEATHER.read_text(encoding="utf-8")
        chart = (ROOT / "components" / "camper" / "v2" / "CamperV2WeatherChart.qml").read_text(encoding="utf-8")
        for field in (
            "hourly",
            "daily",
            "tempC",
            "precipProbabilityPct",
            "maxHourlyPrecipProbabilityPct",
            "minC",
            "maxC",
            "fetchedAtUtc",
            "stale",
            "station",
            "sun",
            "riseUtc",
            "setUtc",
        ):
            self.assertIn(field, source + chart)
        self.assertNotIn("sunriseUtc", source + chart)
        self.assertNotIn("sunsetUtc", source + chart)
        self.assertIn("currentFromHourly", source)
        self.assertIn("Quelle: Deutscher Wetterdienst", source)
        self.assertNotIn("XMLHttpRequest", source + chart)
        self.assertNotIn("adapter.command", source + chart)

    def test_one_exclusive_host_has_two_invisible_edge_swipes(self):
        source = HOST.read_text(encoding="utf-8")
        self.assertIn("activePanel", source)
        self.assertIn("closedPanel: 0", source)
        self.assertIn("quickPanel: 1", source)
        self.assertIn("weatherPanel: 2", source)
        self.assertIn("camperV2LeftEdgeSwipe", source)
        self.assertIn("camperV2RightEdgeSwipe", source)
        self.assertIn("camperV2SharedPanel", source)
        self.assertIn("camperV2PanelClose", source)
        self.assertIn("edgeWidth: 18", source)
        self.assertIn("swipeThreshold: 48", source)
        self.assertIn("horizontal >= vertical * 1.5", source)
        self.assertIn("y: 56", source)
        self.assertIn("height: 335", source)
        self.assertIn("width: 44", source)
        self.assertNotIn("edgeHandle", source)

        shell = V2_SHELL.read_text(encoding="utf-8")
        self.assertEqual(shell.count("CamperV2PanelHost"), 1)
        self.assertIn("panelHost.openQuick(true)", shell)

    def test_quick_panel_uses_only_existing_state_and_command_contract(self):
        source = QUICK.read_text(encoding="utf-8")
        for name in (
            "ui.quickAccess",
            "ui.quickAccessIds",
            "ui.quickAccessOptions",
            "adapter.activateQuick",
            "adapter.setQuickAccessIds",
            "customCommandsAllowed",
        ):
            self.assertIn(name, source)
        self.assertNotIn("quickAccessIds: [\"", source)
        self.assertNotIn("adapter.command", source)
        self.assertIn("width: 44", source)
        self.assertIn("height: 44", source)

    def test_v1_is_not_instantiated_or_packaged(self):
        module = MODULE.read_text(encoding="utf-8")
        shell = SHELL.read_text(encoding="utf-8")
        settings = SETTINGS.read_text(encoding="utf-8")
        preview = PREVIEW.read_text(encoding="utf-8")
        v1_packaged = (
            "CamperHome.qml",
            "CamperLights.qml",
            "CamperPower.qml",
            "CamperDetails.qml",
            "CamperSystem.qml",
            "CamperQuickAccess.qml",
            "CamperStyle.qml",
            "CamperNavBar.qml",
        )
        for filename in v1_packaged:
            self.assertNotIn(filename, module)
        for component in ("CamperHome {", "CamperLights {", "CamperPower {", "CamperDetails {", "CamperSystem {"):
            self.assertNotIn(component, shell + preview)
        self.assertIn("CamperV2Shell", shell)
        self.assertNotIn("CamperDesignSettings", shell + settings + preview)
        self.assertNotIn("ListRadioButtonGroup", settings)

    def test_new_runtime_files_are_in_the_shared_gx_wasm_qml_module(self):
        source = MODULE.read_text(encoding="utf-8")
        for path in (
            "data/camper/CamperWeatherAdapter.qml",
            "components/camper/v2/CamperV2WeatherChart.qml",
            "components/camper/v2/CamperV2WeatherIcon.qml",
            "pages/camper/v2/CamperV2PanelHost.qml",
            "pages/camper/v2/CamperV2QuickPanel.qml",
            "pages/camper/v2/CamperV2WeatherPanel.qml",
        ):
            self.assertEqual(source.count(path), 1)

    def test_indevolt_grid_boolean_bindings_never_return_undefined(self):
        source = SOLAR.read_text(encoding="utf-8")
        self.assertIn(
            "visible: Boolean(view.indevolt.gridConnection && view.indevolt.gridConnection.available === true)",
            source,
        )
        self.assertIn(
            "active: Boolean(view.indevolt.gridConnection && view.indevolt.gridConnection.on === true)",
            source,
        )
        self.assertIn(
            "font.bold: Boolean(view.indevolt.gridConnection && view.indevolt.gridConnection.available === true)",
            source,
        )


if __name__ == "__main__":
    unittest.main()
