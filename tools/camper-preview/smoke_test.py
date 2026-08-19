"""Touch smoke test for the 800x480 Camper Home preview."""

from __future__ import annotations

import os
from pathlib import Path
import sys

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
os.environ.setdefault("QSG_RHI_BACKEND", "software")
os.environ.setdefault("QT_QPA_FONTDIR", str(Path(__file__).resolve().parents[2] / "fonts"))

from PySide6.QtCore import QPoint, Qt, QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtTest import QTest


def expect(window, name: str, expected: int) -> None:
	actual = window.property(name)
	if actual != expected:
		raise AssertionError(f"{name}: expected {expected}, got {actual}")


def click(window, x: int, y: int) -> None:
	QTest.mouseClick(window, Qt.LeftButton, Qt.NoModifier, QPoint(x, y), 20)
	QGuiApplication.processEvents()


def main() -> int:
	app = QGuiApplication(sys.argv[:1])
	engine = QQmlApplicationEngine()
	qml_path = Path(__file__).with_name("Main.qml").resolve()
	engine.load(QUrl.fromLocalFile(str(qml_path)))
	if not engine.rootObjects():
		return 2

	window = engine.rootObjects()[0]
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

	print("PASS touch targets: settings, close, HOME, LICHT, 12/230")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
