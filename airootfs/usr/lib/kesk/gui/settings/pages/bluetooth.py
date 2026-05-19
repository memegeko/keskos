from __future__ import annotations

from PySide6.QtWidgets import QCheckBox, QComboBox, QLabel

from ..widgets import SettingsSection, StatusLabel, action_bar, info_list, small_button
from .base import BasePage


class BluetoothPage(BasePage):
    page_key = "bluetooth"

    def __init__(self, controller) -> None:
        super().__init__(controller, "Bluetooth", "Pair and manage Bluetooth devices.")
        self.backend = controller.backend
        self._build_ui()
        self.load_state()

    def _build_ui(self) -> None:
        status_section = SettingsSection("Backend status", "Bluetooth control depends on bluetoothctl, the bluetooth service, and an available adapter.")
        self.status_label = StatusLabel("Loading backend status", "work")
        self.adapter_status = QLabel()
        self.service_status = QLabel()
        status_section.add_row("Bluetooth backend", "Current availability for Bluetooth management.", self.status_label, keywords="bluetooth backend status")
        status_section.add_row("Adapter", "Detected Bluetooth adapter.", self.adapter_status, keywords="bluetooth adapter")
        status_section.add_row("Service", "Current bluetooth.service state.", self.service_status, keywords="bluetooth service")
        self.add_section(status_section)

        controls = SettingsSection("Bluetooth adapter", "Pair and manage Bluetooth devices.")
        self.enabled = QCheckBox("Enable Bluetooth")
        self.receive_files = QCheckBox("Allow Bluetooth file reception")
        controls.add_row("Bluetooth radio", "Turn the Bluetooth radio on or off.", self.enabled, keywords="bluetooth on off radio")
        controls.add_row("Receive files", "Allow file reception when a Bluetooth backend supports it.", self.receive_files, keywords="receive files bluetooth")
        self.add_section(controls)

        paired = SettingsSection("Paired devices", "Trusted or remembered Bluetooth devices.")
        self.paired_selector = QComboBox()
        self.paired_summary = QLabel()
        self.paired_summary.setWordWrap(True)
        connect_button = small_button("Connect")
        connect_button.clicked.connect(self.connect_selected)
        disconnect_button = small_button("Disconnect")
        disconnect_button.clicked.connect(self.disconnect_selected)
        trust_button = small_button("Trust")
        trust_button.clicked.connect(self.trust_selected)
        remove_button = small_button("Remove")
        remove_button.clicked.connect(self.remove_selected)
        paired.add_row("Known devices", "Select a paired device to connect, trust, or remove it.", self.paired_selector, keywords="paired devices bluetooth")
        paired.add_row("Device status", "Connection and trust information for the selected device.", self.paired_summary, keywords="paired device status")
        paired.add_row("Device actions", "Connect, disconnect, trust, or remove the selected device.", action_bar(connect_button, disconnect_button, trust_button, remove_button), keywords="connect disconnect trust remove bluetooth")
        self.add_section(paired)

        nearby = SettingsSection("Nearby devices", "Detect devices nearby and pair them when the adapter is active.")
        self.nearby_selector = QComboBox()
        pair_button = small_button("Pair Selected Device")
        pair_button.clicked.connect(self.pair_selected)
        advanced_button = small_button("Open Bluetooth Settings")
        advanced_button.clicked.connect(lambda: self.controller.open_kcm("kcm_bluetooth"))
        nearby.add_row("Nearby devices", "Devices currently visible to bluetoothctl.", self.nearby_selector, keywords="nearby bluetooth devices pair")
        nearby.add_row("Pairing tools", "Use direct pair actions or open KDE's Bluetooth module for advanced flows.", action_bar(pair_button, advanced_button), keywords="pair bluetooth advanced")
        self.add_section(nearby)

    def _current_paired_address(self) -> str:
        return str(self.paired_selector.currentData() or "").strip()

    def _current_nearby_address(self) -> str:
        return str(self.nearby_selector.currentData() or "").strip()

    def load_state(self) -> None:
        self.begin_refresh()
        state = self.backend.bluetooth_state()
        status = state["status"]
        self.status_label.set_status(status.summary, status.ui_kind)
        self.adapter_status.setText(str(state["adapter_name"]))
        self.service_status.setText(str(state["service_state"]))
        self.enabled.setChecked(bool(state["enabled"]))
        self.receive_files.setChecked(bool(state["receive_files"]))

        self.enabled.setEnabled(status.code != "missing")
        self.receive_files.setEnabled(status.code != "missing")

        self.paired_selector.blockSignals(True)
        self.paired_selector.clear()
        for device in state.get("paired_devices", []):
            label = f"{device['name']} ({device['address']})"
            self.paired_selector.addItem(label, str(device["address"]))
        self.paired_selector.blockSignals(False)
        self.nearby_selector.blockSignals(True)
        self.nearby_selector.clear()
        for device in state.get("nearby_devices", []):
            label = f"{device['name']} ({device['address']})"
            self.nearby_selector.addItem(label, str(device["address"]))
        self.nearby_selector.blockSignals(False)

        if state.get("paired_devices"):
            first = state["paired_devices"][0]
            self.paired_summary.setText(
                f"Connected: {'yes' if first.get('connected') else 'no'}\nTrusted: {'yes' if first.get('trusted') else 'no'}"
            )
        else:
            self.paired_summary.setText("No paired Bluetooth devices were found.")
        self.finish_refresh()

    def apply_changes(self) -> None:
        result = self.backend.apply_bluetooth(
            {
                "enabled": self.enabled.isChecked(),
                "receive_files": self.receive_files.isChecked(),
            }
        )
        self.show_result(result, "Bluetooth")
        self.load_state()

    def connect_selected(self) -> None:
        address = self._current_paired_address()
        if not address:
            return
        result = self.backend.bluetooth_connect_device(address)
        self.show_result(result, "Bluetooth")
        self.load_state()

    def disconnect_selected(self) -> None:
        address = self._current_paired_address()
        if not address:
            return
        result = self.backend.bluetooth_disconnect_device(address)
        self.show_result(result, "Bluetooth")
        self.load_state()

    def trust_selected(self) -> None:
        address = self._current_paired_address()
        if not address:
            return
        result = self.backend.bluetooth_trust_device(address)
        self.show_result(result, "Bluetooth")
        self.load_state()

    def remove_selected(self) -> None:
        address = self._current_paired_address()
        if not address:
            return
        if not self.controller.confirm_action("Remove Bluetooth Device", f"Remove {self.paired_selector.currentText()} from paired devices?"):
            return
        result = self.backend.bluetooth_remove_device(address)
        self.show_result(result, "Bluetooth")
        self.load_state()

    def pair_selected(self) -> None:
        address = self._current_nearby_address()
        if not address:
            return
        result = self.backend.bluetooth_pair_device(address)
        self.show_result(result, "Bluetooth")
        self.load_state()

    def on_activated(self) -> None:
        self.load_state()
