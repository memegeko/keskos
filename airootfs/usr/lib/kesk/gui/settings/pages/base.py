from __future__ import annotations

from PySide6.QtCore import Signal
from PySide6.QtWidgets import (
    QAbstractButton,
    QAbstractSlider,
    QComboBox,
    QDoubleSpinBox,
    QLineEdit,
    QPlainTextEdit,
    QScrollArea,
    QSpinBox,
    QTextEdit,
    QVBoxLayout,
    QWidget,
)

from ..widgets import SettingsSection


class BasePage(QWidget):
    dirtyChanged = Signal(bool)
    page_key = ""

    def __init__(self, controller, title: str, subtitle: str = "") -> None:
        super().__init__()
        self.controller = controller
        self.sections: list[SettingsSection] = []
        self.search_terms = f"{title} {subtitle}".lower()
        self.page_title = title
        self.page_subtitle = subtitle
        self._dirty = False
        self._loading = False
        self._tracking_bound = False

        outer = QVBoxLayout(self)
        outer.setContentsMargins(0, 0, 0, 0)
        outer.setSpacing(0)

        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        outer.addWidget(scroll)

        self.content = QWidget()
        scroll.setWidget(self.content)
        self.content_layout = QVBoxLayout(self.content)
        self.content_layout.setContentsMargins(22, 22, 22, 22)
        self.content_layout.setSpacing(16)

        self.content_layout.addStretch(1)

    def add_section(self, section: SettingsSection) -> None:
        self.sections.append(section)
        self.content_layout.insertWidget(self.content_layout.count() - 1, section)

    def register_search_terms(self, *values: str) -> None:
        self.search_terms += " " + " ".join(value.lower() for value in values if value)

    def matches_query(self, query: str) -> bool:
        if not query:
            return True
        lowered = query.lower()
        if lowered in self.search_terms:
            return True
        return any(section.matches_query(lowered) for section in self.sections)

    def apply_filter(self, query: str) -> None:
        lowered = query.lower().strip()
        if not lowered:
            for section in self.sections:
                section.apply_filter("")
            return
        for section in self.sections:
            section.apply_filter(lowered)

    def show_result(self, result, title: str) -> None:
        self.controller.present_result(title, result)

    def begin_refresh(self) -> None:
        self._loading = True

    def finish_refresh(self) -> None:
        self._loading = False
        if not self._tracking_bound:
            self._bind_change_tracking()
            self._tracking_bound = True
        self.set_dirty(False)

    def set_dirty(self, dirty: bool) -> None:
        dirty = bool(dirty)
        if self._dirty == dirty:
            return
        self._dirty = dirty
        self.dirtyChanged.emit(dirty)

    def is_dirty(self) -> bool:
        return self._dirty

    def can_apply(self) -> bool:
        return callable(getattr(self, "apply_changes", None))

    def can_reset(self) -> bool:
        return callable(getattr(self, "load_state", None))

    def _mark_dirty(self, *_args) -> None:
        if self._loading:
            return
        self.set_dirty(True)

    def _bind_change_tracking(self) -> None:
        for widget in self.findChildren(QWidget):
            if widget is self:
                continue
            if widget.property("_kesk_dirty_bound"):
                continue

            if isinstance(widget, QLineEdit):
                widget.textChanged.connect(self._mark_dirty)
            elif isinstance(widget, (QSpinBox, QDoubleSpinBox, QAbstractSlider)):
                widget.valueChanged.connect(self._mark_dirty)
            elif isinstance(widget, QComboBox):
                widget.currentIndexChanged.connect(self._mark_dirty)
                if widget.isEditable():
                    widget.editTextChanged.connect(self._mark_dirty)
            elif isinstance(widget, (QTextEdit, QPlainTextEdit)):
                widget.textChanged.connect(self._mark_dirty)
            elif isinstance(widget, QAbstractButton) and widget.isCheckable():
                widget.toggled.connect(self._mark_dirty)
            else:
                continue

            widget.setProperty("_kesk_dirty_bound", True)

    def on_activated(self) -> None:
        pass
