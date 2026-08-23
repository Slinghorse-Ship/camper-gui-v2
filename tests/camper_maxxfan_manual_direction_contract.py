import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MAXXFAN = ROOT / "pages" / "camper" / "CamperMaxxFanDetails.qml"


class MaxxFanManualDirectionContract(unittest.TestCase):
    def test_internal_auto_hold_is_not_exposed(self):
        source = MAXXFAN.read_text(encoding="utf-8")
        self.assertNotIn("fan.autoHold", source)
        self.assertNotIn('commandRequested("auto"', source)
        self.assertNotIn("HAUBE & AUTOMATIK", source)

    def test_manual_air_direction_and_confirmed_power_state_remain(self):
        source = MAXXFAN.read_text(encoding="utf-8")
        self.assertIn('label: "ABLUFT"', source)
        self.assertIn('label: "ZULUFT"', source)
        self.assertIn('commandRequested("mode", "forward")', source)
        self.assertIn('commandRequested("mode", "reverse")', source)
        self.assertIn('view.fan.on === true ? "AUSSCHALTEN" : "EINSCHALTEN"', source)
        self.assertIn('commandRequested("set", view.fan.on !== true)', source)


if __name__ == "__main__":
    unittest.main()
