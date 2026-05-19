from __future__ import annotations

from PySide6.QtCore import Qt
from PySide6.QtGui import QColor, QFontDatabase
from PySide6.QtWidgets import QCheckBox, QColorDialog, QComboBox, QLabel, QPushButton, QHBoxLayout, QSlider, QWidget

from ..widgets import SettingsSection, action_bar, populate_combo, select_combo_value, small_button
from .base import BasePage


class KeskPage(BasePage):
    page_key = "kesk"

    def __init__(self, controller) -> None:
        super().__init__(controller, "KeskOS Theme", "Change KeskOS-specific theme behavior and visual effects.")
        self.backend = controller.backend
        self._build_ui()
        self.load_state()

    def _build_ui(self) -> None:
        theme = SettingsSection("KeskOS Theme", "Change KeskOS-specific theme behavior and visual effects.")
        self.theme_mode = QComboBox()
        populate_combo(
            self.theme_mode,
            [("full", "Full KeskOS"), ("minimal", "Minimal KeskOS"), ("kde_fallback", "KDE fallback")],
        )
        self.accent_value = QLabel()
        self.accent_value.setMinimumWidth(96)
        self.accent_value.setAlignment(Qt.AlignmentFlag.AlignCenter)
        accent_button = QPushButton("Choose Accent")
        accent_button.clicked.connect(self.choose_accent)
        accent_host = QWidget()
        accent_layout = QHBoxLayout(accent_host)
        accent_layout.setContentsMargins(0, 0, 0, 0)
        accent_layout.setSpacing(8)
        accent_layout.addWidget(self.accent_value)
        accent_layout.addWidget(accent_button)

        self.crt = QCheckBox("Enable CRT effects")
        self.scanlines = QCheckBox("Enable scanlines")
        self.glow = QSlider(Qt.Orientation.Horizontal)
        self.glow.setRange(0, 100)
        self.glow_caption = QLabel("70%")
        self.glow_caption.setMinimumWidth(56)
        self.glow.valueChanged.connect(lambda value: self.glow_caption.setText(f"{value}%"))
        self.terminal_font = QComboBox()
        self.terminal_font.setEditable(True)
        self.terminal_font.addItems(sorted(QFontDatabase().families()))
        self.prompt_style = QComboBox()
        populate_combo(self.prompt_style, [("keskos", "KeskOS Prompt"), ("minimal", "Minimal Prompt")])
        apply_theme = small_button("Apply Full KeskOS Theme")
        apply_theme.clicked.connect(self.apply_kesk_defaults)

        theme.add_row("KeskOS theme mode", "Switch between full KeskOS, minimal branded, and KDE-fallback modes.", self.theme_mode, keywords="keskos theme mode full minimal fallback")
        theme.add_row("Accent color", "Primary branded accent used by supported KeskOS surfaces.", accent_host, keywords="keskos accent color orange")
        theme.add_row("CRT effects", "Enable CRT-style shading for supported branded interfaces.", self.crt, keywords="crt effects")
        theme.add_row("Scanlines", "Enable scanline overlays for supported branded interfaces.", self.scanlines, keywords="scanlines")
        theme.add_row("Glow intensity", "Adjust how strong the orange glow should appear.", self.glow, self.glow_caption, keywords="glow intensity")
        theme.add_row("Terminal font", "Choose the preferred monospace font for branded terminal surfaces.", self.terminal_font, keywords="terminal font monospace")
        theme.add_row("Prompt style", "Choose the branded shell prompt overlay.", self.prompt_style, keywords="prompt style terminal")
        theme.add_row("Apply full KeskOS theme", "Reapply the official branded color, shell, and wallpaper defaults.", apply_theme, keywords="apply full keskos theme")
        theme.add_note("Changing the full branded theme may require logging out before every shell surface refreshes.")
        self.add_section(theme)

        browser = SettingsSection("Browser Defaults", "Choose default browser and KeskOS browser homepage behavior.")
        self.browser_homepage = QCheckBox("Enable the KeskOS homepage")
        self.telemetry = QCheckBox("Enable telemetry")
        self.local_analytics = QCheckBox("Enable local analytics dashboard")
        browser.add_row("KeskOS homepage", "Apply the branded start page to supported browsers.", self.browser_homepage, keywords="browser homepage")
        browser.add_row("Telemetry", "Reserved toggle for future privacy-reviewed telemetry.", self.telemetry, keywords="telemetry")
        browser.add_row("Local analytics dashboard", "Reserved toggle for future local-only analytics surfaces.", self.local_analytics, keywords="analytics local")
        self.add_section(browser)

        experimental = SettingsSection("Experimental Features", "Try unfinished KeskOS features. These may be unstable.")
        self.experimental = QCheckBox("Enable experimental features")
        self.quickshell_experimental = QCheckBox("Enable Quickshell experimental mode")
        self.new_launcher_backend = QCheckBox("Enable new launcher backend")
        self.new_settings_backend = QCheckBox("Enable new settings backend")
        self.debug_overlays = QCheckBox("Enable debug UI overlays")
        self.first_run_completed = QCheckBox("First boot welcome already completed")

        experimental.add_row("Experimental features", "Master switch for unfinished KeskOS features.", self.experimental, keywords="experimental features")
        experimental.add_row("Quickshell experimental mode", "Opt in to unfinished Quickshell shell behavior.", self.quickshell_experimental, keywords="quickshell experimental")
        experimental.add_row("New launcher backend", "Use the next-generation launcher path when available.", self.new_launcher_backend, keywords="new launcher backend")
        experimental.add_row("New settings backend", "Use the next-generation settings backend path when available.", self.new_settings_backend, keywords="new settings backend")
        experimental.add_row("Debug UI overlays", "Show developer-oriented layout overlays in supported builds.", self.debug_overlays, keywords="debug overlays")
        experimental.add_row("First boot state", "Mark the future welcome flow complete or reset it.", self.first_run_completed, keywords="first boot welcome state")
        experimental.add_note("Experimental features may break or change.")
        self.add_section(experimental)

    def _set_accent(self, value: str) -> None:
        color = QColor(value)
        if not color.isValid():
            color = QColor("#ce6a35")
        text_color = "#111111" if color.lightness() > 140 else "#f4efe8"
        self.accent_value.setText(color.name().upper())
        self.accent_value.setStyleSheet(f"background-color: {color.name()}; color: {text_color}; border: 1px solid #ce6a35; padding: 6px;")

    def choose_accent(self) -> None:
        color = QColorDialog.getColor(QColor(self.accent_value.text() or "#ce6a35"), self, "Choose KeskOS Accent")
        if color.isValid():
            self._set_accent(color.name())

    def apply_kesk_defaults(self) -> None:
        result = self.backend.apply_kesk_appearance_defaults()
        self.show_result(result, "KeskOS Theme")

    def load_state(self) -> None:
        self.begin_refresh()
        state = self.backend.kesk_state()
        select_combo_value(self.theme_mode, str(state["kesk_theme_mode"]))
        self._set_accent(str(state["accent_color"]))
        self.crt.setChecked(bool(state["crt_effects"]))
        self.scanlines.setChecked(bool(state["scanlines"]))
        self.glow.setValue(int(state["glow_intensity"]))
        self.glow_caption.setText(f"{int(state['glow_intensity'])}%")
        index = self.terminal_font.findText(str(state["terminal_font"]))
        if index >= 0:
            self.terminal_font.setCurrentIndex(index)
        else:
            self.terminal_font.setEditText(str(state["terminal_font"]))
        select_combo_value(self.prompt_style, str(state["prompt_style"]))
        self.browser_homepage.setChecked(bool(state["browser_homepage_enabled"]))
        self.first_run_completed.setChecked(bool(state["first_run_completed"]))
        self.telemetry.setChecked(bool(state["telemetry_enabled"]))
        self.local_analytics.setChecked(bool(state["local_analytics_dashboard"]))
        self.experimental.setChecked(bool(state["experimental_features"]))
        self.quickshell_experimental.setChecked(bool(state["quickshell_experimental_mode"]))
        self.new_launcher_backend.setChecked(bool(state["new_launcher_backend"]))
        self.new_settings_backend.setChecked(bool(state["new_settings_backend"]))
        self.debug_overlays.setChecked(bool(state["debug_ui_overlays"]))
        self.finish_refresh()

    def apply_changes(self) -> None:
        default_browser = self.controller.backend.default_browser_id()
        values = {
            "accent_color": self.accent_value.text().strip(),
            "kesk_theme_mode": self.theme_mode.currentData(),
            "crt_effects": self.crt.isChecked(),
            "scanlines": self.scanlines.isChecked(),
            "glow_intensity": self.glow.value(),
            "terminal_font": self.terminal_font.currentText().strip(),
            "prompt_style": self.prompt_style.currentData(),
            "browser_homepage_enabled": self.browser_homepage.isChecked(),
            "first_run_completed": self.first_run_completed.isChecked(),
            "telemetry_enabled": self.telemetry.isChecked(),
            "local_analytics_dashboard": self.local_analytics.isChecked(),
            "experimental_features": self.experimental.isChecked(),
            "quickshell_experimental_mode": self.quickshell_experimental.isChecked(),
            "new_launcher_backend": self.new_launcher_backend.isChecked(),
            "new_settings_backend": self.new_settings_backend.isChecked(),
            "debug_ui_overlays": self.debug_overlays.isChecked(),
        }
        result = self.backend.apply_kesk(values, default_browser)
        self.show_result(result, "KeskOS Theme")
        self.load_state()

    def on_activated(self) -> None:
        self.load_state()
