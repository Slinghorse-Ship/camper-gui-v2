"""Render a V2-only CamperControl page or side panel with Qt 6."""

from __future__ import annotations

import os
from pathlib import Path
import sys

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
os.environ.setdefault("QSG_RHI_BACKEND", "software")
os.environ.setdefault("QT_QPA_FONTDIR", str(Path(__file__).resolve().parents[2] / "fonts"))

from PySide6.QtCore import QTimer, QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine


def main() -> int:
	qml_path = Path(__file__).with_name("Main.qml").resolve()
	output_path = Path(sys.argv[1] if len(sys.argv) > 1 else "camper-phase2.png").resolve()
	page = int(sys.argv[2]) if len(sys.argv) > 2 else 0
	energy_pane = int(sys.argv[3]) if len(sys.argv) > 3 else 0
	day_mode = bool(int(sys.argv[4])) if len(sys.argv) > 4 else False
	panel = int(sys.argv[5]) if len(sys.argv) > 5 else 0
	all_lights = bool(int(sys.argv[6])) if len(sys.argv) > 6 else False
	right_view = bool(int(sys.argv[7])) if len(sys.argv) > 7 else False
	output_path.parent.mkdir(parents=True, exist_ok=True)
	print(f"Loading {qml_path}", flush=True)

	app = QGuiApplication(sys.argv[:1])
	app.setOrganizationName("Victron Energy")
	app.setOrganizationDomain("victronenergy.com")
	app.setApplicationName("Venus")
	print("QGuiApplication ready", flush=True)
	engine = QQmlApplicationEngine()
	engine.load(QUrl.fromLocalFile(str(qml_path)))
	print(f"QML root objects: {len(engine.rootObjects())}", flush=True)
	if not engine.rootObjects():
		return 2

	window = engine.rootObjects()[0]
	window.setProperty("currentCamperPage", page)
	window.setProperty("previewV2EnergyPane", energy_pane)
	window.setProperty("previewV2DayMode", day_mode)
	window.setProperty("previewPanel", panel)
	window.setProperty("previewAllLightsOn", all_lights)
	window.setProperty("previewLightsRightView", right_view)

	def capture() -> None:
		print("Capturing frame", flush=True)
		pixmap = window.screen().grabWindow(window.winId())
		if pixmap.isNull() or not pixmap.save(str(output_path)):
			app.exit(3)
			return
		print(output_path)
		app.exit(0)

	QTimer.singleShot(750, capture)
	return app.exec()


if __name__ == "__main__":
	raise SystemExit(main())
