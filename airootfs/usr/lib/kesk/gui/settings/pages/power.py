from __future__ import annotations

from PySide6.QtWidgets import QCheckBox, QComboBox, QSpinBox

from ..backend import POWER_PROFILES
from ..widgets import SettingsSection, action_bar, populate_combo, select_combo_value, small_button
from .base import BasePage


class PowerPage(BasePage):
    page_key = "power"

    def __init__(self, controller) -> None:
        super().__init__(controller, "Power Management", "Change power usage, sleep behavior and battery options.")
        self.backend = controller.backend
        self._build_ui()
        self.load_state()

    def _build_ui(self) -> None:
        section = SettingsSection("Power profile", "Change power usage, sleep behavior and battery options.")
        self.profile = QComboBox()
        populate_combo(self.profile, [(value, value.replace("-", " ").title()) for value in POWER_PROFILES])
        self.blank_timeout = QSpinBox()
        self.blank_timeout.setRange(1, 240)
        self.blank_timeout.setSuffix(" min")
        self.sleep_timeout = QSpinBox()
        self.sleep_timeout.setRange(1, 480)
        self.sleep_timeout.setSuffix(" min")
        self.lid_action = QComboBox()
        populate_combo(self.lid_action, [("sleep", "Sleep"), ("hibernate", "Hibernate"), ("lock", "Lock Screen"), ("nothing", "Do nothing")])
        self.dim_screen = QCheckBox("Dim screen on battery")
        self.battery_percent = QCheckBox("Show battery percentage")
        self.low_battery_action = QComboBox()
        populate_combo(self.low_battery_action, [("suspend", "Suspend"), ("hibernate", "Hibernate"), ("shutdown", "Shut down"), ("nothing", "Do nothing")])

        section.add_row("Power profile", "Use power-profiles-daemon if available.", self.profile, keywords="power profile performance balanced saver")
        section.add_row("Screen blank timeout", "Screen blank timeout in minutes.", self.blank_timeout, keywords="screen blank timeout")
        section.add_row("Sleep timeout", "How long the system waits before sleeping.", self.sleep_timeout, keywords="sleep timeout suspend")
        section.add_row("Lid close action", "Choose what happens when the laptop lid is closed.", self.lid_action, keywords="lid close action laptop")
        section.add_row("Dim screen", "Dim the display before sleeping or on battery when supported.", self.dim_screen, keywords="dim screen battery")
        section.add_row("Battery percentage", "Show battery percentage in branded surfaces and future widgets.", self.battery_percent, keywords="battery percentage")
        section.add_row("Low battery action", "Choose what happens when the battery gets critically low.", self.low_battery_action, keywords="low battery action")
        self.add_section(section)

        advanced = SettingsSection("Advanced power settings")
        open_power = small_button("Open Advanced Power Settings")
        open_power.clicked.connect(lambda: self.controller.open_kcm("kcm_powerdevilglobalconfig"))
        advanced.add_widget(action_bar(open_power), keywords="advanced power battery sleep")
        self.add_section(advanced)

    def load_state(self) -> None:
        self.begin_refresh()
        state = self.backend.power_state()
        select_combo_value(self.profile, str(state["profile"]))
        self.blank_timeout.setValue(int(state["blank_timeout"]))
        self.sleep_timeout.setValue(int(state["sleep_timeout"]))
        select_combo_value(self.lid_action, str(state["lid_action"]))
        self.dim_screen.setChecked(bool(state["dim_screen"]))
        self.battery_percent.setChecked(bool(state["show_battery_percent"]))
        select_combo_value(self.low_battery_action, str(state["low_battery_action"]))
        self.finish_refresh()

    def apply_changes(self) -> None:
        values = {
            "profile": self.profile.currentData(),
            "blank_timeout": self.blank_timeout.value(),
            "sleep_timeout": self.sleep_timeout.value(),
            "show_battery_percent": self.battery_percent.isChecked(),
            "lid_action": self.lid_action.currentData(),
            "dim_screen": self.dim_screen.isChecked(),
            "low_battery_action": self.low_battery_action.currentData(),
        }
        result = self.backend.apply_power(values)
        self.show_result(result, "Power Management")
        self.load_state()

    def on_activated(self) -> None:
        self.load_state()
