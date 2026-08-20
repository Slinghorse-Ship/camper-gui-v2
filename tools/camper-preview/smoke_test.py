"""Touch smoke test for the V2-only 800x480 CamperControl preview."""

from __future__ import annotations

import hashlib
import os
from pathlib import Path
import sys

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
os.environ.setdefault("QSG_RHI_BACKEND", "software")
os.environ.setdefault("QT_QPA_FONTDIR", str(Path(__file__).resolve().parents[2] / "fonts"))

from PySide6.QtCore import QObject, QPoint, Qt, QUrl, qInstallMessageHandler
from PySide6.QtGui import QGuiApplication, QImage
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtTest import QTest


def expect(window, name: str, expected) -> None:
	actual = window.property(name)
	if actual != expected:
		raise AssertionError(f"{name}: expected {expected!r}, got {actual!r}")


def expect_text(window, name: str, expected: str) -> None:
	actual = window.property(name)
	if actual != expected:
		raise AssertionError(f"{name}: expected {expected!r}, got {actual!r}")


def click(window, x: int, y: int) -> None:
	QTest.mouseClick(window, Qt.LeftButton, Qt.NoModifier, QPoint(x, y), 20)
	QGuiApplication.processEvents()


def swipe(window, start: QPoint, end: QPoint) -> None:
	QTest.mousePress(window, Qt.LeftButton, Qt.NoModifier, start, 20)
	for step in range(1, 6):
		point = QPoint(
			start.x() + (end.x() - start.x()) * step // 5,
			start.y() + (end.y() - start.y()) * step // 5,
		)
		QTest.mouseMove(window, point, 15)
	QTest.mouseRelease(window, Qt.LeftButton, Qt.NoModifier, end, 20)
	QTest.qWait(80)


def expect_asset(path: Path, expected_sha256: str) -> None:
	actual_sha256 = hashlib.sha256(path.read_bytes()).hexdigest().upper()
	if actual_sha256 != expected_sha256:
		raise AssertionError(f"{path.name}: expected SHA256 {expected_sha256}, got {actual_sha256}")
	image = QImage(str(path))
	if image.isNull() or not image.hasAlphaChannel():
		raise AssertionError(f"{path.name}: expected a readable image with an alpha channel")
	for x, y in (
		(0, 0),
		(image.width() - 1, 0),
		(0, image.height() - 1),
		(image.width() - 1, image.height() - 1),
	):
		if image.pixelColor(x, y).alpha() != 0:
			raise AssertionError(f"{path.name}: corner ({x}, {y}) is not transparent")


def expect_frame_corners(window, expected_top: str, expected_bottom: str) -> None:
	QTest.qWait(80)
	frame = window.screen().grabWindow(window.winId()).toImage()
	if frame.isNull() or frame.width() != 800 or frame.height() != 480:
		raise AssertionError(f"expected an 800x480 frame, got {frame.width()}x{frame.height()}")
	for x, y, expected in (
		(0, 0, expected_top),
		(799, 0, expected_top),
		(0, 479, expected_bottom),
		(799, 479, expected_bottom),
	):
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
		for message in qt_messages:
			print(message, file=sys.stderr)
		return 2

	repository = qml_path.parents[2]
	expect_asset(
		repository / "images" / "camper_transit_line_dark.png",
		"F54F528AF869C6F3CC2DEC1A7B90AE730B6DF1D431F67AEB55328BA1FD6AA605",
	)
	expect_asset(
		repository / "images" / "camper_transit_line_light.png",
		"2B67063319CDB66767CCA2229996B9E6161A849EDDD6B0941FB5F984CF1A594F",
	)

	window = engine.rootObjects()[0]
	expect(window, "previewActivePanel", 0)
	window.setProperty("previewV2DayMode", False)
	expect_frame_corners(window, "#0D1722", "#080C12")
	window.setProperty("previewV2DayMode", True)
	expect_frame_corners(window, "#F8FAFB", "#EDF2F4")
	window.setProperty("previewV2DayMode", False)
	QGuiApplication.processEvents()

	# Header close keeps the original Victron UI reachable.
	click(window, 769, 25)
	expect(window, "closeClickCount", 1)
	click(window, 3, 25)
	expect(window, "previewActivePanel", 0)
	click(window, 797, 430)
	expect(window, "previewActivePanel", 0)

	# The V2 shell is the only productive six-page UI.
	for x, expected_page in ((80, 0), (208, 1), (336, 2), (464, 3), (592, 4), (720, 5)):
		click(window, x, 430)
		expect(window, "currentCamperPage", expected_page)

	# Original Victron settings and the original view remain available in System.
	click(window, 650, 150)
	expect(window, "settingsClickCount", 1)
	click(window, 650, 250)
	expect(window, "closeClickCount", 2)

	# Existing light and energy commands retain their command-capability gate.
	click(window, 208, 430)
	previous_commands = window.property("commandCount")
	click(window, 520, 121)
	expect(window, "commandCount", previous_commands + 1)
	expect_text(window, "lastCommandTarget", "starpower")

	# Dragging previews locally but emits exactly one bounded command on release.
	previous_commands = window.property("commandCount")
	swipe(window, QPoint(500, 343), QPoint(700, 343))
	expect(window, "commandCount", previous_commands + 1)
	expect_text(window, "lastCommandTarget", "starpower")
	expect_text(window, "lastCommandAction", "dim")

	window.setProperty("previewHighBeamVehicleOn", True)
	window.setProperty("previewHighBeamManualOn", False)
	QGuiApplication.processEvents()
	previous_commands = window.property("commandCount")
	click(window, 700, 252)
	expect(window, "commandCount", previous_commands + 1)
	expect_text(window, "lastCommandTarget", "starpower")
	expect(window, "lastCommandValue", 1)
	expect(window, "lastCommandChannel", 3)

	click(window, 464, 430)
	previous_commands = window.property("commandCount")
	click(window, 90, 170)
	expect(window, "commandCount", previous_commands + 1)
	expect_text(window, "lastCommandTarget", "starpower")

	# Left edge opens the one shared host with real quickAccess state.
	click(window, 80, 430)
	swipe(window, QPoint(3, 210), QPoint(63, 265))
	expect(window, "previewActivePanel", 0)
	swipe(window, QPoint(3, 210), QPoint(105, 210))
	expect(window, "previewActivePanel", 1)
	if window.findChild(QObject, "camperV2QuickPanel") is None:
		raise AssertionError("quick panel was not instantiated in the shared host")
	previous_quick = window.property("quickCommandCount")
	click(window, 100, 175)
	expect(window, "quickCommandCount", previous_quick + 1)

	# Monitor-only still shows state but blocks switching and editing.
	window.setProperty("previewCustomCommandsAllowed", False)
	QGuiApplication.processEvents()
	previous_quick = window.property("quickCommandCount")
	click(window, 100, 175)
	expect(window, "quickCommandCount", previous_quick)
	previous_settings = window.property("quickSettingsCount")
	click(window, 270, 86)
	click(window, 292, 150)
	expect(window, "quickSettingsCount", previous_settings)
	window.setProperty("previewCustomCommandsAllowed", True)
	QGuiApplication.processEvents()

	# The existing Cerbo quickAccessIds/options editor remains available.
	click(window, 270, 86)
	previous_settings = window.property("quickSettingsCount")
	click(window, 292, 150)
	expect(window, "quickSettingsCount", previous_settings + 1)
	click(window, 310, 27)
	expect(window, "previewActivePanel", 0)

	# Right edge opens the read-only DWD view with chart and daily forecast.
	swipe(window, QPoint(797, 210), QPoint(690, 210))
	expect(window, "previewActivePanel", 2)
	if window.findChild(QObject, "camperV2WeatherPanel") is None:
		raise AssertionError("weather panel was not instantiated in the shared host")
	if window.findChild(QObject, "camperV2WeatherChart") is None:
		raise AssertionError("24-hour weather chart was not instantiated")
	previous_commands = window.property("commandCount")
	previous_quick = window.property("quickCommandCount")
	click(window, 350, 250)
	expect(window, "commandCount", previous_commands)
	expect(window, "quickCommandCount", previous_quick)

	# While one panel is open the opposite edge is inactive.
	swipe(window, QPoint(3, 210), QPoint(105, 210))
	expect(window, "previewActivePanel", 2)
	click(window, 770, 27)
	expect(window, "previewActivePanel", 0)

	settings_errors = [
		message
		for message in qt_messages
		if "Failed to initialize QSettings" in message or "Status code is: 1" in message
	]
	if settings_errors:
		raise AssertionError(f"QSettings initialization failed: {settings_errors}")

	qml_errors = [
		message
		for message in qt_messages
		if "Unable to assign" in message or "ReferenceError" in message or "TypeError" in message
	]
	if qml_errors:
		raise AssertionError(f"QML runtime errors: {qml_errors}")

	print(
		"PASS V2-only touch UI: Victron return, six-page nav, gated commands, "
		"editable Cerbo favorites, exclusive invisible edge panels and read-only DWD weather"
	)
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
