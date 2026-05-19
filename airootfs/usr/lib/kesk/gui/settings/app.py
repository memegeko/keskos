from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
import os
from pathlib import Path
from typing import Callable

from PySide6.QtCore import QObject, QSize, Qt
from PySide6.QtGui import QColor, QFont, QIcon, QPainter, QPen, QPixmap
from PySide6.QtWidgets import (
    QApplication,
    QFrame,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QMainWindow,
    QMessageBox,
    QPushButton,
    QScrollArea,
    QStackedWidget,
    QStatusBar,
    QStyle,
    QToolButton,
    QVBoxLayout,
    QWidget,
)

from common import SessionLogger

from .backend import ApplyResult, SettingsBackend, launch_terminal_command, load_prefs, open_target, resolve_runtime_paths, save_prefs
from .pages.about import AboutPage
from .pages.accessibility import AccessibilityPage
from .pages.appearance import AppearancePage
from .pages.base import BasePage
from .pages.bluetooth import BluetoothPage
from .pages.boot import BootPage
from .pages.defaults import DefaultsPage
from .pages.desktop import DesktopPage
from .pages.display import DisplayPage
from .pages.input import InputPage
from .pages.kesk import KeskPage
from .pages.network import NetworkPage
from .pages.network_extras import NetworkExtrasPage
from .pages.notifications_page import NotificationsPage
from .pages.panels import PanelsPage
from .pages.power import PowerPage
from .pages.privacy import PrivacyPage
from .pages.quick_settings import QuickSettingsPage
from .pages.search_tools import SearchToolsPage
from .pages.sound import SoundPage
from .pages.updates import UpdatesPage
from .pages.users import UsersPage
from .pages.windows import WindowsPage
from .theme import APP_SUBTITLE, APP_TITLE, stylesheet
from .widgets import (
    SettingsSection,
    action_bar,
    info_list,
    planned_button,
    planned_combo,
    planned_field,
    planned_toggle,
    small_button,
)


@dataclass(frozen=True)
class PageDescriptor:
    key: str
    label: str
    group: str
    page_id: str
    description: str
    icon_name: str
    keywords: str = ""
    focus_query: str = ""


def _display_text(text: str) -> str:
    return text.replace("&", "&&")


def _sidebar_abbreviation(label: str) -> str:
    cleaned = label.replace("&", " ").replace("/", " ").replace("-", " ")
    words = [word for word in cleaned.split() if word]
    if not words:
        return "KS"
    if len(words) == 1:
        return words[0][:2].upper()
    return f"{words[0][0]}{words[1][0]}".upper()


def _badge_icon(text: str) -> QIcon:
    pixmap = QPixmap(18, 18)
    pixmap.fill(Qt.GlobalColor.transparent)

    painter = QPainter(pixmap)
    painter.setRenderHint(QPainter.RenderHint.Antialiasing, False)
    painter.setPen(QPen(QColor("#ce6a35"), 1))
    painter.drawRect(0, 0, 17, 17)
    painter.setPen(QColor("#b8afa6"))
    font = QFont("JetBrains Mono", 7)
    font.setBold(True)
    painter.setFont(font)
    painter.drawText(pixmap.rect(), Qt.AlignmentFlag.AlignCenter, text)
    painter.end()
    return QIcon(pixmap)


def _standard_icon(style: QStyle, descriptor: PageDescriptor) -> QIcon:
    mapping = {
        "quick_settings": QStyle.StandardPixmap.SP_ComputerIcon,
        "mouse_touchpad": QStyle.StandardPixmap.SP_TitleBarShadeButton,
        "keyboard": QStyle.StandardPixmap.SP_DialogResetButton,
        "game_controller": QStyle.StandardPixmap.SP_MediaPlay,
        "sound": QStyle.StandardPixmap.SP_MediaVolume,
        "display_monitor": QStyle.StandardPixmap.SP_DesktopIcon,
        "accessibility": QStyle.StandardPixmap.SP_DialogHelpButton,
        "disks_cameras": QStyle.StandardPixmap.SP_DriveHDIcon,
        "printers": QStyle.StandardPixmap.SP_FileDialogDetailedView,
        "removable_storage": QStyle.StandardPixmap.SP_DriveFDIcon,
        "bluetooth": QStyle.StandardPixmap.SP_BrowserReload,
        "wifi_internet": QStyle.StandardPixmap.SP_DriveNetIcon,
        "online_accounts": QStyle.StandardPixmap.SP_DirHomeIcon,
        "vpn": QStyle.StandardPixmap.SP_ArrowRight,
        "proxy": QStyle.StandardPixmap.SP_BrowserStop,
        "wallpaper": QStyle.StandardPixmap.SP_FileDialogContentsView,
        "colors_themes": QStyle.StandardPixmap.SP_DialogApplyButton,
        "text_fonts": QStyle.StandardPixmap.SP_FileDialogListView,
        "icons": QStyle.StandardPixmap.SP_DirIcon,
        "cursors": QStyle.StandardPixmap.SP_ArrowForward,
        "window_decorations": QStyle.StandardPixmap.SP_TitleBarMenuButton,
        "splash_screen": QStyle.StandardPixmap.SP_MessageBoxInformation,
        "login_screen": QStyle.StandardPixmap.SP_DialogOpenButton,
        "default_apps": QStyle.StandardPixmap.SP_DialogOpenButton,
        "file_associations": QStyle.StandardPixmap.SP_FileIcon,
        "window_behavior": QStyle.StandardPixmap.SP_TitleBarNormalButton,
        "task_switcher": QStyle.StandardPixmap.SP_ArrowBack,
        "shortcuts": QStyle.StandardPixmap.SP_CommandLink,
        "notifications": QStyle.StandardPixmap.SP_MessageBoxInformation,
        "search_tools": QStyle.StandardPixmap.SP_FileDialogStart,
        "power": QStyle.StandardPixmap.SP_BrowserReload,
        "users": QStyle.StandardPixmap.SP_DirHomeIcon,
        "region_language": QStyle.StandardPixmap.SP_DialogYesButton,
        "date_time": QStyle.StandardPixmap.SP_FileDialogInfoView,
        "privacy_security": QStyle.StandardPixmap.SP_MessageBoxWarning,
        "boot_login": QStyle.StandardPixmap.SP_DialogApplyButton,
        "updates": QStyle.StandardPixmap.SP_BrowserReload,
        "about_system": QStyle.StandardPixmap.SP_MessageBoxInformation,
        "kesk_theme": QStyle.StandardPixmap.SP_DialogApplyButton,
        "panels_launcher": QStyle.StandardPixmap.SP_ToolBarHorizontalExtensionButton,
        "hud_widgets": QStyle.StandardPixmap.SP_DesktopIcon,
        "browser_defaults": QStyle.StandardPixmap.SP_DriveNetIcon,
        "boot_splash": QStyle.StandardPixmap.SP_MessageBoxInformation,
        "experimental": QStyle.StandardPixmap.SP_MessageBoxQuestion,
    }
    return style.standardIcon(mapping.get(descriptor.key, QStyle.StandardPixmap.SP_FileIcon))


def _resolve_sidebar_icon(style: QStyle, descriptor: PageDescriptor) -> QIcon:
    icon = QIcon.fromTheme(descriptor.icon_name)
    if not icon.isNull():
        return icon
    icon = _standard_icon(style, descriptor)
    if not icon.isNull():
        return icon
    return _badge_icon(_sidebar_abbreviation(descriptor.label))


class SidebarItemButton(QToolButton):
    def __init__(self, descriptor: PageDescriptor, style: QStyle) -> None:
        super().__init__()
        self.descriptor = descriptor
        self._expanded_label = descriptor.label
        self.setObjectName("SidebarItem")
        self.setCheckable(True)
        self.setCursor(Qt.CursorShape.PointingHandCursor)
        self.setToolButtonStyle(Qt.ToolButtonStyle.ToolButtonTextBesideIcon)
        self.setIconSize(QSize(18, 18))
        self.setText(_display_text(descriptor.label))
        self.setToolTip(descriptor.label)
        self.setIcon(_resolve_sidebar_icon(style, descriptor))

    def set_collapsed(self, collapsed: bool) -> None:
        if collapsed:
            self.setToolButtonStyle(Qt.ToolButtonStyle.ToolButtonIconOnly)
            self.setText("" if not self.icon().isNull() else self._expanded_label[:1].upper())
        else:
            self.setToolButtonStyle(Qt.ToolButtonStyle.ToolButtonTextBesideIcon)
            self.setText(_display_text(self._expanded_label))


class GuiController(QObject):
    def __init__(self, root: Path) -> None:
        super().__init__()
        self.paths = resolve_runtime_paths(root)
        self.logger = SessionLogger("gui")
        self.backend = SettingsBackend(self.paths, self.logger)
        self.prefs = load_prefs(self.paths.ui_state_path)
        self.window: KeskSettingsWindow | None = None

    def set_window(self, window: "KeskSettingsWindow") -> None:
        self.window = window

    def close(self) -> None:
        self.logger.close()

    def log(self, message: str) -> None:
        self.logger.log(message)
        if self.window is not None:
            self.window.statusBar().showMessage(message, 4000)

    def surface_error(self, message: str) -> None:
        self.logger.log(f"gui_error={message}")
        if self.window is not None:
            self.window.statusBar().showMessage(message, 6000)
            QMessageBox.warning(self.window, APP_TITLE, message)

    def open_target(self, target: str) -> None:
        ok, detail = open_target(target, self.logger)
        if ok:
            self.log(f"opened {target}")
            return
        self.surface_error(f"Could not open {target} automatically.\n{detail}")

    def open_url(self, url: str) -> None:
        self.open_target(url)

    def open_kcm(self, module: str) -> None:
        ok, detail = self.backend.open_kcm(module)
        if ok:
            self.log(f"opened {module}")
            return
        self.surface_error(f"Could not open KDE settings module.\n{detail}")

    def open_settings_page(self, key: str) -> None:
        if self.window is not None:
            self.window.select_page(key)

    def confirm_action(self, title: str, message: str) -> bool:
        if self.window is None:
            return False
        result = QMessageBox.question(self.window, title, message, QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No)
        return result == QMessageBox.StandardButton.Yes

    def launch_upgrade(self) -> None:
        command = self.backend.tool_command("upgrade")
        process, description = launch_terminal_command(command, self.logger)
        if process is None:
            self.surface_error(description)
            return
        self.log(f"launched in terminal: {description}")

    def present_result(self, title: str, result: ApplyResult) -> None:
        self.logger.log(f"apply_result={title}:{result.summary}")
        for line in result.details:
            self.logger.log(f"detail {line}")
        for line in result.warnings:
            self.logger.log(f"warning {line}")
        for line in result.requires:
            self.logger.log(f"requires {line}")
        if result.backup_path is not None:
            self.logger.log(f"backup {result.backup_path}")

        if self.window is not None:
            self.window.statusBar().showMessage(result.summary, 6000)

        detail_lines = list(result.details)
        if result.backup_path is not None:
            detail_lines.append(f"Backup: {result.backup_path}")
        detail_lines.extend(result.requires)
        detail_lines.extend(f"Warning: {warning}" for warning in result.warnings)
        if detail_lines:
            box = QMessageBox(self.window)
            box.setWindowTitle(title)
            box.setIcon(QMessageBox.Icon.Information if result.success else QMessageBox.Icon.Warning)
            box.setText(result.summary)
            box.setDetailedText("\n".join(detail_lines))
            box.exec()
        elif not result.success:
            QMessageBox.warning(self.window, title, result.summary)


def _muted_label(text: str) -> QLabel:
    label = QLabel(text)
    label.setObjectName("Muted")
    label.setWordWrap(True)
    return label


def _build_accessibility_page(controller: GuiController) -> BasePage:
    page = BasePage(controller, "Accessibility", "Make the system easier to see, hear, and control without leaving the settings hierarchy.")
    overview = SettingsSection("Assistive controls", "These options will use KDE input and accessibility settings when fully connected.")
    overview.add_row(
        "Large text",
        "Increase UI text scale for better readability.",
        planned_toggle(),
        keywords="large text fonts scale readability",
    )
    overview.add_row(
        "High contrast",
        "Switch to a high-contrast visual profile for supported components.",
        planned_toggle(),
        keywords="high contrast accessibility theme",
    )
    overview.add_row(
        "Screen reader",
        "Enable assistive screen-reader integration when the backend is available.",
        planned_toggle(),
        keywords="screen reader speech accessibility",
    )
    overview.add_row(
        "Reduce animations",
        "Reduce motion and long transitions in the desktop shell.",
        planned_toggle(),
        keywords="reduce animations motion",
    )
    overview.add_row(
        "Cursor size",
        "Choose a larger pointer size for easier tracking.",
        planned_combo(["Default", "24 px", "32 px", "48 px", "64 px"]),
        keywords="cursor size pointer",
    )
    keyboard_button = small_button("Keyboard Settings")
    keyboard_button.clicked.connect(lambda: controller.open_kcm("kcm_keyboard"))
    access_button = small_button("Open Accessibility Settings")
    access_button.clicked.connect(lambda: controller.open_kcm("kcm_access"))
    overview.add_row(
        "Advanced accessibility",
        "Use KDE's accessibility and keyboard modules for stick keys, slow keys, bounce keys, and focus helpers.",
        action_bar(access_button, keyboard_button),
        keywords="accessibility sticky keys bounce keys slow keys screen reader",
    )
    overview.add_note("Backend not connected yet. These rows already describe the KDE accessibility settings they will control.")
    page.add_section(overview)
    return page


def _build_devices_page(controller: GuiController) -> BasePage:
    page = BasePage(controller, "Connected Devices", "Manage removable storage, cameras, printers, and controllers from one place while keeping deeper device workflows in KDE tools.")
    camera_items = sorted(str(path.name) for path in Path("/dev").glob("video*"))
    controller_items = sorted(str(path.name) for path in Path("/dev/input").glob("js*"))
    storage_items = sorted(str(path.name) for path in Path("/run/media").glob("*/*") if path.exists())

    storage = SettingsSection("Disks & Cameras")
    storage.add_row(
        "Removable storage auto-mount",
        "Automatically mount USB drives and memory cards when inserted.",
        planned_toggle(checked=True),
        keywords="removable storage automount usb sd card",
    )
    storage.add_row(
        "Ask before opening new devices",
        "Prompt before opening a newly connected removable device.",
        planned_toggle(checked=True),
        keywords="open new devices prompt ask",
    )
    storage.add_row(
        "Camera access",
        "Allow desktop apps to access connected cameras.",
        planned_toggle(checked=True),
        keywords="camera webcam privacy access",
    )
    storage.add_row(
        "Connected cameras",
        "Currently visible camera devices.",
        info_list(camera_items, "No camera device detected."),
        keywords="camera webcam list",
    )
    storage.add_row(
        "Connected storage devices",
        "Mounted removable devices visible in the current session.",
        info_list(storage_items, "No removable storage detected."),
        keywords="storage removable list devices",
    )
    automount_button = small_button("Open KDE Device Settings")
    automount_button.clicked.connect(lambda: controller.open_kcm("kcm_device_automounter"))
    storage.add_row(
        "Advanced device settings",
        "Open KDE's removable-device module for automount policy and media actions.",
        automount_button,
        keywords="kde device automounter removable",
    )
    storage.add_note("Backend not connected yet. These controls will use KDE removable-device and camera privacy settings when implemented.")
    page.add_section(storage)

    printers = SettingsSection("Printers")
    printers.add_row(
        "Installed printers",
        "Detected printers and print queues from the desktop print stack.",
        _muted_label("Printer discovery will use KDE and CUPS backends when connected."),
        keywords="installed printers cups list",
    )
    printers.add_row(
        "Default printer",
        "Choose the printer used for new print jobs by default.",
        planned_combo(["System default", "Office Printer", "PDF Printer"]),
        keywords="default printer",
    )
    printers.add_row(
        "Current print jobs",
        "View active or queued print jobs.",
        _muted_label("No print jobs to show in the current backend preview."),
        keywords="print jobs queue",
    )
    automount_button = small_button("Open Removable Storage")
    automount_button.clicked.connect(lambda: controller.open_kcm("kcm_device_automounter"))
    printer_button = small_button("Open Printers")
    printer_button.clicked.connect(lambda: controller.open_kcm("kcm_printer_manager"))
    printers.add_row(
        "Printer tools",
        "Add printers, print a test page, and manage queues with KDE's printer module.",
        action_bar(printer_button, automount_button),
        keywords="printer settings add printer test page",
    )
    page.add_section(printers)

    controllers = SettingsSection("Game Controller")
    controllers.add_row(
        "Connected controllers",
        "Joystick and controller devices currently exposed to the session.",
        info_list(controller_items, "No game controller detected."),
        keywords="controller joystick gamepad connected",
    )
    controllers.add_row(
        "Mapping profile",
        "Select a controller mapping profile when controller support is fully connected.",
        planned_combo(["Default mapping", "Xbox layout", "PlayStation layout"]),
        keywords="controller mapping profile",
    )
    controllers.add_row(
        "Controller test area",
        "Test inputs, vibration, and calibration from a dedicated controller backend.",
        action_bar(planned_button("Test Vibration"), planned_button("Calibrate")),
        keywords="controller test vibration calibration",
    )
    controllers.add_note("Controller detection is read-only for now. Calibration and vibration testing will use the KDE/game-controller backend when connected.")
    page.add_section(controllers)
    return page


def _build_bluetooth_page(controller: GuiController) -> BasePage:
    page = BasePage(controller, "Bluetooth", "Pair and manage Bluetooth devices from the normal settings layout.")
    section = SettingsSection("Bluetooth adapter", "These controls will use KDE's Bluetooth stack when fully connected.")
    adapter_status = "Bluetooth tools detected." if controller.backend.tools.get("pkexec") or os.path.exists("/sys/class/bluetooth") else "Bluetooth adapter status unavailable."
    section.add_row("Bluetooth", "Turn the system Bluetooth radio on or off.", planned_toggle(checked=True), keywords="bluetooth on off radio")
    section.add_row("Adapter status", "Current adapter visibility in the running session.", QLabel(adapter_status), keywords="adapter status bluetooth")
    section.add_row("Paired devices", "Trusted and paired Bluetooth devices.", _muted_label("Paired devices will appear here when the backend is connected."), keywords="paired devices trust bluetooth")
    section.add_row("Receive files", "Allow Bluetooth file reception when supported.", planned_toggle(), keywords="receive files bluetooth")
    open_button = small_button("Open Bluetooth Settings")
    open_button.clicked.connect(lambda: controller.open_kcm("kcm_bluetooth"))
    section.add_row(
        "Pairing tools",
        "Open KDE's Bluetooth module to pair, trust, remove, and inspect devices.",
        action_bar(open_button, planned_button("Pair New Device"), planned_button("Remove Device")),
        keywords="bluetooth pairing trust remove device",
    )
    section.add_note("Backend not connected yet. Pairing and trusted-device actions will use KDE Bluetooth settings when implemented.")
    page.add_section(section)
    return page


def _build_network_extras_page(controller: GuiController) -> BasePage:
    page = BasePage(controller, "Advanced Networking", "Keep online accounts, VPN, and proxy settings in the same settings tree without replacing the full network stack.")
    state = controller.backend.network_state()
    accounts = SettingsSection("Online Accounts", "Connect cloud accounts for files, calendars, and other services.")
    network_button = small_button("Open Network Settings")
    network_button.clicked.connect(lambda: controller.open_kcm("kcm_networkmanagement"))
    accounts_button = small_button("Online Accounts")
    accounts_button.clicked.connect(lambda: controller.open_kcm("kcm_kaccounts"))
    accounts.add_row(
        "Connected accounts",
        "Accounts already available to the KDE online-account service.",
        _muted_label("Connected accounts will appear here when the backend is connected."),
        keywords="connected accounts cloud",
    )
    accounts.add_row(
        "Sync calendar",
        "Enable calendar synchronization for connected accounts.",
        planned_toggle(checked=True),
        keywords="sync calendar accounts",
    )
    accounts.add_row(
        "Sync files",
        "Allow connected file providers to sync content into desktop apps.",
        planned_toggle(checked=True),
        keywords="sync files cloud",
    )
    accounts.add_row(
        "Account management",
        "Open KDE's online-accounts module to add or remove services.",
        action_bar(accounts_button, planned_button("Remove Account")),
        keywords="online accounts add remove",
    )
    page.add_section(accounts)

    vpn = SettingsSection("VPN", "Add and manage secure tunnels from the normal network settings layout.")
    vpn.add_row(
        "VPN list",
        "Configured VPN connections and their current state.",
        _muted_label("Configured VPNs will appear here when NetworkManager integration is connected."),
        keywords="vpn list network",
    )
    vpn.add_row(
        "Current network",
        "Active network detected by the lightweight backend.",
        QLabel(str(state["current_network"])),
        keywords="current network connection",
    )
    vpn.add_row(
        "VPN actions",
        "Connect, disconnect, import, or edit VPN profiles through the KDE network module.",
        action_bar(network_button, planned_button("Connect"), planned_button("Import VPN Config")),
        keywords="vpn connect disconnect import",
    )
    page.add_section(vpn)

    proxy = SettingsSection("Proxy", "Configure proxy routes for the system and desktop apps.")
    proxy.add_row(
        "Proxy mode",
        "Choose whether the system uses no proxy, manual proxies, or a PAC URL.",
        planned_combo(["None", "Manual", "Automatic"]),
        keywords="proxy mode automatic pac",
    )
    proxy.add_row(
        "HTTP proxy",
        "Proxy used for plain HTTP requests.",
        planned_field("http://proxy.example:8080"),
        keywords="http proxy",
    )
    proxy.add_row(
        "HTTPS proxy",
        "Proxy used for encrypted HTTPS requests.",
        planned_field("https://proxy.example:8443"),
        keywords="https proxy",
    )
    proxy.add_row(
        "SOCKS proxy",
        "SOCKS proxy for apps that support it.",
        planned_field("socks5://proxy.example:1080"),
        keywords="socks proxy",
    )
    proxy.add_row(
        "No proxy exceptions",
        "Hosts and domains that should bypass the proxy.",
        planned_field("localhost,127.0.0.1,.local"),
        keywords="no proxy exceptions bypass",
    )
    proxy.add_row(
        "Advanced network settings",
        "Open KDE's NetworkManager module for full connection editing, VPN profiles, and proxy helpers.",
        network_button,
        keywords="advanced network proxy vpn",
    )
    proxy.add_note("Backend not connected yet. These proxy fields describe the NetworkManager and KDE settings that will be wired in later.")
    page.add_section(proxy)
    return page


def _build_shortcuts_page(controller: GuiController) -> BasePage:
    page = BasePage(controller, "Shortcuts", "View and edit keyboard shortcuts from the normal settings layout.")
    section = SettingsSection("Shortcut editor", "KDE remains the source of truth for global and application shortcuts.")
    section.add_row(
        "Search shortcuts",
        "Find a shortcut by name, action, or application.",
        planned_field("", "Search shortcuts..."),
        keywords="search shortcut field",
    )
    section.add_row(
        "Shortcut categories",
        "Switch between global, window, workspace, media, and custom shortcut groups.",
        planned_combo(["Global shortcuts", "App shortcuts", "Window shortcuts", "Workspace shortcuts", "Media shortcuts", "Custom shortcuts"]),
        keywords="shortcut categories global media custom",
    )
    section.add_row(
        "Shortcut table",
        "Shortcut bindings will appear here when the editor backend is connected.",
        _muted_label("Backend not connected yet."),
        keywords="shortcut table bindings",
    )
    keys_button = small_button("Open Global Shortcuts")
    keys_button.clicked.connect(lambda: controller.open_kcm("kcm_keys"))
    section.add_row(
        "Shortcut actions",
        "Use KDE's shortcut editor for live editing, reset, import, and export actions.",
        action_bar(keys_button, planned_button("Import"), planned_button("Export")),
        keywords="shortcuts keys global custom media import export reset",
    )
    page.add_section(section)
    return page


def _build_search_page(controller: GuiController) -> BasePage:
    page = BasePage(controller, "Search", "Control launcher search, file indexing, and search plugins from the normal settings hierarchy.")
    section = SettingsSection("Search tools", "These options will use KDE search and Baloo backends when fully connected.")
    section.add_row(
        "Enable KRunner search",
        "Allow the desktop launcher to search applications, windows, and commands.",
        planned_toggle(checked=True),
        keywords="krunner search enable",
    )
    section.add_row(
        "File indexing",
        "Enable or disable desktop file indexing for fast search results.",
        planned_toggle(checked=True),
        keywords="file indexing baloo",
    )
    section.add_row(
        "Index hidden files",
        "Include hidden folders and dotfiles in search indexes.",
        planned_toggle(),
        keywords="index hidden files search",
    )
    section.add_row(
        "Indexed folders",
        "Folders included in file indexing.",
        _muted_label("/home\n/home/Documents\n/home/Pictures"),
        keywords="indexed folders search",
    )
    section.add_row(
        "Excluded folders",
        "Folders excluded from indexing.",
        _muted_label("No excluded folders configured."),
        keywords="excluded folders search",
    )
    section.add_row(
        "Web shortcuts",
        "Allow KRunner to search the web with configured shortcuts.",
        planned_toggle(checked=True),
        keywords="web shortcuts search",
    )
    krunner_button = small_button("Open Search Settings")
    krunner_button.clicked.connect(lambda: controller.open_kcm("kcm_krunnersettings"))
    indexing_button = small_button("Open File Search")
    indexing_button.clicked.connect(lambda: controller.open_kcm("kcm_baloofile"))
    section.add_row(
        "Advanced search settings",
        "Configure search plugins, indexing behavior, and launcher shortcuts through KDE's search modules.",
        action_bar(krunner_button, indexing_button),
        keywords="search krunner baloo indexing plugins",
    )
    page.add_section(section)
    return page


def _build_region_language_page(controller: GuiController) -> BasePage:
    page = BasePage(controller, "Region & Language", "Change language, region, formats, and time zone behavior from the normal settings hierarchy.")
    section = SettingsSection("Locale overview", "These controls will use KDE locale backends when fully connected.")
    section.add_row("System language", "Choose the primary language for the desktop session.", planned_combo(["English (US)", "Dutch", "German", "French"]), keywords="system language")
    section.add_row("Region", "Choose regional defaults for formats and paper sizes.", planned_combo(["Netherlands", "United States", "Germany", "France"]), keywords="region locale")
    section.add_row("Date format", "Default date formatting used by the desktop shell.", planned_combo(["2026-05-19", "19-05-2026", "May 19, 2026"]), keywords="date format")
    section.add_row("Time format", "12-hour or 24-hour time display.", planned_combo(["24-hour", "12-hour"]), keywords="time format")
    section.add_row("Number format", "Choose decimal and grouping conventions.", planned_combo(["1,234.56", "1.234,56"]), keywords="number format")
    section.add_row("Currency format", "Choose default currency formatting.", planned_combo(["EUR (€)", "USD ($)"]), keywords="currency format")
    section.add_row("Time zone", "Select the desktop time zone.", planned_field("Europe/Amsterdam"), keywords="time zone")
    section.add_row("Spell check language", "Preferred spell-check dictionary.", planned_combo(["English", "Dutch", "German", "French"]), keywords="spell check language")
    lang_button = small_button("Open Language Settings")
    lang_button.clicked.connect(lambda: controller.open_kcm("kcm_regionandlang"))
    section.add_row("Current locale", "Session language exported in the current environment.", QLabel(os.environ.get("LANG", "unavailable")), keywords="locale language")
    section.add_row(
        "Advanced region settings",
        "Open KDE's region and language module for locale packages, formats, and spell-check integration.",
        lang_button,
        keywords="region language locale formats",
    )
    page.add_section(section)
    return page


def _build_date_time_page(controller: GuiController) -> BasePage:
    page = BasePage(controller, "Date & Time", "Set time, date, and timezone behavior while leaving privileged system time changes explicit.")
    section = SettingsSection("Clock configuration", "These controls will use KDE time settings and timedate services when fully connected.")
    section.add_row("Current time", "Current session time reported by the desktop.", QLabel(datetime.now().strftime("%Y-%m-%d %H:%M")), keywords="current time")
    section.add_row("Time zone", "Select the current time zone.", planned_field(os.environ.get("TZ", "Europe/Amsterdam")), keywords="time zone")
    section.add_row("Automatic date & time", "Use network time synchronization when available.", planned_toggle(checked=True), keywords="ntp automatic date time")
    section.add_row("NTP server", "Preferred network time server.", planned_field("pool.ntp.org"), keywords="ntp server")
    section.add_row("24-hour time", "Use 24-hour time in the desktop shell.", planned_toggle(checked=True), keywords="24 hour time")
    section.add_row("Date format preview", "Preview how dates will look with the selected format.", QLabel(datetime.now().strftime("%A %d %B %Y")), keywords="date format preview")
    clock_button = small_button("Open Date & Time Settings")
    clock_button.clicked.connect(lambda: controller.open_kcm("kcm_clock"))
    section.add_row(
        "Advanced date & time",
        "Open KDE's date and time module for timezone, NTP, and display formats.",
        action_bar(clock_button, planned_button("Set Date & Time")),
        keywords="date time timezone ntp clock",
    )
    page.add_section(section)
    return page


def _build_privacy_page(controller: GuiController) -> BasePage:
    page = BasePage(controller, "Privacy & Security", "Control privacy, lock-screen, and app-permission behavior from a focused settings page.")
    section = SettingsSection("Session security", "These controls will use KDE privacy and security backends when fully connected.")
    section.add_row("Screen lock timeout", "Choose how long the system waits before locking the session.", planned_combo(["1 minute", "5 minutes", "10 minutes", "15 minutes"]), keywords="screen lock timeout")
    section.add_row("Lock after sleep", "Lock the session when the system wakes from suspend.", planned_toggle(checked=True), keywords="lock after sleep")
    section.add_row("Recent files history", "Allow apps and shells to remember recently opened files.", planned_toggle(checked=True), keywords="recent files history")
    section.add_row("File search privacy", "Hide private folders from file indexing and search.", planned_toggle(), keywords="file indexing privacy")
    section.add_row("KDE Wallet status", "Wallet integration state for saved desktop credentials.", _muted_label("Wallet status will appear here when the backend is connected."), keywords="wallet security")
    section.add_row("Firewall status", "Current firewall integration state.", _muted_label("Firewall state is not connected in this build."), keywords="firewall status")
    lock_button = small_button("Open Lock Screen Settings")
    lock_button.clicked.connect(lambda: controller.open_kcm("kcm_screenlocker"))
    permissions_button = planned_button("Flatpak Permissions")
    section.add_row(
        "Advanced privacy tools",
        "Open KDE's lock-screen module and future sandbox-permission tools.",
        action_bar(lock_button, permissions_button),
        keywords="privacy security lock screen",
    )
    page.add_section(section)
    return page


class KeskSettingsWindow(QMainWindow):
    page_descriptors = [
        PageDescriptor("quick_settings", "Quick Settings", "Quick Settings", "quick_settings", "Common appearance and workspace controls.", "preferences-desktop-theme-global", "quick settings theme behavior"),
        PageDescriptor("mouse_touchpad", "Mouse & Touchpad", "Input & Output", "input", "Pointer speed, tap-to-click, and natural scrolling.", "input-mouse", "mouse touchpad pointer tap scroll", "touchpad mouse pointer scroll"),
        PageDescriptor("keyboard", "Keyboard", "Input & Output", "input", "Keyboard layout and repeat behavior.", "input-keyboard", "keyboard layout repeat", "keyboard layout repeat"),
        PageDescriptor("game_controller", "Game Controller", "Input & Output", "devices", "Controller support and peripheral handoff.", "input-gaming", "game controller joystick", "game controller joystick calibration vibration"),
        PageDescriptor("sound", "Sound", "Input & Output", "sound", "Volume, default devices, and mute state.", "audio-volume-high", "sound audio volume input output"),
        PageDescriptor("display_monitor", "Display & Monitor", "Input & Output", "display", "Display summary and Night Color.", "video-display", "display monitor night color screen"),
        PageDescriptor("accessibility", "Accessibility", "Input & Output", "accessibility", "Assistive features and high-contrast access.", "preferences-desktop-accessibility", "accessibility assistive"),
        PageDescriptor("disks_cameras", "Disks & Cameras", "Connected Devices", "devices", "Device automount and removable media handoff.", "drive-removable-media", "disks cameras storage removable", "disks cameras storage removable automount camera"),
        PageDescriptor("printers", "Printers", "Connected Devices", "devices", "Printer settings and device modules.", "printer", "printers printing devices", "printers print jobs default printer"),
        PageDescriptor("removable_storage", "Removable Storage", "Connected Devices", "devices", "Removable media and automount behavior.", "drive-removable-media-usb", "removable storage automount usb", "removable storage automount usb media"),
        PageDescriptor("bluetooth", "Bluetooth", "Connected Devices", "bluetooth", "Bluetooth pairing and radio controls.", "preferences-system-bluetooth", "bluetooth pairing radio"),
        PageDescriptor("wifi_internet", "Wi-Fi & Internet", "Networking", "network", "Wi-Fi radio, current network, and hostname.", "network-wireless", "wifi internet hostname wireless"),
        PageDescriptor("online_accounts", "Online Accounts", "Networking", "network_extras", "Cloud and online account handoff.", "im-user-online", "online accounts cloud", "online accounts sync calendar files contacts"),
        PageDescriptor("vpn", "VPN", "Networking", "network_extras", "VPN and advanced network handoff.", "network-vpn", "vpn virtual private network", "vpn connect import auto connect"),
        PageDescriptor("proxy", "Proxy", "Networking", "network_extras", "Proxy and advanced route settings.", "preferences-system-network-proxy", "proxy network", "proxy http https socks pac"),
        PageDescriptor("wallpaper", "Wallpaper", "Appearance & Style", "desktop", "Wallpaper and shell background controls.", "preferences-desktop-wallpaper", "wallpaper background desktop", "wallpaper background"),
        PageDescriptor("colors_themes", "Colors & Themes", "Appearance & Style", "appearance", "Global theme, Plasma style, and color scheme.", "preferences-desktop-theme-global", "appearance colors themes plasma", "theme colors scheme look and feel"),
        PageDescriptor("text_fonts", "Text & Fonts", "Appearance & Style", "appearance", "UI fonts and text rendering choices.", "preferences-desktop-font", "fonts text", "font text dpi antialiasing"),
        PageDescriptor("icons", "Icons", "Appearance & Style", "appearance", "Icon packs and symbolic assets.", "preferences-desktop-icons", "icons theme", "icon theme preview sizes"),
        PageDescriptor("cursors", "Cursors", "Appearance & Style", "appearance", "Pointer theme and cursor visuals.", "input-mouse", "cursor pointer theme", "cursor pointer size preview"),
        PageDescriptor("window_decorations", "Window Decorations", "Appearance & Style", "appearance", "KWin decoration theme selection.", "preferences-system-windows", "window decoration borders", "window decoration titlebar borders"),
        PageDescriptor("splash_screen", "Splash Screen", "Appearance & Style", "boot", "Boot and splash presentation status.", "preferences-desktop-screensaver", "splash boot theme", "splash boot session start"),
        PageDescriptor("login_screen", "Login Screen", "Appearance & Style", "boot", "SDDM login look and behavior.", "preferences-system-login", "login screen sddm", "login sddm user list background"),
        PageDescriptor("default_apps", "Default Applications", "Apps & Windows", "defaults", "Browser, terminal, editor, and file handlers.", "preferences-desktop-default-applications", "default apps browser terminal"),
        PageDescriptor("file_associations", "File Associations", "Apps & Windows", "defaults", "File handler associations and MIME routing.", "text-x-generic", "file associations mime", "file associations mime default app"),
        PageDescriptor("window_behavior", "Window Behavior", "Apps & Windows", "windows", "Focus, compositor, snapping, and animation.", "preferences-system-windows-actions", "window behavior focus compositor"),
        PageDescriptor("task_switcher", "Task Switcher", "Apps & Windows", "windows", "Task switching and window interaction behavior.", "preferences-system-windows-switcher", "task switcher alt tab", "task switcher alt tab minimized desktops"),
        PageDescriptor("shortcuts", "Shortcuts", "Apps & Windows", "shortcuts", "Global, app, and workspace shortcuts.", "preferences-desktop-keyboard-shortcuts", "shortcuts keys media"),
        PageDescriptor("notifications", "Notifications", "Apps & Windows", "notifications", "Notification rules, sounds, and quiet mode.", "preferences-desktop-notification", "notifications alerts", "notifications do not disturb sounds"),
        PageDescriptor("search_tools", "Search", "Apps & Windows", "search_tools", "KRunner, search plugins, and indexing handoff.", "system-search", "search krunner indexing"),
        PageDescriptor("power", "Power Management", "System", "power", "Profile, blanking, and timeout preferences.", "battery", "power battery sleep performance"),
        PageDescriptor("users", "Users", "System", "users", "Current account, avatar, and display name.", "system-users", "users account avatar"),
        PageDescriptor("region_language", "Region & Language", "System", "region_language", "Locale, language, and format handoff.", "preferences-desktop-locale", "region language locale", "language locale region timezone spell check"),
        PageDescriptor("date_time", "Date & Time", "System", "date_time", "Timezone and clock configuration handoff.", "preferences-system-time", "date time timezone", "date time timezone ntp clock"),
        PageDescriptor("privacy_security", "Privacy & Security", "System", "privacy", "Lock screen and privacy-related module access.", "preferences-system-privacy", "privacy security lock screen", "privacy security lock screen wallet firewall"),
        PageDescriptor("boot_login", "Boot & Login", "System", "boot", "Boot splash and login preferences.", "preferences-system-login", "boot login sddm plymouth", "boot login sddm plymouth quiet boot"),
        PageDescriptor("updates", "Updates", "System", "updates", "Update-check policy and notification preferences.", "system-software-update", "updates notifications aur flatpak"),
        PageDescriptor("about_system", "About This System", "System", "about", "KeskOS build, kernel, and system information.", "help-about", "about system version kernel"),
        PageDescriptor("kesk_theme", "KeskOS Theme", "KeskOS", "kesk", "Branded KeskOS theme and accent controls.", "applications-graphics", "keskos theme accent crt", "keskos theme accent crt scanlines glow font"),
        PageDescriptor("panels_launcher", "Panels & Launcher", "KeskOS", "panels", "Panel mode, launcher style, and shell layout.", "view-list-details", "panel launcher quickshell", "panel launcher opacity glow auto hide"),
        PageDescriptor("hud_widgets", "HUD / Widgets", "KeskOS", "panels", "HUD mode and shell widget preferences.", "view-dashboard", "hud widgets quickshell", "quickshell hud panel workspace switcher"),
        PageDescriptor("browser_defaults", "Browser Defaults", "KeskOS", "defaults", "Browser preference and branded homepage routing.", "internet-web-browser", "browser homepage defaults", "browser"),
        PageDescriptor("boot_splash", "Boot Splash", "KeskOS", "boot", "Plymouth status, quiet boot, and splash timing.", "preferences-system-bootloader", "boot splash plymouth quiet", "plymouth boot splash quiet"),
        PageDescriptor("experimental", "Experimental Features", "KeskOS", "kesk", "Experimental KeskOS toggles and internal prefs.", "applications-system", "experimental telemetry keskos", "experimental debug overlay launcher backend quickshell"),
    ]

    page_factories: dict[str, Callable[[GuiController], BasePage]] = {
        "quick_settings": QuickSettingsPage,
        "appearance": AppearancePage,
        "desktop": DesktopPage,
        "panels": PanelsPage,
        "windows": WindowsPage,
        "input": InputPage,
        "display": DisplayPage,
        "sound": SoundPage,
        "network": NetworkPage,
        "power": PowerPage,
        "users": UsersPage,
        "defaults": DefaultsPage,
        "updates": UpdatesPage,
        "boot": BootPage,
        "kesk": KeskPage,
        "about": AboutPage,
        "accessibility": AccessibilityPage,
        "devices": _build_devices_page,
        "bluetooth": BluetoothPage,
        "network_extras": NetworkExtrasPage,
        "shortcuts": _build_shortcuts_page,
        "search_tools": SearchToolsPage,
        "notifications": NotificationsPage,
        "region_language": _build_region_language_page,
        "date_time": _build_date_time_page,
        "privacy": PrivacyPage,
    }

    def __init__(self, controller: GuiController) -> None:
        super().__init__()
        self.controller = controller
        self.controller.set_window(self)
        self._ready = False
        self._shown_once = False
        self._sidebar_collapsed = False
        self._current_descriptor: PageDescriptor | None = None
        self._page_instances: dict[str, BasePage] = {}
        self._page_indices: dict[str, int] = {}
        self._sidebar_buttons: dict[str, SidebarItemButton] = {}
        self._group_labels: dict[str, QLabel] = {}
        self._group_dividers: dict[str, QFrame] = {}
        self._group_buttons: dict[str, list[SidebarItemButton]] = {}

        self.setWindowTitle(APP_TITLE)
        self.setMinimumSize(QSize(1100, 700))
        self.resize(self.controller.prefs.width, self.controller.prefs.height)
        self.setStyleSheet(stylesheet())

        status = QStatusBar()
        self.setStatusBar(status)

        outer = QWidget()
        outer.setObjectName("WindowShell")
        self.setCentralWidget(outer)
        window_layout = QVBoxLayout(outer)
        window_layout.setContentsMargins(0, 0, 0, 0)
        window_layout.setSpacing(0)

        titlebar = QFrame()
        titlebar.setObjectName("TitleBar")
        titlebar_layout = QHBoxLayout(titlebar)
        titlebar_layout.setContentsMargins(14, 10, 14, 10)
        titlebar_layout.setSpacing(10)
        glyph = QLabel(">_")
        glyph.setObjectName("TitleGlyph")
        title_text = QVBoxLayout()
        title_text.setContentsMargins(0, 0, 0, 0)
        title_text.setSpacing(2)
        title_label = QLabel(APP_TITLE)
        title_label.setObjectName("TitleText")
        subtitle_label = QLabel(APP_SUBTITLE)
        subtitle_label.setObjectName("TitleSubtext")
        title_text.addWidget(title_label)
        title_text.addWidget(subtitle_label)
        titlebar_layout.addWidget(glyph)
        titlebar_layout.addLayout(title_text, 1)
        window_layout.addWidget(titlebar)

        shell = QHBoxLayout()
        shell.setContentsMargins(0, 0, 0, 0)
        shell.setSpacing(0)
        window_layout.addLayout(shell, 1)

        self.sidebar = QFrame()
        self.sidebar.setObjectName("SidebarHost")
        self.sidebar.setFixedWidth(292)
        sidebar_layout = QVBoxLayout(self.sidebar)
        sidebar_layout.setContentsMargins(12, 12, 12, 12)
        sidebar_layout.setSpacing(10)

        search_row = QFrame()
        search_row.setObjectName("SidebarSearchRow")
        search_layout = QHBoxLayout(search_row)
        search_layout.setContentsMargins(0, 0, 0, 0)
        search_layout.setSpacing(8)
        self.sidebar_toggle = QToolButton()
        self.sidebar_toggle.setObjectName("SidebarToggle")
        self.sidebar_toggle.setText("≡")
        self.sidebar_toggle.clicked.connect(self._toggle_sidebar)
        self.search_input = QLineEdit()
        self.search_input.setObjectName("SearchInput")
        self.search_input.setPlaceholderText("Search...")
        self.search_input.textChanged.connect(self._apply_search)
        search_layout.addWidget(self.sidebar_toggle)
        search_layout.addWidget(self.search_input, 1)
        sidebar_layout.addWidget(search_row)

        self.sidebar_scroll = QScrollArea()
        self.sidebar_scroll.setWidgetResizable(True)
        sidebar_layout.addWidget(self.sidebar_scroll, 1)
        self.sidebar_scroll_content = QWidget()
        self.sidebar_scroll.setWidget(self.sidebar_scroll_content)
        self.sidebar_scroll_layout = QVBoxLayout(self.sidebar_scroll_content)
        self.sidebar_scroll_layout.setContentsMargins(0, 0, 0, 0)
        self.sidebar_scroll_layout.setSpacing(6)
        self._build_sidebar()
        self.sidebar_scroll_layout.addStretch(1)
        shell.addWidget(self.sidebar)

        self.content_host = QFrame()
        self.content_host.setObjectName("ContentHost")
        content_layout = QVBoxLayout(self.content_host)
        content_layout.setContentsMargins(0, 0, 0, 0)
        content_layout.setSpacing(0)

        header = QFrame()
        header.setObjectName("ContentHeader")
        header_layout = QVBoxLayout(header)
        header_layout.setContentsMargins(24, 20, 24, 18)
        header_layout.setSpacing(8)
        self.content_title = QLabel()
        self.content_title.setObjectName("ContentTitle")
        self.content_subtitle = QLabel()
        self.content_subtitle.setObjectName("ContentSubtitle")
        self.content_subtitle.setWordWrap(True)
        divider = QFrame()
        divider.setObjectName("ContentDivider")
        header_layout.addWidget(self.content_title)
        header_layout.addWidget(self.content_subtitle)
        header_layout.addWidget(divider)
        content_layout.addWidget(header)

        self.stack = QStackedWidget()
        content_layout.addWidget(self.stack, 1)

        bottom_bar = QFrame()
        bottom_bar.setObjectName("BottomBar")
        bottom_layout = QHBoxLayout(bottom_bar)
        bottom_layout.setContentsMargins(24, 10, 24, 10)
        bottom_layout.setSpacing(8)
        self.reset_button = QPushButton("Reset")
        self.reset_button.clicked.connect(self._reset_current_page)
        self.apply_button = QPushButton("Apply")
        self.apply_button.setObjectName("Primary")
        self.apply_button.clicked.connect(self._apply_current_page)
        bottom_layout.addWidget(self.reset_button)
        bottom_layout.addStretch(1)
        bottom_layout.addWidget(self.apply_button)
        content_layout.addWidget(bottom_bar)

        shell.addWidget(self.content_host, 1)

        initial_key = self.controller.prefs.last_page
        if initial_key not in self._sidebar_buttons:
            initial_key = "quick_settings"
        self.select_page(initial_key)
        self._update_sidebar_presentation()
        self._ready = True

    def _build_sidebar(self) -> None:
        current_group = None
        for descriptor in self.page_descriptors:
            if descriptor.group != current_group:
                current_group = descriptor.group
                label = QLabel(_display_text(descriptor.group.upper()))
                label.setObjectName("SidebarGroup")
                divider = QFrame()
                divider.setObjectName("SidebarDivider")
                self.sidebar_scroll_layout.addWidget(label)
                self.sidebar_scroll_layout.addWidget(divider)
                self._group_labels[current_group] = label
                self._group_dividers[current_group] = divider
                self._group_buttons[current_group] = []

            button = SidebarItemButton(descriptor, self.style())
            button.clicked.connect(lambda _checked=False, key=descriptor.key: self.select_page(key))
            self.sidebar_scroll_layout.addWidget(button)
            self._sidebar_buttons[descriptor.key] = button
            self._group_buttons[current_group].append(button)

    def _ensure_page(self, page_id: str) -> BasePage:
        if page_id in self._page_instances:
            return self._page_instances[page_id]

        page = self.page_factories[page_id](self.controller)
        page.dirtyChanged.connect(self._update_bottom_actions)
        self._page_indices[page_id] = self.stack.addWidget(page)
        self._page_instances[page_id] = page
        return page

    def _descriptor(self, key: str) -> PageDescriptor:
        for descriptor in self.page_descriptors:
            if descriptor.key == key:
                return descriptor
        raise KeyError(key)

    def select_page(self, key: str) -> None:
        if key not in self._sidebar_buttons:
            return
        descriptor = self._descriptor(key)
        page = self._ensure_page(descriptor.page_id)
        self._current_descriptor = descriptor
        self.controller.prefs.last_page = key

        for button_key, button in self._sidebar_buttons.items():
            button.setChecked(button_key == key)

        self.content_title.setText(_display_text(descriptor.label))
        self.content_subtitle.setText(descriptor.description)
        self.stack.setCurrentWidget(page)
        page.on_activated()
        self._apply_effective_filter()

        if self._ready:
            self.controller.log(f"page_opened={key}")
        self._update_bottom_actions()

    def _effective_query(self) -> str:
        typed = self.search_input.text().strip()
        if typed:
            return typed
        if self._current_descriptor is not None:
            return self._current_descriptor.focus_query
        return ""

    def _apply_effective_filter(self) -> None:
        current = self.stack.currentWidget()
        if current is None or not isinstance(current, BasePage):
            return
        current.apply_filter(self._effective_query())

    def _descriptor_matches(self, descriptor: PageDescriptor, query: str) -> bool:
        if not query:
            return True
        lowered = query.lower()
        haystack = " ".join([descriptor.label, descriptor.group, descriptor.description, descriptor.keywords, descriptor.focus_query]).lower()
        if lowered in haystack:
            return True
        page = self._page_instances.get(descriptor.page_id)
        if page is not None and page.matches_query(lowered):
            return True
        return False

    def _apply_search(self, text: str) -> None:
        lowered = text.strip().lower()
        first_visible: str | None = None

        for descriptor in self.page_descriptors:
            button = self._sidebar_buttons[descriptor.key]
            visible = self._descriptor_matches(descriptor, lowered)
            button.setVisible(visible)
            if visible and first_visible is None:
                first_visible = descriptor.key

        for group, buttons in self._group_buttons.items():
            visible = any(not button.isHidden() for button in buttons)
            self._group_labels[group].setVisible(visible and not self._sidebar_collapsed)
            self._group_dividers[group].setVisible(visible and not self._sidebar_collapsed)

        if self._current_descriptor is None or self._sidebar_buttons[self._current_descriptor.key].isHidden():
            if first_visible is not None:
                self.select_page(first_visible)
        else:
            self._apply_effective_filter()

    def _toggle_sidebar(self) -> None:
        self._sidebar_collapsed = not self._sidebar_collapsed
        self._update_sidebar_presentation()

    def _update_sidebar_presentation(self) -> None:
        self.sidebar.setFixedWidth(84 if self._sidebar_collapsed else 292)
        self.search_input.setVisible(not self._sidebar_collapsed)
        for button in self._sidebar_buttons.values():
            button.set_collapsed(self._sidebar_collapsed)
        for group, label in self._group_labels.items():
            visible = any(not button.isHidden() for button in self._group_buttons[group]) and not self._sidebar_collapsed
            label.setVisible(visible)
            self._group_dividers[group].setVisible(visible)

    def _update_bottom_actions(self, *_args) -> None:
        current = self.stack.currentWidget()
        if current is None or not isinstance(current, BasePage):
            self.apply_button.setEnabled(False)
            self.reset_button.setEnabled(False)
            return

        enabled = current.can_apply() and current.is_dirty()
        self.apply_button.setEnabled(enabled)
        self.reset_button.setEnabled(current.can_reset() and current.is_dirty())

    def _apply_current_page(self) -> None:
        current = self.stack.currentWidget()
        if current is None or not isinstance(current, BasePage):
            return
        apply_handler = getattr(current, "apply_changes", None)
        if callable(apply_handler):
            apply_handler()
            self._update_bottom_actions()

    def _reset_current_page(self) -> None:
        current = self.stack.currentWidget()
        if current is None or not isinstance(current, BasePage):
            return
        reset_handler = getattr(current, "load_state", None)
        if callable(reset_handler):
            reset_handler()
            self._apply_effective_filter()
            self._update_bottom_actions()

    def showEvent(self, event) -> None:  # noqa: N802
        super().showEvent(event)
        if self._shown_once:
            return
        self._shown_once = True
        if self._current_descriptor is not None:
            self.controller.log(f"page_opened={self._current_descriptor.key}")

    def closeEvent(self, event) -> None:  # noqa: N802
        self.controller.prefs.width = self.width()
        self.controller.prefs.height = self.height()
        save_prefs(self.controller.paths.ui_state_path, self.controller.prefs)
        self.controller.close()
        super().closeEvent(event)


def build_application(root: Path) -> tuple[QApplication, KeskSettingsWindow]:
    app = QApplication.instance() or QApplication([])
    app.setApplicationName("Kesk Settings")
    app.setOrganizationName("KeskOS")
    window = KeskSettingsWindow(GuiController(root))
    return app, window
