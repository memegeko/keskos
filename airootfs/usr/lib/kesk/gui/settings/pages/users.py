from __future__ import annotations

from PySide6.QtWidgets import QFileDialog, QHBoxLayout, QLabel, QLineEdit, QWidget

from ..widgets import SettingsSection, action_bar, planned_button, small_button
from .base import BasePage


class UsersPage(BasePage):
    page_key = "users"

    def __init__(self, controller) -> None:
        super().__init__(controller, "Users", "View and change local user profile settings.")
        self.backend = controller.backend
        self._build_ui()
        self.load_state()

    def _build_ui(self) -> None:
        info = SettingsSection("Current user", "View and change local user profile settings.")
        self.username = QLabel()
        self.account_type = QLabel()
        self.autologin = QLabel()
        self.display_name = QLineEdit()
        self.avatar_path = QLineEdit()
        avatar_button = small_button("Choose Avatar")
        avatar_button.clicked.connect(self.choose_avatar)
        avatar_host = QWidget()
        avatar_layout = QHBoxLayout(avatar_host)
        avatar_layout.setContentsMargins(0, 0, 0, 0)
        avatar_layout.setSpacing(8)
        avatar_layout.addWidget(self.avatar_path, 1)
        avatar_layout.addWidget(avatar_button)

        info.add_row("Current user", "The active session user.", self.username, keywords="current user account")
        info.add_row("Display name", "KeskOS display name stored for branded surfaces.", self.display_name, keywords="display name")
        info.add_row("Avatar", "Copy a file to ~/.face.icon for KDE-compatible avatar usage.", avatar_host, keywords="avatar face icon")
        info.add_row("Account type", "Detected account privilege level for the current user.", self.account_type, keywords="account type standard administrator")
        info.add_row("Autologin status", "Read-only detection from SDDM configuration.", self.autologin, keywords="autologin sddm")
        info.add_row(
            "Account actions",
            "Change password and open deeper account settings when backend integration is available.",
            action_bar(planned_button("Change Password"), planned_button("Open Advanced User Settings")),
            keywords="change password advanced user settings",
        )
        self.add_section(info)

    def choose_avatar(self) -> None:
        path, _selected_filter = QFileDialog.getOpenFileName(
            self,
            "Choose Avatar",
            self.avatar_path.text() or str(self.controller.backend.paths.home / "Pictures"),
            "Images (*.png *.jpg *.jpeg *.webp *.bmp *.svg)",
        )
        if path:
            self.avatar_path.setText(path)

    def load_state(self) -> None:
        self.begin_refresh()
        state = self.backend.user_state()
        self.username.setText(str(state["username"]))
        self.account_type.setText(str(state["account_type"]))
        self.display_name.setText(str(state["display_name"]))
        self.avatar_path.setText(str(state["avatar_path"]))
        self.autologin.setText("Enabled" if state["autologin"] else "Disabled")
        self.finish_refresh()

    def apply_changes(self) -> None:
        values = {
            "display_name": self.display_name.text().strip(),
            "avatar_path": self.avatar_path.text().strip(),
        }
        result = self.backend.apply_user(values)
        self.show_result(result, "Users")
        self.load_state()

    def on_activated(self) -> None:
        self.load_state()
