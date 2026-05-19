from __future__ import annotations

from PySide6.QtCore import Qt
from PySide6.QtGui import QColor, QFontDatabase, QPixmap
from PySide6.QtWidgets import (
    QCheckBox,
    QColorDialog,
    QComboBox,
    QFileDialog,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QSlider,
    QWidget,
)

from ..widgets import (
    SettingsSection,
    action_bar,
    image_preview,
    planned_button,
    planned_combo,
    planned_field,
    populate_combo,
    select_combo_value,
    small_button,
)
from .base import BasePage


class AppearancePage(BasePage):
    page_key = "appearance"

    def __init__(self, controller) -> None:
        super().__init__(controller, "Colors & Themes", "Change global theme, colors and application style.")
        self.backend = controller.backend
        self._build_ui()
        self.load_state()

    def _build_ui(self) -> None:
        theme_section = SettingsSection("Colors & Themes", "Change global theme, colors and application style.")
        self.look_and_feel = QComboBox()
        self.plasma_theme = QComboBox()
        self.color_scheme = QComboBox()
        self.application_style = QComboBox()
        populate_combo(
            self.application_style,
            [("breeze", "Breeze"), ("fusion", "Fusion"), ("kvantum", "Kvantum"), ("gtk", "GTK")],
        )
        self.application_style.setEnabled(False)
        self.application_style.setToolTip("Application-style switching will use the KDE backend when fully connected.")
        self.gtk_theme = QComboBox()
        populate_combo(self.gtk_theme, [("keskos", "KeskOS"), ("breeze-dark", "Breeze Dark"), ("adwaita-dark", "Adwaita Dark")])
        self.gtk_theme.setEnabled(False)
        self.gtk_theme.setToolTip("GTK theme switching will use the GTK/Kvantum backend when fully connected.")

        theme_section.add_row("Global theme", "Apply a Plasma look-and-feel package.", self.look_and_feel, keywords="global theme look and feel plasma")
        theme_section.add_row("Color scheme", "Change the KDE color palette.", self.color_scheme, keywords="color scheme colors themes")
        theme_section.add_row("Plasma style", "Choose the active desktop theme for panels and shells.", self.plasma_theme, keywords="plasma style desktop theme")
        theme_section.add_row("Application style", "Qt widget style used by applications.", self.application_style, keywords="application style qt")
        theme_section.add_row("GTK theme", "Theme used by GTK applications when configured.", self.gtk_theme, keywords="gtk theme")
        self.add_section(theme_section)

        accent_section = SettingsSection("KeskOS visuals", "KeskOS-specific theme and presentation settings.")
        self.accent_value = QLabel()
        self.accent_value.setMinimumWidth(96)
        self.accent_value.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.accent_button = small_button("Choose Accent")
        self.accent_button.clicked.connect(self.choose_accent)
        accent_control = QWidget()
        accent_layout = QHBoxLayout(accent_control)
        accent_layout.setContentsMargins(0, 0, 0, 0)
        accent_layout.setSpacing(8)
        accent_layout.addWidget(self.accent_value)
        accent_layout.addWidget(self.accent_button)
        self.decoration = QComboBox()
        self.crt_effects = QCheckBox("Enabled")
        self.scanlines = QCheckBox("Enabled")
        self.glow = QSlider(Qt.Orientation.Horizontal)
        self.glow.setRange(0, 100)
        self.glow_caption = QLabel("70%")
        self.glow_caption.setMinimumWidth(56)
        self.glow.valueChanged.connect(lambda value: self.glow_caption.setText(f"{value}%"))

        accent_section.add_row("Accent color", "Primary KeskOS accent used by supported assets and settings.", accent_control, keywords="accent color orange")
        accent_section.add_row("Window decorations", "Choose the active KWin decoration theme.", self.decoration, keywords="window decorations borders titlebar")
        accent_section.add_row("CRT effects", "Store the main CRT overlay preference for KeskOS components.", self.crt_effects, keywords="crt effects")
        accent_section.add_row("Scanlines", "Store the scanline overlay preference for compatible components.", self.scanlines, keywords="scanlines")
        accent_section.add_row("Glow intensity", "Tune the orange glow level for KeskOS surfaces.", self.glow, self.glow_caption, keywords="glow intensity")
        self.add_section(accent_section)

        fonts = SettingsSection("Text & Fonts", "Change system fonts, sizes and text rendering.")
        self.font_family = QComboBox()
        self.font_family.setEditable(True)
        self.font_family.addItems(sorted(QFontDatabase().families()))
        self.fixed_font = planned_field("JetBrains Mono")
        self.small_font = planned_field("JetBrains Mono")
        self.toolbar_font = planned_field("JetBrains Mono")
        self.menu_font = planned_field("JetBrains Mono")
        self.title_font = planned_field("JetBrains Mono")
        self.antialias = QCheckBox("Enable anti-aliasing")
        self.antialias.setEnabled(False)
        self.antialias.setToolTip("Backend not connected yet.")
        self.dpi = planned_combo(["96 DPI", "120 DPI", "144 DPI", "192 DPI"])
        fonts.add_row("General font", "Primary UI font used by KDE user settings.", self.font_family, keywords="general font")
        fonts.add_row("Fixed-width font", "Monospace font used by terminals and editors.", self.fixed_font, keywords="fixed width font monospace")
        fonts.add_row("Small font", "Small text used in tooltips and status labels.", self.small_font, keywords="small font")
        fonts.add_row("Toolbar font", "Font used by toolbars in supported apps.", self.toolbar_font, keywords="toolbar font")
        fonts.add_row("Menu font", "Font used by application menus.", self.menu_font, keywords="menu font")
        fonts.add_row("Window title font", "Font used in window titlebars.", self.title_font, keywords="window title font")
        fonts.add_row("Anti-aliasing", "Smooth text rendering across the desktop.", self.antialias, keywords="anti aliasing text")
        fonts.add_row("DPI", "Text scaling and rendering density.", self.dpi, keywords="dpi text scaling")
        self.add_section(fonts)

        icons = SettingsSection("Icons & Cursors", "Choose icon and cursor themes and their sizes.")
        self.icon_theme = QComboBox()
        self.cursor_theme = QComboBox()
        self.icon_preview = QLabel("ICON PREVIEW")
        self.icon_preview.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.icon_preview.setMinimumWidth(120)
        self.cursor_preview = QLabel("CURSOR PREVIEW")
        self.cursor_preview.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.cursor_preview.setMinimumWidth(120)
        self.icon_sizes = planned_combo(["Desktop: 32 px", "Toolbar: 22 px", "Panel: 24 px", "File Manager: 16 px"])
        self.cursor_size = planned_combo(["24 px", "32 px", "48 px", "64 px"])
        icons.add_row("Icon theme", "Choose the icon theme used by KDE applications.", self.icon_theme, self.icon_preview, keywords="icon theme preview")
        icons.add_row("Icon sizes", "Preferred icon sizes for desktop, toolbar, panel, and file manager.", self.icon_sizes, keywords="icon sizes desktop toolbar panel")
        icons.add_row("Cursor theme", "Choose the system pointer theme.", self.cursor_theme, self.cursor_preview, keywords="cursor theme preview")
        icons.add_row("Cursor size", "Choose cursor size for visibility and accessibility.", self.cursor_size, keywords="cursor size")
        icons.add_row(
            "Theme actions",
            "Apply branded themes or fetch more assets from KDE's online theme tools later.",
            action_bar(small_button("Apply KeskOS Icons"), planned_button("Get New Icons"), planned_button("Get New Cursors")),
            keywords="apply keskos icons get new icons cursors",
        )
        self.add_section(icons)

        wallpaper = SettingsSection("Wallpaper", "Choose desktop wallpaper and wallpaper behavior.")
        self.wallpaper_preview = image_preview("", size=(240, 136))
        self.wallpaper_path = QLineEdit()
        self.wallpaper_button = small_button("Choose Image")
        self.wallpaper_button.clicked.connect(self.choose_wallpaper)
        path_control = QWidget()
        path_layout = QHBoxLayout(path_control)
        path_layout.setContentsMargins(0, 0, 0, 0)
        path_layout.setSpacing(8)
        path_layout.addWidget(self.wallpaper_path, 1)
        path_layout.addWidget(self.wallpaper_button)
        wallpaper.add_widget(self.wallpaper_preview, keywords="wallpaper background preview")
        wallpaper.add_row("Current wallpaper", "Absolute file path for the desktop background.", path_control, keywords="wallpaper background image")
        self.add_section(wallpaper)

        startup = SettingsSection("Splash & Login", "Choose the animation shown when the desktop session starts.")
        startup.add_row("Splash screen theme", "Choose the Plasma session splash screen.", planned_combo(["KeskOS", "None", "Breeze"]), keywords="splash screen theme")
        startup.add_row("Disable splash screen", "Skip the Plasma session splash animation.", planned_combo(["No", "Yes"]), keywords="disable splash screen")
        startup.add_row("Login screen theme", "Current SDDM theme and future login-screen theme routing.", planned_field("Detected in Boot & Login"), keywords="login screen sddm theme")
        open_boot = small_button("Open Boot & Login")
        open_boot.clicked.connect(lambda: self.controller.open_settings_page("boot_login"))
        startup.add_row(
            "Boot and login settings",
            "Open the dedicated boot and login page for SDDM and Plymouth status.",
            open_boot,
            keywords="boot login splash screen",
        )
        self.add_section(startup)

        actions = SettingsSection("Theme actions")
        self.kesk_defaults_button = small_button("Apply KeskOS Defaults")
        self.kesk_defaults_button.clicked.connect(self.apply_kesk_defaults)
        self.kde_defaults_button = small_button("Restore KDE Defaults")
        self.kde_defaults_button.clicked.connect(self.apply_kde_defaults)
        self.restore_backup_button = small_button("Restore Appearance Backup")
        self.restore_backup_button.clicked.connect(self.restore_backup)
        actions.add_widget(
            action_bar(self.kesk_defaults_button, self.kde_defaults_button, self.restore_backup_button),
            keywords="apply keskos defaults restore kde defaults backup",
        )
        self.add_section(actions)

    def _set_accent_chip(self, value: str) -> None:
        color = QColor(value)
        if not color.isValid():
            color = QColor("#ce6a35")
        text_color = "#111111" if color.lightness() > 140 else "#f4efe8"
        self.accent_value.setText(color.name().upper())
        self.accent_value.setStyleSheet(f"background-color: {color.name()}; color: {text_color}; border: 1px solid #ce6a35; padding: 6px;")

    def _set_wallpaper_preview(self, value: str) -> None:
        self.wallpaper_preview.setPixmap(QPixmap())
        self.wallpaper_preview.setText("NO PREVIEW")
        path = value.strip()
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

    def reload_options(self) -> None:
        populate_combo(self.look_and_feel, self.backend.look_and_feel_options())
        populate_combo(self.plasma_theme, self.backend.plasma_theme_options())
        populate_combo(self.color_scheme, self.backend.color_scheme_options())
        populate_combo(self.icon_theme, self.backend.icon_theme_options())
        populate_combo(self.cursor_theme, self.backend.cursor_theme_options())
        populate_combo(self.decoration, self.backend.window_decoration_options())

    def load_state(self) -> None:
        self.begin_refresh()
        self.reload_options()
        state = self.backend.appearance_state()
        select_combo_value(self.look_and_feel, state["look_and_feel"])
        select_combo_value(self.plasma_theme, state["plasma_theme"])
        select_combo_value(self.color_scheme, state["color_scheme"])
        select_combo_value(self.icon_theme, state["icon_theme"])
        select_combo_value(self.cursor_theme, state["cursor_theme"])
        select_combo_value(self.decoration, state["window_decoration"])
        index = self.font_family.findText(state["font_family"])
        if index >= 0:
            self.font_family.setCurrentIndex(index)
        else:
            self.font_family.setEditText(state["font_family"])
        self._set_accent_chip(state["accent_color"])
        self.wallpaper_path.setText(state["wallpaper_path"])
        self._set_wallpaper_preview(state["wallpaper_path"])
        self.crt_effects.setChecked(bool(state["crt_effects"]))
        self.scanlines.setChecked(bool(state["scanlines"]))
        self.glow.setValue(int(state["glow_intensity"]))
        self.glow_caption.setText(f"{int(state['glow_intensity'])}%")
        self.icon_preview.setText(str(state["icon_theme"]).upper())
        self.cursor_preview.setText(str(state["cursor_theme"]).upper())
        self.finish_refresh()

    def choose_accent(self) -> None:
        color = QColorDialog.getColor(QColor(self.accent_value.text() or "#ce6a35"), self, "Choose KeskOS Accent")
        if color.isValid():
            self._set_accent_chip(color.name())

    def choose_wallpaper(self) -> None:
        path, _selected_filter = QFileDialog.getOpenFileName(
            self,
            "Choose Wallpaper",
            self.wallpaper_path.text() or str(self.controller.backend.paths.home / "Pictures"),
            "Images (*.png *.jpg *.jpeg *.webp *.bmp *.svg)",
        )
        if path:
            self.wallpaper_path.setText(path)
            self._set_wallpaper_preview(path)

    def values(self) -> dict[str, object]:
        return {
            "look_and_feel": self.look_and_feel.currentData(),
            "plasma_theme": self.plasma_theme.currentData(),
            "color_scheme": self.color_scheme.currentData(),
            "icon_theme": self.icon_theme.currentData(),
            "cursor_theme": self.cursor_theme.currentData(),
            "font_family": self.font_family.currentText().strip(),
            "accent_color": self.accent_value.text().strip(),
            "window_decoration": self.decoration.currentData(),
            "wallpaper_path": self.wallpaper_path.text().strip(),
            "crt_effects": self.crt_effects.isChecked(),
            "scanlines": self.scanlines.isChecked(),
            "glow_intensity": self.glow.value(),
        }

    def apply_changes(self) -> None:
        result = self.backend.apply_appearance(self.values())
        self.show_result(result, "Colors & Themes")
        self.load_state()

    def apply_kesk_defaults(self) -> None:
        result = self.backend.apply_kesk_appearance_defaults()
        self.show_result(result, "Colors & Themes")
        self.load_state()

    def apply_kde_defaults(self) -> None:
        result = self.backend.apply_kde_appearance_defaults()
        self.show_result(result, "Colors & Themes")
        self.load_state()

    def restore_backup(self) -> None:
        result = self.backend.restore_latest_backup("appearance")
        self.show_result(result, "Appearance Backup")
        self.load_state()

    def on_activated(self) -> None:
        self.load_state()
