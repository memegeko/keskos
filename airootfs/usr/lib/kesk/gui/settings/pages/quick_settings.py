from __future__ import annotations

from PySide6.QtCore import Qt
from PySide6.QtWidgets import QButtonGroup, QGridLayout, QLabel, QPushButton, QRadioButton, QSlider, QVBoxLayout, QWidget

from ..widgets import SettingsSection, action_bar, small_button
from .base import BasePage


THEME_PRESETS = (
    ("breeze", "BREEZE", "Default Plasma light appearance."),
    ("breeze_dark", "BREEZE DARK", "Dark Breeze palette with neutral accents."),
    ("automatic", "AUTOMATIC", "Plasma-scheduled theme switching when available."),
    ("keskos_dark", "KESKOS DARK", "Official KeskOS shell styling and wallpaper."),
)


class QuickSettingsPage(BasePage):
    page_key = "quick_settings"

    def __init__(self, controller) -> None:
        super().__init__(controller, "Quick Settings", "Common appearance and workspace controls with a Plasma-style quick settings layout.")
        self.backend = controller.backend
        self.theme_buttons: dict[str, QPushButton] = {}
        self._build_ui()
        self.load_state()

    def _build_ui(self) -> None:
        appearance = SettingsSection("Theme", "Fast access to the most common Plasma and KeskOS appearance presets.")
        preview_host = QWidget()
        preview_layout = QGridLayout(preview_host)
        preview_layout.setContentsMargins(0, 0, 0, 0)
        preview_layout.setHorizontalSpacing(10)
        preview_layout.setVerticalSpacing(10)

        self.theme_group = QButtonGroup(self)
        self.theme_group.setExclusive(True)
        for index, (value, label, body) in enumerate(THEME_PRESETS):
            button = QPushButton(f"{label}\n{body}")
            button.setObjectName("ThemeCard")
            button.setCheckable(True)
            button.setCursor(Qt.CursorShape.PointingHandCursor)
            button.setToolTip(body)
            preview_layout.addWidget(button, index // 2, index % 2)
            self.theme_group.addButton(button)
            self.theme_buttons[value] = button

        appearance.add_widget(preview_host, keywords="theme preview breeze dark automatic keskos")

        wallpaper_button = small_button("Wallpaper")
        wallpaper_button.clicked.connect(lambda: self.controller.open_settings_page("wallpaper"))
        global_theme_button = small_button("Global Theme")
        global_theme_button.clicked.connect(lambda: self.controller.open_settings_page("colors_themes"))
        colors_button = small_button("Colors & Themes")
        colors_button.clicked.connect(lambda: self.controller.open_settings_page("colors_themes"))
        appearance.add_row(
            "More appearance settings",
            "Open the detailed appearance pages for wallpapers, themes, and palette changes.",
            action_bar(wallpaper_button, global_theme_button, colors_button),
            keywords="wallpaper global theme colors themes appearance",
        )
        self.add_section(appearance)

        behavior = SettingsSection("Behavior", "Desktop motion and file-click defaults that people usually expect in the first settings screen.")
        self.animation_speed = QSlider(Qt.Orientation.Horizontal)
        self.animation_speed.setRange(0, 200)
        self.animation_caption = QLabel("1.00x")
        self.animation_caption.setMinimumWidth(72)
        self.animation_speed.valueChanged.connect(self._sync_animation_caption)
        behavior.add_row(
            "Animation speed",
            "Move from slow transitions to instant responses. This writes KDE's animation duration factor.",
            self.animation_speed,
            self.animation_caption,
            keywords="animation speed instant slow windows plasma",
        )

        self.selects_radio = QRadioButton("Selects them")
        self.opens_radio = QRadioButton("Opens them")
        behavior.add_row(
            "Clicking files or folders",
            "Open by double-clicking instead. This keeps single-click in selection mode.",
            self.selects_radio,
            keywords="click files folders select double click single click",
        )
        behavior.add_row(
            "Open on single click",
            "Select by clicking on the item's selection marker instead of the main file body.",
            self.opens_radio,
            keywords="single click open files folders",
        )

        behavior_button = small_button("General Behavior")
        behavior_button.clicked.connect(lambda: self.controller.open_kcm("kcm_workspace"))
        behavior.add_row(
            "More behavior settings",
            "Open KDE's deeper workspace behavior module for advanced interaction settings.",
            behavior_button,
            keywords="workspace behavior advanced settings",
        )
        self.add_section(behavior)

    def _selected_theme(self) -> str:
        for value, button in self.theme_buttons.items():
            if button.isChecked():
                return value
        return "automatic"

    def _sync_animation_caption(self) -> None:
        factor = self.animation_speed.value() / 100
        if factor <= 0:
            self.animation_caption.setText("INSTANT")
        else:
            self.animation_caption.setText(f"{factor:.2f}x")

    def load_state(self) -> None:
        self.begin_refresh()
        state = self.backend.quick_settings_state()
        for value, button in self.theme_buttons.items():
            button.setChecked(value == state["theme_preset"])
        self.animation_speed.setValue(int(float(state["animation_speed"]) * 100))
        self._sync_animation_caption()
        if bool(state["single_click"]):
            self.opens_radio.setChecked(True)
        else:
            self.selects_radio.setChecked(True)
        self.finish_refresh()

    def apply_changes(self) -> None:
        values = {
            "theme_preset": self._selected_theme(),
            "animation_speed": self.animation_speed.value() / 100,
            "single_click": self.opens_radio.isChecked(),
        }
        result = self.backend.apply_quick_settings(values)
        self.show_result(result, "Quick Settings")
        self.load_state()

    def on_activated(self) -> None:
        self.load_state()
