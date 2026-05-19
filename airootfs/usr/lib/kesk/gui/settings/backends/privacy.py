from __future__ import annotations

from pathlib import Path
from typing import Any

from .common import limited, result_payload


def is_available(_backend) -> bool:
    return True


def _recent_documents_dir(backend) -> Path:
    return backend.paths.home / ".local" / "share" / "RecentDocuments"


def _recently_used_xbel(backend) -> Path:
    return backend.paths.home / ".local" / "share" / "recently-used.xbel"


def _wallet_status(backend) -> str:
    if backend.tools.get("kwalletd6"):
        return "Installed"
    return "Unavailable"


def _firewall_status(backend) -> str:
    tool = backend.tools.get("systemctl")
    if not tool:
        return "Unknown"
    for unit in ("firewalld.service", "ufw.service"):
        result = backend._run([tool, "is-active", unit], capture=True, timeout=10)
        if result is not None and result.returncode == 0 and result.stdout.strip() == "active":
            return f"{unit.split('.', 1)[0]} active"
    return "Not detected"


def read_current(backend) -> dict[str, Any]:
    screen_lock = backend.parse_int(backend.kread(backend.kscreenlockerrc, ("Daemon",), "Timeout", "300"), 300)
    recent_dir = _recent_documents_dir(backend)
    recent_count = len(list(recent_dir.glob("*"))) if recent_dir.is_dir() else 0
    return {
        "status": limited(
            "Privacy settings mix direct reads with advanced KDE handoff.",
            details=["Recent-file cleanup is available directly. Lock-screen policy and app permissions remain conservative."],
            advanced_module="kcm_screenlocker",
        ),
        "screen_lock_timeout_seconds": screen_lock,
        "lock_after_sleep": backend.as_bool(backend.kread(backend.kscreenlockerrc, ("Daemon",), "LockOnResume", "true"), True),
        "recent_files_history": bool(backend.custom_value("privacy_recent_files_history", True)),
        "recent_files_count": recent_count,
        "file_search_privacy": bool(backend.custom_value("privacy_file_search", False)),
        "wallet_status": _wallet_status(backend),
        "firewall_status": _firewall_status(backend),
        "flatseal_available": bool(backend.tools.get("flatseal")),
    }


def apply_changes(backend, values: dict[str, Any]) -> dict[str, Any]:
    backend.set_custom_values(
        {
            "privacy_recent_files_history": bool(values.get("recent_files_history", True)),
            "privacy_file_search": bool(values.get("file_search_privacy", False)),
        }
    )
    return result_payload(
        True,
        "Privacy preferences saved.",
        details=["Stored recent-files and file-search privacy preferences for KeskOS."],
        requires=["Use KDE's screen-lock and privacy modules for deeper policy changes."],
    )


def clear_recent_history(backend) -> dict[str, Any]:
    removed = 0
    recent_dir = _recent_documents_dir(backend)
    if recent_dir.is_dir():
        for path in recent_dir.iterdir():
            try:
                path.unlink()
                removed += 1
            except OSError:
                pass
    xbel = _recently_used_xbel(backend)
    if xbel.exists():
        try:
            xbel.write_text(
                "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<xbel version=\"1.0\" xmlns:bookmark=\"http://www.freedesktop.org/standards/desktop-bookmarks\"></xbel>\n",
                encoding="utf-8",
            )
            removed += 1
        except OSError:
            pass
    return result_payload(True, "Recent-file history cleared.", details=[f"Cleared {removed} recent-history item(s)."])


def open_advanced_settings(backend):
    return backend.open_kcm("kcm_screenlocker")
