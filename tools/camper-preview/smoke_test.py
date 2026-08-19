"""Touch smoke test for the 800x480 Camper Home preview."""

from __future__ import annotations

import hashlib
import os
from pathlib import Path
import sys

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
os.environ.setdefault("QSG_RHI_BACKEND", "software")
os.environ.setdefault("QT_QPA_FONTDIR", str(Path(__file__).resolve().parents[2] / "fonts"))

from PySide6.QtCore import QPoint, Qt, QUrl, qInstallMessageHandler
from PySide6.QtGui import QGuiApplication, QImage
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtTest import QTest


def expect(window, name: str, expected: int) -> None:
	actual = window.property(name)
	if actual != expected:
		raise AssertionError(f"{name}: expected {expected}, got {actual}")


def expect_text(window, name: str, expected: str) -> None:
	actual = window.property(name)
	if actual != expected:
		raise AssertionError(f"{name}: expected {expected!r}, got {actual!r}")


def click(window, x: int, y: int) -> None:
	QTest.mouseClick(window, Qt.LeftButton, Qt.NoModifier, QPoint(x, y), 20)
	QGuiApplication.processEvents()


def expect_asset(path: Path, expected_sha256: str) -> None:
	actual_sha256 = hashlib.sha256(path.read_bytes()).hexdigest().upper()
	if actual_sha256 != expected_sha256:
		raise AssertionError(f"{path.name}: expected SHA256 {expected_sha256}, got {actual_sha256}")
	image = QImage(str(path))
	if image.isNull() or not image.hasAlphaChannel():
		raise AssertionError(f"{path.name}: expected a readable image with an alpha channel")
	for x, y in ((0, 0), (image.width() - 1, 0), (0, image.height() - 1), (image.width() - 1, image.height() - 1)):
		if image.pixelColor(x, y).alpha() != 0:
			raise AssertionError(f"{path.name}: corner ({x}, {y}) is not transparent")


def expect_frame_corners(window, expected_top: str, expected_bottom: str) -> None:
	QTest.qWait(80)
	frame = window.screen().grabWindow(window.winId()).toImage()
	if frame.isNull() or frame.width() != 800 or frame.height() != 480:
		raise AssertionError(f"expected an 800x480 frame, got {frame.width()}x{frame.height()}")
	for x, y, expected in ((0, 0, expected_top), (799, 0, expected_top), (0, 479, expected_bottom), (799, 479, expected_bottom)):
		actual = frame.pixelColor(x, y).name().upper()
		if actual != expected:
			raise AssertionError(f"frame corner ({x}, {y}): expected {expected}, got {actual}")


def main() -> int:
	qt_messages = []

	def qt_message_handler(_message_type, _context, message):
		qt_messages.append(message)

	qInstallMessageHandler(qt_message_handler)
	app = QGuiApplication(sys.argv[:1])
	app.setOrganizationName("Victron Energy")
	app.setOrganizationDomain("victronenergy.com")
	app.setApplicationName("Venus")
	engine = QQmlApplicationEngine()
	qml_path = Path(__file__).with_name("Main.qml").resolve()
	engine.load(QUrl.fromLocalFile(str(qml_path)))
	if not engine.rootObjects():
		return 2
	repository = qml_path.parents[2]
	expect_asset(repository / "images" / "camper_transit_line_dark.png", "F54F528AF869C6F3CC2DEC1A7B90AE730B6DF1D431F67AEB55328BA1FD6AA605")
	expect_asset(repository / "images" / "camper_transit_line_light.png", "2B67063319CDB66767CCA2229996B9E6161A849EDDD6B0941FB5F984CF1A594F")

	window = engine.rootObjects()[0]
	expect(window, "previewDesignVersion", 2)
	window.setProperty("previewDesignVersion", 1)
	QTest.qWait(250)

	click(window, 693, 28)
	expect(window, "settingsClickCount", 1)

	click(window, 769, 28)
	expect(window, "closeClickCount", 1)

	click(window, 130, 451)
	expect(window, "lastRequestedPage", 0)

	click(window, 400, 451)
	expect(window, "lastRequestedPage", 1)

	click(window, 667, 451)
	expect(window, "lastRequestedPage", 5)

	click(window, 130, 451)
	expect(window, "lastRequestedPage", 0)

	click(window, 722, 308)
	expect(window, "currentCamperPage", 12)

	click(window, 354, 179)
	expect(window, "quickSettingsCount", 1)

	click(window, 726, 28)
	expect(window, "currentCamperPage", 0)

	click(window, 105, 360)
	expect(window, "quickCommandCount", 1)

	for x, y, expected_page in (
		(100, 110, 8),
		(300, 110, 7),
		(500, 110, 11),
		(700, 110, 10),
		(100, 185, 6),
		(100, 260, 9),
	):
		click(window, x, y)
		expect(window, "currentCamperPage", expected_page)
		click(window, 52, 86)
		expect(window, "currentCamperPage", 0)

	# V2 is a distinct six-page shell backed by the same command adapter.
	window.setProperty("previewDesignVersion", 2)
	window.setProperty("currentCamperPage", 0)
	QGuiApplication.processEvents()
	window.setProperty("previewV2DayMode", False)
	expect_frame_corners(window, "#0D1722", "#080C12")
	window.setProperty("previewV2DayMode", True)
	expect_frame_corners(window, "#F8FAFB", "#EDF2F4")
	window.setProperty("previewV2DayMode", False)
	QGuiApplication.processEvents()
	previous_close_clicks = window.property("closeClickCount")
	click(window, 769, 25)
	expect(window, "closeClickCount", previous_close_clicks + 1)
	for x, expected_page in ((80, 0), (208, 1), (336, 2), (464, 3), (592, 4), (720, 5)):
		click(window, x, 430)
		expect(window, "currentCamperPage", expected_page)

	# Light cards and energy cards issue only existing adapter commands.
	click(window, 208, 430)
	previous_commands = window.property("commandCount")
	click(window, 520, 121)
	expect(window, "commandCount", previous_commands + 1)
	expect_text(window, "lastCommandTarget", "starpower")

	# Vehicle high beam must never invert the separate manual output state.
	window.setProperty("previewHighBeamVehicleOn", True)
	window.setProperty("previewHighBeamManualOn", False)
	QGuiApplication.processEvents()
	previous_commands = window.property("commandCount")
	click(window, 700, 252)
	expect(window, "commandCount", previous_commands + 1)
	expect_text(window, "lastCommandTarget", "starpower")
	expect(window, "lastCommandValue", 1)
	expect(window, "lastCommandChannel", 3)
	window.setProperty("previewHighBeamOutputOnline", False)
	QGuiApplication.processEvents()
	previous_commands = window.property("commandCount")
	click(window, 700, 252)
	expect(window, "commandCount", previous_commands)
	window.setProperty("previewHighBeamOutputOnline", True)

	click(window, 464, 430)
	previous_commands = window.property("commandCount")
	click(window, 90, 170)
	expect(window, "commandCount", previous_commands + 1)
	expect_text(window, "lastCommandTarget", "starpower")

	# Orion is unavailable in the fixture: it renders disabled and emits no command.
	click(window, 230, 77)
	previous_commands = window.property("commandCount")
	click(window, 395, 210)
	expect(window, "commandCount", previous_commands)
	click(window, 650, 210)
	expect(window, "commandCount", previous_commands + 1)
	expect_text(window, "lastCommandTarget", "indevoltGrid")

	# The local V1 selector applies immediately and returns to the productive V1 Home.
	click(window, 716, 451)
	expect(window, "currentCamperPage", 5)
	click(window, 300, 165)
	expect(window, "previewDesignVersion", 1)
	expect(window, "currentCamperPage", 0)

	settings_errors = [
		message
		for message in qt_messages
		if "Failed to initialize QSettings" in message or "Status code is: 1" in message
	]
	if settings_errors:
		raise AssertionError(f"QSettings initialization failed: {settings_errors}")

	print("PASS touch targets: unchanged V1, full-bleed V2 day/night, Victron return, six-page nav, disabled unavailable source, adapter commands, local design selector and exact RGBA Transit assets")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
