#!/usr/bin/env python3

from pathlib import Path
import unittest


ROOT = Path(__file__).parents[1]
HOME = ROOT / "pages" / "camper" / "v2" / "CamperV2Home.qml"
ENERGY = ROOT / "pages" / "camper" / "v2" / "CamperV2Energy.qml"
CLIMATE = ROOT / "pages" / "camper" / "v2" / "CamperV2Climate.qml"
LIGHTS = ROOT / "pages" / "camper" / "v2" / "CamperV2Lights.qml"
WEATHER = ROOT / "pages" / "camper" / "v2" / "CamperV2WeatherPanel.qml"
WEATHER_CHART = ROOT / "components" / "camper" / "v2" / "CamperV2WeatherChart.qml"
WEATHER_ICON = ROOT / "components" / "camper" / "v2" / "CamperV2WeatherIcon.qml"
NATIVE = ROOT / "data" / "camper" / "CamperVictronAdapter.qml"
VIEWPORT = ROOT / "components" / "camper" / "CamperViewport.qml"
SHELL = ROOT / "pages" / "camper" / "CamperShell.qml"


class CamperV2FinalUiContractTest(unittest.TestCase):
    def test_solar_total_never_adds_the_separate_indevolt_source(self):
        for path in (HOME, ENERGY):
            source = path.read_text(encoding="utf-8")
            function = source[source.index("function solarTotal()") : source.index("\n    }", source.index("function solarTotal()"))]
            self.assertNotIn("indevolt", function)
            self.assertIn("solar.power", function)

    def test_energy_panes_have_bounded_non_overlapping_800x480_geometry(self):
        source = ENERGY.read_text(encoding="utf-8")
        for object_name in (
            "camperV2EnergyPowerPane",
            "camperV2EnergyDcCard",
            "camperV2EnergyAcCard",
            "camperV2EnergySourcesPane",
            "camperV2EnergySolarCard",
            "camperV2EnergyOrionCard",
            "camperV2EnergyIndevoltCard",
        ):
            self.assertIn(f'objectName: "{object_name}"', source)
        for token in ("width: 776", "height: 274", "x: 511", "width: 265", "x: 523", "width: 253"):
            self.assertIn(token, source)

    def test_home_uses_original_victron_dc_total_and_separate_battery_direction(self):
        native = NATIVE.read_text(encoding="utf-8")
        home = HOME.read_text(encoding="utf-8")
        self.assertIn("Global.system.dc.power", native)
        self.assertIn("Global.system.battery.power", native)
        self.assertIn("Global.system.battery.timeToGo", native)
        self.assertIn("root.energy.dcSystemPower", home)
        self.assertIn('objectName: "camperV2HomeDcPower"', home)
        self.assertIn('return "Lädt +"', home)
        self.assertIn('return "Entlädt "', home)
        self.assertIn('return "Ruhe"', home)
        self.assertIn("power > 5", home)
        self.assertIn("power < -5", home)
        self.assertIn("root.battery.timeToGoSeconds", home)
        self.assertIn('seconds >= 86400 ? " Tage" : " h"', home)

    def test_climate_control_is_one_cerbo_owned_three_way_settings_patch(self):
        for path in (HOME, CLIMATE):
            source = path.read_text(encoding="utf-8")
            self.assertIn('["off", "manual", "auto"]', source)
            self.assertIn("controlMode: mode", source)
            self.assertIn('label: "Aus"', source)
            self.assertIn('label: "Manuell"', source)
            self.assertIn('label: "Automatik"', source)
            control = source[source.index("function setControlMode") : source.index("\n    }", source.index("function setControlMode"))]
            self.assertEqual(control.count('root.adapter.command("settings", "patch"'), 1)
            self.assertNotIn('command("heater"', control)
            self.assertNotIn('command("maxxfan"', control)

    def test_light_scene_editor_writes_settings_only_and_keeps_run_separate(self):
        source = LIGHTS.read_text(encoding="utf-8")
        self.assertIn("snapshot.operations", source)
        self.assertIn("operations.lightScenes", source.replace("snapshot.", ""))
        self.assertIn("lightingScenes[sceneEditorId] = values", source)
        self.assertIn('adapter.command("settings", "patch"', source)
        self.assertIn('adapter.command("scene", "run"', source)
        save = source[source.index("function saveSceneProfile") : source.index("\n    }", source.index("function saveSceneProfile"))]
        self.assertNotIn('command("starpower"', save)

    def test_weather_tides_are_optional_read_only_cerbo_data(self):
        source = WEATHER.read_text(encoding="utf-8")
        chart = WEATHER_CHART.read_text(encoding="utf-8")
        weather_icon = WEATHER_ICON.read_text(encoding="utf-8")
        for token in ("weather.tides", "nextHigh", "nextLow", '"BSH Tide "', "heightM"):
            self.assertIn(token, source)
        for token in ("tides.curve", "tideData", "validTidePointCount", "hasTideCurve", "tideColor"):
            self.assertIn(token, source + chart)
        self.assertIn("tideData.length > 27", chart)
        self.assertIn("time <= previousTime", chart)
        self.assertIn("chartStartTime + 24 * 60 * 60 * 1000", chart)
        self.assertIn("root.hasTideCurve ? root.tidePoints[0].time", chart)
        self.assertIn('return "unknown"', weather_icon)
        self.assertIn('ctx.fillText("?"', weather_icon)
        self.assertIn("point.time >= chartStartTime && point.time <= chartEndTime", chart)
        self.assertIn('const left = 43', chart)
        self.assertIn('Math.ceil(maximum) + " °C"', chart)
        self.assertIn('Math.floor(minimum) + " °C"', chart)
        self.assertIn('tideMinimum.toFixed(1).replace(".", ",") + " m"', chart)
        self.assertIn('text: "Tide"', source)
        for forbidden in ("XMLHttpRequest", "https://", "http://", "adapter.command"):
            self.assertNotIn(forbidden, source + chart)

    def test_weather_maps_every_official_mosmix_group_and_defensive_hail(self):
        panel = WEATHER.read_text(encoding="utf-8")
        icon = WEATHER_ICON.read_text(encoding="utf-8")
        for code in (0, 1, 2, 3, 45, 49, 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 68, 69, 71, 73, 75, 80, 81, 82, 83, 84, 85, 86, 95):
            self.assertIn(f"{code}:", panel)
        self.assertIn("code === 80 || code === 81 || code === 82", icon)
        self.assertIn("code === 83 || code === 84", icon)
        self.assertIn("code === 96 || code === 99", icon)
        self.assertIn('return "hail"', icon)
        self.assertIn('96: "Hagelgewitter"', panel)
        self.assertIn('99: "Starkes Hagelgewitter"', panel)

    def test_wasm_viewport_fills_canvas_uniformly_while_gx_stays_800_by_480(self):
        viewport = VIEWPORT.read_text(encoding="utf-8")
        shell = SHELL.read_text(encoding="utf-8")
        self.assertIn("Math.min(width / logicalWidth, height / logicalHeight)", viewport)
        self.assertIn("root.width / root.contentScale", viewport)
        self.assertIn("root.height / root.contentScale", viewport)
        self.assertIn("anchors.fill: parent", shell)
        self.assertNotIn("width: 800\n            height: 480", shell)


if __name__ == "__main__":
    unittest.main()
