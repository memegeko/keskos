from __future__ import annotations

from PySide6.QtWidgets import QCheckBox, QComboBox, QFileDialog, QHBoxLayout, QLabel, QLineEdit, QSlider, QSpinBox, QWidget

from ..widgets import SettingsSection, StatusLabel, action_bar, populate_combo, select_combo_value, small_button
from .base import BasePage


class BootPage(BasePage):
    page_key = "boot"

    def __init__(self, controller) -> None:
        super().__init__(controller, "Boot & Login", "Change boot splash, quiet boot and login screen behavior.")
        self.backend = controller.backend
        self._build_ui()
        self.load_state()

    def _build_ui(self) -> None:
        status = SettingsSection("Backend status", "System-level boot and login changes are isolated behind a pkexec helper so the settings app itself stays unprivileged.")
        self.status_label = StatusLabel("Loading backend status", "work")
        status.add_row("Boot/login backend", "Current availability for privileged SDDM and Plymouth changes.", self.status_label, keywords="boot login backend status")
        self.add_section(status)

        info = SettingsSection("Detected system values", "Requires administrator permission for SDDM and Plymouth theme changes.")
        self.sddm_theme = QLabel()
        self.plymouth_theme = QLabel()
        self.reboot_status = QLabel()
        info.add_row("Current login theme", "Detected SDDM login theme from current system configuration.", self.sddm_theme, keywords="sddm login theme")
        info.add_row("Current boot splash", "Detected Plymouth boot theme from current system configuration.", self.plymouth_theme, keywords="plymouth boot splash")
        info.add_row("Reboot status", "Whether the system currently indicates a reboot is recommended.", self.reboot_status, keywords="reboot required")
        self.add_section(info)

        boot = SettingsSection("Boot splash", "Change boot splash, quiet boot and login screen behavior.")
        self.plymouth_selector = QComboBox()
        self.boot_splash_duration = QSpinBox()
        self.boot_splash_duration.setRange(0, 20)
        self.boot_splash_duration.setSuffix(" s")
        self.quiet_boot = QCheckBox("Enable quiet boot")
        self.show_logs = QCheckBox("Show boot logs")
        self.terminal_boot_text = QCheckBox("Show terminal-style boot text")
        boot.add_row("Plymouth theme", "Choose the KeskOS boot animation or another installed Plymouth theme.", self.plymouth_selector, keywords="plymouth theme boot splash")
        boot.add_row("Minimum splash duration", "Minimum time the splash remains visible before the session appears.", self.boot_splash_duration, keywords="minimum splash duration")
        boot.add_row("Quiet boot", "Hides most boot messages and shows the KeskOS splash instead.", self.quiet_boot, keywords="quiet boot")
        boot.add_row("Show boot logs", "Keep kernel and service messages visible during boot.", self.show_logs, keywords="boot logs")
        boot.add_row("Terminal-style boot text", "Prefer a terminal-like boot text presentation when supported.", self.terminal_boot_text, keywords="terminal style boot text")
        boot_docs = small_button("Open Boot Docs")
        boot_docs.clicked.connect(lambda: self.controller.open_url("https://docs.keskos.org"))
        repair_theme = small_button("Open Repair Theme Options")
        repair_theme.clicked.connect(lambda: self.controller.open_settings_page("kesk_theme"))
        boot.add_row(
            "Boot tools",
            "Plymouth changes may require initramfs rebuilds and a reboot.",
            action_bar(boot_docs, repair_theme),
            keywords="boot docs repair initramfs",
        )
        boot.add_note("System Plymouth changes go through the dedicated Kesk Settings helper and may rebuild initramfs.")
        self.add_section(boot)

        login = SettingsSection("Login screen", "Change the login screen theme and background.")
        self.sddm_selector = QComboBox()
        self.show_user_list = QCheckBox("Show user list on the login screen")
        self.login_background = QLineEdit()
        background_button = small_button("Choose File")
        background_button.clicked.connect(self.choose_background)
        background_host = QWidget()
        background_layout = QHBoxLayout(background_host)
        background_layout.setContentsMargins(0, 0, 0, 0)
        background_layout.setSpacing(8)
        background_layout.addWidget(self.login_background, 1)
        background_layout.addWidget(background_button)
        login.add_row("SDDM theme", "Choose the login theme shown before the desktop session starts.", self.sddm_selector, keywords="sddm theme login")
        login.add_row("Login background", "Pick a preferred background for future SDDM theme integration.", background_host, keywords="login background sddm")
        login.add_row("Show user list", "Show local users on the login screen.", self.show_user_list, keywords="show user list login")
        login_docs = small_button("Open Boot Docs")
        login_docs.clicked.connect(lambda: self.controller.open_url("https://docs.keskos.org"))
        login_theme = small_button("Open Repair Theme Options")
        login_theme.clicked.connect(lambda: self.controller.open_settings_page("kesk_theme"))
        login.add_row(
            "Login tools",
            "Login-screen theme changes affect the whole system and may require administrator permission.",
            action_bar(login_docs, login_theme),
            keywords="login tools sddm theme repair",
        )
        login.add_note("This affects the login screen and may require administrator permission.")
        self.add_section(login)

    def choose_background(self) -> None:
        path, _selected_filter = QFileDialog.getOpenFileName(
            self,
            "Choose Login Background",
            self.login_background.text() or str(self.controller.backend.paths.home / "Pictures"),
            "Images (*.png *.jpg *.jpeg *.webp *.bmp *.svg)",
        )
        if path:
            self.login_background.setText(path)

    def load_state(self) -> None:
        self.begin_refresh()
        state = self.backend.boot_state()
        self.status_label.set_status(state["status"].summary, state["status"].ui_kind)
        populate_combo(self.sddm_selector, self.backend.ensure_choice(str(state["sddm_theme"]), self.backend.sddm_theme_options()))
        populate_combo(self.plymouth_selector, self.backend.ensure_choice(str(state["plymouth_theme"]), self.backend.plymouth_theme_options()))
        select_combo_value(self.sddm_selector, str(state["sddm_theme"]))
        select_combo_value(self.plymouth_selector, str(state["plymouth_theme"]))
        self.sddm_theme.setText(str(state["sddm_theme"]))
        self.plymouth_theme.setText(str(state["plymouth_theme"]))
        self.reboot_status.setText("Reboot recommended" if state.get("reboot_required") else "No reboot required")
        self.boot_splash_duration.setValue(int(state["boot_splash_min_duration"]))
        self.show_logs.setChecked(bool(state["show_boot_logs"]))
        self.quiet_boot.setChecked(bool(state["quiet_boot"]))
        self.show_user_list.setChecked(bool(state.get("show_user_list", True)))
        self.terminal_boot_text.setChecked(bool(state.get("terminal_boot_text", False)))
        self.login_background.setText(str(state["login_background"]))
        privileged_available = state["status"].code in {"requires_admin", "connected"}
        self.sddm_selector.setEnabled(privileged_available and self.sddm_selector.count() > 0)
        self.plymouth_selector.setEnabled(privileged_available and self.plymouth_selector.count() > 0)
        self.finish_refresh()

    def apply_changes(self) -> None:
        values = {
            "sddm_theme": self.sddm_selector.currentData(),
            "plymouth_theme": self.plymouth_selector.currentData(),
            "boot_splash_min_duration": self.boot_splash_duration.value(),
            "show_boot_logs": self.show_logs.isChecked(),
            "quiet_boot": self.quiet_boot.isChecked(),
            "show_user_list": self.show_user_list.isChecked(),
            "terminal_boot_text": self.terminal_boot_text.isChecked(),
            "login_background": self.login_background.text().strip(),
        }
        result = self.backend.apply_boot(values)
        self.show_result(result, "Boot & Login")
        self.load_state()

    def on_activated(self) -> None:
        self.load_state()
