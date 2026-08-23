from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CLIMATE = (ROOT / "pages/camper/v2/CamperV2Climate.qml").read_text(encoding="utf-8")
HOME = (ROOT / "pages/camper/v2/CamperV2Home.qml").read_text(encoding="utf-8")


class CamperV2ClimateControlsContract(unittest.TestCase):
    def test_climate_off_is_sent_from_both_surfaces(self):
        self.assertIn('mode: "off"', CLIMATE)
        self.assertIn('controlMode: mode', CLIMATE)
        self.assertIn('mode: "off"', HOME)
        self.assertIn('controlMode: mode', HOME)

    def test_home_navigation_does_not_cover_mode_buttons(self):
        self.assertIn(
            "MouseArea {\n            x: 0\n            y: 34\n"
            "            width: 196\n            height: parent.height - y\n"
            "            onClicked: root.pageRequested(2)",
            HOME,
        )

    def test_maxxfan_has_only_manual_directions(self):
        self.assertIn('label: "Abluft"', CLIMATE)
        self.assertIn('label: "Zuluft"', CLIMATE)
        self.assertNotIn('root.adapter.command("maxxfan", "auto"', CLIMATE)
        self.assertNotIn('label: "Auto"', CLIMATE)


if __name__ == "__main__":
    unittest.main()
