#!/usr/bin/env python3
from __future__ import annotations

import argparse
import fcntl
import logging
import os
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path

APP_DIR = Path(__file__).resolve().parent
if str(APP_DIR) not in sys.path:
    sys.path.insert(0, str(APP_DIR))

from PySide6.QtCore import QObject, QProcess, QRunnable, QThreadPool, QTimer, Qt, Signal
from PySide6.QtGui import QColor, QCloseEvent, QFont, QKeySequence, QPainter, QPen, QShortcut
from PySide6.QtWidgets import (
    QApplication,
    QAbstractItemView,
    QCheckBox,
    QFrame,
    QGridLayout,
    QHBoxLayout,
    QHeaderView,
    QLabel,
    QLineEdit,
    QMainWindow,
    QMessageBox,
    QPushButton,
    QPlainTextEdit,
    QStackedWidget,
    QTreeWidget,
    QTreeWidgetItem,
    QVBoxLayout,
    QWidget,
)

from backend import browser_setup, pacman_backend, state, theme_apply
from package_presets import CATEGORY_ORDER, PRESET_CATEGORIES

ACCENT = "#ce6a35"
BACKGROUND = "#050505"
PANEL = "#080706"
SECTION = "#11100e"
TEXT = "#b8afa6"
DIM = "#8f8a84"
HOVER = "rgba(206,106,53,0.16)"
ACTIVE = "rgba(206,106,53,0.22)"
LOCK_FILE = state.LOG_DIR / "first-run.lock"
_LOCK_HANDLE = None

APP_STYLE = f"""
QWidget {{
  background: {BACKGROUND};
  color: {TEXT};
  font-family: "JetBrains Mono Nerd Font", "JetBrains Mono", "Iosevka", monospace;
  font-size: 11pt;
}}
QMainWindow {{
  background: {BACKGROUND};
}}
QFrame#sidebarPanel,
QFrame#contentPanel,
QFrame#cardPanel,
QFrame#debugPanel,
QFrame#statusPanel,
QFrame#blockPanel {{
  background: {PANEL};
  border: 1px solid {ACCENT};
  border-radius: 0px;
}}
QFrame#sectionPanel,
QPlainTextEdit,
QLineEdit,
QTreeWidget,
QListWidget,
QScrollArea {{
  background: {SECTION};
  border: 1px solid {ACCENT};
  border-radius: 0px;
}}
QPlainTextEdit,
QTreeWidget,
QListWidget,
QLineEdit {{
  selection-background-color: {ACTIVE};
  selection-color: {TEXT};
}}
QPushButton {{
  background: {SECTION};
  border: 1px solid {ACCENT};
  color: {TEXT};
  padding: 10px 14px;
  border-radius: 0px;
  text-transform: uppercase;
}}
QPushButton:hover {{
  background: {HOVER};
}}
QPushButton:checked {{
  background: {ACTIVE};
}}
QPushButton:disabled {{
  color: {DIM};
  border-color: #5e3a24;
  background: #0b0a09;
}}
QPushButton#primaryButton {{
  background: rgba(206,106,53,0.12);
}}
QPushButton#dangerButton {{
  border-color: #d07d52;
  background: rgba(206,106,53,0.08);
}}
QLabel#titleLabel {{
  color: {ACCENT};
  font-size: 22pt;
  font-weight: 700;
}}
QLabel#subtitleLabel {{
  color: {DIM};
  font-size: 11pt;
}}
QLabel#sectionLabel,
QLabel#stepLabel {{
  color: {ACCENT};
  font-size: 10pt;
  font-weight: 700;
}}
QLabel#dimLabel {{
  color: {DIM};
}}
QLabel#stepInactive {{
  color: {DIM};
  padding: 6px 0px;
}}
QLabel#stepActive {{
  color: {ACCENT};
  padding: 6px 0px;
}}
QLabel#stepDone {{
  color: {TEXT};
  padding: 6px 0px;
}}
QFrame#browserCard {{
  background: {SECTION};
  border: 1px solid #3f2618;
  border-radius: 0px;
}}
QFrame#browserCard[selected="true"] {{
  background: {ACTIVE};
  border: 1px solid {ACCENT};
}}
QHeaderView::section {{
  background: {PANEL};
  color: {ACCENT};
  border: 1px solid {ACCENT};
  padding: 6px;
}}
QTreeWidget::item {{
  padding: 6px 4px;
}}
QTreeWidget::item:selected {{
  background: {ACTIVE};
}}
QLineEdit {{
  padding: 8px;
}}
QCheckBox {{
  spacing: 8px;
}}
QCheckBox::indicator {{
  width: 14px;
  height: 14px;
  border: 1px solid {ACCENT};
  background: {BACKGROUND};
}}
QCheckBox::indicator:checked {{
  background: {ACCENT};
}}
"""


class WorkerSignals(QObject):
    finished = Signal(int, object, object)


class FunctionWorker(QRunnable):
    def __init__(self, request_id: int, fn, *args, **kwargs) -> None:
        super().__init__()
        self.request_id = request_id
        self.fn = fn
        self.args = args
        self.kwargs = kwargs
        self.signals = WorkerSignals()

    def run(self) -> None:
        try:
            result = self.fn(*self.args, **self.kwargs)
            error = None
        except Exception as exc:  # pragma: no cover - defensive
            result = None
            error = exc
        self.signals.finished.emit(self.request_id, result, error)


class BrowserCard(QFrame):
    clicked = Signal(str)

    def __init__(self, option: browser_setup.BrowserOption) -> None:
        super().__init__()
        self.option = option
        self.setObjectName("browserCard")
        self.setProperty("selected", False)
        self.setCursor(Qt.PointingHandCursor)

        layout = QVBoxLayout(self)
        layout.setContentsMargins(16, 16, 16, 16)
        layout.setSpacing(8)

        name = QLabel(option.label)
        name.setObjectName("sectionLabel")
        description = QLabel(option.description)
        description.setWordWrap(True)
        note = QLabel(option.note)
        note.setObjectName("dimLabel")
        note.setWordWrap(True)
        self.status_label = QLabel("Checking package status...")
        self.status_label.setObjectName("dimLabel")
        self.status_label.setWordWrap(True)

        layout.addWidget(name)
        layout.addWidget(description)
        layout.addWidget(note)
        layout.addStretch(1)
        layout.addWidget(self.status_label)

    def set_selected(self, selected: bool) -> None:
        self.setProperty("selected", selected)
        self.style().unpolish(self)
        self.style().polish(self)

    def set_status(self, text: str) -> None:
        self.status_label.setText(text)

    def mousePressEvent(self, event) -> None:  # noqa: N802
        if event.button() == Qt.MouseButton.LeftButton:
            self.clicked.emit(self.option.key)
        super().mousePressEvent(event)


class SetupConsole(QMainWindow):
    def __init__(self) -> None:
        super().__init__()
        state.ensure_state_dirs()
        self.logger = self._build_logger()
        self.logger.info("setup console started")

        self.thread_pool = QThreadPool.globalInstance()
        self.search_request_id = 0
        self.preset_request_id = 0
        self.selected_browser_key = ""
        self.selected_browser_package = ""
        self.theme_status_headline = "PENDING"
        self.theme_status_details: list[str] = []
        self.browser_setup_summary: list[str] = []
        self.selected_packages: dict[str, dict[str, str]] = {}
        self.package_install_success: list[str] = []
        self.package_install_failed: list[str] = []
        self.browser_install_failed = False
        self.allow_close = False
        self.current_category = CATEGORY_ORDER[0]
        self._syncing_items = False
        self.install_context = ""
        self.install_targets: list[str] = []
        self.install_command: list[str] = []
        self.process: QProcess | None = None

        self.setWindowTitle("KeskOS Setup Console")
        self.setWindowFlag(Qt.WindowCloseButtonHint, False)
        self.setWindowFlag(Qt.WindowContextHelpButtonHint, False)
        self.resize(1360, 860)
        self.setMinimumSize(1220, 760)

        self.search_timer = QTimer(self)
        self.search_timer.setSingleShot(True)
        self.search_timer.setInterval(420)
        self.search_timer.timeout.connect(self.perform_search)

        self._build_ui()
        self._configure_shortcuts()
        self.refresh_network_status()
        self.refresh_browser_cards()
        self.load_preset_category(self.current_category)
        self.go_to_step(0)

    def _build_logger(self) -> logging.Logger:
        logger = logging.getLogger("keskos-first-run")
        logger.setLevel(logging.INFO)
        if not logger.handlers:
            handler = logging.FileHandler(state.LOG_FILE, encoding="utf-8")
            handler.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(message)s"))
            logger.addHandler(handler)
        return logger

    def _configure_shortcuts(self) -> None:
        QShortcut(QKeySequence("Esc"), self, activated=self.show_blocked_close_warning)
        QShortcut(QKeySequence("Ctrl+Shift+D"), self, activated=self.toggle_debug_panel)

    def _build_ui(self) -> None:
        central = QWidget()
        root_layout = QHBoxLayout(central)
        root_layout.setContentsMargins(18, 18, 18, 18)
        root_layout.setSpacing(18)
        self.setCentralWidget(central)

        root_layout.addWidget(self._build_sidebar())

        right_column = QVBoxLayout()
        right_column.setSpacing(12)
        root_layout.addLayout(right_column, 1)

        self.content_panel = QFrame()
        self.content_panel.setObjectName("contentPanel")
        content_layout = QVBoxLayout(self.content_panel)
        content_layout.setContentsMargins(18, 18, 18, 18)
        content_layout.setSpacing(16)
        right_column.addWidget(self.content_panel, 1)

        self.page_stack = QStackedWidget()
        content_layout.addWidget(self.page_stack, 1)

        self.page_stack.addWidget(self._build_welcome_page())
        self.page_stack.addWidget(self._build_browser_page())
        self.page_stack.addWidget(self._build_theme_page())
        self.page_stack.addWidget(self._build_packages_page())
        self.page_stack.addWidget(self._build_complete_page())

        self.debug_panel = QFrame()
        self.debug_panel.setObjectName("debugPanel")
        self.debug_panel.setVisible(False)
        debug_layout = QHBoxLayout(self.debug_panel)
        debug_layout.setContentsMargins(14, 12, 14, 12)
        debug_layout.setSpacing(10)
        debug_label = QLabel("DEBUG CHANNEL OPEN // RECOVERY CONTROLS")
        debug_label.setObjectName("sectionLabel")
        self.debug_status = QLabel("Use only if the setup cannot proceed normally.")
        self.debug_status.setObjectName("dimLabel")
        open_terminal = self._make_button("Open Terminal", self.open_terminal)
        view_logs = self._make_button("View Logs", self.view_logs)
        skip_button = self._make_button("Emergency Skip", self.confirm_emergency_skip)
        skip_button.setObjectName("dangerButton")
        debug_layout.addWidget(debug_label)
        debug_layout.addWidget(self.debug_status, 1)
        debug_layout.addWidget(open_terminal)
        debug_layout.addWidget(view_logs)
        debug_layout.addWidget(skip_button)
        right_column.addWidget(self.debug_panel)

    def _build_sidebar(self) -> QWidget:
        panel = QFrame()
        panel.setObjectName("sidebarPanel")
        panel.setFixedWidth(280)
        layout = QVBoxLayout(panel)
        layout.setContentsMargins(18, 20, 18, 20)
        layout.setSpacing(14)

        logo = QLabel("KESKOS SETUP CONSOLE")
        logo.setObjectName("titleLabel")
        logo.setWordWrap(True)
        sub = QLabel("FIRST BOOT PERSONALIZATION REQUIRED")
        sub.setObjectName("subtitleLabel")
        sub.setWordWrap(True)
        layout.addWidget(logo)
        layout.addWidget(sub)

        step_box = QFrame()
        step_box.setObjectName("sectionPanel")
        step_layout = QVBoxLayout(step_box)
        step_layout.setContentsMargins(14, 14, 14, 14)
        step_layout.setSpacing(6)
        layout.addWidget(step_box)

        self.step_labels: list[QLabel] = []
        for label_text in (
            "01 WELCOME",
            "02 BROWSER",
            "03 THEME",
            "04 PACKAGES",
            "05 COMPLETE",
        ):
            label = QLabel(label_text)
            label.setObjectName("stepInactive")
            self.step_labels.append(label)
            step_layout.addWidget(label)

        self.sidebar_network = QLabel("NETWORK // CHECKING")
        self.sidebar_network.setObjectName("dimLabel")
        self.sidebar_hint = QLabel("CTRL+SHIFT+D unlocks recovery tools.")
        self.sidebar_hint.setObjectName("dimLabel")
        self.sidebar_hint.setVisible(False)
        layout.addStretch(1)
        layout.addWidget(self.sidebar_network)
        layout.addWidget(self.sidebar_hint)
        return panel

    def _build_page_header(self, title: str, subtitle: str) -> QWidget:
        container = QWidget()
        layout = QVBoxLayout(container)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(4)
        title_label = QLabel(title)
        title_label.setObjectName("titleLabel")
        subtitle_label = QLabel(subtitle)
        subtitle_label.setObjectName("subtitleLabel")
        subtitle_label.setWordWrap(True)
        layout.addWidget(title_label)
        layout.addWidget(subtitle_label)
        return container

    def _build_welcome_page(self) -> QWidget:
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setSpacing(18)
        layout.addWidget(
            self._build_page_header(
                "KESKOS SETUP CONSOLE",
                "KeskOS has completed installation. Before entering the desktop, choose your browser and optional system packages.",
            )
        )

        block = QFrame()
        block.setObjectName("cardPanel")
        block_layout = QVBoxLayout(block)
        block_layout.setContentsMargins(18, 18, 18, 18)
        block_layout.setSpacing(14)

        labels = (
            "WELCOME // FIRST BOOT DETECTED",
            "BROWSER // SELECT ONE BASE BROWSER",
            "THEME // APPLY LOCAL STARTPAGE + BROWSER CUSTOMIZATION",
            "PACKAGES // OPTIONAL EXTRA SOFTWARE INSTALL",
            "COMPLETE // COMMIT STATE AND ENTER DESKTOP",
        )
        for text in labels:
            label = QLabel(text)
            label.setWordWrap(True)
            block_layout.addWidget(label)

        begin_button = self._make_button("Begin Setup", lambda: self.go_to_step(1), primary=True)
        block_layout.addSpacing(8)
        block_layout.addWidget(begin_button, 0, Qt.AlignLeft)

        layout.addWidget(block)
        layout.addStretch(1)
        return page

    def _build_browser_page(self) -> QWidget:
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setSpacing(14)
        layout.addWidget(
            self._build_page_header(
                "BROWSER SELECTION",
                "Choose one primary browser. KeskOS will install it if available, set it as default where possible, and prepare the local startpage profile.",
            )
        )

        status_panel = QFrame()
        status_panel.setObjectName("statusPanel")
        status_layout = QHBoxLayout(status_panel)
        status_layout.setContentsMargins(14, 12, 14, 12)
        self.browser_network_label = QLabel("NETWORK LINK // CHECKING")
        self.browser_network_label.setObjectName("sectionLabel")
        self.browser_network_detail = QLabel("Repository availability is being probed.")
        self.browser_network_detail.setObjectName("dimLabel")
        retry_button = self._make_button("Retry", self.refresh_network_status)
        network_button = self._make_button("Open Network Settings", self.open_network_settings)
        status_layout.addWidget(self.browser_network_label)
        status_layout.addWidget(self.browser_network_detail, 1)
        status_layout.addWidget(retry_button)
        status_layout.addWidget(network_button)
        layout.addWidget(status_panel)

        cards = QWidget()
        cards_layout = QGridLayout(cards)
        cards_layout.setSpacing(14)
        self.browser_cards: dict[str, BrowserCard] = {}
        for index, option in enumerate(browser_setup.BROWSERS):
            card = BrowserCard(option)
            card.clicked.connect(self.select_browser)
            self.browser_cards[option.key] = card
            cards_layout.addWidget(card, index // 2, index % 2)
        layout.addWidget(cards)

        button_row = QHBoxLayout()
        button_row.addStretch(1)
        back_button = self._make_button("Back", lambda: self.go_to_step(0))
        self.browser_continue_button = self._make_button("Continue", lambda: self.go_to_step(2), primary=True)
        self.browser_continue_button.setEnabled(False)
        button_row.addWidget(back_button)
        button_row.addWidget(self.browser_continue_button)
        layout.addLayout(button_row)
        return page

    def _build_theme_page(self) -> QWidget:
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setSpacing(14)
        layout.addWidget(
            self._build_page_header(
                "BROWSER INSTALL // THEME APPLY",
                "Install the selected browser, apply the local KeskOS startpage, and attempt browser-specific black/orange profile customization.",
            )
        )

        info_panel = QFrame()
        info_panel.setObjectName("sectionPanel")
        info_layout = QVBoxLayout(info_panel)
        info_layout.setContentsMargins(16, 16, 16, 16)
        info_layout.setSpacing(8)
        self.theme_browser_label = QLabel("SELECTED BROWSER // NONE")
        self.theme_browser_label.setObjectName("sectionLabel")
        self.theme_package_label = QLabel("PACKAGE // PENDING")
        self.theme_package_label.setObjectName("dimLabel")
        self.theme_headline = QLabel("STATUS // WAITING")
        self.theme_headline.setObjectName("sectionLabel")
        self.theme_detail = QLabel("Choose a browser on the previous step to begin installation and theme application.")
        self.theme_detail.setObjectName("dimLabel")
        self.theme_detail.setWordWrap(True)
        info_layout.addWidget(self.theme_browser_label)
        info_layout.addWidget(self.theme_package_label)
        info_layout.addWidget(self.theme_headline)
        info_layout.addWidget(self.theme_detail)
        layout.addWidget(info_panel)

        self.theme_log = QPlainTextEdit()
        self.theme_log.setReadOnly(True)
        self.theme_log.setPlaceholderText("Install and theme logs will appear here...")
        self.theme_log.setMinimumHeight(260)
        layout.addWidget(self.theme_log, 1)

        button_row = QHBoxLayout()
        self.theme_back_button = self._make_button("Back", lambda: self.go_to_step(1))
        self.theme_retry_network = self._make_button("Retry Network", self.refresh_network_status)
        self.theme_open_network = self._make_button("Open Network Settings", self.open_network_settings)
        self.theme_run_button = self._make_button("Install and Apply", self.start_browser_setup, primary=True)
        self.theme_continue_button = self._make_button("Continue", lambda: self.go_to_step(3), primary=True)
        self.theme_continue_button.setEnabled(False)
        button_row.addWidget(self.theme_back_button)
        button_row.addWidget(self.theme_retry_network)
        button_row.addWidget(self.theme_open_network)
        button_row.addStretch(1)
        button_row.addWidget(self.theme_run_button)
        button_row.addWidget(self.theme_continue_button)
        layout.addLayout(button_row)
        return page

    def _build_packages_page(self) -> QWidget:
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setSpacing(14)
        layout.addWidget(
            self._build_page_header(
                "OPTIONAL PACKAGE INSTALLER",
                "Search the Arch repositories, browse KeskOS preset categories, queue packages, and install them with pkexec-backed pacman actions.",
            )
        )

        category_row = QHBoxLayout()
        self.category_buttons: dict[str, QPushButton] = {}
        for category in CATEGORY_ORDER:
            button = self._make_button(category, lambda checked=False, c=category: self.load_preset_category(c))
            button.setCheckable(True)
            self.category_buttons[category] = button
            category_row.addWidget(button)
        category_row.addStretch(1)
        layout.addLayout(category_row)

        split = QHBoxLayout()
        split.setSpacing(14)
        layout.addLayout(split, 1)

        left_column = QVBoxLayout()
        left_column.setSpacing(12)
        split.addLayout(left_column, 3)

        preset_panel = QFrame()
        preset_panel.setObjectName("sectionPanel")
        preset_layout = QVBoxLayout(preset_panel)
        preset_layout.setContentsMargins(12, 12, 12, 12)
        preset_title = QLabel("CATEGORY PRESETS")
        preset_title.setObjectName("sectionLabel")
        self.preset_tree = QTreeWidget()
        self.preset_tree.setHeaderLabels(["Package", "Status", "Description"])
        self.preset_tree.header().setSectionResizeMode(0, QHeaderView.ResizeToContents)
        self.preset_tree.header().setSectionResizeMode(1, QHeaderView.ResizeToContents)
        self.preset_tree.header().setSectionResizeMode(2, QHeaderView.Stretch)
        self.preset_tree.setRootIsDecorated(False)
        self.preset_tree.itemChanged.connect(self.handle_tree_item_changed)
        preset_layout.addWidget(preset_title)
        preset_layout.addWidget(self.preset_tree)
        left_column.addWidget(preset_panel, 1)

        search_panel = QFrame()
        search_panel.setObjectName("sectionPanel")
        search_layout = QVBoxLayout(search_panel)
        search_layout.setContentsMargins(12, 12, 12, 12)
        search_title = QLabel("SEARCH ARCH PACKAGES")
        search_title.setObjectName("sectionLabel")
        self.search_input = QLineEdit()
        self.search_input.setPlaceholderText("Search Arch packages...")
        self.search_input.textChanged.connect(self.queue_search)
        self.search_status = QLabel("Type a query to search the enabled pacman repositories.")
        self.search_status.setObjectName("dimLabel")
        self.search_tree = QTreeWidget()
        self.search_tree.setHeaderLabels(["Package", "Repo", "Version", "Status", "Description"])
        self.search_tree.header().setSectionResizeMode(0, QHeaderView.ResizeToContents)
        self.search_tree.header().setSectionResizeMode(1, QHeaderView.ResizeToContents)
        self.search_tree.header().setSectionResizeMode(2, QHeaderView.ResizeToContents)
        self.search_tree.header().setSectionResizeMode(3, QHeaderView.ResizeToContents)
        self.search_tree.header().setSectionResizeMode(4, QHeaderView.Stretch)
        self.search_tree.setRootIsDecorated(False)
        self.search_tree.itemChanged.connect(self.handle_tree_item_changed)
        search_layout.addWidget(search_title)
        search_layout.addWidget(self.search_input)
        search_layout.addWidget(self.search_status)
        search_layout.addWidget(self.search_tree, 1)
        left_column.addWidget(search_panel, 1)

        right_column = QVBoxLayout()
        right_column.setSpacing(12)
        split.addLayout(right_column, 2)

        queue_panel = QFrame()
        queue_panel.setObjectName("sectionPanel")
        queue_layout = QVBoxLayout(queue_panel)
        queue_layout.setContentsMargins(12, 12, 12, 12)
        queue_title = QLabel("INSTALL QUEUE")
        queue_title.setObjectName("sectionLabel")
        self.queue_list = QTreeWidget()
        self.queue_list.setHeaderLabels(["Package", "Source"])
        self.queue_list.header().setSectionResizeMode(0, QHeaderView.Stretch)
        self.queue_list.header().setSectionResizeMode(1, QHeaderView.ResizeToContents)
        self.queue_list.setRootIsDecorated(False)
        self.queue_list.setSelectionMode(QAbstractItemView.NoSelection)
        self.package_refresh_check = QCheckBox("Refresh pacman sync databases before install")
        queue_layout.addWidget(queue_title)
        queue_layout.addWidget(self.queue_list, 1)
        queue_layout.addWidget(self.package_refresh_check)
        right_column.addWidget(queue_panel, 1)

        install_panel = QFrame()
        install_panel.setObjectName("sectionPanel")
        install_layout = QVBoxLayout(install_panel)
        install_layout.setContentsMargins(12, 12, 12, 12)
        install_title = QLabel("INSTALL LOG")
        install_title.setObjectName("sectionLabel")
        self.package_summary = QLabel("Select packages from presets or search results to build the install queue.")
        self.package_summary.setObjectName("dimLabel")
        self.package_summary.setWordWrap(True)
        self.package_log = QPlainTextEdit()
        self.package_log.setReadOnly(True)
        self.package_log.setPlaceholderText("Package install output will appear here...")
        self.package_log.setMinimumHeight(220)
        install_layout.addWidget(install_title)
        install_layout.addWidget(self.package_summary)
        install_layout.addWidget(self.package_log, 1)
        right_column.addWidget(install_panel, 1)

        button_row = QHBoxLayout()
        button_row.addWidget(self._make_button("Back", lambda: self.go_to_step(2)))
        button_row.addStretch(1)
        self.package_install_button = self._make_button("Install Selected", self.start_package_install, primary=True)
        self.package_install_button.setEnabled(False)
        self.package_continue_button = self._make_button("Continue", self.finalize_summary_and_continue, primary=True)
        button_row.addWidget(self.package_install_button)
        button_row.addWidget(self.package_continue_button)
        layout.addLayout(button_row)
        return page

    def _build_complete_page(self) -> QWidget:
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setSpacing(16)
        layout.addWidget(
            self._build_page_header(
                "KESKOS SETUP COMPLETE",
                "The first-run setup has finished. Review the summary below, then commit the state file and enter the desktop.",
            )
        )

        summary_panel = QFrame()
        summary_panel.setObjectName("cardPanel")
        summary_layout = QVBoxLayout(summary_panel)
        summary_layout.setContentsMargins(16, 16, 16, 16)
        summary_layout.setSpacing(10)
        self.complete_summary = QPlainTextEdit()
        self.complete_summary.setReadOnly(True)
        self.complete_summary.setMinimumHeight(360)
        summary_layout.addWidget(self.complete_summary)
        layout.addWidget(summary_panel, 1)

        button_row = QHBoxLayout()
        button_row.addStretch(1)
        enter_button = self._make_button("Enter Desktop", self.complete_and_exit, primary=True)
        button_row.addWidget(enter_button)
        layout.addLayout(button_row)
        return page

    def _make_button(self, text: str, slot, primary: bool = False) -> QPushButton:
        button = QPushButton(text.upper())
        if primary:
            button.setObjectName("primaryButton")
        button.clicked.connect(slot)
        return button

    def refresh_network_status(self) -> None:
        online = pacman_backend.internet_available()
        if online:
            title = "NETWORK LINK // AVAILABLE"
            detail = "Remote package repositories should be reachable."
            sidebar = "NETWORK // ONLINE"
        else:
            title = "NETWORK LINK // UNAVAILABLE"
            detail = "Package installs may fail. Retry, open network settings, or use the emergency skip path."
            sidebar = "NETWORK // OFFLINE"

        self.browser_network_label.setText(title)
        self.browser_network_detail.setText(detail)
        self.sidebar_network.setText(sidebar)
        self.logger.info("network status online=%s", online)

    def refresh_browser_cards(self) -> None:
        for option in browser_setup.BROWSERS:
            status, _ = browser_setup.browser_status(option)
            self.browser_cards[option.key].set_status(status)

    def select_browser(self, key: str) -> None:
        self.selected_browser_key = key
        for browser_key, card in self.browser_cards.items():
            card.set_selected(browser_key == key)
        self.browser_continue_button.setEnabled(True)
        option = browser_setup.get_browser_option(key)
        if option:
            package_name = browser_setup.resolve_browser_package(option) or "UNAVAILABLE"
            self.selected_browser_package = package_name
            self.theme_browser_label.setText(f"SELECTED BROWSER // {option.label.upper()}")
            self.theme_package_label.setText(f"PACKAGE // {package_name}")
            self.theme_headline.setText("STATUS // READY")
            self.theme_detail.setText("Install and apply the browser theme when you continue to the next step.")
            self.theme_continue_button.setEnabled(False)
            self.theme_log.clear()
            self.logger.info("browser selected key=%s package=%s", key, package_name)

    def go_to_step(self, index: int) -> None:
        if index == 2 and not self.selected_browser_key:
            index = 1
        self.page_stack.setCurrentIndex(index)
        for idx, label in enumerate(self.step_labels):
            if idx < index:
                label.setObjectName("stepDone")
            elif idx == index:
                label.setObjectName("stepActive")
            else:
                label.setObjectName("stepInactive")
            label.style().unpolish(label)
            label.style().polish(label)

        if index == 4:
            self.update_complete_summary()

    def start_browser_setup(self) -> None:
        option = browser_setup.get_browser_option(self.selected_browser_key)
        if option is None:
            self.show_status_dialog("NO BROWSER SELECTED", "Select a browser before attempting installation.")
            return

        self.theme_log.clear()
        self.theme_continue_button.setEnabled(False)
        self.browser_install_failed = False
        self.browser_setup_summary = []
        package_name = browser_setup.resolve_browser_package(option)
        self.selected_browser_package = package_name or ""
        self.logger.info("browser setup started key=%s package=%s", option.key, package_name)

        if not package_name:
            self.browser_install_failed = True
            self.theme_status_headline = "THEME PARTIALLY APPLIED"
            self.theme_status_details = ["Selected browser package was not found in the configured pacman repositories."]
            self.theme_headline.setText(f"STATUS // {self.theme_status_headline}")
            self.theme_detail.setText(self.theme_status_details[0])
            self.theme_log.appendPlainText("Selected browser package is unavailable in the current repositories.")
            self.theme_continue_button.setEnabled(True)
            return

        self.theme_package_label.setText(f"PACKAGE // {package_name}")

        if pacman_backend.is_installed(package_name):
            self.theme_log.appendPlainText(f"{package_name} is already installed. Applying default browser + theme steps.")
            self.finish_browser_setup(option)
            return

        if not pacman_backend.internet_available():
            self.browser_install_failed = True
            self.theme_status_headline = "NETWORK LINK UNAVAILABLE"
            self.theme_status_details = [
                "The selected browser is not installed and the network appears offline. Open Network Settings, retry later, or use the emergency skip path.",
            ]
            self.theme_headline.setText(f"STATUS // {self.theme_status_headline}")
            self.theme_detail.setText(self.theme_status_details[0])
            self.theme_log.appendPlainText("Network unavailable. Browser install was not started.")
            self.theme_continue_button.setEnabled(True)
            return

        self.start_install_process("browser", [package_name], self.theme_log, refresh_db=False)

    def finish_browser_setup(self, option: browser_setup.BrowserOption) -> None:
        default_ok, default_details = browser_setup.set_default_browser(option, self.logger)
        result = theme_apply.apply_browser_theme(option)

        self.browser_setup_summary = default_details
        self.theme_status_headline = result.headline
        self.theme_status_details = result.details
        self.theme_headline.setText(f"STATUS // {result.headline}")
        self.theme_detail.setText(result.details[0] if result.details else "No theme details available.")
        for line in default_details:
            self.theme_log.appendPlainText(f"[default browser] {line}")
        for line in result.details:
            self.theme_log.appendPlainText(f"[theme] {line}")
        self.theme_continue_button.setEnabled(True)
        self.logger.info(
            "browser setup complete key=%s default_ok=%s theme_status=%s",
            option.key,
            default_ok,
            result.status,
        )

    def queue_search(self) -> None:
        self.search_timer.start()

    def perform_search(self) -> None:
        query = self.search_input.text().strip()
        if not query:
            self.search_tree.clear()
            self.search_status.setText("Type a query to search the enabled pacman repositories.")
            return
        self.search_status.setText("Searching pacman repositories...")
        self.search_request_id += 1
        worker = FunctionWorker(self.search_request_id, pacman_backend.search_packages, query)
        worker.signals.finished.connect(self.handle_search_results)
        self.thread_pool.start(worker)

    def handle_search_results(self, request_id: int, result, error) -> None:
        if request_id != self.search_request_id:
            return
        if error:
            self.search_status.setText(f"Search failed: {error}")
            return

        packages, backend_error = result
        if backend_error:
            self.search_status.setText(backend_error)
            return

        self._syncing_items = True
        self.search_tree.clear()
        for package in packages:
            item = QTreeWidgetItem(
                [
                    package.name,
                    package.repo,
                    package.version,
                    "INSTALLED" if package.installed else "AVAILABLE",
                    package.description,
                ]
            )
            item.setData(0, Qt.UserRole, ("search", package.name, package.description))
            item.setFlags(item.flags() | Qt.ItemIsUserCheckable)
            item.setCheckState(0, Qt.Checked if package.name in self.selected_packages else Qt.Unchecked)
            self.search_tree.addTopLevelItem(item)
        self._syncing_items = False

        if packages:
            self.search_status.setText(f"Found {len(packages)} package result(s).")
        else:
            self.search_status.setText("No matching packages were found.")

    def load_preset_category(self, category: str) -> None:
        self.current_category = category
        for name, button in self.category_buttons.items():
            button.setChecked(name == category)

        self.preset_request_id += 1
        self.package_summary.setText(f"Loading preset metadata for {category}...")
        worker = FunctionWorker(
            self.preset_request_id,
            pacman_backend.inspect_packages,
            PRESET_CATEGORIES[category],
        )
        worker.signals.finished.connect(self.handle_preset_results)
        self.thread_pool.start(worker)

    def handle_preset_results(self, request_id: int, result, error) -> None:
        if request_id != self.preset_request_id:
            return
        if error:
            self.package_summary.setText(f"Preset load failed: {error}")
            return

        records = result
        self._syncing_items = True
        self.preset_tree.clear()
        for package_name in PRESET_CATEGORIES[self.current_category]:
            record = records[package_name]
            status = "INSTALLED" if record.installed else ("AVAILABLE" if record.available else "UNAVAILABLE")
            item = QTreeWidgetItem([record.name, status, record.description])
            item.setData(0, Qt.UserRole, ("preset", record.name, record.description))
            item.setFlags(item.flags() | Qt.ItemIsUserCheckable)
            if not record.available and not record.installed:
                item.setFlags(item.flags() & ~Qt.ItemIsEnabled)
            item.setCheckState(0, Qt.Checked if record.name in self.selected_packages else Qt.Unchecked)
            self.preset_tree.addTopLevelItem(item)
        self._syncing_items = False
        self.package_summary.setText(f"{self.current_category} preset packages are ready. Select anything you want to add to the queue.")

    def handle_tree_item_changed(self, item: QTreeWidgetItem, column: int) -> None:
        if self._syncing_items or column != 0:
            return
        source, package_name, description = item.data(0, Qt.UserRole)
        checked = item.checkState(0) == Qt.Checked
        self.set_package_selected(package_name, description, source, checked)

    def set_package_selected(self, package_name: str, description: str, source: str, selected: bool) -> None:
        if selected:
            self.selected_packages[package_name] = {"description": description, "source": source}
        else:
            self.selected_packages.pop(package_name, None)
        self.refresh_selected_queue()
        self.sync_tree_checks()

    def refresh_selected_queue(self) -> None:
        self.queue_list.clear()
        for package_name, details in self.selected_packages.items():
            item = QTreeWidgetItem([package_name, details["source"].upper()])
            self.queue_list.addTopLevelItem(item)
        self.package_install_button.setEnabled(bool(self.selected_packages))

    def sync_tree_checks(self) -> None:
        self._syncing_items = True
        for tree in (self.preset_tree, self.search_tree):
            for index in range(tree.topLevelItemCount()):
                item = tree.topLevelItem(index)
                _, package_name, _ = item.data(0, Qt.UserRole)
                item.setCheckState(0, Qt.Checked if package_name in self.selected_packages else Qt.Unchecked)
        self._syncing_items = False

    def start_package_install(self) -> None:
        if not self.selected_packages:
            return
        package_names = list(self.selected_packages.keys())
        self.logger.info("package install started packages=%s", ",".join(package_names))
        self.start_install_process(
            "packages",
            package_names,
            self.package_log,
            refresh_db=self.package_refresh_check.isChecked(),
        )

    def start_install_process(self, context: str, packages: list[str], log_widget: QPlainTextEdit, refresh_db: bool) -> None:
        self.install_context = context
        self.install_targets = packages
        self.install_command = pacman_backend.build_install_command(packages, refresh_db=refresh_db)
        command = self.install_command
        log_widget.appendPlainText(f"$ {' '.join(command)}")

        self.process = QProcess(self)
        self.process.setProgram(command[0])
        self.process.setArguments(command[1:])
        self.process.readyReadStandardOutput.connect(lambda: self.append_process_output(log_widget, self.process.readAllStandardOutput()))
        self.process.readyReadStandardError.connect(lambda: self.append_process_output(log_widget, self.process.readAllStandardError()))
        self.process.finished.connect(lambda exit_code, exit_status: self.handle_install_finished(exit_code, context))
        self.process.start()

        self.theme_run_button.setEnabled(False)
        self.package_install_button.setEnabled(False)

    def append_process_output(self, widget: QPlainTextEdit, payload) -> None:
        text = bytes(payload).decode("utf-8", errors="ignore")
        if text:
            widget.appendPlainText(text.rstrip())

    def handle_install_finished(self, exit_code: int, context: str) -> None:
        self.theme_run_button.setEnabled(True)
        self.package_install_button.setEnabled(bool(self.selected_packages))
        targets = list(self.install_targets)
        self.logger.info("install finished context=%s exit_code=%s targets=%s", context, exit_code, ",".join(targets))

        if context == "browser":
            option = browser_setup.get_browser_option(self.selected_browser_key)
            if exit_code == 0 and option is not None:
                self.theme_log.appendPlainText("Browser package installed successfully.")
                self.finish_browser_setup(option)
            else:
                self.browser_install_failed = True
                self.theme_status_headline = "BROWSER INSTALL FAILED"
                self.theme_status_details = ["pacman did not complete the browser installation. Check the log or use the emergency skip path if needed."]
                self.theme_headline.setText(f"STATUS // {self.theme_status_headline}")
                self.theme_detail.setText(self.theme_status_details[0])
                self.theme_continue_button.setEnabled(True)
            return

        installed = [name for name in targets if pacman_backend.is_installed(name)]
        failed = [name for name in targets if name not in installed]
        self.package_install_success = sorted(set(self.package_install_success + installed))
        self.package_install_failed = sorted(set(self.package_install_failed + failed))
        if failed:
            self.package_summary.setText(
                f"Install complete with warnings. Installed: {', '.join(installed) or 'none'}. Failed: {', '.join(failed)}."
            )
        else:
            self.package_summary.setText(f"Install complete. Installed {len(installed)} package(s).")
        self.load_preset_category(self.current_category)
        self.perform_search()

    def finalize_summary_and_continue(self) -> None:
        self.update_complete_summary()
        self.go_to_step(4)

    def update_complete_summary(self) -> None:
        option = browser_setup.get_browser_option(self.selected_browser_key)
        browser_name = option.label if option else "Not selected"
        lines = [
            "KESKOS SETUP COMPLETE",
            "",
            f"Selected browser: {browser_name}",
            f"Browser package: {self.selected_browser_package or 'Unavailable'}",
            f"Browser theme status: {self.theme_status_headline}",
        ]
        if self.theme_status_details:
            lines.append("Theme details:")
            lines.extend(f"  - {detail}" for detail in self.theme_status_details)
        if self.browser_setup_summary:
            lines.append("Default-browser actions:")
            lines.extend(f"  - {detail}" for detail in self.browser_setup_summary)

        lines.append("")
        lines.append("Extra package installs:")
        if self.package_install_success:
            lines.extend(f"  - installed: {name}" for name in self.package_install_success)
        else:
            lines.append("  - installed: none")
        if self.package_install_failed:
            lines.extend(f"  - failed: {name}" for name in self.package_install_failed)

        queued_but_not_installed = [name for name in self.selected_packages if name not in self.package_install_success]
        if queued_but_not_installed:
            lines.append("  - queued/not installed: " + ", ".join(queued_but_not_installed))

        self.complete_summary.setPlainText("\n".join(lines))

    def complete_and_exit(self) -> None:
        metadata = {
            "browser": self.selected_browser_key,
            "browser_package": self.selected_browser_package,
            "theme_status": self.theme_status_headline,
            "installed_packages": self.package_install_success,
            "failed_packages": self.package_install_failed,
        }
        state.mark_complete("complete", metadata)
        self.logger.info("setup completed metadata=%s", metadata)
        self.allow_close = True
        self.close()

    def toggle_debug_panel(self) -> None:
        visible = not self.debug_panel.isVisible()
        self.debug_panel.setVisible(visible)
        self.sidebar_hint.setVisible(visible)
        self.logger.info("debug panel visible=%s", visible)

    def open_terminal(self) -> None:
        self.logger.info("debug open terminal requested")
        if shutil.which("konsole"):
            QProcess.startDetached("konsole", ["--workdir", str(Path.home())])

    def view_logs(self) -> None:
        self.logger.info("debug view logs requested")
        if shutil.which("konsole"):
            QProcess.startDetached(
                "konsole",
                [
                    "-e",
                    "bash",
                    "-lc",
                    f'tail -n 200 -F "{state.LOG_FILE}"',
                ],
            )

    def open_network_settings(self) -> None:
        self.logger.info("open network settings requested")
        if shutil.which("systemsettings"):
            QProcess.startDetached("systemsettings", ["kcm_networkmanagement"])
            return
        if shutil.which("kcmshell6"):
            QProcess.startDetached("kcmshell6", ["kcm_networkmanagement"])

    def confirm_emergency_skip(self) -> None:
        self.logger.warning("emergency skip requested")
        dialog = QMessageBox(self)
        dialog.setWindowTitle("Emergency Skip")
        dialog.setText("Skip first-run setup?")
        dialog.setInformativeText("This will write the first-run completion file and stop the setup console from opening automatically.")
        dialog.setStandardButtons(QMessageBox.Yes | QMessageBox.No)
        dialog.setDefaultButton(QMessageBox.No)
        dialog.setStyleSheet(APP_STYLE)
        if dialog.exec() == QMessageBox.Yes:
            state.mark_complete("skipped", {"browser": self.selected_browser_key or "none"})
            self.logger.warning("setup skipped by user")
            self.allow_close = True
            self.close()

    def show_blocked_close_warning(self) -> None:
        self.show_status_dialog(
            "SETUP REQUIRED BEFORE ENTERING DESKTOP",
            "Finish the wizard or use the hidden emergency skip path if the setup cannot proceed normally.",
        )

    def show_status_dialog(self, title: str, text: str) -> None:
        dialog = QMessageBox(self)
        dialog.setWindowTitle(title)
        dialog.setText(title)
        dialog.setInformativeText(text)
        dialog.setStandardButtons(QMessageBox.Ok)
        dialog.setStyleSheet(APP_STYLE)
        dialog.exec()

    def closeEvent(self, event: QCloseEvent) -> None:  # noqa: N802
        if self.allow_close:
            event.accept()
            return
        event.ignore()
        self.show_blocked_close_warning()

    def paintEvent(self, event) -> None:  # noqa: N802
        super().paintEvent(event)
        painter = QPainter(self)
        pen = QPen(QColor(206, 106, 53, 20))
        painter.setPen(pen)
        for y in range(0, self.height(), 5):
            painter.drawLine(0, y, self.width(), y)
        painter.end()


def launch_application() -> int:
    global _LOCK_HANDLE

    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--autorun", action="store_true")
    args, _unknown = parser.parse_known_args(sys.argv[1:])

    state.ensure_state_dirs()
    with state.LOG_FILE.open("a", encoding="utf-8") as handle:
        handle.write(
            f"{datetime.now(timezone.utc).isoformat()} INFO launch requested "
            f"force={args.force} autorun={args.autorun} user={Path.home().name}\n"
        )

    if not args.force and state.is_complete():
        with state.LOG_FILE.open("a", encoding="utf-8") as handle:
            handle.write(f"{datetime.now(timezone.utc).isoformat()} INFO launch skipped: state complete\n")
        return 0

    if not args.force and state.should_skip_autorun():
        with state.LOG_FILE.open("a", encoding="utf-8") as handle:
            handle.write(f"{datetime.now(timezone.utc).isoformat()} INFO launch skipped: autorun guard active\n")
        return 0

    LOCK_FILE.parent.mkdir(parents=True, exist_ok=True)
    _LOCK_HANDLE = LOCK_FILE.open("w", encoding="utf-8")
    try:
        fcntl.flock(_LOCK_HANDLE.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        with state.LOG_FILE.open("a", encoding="utf-8") as handle:
            handle.write(f"{datetime.now(timezone.utc).isoformat()} INFO launch skipped: another instance already running\n")
        return 0

    os.environ.setdefault("QT_QPA_PLATFORMTHEME", "qt6ct")
    app = QApplication(sys.argv)
    app.setApplicationName("KeskOS Setup Console")
    app.setStyleSheet(APP_STYLE)
    app.setFont(QFont("JetBrains Mono Nerd Font", 10))

    window = SetupConsole()
    window.show()
    window.raise_()
    window.activateWindow()
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(launch_application())
