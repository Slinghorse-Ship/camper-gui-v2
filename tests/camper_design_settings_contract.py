#!/usr/bin/env python3

from pathlib import Path
import unittest


ROOT = Path(__file__).parents[1]
SETTINGS = ROOT / "components" / "camper" / "CamperDesignSettings.qml"
MAIN = ROOT / "src" / "main.cpp"
RENDER = ROOT / "tools" / "camper-preview" / "render.py"
SMOKE = ROOT / "tools" / "camper-preview" / "smoke_test.py"


class CamperDesignSettingsContractTest(unittest.TestCase):
    def test_native_gx_uses_persistent_data_file(self):
        source = SETTINGS.read_text(encoding="utf-8")
        self.assertIn('Qt.platform.os === "linux"', source)
        self.assertIn('file:///data/campercontrol-gui-v2.ini', source)
        self.assertIn('location: root.settingsLocation', source)

    def test_wasm_and_desktop_keep_platform_default_settings_backend(self):
        source = SETTINGS.read_text(encoding="utf-8")
        self.assertIn('? "file:///data/campercontrol-gui-v2.ini" : ""', source)
        self.assertNotIn("com.victronenergy.settings", source)
        self.assertNotIn("VeQuickItem", source)

        main_source = MAIN.read_text(encoding="utf-8")
        self.assertIn('setOrganizationName("Victron Energy")', main_source)
        self.assertIn('setOrganizationDomain("victronenergy.com")', main_source)

        for harness in (RENDER, SMOKE):
            source = harness.read_text(encoding="utf-8")
            self.assertIn('setOrganizationName("Victron Energy")', source)
            self.assertIn('setOrganizationDomain("victronenergy.com")', source)
            self.assertIn('setApplicationName("Venus")', source)

        smoke_source = SMOKE.read_text(encoding="utf-8")
        self.assertIn('"Failed to initialize QSettings"', smoke_source)
        self.assertIn('"Status code is: 1"', smoke_source)


if __name__ == "__main__":
    unittest.main()
