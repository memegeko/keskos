from __future__ import annotations

from PySide6.QtCore import Qt
from PySide6.QtGui import QPixmap
from PySide6.QtWidgets import QCheckBox, QComboBox, QFileDialog, QHBoxLayout, QLabel, QLineEdit, QSpinBox, QWidget

from ..widgets import SettingsSection, action_bar, image_preview, populate_combo, select_combo_value, small_button
from .base import BasePage


class DesktopPage(BasePage):
    page_key = "desktop"

    def __init__(self, controller) -> None:
        super().__init__(controller, "Wallpaper", "Choose desktop wallpaper and wallpaper behavior.")
        self.backend = controller.backend
        self._build_ui()
        self.load_state()

    def _build_ui(self) -> None:
        wallpaper_section = SettingsSection("Wallpaper", "Choose desktop wallpaper and wallpaper behavior.")
        self.wallpaper_preview = image_preview("", size=(260, 150))
        self.wallpaper_path = QLineEdit()
        choose_button = small_button("Choose Image")
        choose_button.clicked.connect(self.choose_wallpaper)
        path_host = QWidget()
        path_layout = QHBoxLayout(path_host)
        path_layout.setContentsMargins(0, 0, 0, 0)
        path_layout.setSpacing(8)
        path_layout.addWidget(self.wallpaper_path, 1)
        path_layout.addWidget(choose_button)
        self.wallpaper_fit = QComboBox()
        populate_combo(self.wallpaper_fit, [("Fill", "Fill"), ("Fit", "Fit"), ("Stretch", "Stretch"), ("Tile", "Tile"), ("Center", "Center")])
        self.random_wallpaper = QCheckBox("Use random wallpaper rotation")
        self.wallpaper_folder = QLineEdit()
        folder_button = small_button("Choose Folder")
        folder_button.clicked.connect(self.choose_wallpaper_folder)
        folder_host = QWidget()
        folder_layout = QHBoxLayout(folder_host)
        folder_layout.setContentsMargins(0, 0, 0, 0)
        folder_layout.setSpacing(8)
        folder_layout.addWidget(self.wallpaper_folder, 1)
        folder_layout.addWidget(folder_button)
        self.apply_to_lock = QCheckBox("Apply the same wallpaper to the lock screen when supported")

        wallpaper_section.add_widget(self.wallpaper_preview, keywords="wallpaper preview background")
        wallpaper_section.add_row("Current wallpaper", "Desktop background image used for the main Plasma shell.", path_host, keywords="wallpaper image desktop")
        wallpaper_section.add_row("Wallpaper fit", "Choose how the wallpaper fills the screen.", self.wallpaper_fit, keywords="wallpaper fit fill stretch tile center")
        wallpaper_section.add_row("Random wallpaper", "Rotate wallpapers from a folder.", self.random_wallpaper, keywords="random wallpaper slideshow")
        wallpaper_section.add_row("Wallpaper folder", "Folder used for random wallpaper rotation.", folder_host, keywords="wallpaper folder slideshow")
        wallpaper_section.add_row("Apply to lock screen", "Use the same background for the lock screen when supported.", self.apply_to_lock, keywords="lock screen wallpaper background")
        self.add_section(wallpaper_section)

        desktop_section = SettingsSection("Desktop behavior", "Adjust wallpaper, virtual desktops, and the high-level KeskOS desktop presentation layer.")
        self.desktop_icons = QCheckBox("Show desktop icons")
        self.desktop_toolbox = QCheckBox("Show Plasma desktop toolbox")
        self.show_hidden = QCheckBox("Show hidden files on the desktop when supported")
        self.containment = QComboBox()
        populate_combo(self.containment, [("folder_view", "Folder View"), ("desktop", "Plain Desktop")])
        self.screen_edges = QComboBox()
        populate_combo(self.screen_edges, [("overview", "Overview"), ("present_windows", "Present Windows"), ("disabled", "Disabled")])
        desktop_section.add_row("Desktop containment", "Choose between folder-view and plain-desktop behavior.", self.containment, keywords="desktop containment folder view")
        desktop_section.add_row("Screen edge behavior", "Choose what the active screen corner behavior should prefer.", self.screen_edges, keywords="screen edge behavior overview")
        desktop_section.add_row("Desktop icons", "Show or hide icons on the desktop.", self.desktop_icons, keywords="desktop icons")
        desktop_section.add_row("Desktop toolbox", "Show or hide the Plasma desktop toolbox.", self.desktop_toolbox, keywords="desktop toolbox")
        desktop_section.add_row("Show hidden files", "Show hidden files in folder-view desktop mode.", self.show_hidden, keywords="show hidden files desktop")
        advanced_behavior = small_button("Open Advanced Desktop Settings")
        advanced_behavior.clicked.connect(lambda: self.controller.open_kcm("kcm_workspace"))
        desktop_section.add_row("General behavior", "Open KDE's workspace settings for extra desktop behavior options.", advanced_behavior, keywords="general desktop behavior")
        self.add_section(desktop_section)

        virtual = SettingsSection("Virtual desktops", "Choose how many workspaces KDE should keep active.")
        self.desktop_count = QSpinBox()
        self.desktop_count.setRange(1, 8)
        virtual.add_row("Desktop count", "Choose how many workspaces KDE should keep active.", self.desktop_count, keywords="virtual desktops workspaces count")
        self.workspace_names: list[QLineEdit] = []
        for index in range(1, 5):
            field = QLineEdit()
            self.workspace_names.append(field)
            virtual.add_row(
                f"Workspace {index}",
                "Visible workspace name written into KDE user config.",
                field,
                keywords="workspace names virtual desktops",
            )
        self.add_section(virtual)

    def choose_wallpaper(self) -> None:
        path, _selected_filter = QFileDialog.getOpenFileName(
            self,
            "Choose Wallpaper",
            self.wallpaper_path.text() or str(self.controller.backend.paths.home / "Pictures"),
            "Images (*.png *.jpg *.jpeg *.webp *.bmp *.svg)",
        )
        if path:
            self.wallpaper_path.setText(path)
            self._refresh_preview(path)

    def choose_wallpaper_folder(self) -> None:
        path = QFileDialog.getExistingDirectory(
            self,
            "Choose Wallpaper Folder",
            self.wallpaper_folder.text() or str(self.controller.backend.paths.home / "Pictures"),
        )
        if path:
            self.wallpaper_folder.setText(path)

    def _refresh_preview(self, path: str) -> None:
        self.wallpaper_preview.setPixmap(QPixmap())
        self.wallpaper_preview.setText("NO PREVIEW")
        if not path:
            return
        pixmap = QPixmap(path)
        if pixmap.isNull():
            self.wallpaper_preview.setText("PREVIEW UNAVAILABLE")
            return
        self.wallpaper_preview.setPixmap(
            pixmap.scaled(
                self.wallpaper_preview.size(),
                Qt.AspectRatioMode.KeepAspectRatioByExpanding,
                Qt.TransformationMode.SmoothTransformation,
            )
        )

    def load_state(self) -> None:
        self.begin_refresh()
        state = self.backend.desktop_state()
        self.wallpaper_path.setText(str(state["wallpaper_path"]))
        self._refresh_preview(str(state["wallpaper_path"]))
        select_combo_value(self.wallpaper_fit, str(state["wallpaper_fit"]))
        self.random_wallpaper.setChecked(bool(state["random_wallpaper"]))
        self.wallpaper_folder.setText(str(state["wallpaper_folder"]))
        self.apply_to_lock.setChecked(bool(state["apply_wallpaper_to_lock"]))
        self.desktop_icons.setChecked(bool(state["desktop_icons"]))
        self.desktop_toolbox.setChecked(bool(state["desktop_toolbox"]))
        self.show_hidden.setChecked(bool(state["desktop_show_hidden"]))
        select_combo_value(self.containment, str(state["desktop_containment"]))
        select_combo_value(self.screen_edges, str(state["screen_edge_behavior"]))
        self.desktop_count.setValue(int(state["desktop_count"]))
        names = list(state["workspace_names"])
        for index, field in enumerate(self.workspace_names):
            field.setText(names[index] if index < len(names) else str(index + 1))
        self.finish_refresh()

    def apply_changes(self) -> None:
        values = {
            "wallpaper_path": self.wallpaper_path.text().strip(),
            "wallpaper_fit": self.wallpaper_fit.currentData() or "Fill",
            "random_wallpaper": self.random_wallpaper.isChecked(),
            "wallpaper_folder": self.wallpaper_folder.text().strip(),
            "apply_wallpaper_to_lock": self.apply_to_lock.isChecked(),
            "desktop_icons": self.desktop_icons.isChecked(),
            "desktop_toolbox": self.desktop_toolbox.isChecked(),
            "desktop_show_hidden": self.show_hidden.isChecked(),
            "desktop_containment": self.containment.currentData() or "folder_view",
            "screen_edge_behavior": self.screen_edges.currentData() or "overview",
            "desktop_count": self.desktop_count.value(),
            "workspace_names": [field.text().strip() for field in self.workspace_names],
        }
        result = self.backend.apply_desktop(values)
        self.show_result(result, "Wallpaper")
        self.load_state()

    def on_activated(self) -> None:
        self.load_state()
