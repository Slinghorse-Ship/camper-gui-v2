"""Render the Phase-2 Camper Home with Qt 6 for visual regression checks."""

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
	output_path.parent.mkdir(parents=True, exist_ok=True)
	print(f"Loading {qml_path}", flush=True)

	app = QGuiApplication(sys.argv[:1])
	print("QGuiApplication ready", flush=True)
	engine = QQmlApplicationEngine()
	engine.load(QUrl.fromLocalFile(str(qml_path)))
	print(f"QML root objects: {len(engine.rootObjects())}", flush=True)
	if not engine.rootObjects():
		return 2

	window = engine.rootObjects()[0]
	window.setProperty("currentCamperPage", page)

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
