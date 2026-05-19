from __future__ import annotations

from PySide6.QtWidgets import QCheckBox, QLabel, QLineEdit

from ..widgets import SettingsSection, action_bar, info_list, planned_button, small_button
from .base import BasePage


class NetworkPage(BasePage):
    page_key = "network"

    def __init__(self, controller) -> None:
        super().__init__(controller, "Wi-Fi & Internet", "Connect to Wi-Fi, Ethernet and manage internet access.")
        self.backend = controller.backend
        self._build_ui()
        self.load_state()

    def _build_ui(self) -> None:
        section = SettingsSection("Connection status", "Connect to Wi-Fi, Ethernet and manage internet access.")
        self.wifi_enabled = QCheckBox("Enable Wi-Fi radio")
        self.current_network = QLabel()
        self.available_networks = QLabel()
        self.available_networks.setWordWrap(True)
        self.ethernet_status = QLabel()
        self.metered = QCheckBox("Treat current connection as metered")
        self.hostname = QLineEdit()

        section.add_row("Wi-Fi", "Enable or disable the NetworkManager Wi-Fi radio.", self.wifi_enabled, keywords="wifi wireless radio")
        section.add_row("Current connection", "Current active wireless connection if one is connected.", self.current_network, keywords="wifi current connection ssid")
        section.add_row("Available networks", "Nearby networks reported by NetworkManager.", self.available_networks, keywords="available networks wifi")
        section.add_row("Ethernet status", "Current wired-network status.", self.ethernet_status, keywords="ethernet wired status")
        section.add_row("Metered connection", "Reduce background activity on limited connections.", self.metered, keywords="metered connection data")
        section.add_row("Hostname", "System hostname. Changing this requires pkexec.", self.hostname, keywords="hostname computer name")

        connect_button = planned_button("Connect")
        disconnect_button = planned_button("Disconnect")
        advanced_button = small_button("Open Advanced Network Settings")
        advanced_button.clicked.connect(lambda: self.controller.open_kcm("kcm_networkmanagement"))
        section.add_row(
            "Network actions",
            "Connect, disconnect, and edit saved networks from KDE's network module.",
            action_bar(connect_button, disconnect_button, advanced_button),
            keywords="connect disconnect advanced network",
        )
        self.add_section(section)

    def load_state(self) -> None:
        self.begin_refresh()
        state = self.backend.network_state()
        if state["wifi_enabled"] is None:
            self.wifi_enabled.setEnabled(False)
        else:
            self.wifi_enabled.setEnabled(True)
            self.wifi_enabled.setChecked(bool(state["wifi_enabled"]))
        self.current_network.setText(str(state["current_network"]))
        networks = state.get("available_networks") or []
        self.available_networks.setText("\n".join(f"- {item}" for item in networks[:12]) if networks else "No network list available.")
        self.ethernet_status.setText(str(state.get("ethernet_status", "unknown")))
        self.metered.setChecked(bool(state.get("metered", False)))
        self.hostname.setText(str(state["hostname"]))
        self.finish_refresh()

    def apply_changes(self) -> None:
        values = {
            "wifi_enabled": self.wifi_enabled.isChecked() if self.wifi_enabled.isEnabled() else None,
            "hostname": self.hostname.text().strip(),
            "metered": self.metered.isChecked(),
        }
        result = self.backend.apply_network(values)
        self.show_result(result, "Wi-Fi & Internet")
        self.load_state()

    def on_activated(self) -> None:
        self.load_state()
