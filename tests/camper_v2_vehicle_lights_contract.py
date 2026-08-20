#!/usr/bin/env python3

from pathlib import Path
import struct
import unittest


ROOT = Path(__file__).parents[1]
OVERLAY = ROOT / "components" / "camper" / "v2" / "CamperV2VehicleLightOverlay.qml"
PAGE = ROOT / "pages" / "camper" / "v2" / "CamperV2Lights.qml"


def png_size(path: Path) -> tuple[int, int]:
    raw = path.read_bytes()[:24]
    if raw[:8] != b"\x89PNG\r\n\x1a\n":
        raise AssertionError(f"not a PNG: {path}")
    return struct.unpack(">II", raw[16:24])


class CamperV2VehicleLightsContractTest(unittest.TestCase):
    def test_both_vehicle_assets_keep_the_measured_560_by_360_coordinate_space(self):
        for name in ("camper_v2_vehicle_left.png", "camper_v2_vehicle_right.png"):
            self.assertEqual(png_size(ROOT / "images" / name), (560, 360))

    def test_glows_use_measured_roof_fixture_coordinates(self):
        source = OVERLAY.read_text(encoding="utf-8")
        for coordinates in (
            "65, 73, 45",
            "154, 162, 41",
            "374, 383, 33",
            "458, 466, 36",
            "rightView ? 52 : 437, 12",
            "rightView ? 260 : 166",
            "rightView ? 407 : 339",
            "rightView ? 39 : 50",
        ):
            self.assertIn(coordinates, source)
        self.assertIn("fixtureLine", source)
        self.assertIn("fixtureSquare", source)

    def test_click_router_uses_the_same_physical_fixture_coordinates(self):
        source = PAGE.read_text(encoding="utf-8")
        self.assertIn("function handleVehicleLampClick", source)
        for coordinates in (
            "69, 45",
            "158, 41",
            "378, 33",
            "462, 36",
            "rightView ? 52 : 437, 12",
            "rightView ? 260 : 166",
            "rightView ? 407 : 339",
            "rightView ? 39 : 50",
        ):
            self.assertIn(coordinates, source)
        self.assertIn("nearest > 34", source)
        self.assertEqual(source.count("handleVehicleLampClick(mouse.x"), 1)

    def test_blink_timer_runs_only_while_amber_light_is_active(self):
        source = OVERLAY.read_text(encoding="utf-8")
        self.assertIn("running: overlay.frontOn && overlay.frontAmber", source)
        self.assertEqual(source.count("interval: 500"), 1)


if __name__ == "__main__":
    unittest.main()
