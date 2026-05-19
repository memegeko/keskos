from __future__ import annotations

from PySide6.QtCore import Qt
from PySide6.QtWidgets import QCheckBox, QComboBox, QLabel, QSlider, QSpinBox

from ..widgets import SettingsSection, action_bar, populate_combo, select_combo_value, small_button
from .base import BasePage


class InputPage(BasePage):
    page_key = "input"

    def __init__(self, controller) -> None:
        super().__init__(controller, "Input", "Adjust pointer speed, scrolling, clicks, keyboard layout, and typing behavior.")
        self.backend = controller.backend
        self._build_ui()
        self.load_state()

    def _build_ui(self) -> None:
        pointer = SettingsSection("Mouse & Touchpad", "Adjust pointer speed, scrolling, clicks and touchpad gestures.")
        self.mouse_speed = QSlider(Qt.Orientation.Horizontal)
        self.mouse_speed.setRange(0, 100)
        self.mouse_speed_caption = QLabel("50%")
        self.mouse_speed_caption.setMinimumWidth(56)
        self.mouse_speed.valueChanged.connect(lambda value: self.mouse_speed_caption.setText(f"{value}%"))
        self.acceleration_profile = QComboBox()
        populate_combo(self.acceleration_profile, [("adaptive", "Adaptive"), ("flat", "Flat")])
        self.tap_to_click = QCheckBox("Enabled")
        self.natural_scroll = QCheckBox("Enabled")
        self.two_finger_scroll = QCheckBox("Enabled")
        self.right_click_method = QComboBox()
        populate_combo(
            self.right_click_method,
            [("two_finger", "Two-finger tap"), ("bottom_right", "Bottom-right corner")],
        )
        self.disable_while_typing = QCheckBox("Enabled")

        pointer.add_row(
            "Pointer speed",
            "Controls how fast the pointer moves across the screen.",
            self.mouse_speed,
            self.mouse_speed_caption,
            keywords="pointer speed mouse speed touchpad",
        )
        pointer.add_row(
            "Acceleration profile",
            "Choose whether pointer movement adapts to speed or stays linear.",
            self.acceleration_profile,
            keywords="acceleration profile adaptive flat",
        )
        pointer.add_row(
            "Natural scrolling",
            "Reverse scroll direction to follow touchscreen-style movement.",
            self.natural_scroll,
            keywords="natural scrolling touchpad mouse wheel",
        )
        pointer.add_row(
            "Tap-to-click",
            "Tap the touchpad instead of pressing it to click.",
            self.tap_to_click,
            keywords="tap to click touchpad",
        )
        pointer.add_row(
            "Two-finger scrolling",
            "Scroll with two fingers on touchpads that support it.",
            self.two_finger_scroll,
            keywords="two finger scrolling touchpad",
        )
        pointer.add_row(
            "Right-click method",
            "Choose how a secondary click is triggered on the touchpad.",
            self.right_click_method,
            keywords="right click touchpad two finger bottom right",
        )
        pointer.add_row(
            "Disable touchpad while typing",
            "Reduce accidental cursor jumps while entering text.",
            self.disable_while_typing,
            keywords="disable touchpad while typing palm rejection",
        )
        pointer.add_note("These options will use KDE input settings when fully connected.")
        self.add_section(pointer)

        keyboard = SettingsSection("Keyboard", "Change keyboard layout, repeat speed and typing behavior.")
        self.keyboard_layout = QComboBox()
        self.keyboard_layout.setEditable(True)
        self.keyboard_layout.addItems(["us", "gb", "de", "fr", "nl", "fi", "se"])
        self.repeat_enabled = QCheckBox("Enabled")
        self.repeat_delay = QSpinBox()
        self.repeat_delay.setRange(100, 2000)
        self.repeat_delay.setSuffix(" ms")
        self.repeat_rate = QSpinBox()
        self.repeat_rate.setRange(1, 60)
        self.repeat_rate.setSuffix(" cps")
        self.numlock_startup = QComboBox()
        populate_combo(
            self.numlock_startup,
            [("on", "On"), ("off", "Off"), ("unchanged", "Leave unchanged")],
        )
        self.compose_key = QComboBox()
        populate_combo(
            self.compose_key,
            [
                ("Disabled", "Disabled"),
                ("Right Alt", "Right Alt"),
                ("Menu", "Menu"),
                ("Caps Lock", "Caps Lock"),
            ],
        )

        add_layout = small_button("Add Layout")
        add_layout.clicked.connect(lambda: self.controller.open_kcm("kcm_keyboard"))
        advanced_keyboard = small_button("Open Advanced Keyboard Settings")
        advanced_keyboard.clicked.connect(lambda: self.controller.open_kcm("kcm_keyboard"))

        keyboard.add_row(
            "Keyboard layout",
            "Primary keyboard layout written to KDE user config.",
            self.keyboard_layout,
            add_layout,
            keywords="keyboard layout xkb add layout",
        )
        keyboard.add_row(
            "Repeat keys",
            "Allow keys to repeat when held down.",
            self.repeat_enabled,
            keywords="repeat keys keyboard",
        )
        keyboard.add_row(
            "Repeat delay",
            "Delay before a held key starts repeating.",
            self.repeat_delay,
            keywords="repeat delay typing",
        )
        keyboard.add_row(
            "Repeat rate",
            "How quickly a held key repeats after the delay.",
            self.repeat_rate,
            keywords="repeat rate typing",
        )
        keyboard.add_row(
            "NumLock on startup",
            "Choose the preferred NumLock state when the session starts.",
            self.numlock_startup,
            keywords="numlock startup boot login",
        )
        keyboard.add_row(
            "Compose key",
            "Choose a key to enter special composed characters.",
            self.compose_key,
            keywords="compose key special characters",
        )
        keyboard.add_row(
            "Advanced keyboard settings",
            "Open KDE's keyboard module for layout variants, shortcuts, and extra typing options.",
            advanced_keyboard,
            keywords="advanced keyboard settings",
        )
        self.add_section(keyboard)

    def load_state(self) -> None:
        self.begin_refresh()
        state = self.backend.input_state()
        self.keyboard_layout.setCurrentText(str(state["keyboard_layout"]))
        self.repeat_enabled.setChecked(bool(state["repeat_enabled"]))
        self.repeat_delay.setValue(int(state["repeat_delay"]))
        self.repeat_rate.setValue(int(state["repeat_rate"]))
        self.tap_to_click.setChecked(bool(state["tap_to_click"]))
        self.natural_scroll.setChecked(bool(state["natural_scroll"]))
        self.two_finger_scroll.setChecked(bool(state["two_finger_scroll"]))
        self.disable_while_typing.setChecked(bool(state["disable_while_typing"]))
        self.mouse_speed.setValue(int(state["mouse_speed"]))
        self.mouse_speed_caption.setText(f"{int(state['mouse_speed'])}%")
        select_combo_value(self.acceleration_profile, str(state["acceleration_profile"]))
        select_combo_value(self.right_click_method, str(state["right_click_method"]))
        select_combo_value(self.numlock_startup, str(state["numlock_startup"]))
        select_combo_value(self.compose_key, str(state["compose_key"]))
        self.finish_refresh()

    def apply_changes(self) -> None:
        values = {
            "keyboard_layout": self.keyboard_layout.currentText().strip() or "us",
            "repeat_enabled": self.repeat_enabled.isChecked(),
            "repeat_delay": self.repeat_delay.value(),
            "repeat_rate": self.repeat_rate.value(),
            "tap_to_click": self.tap_to_click.isChecked(),
            "natural_scroll": self.natural_scroll.isChecked(),
            "two_finger_scroll": self.two_finger_scroll.isChecked(),
            "disable_while_typing": self.disable_while_typing.isChecked(),
            "mouse_speed": self.mouse_speed.value(),
            "acceleration_profile": self.acceleration_profile.currentData(),
            "right_click_method": self.right_click_method.currentData(),
            "numlock_startup": self.numlock_startup.currentData(),
            "compose_key": self.compose_key.currentData(),
        }
        result = self.backend.apply_input(values)
        self.show_result(result, "Input")
        self.load_state()

    def on_activated(self) -> None:
        self.load_state()
