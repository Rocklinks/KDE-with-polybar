#!/usr/bin/env python3
import sys
import os
import darkdetect
from PyQt5 import QtWidgets, QtGui, QtCore

def get_battery_status():
    base = "/sys/class/power_supply/BAT0"
    try:
        with open(os.path.join(base, "capacity")) as f:
            percent = int(f.read().strip())
        with open(os.path.join(base, "status")) as f:
            status = f.read().strip()
        return percent, status
    except Exception:
        return None, None

def battery_icon(percent, charging):
    if charging:
        return "🔌"
    elif percent >= 90:
        return "🔋"
    elif percent >= 60:
        return "🔋"
    elif percent >= 30:
        return "🔋"
    elif percent >= 10:
        return "🔋"
    else:
        return "🪫"

def get_text_color():
    # Use darkdetect to choose color for visibility
    if darkdetect.isDark():
        return QtCore.Qt.white
    else:
        return QtCore.Qt.black

class BatteryTray(QtWidgets.QSystemTrayIcon):
    def __init__(self, app):
        super().__init__()
        self.app = app
        self.setToolTip("Battery Monitor")
        self.menu = QtWidgets.QMenu()
        quit_action = self.menu.addAction("Quit")
        quit_action.triggered.connect(app.quit)
        self.setContextMenu(self.menu)
        self.timer = QtCore.QTimer()
        self.timer.timeout.connect(self.update_icon)
        self.timer.start(60 * 1000)
        self.update_icon()
        self.show()

    def update_icon(self):
        percent, status = get_battery_status()
        if percent is None:
            self.setIcon(QtGui.QIcon())
            self.setToolTip("No battery found")
            return
        charging = (status == "Charging")
        icon_text = f"{battery_icon(percent, charging)} {percent}%"
        pixmap = QtGui.QPixmap(64, 64)
        pixmap.fill(QtCore.Qt.transparent)
        painter = QtGui.QPainter(pixmap)
        font = QtGui.QFont("Arial", 32)
        painter.setFont(font)
        painter.setPen(get_text_color())
        painter.drawText(pixmap.rect(), QtCore.Qt.AlignCenter, icon_text)
        painter.end()
        icon = QtGui.QIcon(pixmap)
        self.setIcon(icon)
        self.setToolTip(f"Battery: {percent}%")

if __name__ == "__main__":
    app = QtWidgets.QApplication(sys.argv)
    tray = BatteryTray(app)
    sys.exit(app.exec_())

