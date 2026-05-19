from __future__ import annotations

import configparser
from pathlib import Path
from typing import Any

from .common import connected, limited, missing, result_payload


COMMON_MIME_TYPES = [
    "inode/directory",
    "text/plain",
    "text/html",
    "application/pdf",
    "application/xhtml+xml",
    "image/png",
    "image/jpeg",
    "image/webp",
    "audio/mpeg",
    "video/mp4",
    "application/zip",
    "application/vnd.appimage",
    "x-scheme-handler/http",
    "x-scheme-handler/https",
]


def is_available(backend) -> bool:
    return bool(backend.tools.get("xdg-mime")) or backend.mimeapps.exists()


def _desktop_exists(backend, desktop_id: str) -> bool:
    roots = (Path("/usr/share/applications"), backend.paths.home / ".local" / "share" / "applications")
    return any((root / desktop_id).is_file() for root in roots)


def _mime_catalog(backend) -> list[str]:
    items = set(COMMON_MIME_TYPES)
    if backend.mimeapps.exists():
        parser = configparser.ConfigParser(interpolation=None)
        parser.optionxform = str
        parser.read(backend.mimeapps, encoding="utf-8")
        if parser.has_section("Default Applications"):
            items.update(parser["Default Applications"].keys())
    shared = Path("/usr/share/mime/types")
    if shared.is_file():
        try:
            for line in shared.read_text(encoding="utf-8", errors="replace").splitlines():
                stripped = line.strip()
                if "/" in stripped and not stripped.startswith("#"):
                    items.add(stripped)
        except OSError:
            pass
    return sorted(items)


def search_mime_types(backend, query: str) -> list[str]:
    query = query.strip().lower()
    catalog = _mime_catalog(backend)
    if not query:
        return catalog[:80]
    results = [mime for mime in catalog if query in mime.lower()]
    return results[:120]


def _status(backend):
    if backend.tools.get("xdg-mime"):
        return connected("File associations can be updated through xdg-mime and mimeapps.list.", advanced_module="kcm_filetypes")
    if backend.mimeapps.exists():
        return limited(
            "mimeapps.list can be edited directly, but xdg-mime is missing.",
            missing_tools=["xdg-mime"],
            advanced_module="kcm_filetypes",
        )
    return missing("No MIME editor backend is available.", missing_tools=["xdg-mime"], advanced_module="kcm_filetypes")


def read_current(backend) -> dict[str, Any]:
    return {
        "status": _status(backend),
        "known_mime_types": _mime_catalog(backend),
    }


def current_default(backend, mime_type: str) -> str:
    mime_type = mime_type.strip()
    if not mime_type:
        return ""
    if backend.tools.get("xdg-mime"):
        result = backend._run([backend.tools["xdg-mime"], "query", "default", mime_type], capture=True, timeout=10)
        if result is not None and result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip()
    return backend.mime_default(mime_type)


def apply_changes(backend, values: dict[str, Any]) -> dict[str, Any]:
    mime_type = str(values.get("mime_type", "")).strip()
    desktop_id = str(values.get("desktop_id", "")).strip()
    if not mime_type or "/" not in mime_type:
        return result_payload(False, "Enter a valid MIME type before applying a file association.")
    if not desktop_id or not _desktop_exists(backend, desktop_id):
        return result_payload(False, "The selected desktop file could not be found.")

    if backend.tools.get("xdg-mime"):
        backend._run([backend.tools["xdg-mime"], "default", desktop_id, mime_type], capture=True, timeout=20)
    backend.write_mime_defaults({mime_type: desktop_id})
    return result_payload(
        True,
        "File association updated.",
        details=[f"Set {desktop_id} as the default handler for {mime_type}."],
    )


def reset_to_system_default(backend, mime_type: str) -> dict[str, Any]:
    mime_type = mime_type.strip()
    if not mime_type:
        return result_payload(False, "Select a MIME type before resetting it.")
    parser = configparser.ConfigParser(interpolation=None)
    parser.optionxform = str
    if backend.mimeapps.exists():
        parser.read(backend.mimeapps, encoding="utf-8")
    if parser.has_section("Default Applications") and parser.has_option("Default Applications", mime_type):
        parser.remove_option("Default Applications", mime_type)
        with backend.mimeapps.open("w", encoding="utf-8") as handle:
            parser.write(handle)
        return result_payload(True, "The file association was reset to the system default.")
    return result_payload(True, "No custom file association was stored for that MIME type.")


def open_advanced_settings(backend):
    return backend.open_kcm("kcm_filetypes")
