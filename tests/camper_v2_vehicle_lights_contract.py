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
            "63, 44.5, 79, 44.5",
            "147, 43.5, 164, 43.5",
            "368, 37.5, 384, 37.5",
            "454, 38.5, 471, 38.5",
            "rightView ? 50 : 439, 12",
            "rightView ? 263 : 168",
            "rightView ? 60 : 49",
            "rightView ? 403 : 317",
            "rightView ? 65 : 49",
            "rightView ? 223 : 402",
        ):
            self.assertIn(coordinates, source)
        self.assertIn("fixtureLine", source)
        self.assertIn("fixtureSquare", source)

    def test_click_router_uses_the_same_physical_fixture_coordinates(self):
        source = PAGE.read_text(encoding="utf-8")
        self.assertIn("function handleVehicleLampClick", source)
        for coordinates in (
            "71, 44.5",
            "155.5, 43.5",
            "376, 37.5",
            "462.5, 38.5",
            "rightView ? 50 : 439, 12",
            "263, 60, 403, 65",
            "168, 49, 317, 49",
        ):
            self.assertIn(coordinates, source)
        self.assertIn("nearest > 34", source)
        self.assertEqual(source.count("handleVehicleLampClick(mouse.x"), 1)

    def test_right_control_matrix_matches_requested_inside_rear_left_right_order(self):
        source = PAGE.read_text(encoding="utf-8")
        start = source.index('model: [\n                    {\n                        id: "inside_main"')
        end = source.index("                ]", start)
        model = source[start:end]
        self.assertLess(model.index('id: "inside_main"'), model.index('id: "outside_rear"'))
        self.assertLess(model.index('id: "outside_rear"'), model.index('id: "outside_left"'))
        self.assertLess(model.index('id: "outside_left"'), model.index('id: "outside_right"'))

    def test_blink_timer_runs_only_while_amber_light_is_active(self):
        source = OVERLAY.read_text(encoding="utf-8")
        self.assertIn("running: overlay.frontOn && overlay.frontAmber", source)
        self.assertEqual(source.count("interval: 500"), 1)


if __name__ == "__main__":
    unittest.main()
