from __future__ import annotations

from typing import Any

from .common import connected, limited, result_payload


def is_available(_backend) -> bool:
    return True


def _baloofile(backend):
    return backend.settings_file("baloofilerc")


def _krunnerrc(backend):
    return backend.settings_file("krunnerrc")


def _split_paths(raw: str) -> list[str]:
    if not raw:
        return []
    parts = [part.strip() for part in raw.replace(";", "\n").replace(",", "\n").splitlines()]
    return [part for part in parts if part]


def read_current(backend) -> dict[str, Any]:
    indexing = backend.as_bool(backend.kread(_baloofile(backend), ("Basic Settings",), "Indexing-Enabled", "true"), True)
    hidden = backend.as_bool(backend.kread(_baloofile(backend), ("General",), "Index Hidden Folders", "false"), False)
    indexed = _split_paths(backend.kread(_baloofile(backend), ("General",), "folders[$e]", ""))
    excluded = _split_paths(backend.kread(_baloofile(backend), ("General",), "exclude folders[$e]", ""))
    status = connected("Baloo file indexing can be toggled directly.", advanced_module="kcm_baloofile")
    if not (backend.tools.get("balooctl6") or backend.tools.get("kcmshell6")):
        status = limited(
            "Baloo settings can be written, but runtime reload helpers are missing.",
            missing_tools=["balooctl6"],
            advanced_module="kcm_baloofile",
        )
    return {
        "status": status,
        "krunner_enabled": True,
        "file_indexing": indexing,
        "index_hidden_files": hidden,
        "indexed_folders": indexed,
        "excluded_folders": excluded,
        "web_shortcuts": True,
    }


def apply_changes(backend, values: dict[str, Any]) -> dict[str, Any]:
    backend.kwrite(_baloofile(backend), ("Basic Settings",), "Indexing-Enabled", backend.bool_text(bool(values.get("file_indexing", True))))
    backend.kwrite(_baloofile(backend), ("General",), "Index Hidden Folders", backend.bool_text(bool(values.get("index_hidden_files", False))))
    indexed = "\n".join(values.get("indexed_folders", []) or [])
    excluded = "\n".join(values.get("excluded_folders", []) or [])
    backend.kwrite(_baloofile(backend), ("General",), "folders[$e]", indexed)
    backend.kwrite(_baloofile(backend), ("General",), "exclude folders[$e]", excluded)

    details = ["Updated Baloo indexing preferences."]
    if backend.tools.get("balooctl6"):
        command = ["enable"] if bool(values.get("file_indexing", True)) else ["disable"]
        backend._run([backend.tools["balooctl6"], *command], capture=True, timeout=20)
        details.append("Applied the Baloo runtime indexing state.")

    return result_payload(
        True,
        "Search settings updated.",
        details=details,
        requires=["KRunner plugin and web-shortcut editing still use KDE's advanced search modules."],
    )


def open_advanced_settings(backend):
    return backend.open_kcm("kcm_baloofile")
