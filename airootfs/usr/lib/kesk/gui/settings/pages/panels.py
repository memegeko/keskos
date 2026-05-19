from __future__ import annotations

from PySide6.QtCore import Qt
from PySide6.QtWidgets import QCheckBox, QComboBox, QLabel, QSlider

from ..widgets import SettingsSection, action_bar, planned_button, populate_combo, select_combo_value, small_button
from .base import BasePage


class PanelsPage(BasePage):
    page_key = "panels"

    def __init__(self, controller) -> None:
        super().__init__(controller, "Panels & Launcher", "Change KeskOS panels, launcher and workspace controls.")
        self.backend = controller.backend
        self._build_ui()
        self.load_state()

    def _build_ui(self) -> None:
        launcher_section = SettingsSection("Panels & launcher", "Change KeskOS panels, launcher and workspace controls.")
        self.panel_mode = QComboBox()
        populate_combo(
            self.panel_mode,
            [
                ("kesk_panel", "KDE branded panels"),
                ("quickshell_hud", "Quickshell HUD"),
                ("kde_default", "KDE default fallback"),
            ],
        )
        self.top_panel = QCheckBox("Enable top panel")
        self.bottom_panel = QCheckBox("Enable bottom panel")
        self.auto_hide = QCheckBox("Auto-hide bottom panel")
        self.workspace_switcher = QCheckBox("Show workspace switcher")
        self.launcher_enabled = QCheckBox("Enable Kesk launcher")
        self.launcher_style = QComboBox()
        populate_combo(self.launcher_style, [("keskos", "KeskOS launcher"), ("kde", "KDE fallback launcher")])
        self.launcher_keybind = QComboBox()
        populate_combo(self.launcher_keybind, [("Meta", "Meta"), ("Meta+Q", "Meta+Q"), ("Meta+Space", "Meta+Space")])
        self.opacity = QSlider(Qt.Orientation.Horizontal)
        self.opacity.setRange(0, 100)
        self.glow = QSlider(Qt.Orientation.Horizontal)
        self.glow.setRange(0, 100)

        launcher_section.add_row("Panel mode", "Switch between stable KDE panels and the cinematic KeskOS HUD.", self.panel_mode, keywords="panel mode quickshell kde")
        launcher_section.add_row("Top panel", "Show or hide the top panel.", self.top_panel, keywords="top panel")
        launcher_section.add_row("Bottom panel", "Show or hide the bottom taskbar.", self.bottom_panel, keywords="bottom panel taskbar")
        launcher_section.add_row("Auto-hide", "Automatically hide the bottom taskbar.", self.auto_hide, keywords="auto hide panel")
        launcher_section.add_row("Panel opacity", "Preferred opacity for compatible panels.", self.opacity, keywords="panel opacity")
        launcher_section.add_row("Panel glow", "Preferred glow level for compatible panels.", self.glow, keywords="panel glow")
        launcher_section.add_row("Workspace switcher", "Show the workspace switcher in compatible panel layouts.", self.workspace_switcher, keywords="workspace switcher")
        launcher_section.add_row("Kesk launcher", "Enable or disable the branded application launcher.", self.launcher_enabled, keywords="kesk launcher enable")
        launcher_section.add_row("Launcher style", "Switch between the branded launcher and the KDE fallback.", self.launcher_style, keywords="launcher style")
        launcher_section.add_row("Launcher shortcut", "Shortcut used to open the launcher.", self.launcher_keybind, keywords="launcher keybind meta shortcut")
        reset_layout = small_button("Reset Panel Layout")
        reset_layout.clicked.connect(self._stage_reset_layout)
        launcher_section.add_row("Panel layout", "Restore the official branded panel layout on the next Apply.", reset_layout, keywords="reset panel layout")
        self.add_section(launcher_section)

        hud_section = SettingsSection("HUD / Widgets", "Enable or disable KeskOS desktop HUD widgets.")
        self.quickshell_status = QLabel()
        self.hud_enabled = QCheckBox("Enable HUD widgets")
        self.hud_cpu = QCheckBox("CPU widget")
        self.hud_memory = QCheckBox("Memory widget")
        self.hud_network = QCheckBox("Network widget")
        self.hud_media = QCheckBox("Media widget")
        self.hud_clock = QCheckBox("Clock widget")
        self.hud_position = QComboBox()
        populate_combo(
            self.hud_position,
            [("top-right", "Top right"), ("top-left", "Top left"), ("bottom-right", "Bottom right"), ("bottom-left", "Bottom left")],
        )
        hud_section.add_row("Quickshell status", "Whether the Quickshell runtime appears to be available on this system.", self.quickshell_status, keywords="quickshell installed status")
        hud_section.add_row("HUD widgets", "Enable or disable the branded HUD widget layer.", self.hud_enabled, keywords="hud widgets enable")
        hud_section.add_row("CPU widget", "Show CPU usage in the HUD.", self.hud_cpu, keywords="cpu widget hud")
        hud_section.add_row("Memory widget", "Show memory usage in the HUD.", self.hud_memory, keywords="memory widget hud")
        hud_section.add_row("Network widget", "Show network status in the HUD.", self.hud_network, keywords="network widget hud")
        hud_section.add_row("Media widget", "Show current media playback in the HUD.", self.hud_media, keywords="media widget hud")
        hud_section.add_row("Clock widget", "Show the clock in the HUD.", self.hud_clock, keywords="clock widget hud")
        hud_section.add_row("Widget position", "Choose where compatible HUD widgets should prefer to appear.", self.hud_position, keywords="widget position hud")
        hud_section.add_row(
            "HUD actions",
            "Restart or inspect the widget shell when the backend is fully connected.",
            action_bar(planned_button("Restart Widget Shell")),
            keywords="restart hud widget shell",
        )
        hud_section.add_note("Do not enable experimental Quickshell mode unless you are ready to test unfinished shell behavior.")
        self.add_section(hud_section)

    def _stage_reset_layout(self) -> None:
        select_combo_value(self.panel_mode, "kesk_panel")
        self.top_panel.setChecked(True)
        self.bottom_panel.setChecked(True)
        self.auto_hide.setChecked(False)
        self.workspace_switcher.setChecked(True)
        self.launcher_enabled.setChecked(True)

    def load_state(self) -> None:
        self.begin_refresh()
        state = self.backend.panel_state()
        select_combo_value(self.panel_mode, str(state["panel_mode"]))
        self.top_panel.setChecked(bool(state["top_panel_enabled"]))
        self.bottom_panel.setChecked(bool(state["bottom_panel_enabled"]))
        self.auto_hide.setChecked(bool(state["bottom_panel_autohide"]))
        self.workspace_switcher.setChecked(bool(state["workspace_switcher"]))
        self.launcher_enabled.setChecked(bool(state["launcher_enabled"]))
        select_combo_value(self.launcher_style, str(state["launcher_style"]))
        select_combo_value(self.launcher_keybind, str(state["launcher_keybind"]))
        self.opacity.setValue(int(state["panel_opacity"]))
        self.glow.setValue(int(state["panel_glow_intensity"]))
        self.hud_enabled.setChecked(bool(state["hud_widgets_enabled"]))
        self.hud_cpu.setChecked(bool(state["hud_cpu_widget"]))
        self.hud_memory.setChecked(bool(state["hud_memory_widget"]))
        self.hud_network.setChecked(bool(state["hud_network_widget"]))
        self.hud_media.setChecked(bool(state["hud_media_widget"]))
        self.hud_clock.setChecked(bool(state["hud_clock_widget"]))
        select_combo_value(self.hud_position, str(state["hud_widget_position"]))
        self.quickshell_status.setText("Installed" if state.get("quickshell_available") else "Not installed")
        self.finish_refresh()

    def apply_changes(self) -> None:
        values = {
            "launcher_enabled": self.launcher_enabled.isChecked(),
            "launcher_style": self.launcher_style.currentData(),
            "launcher_keybind": self.launcher_keybind.currentData(),
            "panel_mode": self.panel_mode.currentData(),
            "top_panel_enabled": self.top_panel.isChecked(),
            "bottom_panel_enabled": self.bottom_panel.isChecked(),
            "bottom_panel_autohide": self.auto_hide.isChecked(),
            "workspace_switcher": self.workspace_switcher.isChecked(),
            "panel_opacity": self.opacity.value(),
            "panel_glow_intensity": self.glow.value(),
            "hud_widgets_enabled": self.hud_enabled.isChecked(),
            "hud_cpu_widget": self.hud_cpu.isChecked(),
            "hud_memory_widget": self.hud_memory.isChecked(),
            "hud_network_widget": self.hud_network.isChecked(),
            "hud_media_widget": self.hud_media.isChecked(),
            "hud_clock_widget": self.hud_clock.isChecked(),
            "hud_widget_position": self.hud_position.currentData(),
        }
        result = self.backend.apply_panels(values)
        self.show_result(result, "Panels & Launcher")
        self.load_state()

    def on_activated(self) -> None:
        self.load_state()
